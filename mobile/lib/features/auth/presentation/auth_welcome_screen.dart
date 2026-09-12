import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/language_switcher.dart';
import '../../../shared/widgets/mizan_button.dart';
import '../../../shared/widgets/theme_toggle.dart';

class AuthWelcomeScreen extends StatelessWidget {
  const AuthWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: primaryColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor,
              const Color(0xFF08261D),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    LanguageSwitcher(
                      color: Colors.white,
                      backgroundColor: Color(0x33FFFFFF), // 20% white glass
                      borderColor: Color(0x66FFFFFF), // 40% white border
                    ),
                    ThemeToggle(
                      iconColor: Colors.white,
                      backgroundColor: Color(0x33FFFFFF),
                      borderColor: Color(0x66FFFFFF),
                    ),
                  ],
                ),
                const Spacer(flex: 2),

                // Stylized Scale Icon & Glowing Badge (Reference Image 1 Screen 1)
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accentBrightGreen.withValues(alpha: 0.55),
                      width: 2.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentBrightGreen.withValues(alpha: 0.28),
                        blurRadius: 28,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.balance_rounded,
                      size: 54,
                      color: AppColors.accentBrightGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Brand Name
                Text(
                  isArabic ? 'مـيـزان' : 'MIZAN',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),

                // Brand Slogan
                Text(
                  isArabic
                      ? 'وازن صرفك.. خطط لبكرا.'
                      : 'Balance your money. Own your future.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(flex: 3),

                // Pill Action Button: Get Started (Reference Image 1 Screen 1)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: MizanButton(
                    text: isArabic ? 'ابدأ الآن' : 'Get Started',
                    backgroundColor: AppColors.accentBrightGreen,
                    textColor: const Color(0xFF042017), // High contrast deep green-black
                    onPressed: () => context.push(AppRoutes.register),
                  ),
                ),
                const SizedBox(height: 14),

                // Secondary Action: Sign In
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: MizanButton(
                    text: l10n.signIn,
                    isOutlined: true,
                    textColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    onPressed: () => context.push(AppRoutes.login),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
