import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/supabase_client.dart';
import '../core/theme.dart';
import '../core/bouncing_card.dart';

class CouponsTab extends StatefulWidget {
  final String pairId;

  const CouponsTab({super.key, required this.pairId});

  @override
  State<CouponsTab> createState() => _CouponsTabState();
}

class _CouponsTabState extends State<CouponsTab> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedEmoji = '🎟️';
  bool _isCreating = false;

  final _emojiPicker = const [
    '🎟️',
    '💆‍♂️',
    '☕',
    '🍕',
    '🎬',
    '🚗',
    '🧸',
    '🍦',
    '🎮',
    '✨',
  ];

  static const _defaultCoupons = [
    {
      'title': 'Расслабляющий массаж',
      'desc': 'Действует 20 минут в любой вечер без права на отказ',
      'emoji': '💆‍♂️',
    },
    {
      'title': 'Кофе и завтрак в постель',
      'desc': 'Любимый напиток и вкусняшка прямо с утра под одеяло',
      'emoji': '☕',
    },
    {
      'title': 'Полный выбор фильма',
      'desc': 'Никаких споров: сегодня смотрим то, что выбираешь ты',
      'emoji': '🎬',
    },
    {
      'title': 'Освобождение от дел',
      'desc': 'Право не мыть посуду и не готовить весь вечер',
      'emoji': '🍕',
    },
    {
      'title': 'Ночная автопрогулка',
      'desc': 'Поездка по вечернему городу под твой любимый плейлист',
      'emoji': '🚗',
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _populateDefaultCoupons() async {
    HapticFeedback.mediumImpact();
    setState(() => _isCreating = true);

    try {
      final inserts = _defaultCoupons
          .map(
            (c) => {
              'pair_id': widget.pairId,
              'title': c['title'],
              'description': c['desc'],
              'emoji': c['emoji'],
              'is_redeemed': false,
            },
          )
          .toList();

      await supabase.from('pair_coupons').insert(inserts);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _openCreateCouponModal() {
    _titleController.clear();
    _descController.clear();
    _selectedEmoji = '🎟️';
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
                          child: Text(
                            _selectedEmoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Новый купон любви ✨',
                          style: GoogleFonts.rubik(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _emojiPicker.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 6),
                        itemBuilder: (context, idx) {
                          final em = _emojiPicker[idx];
                          final isSel = em == _selectedEmoji;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setModalState(() => _selectedEmoji = em);
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSel
                                    ? AppTheme.primary.withValues(alpha: 0.15)
                                    : AppTheme.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSel
                                      ? AppTheme.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                em,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      maxLength: 40,
                      decoration: InputDecoration(
                        labelText: 'Название купона',
                        hintText: 'Например: Поцелуй вне очереди',
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
                      controller: _descController,
                      maxLength: 80,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Условия действия',
                        hintText:
                            'Когда и как половинка может его активировать...',
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
                      onPressed: _isCreating ? null : () => _submitCoupon(ctx),
                      child: _isCreating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Создать купон'),
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

  Future<void> _submitCoupon(BuildContext modalContext) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isCreating = true);
    HapticFeedback.mediumImpact();

    try {
      await supabase.from('pair_coupons').insert({
        'pair_id': widget.pairId,
        'title': title,
        'description': _descController.text.trim(),
        'emoji': _selectedEmoji,
        'is_redeemed': false,
      });

      if (modalContext.mounted) Navigator.pop(modalContext);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _redeemCoupon(Map<String, dynamic> coupon) async {
    final bool isAlreadyRedeemed = coupon['is_redeemed'] ?? false;
    if (isAlreadyRedeemed) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          'Активировать купон? 🎟️',
          style: GoogleFonts.rubik(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '«${coupon['title']}»\n\nКупон будет отмечен как использованный.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Использовать'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    HapticFeedback.heavyImpact();
    try {
      await supabase
          .from('pair_coupons')
          .update({
            'is_redeemed': true,
            'redeemed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', coupon['id']);
    } catch (_) {}
  }

  Future<void> _deleteCoupon(String id) async {
    HapticFeedback.lightImpact();
    try {
      await supabase.from('pair_coupons').delete().eq('id', id);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: supabase
          .from('pair_coupons')
          .stream(primaryKey: ['id'])
          .eq('pair_id', widget.pairId)
          .order('created_at', ascending: true),
      builder: (context, snapshot) {
        final List coupons = [];
        if (snapshot.hasData && snapshot.data != null) {
          final dynamic raw = snapshot.data;
          for (final item in raw) {
            coupons.add(Map<String, dynamic>.from(item as Map));
          }
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppTheme.primary,
            elevation: 3,
            onPressed: _openCreateCouponModal,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              'Создать купон',
              style: GoogleFonts.rubik(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: coupons.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🎟️', style: TextStyle(fontSize: 50)),
                        const SizedBox(height: 14),
                        Text(
                          'У вас пока нет купонов',
                          style: GoogleFonts.rubik(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Добавьте готовый стартовый набор романтичных и заботливых купонов для двоих',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _isCreating
                              ? null
                              : _populateDefaultCoupons,
                          icon: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 18,
                          ),
                          label: const Text('Загрузить готовый набор ✨'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                  itemCount: coupons.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final c = coupons[index] as Map<String, dynamic>;
                    final bool isRedeemed = c['is_redeemed'] ?? false;

                    return Dismissible(
                      key: Key(c['id'].toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        padding: const EdgeInsets.only(right: 20),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red.shade700,
                        ),
                      ),
                      onDismissed: (direction) => _deleteCoupon(c['id']),
                      child: BouncingWidget(
                        onTap: () => _redeemCoupon(c),
                        child: _TicketCard(
                          emoji: c['emoji'] ?? '🎟️',
                          title: c['title'] ?? '',
                          description: c['description'] ?? '',
                          isRedeemed: isRedeemed,
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _TicketCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final bool isRedeemed;

  const _TicketCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.isRedeemed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isRedeemed ? const Color(0xFFF9F9FB) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isRedeemed
              ? Colors.grey.shade300
              : AppTheme.primary.withValues(alpha: 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isRedeemed
                ? Colors.transparent
                : AppTheme.primary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isRedeemed
                          ? Colors.grey.shade100
                          : AppTheme.accentPeach,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      emoji,
                      style: TextStyle(
                        fontSize: 24,
                        color: isRedeemed ? Colors.grey : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.rubik(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            decoration: isRedeemed
                                ? TextDecoration.lineThrough
                                : null,
                            color: isRedeemed
                                ? Colors.grey.shade400
                                : AppTheme.textDark,
                          ),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 12,
                              color: isRedeemed
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isRedeemed
                          ? Colors.grey.shade200
                          : AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isRedeemed ? 'ПОГАШЕН' : 'АКТИВЕН',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: isRedeemed
                            ? Colors.grey.shade500
                            : AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Аккуратный штамп поверх карточки без вылетов
            if (isRedeemed)
              Positioned(
                right: 20,
                bottom: 8,
                child: Transform.rotate(
                  angle: -0.12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.red.shade400,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    child: Text(
                      'ИСПОЛЬЗОВАНО',
                      style: GoogleFonts.rubik(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
