import 'package:flutter/material.dart';
import 'app_color.dart';

ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColor.bodyColorDark,
    hintColor: AppColor.textColor,
    primaryColorLight: AppColor.buttonBackgroundColorDark,
    textTheme: const TextTheme(
        displayLarge: TextStyle(
            color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
    buttonTheme: const ButtonThemeData(
                textTheme: ButtonTextTheme.primary, buttonColor: Colors.white),
            colorScheme: ColorScheme(
                brightness: Brightness.dark,
                primary: AppColor.buttonBackgroundColorDark,
                onPrimary: Colors.white,
                secondary: AppColor.textColor,
                onSecondary: Colors.white,
                error: Colors.red,
                onError: Colors.white,
                surface: AppColor.bodyColorDark,
                onSurface: Colors.white,
            ),
        );
