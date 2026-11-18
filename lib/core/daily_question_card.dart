import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'supabase_client.dart';
import 'theme.dart';
import 'bouncing_card.dart';

class DailyQuestionCard extends StatefulWidget {
  final String pairId;
  final String userName;

  const DailyQuestionCard({
    super.key,
    required this.pairId,
    required this.userName,
  });

  @override
  State<DailyQuestionCard> createState() => _DailyQuestionCardState();
}

class _DailyQuestionCardState extends State<DailyQuestionCard> {
  final _answerController = TextEditingController();
  bool _isSaving = false;

  final List<String> _questionsPool = [
    'Какое моё первое впечатление о тебе было самым ярким?',
    'Если бы мы прямо сейчас выиграли поездку на 3 дня, куда бы поехали?',
    'Какая песня или трек у тебя всегда ассоциируется со мной?',
    'Какая моя привычка тебя больше всего умиляет или смешит?',
    'Идеальный вечер пятницы вдвоём: фильм дома или прогулка по ночному городу?',
    'Какой момент из наших отношений тебе хочется пережить заново?',
    'Какое блюдо или вкусняшку ты больше всего любишь заказывать вместе?',
    'За что ты больше всего благодарен(-на) нашим отношениям прямо сейчас?',
  ];

  String get _todayQuestion {
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    return _questionsPool[dayOfYear % _questionsPool.length];
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _openAnswerModal(String? currentAnswer) {
    _answerController.text = currentAnswer ?? '';
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPeach,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('✨', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Твой ответ дня',
                    style: GoogleFonts.rubik(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _todayQuestion,
              style: GoogleFonts.rubik(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _answerController,
              maxLength: 140,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ответь честно и тепло...',
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSaving ? null : () => _submitAnswer(ctx),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Сохранить ответ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitAnswer(BuildContext modalContext) async {
    final text = _answerController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final today = DateTime.now();
    final todayStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    try {
      final existing = await supabase
          .from('daily_answers')
          .select()
          .eq('pair_id', widget.pairId)
          .eq('answer_date', todayStr)
          .maybeSingle();

      if (existing == null) {
        await supabase.from('daily_answers').insert({
          'pair_id': widget.pairId,
          'question_text': _todayQuestion,
          'answer_date': todayStr,
          'partner1_answer': text,
        });
      } else {
        await supabase
            .from('daily_answers')
            .update({'partner1_answer': text})
            .eq('id', existing['id']);
      }

      if (modalContext.mounted) {
        Navigator.pop(modalContext);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    return StreamBuilder(
      stream: supabase
          .from('daily_answers')
          .stream(primaryKey: ['id'])
          .eq('pair_id', widget.pairId),
      builder: (context, snapshot) {
        final List list = snapshot.hasData ? (snapshot.data as List) : [];

        Map<String, dynamic>? todayData;
        if (list.isNotEmpty) {
          for (final item in list) {
            final d = Map<String, dynamic>.from(item as Map);
            if (d['answer_date'] == todayStr) {
              todayData = d;
              break;
            }
          }
        }

        final myAnswer = todayData?['partner1_answer'];
        final partnerAnswer = todayData?['partner2_answer'];

        final iAnswered =
            myAnswer != null && myAnswer.toString().trim().isNotEmpty;
        final partnerAnswered =
            partnerAnswer != null && partnerAnswer.toString().trim().isNotEmpty;
        final bothAnswered = iAnswered && partnerAnswered;

        return BouncingWidget(
          onTap: () => _openAnswerModal(myAnswer),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: bothAnswered
                    ? Colors.green.shade200
                    : AppTheme.primary.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('💬', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          'ВОПРОС ДНЯ В СЛЕПУЮ',
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
                        color: bothAnswered
                            ? Colors.green.shade50
                            : (iAnswered
                                  ? Colors.orange.shade50
                                  : AppTheme.accentPeach),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        bothAnswered
                            ? 'Открыто ✨'
                            : (iAnswered
                                  ? 'Ждём половинку ⏳'
                                  : 'Ждёт ответа 🔒'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: bothAnswered
                              ? Colors.green.shade700
                              : (iAnswered
                                    ? Colors.orange.shade800
                                    : AppTheme.primary),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _todayQuestion,
                  style: GoogleFonts.rubik(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                if (!iAnswered)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Нажми, чтобы ответить и открыть ответ половинки',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Твой ответ:',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          myAnswer,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bothAnswered
                          ? const Color(0xFFF3FAF5)
                          : const Color(0xFFFDF5F6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: bothAnswered
                            ? Colors.green.shade100
                            : Colors.pink.shade50,
                      ),
                    ),
                    child: bothAnswered
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ответ половинки:',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                partnerAnswer,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              const Icon(
                                Icons.lock_rounded,
                                size: 16,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  partnerAnswered
                                      ? 'Половинка уже ответила! (Нажми, чтобы посмотреть)'
                                      : 'Половинка ещё не ответила...',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms);
      },
    );
  }
}
