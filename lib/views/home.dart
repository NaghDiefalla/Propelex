import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:share_plus/share_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui' as ui;
import 'settings.dart';
import 'search.dart';

class Quote {
  final String id;
  final String content;
  final String author;

  Quote({
    required this.id,
    required this.content,
    required this.author,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['_id'] as String? ?? DateTime.now().toIso8601String(),
      content: json['q'] as String? ?? 'No quote available',
      author: json['a'] as String? ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'q': content,
      'a': author,
    };
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  static const _quoteApiUrl = 'https://zenquotes.io/api/random';
  static const _maxRetries = 3;
  static const _retryDelay = Duration(seconds: 2);
  static const _notificationId = 0;
  static const _notificationChannelId = 'quote_channel';
  static const _notificationChannelName = 'Quote of the Day';
  static const _quoteCacheDuration = Duration(hours: 24);

  Quote? _currentQuote;
  bool _isLoading = false;
  bool _isOffline = false;
  DateTime? _lastPressed;
  List<Quote> _quoteHistory = [];
  List<Quote> _favorites = [];
  Map<String, int> _quoteRatings = {};
  bool _enableNotifications = true;
  String _notificationTime = '08:00';
  int _streakCount = 0;
  DateTime? _lastOpened;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final GlobalKey _quoteCardKey = GlobalKey();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool get enableNotifications => _enableNotifications;
  List<Quote> get quoteHistory => _quoteHistory;
  Quote? get currentQuote => _currentQuote;
  Map<String, int> get quoteRatings => _quoteRatings;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _initializeApp();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    await Future.wait([
      _initializeNotifications(),
      _initializeTimeZone(),
      _getSavedData(),
      _loadRatings(),
      _updateStreak(),
    ]);
    final prefs = await SharedPreferences.getInstance();
    _notificationTime = prefs.getString('notification_time') ?? '08:00';
    await _checkConnectivityAndFetchQuote();
  }

