import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/language_selection_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/auth_welcome_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/account_success_screen.dart';
import '../../features/setup/presentation/profile_setup_screen.dart';
import '../../features/setup/presentation/initial_balance_screen.dart';
import '../../features/setup/presentation/commitments_setup_screen.dart';
import '../../features/setup/presentation/budget_setup_screen.dart';
import '../../features/setup/presentation/category_budget_screen.dart';
import '../../features/setup/presentation/notification_setup_screen.dart';
import '../../features/setup/presentation/privacy_setup_screen.dart';
import '../../features/setup/presentation/setup_complete_screen.dart';
import '../../features/commitments/presentation/commitments_screen.dart';
import '../../features/commitments/presentation/add_commitment_screen.dart';
import '../../features/bank_parser/presentation/review_detected_transaction_screen.dart';
import '../../features/bank_parser/presentation/parser_debug_screen.dart';
import '../../features/bank_parser/data/models/parsed_bank_transaction.dart';
import '../../features/shell/app_shell.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/transactions/presentation/transactions_screen.dart';
import '../../features/transactions/presentation/add_transaction_screen.dart';
import '../../features/transactions/presentation/transaction_details_screen.dart';
import '../../features/budgets/presentation/budget_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/insights/presentation/mizan_ai_chat_screen.dart';
import '../../features/more/presentation/more_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String language = '/language';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String accountSuccess = '/account-success';

  // Setup Wizard
  static const String setupProfile = '/setup/profile';
  static const String setupBalance = '/setup/balance';
  static const String setupCommitments = '/setup/commitments';
  static const String setupBudget = '/setup/budget';
  static const String setupCategories = '/setup/categories';
  static const String setupNotifications = '/setup/notifications';
  static const String setupPrivacy = '/setup/privacy';
  static const String setupComplete = '/setup/complete';

  // Commitments Feature
  static const String commitments = '/commitments';
  static const String addCommitment = '/commitments/add';

  // Bank Message Parser Feature
  static const String reviewDetectedTransaction = '/transactions/review-detected';
  static const String parserDebug = '/debug/parser';

  // Core Shell Routes
  static const String home = '/home';
  static const String transactions = '/transactions';
  static const String addTransaction = '/transactions/add';
  static const String transactionDetails = '/transactions/:id';
  static const String budget = '/budget';
  static const String insights = '/insights';
  static const String more = '/more';
  static const String aiChat = '/ai-chat';
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.language,
      builder: (context, state) => const LanguageSelectionScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.auth,
      builder: (context, state) => const AuthWelcomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.accountSuccess,
      builder: (context, state) => const AccountSuccessScreen(),
    ),

    // Setup Wizard
    GoRoute(
      path: AppRoutes.setupProfile,
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: AppRoutes.setupBalance,
      builder: (context, state) => const InitialBalanceScreen(),
    ),
    GoRoute(
      path: AppRoutes.setupCommitments,
      builder: (context, state) => const CommitmentsSetupScreen(),
    ),
    GoRoute(
      path: AppRoutes.setupBudget,
      builder: (context, state) => const BudgetSetupScreen(),
    ),
    GoRoute(
      path: AppRoutes.setupCategories,
      builder: (context, state) => const CategoryBudgetScreen(),
    ),
    GoRoute(
      path: AppRoutes.setupNotifications,
      builder: (context, state) => const NotificationSetupScreen(),
    ),
    GoRoute(
      path: AppRoutes.setupPrivacy,
      builder: (context, state) => const PrivacySetupScreen(),
    ),
    GoRoute(
      path: AppRoutes.setupComplete,
      builder: (context, state) => const SetupCompleteScreen(),
    ),

    // Commitments
    GoRoute(
      path: AppRoutes.commitments,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CommitmentsScreen(),
    ),
    GoRoute(
      path: AppRoutes.addCommitment,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddCommitmentScreen(),
    ),

    // Bank Parser
    GoRoute(
      path: AppRoutes.reviewDetectedTransaction,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final tx = state.extra as ParsedBankTransactionDto?;
        return ReviewDetectedTransactionScreen(transaction: tx);
      },
    ),
    GoRoute(
      path: AppRoutes.parserDebug,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ParserDebugScreen(),
    ),

    // Standalone Full-screen routes
    GoRoute(
      path: AppRoutes.addTransaction,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddTransactionScreen(),
    ),
    GoRoute(
      path: AppRoutes.transactionDetails,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return TransactionDetailsScreen(transactionId: id);
      },
    ),
    GoRoute(
      path: AppRoutes.aiChat,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MizanAiChatScreen(),
    ),

    // Main App Shell with Bottom Navigation
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.transactions,
          builder: (context, state) => const TransactionsScreen(),
        ),
        GoRoute(
          path: AppRoutes.budget,
          builder: (context, state) => const BudgetScreen(),
        ),
        GoRoute(
          path: AppRoutes.insights,
          builder: (context, state) => const InsightsScreen(),
        ),
        GoRoute(
          path: AppRoutes.more,
          builder: (context, state) => const MoreScreen(),
        ),
      ],
    ),
  ],
);
