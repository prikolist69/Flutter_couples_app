import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/supabase_client.dart';
import '../core/theme.dart';
import '../core/bouncing_card.dart';

class TimeCapsuleScreen extends StatefulWidget {
  final String pairId;
  final String userName;

  const TimeCapsuleScreen({
    super.key,
    required this.pairId,
    required this.userName,
  });

  @override
  State<TimeCapsuleScreen> createState() => _TimeCapsuleScreenState();
}

class _TimeCapsuleScreenState extends State<TimeCapsuleScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  bool _isCreating = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Минутный таймер для плавного обновления времени до вскрытия
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _openCreateModal() {
    _titleController.clear();
    _messageController.clear();
    _selectedDate = DateTime.now().add(const Duration(days: 7));
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final formattedDate =
                "${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}";

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              child: SingleChildScrollView(
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
                          child: const Text(
                            '⏳',
                            style: TextStyle(fontSize: 22),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Письмо в будущее ✨',
                          style: GoogleFonts.rubik(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      maxLength: 40,
                      decoration: InputDecoration(
                        labelText: 'Название или повод',
                        hintText: 'Например: Прочитай ровно через месяц...',
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _messageController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        labelText: 'Тайное послание',
                        hintText: 'Слова, признания или мысли, которые откроются в будущем...',
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      tileColor: AppTheme.background,
                      leading: const Icon(
                        Icons.lock_clock_rounded,
                        color: AppTheme.primary,
                      ),
                      title: const Text(
                        'Дата вскрытия замка',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.calendar_month_rounded,
                        size: 20,
                        color: AppTheme.primary,
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now().add(
                            const Duration(days: 1),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 1000),
                          ),
                        );
                        if (picked != null) {
                          setModalState(() {
                            _selectedDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              23,
                              59,
                            );
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isCreating ? null : () => _submitCapsule(ctx),
                      icon: const Icon(Icons.lock_rounded, size: 18),
                      label: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Запечатать капсулу 🔒'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitCapsule(BuildContext modalContext) async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    if (title.isEmpty || message.isEmpty) return;

    setState(() => _isCreating = true);
    HapticFeedback.heavyImpact();

    try {
      await supabase.from('pair_capsules').insert({
        'pair_id': widget.pairId,
        'author_name': widget.userName,
        'title': title,
        'message': message,
        'unlock_at': _selectedDate.toIso8601String(),
        'is_opened': false,
      });

      if (modalContext.mounted) Navigator.pop(modalContext);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _openCapsuleDialog(Map<String, dynamic> capsule) {
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: Row(
          children: [
            const Text('💌', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                capsule['title'] ?? 'Послание',
                style: GoogleFonts.rubik(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'От: ${capsule['author_name']}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                capsule['message'] ?? '',
                style: GoogleFonts.rubik(
                  fontSize: 14,
                  height: 1.45,
                  color: AppTheme.textDark,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  String _formatRemaining(DateTime unlockDate) {
    final now = DateTime.now();
    final diff = unlockDate.difference(now);

    if (diff.isNegative) return 'Можно открывать!';
    if (diff.inDays > 0) return '${diff.inDays} дн. ${diff.inHours % 24} ч.';
    if (diff.inHours > 0)
      return '${diff.inHours} ч. ${diff.inMinutes % 60} мин.';
    return '${diff.inMinutes} мин.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Капсулы времени ⏳',
          style: GoogleFonts.rubik(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        elevation: 3,
        onPressed: _openCreateModal,
        icon: const Icon(Icons.lock_outline_rounded, color: Colors.white),
        label: Text(
          'Запечатать письмо',
          style: GoogleFonts.rubik(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder(
        stream: supabase
            .from('pair_capsules')
            .stream(primaryKey: ['id'])
            .eq('pair_id', widget.pairId)
            .order('unlock_at', ascending: true),
        builder: (context, snapshot) {
          final List capsules = [];
          if (snapshot.hasData && snapshot.data != null) {
            for (final e in snapshot.data as List) {
              capsules.add(Map<String, dynamic>.from(e as Map));
            }
          }

          if (capsules.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('⏳', style: TextStyle(fontSize: 54)),
                    const SizedBox(height: 14),
                    Text(
                      'Пока нет запечатанных капсул',
                      style: GoogleFonts.rubik(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Напишите теплое признание или обещание и укажите дату, когда половинка сможет его прочитать ✨',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
            itemCount: capsules.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final c = capsules[index] as Map<String, dynamic>;
              final unlockAt = DateTime.parse(c['unlock_at']);
              final bool isUnlocked = DateTime.now().isAfter(unlockAt);

              return BouncingWidget(
                onTap: isUnlocked
                    ? () => _openCapsuleDialog(c)
                    : () {
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            content: Text(
                              'Капсула надежно запечатана до ${_formatRemaining(unlockAt)} 🔒',
                            ),
                          ),
                        );
                      },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: isUnlocked
                          ? Colors.green.withValues(alpha: 0.3)
                          : AppTheme.primary.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isUnlocked ? Colors.green : AppTheme.primary)
                            .withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? Colors.green.shade50
                              : AppTheme.accentPeach,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isUnlocked ? '🔓' : '🔒',
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c['title'] ?? '',
                              style: GoogleFonts.rubik(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'От: ${c['author_name']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  isUnlocked
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.timer_outlined,
                                  size: 13,
                                  color: isUnlocked
                                      ? Colors.green
                                      : AppTheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isUnlocked
                                      ? 'Готово к открытию!'
                                      : 'До вскрытия: ${_formatRemaining(unlockAt)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isUnlocked
                                        ? Colors.green
                                        : AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isUnlocked
                            ? Icons.mail_rounded
                            : Icons.lock_outline_rounded,
                        color: isUnlocked ? Colors.green : Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
