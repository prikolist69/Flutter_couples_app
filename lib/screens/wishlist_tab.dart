import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/supabase_client.dart';
import '../core/theme.dart';
import '../core/bouncing_card.dart';

class WishlistTab extends StatefulWidget {
  final String pairId;

  const WishlistTab({super.key, required this.pairId});

  @override
  State<WishlistTab> createState() => _WishlistTabState();
}

class _WishlistTabState extends State<WishlistTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _titleController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _openAddModal(String category) {
    _titleController.clear();
    HapticFeedback.lightImpact();

    final isDate = category == 'date';

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
                  child: Text(
                    isDate ? '🎯' : '🎁',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isDate
                        ? 'Новая цель или свидание'
                        : 'Новое желание в вишлист',
                    style: GoogleFonts.rubik(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              autofocus: true,
              maxLength: 60,
              decoration: InputDecoration(
                hintText: isDate
                    ? 'Например: встретить рассвет на набережной...'
                    : 'Например: духи, книга, толстовка...',
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
              onPressed: _isSaving ? null : () => _saveItem(category, ctx),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Добавить в список'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveItem(String category, BuildContext modalContext) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      await supabase.from('pair_plans').insert({
        'pair_id': widget.pairId,
        'title': title,
        'category': category,
        'is_completed': false,
      });

      if (modalContext.mounted) {
        Navigator.pop(modalContext);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleComplete(Map<String, dynamic> item) async {
    HapticFeedback.mediumImpact();
    final bool currentStatus = item['is_completed'] ?? false;

    try {
      await supabase
          .from('pair_plans')
          .update({
            'is_completed': !currentStatus,
            'completed_at': !currentStatus
                ? DateTime.now().toIso8601String()
                : null,
          })
          .eq('id', item['id']);
    } catch (_) {}
  }

  Future<void> _deleteItem(String id) async {
    HapticFeedback.lightImpact();
    try {
      await supabase.from('pair_plans').delete().eq('id', id);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Аккуратная капсула табов
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: AppTheme.loveGradient,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle: GoogleFonts.rubik(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: '🎯 Цели и свидания'),
                  Tab(text: '🎁 Вишлист подарков'),
                ],
              ),
            ),
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildCategoryList('date'), _buildCategoryList('wish')],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryList(String category) {
    final isDate = category == 'date';

    return StreamBuilder(
      stream: supabase
          .from('pair_plans')
          .stream(primaryKey: ['id'])
          .eq('pair_id', widget.pairId)
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        final List items = [];
        if (snapshot.hasData && snapshot.data != null) {
          final dynamic raw = snapshot.data;
          for (final e in raw) {
            final map = Map<String, dynamic>.from(e as Map);
            if (map['category'] == category) {
              items.add(map);
            }
          }
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppTheme.primary,
            elevation: 3,
            onPressed: () => _openAddModal(category),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              isDate ? 'Добавить свидание' : 'Добавить желание',
              style: GoogleFonts.rubik(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isDate ? '🗺️' : '✨',
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isDate ? 'Список свиданий пуст' : 'Вишлист пуст',
                          style: GoogleFonts.rubik(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isDate
                              ? 'Добавьте первую совместную поездку или уютное свидание'
                              : 'Запишите подарки и желания, чтобы радовать друг друга',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index] as Map<String, dynamic>;
                    final bool isDone = item['is_completed'] ?? false;

                    return Dismissible(
                      key: Key(item['id'].toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        padding: const EdgeInsets.only(right: 20),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red.shade700,
                        ),
                      ),
                      onDismissed: (direction) => _deleteItem(item['id']),
                      child: BouncingWidget(
                        onTap: () => _toggleComplete(item),
                        child: AnimatedContainer(
                          duration: 250.ms,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDone
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isDone
                                  ? Colors.green.shade100
                                  : Colors.black.withValues(alpha: 0.05),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: 200.ms,
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDone
                                      ? Colors.green
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isDone
                                        ? Colors.green
                                        : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                ),
                                child: isDone
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  item['title'] ?? '',
                                  style: GoogleFonts.rubik(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    decoration: isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: isDone
                                        ? Colors.grey.shade400
                                        : AppTheme.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
