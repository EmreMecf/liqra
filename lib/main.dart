import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
// CupertinoPageTransitionsBuilder artık material.dart'tan export edilmiyor
// (Flutter 3.4x) — cupertino.dart'tan gelir.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_colors.dart';
import 'core/di/injection.dart';
import 'core/services/auth_service.dart';
import 'core/navigation/app_routes.dart';
import 'core/services/notification_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/crash_service.dart';
import 'core/services/feature_flag_service.dart';
import 'core/services/ledger_backfill_service.dart';
import 'data/providers/app_provider.dart';
import 'features/ai_assistant/presentation/viewmodel/ai_assistant_viewmodel.dart';
import 'features/spending/presentation/viewmodel/spending_viewmodel.dart';
import 'features/portfolio/presentation/viewmodel/portfolio_viewmodel.dart';
import 'features/portfolio/presentation/viewmodel/market_viewmodel.dart';
import 'features/dashboard/presentation/viewmodel/dashboard_viewmodel.dart';
import 'features/accounts/presentation/viewmodels/accounts_viewmodel.dart';
import 'features/campaigns/presentation/viewmodel/campaign_viewmodel.dart';
import 'features/news/presentation/viewmodel/news_viewmodel.dart';
import 'features/ai_assistant/presentation/assistant_context_builder.dart';
import 'firebase_options.dart';
import 'presentation/auth/auth_screen.dart';
import 'presentation/onboarding/intro_onboarding_screen.dart';
import 'presentation/onboarding/onboarding_screen.dart';
import 'presentation/main_scaffold.dart';