  Future<void> _initializeNotifications() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) async {
        if (response.payload == 'daily_quote') {
          await _getQuote();
        }
      },
    );
    debugPrint('Notifications initialized: ${await _notificationsPlugin.getNotificationAppLaunchDetails()}');
  }

  Future<void> _initializeTimeZone() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
  }

  Future<void> _getSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedQuote = prefs.getString('quote');
    final savedHistory = prefs.getString('quote_history');
    final savedFavorites = prefs.getString('favorites');
    setState(() {
      if (savedQuote != null) {
        try {
          _currentQuote = Quote.fromJson(jsonDecode(savedQuote));
        } catch (e) {
          debugPrint('Error parsing saved quote: $e');
        }
      }
      if (savedHistory != null) {
        try {
          _quoteHistory = (jsonDecode(savedHistory) as List<dynamic>)
              .map((e) => Quote.fromJson(e))
              .toList();
        } catch (e) {
          debugPrint('Error parsing quote history: $e');
        }
      }
      if (savedFavorites != null) {
        try {
          _favorites = (jsonDecode(savedFavorites) as List<dynamic>)
              .map((e) => Quote.fromJson(e))
              .toList();
        } catch (e) {
          debugPrint('Error parsing favorites: $e');
        }
      }
      _enableNotifications = prefs.getBool('enable_notifications') ?? true;
    });
    _animationController.forward();
  }

  Future<void> _loadRatings() async {
    final prefs = await SharedPreferences.getInstance();
    final ratingsJson = prefs.getString('quote_ratings');
    if (ratingsJson != null) {
      try {
        _quoteRatings = Map<String, int>.from(jsonDecode(ratingsJson));
      } catch (e) {
        debugPrint('Error parsing ratings: $e');
      }
    }
  }

  Future<void> _updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastOpenedStr = prefs.getString('last_opened');
    final today = DateTime(now.year, now.month, now.day);

    if (lastOpenedStr != null) {
      try {
        _lastOpened = DateTime.parse(lastOpenedStr);
        final lastOpenedDay = DateTime(_lastOpened!.year, _lastOpened!.month, _lastOpened!.day);
        final difference = today.difference(lastOpenedDay).inDays;
        if (difference == 1) {
          _streakCount = (prefs.getInt('streak_count') ?? 0) + 1;
        } else if (difference > 1) {
          _streakCount = 1;
        }
      } catch (e) {
        debugPrint('Error parsing last opened date: $e');
        _streakCount = 1;
      }
    } else {
      _streakCount = 1;
    }

    await prefs.setString('last_opened', now.toIso8601String());
    await prefs.setInt('streak_count', _streakCount);
    setState(() {});
    debugPrint('Streak updated: $_streakCount');
  }

  Future<void> _rateQuote(String quoteId, int rating) async {
    final prefs = await SharedPreferences.getInstance();
    _quoteRatings[quoteId] = rating;
    await prefs.setString('quote_ratings', jsonEncode(_quoteRatings));
    setState(() {});
    debugPrint('Rated quote $quoteId: $rating');
  }

  Future<void> _checkConnectivityAndFetchQuote() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() => _isOffline = connectivityResult == ConnectivityResult.none);

    if (_isOffline) {
      _showError('No internet connection. Showing cached quote.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastFetch = prefs.getString('last_notification');
    if (lastFetch != null) {
      try {
        final lastFetchTime = DateTime.parse(lastFetch);
        if (DateTime.now().difference(lastFetchTime) < _quoteCacheDuration) {
          return;
        }
      } catch (e) {
        debugPrint('Error parsing last fetch time: $e');
      }
    }

    await _getQuote();
  }

  Future<void> _getQuote({int retryCount = 0}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _animationController.reset();
    });

    try {
      final response = await http.get(Uri.parse(_quoteApiUrl)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('Request timed out', 408),
      );

      if (response.statusCode != 200) {
        if (retryCount < _maxRetries) {
          await Future.delayed(_retryDelay);
          return _getQuote(retryCount: retryCount + 1);
        }
        _showError('Failed to fetch quote (Status: ${response.statusCode})');
        return;
      }

      debugPrint('API Response: ${response.body}');
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        debugPrint('JSON Decode Error: $e');
        if (retryCount < _maxRetries) {
          await Future.delayed(_retryDelay);
          return _getQuote(retryCount: retryCount + 1);
        }
        _showError('Invalid response format');
        return;
      }

      if (data is! List || data.isEmpty || data.first is! Map) {
        if (retryCount < _maxRetries) {
          await Future.delayed(_retryDelay);
          return _getQuote(retryCount: retryCount + 1);
        }
        _showError('Unexpected response format');
        return;
      }

      final quoteData = data.first as Map<String, dynamic>;
      final newQuote = Quote.fromJson(quoteData);

      if (newQuote.content.isEmpty || newQuote.author.isEmpty) {
        if (retryCount < _maxRetries) {
          await Future.delayed(_retryDelay);
          return _getQuote(retryCount: retryCount + 1);
        }
        _showError('Invalid quote data');
        return;
      }

      setState(() {
        _currentQuote = newQuote;
        _animationController.forward();
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('quote', jsonEncode(newQuote.toJson()));
      await prefs.setString('last_notification', DateTime.now().toIso8601String());

      if (!_quoteHistory.any((q) => q.id == newQuote.id)) {
        _quoteHistory.add(newQuote);
        if (_quoteHistory.length > 50) _quoteHistory.removeAt(0);
        await prefs.setString('quote_history', jsonEncode(_quoteHistory.map((q) => q.toJson()).toList()));
      }

      if (_enableNotifications) {
        await _scheduleNotification(newQuote.content, newQuote.author);
      }
    } catch (e, stack) {
      debugPrint('Error fetching quote: $e\n$stack');
      if (retryCount < _maxRetries) {
        await Future.delayed(_retryDelay);
          return _getQuote(retryCount: retryCount + 1);
        }
        _showError('Failed to fetch quote. Please try again.');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  
    Future<bool> _requestExactAlarmPermission() async {
      final status = await Permission.scheduleExactAlarm.request();
      debugPrint('Exact alarm permission status: $status');
      return status.isGranted;
    }
  
    Future<void> _scheduleNotification(String quote, String author) async {
      const androidDetails = AndroidNotificationDetails(
        _notificationChannelId,
        _notificationChannelName,
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(''),
        showWhen: true,
      );
      const platformDetails = NotificationDetails(android: androidDetails);
  
      final now = tz.TZDateTime.now(tz.local);
      final timeParts = _notificationTime.split(':');
      final scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      ).add(const Duration(days: 1));
  
      try {
        bool useExact = await _requestExactAlarmPermission();
        await _notificationsPlugin.zonedSchedule(
          _notificationId,
          'Quote of the Day',
          '$quote\n- $author',
          scheduledTime,
          platformDetails,
          androidScheduleMode: useExact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'daily_quote',
        );
        debugPrint('Daily notification scheduled for: $scheduledTime');
      } catch (e) {
        debugPrint('Error scheduling daily notification: $e');
        _showError('Failed to schedule daily notification');
      }
    }
  
    Future<void> rescheduleNotification() async {
      if (_currentQuote != null) {
        await _notificationsPlugin.cancel(_notificationId);
        await _scheduleNotification(_currentQuote!.content, _currentQuote!.author);
      }
    }
  
    Future<void> updateNotifications(bool value) async {
      setState(() {
        _enableNotifications = value;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('enable_notifications', value);
      if (!value) {
        await _notificationsPlugin.cancel(_notificationId);
      } else if (_currentQuote != null) {
        await _scheduleNotification(_currentQuote!.content, _currentQuote!.author);
      }
    }
  
    void _showError(String message) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _getQuote,
          ),
        ),
      );
    }
  
    void _shareQuote() {
      if (_currentQuote != null) {
        Share.share('${_currentQuote!.content}\n- ${_currentQuote!.author}', subject: 'Quote of the Day');
      } else {
        _showError('No quote available to share');
      }
    }
  
    Future<void> _shareQuoteAsImage() async {
      if (_currentQuote == null) {
        _showError('No quote available to share');
        return;
      }
      try {
        final context = _quoteCardKey.currentContext;
        if (context == null) {
          debugPrint('Error: _quoteCardKey.currentContext is null');
          _showError('Failed to capture quote image');
          return;
        }
        final renderObject = context.findRenderObject();
        if (renderObject == null) {
          debugPrint('Error: renderObject is null');
          _showError('Failed to capture quote image');
          return;
        }
        if (renderObject is! RenderRepaintBoundary) {
          debugPrint('Error: renderObject is not a RenderRepaintBoundary');
          _showError('Failed to capture quote image');
          return;
        }
        final boundary = renderObject;
        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          debugPrint('Error: byteData is null');
          _showError('Failed to capture quote image');
          return;
        }
        final buffer = byteData.buffer.asUint8List();
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/quote.png').writeAsBytes(buffer);
        await Share.shareXFiles([XFile(file.path)], text: 'Quote of the Day');
        debugPrint('Shared quote as image');
      } catch (e) {
        debugPrint('Error sharing quote as image: $e');
        _showError('Failed to share quote as image');
      }
    }
  
    void _copyQuote() {
      if (_currentQuote != null) {
        Clipboard.setData(ClipboardData(text: '${_currentQuote!.content}\n- ${_currentQuote!.author}'));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote copied to clipboard')),
        );
      } else {
        _showError('No quote available to copy');
      }
    }
  
    void _toggleFavorite() async {
      if (_currentQuote == null) return;
      final prefs = await SharedPreferences.getInstance();
      if (_favorites.any((q) => q.id == _currentQuote!.id)) {
        _favorites.removeWhere((q) => q.id == _currentQuote!.id);
      } else {
        _favorites.add(_currentQuote!);
      }
      await prefs.setString('favorites', jsonEncode(_favorites.map((q) => q.toJson()).toList()));
      setState(() {});
    }
  
    void _showQuoteHistory() {
      showModalBottomSheet(
        context: context,
        builder: (context) => DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) => ListView.builder(
            controller: scrollController,
            itemCount: _quoteHistory.length,
            itemBuilder: (context, index) {
              final quote = _quoteHistory[_quoteHistory.length - 1 - index];
              return ListTile(
                title: Text(
                  quote.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                subtitle: Text(
                  '- ${quote.author}${_quoteRatings.containsKey(quote.id) ? ' (Rating: ${_quoteRatings[quote.id]})' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () {
                  setCurrentQuote(quote);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      );
    }
  
    void _showFavorites() {
      showModalBottomSheet(
        context: context,
        builder: (context) => DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) => ListView.builder(
            controller: scrollController,
            itemCount: _favorites.length,
            itemBuilder: (context, index) {
              final quote = _favorites[_favorites.length - 1 - index];
              return ListTile(
                title: Text(
                  quote.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                subtitle: Text(
                  '- ${quote.author}${_quoteRatings.containsKey(quote.id) ? ' (Rating: ${_quoteRatings[quote.id]})' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () {
                  setCurrentQuote(quote);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      );
    }
  
    void _showRatedQuotes() {
      showModalBottomSheet(
        context: context,
        builder: (context) => DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) => ListView.builder(
            controller: scrollController,
            itemCount: _quoteHistory.length,
            itemBuilder: (context, index) {
              final quote = _quoteHistory[_quoteHistory.length - 1 - index];
              if (!_quoteRatings.containsKey(quote.id)) return const SizedBox.shrink();
              return ListTile(
                title: Text(quote.content),
                subtitle: Text('- ${quote.author} (Rating: ${_quoteRatings[quote.id]})'),
                onTap: () {
                  setCurrentQuote(quote);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      );
    }
  
    void setCurrentQuote(Quote quote) {
      setState(() {
        _currentQuote = quote;
        _animationController.reset();
        _animationController.forward();
      });
    }
  
    @override
    void dispose() {
      _animationController.dispose();
      super.dispose();
    }
  
    @override
    Widget build(BuildContext context) {
      final isFavorite = _currentQuote != null && _favorites.any((q) => q.id == _currentQuote!.id);
      return WillPopScope(
        onWillPop: () async {
          final now = DateTime.now();
          if (_lastPressed == null ||
              now.difference(_lastPressed!) > const Duration(seconds: 2)) {
            _lastPressed = now;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Press again to exit'),
                backgroundColor: Theme.of(context).primaryColor,
                duration: const Duration(seconds: 2),
              ),
            );
            return false;
          }
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text('Quote of the Day (Streak: $_streakCount)'),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  debugPrint('PopupMenu selected: $value');
                  if (value == 'settings') {
                    Get.to(() => SettingsPage(homeState: this));
                  } else if (value == 'favorites') {
                    _showFavorites();
                  } else if (value == 'history') {
                    _showQuoteHistory();
                  } else if (value == 'search') {
                    Get.to(() => SearchPage(homeState: this));
                  } else if (value == 'rated') {
                    _showRatedQuotes();
                  } else if (value == 'about') {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Quote App',
                      applicationVersion: '1.0',
                      applicationLegalese: '© 2023 Your Company',
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'settings', child: Text('Settings')),
                  const PopupMenuItem(value: 'favorites', child: Text('Favorites')),
                  const PopupMenuItem(value: 'history', child: Text('History')),
                  const PopupMenuItem(value: 'search', child: Text('Search Quotes')),
                  const PopupMenuItem(value: 'rated', child: Text('Rated Quotes')),
                  const PopupMenuItem(value: 'about', child: Text('About')),
                ],
              ),
            ],
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: _getQuote,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height,
                    ),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: MediaQuery.of(context).padding.top + 20,
                        ),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: RepaintBoundary(
                            key: _quoteCardKey,
                            child: Card(
                              color: Colors.transparent,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).primaryColor,
                                      Theme.of(context).primaryColor.withOpacity(0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.format_quote, size: 40, color: Colors.white70),
                                    const SizedBox(height: 8),
                                    if (_currentQuote != null)
                                      Semantics(
                                        label: 'Quote text',
                                        child: Text(
                                          _currentQuote!.content,
                                          style: Theme.of(context).textTheme.bodyLarge,
                                          textAlign: TextAlign.center,
                                        ),
                                      )
                                    else
                                      const Text('Tap to get a quote', style: TextStyle(color: Colors.white)),
                                    const SizedBox(height: 12),
                                    if (_currentQuote != null)
                                      Semantics(
                                        label: 'Quote author',
                                        child: Text(
                                          '- ${_currentQuote!.author}',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    if (_isOffline) ...[
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Offline: Showing cached quote',
                                        style: TextStyle(color: Colors.yellow, fontSize: 14),
                                        textAlign: TextAlign.center,
                                        semanticsLabel: 'Offline message',
                                      ),
                                    ],
                                    if (_currentQuote != null) ...[
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              isFavorite ? Icons.favorite : Icons.favorite_border,
                                              color: isFavorite ? Colors.red : Colors.white,
                                            ),
                                            onPressed: _toggleFavorite,
                                            tooltip: 'Favorite',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.copy, color: Colors.white),
                                            onPressed: _copyQuote,
                                            tooltip: 'Copy',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.share, color: Colors.white),
                                            onPressed: _shareQuote,
                                            tooltip: 'Share',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.image, color: Colors.white),
                                            onPressed: _shareQuoteAsImage,
                                            tooltip: 'Share as Image',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: List.generate(5, (index) => IconButton(
                                          icon: Icon(
                                            index < (_quoteRatings[_currentQuote!.id] ?? 0)
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: Colors.yellow,
                                          ),
                                          onPressed: () => _rateQuote(_currentQuote!.id, index + 1),
                                        )),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
          floatingActionButton: SpeedDial(
            icon: Icons.menu,
            activeIcon: Icons.close,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Colors.white,
            spacing: 10,
            childPadding: const EdgeInsets.all(5),
            spaceBetweenChildren: 10,
            children: [
              SpeedDialChild(
                child: const Icon(Icons.refresh),
                label: 'Refresh Quote',
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
                onTap: _getQuote,
              ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ),
      );
    }
  }