import 'package:flutter/material.dart';

class NoteThemeModel {
  final String id;
  final String name;
  final LinearGradient gradient;
  final Color textColor;
  final Color badgeColor;

  const NoteThemeModel({
    required this.id,
    required this.name,
    required this.gradient,
    required this.textColor,
    required this.badgeColor,
  });
}

class NoteThemes {
  static const List<NoteThemeModel> all = [
    NoteThemeModel(
      id: 'default',
      name: 'Чистый белый',
      gradient: LinearGradient(
        colors: [Colors.white, Color(0xFFFAF7F5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      textColor: Color(0xFF232533),
      badgeColor: Color(0xFFFFF0EC),
    ),
    NoteThemeModel(
      id: 'sunset',
      name: 'Персиковый закат',
      gradient: LinearGradient(
        colors: [Color(0xFFFF9A8B), Color(0xFFFF6A88)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      textColor: Colors.white,
      badgeColor: Color(0x33FFFFFF),
    ),
    NoteThemeModel(
      id: 'lavender',
      name: 'Лавандовый сон',
      gradient: LinearGradient(
        colors: [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      textColor: Colors.white,
      badgeColor: Color(0x33FFFFFF),
    ),
    NoteThemeModel(
      id: 'mint',
      name: 'Мятная свежесть',
      gradient: LinearGradient(
        colors: [Color(0xFF84FAB0), Color(0xFF8FD3F4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      textColor: Color(0xFF1B3B36),
      badgeColor: Color(0x33FFFFFF),
    ),
    NoteThemeModel(
      id: 'midnight',
      name: 'Глубокая ночь',
      gradient: LinearGradient(
        colors: [Color(0xFF232533), Color(0xFF14151F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      textColor: Colors.white,
      badgeColor: Color(0x22FFFFFF),
    ),
  ];

  static NoteThemeModel getById(String? id) {
    return all.firstWhere(
      (element) => element.id == id,
      orElse: () => all.first,
    );
  }
}
