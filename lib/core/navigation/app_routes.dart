import '../../presentation/main_scaffold.dart';

/// Uygulama içi rota adları → [MainScaffold] sekme indeksi.
///
/// ── Neden gerekli ───────────────────────────────────────────────────────────
/// Uygulama `MaterialApp.routes` kullanmıyor; tüm ekranlar `MainScaffold`
/// içindeki `IndexedStack`'te duruyor. Buna rağmen iki yerde rota adı
/// üretiliyordu:
///
///   • `NotificationService` bildirim payload'una '/spending', '/accounts'
///     gibi rotalar yazıyor ve `pendingRoute` alanında tutuyordu — ama bu alanı
///     **hiç kimse okumuyordu**. Kullanıcı bildirime dokunduğunda uygulama
///     açılıyor, hiçbir şey olmuyordu.
///   • Asistan içgörü kartları `Navigator.pushNamed(route)` çağırıyordu.
///     Kayıtlı rota olmadığı için bu çağrı **hata fırlatıyordu**.
///
/// Bu sınıf ikisini de tek bir yere bağlar: rota adı sekmeye çevrilir.
class AppRoutes {
  const AppRoutes._();

  static const dashboard     = '/';
  static const spending      = '/spending';
  static const accounts      = '/accounts';
  static const portfolio     = '/portfolio';
  static const assistant     = '/ai';
  static const subscriptions = '/subscriptions';
  static const discover      = '/kesfet';
  static const profile       = '/profile';

  /// Rota → sekme indeksi. [MainScaffold] içindeki `_builders` sırasıyla aynı.
  static const _tabIndex = <String, int>{
    dashboard:     0,
    spending:      1,
    accounts:      2,
    portfolio:     3,
    assistant:     4,
    subscriptions: 5,
    discover:      6,
    profile:       7,
  };

  /// Rota tanınıyor mu?
  static bool isKnown(String? route) => _tabIndex.containsKey(route);

  /// Rotaya git. Tanınmayan rota sessizce yok sayılır — bildirim payload'u
  /// dışarıdan gelebildiği için burada hata fırlatmak doğru olmaz.
  static void go(String? route) {
    final index = _tabIndex[route];
    if (index != null) MainScaffold.switchTab(index);
  }
}
