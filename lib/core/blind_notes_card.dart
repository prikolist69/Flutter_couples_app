import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'supabase_client.dart';
import 'theme.dart';
import 'bouncing_card.dart';
import 'widget_sync_service.dart';

class FortuneItem {
  final String emoji;
  final String title;
  final String text;

  const FortuneItem({
    required this.emoji,
    required this.title,
    required this.text,
  });
}

class BlindNotesCard extends StatefulWidget {
  final String pairId;
  final String userName;
  final String partnerName;

  const BlindNotesCard({
    super.key,
    required this.pairId,
    required this.userName,
    required this.partnerName,
  });

  @override
  State<BlindNotesCard> createState() => _BlindNotesCardState();
}

class _BlindNotesCardState extends State<BlindNotesCard> {
  bool _isProcessing = false;

  // База автогенерируемых посланий и заданий дня
  static const List<FortuneItem> _fortunesPool = [
    FortuneItem(
      emoji: '☕',
      title: 'Уютная миссия',
      text: 'Сегодня идеальный повод устроить вечерний чай или взять любимый кофе на прогулку вдвоём.',
    ),
    FortuneItem(
      emoji: '✨',
      title: 'Комплимент дня',
      text: 'Вспомни, как красиво твоя половинка улыбается, когда искренне радуется мелочам.',
    ),
    FortuneItem(
      emoji: '🍿',
      title: 'Челлендж на вечер',
      text: 'Никаких споров о фильме: пусть тот, кто обычно уступает, выберет кино сегодня сам!',
    ),
    FortuneItem(
      emoji: '🧸',
      title: 'Обнимательный пакт',
      text: 'Обязательное объятие не менее 30 секунд при встрече. Научно доказано — снижает стресс на 99%.',
    ),
    FortuneItem(
      emoji: '🚗',
      title: 'Ночной вайб',
      text: 'Включить любимый плейлист в авто или наушниках и просто проехаться по вечерним огням города.',
    ),
    FortuneItem(
      emoji: '🍕',
      title: 'Вкусный вечер',
      text: 'Секретный десерт или пицца сегодня не считаются за калории, если съедены вместе.',
    ),
    FortuneItem(
      emoji: '💌',
      title: 'Секретная записка',
      text: 'Отправь половинке самое нелепое и милое совместное фото из галереи без контекста.',
    ),
  ];

  FortuneItem _getTodayFortune() {
    final now = DateTime.now();
    final dayIndex =
        (now.year * 365 + now.month * 31 + now.day) % _fortunesPool.length;
    return _fortunesPool[dayIndex];
  }

  Future<void> _revealNote(Map<String, dynamic>? currentData) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    HapticFeedback.heavyImpact();

    final today = DateTime.now();
    final todayStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final todayFortune = _getTodayFortune();

    try {
      if (currentData == null) {
        // Создаем запись на сегодня и отмечаем, что партнер 1 нажал
        await supabase.from('auto_daily_notes').insert({
          'pair_id': widget.pairId,
          'note_date': todayStr,
          'title': todayFortune.title,
          'message': todayFortune.text,
          'emoji': todayFortune.emoji,
          'partner1_opened': true,
          'partner2_opened': false,
        });
      } else {
        // Обновляем статус открытия
        await supabase
            .from('auto_daily_notes')
            .update({'partner1_opened': true})
            .eq('id', currentData['id']);
      }

      // Обновляем системный виджет на рабочем столе
      await WidgetSyncService.updateWidgetData(
        noteText: todayFortune.text,
        emoji: todayFortune.emoji,
        counterText: 'Послание дня ✨',
      );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _rerollFortune(Map<String, dynamic> currentData) async {
    HapticFeedback.mediumImpact();
    final randomItem = _fortunesPool[Random().nextInt(_fortunesPool.length)];

    try {
      await supabase
          .from('auto_daily_notes')
          .update({
            'title': randomItem.title,
            'message': randomItem.text,
            'emoji': randomItem.emoji,
          })
          .eq('id', currentData['id']);

      await WidgetSyncService.updateWidgetData(
        noteText: randomItem.text,
        emoji: randomItem.emoji,
        counterText: 'Новое послание ✨',
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    return StreamBuilder(
      stream: supabase
          .from('auto_daily_notes')
          .stream(primaryKey: ['id'])
          .eq('pair_id', widget.pairId),
      builder: (context, snapshot) {
        final List list = snapshot.hasData ? (snapshot.data as List) : [];
        Map<String, dynamic>? todayData;

        if (list.isNotEmpty) {
          for (final item in list) {
            final d = Map<String, dynamic>.from(item as Map);
            if (d['note_date'] == todayStr) {
              todayData = d;
              break;
            }
          }
        }

        final bool iOpened = todayData?['partner1_opened'] == true;
        final bool partnerOpened = todayData?['partner2_opened'] == true;
        final bool isBothOpened = iOpened && partnerOpened;

        final displayItem = todayData != null
            ? FortuneItem(
                emoji: todayData['emoji'] ?? '💌',
                title: todayData['title'] ?? 'Послание дня',
                text: todayData['message'] ?? '',
              )
            : _getTodayFortune();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🥠', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      'ЗАПИСКА ДНЯ ДЛЯ ДВОИХ',
                      style: GoogleFonts.rubik(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isBothOpened
                        ? Colors.green.shade50
                        : (iOpened
                              ? Colors.orange.shade50
                              : AppTheme.accentPeach),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isBothOpened
                        ? 'Вскрыто ✨'
                        : (iOpened
                              ? 'Ждём ${widget.partnerName} ⏳'
                              : 'Запечатано 🔒'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isBothOpened
                          ? Colors.green.shade700
                          : (iOpened
                                ? Colors.orange.shade800
                                : AppTheme.primary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (!isBothOpened)
              // Запечатанный конверт с интригой
              BouncingWidget(
                onTap: iOpened ? null : () => _revealNote(todayData),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF0F5), Color(0xFFFFDFE5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Text('💌', style: TextStyle(fontSize: 34)),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        iOpened
                            ? 'Ты нажал(-а) «Вскрыть»!'
                            : 'Свежее предсказание дня готово!',
                        style: GoogleFonts.rubik(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        iOpened
                            ? 'Осталось дождаться, пока ${widget.partnerName} тоже нажмет у себя'
                            : 'Нажми, чтобы сорвать печать вместе с половинкой ✨',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!iOpened)
                        ElevatedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () => _revealNote(todayData),
                          icon: const Icon(
                            Icons.mark_email_read_rounded,
                            size: 18,
                          ),
                          label: const Text('Сорвать печать'),
                        ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 350.ms)
            else
              // Открытая записка дня
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: Colors.green.shade200, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.accentPeach,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            displayItem.emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayItem.title,
                                style: GoogleFonts.rubik(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Синхронизировано на рабочий стол',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.casino_outlined,
                            color: AppTheme.primary,
                          ),
                          tooltip: 'Другое предсказание',
                          onPressed: () => _rerollFortune(todayData!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        displayItem.text,
                        style: GoogleFonts.rubik(
                          fontSize: 15,
                          height: 1.4,
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          ],
        );
      },
    );
  }
}
