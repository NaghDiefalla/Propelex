import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'home.dart';

class SettingsPage extends StatelessWidget {
  final HomePageState homeState;

  const SettingsPage({super.key, required this.homeState});

  Future<void> _toggleThemeMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    if (isDark) {
      Get.changeThemeMode(ThemeMode.dark);
      await prefs.setString('theme_mode', 'dark');
    } else {
      Get.changeThemeMode(ThemeMode.light);
      await prefs.setString('theme_mode', 'light');
    }
    debugPrint('Theme mode toggled: ${isDark ? 'dark' : 'light'}');
  }

  Future<void> _setNotificationTime(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final savedTime = prefs.getString('notification_time') ?? '08:00';
    final initialTime = TimeOfDay(
      hour: int.parse(savedTime.split(':')[0]),
      minute: int.parse(savedTime.split(':')[1]),
    );
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (selectedTime != null) {
      final timeString = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      await prefs.setString('notification_time', timeString);
      debugPrint('Notification time set: $timeString');
      if (homeState.enableNotifications && homeState.currentQuote != null) {
        await homeState.rescheduleNotification();
      }
    }
  }

  Future<void> _testNotification(BuildContext context) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'quote_channel',
        'Quote of the Day',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(''),
        showWhen: true,
      );
      const platformDetails = NotificationDetails(android: androidDetails);

      final now = tz.TZDateTime.now(tz.local);
      final scheduledTime = now.add(const Duration(seconds: 10));
      final quote = homeState.currentQuote;
      final notificationText = quote != null
          ? '${quote.content}\n- ${quote.author}'
          : 'Test notification: No quote available';

      final status = await Permission.scheduleExactAlarm.request();
      debugPrint('Exact alarm permission status: $status');
      if (status.isPermanentlyDenied) {
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Permission Required'),
              content: const Text('Please enable exact alarm permission in system settings to allow precise notifications.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        }
        return;
      }

      bool useExact = status.isGranted;
      await FlutterLocalNotificationsPlugin().zonedSchedule(
        999,
        'Test Notification',
        notificationText,
        scheduledTime,
        platformDetails,
        androidScheduleMode: useExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'test_notification',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test notification scheduled (check in 10 seconds, ${useExact ? 'exact' : 'inexact'} timing)'),
          ),
        );
      }
      debugPrint('Test notification scheduled for: $scheduledTime (exact: $useExact)');
    } catch (e) {
      debugPrint('Error scheduling test notification: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to schedule test notification')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Get.theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Enable Notifications'),
              value: homeState.enableNotifications,
              onChanged: (value) async {
                try {
                  await homeState.updateNotifications(value);
                  debugPrint('Notifications toggled: $value');
                } catch (e) {
                  debugPrint('Error updating notifications: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update notification settings')),
                  );
                }
              },
            ),
            ListTile(
              title: const Text('Notification Time'),
              subtitle: FutureBuilder<String>(
                future: SharedPreferences.getInstance().then((prefs) => prefs.getString('notification_time') ?? '08:00'),
                builder: (context, snapshot) => Text(snapshot.data ?? '08:00'),
              ),
              onTap: () => _setNotificationTime(context),
            ),
            // ListTile(
            //   title: const Text('Test Notification'),
            //   subtitle: const Text('Send a test notification now'),
            //   onTap: () => _testNotification(context),
            // ),
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: isDarkMode,
              onChanged: (value) async {
                await _toggleThemeMode(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}