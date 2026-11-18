import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/supabase_client.dart';
import '../core/theme.dart';
import '../core/bouncing_card.dart';

class StatusTab extends StatefulWidget {
  final String pairId;
  final String userName;

  const StatusTab({super.key, required this.pairId, required this.userName});

  @override
  State<StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends State<StatusTab> {
  String _currentActivity = 'Отдыхает';

  final _statusPresets = const [
    {'emoji': '🎓', 'activity': 'На парах / Учусь'},
    {'emoji': '🚗', 'activity': 'За рулём / В дороге'},
    {'emoji': '💻', 'activity': 'Пишу код / Работа'},
    {'emoji': '☕', 'activity': 'Пью кофе / Перерыв'},
    {'emoji': '🧸', 'activity': 'Скучаю по тебе'},
    {'emoji': '🍕', 'activity': 'Обедаю / Ужинаю'},
    {'emoji': '🎧', 'activity': 'Слушаю музыку'},
    {'emoji': '🌙', 'activity': 'Ложусь спать'},
  ];

  Future<void> _updateMyStatus(String emoji, String activity) async {
    HapticFeedback.selectionClick();
    setState(() {
      _currentActivity = activity;
    });

    try {
      await supabase
          .from('pairs')
          .update({
            'partner1_mood': emoji,
            'partner1_activity': activity,
            'partner1_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.pairId);
    } catch (_) {}
  }

  String _formatTimeAgo(String? timeStr) {
    if (timeStr == null) return 'Только что';
    final dt = DateTime.tryParse(timeStr);
    if (dt == null) return 'Только что';
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) return 'Только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    return 'Давно';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: supabase
          .from('pairs')
          .stream(primaryKey: ['id'])
          .eq('id', widget.pairId),
      builder: (context, snapshot) {
        Map<String, dynamic> pairData = {};
        if (snapshot.hasData && snapshot.data != null) {
          final rawList = snapshot.data as dynamic;
          if (rawList is Iterable && rawList.isNotEmpty) {
            pairData = Map<String, dynamic>.from(rawList.first as Map);
          }
        }

        final partnerName = pairData['partner2_name'] ?? 'Половинка';
        final partnerMood = pairData['partner2_mood'] ?? '✨';
        final partnerActivity = pairData['partner2_activity'] ?? 'Отдыхает';
        final partnerUpdatedAt = pairData['partner2_updated_at'];

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Живой Mood Orb Радар
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    center: Alignment(0, -0.2),
                    radius: 1.1,
                    colors: [Color(0xFFFFF0F5), Color(0xFFFFE6ED)],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'РАДАР ПРИСУТСТВИЯ',
                          style: GoogleFonts.rubik(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.3,
                            color: AppTheme.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00E676),
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                  .animate(
                                    onPlay: (c) => c.repeat(reverse: true),
                                  )
                                  .scale(
                                    begin: const Offset(0.8, 0.8),
                                    end: const Offset(1.3, 1.3),
                                    duration: 800.ms,
                                  ),
                              const SizedBox(width: 6),
                              Text(
                                _formatTimeAgo(partnerUpdatedAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Живая сфера с волнами ауры
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(
                                begin: const Offset(1.0, 1.0),
                                end: const Offset(1.15, 1.15),
                                duration: 1500.ms,
                              ),

                          Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Colors.white, Color(0xFFFFF0F5)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withValues(
                                        alpha: 0.28,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  partnerMood,
                                  style: const TextStyle(fontSize: 48),
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scaleXY(
                                begin: 1.0,
                                end: 1.06,
                                duration: 1100.ms,
                              ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    Text(
                      partnerName,
                      style: GoogleFonts.rubik(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        partnerActivity,
                        style: GoogleFonts.rubik(
                          fontSize: 15,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Твоё текущее занятие',
                style: GoogleFonts.rubik(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Нажми, и статус мгновенно обновится на экране половинки',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 16),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                ),
                itemCount: _statusPresets.length,
                itemBuilder: (context, index) {
                  final preset = _statusPresets[index];
                  final isSelected = _currentActivity == preset['activity'];

                  return BouncingWidget(
                    onTap: () =>
                        _updateMyStatus(preset['emoji']!, preset['activity']!),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withValues(alpha: 0.12)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : Colors.black.withValues(alpha: 0.06),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isSelected ? 0.05 : 0.02,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            preset['emoji']!,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              preset['activity']!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.rubik(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
