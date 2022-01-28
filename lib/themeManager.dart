import 'package:dog_breed_classifier/storageManager.dart';
import 'package:flutter/material.dart';

class ThemeNotifier with ChangeNotifier {
  final darkTheme = ThemeData.dark().copyWith(
    primaryColor: Colors.blueGrey.shade900,
    dividerTheme: DividerThemeData(color: Colors.white),
    iconTheme: IconThemeData(color: Colors.white),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  final lightTheme = ThemeData.light().copyWith(
    primaryColor: Colors.blue,
    dividerTheme: DividerThemeData(color: Colors.black54),
    iconTheme: IconThemeData(color: Colors.black),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  ThemeData? _themeData;
  ThemeData? getTheme() => _themeData;

  ThemeNotifier() {
    StorageManager.readData('themeMode').then((value) {
      print('value read from storage: ' + value.toString());
      var themeMode = value ?? 'light';
      if (themeMode == 'light') {
        _themeData = lightTheme;
      } else {
        print('setting dark theme');
        _themeData = darkTheme;
      }
      notifyListeners();
    });
  }

  void setDarkMode() async {
    _themeData = darkTheme;
    StorageManager.saveData('themeMode', 'dark');
    notifyListeners();
  }

  void setLightMode() async {
    _themeData = lightTheme;
    StorageManager.saveData('themeMode', 'light');
    notifyListeners();
  }
}
