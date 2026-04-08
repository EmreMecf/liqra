import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../network/dio_client.dart';
import '../services/gemini_service.dart';

// AI Feature
import '../../features/ai_assistant/data/datasources/ai_remote_datasource.dart';
import '../../features/ai_assistant/data/repositories/ai_repository_impl.dart';
import '../../features/ai_assistant/domain/repositories/ai_repository.dart';
import '../../features/ai_assistant/domain/usecases/send_message_usecase.dart';
import '../../features/ai_assistant/domain/usecases/get_context_usecase.dart';
import '../../features/ai_assistant/presentation/viewmodel/ai_assistant_viewmodel.dart';

// Spending Feature
import '../../features/spending/data/datasources/spending_local_datasource.dart';
import '../../features/spending/data/datasources/spending_firestore_datasource.dart';
import '../../features/spending/data/repositories/spending_repository_impl.dart';
import '../../features/spending/domain/repositories/spending_repository.dart';
import '../../features/spending/domain/usecases/add_transaction_usecase.dart';
import '../../features/spending/domain/usecases/delete_transaction_usecase.dart';
import '../../features/spending/domain/usecases/get_transactions_usecase.dart';
import '../../features/spending/domain/usecases/get_monthly_summary_usecase.dart';
import '../../features/spending/presentation/viewmodel/spending_viewmodel.dart';

// Portfolio Feature
import '../../features/portfolio/data/datasources/portfolio_local_datasource.dart';
import '../../features/portfolio/data/datasources/portfolio_firestore_datasource.dart';
import '../../features/portfolio/data/datasources/tefas_datasource.dart';
import '../../features/portfolio/data/datasources/market_remote_datasource.dart';
import '../../features/portfolio/data/datasources/market_firestore_datasource.dart';
import '../../features/portfolio/data/repositories/portfolio_repository_impl.dart';
import '../../features/portfolio/domain/repositories/portfolio_repository.dart';
import '../../features/portfolio/domain/usecases/get_portfolio_usecase.dart';
import '../../features/portfolio/domain/usecases/get_market_data_usecase.dart';
import '../../features/portfolio/domain/usecases/add_asset_usecase.dart';
import '../../features/portfolio/domain/usecases/update_asset_usecase.dart';
import '../../features/portfolio/domain/usecases/delete_asset_usecase.dart';
import '../../features/portfolio/presentation/viewmodel/portfolio_viewmodel.dart';
import '../../features/portfolio/presentation/viewmodel/market_viewmodel.dart';

// Dashboard Feature
import '../../features/dashboard/presentation/viewmodel/dashboard_viewmodel.dart';

// Accounts Feature
import '../../features/accounts/data/datasources/accounts_firestore_datasource.dart';
import '../../features/accounts/data/repositories/accounts_repository_impl.dart';
import '../../features/accounts/domain/repositories/accounts_repository.dart';
import '../../features/accounts/domain/usecases/get_accounts_usecase.dart';
import '../../features/accounts/domain/usecases/add_account_usecase.dart';
import '../../features/accounts/domain/usecases/delete_account_usecase.dart';
import '../../features/accounts/domain/usecases/update_account_usecase.dart';
import '../../features/accounts/domain/usecases/get_account_transactions_usecase.dart';
import '../../features/accounts/domain/usecases/add_account_transaction_usecase.dart';
import '../../features/accounts/domain/usecases/import_statement_usecase.dart';
import '../../features/accounts/presentation/viewmodels/accounts_viewmodel.dart';

// Subscriptions Feature
import '../../features/subscriptions/data/datasources/subscription_datasource.dart';
import '../../features/subscriptions/data/repositories/subscription_repository_impl.dart';
import '../../features/subscriptions/domain/repositories/subscription_repository.dart';
import '../../features/subscriptions/domain/usecases/get_subscriptions_usecase.dart';
import '../../features/subscriptions/domain/usecases/add_subscription_usecase.dart';
import '../../features/subscriptions/domain/usecases/update_subscription_usecase.dart';
import '../../features/subscriptions/domain/usecases/delete_subscription_usecase.dart';
import '../../features/subscriptions/domain/usecases/toggle_subscription_usecase.dart';
import '../../features/subscriptions/presentation/viewmodel/subscription_viewmodel.dart';

/// DI kayıt defteri
/// get_it singleton — manual registration (build_runner gerekmez)
final GetIt getIt = GetIt.instance;

