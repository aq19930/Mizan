import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/language_switcher.dart';
import '../../../shared/widgets/mizan_button.dart';
import '../../../shared/widgets/mizan_animated_entrance.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _onNext() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppRoutes.auth);
    }
  }

  void _onSkip() {
    context.go(AppRoutes.auth);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final slides = [
      _OnboardingData(
        title: l10n.onboarding1Title,
        desc: l10n.onboarding1Desc,
        illustration: const _IllustrationWallet(),
      ),
      _OnboardingData(
        title: l10n.onboarding2Title,
        desc: l10n.onboarding2Desc,
        illustration: const _IllustrationSmsDetect(),
      ),
      _OnboardingData(
        title: l10n.onboarding3Title,
        desc: l10n.onboarding3Desc,
        illustration: const _IllustrationBudgetRing(),
      ),
      _OnboardingData(
        title: l10n.onboarding4Title,
        desc: l10n.onboarding4Desc,
        illustration: const _IllustrationAiForecast(),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const LanguageSwitcher(),
                  if (_currentPage < 3)
                    TextButton(
                      onPressed: _onSkip,
                      child: Text(
                        l10n.skip,
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Center(child: slide.illustration),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.desc,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                height: 1.5,
                              ),
                        ),
                        const Spacer(flex: 1),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        width: _currentPage == index ? 24.0 : 8.0,
                        height: 8.0,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primaryDeepGreen
                              : (isDark ? Colors.white24 : Colors.black12),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: MizanButton(
                      text: _currentPage == 3 ? l10n.getStarted : l10n.next,
                      onPressed: _onNext,
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
}

class _OnboardingData {
  final String title;
  final String desc;
  final Widget illustration;

  _OnboardingData({
    required this.title,
    required this.desc,
    required this.illustration,
  });
}

class _IllustrationWallet extends StatelessWidget {
  const _IllustrationWallet();

  @override
  Widget build(BuildContext context) {
    return MizanPulseEffect(
      duration: const Duration(milliseconds: 2400),
      minScale: 0.95,
      maxScale: 1.04,
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.primaryDeepGreen.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Hero(
              tag: 'app_logo_icon',
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDeepGreen.withValues(alpha: 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    AppConstants.appIcon,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 18,
              right: 18,
              child: _MiniBadge(icon: Icons.trending_up, color: AppColors.accentBrightGreen),
            ),
            const Positioned(
              bottom: 20,
              left: 18,
              child: _MiniBadge(icon: Icons.pie_chart, color: AppColors.secondarySageGreen),
            ),
          ],
        ),
      ),
    );
  }
}

class _IllustrationSmsDetect extends StatelessWidget {
  const _IllustrationSmsDetect();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.accentBrightGreen.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 170,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryDeepGreen.withValues(alpha: 0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.security, size: 18, color: AppColors.primaryDeepGreen),
                    const SizedBox(width: 8),
                    const Text('Bank SMS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentBrightGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Auto', style: TextStyle(fontSize: 10, color: AppColors.primaryDeepGreen, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(height: 6, width: 110, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3))),
                const SizedBox(height: 6),
                Container(height: 6, width: 80, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(3))),
              ],
            ),
          ),
          const Positioned(
            top: 24,
            child: _MiniBadge(icon: Icons.flash_on, color: AppColors.accentBrightGreen),
          ),
        ],
      ),
    );
  }
}

class _IllustrationBudgetRing extends StatelessWidget {
  const _IllustrationBudgetRing();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.secondarySageGreen.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CircularProgressIndicator(
              value: 0.68,
              strokeWidth: 12,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryDeepGreen),
            ),
          ),
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('68%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryDeepGreen)),
              Text('Safe', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accentBrightGreen)),
            ],
          ),
          const Positioned(
            bottom: 26,
            right: 32,
            child: _MiniBadge(icon: Icons.check_circle, color: AppColors.accentBrightGreen),
          ),
        ],
      ),
    );
  }
}

class _IllustrationAiForecast extends StatelessWidget {
  const _IllustrationAiForecast();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.primaryDeepGreen.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 160,
            height: 110,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F4D3A), Color(0xFF1B6B52)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDeepGreen.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 18, color: AppColors.accentBrightGreen),
                    SizedBox(width: 6),
                    Text('AI Forecast', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 10),
                Text('~ 265 SAR', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Tomorrow Confidence: 92%', style: TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
          const Positioned(
            top: 24,
            right: 28,
            child: _MiniBadge(icon: Icons.insights, color: AppColors.accentBrightGreen),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _MiniBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
