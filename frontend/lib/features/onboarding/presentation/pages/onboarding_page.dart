import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../viewmodels/onboarding_view_model.dart';

const _canvas = Color(0xFFF8FAFC);
const _surface = Colors.white;
const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _line = Color(0xFFE2E8F0);
const _selected = Color(0xFF2563EB);

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  bool _isFinishing = false;

  final _pages = const [
    _OnboardData(
      icon: Icons.electric_meter_outlined,
      badgeLabel: 'چاودێری ڕاستەوخۆ',
      title: 'بەکارهێنانی کارەبا بە وردی ببینە',
      subtitle:
          'بە شێوەی ڕاستەوخۆ بزانە هەر ئامێرێک چەند kWh بەکاردێنێت و زوو ئاگاداربە لە بەشە زۆر-خەرجەکان.',
    ),
    _OnboardData(
      icon: Icons.savings_outlined,
      badgeLabel: 'پێشبینی دینار',
      title: 'تێچووی مانگانە پێشبینی بکە',
      subtitle:
          'پێش ڕۆژی کۆتایی مانگ بزانە چەند دینار دەبێت و پلانی بەدجەتەکەت بە داتا دروست بکە.',
    ),
    _OnboardData(
      icon: Icons.home_outlined,
      badgeLabel: 'کۆنترۆڵی ماڵ',
      title: 'ئامێرەکانی ماڵ بە زیرەکی ڕێکبخە',
      subtitle:
          'کار/وەستان و کاتژمێری بەکارهێنان دابنێ، هۆشداری و ڕێنمایی باشتر وەربگرە بۆ کەمکردنەوەی خەرجی.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _completeAndNavigate() async {
    if (_isFinishing) return;
    _isFinishing = true;
    final success = await ref
        .read(onboardingViewModelProvider.notifier)
        .complete();
    if (!success || !mounted) {
      _isFinishing = false;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/');
    });
  }

  Future<void> _next() async {
    final state = ref.read(onboardingViewModelProvider);
    if (state.pageIndex < _pages.length - 1) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    await _completeAndNavigate();
  }

  Future<void> _back() async {
    final state = ref.read(onboardingViewModelProvider);
    if (state.pageIndex > 0) {
      await _controller.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vmState = ref.watch(onboardingViewModelProvider);
    final isLastPage = vmState.pageIndex == _pages.length - 1;
    final isCompleting = vmState.isCompleting;
    final media = MediaQuery.of(context);
    final responsiveMedia = media.copyWith(
      textScaler: AppResponsive.textScaler(media, min: 0.9, max: 1.16),
    );
    final horizontalPadding = (media.size.width * 0.055).clamp(14.0, 30.0);
    final actionPadding = (media.size.width * 0.03).clamp(9.0, 14.0);

    return MediaQuery(
      data: responsiveMedia,
      child: Scaffold(
        backgroundColor: _canvas,
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    10,
                    horizontalPadding,
                    6,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _line),
                        ),
                        child: Text(
                          'ڕێنمایی سەرەتا',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: _ink,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      const Spacer(),
                      if (!isLastPage)
                        AppButton(
                          label: 'تێپەڕاندن',
                          variant: AppButtonVariant.ghost,
                          textColor: _ink,
                          onPressed: (isCompleting || _isFinishing)
                              ? null
                              : _completeAndNavigate,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          fontSize: 12,
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (index) => ref
                        .read(onboardingViewModelProvider.notifier)
                        .setPage(index),
                    itemCount: _pages.length,
                    itemBuilder: (context, index) => _OnboardSlide(
                      data: _pages[index],
                      isActive: index == vmState.pageIndex,
                    ),
                  ),
                ),
                _Dots(current: vmState.pageIndex, total: _pages.length),
                const SizedBox(height: 6),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    4,
                    horizontalPadding,
                    12,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(actionPadding),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _line),
                    ),
                    child: Row(
                      children: [
                        if (vmState.pageIndex > 0) ...[
                          Expanded(
                            flex: 38,
                            child: AppButton(
                              label: 'گەڕانەوە',
                              variant: AppButtonVariant.neutral,
                              backgroundColor: _surface,
                              textColor: _ink,
                              borderColor: _line,
                              onPressed: (isCompleting || _isFinishing)
                                  ? null
                                  : _back,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              borderRadius: 11,
                              fontSize: 12,
                              icon: Icons.arrow_forward,
                              iconSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          flex: 62,
                          child: AppButton(
                            label: isLastPage ? 'دەستپێکردن' : 'بەردەوامبوون',
                            variant: AppButtonVariant.neutral,
                            backgroundColor: const Color(0xFFF1F5F9),
                            textColor: _ink,
                            borderColor: _ink,
                            onPressed: (isCompleting || _isFinishing)
                                ? null
                                : _next,
                            isLoading: isCompleting,
                            icon: isLastPage
                                ? Icons.check_circle_outline
                                : Icons.arrow_back,
                            iconSize: 17,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 11,
                            ),
                            borderRadius: 12,
                            fontSize: 12.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardSlide extends StatelessWidget {
  const _OnboardSlide({required this.data, required this.isActive});

  final _OnboardData data;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxCardWidth = constraints.maxWidth.clamp(0.0, 620.0);
        final compact =
            constraints.maxHeight < 620 || constraints.maxWidth < 350;
        final imageHeight = (constraints.maxHeight * (compact ? 0.34 : 0.4))
            .clamp(180.0, 290.0)
            .toDouble();
        final titleSize = (constraints.maxWidth * 0.062)
            .clamp(21.0, 29.0)
            .toDouble();
        final subtitleSize = (constraints.maxWidth * 0.038)
            .clamp(13.0, 16.0)
            .toDouble();
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxCardWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                (constraints.maxWidth * 0.05).clamp(12.0, 24.0),
                8,
                (constraints.maxWidth * 0.05).clamp(12.0, 24.0),
                4,
              ),
              child: Column(
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    scale: isActive ? 1 : 0.99,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _line),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: imageHeight,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ColoredBox(
                                color: _canvas,
                                child: Center(
                                  child: Container(
                                    width: 92,
                                    height: 92,
                                    decoration: BoxDecoration(
                                      color: _surface,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: _line),
                                    ),
                                    child: Icon(
                                      data.icon,
                                      size: 44,
                                      color: _ink,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _surface,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: _line),
                                  ),
                                  child: Text(
                                    data.badgeLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: _ink,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: titleSize,
                                height: 1.2,
                                color: _ink,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data.subtitle,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: subtitleSize,
                                height: 1.55,
                                color: _muted,
                                fontWeight: FontWeight.w600,
                              ),
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
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final active = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: active ? 30 : 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: active ? _selected : _line,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}

class _OnboardData {
  const _OnboardData({
    required this.icon,
    required this.badgeLabel,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String badgeLabel;
  final String title;
  final String subtitle;
}
