import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blueGrey[800],
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blueGrey,
          accentColor: Colors.teal[300],
        ),
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.white70),
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  static const _quoteApiUrl = 'https://zenquotes.io/api/random';
  static const _maxRetries = 3;
  static const _retryDelay = Duration(seconds: 2);
  static const _notificationId = 0;
  static const _notificationChannelId = 'quote_channel';
  static const _notificationChannelName = 'Quote of the Day';

  String _quote = 'Tap the button to get a quote';
  String _author = '';
  bool _isLoading = false;
  DateTime? _lastPressed;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

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
      _getSavedQuote(),
    ]);
    // Fetch a new quote after loading saved quote
    await _getQuote();
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
  }

  Future<void> _initializeTimeZone() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
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

      final List<dynamic> data = jsonDecode(response.body);
      if (data.isEmpty || data.first is! Map) {
        if (retryCount < _maxRetries) {
          await Future.delayed(_retryDelay);
          return _getQuote(retryCount: retryCount + 1);
        }
        _showError('Unexpected response format');
        return;
      }

      final quoteData = data.first as Map<String, dynamic>;
      final newQuote = quoteData['q']?.toString() ?? 'No quote available';
      final newAuthor = quoteData['a']?.toString() ?? 'Unknown';

      if (newQuote.isEmpty || newAuthor.isEmpty) {
        if (retryCount < _maxRetries) {
          await Future.delayed(_retryDelay);
          return _getQuote(retryCount: retryCount + 1);
        }
        _showError('Invalid quote data');
        return;
      }

      setState(() {
        _quote = newQuote;
        _author = newAuthor;
        _animationController.forward();
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('quote', newQuote);
      await prefs.setString('author', newAuthor);
      await prefs.setString('last_notification', DateTime.now().toIso8601String());

      await _scheduleNotification(newQuote, newAuthor);
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

    final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(hours: 24));

    await _notificationsPlugin.zonedSchedule(
      _notificationId,
      'Quote of the Day',
      '$quote\n- $author',
      scheduledTime,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'daily_quote',
    );
  }

  Future<void> _getSavedQuote() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _quote = prefs.getString('quote') ?? 'Tap the button to get a quote';
      _author = prefs.getString('author') ?? '';
    });
    _animationController.forward();
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Card(
              color: Theme.of(context).primaryColor,
              margin: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _quote,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _author.isNotEmpty ? '- $_author' : '',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _getQuote,
          backgroundColor: Theme.of(context).colorScheme.secondary,
          tooltip: 'Get New Quote',
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Icon(Icons.refresh, size: 28),
        ),
      ),
    );
  }
}