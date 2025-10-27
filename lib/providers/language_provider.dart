import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  bool _isKannada = false;

  bool get isKannada => _isKannada;

  void toggleLanguage() {
    _isKannada = !_isKannada;
    notifyListeners(); // 🔄 Updates all listening widgets
  }

  void setLanguage(bool value) {
    _isKannada = value;
    notifyListeners();
  }
}
