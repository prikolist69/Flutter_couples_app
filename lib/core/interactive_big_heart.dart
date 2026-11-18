import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'heart_skin_config.dart';

class InteractiveBigHeart extends StatefulWidget {
  final VoidCallback onHeartTap;
  final ValueChanged<bool> onTouchHolding;
  final bool isPartnerTouching;
  final String activeSkinId;
  final int streakDays;
  final ValueChanged<String>? onSkinChanged;

  const InteractiveBigHeart({
    super.key,
    required this.onHeartTap,
    required this.onTouchHolding,
    this.isPartnerTouching = false,
    this.activeSkinId = 'rose_bloom',
    this.streakDays = 1,
    this.onSkinChanged,
  });

  @override
  State<InteractiveBigHeart> createState() => _InteractiveBigHeartState();
}

class _InteractiveBigHeartState extends State<InteractiveBigHeart>
    with TickerProviderStateMixin {
  late AnimationController _heartbeatController;
  late Animation<double> _heartbeatScale;
  late AnimationController _waveController;
  late AnimationController _pressSpringController;
  late Animation<double> _springScale;
  late AnimationController _sparkleController;
  final List<_SparkleParticle> _particles = [];

  bool _isHolding = false;
  Timer? _hapticLoopTimer;
  int _localTapCount = 0;

  @override
  void initState() {
    super.initState();

    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    _heartbeatScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.08,
          end: 0.98,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.98,
          end: 1.04,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.04,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 45,
      ),
    ]).animate(_heartbeatController);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _pressSpringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _springScale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(
        parent: _pressSpringController,
        curve: Curves.easeOutQuad,
        reverseCurve: Curves.elasticOut,
      ),
    );

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void didUpdateWidget(covariant InteractiveBigHeart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isBothNow = widget.isPartnerTouching && _isHolding;
    final wasBothBefore = oldWidget.isPartnerTouching && _isHolding;

    if (isBothNow && !wasBothBefore) {
      _triggerSparkles();
      _startSyncVibration();
    } else if (!isBothNow && wasBothBefore) {
      _stopSyncVibration();
    }
  }

  void _triggerSparkles() {
    final skin = HeartSkinConfig.getById(widget.activeSkinId);
    final rand = Random();
    _particles.clear();
    for (int i = 0; i < 20; i++) {
      final angle = (i * (2 * pi / 20)) + (rand.nextDouble() * 0.2);
      final speed = 75.0 + rand.nextDouble() * 60.0;
      final size = 4.0 + rand.nextDouble() * 5.0;
      final color = skin.sparkleColors[rand.nextInt(skin.sparkleColors.length)];
      _particles.add(
        _SparkleParticle(angle: angle, speed: speed, size: size, color: color),
      );
    }
    _sparkleController.forward(from: 0.0);
  }

  void _startSyncVibration() {
    _hapticLoopTimer?.cancel();
    HapticFeedback.heavyImpact();
    _hapticLoopTimer = Timer.periodic(const Duration(milliseconds: 550), (_) {
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 140), () {
        HapticFeedback.lightImpact();
      });
    });
  }

  void _stopSyncVibration() {
    _hapticLoopTimer?.cancel();
    _hapticLoopTimer = null;
  }

  @override
  void dispose() {
    _stopSyncVibration();
    _heartbeatController.dispose();
    _waveController.dispose();
    _pressSpringController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    setState(() => _isHolding = true);
    _pressSpringController.forward();
    HapticFeedback.heavyImpact();
    widget.onTouchHolding(true);

    if (widget.isPartnerTouching) {
      _triggerSparkles();
      _startSyncVibration();
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _releaseHold();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _releaseHold();
  }

  void _releaseHold() {
    if (!_isHolding) return;
    setState(() {
      _isHolding = false;
      _localTapCount++;
    });
    _stopSyncVibration();
    _pressSpringController.reverse();
    widget.onTouchHolding(false);
    widget.onHeartTap();
  }

  void _openSkinSelectorModal() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Text(
                    'Коллекция обликов сердца',
                    style: GoogleFonts.rubik(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Заходите каждый день и держите связь, чтобы открывать редкие скины!',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 18),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: HeartSkinConfig.allSkins.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final skin = HeartSkinConfig.allSkins[idx];
                    final isUnlocked = widget.streakDays >= skin.requiredStreak;
                    final isSelected = widget.activeSkinId == skin.id;

                    return GestureDetector(
                      onTap: () {
                        if (isUnlocked) {
                          HapticFeedback.selectionClick();
                          widget.onSkinChanged?.call(skin.id);
                          Navigator.pop(ctx);
                        } else {
                          HapticFeedback.heavyImpact();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? skin.gradientColors.first.withValues(
                                  alpha: 0.12,
                                )
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? skin.gradientColors.first
                                : Colors.black.withValues(alpha: 0.08),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: skin.gradientColors,
                                ),
                              ),
                              child: Icon(
                                isUnlocked
                                    ? skin.icon
                                    : Icons.lock_outline_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        skin.name,
                                        style: GoogleFonts.rubik(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 8),
                                        const Text(
                                          '🔥 Активен',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepOrange,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isUnlocked
                                        ? skin.description
                                        : 'Откроется на ${skin.requiredStreak}-й день серии (сейчас ${widget.streakDays})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isUnlocked
                                          ? Colors.grey.shade600
                                          : Colors.red.shade400,
                                      fontWeight: isUnlocked
                                          ? FontWeight.normal
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final skin = HeartSkinConfig.getById(widget.activeSkinId);
    final isBothTouching = _isHolding && widget.isPartnerTouching;

    return Column(
      children: [
        // Бейдж стрика и выбора скина
        GestureDetector(
          onTap: _openSkinSelectorModal,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: skin.shadowColor.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: skin.shadowColor.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  'Серия: ${widget.streakDays} дн. • ${skin.name}',
                  style: GoogleFonts.rubik(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: skin.gradientColors.last,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ).animate().scale(duration: 300.ms),

        const SizedBox(height: 12),

        Listener(
          onPointerDown: _onPointerDown,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Расходящиеся волны
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: const Size(240, 240),
                      painter: _RippleWavePainter(
                        progress: _waveController.value,
                        isPartnerOnline: widget.isPartnerTouching,
                        isSync: isBothTouching,
                        baseColor: isBothTouching
                            ? skin.syncColor
                            : (widget.isPartnerTouching
                                  ? Colors.amberAccent
                                  : skin.waveColor),
                      ),
                    );
                  },
                ),

                // 2. Искры
                AnimatedBuilder(
                  animation: _sparkleController,
                  builder: (context, _) {
                    if (!_sparkleController.isAnimating)
                      return const SizedBox.shrink();
                    return CustomPaint(
                      size: const Size(240, 240),
                      painter: _SparklesPainter(
                        progress: _sparkleController.value,
                        particles: _particles,
                      ),
                    );
                  },
                ),

                // 3. Сердце
                AnimatedBuilder(
                  animation: Listenable.merge([_heartbeatScale, _springScale]),
                  builder: (context, child) {
                    final scale =
                        _heartbeatScale.value *
                        _springScale.value *
                        (isBothTouching ? 1.08 : 1.0);
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 146,
                    height: 146,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isBothTouching
                            ? [
                                Colors.white,
                                skin.syncColor,
                                skin.gradientColors.last,
                              ]
                            : skin.gradientColors,
                        stops: const [0.15, 0.65, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isBothTouching
                                      ? skin.syncColor
                                      : skin.shadowColor)
                                  .withValues(
                                    alpha: isBothTouching ? 0.8 : 0.45,
                                  ),
                          blurRadius: isBothTouching ? 50 : 34,
                          spreadRadius: isBothTouching ? 8 : 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 18,
                          child: Container(
                            width: 56,
                            height: 22,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                        Icon(
                          skin.icon,
                          size: isBothTouching ? 82 : 74,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        if (isBothTouching)
          Text(
            'Связь в унисон! Держитесь вместе ✨',
            style: GoogleFonts.rubik(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: skin.syncColor,
            ),
          ).animate().shimmer(duration: 900.ms)
        else if (widget.isPartnerTouching)
          Text(
                'Половинка прямо сейчас держит сердце! Скорее прикоснись! ❤️',
                textAlign: TextAlign.center,
                style: GoogleFonts.rubik(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.05, duration: 600.ms)
        else
          Text(
            _isHolding
                ? 'Держи палец для связи...'
                : 'Прикоснись или зажми сердце',
            style: GoogleFonts.rubik(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF232533),
            ),
          ),

        const SizedBox(height: 4),
        Text(
          isBothTouching
              ? 'Вибрация бьётся в ритме сердец'
              : (_localTapCount == 0
                    ? 'Тапни для нежного тыка или зажми для пульса'
                    : 'Отправлено $_localTapCount ${_localTapCount % 10 == 1 && _localTapCount % 100 != 11 ? "пульс" : "пульсов"} любви ❤️'),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RippleWavePainter extends CustomPainter {
  final double progress;
  final bool isPartnerOnline;
  final bool isSync;
  final Color baseColor;

  _RippleWavePainter({
    required this.progress,
    required this.isPartnerOnline,
    required this.isSync,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress + (i * 0.33)) % 1.0;
      final radius = 74.0 + (waveProgress * 42.0);
      final opacity =
          (1.0 - waveProgress).clamp(0.0, 1.0) * (isSync ? 0.55 : 0.35);

      final paint = Paint()
        ..color = baseColor.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSync ? 3.0 : 2.0;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RippleWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPartnerOnline != isPartnerOnline ||
        oldDelegate.isSync != isSync ||
        oldDelegate.baseColor != baseColor;
  }
}

class _SparkleParticle {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  _SparkleParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class _SparklesPainter extends CustomPainter {
  final double progress;
  final List<_SparkleParticle> particles;

  _SparklesPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ease = Curves.easeOutCubic.transform(progress);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in particles) {
      final distance = 75.0 + (p.speed * ease);
      final dx = center.dx + cos(p.angle) * distance;
      final dy = center.dy + sin(p.angle) * distance;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(dx, dy),
        p.size * (1.0 - (progress * 0.5)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
