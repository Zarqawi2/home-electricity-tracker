import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../viewmodels/onboarding_view_model.dart';
import '../../../../core/widgets/app_button.dart';

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
      imageAsset: 'assets/img/1.jpg',
      icon: Icons.bolt,
      title: 'ژمێری کارەبای ڕۆژانەت بەژێر چاودێری بەرەوە',
      subtitle:
          'بینەوە چەند کارەبا لە هەر ئامێر دەردەچێت و زەبڵەکان بناسە پێش ئەوەی وەسڵ بگەیت.',
      badgeColor: Color(0xFFDDE9FF),
      badgeIconColor: AppColors.primary,
    ),
    _OnboardData(
      imageAsset: 'assets/img/2.jpg',
      icon: Icons.attach_money,
      title: 'پێشبینی وەسڵی مانگانە',
      subtitle:
          'وەسڵەکەت پێش کات بزانە بە هەژماری ئۆتۆماتیکی نرخەکانی IQD بۆ هەر ئامێرێک.',
      badgeColor: Color(0xFFFFF3D6),
      badgeIconColor: Color(0xFFEEB211),
    ),
    _OnboardData(
      imageAsset: 'assets/img/3.jfif',
      icon: Icons.home_filled,
      title: 'کۆنتڕۆڵی ئامێرەکانی ماڵ',
      subtitle:
          'ئامێرەکان بکە کار/بوەستن، کاتژمێری بەکارهێنان ڕێک بخە و پەندەکانی کارامەیی لەمەرج بدەست بگرە.',
      badgeColor: Color(0xFFE7F7EE),
      badgeIconColor: Color(0xFF22C55E),
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
    final vm = ref.read(onboardingViewModelProvider.notifier);
    final success = await vm.complete();
    if (!success || !mounted) {
      _isFinishing = false;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go('/');
      }
    });
  }

  Future<void> _next() async {
    final state = ref.read(onboardingViewModelProvider);
    if (state.pageIndex < _pages.length - 1) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      await _completeAndNavigate();
    }
  }

  Future<void> _back() async {
    final state = ref.read(onboardingViewModelProvider);
    if (state.pageIndex > 0) {
      await _controller.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vmState = ref.watch(onboardingViewModelProvider);
    final isLastPage = vmState.pageIndex == _pages.length - 1;
    final isCompleting = vmState.isCompleting;
    final screenWidth = MediaQuery.of(context).size.width;
    final clampedWidth = screenWidth.clamp(280.0, 430.0);
    final backWidth = vmState.pageIndex > 0 ? clampedWidth * 0.33 : 0.0;
    final nextWidth = clampedWidth * 0.34;
    final backPadding = EdgeInsets.symmetric(
      horizontal: (screenWidth * 0.03).clamp(10, 16),
      vertical: 9,
    );
    final nextPadding = EdgeInsets.symmetric(
      horizontal: (screenWidth * 0.06).clamp(18, 26),
      vertical: (screenWidth * 0.03).clamp(12, 15),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) =>
                    ref.read(onboardingViewModelProvider.notifier).setPage(i),
                itemCount: _pages.length,
                itemBuilder: (context, i) {
                  final item = _pages[i];
                  return _OnboardSlide(data: item);
                },
              ),
            ),
            _Dots(current: vmState.pageIndex, total: _pages.length),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: backWidth,
                    child: vmState.pageIndex > 0
                        ? AppButton(
                            label: 'گەڕانەوە',
                          variant: AppButtonVariant.outline,
                          onPressed: (isCompleting || _isFinishing) ? null : _back,
                          padding: backPadding,
                          borderRadius: 8,
                        )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: nextWidth,
                    child: AppButton(
                      label: isLastPage ? 'دەستپێکردن' : 'دواتر',
                      variant: AppButtonVariant.primary,
                      onPressed: (isCompleting || _isFinishing) ? null : _next,
                      isLoading: isCompleting,
                      padding: nextPadding,
                      borderRadius: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _OnboardSlide extends StatelessWidget {
  const _OnboardSlide({required this.data});

  final _OnboardData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: data.imageAsset != null
                  ? Image.asset(
                      data.imageAsset!,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      data.imageUrl ?? '',
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(height: 26),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: data.badgeColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 32,
              color: data.badgeIconColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
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
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: active ? 24 : 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : const Color(0xFFD1D5DB),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}

class _OnboardData {
  const _OnboardData({
    // ignore: unused_element_parameter
    this.imageUrl,
    this.imageAsset,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeColor,
    required this.badgeIconColor,
  });

  final String? imageUrl;
  final String? imageAsset;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color badgeColor;
  final Color badgeIconColor;
}
