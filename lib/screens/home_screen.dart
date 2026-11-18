import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/supabase_client.dart';
import '../core/theme.dart';
import '../core/bouncing_card.dart';
import '../core/heart_burst.dart';
import '../core/pulsing_heart.dart';
import '../core/interactive_big_heart.dart';
import '../core/blind_notes_card.dart';
import 'activities_tab.dart';
import 'status_tab.dart';
import 'coupons_tab.dart';
import 'wishlist_tab.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final String pairId;
  final String userName;

  const HomeScreen({super.key, required this.pairId, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  DateTime? _startDate;
  String _partner1Name = 'Я';
  String _partner2Name = 'Половинка';
  String _partner2Emoji = '✨';
  String _partner2Activity = 'Отдыхает';
  DateTime? _lastKnownPulse;
  bool _isPartnerTouching = false;
  Timer? _heartbeatSyncTimer;

  int _streakDays = 1;
  String _activeSkinId = 'rose_bloom';

  StreamSubscription? _pairSubscription;

  @override
  void initState() {
    super.initState();
    _fetchPairDetails();
    _subscribeToPairRealtime();
  }

  @override
  void dispose() {
    _heartbeatSyncTimer?.cancel();
    _pairSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToPairRealtime() {
    _pairSubscription = supabase
        .from('pairs')
        .stream(primaryKey: ['id'])
        .eq('id', widget.pairId)
        .listen((data) {
          if (data.isNotEmpty && mounted) {
            final row = data.first;
            final incomingPulseStr = row['last_pulse'];

            if (incomingPulseStr != null) {
              final incomingPulse = DateTime.parse(incomingPulseStr);
              if (_lastKnownPulse != null &&
                  incomingPulse.isAfter(_lastKnownPulse!)) {
                HapticFeedback.heavyImpact();
                HeartBurstOverlay.of(context)?.spawnHearts();
              }
              _lastKnownPulse = incomingPulse;
            }

            final p2TouchStr = row['partner2_touch_at'];
            bool partnerActive = false;
            if (p2TouchStr != null) {
              final p2Time = DateTime.parse(p2TouchStr);
              partnerActive = DateTime.now().difference(p2Time).inSeconds < 4;
            }

            setState(() {
              _isPartnerTouching = partnerActive;
              _partner1Name = row['partner1_name'] ?? widget.userName;
              _partner2Name = row['partner2_name'] ?? 'Половинка';
              _partner2Emoji = row['partner2_mood'] ?? '✨';
              _partner2Activity = row['partner2_activity'] ?? 'Отдыхает';
              _streakDays = row['streak_days'] ?? 1;
              _activeSkinId = row['active_heart_skin'] ?? 'rose_bloom';

              if (row['start_date'] != null) {
                _startDate = DateTime.parse(row['start_date']);
              }
            });
          }
        });
  }

  Future<void> _fetchPairDetails() async {
    try {
      final res = await supabase
          .from('pairs')
          .select()
          .eq('id', widget.pairId)
          .single();

      if (mounted) {
        setState(() {
          if (res['start_date'] != null) {
            _startDate = DateTime.parse(res['start_date']);
          }
          _partner1Name = res['partner1_name'] ?? widget.userName;
          _partner2Name = res['partner2_name'] ?? 'Половинка';
          _partner2Emoji = res['partner2_mood'] ?? '✨';
          _partner2Activity = res['partner2_activity'] ?? 'Отдыхает';
          _streakDays = res['streak_days'] ?? 1;
          _activeSkinId = res['active_heart_skin'] ?? 'rose_bloom';

          if (res['last_pulse'] != null) {
            _lastKnownPulse = DateTime.parse(res['last_pulse']);
          }
        });
      }
    } catch (_) {}
  }

  void _handleHeartHolding(bool isHolding) {
    _heartbeatSyncTimer?.cancel();
    if (isHolding) {
      _sendHeartbeatSignal();
      _heartbeatSyncTimer = Timer.periodic(const Duration(milliseconds: 1500), (
        _,
      ) {
        _sendHeartbeatSignal();
      });
    } else {
      _clearHeartbeatSignal();
    }
  }

  Future<void> _sendHeartbeatSignal() async {
    try {
      await supabase
          .from('pairs')
          .update({'partner1_touch_at': DateTime.now().toIso8601String()})
          .eq('id', widget.pairId);
    } catch (_) {}
  }

  Future<void> _clearHeartbeatSignal() async {
    try {
      await supabase
          .from('pairs')
          .update({'partner1_touch_at': null})
          .eq('id', widget.pairId);
    } catch (_) {}
  }

  Future<void> _sendLovePulse() async {
    HapticFeedback.heavyImpact();
    HeartBurstOverlay.of(context)?.spawnHearts();

    try {
      await supabase
          .from('pairs')
          .update({'last_pulse': DateTime.now().toIso8601String()})
          .eq('id', widget.pairId);
    } catch (_) {}
  }

  Future<void> _changeHeartSkin(String newSkinId) async {
    setState(() => _activeSkinId = newSkinId);
    try {
      await supabase
          .from('pairs')
          .update({'active_heart_skin': newSkinId})
          .eq('id', widget.pairId);
    } catch (_) {}
  }

  void _openNamesModal() {
    final p1Controller = TextEditingController(text: _partner1Name);
    final p2Controller = TextEditingController(text: _partner2Name);

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
            Text(
              'Персонализация пары ✨',
              style: GoogleFonts.rubik(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: p1Controller,
              decoration: InputDecoration(
                labelText: 'Твоё имя',
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: p2Controller,
              decoration: InputDecoration(
                labelText: 'Имя второй половинки',
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final n1 = p1Controller.text.trim();
                final n2 = p2Controller.text.trim();
                if (n1.isEmpty || n2.isEmpty) return;

                setState(() {
                  _partner1Name = n1;
                  _partner2Name = n2;
                });

                await supabase
                    .from('pairs')
                    .update({'partner1_name': n1, 'partner2_name': n2})
                    .eq('id', widget.pairId);

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Сохранить имена'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusDetailDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.accentPeach,
                shape: BoxShape.circle,
              ),
              child: Text(_partner2Emoji, style: const TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 16),
            Text(
              _partner2Name,
              style: GoogleFonts.rubik(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Сейчас: $_partner2Activity',
              textAlign: TextAlign.center,
              style: GoogleFonts.rubik(
                fontSize: 15,
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _currentIndex = 2); // переход на вкладку Статус
              },
              child: const Text('Сменить свой статус'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateDirectly() async {
    HapticFeedback.lightImpact();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'ДАТА НАЧАЛА ОТНОШЕНИЙ',
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

    if (picked != null && picked != _startDate) {
      setState(() => _startDate = picked);
      final formatted =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      await supabase
          .from('pairs')
          .update({'start_date': formatted})
          .eq('id', widget.pairId);
    }
  }

  int get _daysTogether {
    if (_startDate == null) return 0;
    final diff = DateTime.now().difference(_startDate!).inDays;
    return diff >= 0 ? diff : 0;
  }

  String _formatDays(int days) {
    if (_startDate == null) return 'Укажите дату';
    if (days % 10 == 1 && days % 100 != 11) return '$days день';
    if ([2, 3, 4].contains(days % 10) && ![12, 13, 14].contains(days % 100)) {
      return '$days дня';
    }
    return '$days дней';
  }

  @override
  Widget build(BuildContext context) {
    return HeartBurstOverlay(
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 18,
          title: Row(
            children: [
              // 1. Имена пары
              BouncingWidget(
                onTap: _openNamesModal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_partner1Name & $_partner2Name',
                      style: GoogleFonts.rubik(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.edit_rounded,
                      size: 12,
                      color: AppTheme.textMuted,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 2. Dynamic Island: светящаяся пилюля статуса половинки
              BouncingWidget(
                onTap: _showStatusDetailDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF0F5), Color(0xFFFFE3EA)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00E676),
                              shape: BoxShape.circle,
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1.3, 1.3),
                            duration: 900.ms,
                          ),
                      const SizedBox(width: 6),
                      Text(
                        _partner2Emoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 5),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 75),
                        child: Text(
                          _partner2Activity,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.rubik(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.settings_outlined,
                color: AppTheme.textDark,
                size: 22,
              ),
              onPressed: () async {
                HapticFeedback.lightImpact();
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      pairId: widget.pairId,
                      initialDate: _startDate,
                    ),
                  ),
                );
                _fetchPairDetails();
              },
            ),
          ],
          backgroundColor: Colors.transparent,
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildDashboardTab(),
            ActivitiesTab(pairId: widget.pairId, partnerName: _partner2Name),
            StatusTab(pairId: widget.pairId, userName: widget.userName),
            CouponsTab(pairId: widget.pairId),
            WishlistTab(pairId: widget.pairId),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          elevation: 0,
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.primary.withValues(alpha: 0.15),
          onDestinationSelected: (idx) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = idx);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.favorite_border_rounded),
              selectedIcon: Icon(
                Icons.favorite_rounded,
                color: AppTheme.primary,
              ),
              label: 'Главная',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.primary,
              ),
              label: 'Игры',
            ),
            NavigationDestination(
              icon: Icon(Icons.radar_outlined),
              selectedIcon: Icon(Icons.radar_rounded, color: AppTheme.primary),
              label: 'Статус',
            ),
            NavigationDestination(
              icon: Icon(Icons.confirmation_number_outlined),
              selectedIcon: Icon(
                Icons.confirmation_number_rounded,
                color: AppTheme.primary,
              ),
              label: 'Купоны',
            ),
            NavigationDestination(
              icon: Icon(Icons.checklist_rounded),
              selectedIcon: Icon(
                Icons.checklist_rounded,
                color: AppTheme.primary,
              ),
              label: 'Планы',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BouncingWidget(
            onTap: _pickDateDirectly,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: AppTheme.loveGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.32),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Мы вместе уже',
                        style: GoogleFonts.rubik(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const PulsingHeartIcon(size: 16, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDays(_daysTogether),
                    style: GoogleFonts.rubik(
                      color: Colors.white,
                      fontSize: _startDate != null ? 40 : 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ).animate().scale(
                    duration: 400.ms,
                    curve: Curves.easeOutBack,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _startDate != null
                          ? 'Нажми, чтобы изменить дату'
                          : 'Нажми, чтобы выбрать дату ✨',
                      style: GoogleFonts.rubik(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.08, end: 0),

          const SizedBox(height: 24),

          InteractiveBigHeart(
                onHeartTap: _sendLovePulse,
                onTouchHolding: _handleHeartHolding,
                isPartnerTouching: _isPartnerTouching,
                activeSkinId: _activeSkinId,
                streakDays: _streakDays,
                onSkinChanged: _changeHeartSkin,
              )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.9, 0.9)),

          const SizedBox(height: 28),

          BlindNotesCard(
            pairId: widget.pairId,
            userName: _partner1Name,
            partnerName: _partner2Name,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
