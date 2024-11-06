import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String quote = '';
  String author = '';
  DateTime? _lastPressed;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> _scheduleNotification() async {
    var scheduledNotificationDateTime =
        DateTime.now().add(Duration(hours: 24));
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      '1',
      'Quote of the Day',
      'Get a daily inspirational quote!',
      importance: Importance.high,
      priority: Priority.high,
    );
    var platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.schedule(
      0,
      'Quote of the Day',
      quote + '\n- ' + author,
      scheduledNotificationDateTime,
      platformChannelSpecifics,
      payload: 'daily_quote',
    );
  }

  Future<void> _getQuote() async {
    final response = await http.get(Uri.parse('https://api.quotable.io/random'));
    final data = json.decode(response.body);
    setState(() {
      quote = data['content'];
      author = data['author'];
    });
    _scheduleNotification();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('quote', quote);
    await prefs.setString('author', author);
    await prefs.setString(
        'last_notification', DateTime.now().toString());
  }

  Future<void> _getSavedQuote() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String savedQuote = prefs.getString('quote') ?? '';
    String savedAuthor = prefs.getString('author') ?? '';
    setState(() {
      quote = savedQuote;
      author = savedAuthor;
    });
  }

  @override
  void initState() {
    super.initState();
    _getSavedQuote();
    var initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (String? payload) async {});
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();
        if (_lastPressed == null || now.difference(_lastPressed!) > Duration(seconds: 2)) {
          _lastPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Press again to exit", style: Theme.of(context).textTheme.bodyText1), backgroundColor: Theme.of(context).primaryColor),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Card(
            color: Theme.of(context).primaryColor,
            margin: EdgeInsets.all(20),
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    quote,
                    style:Theme.of(context).textTheme.bodyText2
                  ),
                  SizedBox(height: 10),
                  Text(
                    '- ' + author,
                    style: Theme.of(context).textTheme.bodyText1,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _getQuote,
          backgroundColor: Theme.of(context).secondaryHeaderColor,
          foregroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: Icon(Icons.refresh),
        ),
      ),
    );
  }
}
