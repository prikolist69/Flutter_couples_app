import 'package:flutter/material.dart';

enum HeartSkinType {
  roseBloom, // Уровень 1: Нежный лепесток (базовый)
  cyberNeon, // Уровень 2: Неоновый пульс (от 5 дней)
  pureCrystal, // Уровень 3: Ледяной кристалл (от 14 дней)
  stellarGold, // Уровень 4: Расплавленное золото (от 30 дней)
}

class HeartSkinConfig {
  final HeartSkinType type;
  final String id;
  final String name;
  final String description;
  final int requiredStreak;
  final List<Color> gradientColors;
  final Color shadowColor;
  final Color waveColor;
  final Color syncColor;
  final List<Color> sparkleColors;
  final IconData icon;

  const HeartSkinConfig({
    required this.type,
    required this.id,
    required this.name,
    required this.description,
    required this.requiredStreak,
    required this.gradientColors,
    required this.shadowColor,
    required this.waveColor,
    required this.syncColor,
    required this.sparkleColors,
    this.icon = Icons.favorite_rounded,
  });

  static const List<HeartSkinConfig> allSkins = [
    HeartSkinConfig(
      type: HeartSkinType.roseBloom,
      id: 'rose_bloom',
      name: 'Нежный Лепесток',
      description: 'Мягкий пастельный стиль первой влюблённости',
      requiredStreak: 1,
      gradientColors: [Color(0xFFFF94B8), Color(0xFFFF4D79), Color(0xFFD81B60)],
      shadowColor: Color(0xFFFF4D79),
      waveColor: Color(0xFFFF5277),
      syncColor: Color(0xFFFF0055),
      sparkleColors: [Color(0xFFFF80AB), Color(0xFFFF4081)],
    ),
    HeartSkinConfig(
      type: HeartSkinType.cyberNeon,
      id: 'cyber_neon',
      name: 'Cyber Неон',
      description: 'Электрический импульс страсти и драйва',
      requiredStreak: 5,
      gradientColors: [Color(0xFFE040FB), Color(0xFF7C4DFF), Color(0xFF00E5FF)],
      shadowColor: Color(0xFF7C4DFF),
      waveColor: Color(0xFF00E5FF),
      syncColor: Color(0xFFE040FB),
      sparkleColors: [Color(0xFF00E5FF), Color(0xFFE040FB), Color(0xFFFFFF00)],
      icon: Icons.electric_bolt_rounded,
    ),
    HeartSkinConfig(
      type: HeartSkinType.pureCrystal,
      id: 'pure_crystal',
      name: 'Чистый Кристалл',
      description: 'Светящиеся грани доверия и глубины чувств',
      requiredStreak: 14,
      gradientColors: [Color(0xFF80DEEA), Color(0xFF4DD0E1), Color(0xFF26C6DA)],
      shadowColor: Color(0xFF26C6DA),
      waveColor: Color(0xFF80DEEA),
      syncColor: Color(0xFF00E5FF),
      sparkleColors: [Color(0xFFE0F7FA), Color(0xFF80DEEA), Color(0xFFFFFFFF)],
      icon: Icons.diamond_rounded,
    ),
    HeartSkinConfig(
      type: HeartSkinType.stellarGold,
      id: 'stellar_gold',
      name: 'Звёздное Золото',
      description: 'Королевский огонь нерушимой связи',
      requiredStreak: 30,
      gradientColors: [Color(0xFFFFD54F), Color(0xFFFFB300), Color(0xFFFF8F00)],
      shadowColor: Color(0xFFFF8F00),
      waveColor: Color(0xFFFFD54F),
      syncColor: Color(0xFFFF6F00),
      sparkleColors: [Color(0xFFFFD700), Color(0xFFFFF9C4), Color(0xFFFFAB00)],
      icon: Icons.auto_awesome_rounded,
    ),
  ];

  static HeartSkinConfig getById(String? id) {
    return allSkins.firstWhere((s) => s.id == id, orElse: () => allSkins.first);
  }
}
