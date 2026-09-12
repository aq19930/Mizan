import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/mizan_app_bar.dart';
import '../../../shared/widgets/mizan_button.dart';
import '../../../shared/widgets/mizan_card.dart';

class PrivacySetupScreen extends StatelessWidget {
  const PrivacySetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: MizanAppBar(title: '${l10n.setupStepPrivacy} (7/7)'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: 7 / 7,
                backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentBrightGreen),
                borderRadius: BorderRadius.circular(4),
              ),
              const Spacer(flex: 1),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primaryDeepGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 56,
                  color: AppColors.primaryDeepGreen,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.privacyTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.privacyDesc,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 24),
              MizanCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    _PrivacyBullet(
                      icon: Icons.lock_outline,
                      title: 'معالجة محلية 100%',
                      subtitle: 'تحليل الرسائل البنكية يتم بالكامل على جهازك دون إرسال أي نص لخوادم خارجية.',
                    ),
                    SizedBox(height: 12),
                    _PrivacyBullet(
                      icon: Icons.no_encryption_gmailerrorred_outlined,
                      title: 'لا نصل للرسائل الشخصية إطلاقاً',
                      subtitle: 'القارئ الذكي يتعرف فقط على رسائل العمليات البنكية ولا يقرأ أي محادثات شخصية.',
                    ),
                    SizedBox(height: 12),
                    _PrivacyBullet(
                      icon: Icons.verified_user_outlined,
                      title: 'التحكم في بياناتك بيدك دائماً',
                      subtitle: 'يمكنك تعطيل الرصد التلقائي وحذف بياناتك المالية المخزنة متى شئت.',
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: MizanButton(
                  text: l10n.enableSmartDetection,
                  onPressed: () {
                    context.go(AppRoutes.setupComplete);
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  context.go(AppRoutes.setupComplete);
                },
                child: Text(
                  l10n.notNow,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyBullet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PrivacyBullet({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primaryDeepGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
