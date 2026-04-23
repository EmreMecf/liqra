import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_colors.dart';
import 'core/di/injection.dart';
import 'core/services/auth_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/crash_service.dart';
import 'core/services/feature_flag_service.dart';
import 'data/providers/app_provider.dart';
import 'features/ai_assistant/presentation/viewmodel/ai_assistant_viewmodel.dart';
import 'features/spending/presentation/viewmodel/spending_viewmodel.dart';
import 'features/portfolio/presentation/viewmodel/portfolio_viewmodel.dart';
import 'features/portfolio/presentation/viewmodel/market_viewmodel.dart';
import 'features/dashboard/presentation/viewmodel/dashboard_viewmodel.dart';
import 'features/accounts/presentation/viewmodels/accounts_viewmodel.dart';
import 'firebase_options.dart';
import 'presentation/auth/auth_screen.dart';
import 'presentation/onboarding/intro_onboarding_screen.dart';
import 'presentation/onboarding/onboarding_screen.dart';
import 'presentation/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase ──────────────────────────────────────────────────────────────
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Future.wait([
    CrashService.instance.init(),
    AnalyticsService.instance.init(),
    NotificationService.instance.init(),
    FeatureFlagService.instance.init(),
    AuthService.instance.init(),
  ]);

  // ── DI kayıt ─────────────────────────────────────────────────────────────
  await configureDependencies();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:                    Colors.transparent,
      statusBarIconBrightness:           Brightness.light,
      systemNavigationBarColor:          AppColors.bgSecondary,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const LiqraApp());
}

class LiqraApp extends StatelessWidget {
  const LiqraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        // ViewModel'ler kullanıcı girişi öncesi load() çağırmaz — auth sonrası yüklenir
        ChangeNotifierProvider<DashboardViewModel>(
          create: (_) => getIt<DashboardViewModel>(),
        ),
        ChangeNotifierProvider<SpendingViewModel>(
          create: (_) => getIt<SpendingViewModel>(),
        ),
        ChangeNotifierProvider<PortfolioViewModel>(
          create: (_) => getIt<PortfolioViewModel>(),
        ),
        ChangeNotifierProvider<MarketViewModel>(
          create: (_) => getIt<MarketViewModel>(), // auth değişiminde otomatik load
        ),
        ChangeNotifierProvider<AiAssistantViewModel>(
          create: (_) => getIt<AiAssistantViewModel>(),
        ),
        ChangeNotifierProvider<AccountsViewModel>(
          create: (_) => getIt<AccountsViewModel>(),
        ),
      ],
      child: MaterialApp(
        title:                     'Liqra',
        debugShowCheckedModeBanner: false,
        navigatorObservers: [AnalyticsService.instance.observer],
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.dark(
            primary:   AppColors.accentGreen,
            secondary: AppColors.accentGold,
            surface:   AppColors.bgSecondary,
            onSurface: AppColors.textPrimary,
          ),
          scaffoldBackgroundColor: AppColors.bgPrimary,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.bgPrimary,
            elevation: 0,
            scrolledUnderElevation: 0,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor:          Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            ),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: AppColors.bgSecondary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: AppColors.bgCard2,
            contentTextStyle:
                const TextStyle(color: AppColors.textPrimary),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            behavior: SnackBarBehavior.floating,
          ),
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor:          AppColors.accentGreen,
            selectionColor:       Color(0x1A0AFFE0), // liqra teal %10
            selectionHandleColor: AppColors.accentGreen,
          ),
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: CupertinoPageTransitionsBuilder(),
              TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
            },
          ),
        ),
        home: const _AppEntry(),
      ),
    );
  }
}

/// Splash → Intro (ilk açılış) → Auth gate
class _AppEntry extends StatefulWidget {
  const _AppEntry();
  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool? _introSeen;

  @override
  void initState() {
    super.initState();
    _loadIntroFlag();
  }

  Future<void> _loadIntroFlag() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _introSeen = prefs.getBool('liqra_intro_seen') ?? false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Yüklenirken boş ekran (native splash zaten gösteriliyor)
    if (_introSeen == null) {
      return const Scaffold(backgroundColor: AppColors.bgPrimary);
    }

    // İlk açılış → intro onboarding
    if (_introSeen == false) {
      return const IntroOnboardingScreen();
    }

    // Normal akış
    return const _AuthGate();
  }
}

/// Firebase Auth stream'ini dinler — kullanıcı durumuna göre yönlendirir
///
///  Giriş yok           → AuthScreen
///  Giriş var, profil yok → OnboardingScreen
///  Giriş var, profil var → MainScaffold
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  String? _lastLoadedUid; // hangi uid için load yapıldığını takip et

  /// Kullanıcı verilerini tek seferlik yükler (her rebuild'de tekrar çağrılmaz)
  void _loadUserData(BuildContext context) {
    final uid = AuthService.instance.userId;
    if (uid == null || uid == _lastLoadedUid) return;
    _lastLoadedUid = uid;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppProvider>().loadUserProfile();
      context.read<DashboardViewModel>().load();
      context.read<SpendingViewModel>().loadCurrentMonth();
      context.read<AccountsViewModel>().load();

      // Portföy yüklenince mevcut varlıkları hedefe bir kez senkronize et
      final portfolioVm = context.read<PortfolioViewModel>();
      final appProvider = context.read<AppProvider>();

      void syncOnce() {
        final assets = portfolioVm.assets;
        if (assets.isNotEmpty) {
          portfolioVm.removeListener(syncOnce);
          appProvider.syncGoalWithPortfolio(assets);
        }
      }

      portfolioVm.addListener(syncOnce);
      portfolioVm.load(); // load tamamlanınca syncOnce çağrılır
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: AppColors.bgPrimary);
        }

        final user = snapshot.data;

        // Giriş yapılmamış
        if (user == null) {
          _lastLoadedUid = null; // çıkış yapıldı, reset
          return const AuthScreen();
        }

        // Giriş yapılmış — profil tamamlandı mı?
        return ListenableBuilder(
          listenable: AuthService.instance,
          builder: (context, _) {
            if (!AuthService.instance.profileComplete) {
              // Profil eksik → onboarding (AppProvider profil yüklemeyi dene)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) context.read<AppProvider>().loadUserProfile();
              });
              return const OnboardingScreen();
            }

            // Profil tamam → verileri bir kez yükle
            _loadUserData(context);
            return MainScaffold();
          },
        );
      },
    );
  }
}

