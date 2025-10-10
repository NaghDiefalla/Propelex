import 'package:flutter/material.dart';
import 'app_color.dart';

ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColor.bodyColor,
    hintColor: AppColor.textColor,
    primaryColorLight: AppColor.buttonBackgroundColor,
    textTheme: const TextTheme(
        displayLarge: TextStyle(
            color: Colors.black, fontSize: 40, fontWeight: FontWeight.bold)),
    buttonTheme: const ButtonThemeData(
            textTheme: ButtonTextTheme.primary, buttonColor: Colors.black),
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: AppColor.buttonBackgroundColor,
          onPrimary: Colors.white,
          secondary: AppColor.textColor,
          onSecondary: Colors.black,
          error: Colors.red,
          onError: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
        ));