/// Açılışta bir yardımcı servis patlarsa uygulamayı ÖLDÜRMEZ.
///
/// ── Neden ──────────────────────────────────────────────────────────────────
/// Eskiden beş servis tek bir `Future.wait` içinde bekleniyordu. `Future.wait`
/// ilk hatayı yeniden fırlatır: **herhangi biri** patladığında `main()` çöker,
/// `runApp` hiç çağrılmaz ve kullanıcı siyah ekran görür. Birkaç saniye sonra
/// iOS watchdog uygulamayı sonlandırır — dışarıdan "uygulama açılmıyor" ya da
/// "uygulama yok" gibi görünür, hiçbir hata mesajı çıkmaz.
///
/// Bu servislerin hiçbiri açılış için **zorunlu değildir**: Remote Config
/// düşerse varsayılanlar, Analytics düşerse ölçüm, bildirim izni düşerse
/// bildirim kaybolur — uygulama yine de çalışır.
///
/// Zaman aşımı da şart: `NotificationService.init()` iOS'ta APNs jetonu
/// gelmezse **askıda kalabilir**. Sonsuza kadar beklemek de siyah ekran
/// demektir, çökmekten farkı yoktur.
Future<void> _startOptional(String name, Future<void> Function() start) async {
  try {
    await start().timeout(const Duration(seconds: 10));
  } catch (e, s) {
    debugPrint('[Açılış] $name başlatılamadı, devam ediliyor: $e');
    // Crashlytics hazırsa kaydet; hazır değilse bu çağrı da sessizce geçer.
    unawaited(CrashService.instance.recordError(e, s, reason: '$name init'));
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase ──────────────────────────────────────────────────────────────
  // Bu ZORUNLU. Başarısız olursa uygulamanın anlamlı bir şey yapması mümkün
  // değil, ama siyah ekranla ölmek yerine sebebi göstermek gerekir: TestFlight
  // ya da mağaza sürümünde hata ayıklayıcı bağlanamaz, ekrandaki metin elde
  // kalan tek ipucudur.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, s) {
    debugPrint('[Açılış] Firebase başlatılamadı: $e\n$s');
    runApp(_StartupFailureApp(
      title: 'Bağlantı kurulamadı',
      detail: 'Firebase başlatılamadı.\n\n$e',
    ));
    return;
  }

  // ── Yardımcı servisler — hiçbiri açılışı engelleyemez ────────────────────
  // Crashlytics ilk sırada: sonrakiler patlarsa raporu o toplasın.
  await _startOptional('Crashlytics', CrashService.instance.init);
  await Future.wait([
    _startOptional('Analytics', AnalyticsService.instance.init),
    _startOptional('Bildirimler', NotificationService.instance.init),
    _startOptional('Remote Config', FeatureFlagService.instance.init),
    _startOptional('Auth', AuthService.instance.init),
  ]);

  // ── DI kayıt ─────────────────────────────────────────────────────────────
  // Bu da zorunlu: ekranlar getIt üzerinden ViewModel çözüyor, kayıt
  // yapılmazsa ilk karede fırlatır.
  try {
    await configureDependencies();
  } catch (e, s) {
    debugPrint('[Açılış] Bağımlılıklar kaydedilemedi: $e\n$s');
    unawaited(CrashService.instance.recordError(e, s, reason: 'DI init'));
    runApp(_StartupFailureApp(
      title: 'Uygulama başlatılamadı',
      detail: 'Bağımlılıklar kurulamadı.\n\n$e',
    ));
    return;
  }

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

/// Açılış tamamlanamadığında gösterilen ekran.
///
/// `runApp` hiç çağrılmazsa ekran siyah kalır ve iOS watchdog uygulamayı
/// sonlandırır; kullanıcıya "uygulama açılmıyor" diye görünür, elde hiçbir
/// bilgi kalmaz. Bu ekran en azından **neyin** patladığını söyler — TestFlight
/// ve mağaza sürümünde hata ayıklayıcı bağlanamadığı için tek ipucu budur.
class _StartupFailureApp extends StatelessWidget {
  final String title;
  final String detail;

  const _StartupFailureApp({required this.title, required this.detail});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      size: 52, color: AppColors.accentAmber),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'İnternet bağlantını kontrol edip uygulamayı yeniden aç. '
                    'Sorun sürerse aşağıdaki metni bize ilet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13.5),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bgSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      detail,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
        // Kampanya ve haberler uygulama kökünde: asistan bunları hisse
        // analizinde ve kampanya önerisinde kullanıyor, Keşfet ekranına
        // bağlı kalamaz.
        ChangeNotifierProvider<CampaignViewModel>(
          create: (_) => getIt<CampaignViewModel>(),
        ),
        ChangeNotifierProvider<NewsViewModel>(
          create: (_) => getIt<NewsViewModel>(),
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
      // Geçmiş cüzdan hareketlerini ana deftere taşı (kullanıcı başına bir kez,
      // idempotent). Dashboard'ın kredi kartı geçmişini de görmesi için gerekli.
      LedgerBackfillService.instance.runIfNeeded();

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

      _refreshAssistant(context);
    });
  }

  /// Bildirime dokunarak gelindiyse ilgili sekmeye geçer.
  ///
  /// Bildirimler '/spending', '/accounts' gibi rotalar taşıyordu ama bu değer
  /// hiçbir yerde okunmuyordu: kullanıcı bildirime dokunuyor, uygulama
  /// açılıyor ve ana sayfada kalıyordu.
  void _consumeNotificationRoute() {
    // İlk kare çizildikten sonra — MainScaffold'un state'i hazır olmalı.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = NotificationService.instance.consumePendingRoute();
      if (route != null) AppRoutes.go(route);
    });

    // Uygulama açıkken gelen bildirime dokunulursa anında yönlendir.
    NotificationService.instance.onRouteRequested = (route) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationService.instance.clearPendingRoute();
        AppRoutes.go(route);
      });
    };
  }

  /// Veriler yüklendikten sonra asistanın içgörülerini üretir ve gerekiyorsa
  /// bildirim gönderir.
  ///
  /// İçgörüler modele hiç gitmez (bkz. InsightEngine) — bu yüzden açılışta
  /// çalıştırmak ne para ne de görünür gecikme maliyeti yaratır. Bildirimler
  /// günde bir kez ve en fazla üç tane gönderilir.
  Future<void> _refreshAssistant(BuildContext context) async {
    final accounts  = context.read<AccountsViewModel>();
    final assistant = context.read<AiAssistantViewModel>();
    final app       = context.read<AppProvider>();

    // Cüzdan ve harcama verisi gelmeden içgörü üretmek yanıltıcı olur.
    await Future.wait([
      accounts.load(),
      app.loadUserProfile(),
    ]);
    if (!mounted || !context.mounted) return;

    await assistant.refreshInsights(
      AssistantContextBuilder.fromContext(context),
      userBanks: AssistantContextBuilder.userBanks(accounts),
    );
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
            _consumeNotificationRoute();
            return MainScaffold();
          },
        );
      },
    );
  }
}

