import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/supabase_client.dart';
import '../core/storage_service.dart';
import '../core/theme.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String pairId;
  final DateTime? initialDate;

  const SettingsScreen({super.key, required this.pairId, this.initialDate});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  DateTime? _selectedDate;
  String _inviteCode = '...';
  String _partner1 = 'Я';
  String _partner2 = 'Половинка';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _loadPairData();
  }

  Future<void> _loadPairData() async {
    try {
      final data = await supabase
          .from('pairs')
          .select('invite_code, start_date, partner1_name, partner2_name')
          .eq('id', widget.pairId)
          .single();

      if (mounted) {
        setState(() {
          _inviteCode = data['invite_code'] ?? '------';
          _partner1 = data['partner1_name'] ?? 'Я';
          _partner2 = data['partner2_name'] ?? 'Половинка';
          if (data['start_date'] != null) {
            _selectedDate = DateTime.parse(data['start_date']);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _saveDate(picked);
    }
  }

  Future<void> _saveDate(DateTime date) async {
    setState(() => _isLoading = true);
    try {
      final formatted =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      await supabase
          .from('pairs')
          .update({'start_date': formatted})
          .eq('id', widget.pairId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Дата отношений сохранена! ❤️')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка сохранения даты: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Выход из сессии на телефоне
  void _leavePair() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Сменить пару?'),
        content: const Text(
          'Вы выйдете из профиля на этом устройстве. Данные в облаке останутся сохранены, подключиться снова можно по коду приглашения.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
            ),
            onPressed: () async {
              await StorageService.clearSession();
              if (!mounted) return;
              Navigator.pop(dialogContext);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                (route) => false,
              );
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  // Полное удаление всех данных пары (Требование сторов App Store / Google Play)
  void _deletePairDataPermanently() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить пару и все данные?'),
        content: const Text(
          'Это действие необратимо. Все записки, списки желаний, купоны и история будут безвозвратно удалены из облачной базы данных.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() => _isLoading = true);

              try {
                // Удаляем связанные данные
                await supabase
                    .from('widget_notes')
                    .delete()
                    .eq('pair_id', widget.pairId);
                await supabase
                    .from('wishlist_items')
                    .delete()
                    .eq('pair_id', widget.pairId);
                await supabase
                    .from('coupons')
                    .delete()
                    .eq('pair_id', widget.pairId);
                await supabase.from('pairs').delete().eq('id', widget.pairId);

                await StorageService.clearSession();

                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка удаления: $e')),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Удалить навсегда'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.rubik(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(height: 1.4)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _selectedDate != null
        ? "${_selectedDate!.day.toString().padLeft(2, '0')}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.year}"
        : "Не выбрана";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Настройки',
          style: GoogleFonts.rubik(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // 1. Профиль пары
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Пара',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_partner1 & $_partner2',
                          style: GoogleFonts.rubik(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.copy_rounded,
                        color: AppTheme.primary,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Код пары скопирован!')),
                        );
                      },
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Код подключения:',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                    Text(
                      _inviteCode,
                      style: GoogleFonts.rubik(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Дата отношений
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Начало отношений',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: GoogleFonts.rubik(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _isLoading ? null : _pickDate,
                  child: const Text('Изменить'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. Блок информации и стандартов площадок
          Text(
            'О приложении и конфиденциальность',
            style: GoogleFonts.rubik(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppTheme.textDark,
                  ),
                  title: const Text('Политика конфиденциальности'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    _showInfoDialog(
                      'Политика конфиденциальности',
                      'Our Space бережно относится к вашим данным. Все записки, списки желаний и статусы шифруются при передаче и доступны только вам и вашей второй половинке по уникальному коду пары.',
                    );
                  },
                ),
                const Divider(height: 1, indent: 60),
                ListTile(
                  leading: const Icon(
                    Icons.description_outlined,
                    color: AppTheme.textDark,
                  ),
                  title: const Text('Условия использования'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    _showInfoDialog(
                      'Условия использования',
                      'Приложение Our Space предназначено для личного использования парами для синхронизации заметок, желаний и виджетов.',
                    );
                  },
                ),
                const Divider(height: 1, indent: 60),
                ListTile(
                  leading: const Icon(
                    Icons.mail_outline_rounded,
                    color: AppTheme.textDark,
                  ),
                  title: const Text('Поддержка и отзывы'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    _showInfoDialog(
                      'Служба заботы',
                      'По любым вопросам и предложениям пишите нам на почту поддержки: support@ourspace.app',
                    );
                  },
                ),
                const Divider(height: 1, indent: 60),
                const ListTile(
                  leading: Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.textDark,
                  ),
                  title: Text('Версия сборки'),
                  trailing: Text(
                    '1.0.0 (Release Ready)',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // 4. Действия с аккаунтом
          OutlinedButton.icon(
            onPressed: _leavePair,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade400,
              side: BorderSide(color: Colors.red.shade200),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Сменить пару на этом устройстве'),
          ),

          const SizedBox(height: 12),

          TextButton.icon(
            onPressed: _deletePairDataPermanently,
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            icon: const Icon(Icons.delete_forever_rounded, size: 20),
            label: const Text('Удалить пару и стереть все данные навсегда'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