/// Tüm bağımlılıkları kayıt et
/// main() içinde çağrılır: await configureDependencies();
Future<void> configureDependencies() async {
  _registerNetwork();
  _registerAiFeature();
  _registerSpendingFeature();
  _registerPortfolioFeature();
  _registerDashboardFeature();
  _registerAccountsFeature();
  _registerSubscriptionsFeature();
}

// ── Network ───────────────────────────────────────────────────────────────────

void _registerNetwork() {
  // Dio — lazySingleton: ilk kullanımda oluşturulur
  getIt.registerLazySingleton<Dio>(() => DioClient.instance);
}

// ── AI Asistan Feature ────────────────────────────────────────────────────────

void _registerAiFeature() {
  // Gemini API servisi — Google'a direkt bağlanır, key Remote Config'den gelir
  getIt.registerLazySingleton<GeminiService>(
    () => GeminiService.instance,
  );

  // DataSource — backend değil, doğrudan Gemini
  getIt.registerLazySingleton<AiRemoteDataSource>(
    () => AiRemoteDataSourceImpl(getIt<GeminiService>()),
  );

  // Repository
  getIt.registerLazySingleton<AiRepository>(
    () => AiRepositoryImpl(getIt<AiRemoteDataSource>()),
  );

  // Use Cases
  getIt.registerLazySingleton(() => SendMessageUseCase(getIt<AiRepository>()));
  getIt.registerLazySingleton(() => GetContextUseCase());

  // ViewModel — factory: her kullanımda taze instance
  getIt.registerFactory<AiAssistantViewModel>(
    () => AiAssistantViewModel(
      sendMessage: getIt<SendMessageUseCase>(),
      getContext: getIt<GetContextUseCase>(),
    ),
  );
}

// ── Spending Feature ──────────────────────────────────────────────────────────

void _registerSpendingFeature() {
  // DataSource — Firestore (gerçek veritabanı)
  getIt.registerLazySingleton<SpendingLocalDataSource>(
    () => SpendingFirestoreDataSource(),
  );

  // Repository
  getIt.registerLazySingleton<SpendingRepository>(
    () => SpendingRepositoryImpl(getIt<SpendingLocalDataSource>()),
  );

  // Use Cases
  getIt.registerLazySingleton(
      () => GetTransactionsUseCase(getIt<SpendingRepository>()));
  getIt.registerLazySingleton(
      () => AddTransactionUseCase(getIt<SpendingRepository>()));
  getIt.registerLazySingleton(
      () => DeleteTransactionUseCase(getIt<SpendingRepository>()));
  getIt.registerLazySingleton(
      () => GetMonthlySummaryUseCase(getIt<SpendingRepository>()));

  // ViewModel
  getIt.registerFactory<SpendingViewModel>(
    () => SpendingViewModel(
      getTransactions: getIt<GetTransactionsUseCase>(),
      addTransaction: getIt<AddTransactionUseCase>(),
      deleteTransaction: getIt<DeleteTransactionUseCase>(),
      getMonthlySummary: getIt<GetMonthlySummaryUseCase>(),
    ),
  );
}

// ── Portfolio Feature ─────────────────────────────────────────────────────────

void _registerPortfolioFeature() {
  // DataSources — Firestore (gerçek veritabanı)
  getIt.registerLazySingleton<PortfolioLocalDataSource>(
    () => PortfolioFirestoreDataSource(),
  );
  // Firestore onSnapshot — Cloud Functions her 1dk'da bir günceller
  getIt.registerLazySingleton<MarketRemoteDataSource>(
    () => MarketFirestoreDataSource(),
  );
  getIt.registerLazySingleton<TefasDataSource>(
    () => TefasDataSourceImpl(),
  );

  // Repository
  getIt.registerLazySingleton<PortfolioRepository>(
    () => PortfolioRepositoryImpl(
      localDataSource:  getIt<PortfolioLocalDataSource>(),
      remoteDataSource: getIt<MarketRemoteDataSource>(),
      tefasDataSource:  getIt<TefasDataSource>(),
    ),
  );

  // Use Cases
  getIt.registerLazySingleton(
      () => GetPortfolioUseCase(getIt<PortfolioRepository>()));
  getIt.registerLazySingleton(
      () => GetMarketDataUseCase(getIt<PortfolioRepository>()));
  getIt.registerLazySingleton(
      () => AddAssetUseCase(getIt<PortfolioRepository>()));
  getIt.registerLazySingleton(
      () => UpdateAssetUseCase(getIt<PortfolioRepository>()));
  getIt.registerLazySingleton(
      () => DeleteAssetUseCase(getIt<PortfolioRepository>()));

  // ViewModels
  getIt.registerFactory<PortfolioViewModel>(
    () => PortfolioViewModel(
      getPortfolio: getIt<GetPortfolioUseCase>(),
      addAsset:     getIt<AddAssetUseCase>(),
      updateAsset:  getIt<UpdateAssetUseCase>(),
      deleteAsset:  getIt<DeleteAssetUseCase>(),
    ),
  );
  getIt.registerFactory<MarketViewModel>(
    () => MarketViewModel(
      getMarketData: getIt<GetMarketDataUseCase>(),
    ),
  );
}

