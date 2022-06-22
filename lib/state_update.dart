import 'package:flutter/material.dart';
import 'global.dart';

class ChangeTheme with ChangeNotifier {
  String _theme = appSettings.theme;

  String get getTheme => _theme;

  void change() {
    _theme = appSettings.theme;
    notifyListeners();
  }
}

class ChangeTime with ChangeNotifier {
  int _time = 0;

  int get getTime => _time;

  void increment() {
    _time = _time + 1;
    notifyListeners();
  }
  void change(int time) {
    _time = time;
    notifyListeners();
  }
}