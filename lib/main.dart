import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/views/login.dart';
import 'themes/app_theme.dart';
import 'themes/dark_theme.dart';
import 'themes/light_theme.dart';

void main() {
  runApp(GetMaterialApp(
    home: LoginPage(),
    debugShowCheckedModeBanner: false,
    theme: darkTheme,
    darkTheme: darkTheme,
    themeMode: ThemeMode.system,
  ));
}
