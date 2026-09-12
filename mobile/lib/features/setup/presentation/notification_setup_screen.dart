import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/mizan_app_bar.dart';
import '../../../shared/widgets/mizan_button.dart';
import '../../../shared/widgets/mizan_card.dart';

class NotificationSetupScreen extends StatefulWidget {
  const NotificationSetupScreen({super.key});

  @override
  State<NotificationSetupScreen> createState() => _NotificationSetupScreenState();
}

class _NotificationSetupScreenState extends State<NotificationSetupScreen> {
  bool _transactions = true;
  bool _dailySummary = true;
  bool _budgetLimits = true;
  bool _billReminders = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: MizanAppBar(title: '${l10n.setupStepNotifications} (6/7)'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: 6 / 7,
                backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryDeepGreen),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.notificationsTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.notificationsDesc,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
              ),
              const SizedBox(height: 28),
              _NotificationSwitchTile(
                title: l10n.notifyTransactions,
                icon: Icons.notifications_active_outlined,
                value: _transactions,
                onChanged: (v) => setState(() => _transactions = v),
              ),
              const SizedBox(height: 12),
              _NotificationSwitchTile(
                title: l10n.notifyDailySummary,
                icon: Icons.nights_stay_outlined,
                value: _dailySummary,
                onChanged: (v) => setState(() => _dailySummary = v),
              ),
              const SizedBox(height: 12),
              _NotificationSwitchTile(
                title: l10n.notifyBudgetLimits,
                icon: Icons.warning_amber_rounded,
                value: _budgetLimits,
                onChanged: (v) => setState(() => _budgetLimits = v),
              ),
              const SizedBox(height: 12),
              _NotificationSwitchTile(
                title: l10n.notifyBillReminders,
                icon: Icons.calendar_month_outlined,
                value: _billReminders,
                onChanged: (v) => setState(() => _billReminders = v),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: MizanButton(
                  text: l10n.continueText,
                  onPressed: () {
                    context.push(AppRoutes.setupPrivacy);
                  },
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

class _NotificationSwitchTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationSwitchTile({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MizanCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryDeepGreen),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: AppColors.primaryDeepGreen,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
