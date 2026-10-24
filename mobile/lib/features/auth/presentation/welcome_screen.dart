import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/motion.dart';
import '../../../core/ui/emoji.dart';
import '../../../core/ui/rise_in.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final PageController _pages = PageController();
  Timer? _timer;
  var _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  void _syncTimer() {
    _timer?.cancel();
    _timer = null;
    if (!animationsEnabled(context)) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pages.hasClients) {
        return;
      }
      final next =
          (_index + 1) % _slidesOf(AppLocalizations.of(context)).length;
      unawaited(
        _pages.animateToPage(
          next,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        ),
      );
    });
  }

  void _onPage(int index) {
    setState(() => _index = index);
    _syncTimer();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final slides = _slidesOf(l10n);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final scaler = MediaQuery.textScalerOf(context).scale(1);
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: colors.heroGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              const padding = EdgeInsets.fromLTRB(22, 16, 22, 24);
              return SingleChildScrollView(
                padding: padding,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(
                      0,
                      constraints.maxHeight - padding.vertical,
                    ),
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: <Widget>[
                        RiseIn(
                          index: 0,
                          child: Row(
                            children: <Widget>[
                              const Emoji('seedling', size: 30),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  l10n.appTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (kDebugMode)
                                IconButton(
                                  key: const Key('debug-server-check'),
                                  tooltip: 'Server check',
                                  onPressed: () =>
                                      context.go('/dev/server-check'),
                                  icon: const Icon(
                                    Icons.monitor_heart_outlined,
                                    color: Colors.white,
                                  ),
                                ),
                              const Spacer(),
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.15,
                                  ),
                                  minimumSize: const Size(48, 48),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  shape: const StadiumBorder(
                                    side: BorderSide(color: Color(0x40FFFFFF)),
                                  ),
                                ),
                                onPressed: () {
                                  unawaited(
                                    ref.read(localeProvider.notifier).toggle(),
                                  );
                                },
                                child: Text(arabic ? 'English' : 'العربية'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const RiseIn(index: 1, child: _MealOrbit()),
                        const SizedBox(height: 8),
                        RiseIn(
                          index: 2,
                          child: SizedBox(
                            height: 210 * scaler,
                            child: PageView.builder(
                              controller: _pages,
                              itemCount: slides.length,
                              onPageChanged: _onPage,
                              itemBuilder: (BuildContext context, int index) {
                                final slide = slides[index];
                                return SingleChildScrollView(
                                  child: Column(
                                    children: <Widget>[
                                      DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.16,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        child: SizedBox(
                                          width: 56,
                                          height: 56,
                                          child: Center(
                                            child: Emoji(slide.icon, size: 34),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        slide.title,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          height: 1.3,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        slide.body,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          fontSize: 16,
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _Dots(count: slides.length, index: _index),
                        const Spacer(),
                        const SizedBox(height: 16),
                        RiseIn(
                          index: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF0B6B4D),
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () => context.go('/register'),
                                child: Text(l10n.welcomeStart),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(52),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.4),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () => context.go('/login'),
                                child: Text(l10n.welcomeHaveAccount),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide(this.icon, this.title, this.body);

  final String icon;
  final String title;
  final String body;
}

List<_Slide> _slidesOf(AppLocalizations l10n) {
  return <_Slide>[
    _Slide('brain', l10n.welcomeSlide1Title, l10n.welcomeSlide1Body),
    _Slide('alarm-clock', l10n.welcomeSlide2Title, l10n.welcomeSlide2Body),
    _Slide('chart-increasing', l10n.welcomeSlide3Title, l10n.welcomeSlide3Body),
  ];
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedContainer(
              duration: animationsEnabled(context)
                  ? const Duration(milliseconds: 200)
                  : Duration.zero,
              width: i == index ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: i == index ? 1 : 0.45),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
      ],
    );
  }
}

class _MealOrbit extends StatefulWidget {
  const _MealOrbit();

  @override
  State<_MealOrbit> createState() => _MealOrbitState();
}

class _MealOrbitState extends State<_MealOrbit>
    with SingleTickerProviderStateMixin {
  static const _foods = <String>[
    'avocado',
    'fish',
    'broccoli',
    'red-apple',
    'bread',
    'carrot',
    'egg',
    'lemon',
  ];

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 36),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (animationsEnabled(context)) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const box = 250.0;
    const radius = 102.0;
    return SizedBox(
      width: box,
      height: box,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final turn = _controller.value * math.pi * 2;
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              for (var i = 0; i < _foods.length; i++)
                _orbitItem(
                  box: box,
                  radius: radius,
                  angle: turn + i * math.pi * 2 / _foods.length,
                  child: Emoji(_foods[i], size: 32),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 112,
                  height: 112,
                  child: Center(child: Emoji('green-salad', size: 78)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _orbitItem({
    required double box,
    required double radius,
    required double angle,
    required Widget child,
  }) {
    final dx = math.cos(angle) * radius;
    final dy = math.sin(angle) * radius;
    return Positioned(
      left: box / 2 + dx - 16,
      top: box / 2 + dy - 16,
      child: child,
    );
  }
}
