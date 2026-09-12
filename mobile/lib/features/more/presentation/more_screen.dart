import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_palette_provider.dart';
import '../../../shared/widgets/language_switcher.dart';
import '../../../shared/widgets/mizan_card.dart';
import '../../../shared/widgets/theme_toggle.dart';
import '../../auth/presentation/auth_state_provider.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final user = ref.watch(authStateProvider).user;
    final activePalette = ref.watch(themePaletteProvider);
    final notifState = ref.watch(notificationSettingsProvider);

    void confirmLogout() {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.logout),
          content: Text(l10n.logoutConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerRed),
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) {
                  context.go(AppRoutes.auth);
                }
              },
              child: Text(l10n.logout, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.more,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.creamBackground,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Card
              MizanCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDeepGreen.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, size: 28, color: AppColors.primaryDeepGreen),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName.isNotEmpty == true ? user!.fullName : 'عبدالله أحمد',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email.isNotEmpty == true ? user!.email : 'user@mizan.app',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                isArabic ? 'الإدارة المالية والأدوات' : 'Financial Management & Tools',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              MizanCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsItem(
                      icon: Icons.assignment_outlined,
                      title: l10n.financialCommitments,
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      onTap: () => context.push(AppRoutes.commitments),
                    ),
                    const Divider(height: 1),
                    _SettingsItem(
                      icon: Icons.phonelink_lock,
                      title: l10n.bankParserPlayground,
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      onTap: () => context.push(AppRoutes.parserDebug),
                    ),
                    const Divider(height: 1),
                    _SettingsItem(
                      icon: Icons.map_outlined,
                      title: isArabic ? 'أين صرفت؟ (خريطة النفقات)' : 'Where Did I Spend? (Spending Map)',
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      onTap: () => context.go(AppRoutes.transactions),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                Localizations.localeOf(context).languageCode == 'ar' ? 'إعدادات الذكاء الاصطناعي والخصوصية' : 'AI & Privacy Settings',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              MizanCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.auto_awesome, color: AppColors.primaryDeepGreen),
                      title: Text(
                        Localizations.localeOf(context).languageCode == 'ar' ? 'التحليل المالي الذكي' : 'AI Financial Analysis',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        Localizations.localeOf(context).languageCode == 'ar' ? 'توليد التقارير ودراسة القروض' : 'Generate reports and loan studies',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      value: true,
                      activeTrackColor: AppColors.primaryDeepGreen,
                      onChanged: (val) {},
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryDeepGreen),
                      title: Text(
                        Localizations.localeOf(context).languageCode == 'ar' ? 'مساعد ميزان التفاعلي' : 'Mizan AI Chat',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        Localizations.localeOf(context).languageCode == 'ar' ? 'الزر العائم والمحادثة الذكية' : 'Floating chat assistant',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      value: true,
                      activeTrackColor: AppColors.primaryDeepGreen,
                      onChanged: (val) {},
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.trending_up, color: AppColors.primaryDeepGreen),
                      title: Text(
                        Localizations.localeOf(context).languageCode == 'ar' ? 'التوقعات المالية الشهرية' : 'Financial Forecasting',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        Localizations.localeOf(context).languageCode == 'ar' ? 'حساب الفائض المتوقع لنهاية الشهر' : 'Month-end surplus forecast',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      value: true,
                      activeTrackColor: AppColors.primaryDeepGreen,
                      onChanged: (val) {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                isArabic ? 'إشعارات وملخص المصاريف اليومي' : 'Daily Spending Summary Notification',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildNotificationCard(context, ref, notifState, isArabic, isDark),
              const SizedBox(height: 20),

              Text(
                isArabic ? 'ألوان الواجهة (سمة ميزان)' : 'Theme Color Palette',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildPaletteSelector(ref, activePalette, isArabic, isDark),
              const SizedBox(height: 20),

              Text(
                l10n.generalSettings,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Setting Tiles
              MizanCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: const [
                    _SettingsItem(
                      icon: Icons.language,
                      title: 'اللغة / Language',
                      trailing: LanguageSwitcher(),
                    ),
                    Divider(height: 1),
                    _SettingsItem(
                      icon: Icons.palette_outlined,
                      title: 'المظهر / Theme',
                      trailing: ThemeToggle(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              MizanCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsItem(
                      icon: Icons.lock_outline,
                      title: l10n.securityLock,
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    _SettingsItem(
                      icon: Icons.privacy_tip_outlined,
                      title: l10n.privacyPolicy,
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    _SettingsItem(
                      icon: Icons.info_outline,
                      title: l10n.aboutMizan,
                      trailing: Text(
                        'v1.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button
              MizanCard(
                padding: EdgeInsets.zero,
                child: _SettingsItem(
                  icon: Icons.logout,
                  iconColor: AppColors.dangerRed,
                  title: l10n.logout,
                  titleColor: AppColors.dangerRed,
                  onTap: confirmLogout,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaletteSelector(
    WidgetRef ref,
    AppThemePalette activePalette,
    bool isArabic,
    bool isDark,
  ) {
    final palettes = [
      (
        palette: AppThemePalette.emerald,
        titleAr: 'الزمردي الملكي',
        titleEn: 'Royal Emerald',
        primary: const Color(0xFF0F4D3A),
        accent: const Color(0xFF22C55E),
        secondary: const Color(0xFFA7C957),
      ),
      (
        palette: AppThemePalette.vibrantGreen,
        titleAr: 'الأخضر الحيوي',
        titleEn: 'Vibrant Green',
        primary: const Color(0xFF16A34A),
        accent: const Color(0xFF10B981),
        secondary: const Color(0xFFA7C957),
      ),
      (
        palette: AppThemePalette.sage,
        titleAr: 'الميرمية الهادئ',
        titleEn: 'Calm Sage',
        primary: const Color(0xFF557A46),
        accent: const Color(0xFFA7C957),
        secondary: const Color(0xFFD4C9B6),
      ),
    ];

    return Row(
      children: palettes.map((item) {
        final isSelected = activePalette == item.palette;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                ref.read(themePaletteProvider.notifier).setPalette(item.palette);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? item.accent : (isDark ? Colors.white12 : Colors.grey.shade300),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: item.accent.withValues(alpha: 0.22),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _colorCircle(item.primary),
                        const SizedBox(width: 3),
                        _colorCircle(item.accent),
                        const SizedBox(width: 3),
                        _colorCircle(item.secondary),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isArabic ? item.titleAr : item.titleEn,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? item.primary : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 4),
                      Icon(Icons.check_circle, size: 14, color: item.accent),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _colorCircle(Color color) {
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.2),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    NotificationSettingsState notifState,
    bool isArabic,
    bool isDark,
  ) {
    final summary = notifState.currentSummary;
    final primaryColor = Theme.of(context).primaryColor;

    return MizanCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryDeepGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active_outlined, color: AppColors.primaryDeepGreen, size: 22),
            ),
            title: Text(
              isArabic ? 'تنبيه الملخص اليومي للمصاريف' : 'Daily Spending Summary Alert',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              isArabic
                  ? 'إرسال إشعار يومي يوضح: (كم صرفت + كم المتبقي + كم المفروض تصرف بكره)'
                  : 'Daily push alert (Spent today + Remaining + Recommended tomorrow)',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            value: notifState.isDailyEnabled,
            activeTrackColor: AppColors.primaryDeepGreen,
            onChanged: (val) {
              ref.read(notificationSettingsProvider.notifier).toggleDailyEnabled(val);
            },
          ),
          if (notifState.isDailyEnabled) ...[
            const Divider(height: 20),
            // Time selection row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          isArabic ? 'وقت وصول التنبيه:' : 'Alert Time:',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: notifState.summaryTime,
                    );
                    if (picked != null) {
                      await ref.read(notificationSettingsProvider.notifier).setSummaryTime(picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          notifState.summaryTime.format(context),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, size: 13, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Live Preview of Notification
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF13221B) : const Color(0xFFF4F8F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryDeepGreen.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryDeepGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.balance, size: 12, color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isArabic ? 'ميزان • معاينة الإشعار على جوالك' : 'Mizan • Phone Notification Preview',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDeepGreen,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isArabic ? 'الآن' : 'Now',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary.getNotificationTitle(isArabic),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // 3 Key Metrics Box
                  Row(
                    children: [
                      Expanded(
                        child: _summaryMiniCard(
                          isDark: isDark,
                          label: isArabic ? 'صرفت اليوم' : 'Spent Today',
                          value: '${summary.spentToday.toStringAsFixed(2)} ر.س',
                          color: const Color(0xFFEF4444),
                          icon: Icons.arrow_downward_rounded,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _summaryMiniCard(
                          isDark: isDark,
                          label: isArabic ? 'كم المتبقي' : 'Remaining',
                          value: '${summary.remainingBudget.toStringAsFixed(0)} ر.س',
                          color: AppColors.primaryDeepGreen,
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _summaryMiniCard(
                          isDark: isDark,
                          label: isArabic ? 'كم المفروض بكره' : 'Tomorrow',
                          value: '${summary.recommendedTomorrow.toStringAsFixed(0)} ر.س',
                          color: const Color(0xFF10B981),
                          icon: Icons.trending_up,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Test Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDeepGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: notifState.isSendingTest
                    ? null
                    : () async {
                        final success = await ref
                            .read(notificationSettingsProvider.notifier)
                            .sendTestNotification(isArabic: isArabic);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(
                                    success ? Icons.check_circle : Icons.error,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      success
                                          ? (isArabic
                                              ? 'تم إرسال إشعار التجربة بنجاح إلى شريط إشعارات جوالك!'
                                              : 'Test notification sent to your phone notification tray!')
                                          : (isArabic
                                              ? 'تعذر إرسال الإشعار. يرجى التأكد من تفعيل صلاحيات الإشعارات.'
                                              : 'Could not send alert. Please ensure notification permissions are granted.'),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor:
                                  success ? AppColors.primaryDeepGreen : AppColors.dangerRed,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      },
                icon: notifState.isSendingTest
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  notifState.isSendingTest
                      ? (isArabic ? 'جاري إرسال الإشعار...' : 'Sending Alert...')
                      : (isArabic ? 'تجربة إرسال الإشعار الآن للجوال' : 'Send Test Notification Now'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryMiniCard({
    required bool isDark,
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2E25) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    this.iconColor,
    required this.title,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primaryDeepGreen, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: titleColor,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
