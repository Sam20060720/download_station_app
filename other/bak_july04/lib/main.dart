import 'package:flutter/material.dart';
import 'package:download_station/pageLogin.dart';

void main() async {
  runApp(MyApp());
}
// runAPP() 執行App

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
      theme: ThemeData(),
      darkTheme: ThemeData.dark(), // standard dark theme
      themeMode: ThemeMode.system,
      home: const pageLogin(
        isneedrunLogin: 1,
      ));
}
