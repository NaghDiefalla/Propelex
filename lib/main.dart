import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/views/login.dart';
import 'themes/dark_theme.dart';

void main() {
  runApp(GetMaterialApp(
    home: const LoginPage(),
    debugShowCheckedModeBanner: false,
    theme: darkTheme,
    darkTheme: darkTheme,
    themeMode: ThemeMode.system,
  ));
}
