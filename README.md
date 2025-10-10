Quote of the Day App 📜
Welcome to the Quote of the Day app, a Flutter-based mobile application that delivers daily inspiration through quotes fetched from zenquotes.io. With features like quote rating, favorites, history, search, and notifications, this app keeps you motivated while offering a sleek, user-friendly experience in both light and dark modes.
Features ✨

Daily Quotes: Fetches random quotes from zenquotes.io/api/random.
Favorites: Save your favorite quotes with a single tap.
Quote History: View up to 50 previously fetched quotes.
Search Quotes: Search through your quote history by content or author.
Quote Rating: Rate quotes from 1 to 5 stars, with ratings displayed in history and search.
Daily Streaks: Tracks consecutive days you open the app, displayed in the app bar.
Notifications: Receive daily quote notifications at a customizable time; includes a test notification feature.
Dark/Light Mode: Toggle between themes for a personalized experience.
Copy & Share: Copy quotes to clipboard or share as text or images.
Offline Support: Displays cached quotes when offline with a clear status message.
Smooth Navigation: Built with GetX for seamless transitions between pages.

Screenshots 📸



Home Page
Settings Page
Search Page








Note: Replace screenshots/ with actual screenshot paths after adding them to your repository.
Getting Started 🚀
Follow these steps to set up and run the Quote of the Day app locally.
Prerequisites

Flutter: Version 3.x or higher (Install Flutter).
Dart: Included with Flutter.
IDE: Android Studio, VS Code, or any IDE with Flutter support.
Android Emulator/Device: For testing on Android (iOS also supported).

Installation

Clone the Repository:
git clone https://github.com/NaghDiefalla/propelex.git
cd propelex


Install Dependencies:Update pubspec.yaml with the required dependencies and run:
flutter pub get


Run the App:Connect a device or start an emulator, then run:
flutter run --verbose



Project Structure
lib/
├── main.dart                 # App entry point with GetMaterialApp
├── themes/
│   └── dark_theme.dart       # Dark theme configuration
├── views/
│   ├── login.dart            # Login page (assumed)
│   ├── home.dart             # Main page with quote display and actions
│   ├── settings.dart         # Settings for notifications and theme
│   ├── search.dart           # Search through quote history

Dependencies
Ensure pubspec.yaml includes:
dependencies:
  flutter:
    sdk: flutter
  get: ^4.6.5
  http: ^1.0.0
  flutter_local_notifications: ^17.0.0
  shared_preferences: ^2.0.0
  timezone: ^0.9.0
  share_plus: ^7.0.0
  connectivity_plus: ^6.0.0
  flutter_speed_dial: ^7.0.0
  path_provider: ^2.0.0
  permission_handler: ^11.3.1

Run flutter pub get after updating.
Android Permissions
Update android/app/src/main/AndroidManifest.xml:
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-permission android:name="android.permission.INTERNET"/>
  <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
  <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
  <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
  <application
    android:label="quote_app"
    android:icon="@mipmap/ic_launcher">
    ...
  </application>
</manifest>

Usage 🛠️

Login: Start at the login page (assumed) and navigate to the Home page.
Home Page:
View a daily quote fetched from zenquotes.io.
Use action buttons to favorite, copy, share as text, or share as an image.
Rate quotes using 1–5 stars.
Refresh quotes with the floating action button or pull-to-refresh.
View streak count in the app bar.


Settings Page:
Toggle notifications and set a daily notification time.
Test notifications (appears in 10 seconds).
Switch between dark and light modes.


Search Page:
Search quote history by content or author.
View ratings for quotes.


Offline Mode:
Displays cached quote with an "Offline" message when no internet is available.



Testing 📝
Test Notification Feature

Navigate to Settings > Test Notification.
Grant SCHEDULE_EXACT_ALARM permission if prompted (Android 12+).
If denied, enable in system settings via the dialog (Open Settings).
Verify a SnackBar shows “Test notification scheduled (check in 10 seconds, exact/inexact timing)”.
Check for a notification within 10 seconds with the current quote or fallback text.
Console logs: Look for Test notification scheduled for: ... or errors.

Test Other Features

Share as Image: Tap the image icon on the Home page; verify PNG sharing.
Search and Ratings: Rate a quote, search in SearchPage, confirm ratings display (e.g., “(Rating: 3)”).
Daily Streaks: Open daily to increment streak count in app bar.
Notifications: Set a notification time (e.g., 1 minute ahead for testing); verify daily notification.
Favorites/History/Rated Quotes: Check menu options in HomePage app bar.
Offline Mode: Disable internet; confirm cached quote and offline message.
API: Verify quotes load from zenquotes.io (check API Response: ... in logs).

Run with verbose logging:
flutter run --verbose

Debugging

Check console for errors (e.g., Error scheduling test notification: ..., Error sharing quote as image: ...).
For notification issues, verify initialization:debugPrint('Notifications initialized: ${await _notificationsPlugin.getNotificationAppLaunchDetails()}');


For image sharing issues, log _quoteCardKey.currentContext:debugPrint('Context: ${_quoteCardKey.currentContext}');


Share flutter run --verbose output if issues persist.

Troubleshooting 🔍

Notification Error (exact_alarms_not_permitted):
Ensure SCHEDULE_EXACT_ALARM and USE_EXACT_ALARM are in AndroidManifest.xml.
Grant permission in app settings (Android 12+).
Fallback to inexact scheduling works if permission is denied.


Image Sharing Fails:
Verify RepaintBoundary wraps the quote card in home.dart.
Check console for Error: _quoteCardKey.currentContext is null.


Ratings Not Displaying:
Confirm quoteRatings getter in HomePageState is used in search.dart.


API Issues:
Ensure internet permission and connectivity; check API Response: ... logs.



Contributing 🤝
Contributions are welcome! To contribute:

Fork the repository.
Create a feature branch (git checkout -b feature/your-feature).
Commit changes (git commit -m 'Add your feature').
Push to the branch (git push origin feature/your-feature).
Open a pull request.

Please include tests and update documentation as needed.
License 📄
This project is licensed under the MIT License - see the LICENSE file for details.
Contact 📧
For questions or feedback, open an issue on GitHub or contact naghdiefalla@gmail.com

Built with ❤️ by Nagh using Flutter and powered by zenquotes.io.