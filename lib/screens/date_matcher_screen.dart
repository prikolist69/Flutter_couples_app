import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/supabase_client.dart';
import '../core/theme.dart';
import '../core/bouncing_card.dart';

class MatchCard {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final String category;

  const MatchCard({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.category,
  });
}

class DateMatcherScreen extends StatefulWidget {
  final String pairId;
  final String partnerName;

  const DateMatcherScreen({
    super.key,
    required this.pairId,
    required this.partnerName,
  });

  @override
  State<DateMatcherScreen> createState() => _DateMatcherScreenState();
}

class _DateMatcherScreenState extends State<DateMatcherScreen>
    with SingleTickerProviderStateMixin {
  int _cardIndex = 0;
  String _selectedCategory = 'date';

  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0.0;
  bool _isAnimatingOut = false;

  late AnimationController _springController;
  late Animation<Offset> _springAnimation;

  static const List<MatchCard> _dateCards = [
    MatchCard(
      id: 'd1',
      title: 'Ночная автопрогулка',
      subtitle: 'Кофе на заправке, огни города и любимый плейлист',
      emoji: '🚗',
      category: 'date',
    ),
    MatchCard(
      id: 'd2',
      title: 'Уютный вечер кино',
      subtitle: 'Огромная миска попкорна, плед и фильм на выбор',
      emoji: '🍿',
      category: 'date',
    ),
    MatchCard(
      id: 'd3',
      title: 'Прогулка по набережной',
      subtitle: 'Взять горячий чай в термосе и болтать обо всём',
      emoji: '🌊',
      category: 'date',
    ),
    MatchCard(
      id: 'd4',
      title: 'Поход в уютную кофейню',
      subtitle: 'Найти новое классное место и заказать десерт',
      emoji: '☕',
      category: 'date',
    ),
    MatchCard(
      id: 'd5',
      title: 'Совместная готовка дома',
      subtitle: 'Приготовить домашнюю пасту или пиццу под музыку',
      emoji: '🍝',
      category: 'date',
    ),
    MatchCard(
      id: 'd6',
      title: 'Поездка за город на выходные',
      subtitle: 'Сменить обстановку, свежий воздух и закат',
      emoji: '🌲',
      category: 'date',
    ),
  ];

  static const List<MatchCard> _foodCards = [
    MatchCard(
      id: 'f1',
      title: 'Большая сочная пицца',
      subtitle: 'Сырные бортики, любимые топпинги и соусы',
      emoji: '🍕',
      category: 'food',
    ),
    MatchCard(
      id: 'f2',
      title: 'Роллы и суши сет',
      subtitle: 'Филадельфия, запечённые роллы и соевый соус',
      emoji: '🍱',
      category: 'food',
    ),
    MatchCard(
      id: 'f3',
      title: 'Бургеры и картошка фри',
      subtitle: 'Хрустящий картофель и двойной бургер',
      emoji: '🍔',
      category: 'food',
    ),
    MatchCard(
      id: 'f4',
      title: 'Горячий наваристый рамен',
      subtitle: 'Пряный бульон, лапша и яйцо в соевом маринаде',
      emoji: '🍜',
      category: 'food',
    ),
    MatchCard(
      id: 'f5',
      title: 'Вкусный стейк с овощами',
      subtitle: 'Мясо на гриле с хрустящей корочкой',
      emoji: '🥩',
      category: 'food',
    ),
  ];

  List<MatchCard> get _currentCards =>
      _selectedCategory == 'date' ? _dateCards : _foodCards;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimatingOut) return;
    setState(() {
      _dragOffset += details.delta;
      _dragAngle = (_dragOffset.dx / 300) * (pi / 12);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isAnimatingOut) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.32;

    if (_dragOffset.dx > threshold) {
      _swipeOut(liked: true);
    } else if (_dragOffset.dx < -threshold) {
      _swipeOut(liked: false);
    } else {
      // Возврат назад пружиной
      _springAnimation = Tween<Offset>(begin: _dragOffset, end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _springController,
              curve: Curves.easeOutBack,
            ),
          );

      _springController.forward(from: 0.0).then((_) {
        setState(() {
          _dragOffset = Offset.zero;
          _dragAngle = 0.0;
        });
      });
    }
  }

  void _swipeOut({required bool liked}) {
    _isAnimatingOut = true;
    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = liked ? screenWidth * 1.5 : -screenWidth * 1.5;

    _springAnimation =
        Tween<Offset>(
          begin: _dragOffset,
          end: Offset(targetX, _dragOffset.dy * 1.2),
        ).animate(
          CurvedAnimation(
            parent: _springController,
            curve: Curves.easeOutCubic,
          ),
        );

    _springController.forward(from: 0.0).then((_) {
      final currentCard = _currentCards[_cardIndex];
      _handleVote(currentCard, liked);

      setState(() {
        _dragOffset = Offset.zero;
        _dragAngle = 0.0;
        _isAnimatingOut = false;
        _cardIndex++;
      });
    });
  }

  Future<void> _handleVote(MatchCard card, bool liked) async {
    HapticFeedback.mediumImpact();

    if (liked) {
      try {
        final existing = await supabase
            .from('pair_matches')
            .select()
            .eq('pair_id', widget.pairId)
            .eq('card_id', card.id)
            .maybeSingle();

        if (existing == null) {
          await supabase.from('pair_matches').insert({
            'pair_id': widget.pairId,
            'card_id': card.id,
            'title': card.title,
            'category': card.category,
            'partner1_liked': true,
          });
        } else {
          final bool partner2Liked = existing['partner2_liked'] == true;
          if (partner2Liked) {
            await supabase
                .from('pair_matches')
                .update({'partner1_liked': true, 'is_matched': true})
                .eq('id', existing['id']);

            _showMatchCelebration(card);
          } else {
            await supabase
                .from('pair_matches')
                .update({'partner1_liked': true})
                .eq('id', existing['id']);
          }
        }
      } catch (_) {}
    }
  }

  void _showMatchCelebration(MatchCard card) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Text(card.emoji, style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 14),
            Text(
              'ЭТО МЭТЧ! 🎉',
              style: GoogleFonts.rubik(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Вы оба выбрали:\n«${card.title}»',
              textAlign: TextAlign.center,
              style: GoogleFonts.rubik(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Идеальный план на сегодня найден без споров ✨',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Супер! Идём дальше'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = _currentCards;
    final isFinished = _cardIndex >= cards.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Мэтчер для двоих ✨',
          style: GoogleFonts.rubik(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Переключатель Свидания / Еда
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedCategory = 'date';
                          _cardIndex = 0;
                          _dragOffset = Offset.zero;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedCategory == 'date'
                              ? AppTheme.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '🎯 Свидания',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedCategory == 'date'
                                ? Colors.white
                                : AppTheme.textDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedCategory = 'food';
                          _cardIndex = 0;
                          _dragOffset = Offset.zero;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedCategory == 'food'
                              ? AppTheme.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '🍕 Что едим',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedCategory == 'food'
                                ? Colors.white
                                : AppTheme.textDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Стек с интерактивными карточками
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: isFinished
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('✨', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              'Карточки закончились!',
                              style: GoogleFonts.rubik(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Когда ${widget.partnerName} тоже закончит выбор, вы увидите совпадения.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => setState(() {
                                _cardIndex = 0;
                                _dragOffset = Offset.zero;
                              }),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Пройти заново'),
                            ),
                          ],
                        ),
                      )
                    : Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // Фоновая карточка следующего элемента для глубины стека
                          if (_cardIndex + 1 < cards.length)
                            Transform.scale(
                              scale: 0.94,
                              child: _buildCardView(
                                cards[_cardIndex + 1],
                                isBackground: true,
                              ),
                            ),

                          // Верхняя активная свайпаемая карточка
                          GestureDetector(
                            onPanUpdate: _onPanUpdate,
                            onPanEnd: _onPanEnd,
                            child: AnimatedBuilder(
                              animation: _springController,
                              builder: (context, child) {
                                final currentOffset =
                                    _springController.isAnimating
                                    ? _springAnimation.value
                                    : _dragOffset;
                                final currentAngle =
                                    _springController.isAnimating
                                    ? (currentOffset.dx / 300) * (pi / 12)
                                    : _dragAngle;

                                return Transform.translate(
                                  offset: currentOffset,
                                  child: Transform.rotate(
                                    angle: currentAngle,
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildCardView(cards[_cardIndex]),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // Кнопки дублирования тапом
            if (!isFinished)
              Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 40, right: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Смахнуть влево
                    BouncingWidget(
                      onTap: () {
                        if (!_isAnimatingOut) _swipeOut(liked: false);
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 32,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),

                    // Смахнуть вправо
                    BouncingWidget(
                      onTap: () {
                        if (!_isAnimatingOut) _swipeOut(liked: true);
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppTheme.loveGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardView(MatchCard card, {bool isBackground = false}) {
    final dragX = _dragOffset.dx;
    final likeOpacity = isBackground ? 0.0 : (dragX / 100).clamp(0.0, 1.0);
    final nopeOpacity = isBackground ? 0.0 : (-dragX / 100).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(
              alpha: isBackground ? 0.03 : 0.09,
            ),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPeach,
                    shape: BoxShape.circle,
                  ),
                  child: Text(card.emoji, style: const TextStyle(fontSize: 66)),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    card.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rubik(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    card.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),

            // Штамп «ХОЧУ!» (при свайпе вправо)
            if (likeOpacity > 0.05)
              Positioned(
                top: 30,
                right: 30,
                child: Opacity(
                  opacity: likeOpacity,
                  child: Transform.rotate(
                    angle: 0.15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ХОЧУ! ❤️',
                        style: GoogleFonts.rubik(
                          color: Colors.green,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Штамп «НЕ СЕЙЧАС» (при свайпе влево)
            if (nopeOpacity > 0.05)
              Positioned(
                top: 30,
                left: 30,
                child: Opacity(
                  opacity: nopeOpacity,
                  child: Transform.rotate(
                    angle: -0.15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.redAccent, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'НЕ СЕЙЧАС ✖',
                        style: GoogleFonts.rubik(
                          color: Colors.redAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