// ── Dashboard Feature ─────────────────────────────────────────────────────────

void _registerDashboardFeature() {
  getIt.registerFactory<DashboardViewModel>(
    () => DashboardViewModel(
      getTransactions: getIt<GetTransactionsUseCase>(),
      getPortfolio: getIt<GetPortfolioUseCase>(),
    ),
  );
}

// ── Accounts Feature ──────────────────────────────────────────────────────────

void _registerAccountsFeature() {
  getIt.registerLazySingleton<AccountsFirestoreDataSource>(
    () => AccountsFirestoreDataSourceImpl(),
  );

  getIt.registerLazySingleton<AccountsRepository>(
    () => AccountsRepositoryImpl(getIt<AccountsFirestoreDataSource>()),
  );

  getIt.registerLazySingleton(() => GetAccountsUseCase(getIt<AccountsRepository>()));
  getIt.registerLazySingleton(() => AddAccountUseCase(getIt<AccountsRepository>()));
  getIt.registerLazySingleton(() => DeleteAccountUseCase(getIt<AccountsRepository>()));
  getIt.registerLazySingleton(() => UpdateAccountUseCase(getIt<AccountsRepository>()));
  getIt.registerLazySingleton(() => GetAccountTransactionsUseCase(getIt<AccountsRepository>()));
  getIt.registerLazySingleton(() => AddAccountTransactionUseCase(getIt<AccountsRepository>()));
  getIt.registerLazySingleton(() => ImportStatementUseCase(getIt<AccountsRepository>()));

  getIt.registerFactory<AccountsViewModel>(
    () => AccountsViewModel(
      getAccounts:     getIt<GetAccountsUseCase>(),
      addAccount:      getIt<AddAccountUseCase>(),
      deleteAccount:   getIt<DeleteAccountUseCase>(),
      updateAccount:   getIt<UpdateAccountUseCase>(),
      getTransactions: getIt<GetAccountTransactionsUseCase>(),
      addTransaction:  getIt<AddAccountTransactionUseCase>(),
      importStatement: getIt<ImportStatementUseCase>(),
    ),
  );
}

// ── Subscriptions Feature ─────────────────────────────────────────────────────

void _registerSubscriptionsFeature() {
  getIt.registerLazySingleton<SubscriptionDataSource>(
    () => SubscriptionFirestoreDataSource(),
  );

  getIt.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(getIt<SubscriptionDataSource>()),
  );

  getIt.registerLazySingleton(
      () => GetSubscriptionsUseCase(getIt<SubscriptionRepository>()));
  getIt.registerLazySingleton(
      () => AddSubscriptionUseCase(getIt<SubscriptionRepository>()));
  getIt.registerLazySingleton(
      () => UpdateSubscriptionUseCase(getIt<SubscriptionRepository>()));
  getIt.registerLazySingleton(
      () => DeleteSubscriptionUseCase(getIt<SubscriptionRepository>()));
  getIt.registerLazySingleton(
      () => ToggleSubscriptionUseCase(getIt<SubscriptionRepository>()));

  getIt.registerFactory<SubscriptionViewModel>(
    () => SubscriptionViewModel(
      getSubscriptions:   getIt<GetSubscriptionsUseCase>(),
      addSubscription:    getIt<AddSubscriptionUseCase>(),
      updateSubscription: getIt<UpdateSubscriptionUseCase>(),
      deleteSubscription: getIt<DeleteSubscriptionUseCase>(),
      toggleSubscription: getIt<ToggleSubscriptionUseCase>(),
    ),
  );
}
