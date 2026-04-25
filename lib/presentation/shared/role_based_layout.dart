import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/app_provider.dart';

/// Role-Based Dashboard Layout
///
/// Bu widget, kullanıcının rolüne göre tamamen farklı dashboard'lar gösterir:
/// - personal: Kişisel finans paneli
/// - merchant_admin: Esnaf işletme paneli (POS+Web)
/// - merchant_cashier: Kasiyer işlem paneli (sınırlı)
///
/// Usage:
///   Scaffold(
///     body: RoleBasedLayout()
///   )

class RoleBasedLayout extends StatelessWidget {
  const RoleBasedLayout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final userRole = appProvider.userRole; // 'personal', 'merchant_admin', 'merchant_cashier'

        // Role'a göre farklı widget render et
        switch (userRole) {
          case 'personal':
            return const PersonalDashboard();
          case 'merchant_admin':
            return const MerchantAdminDashboard();
          case 'merchant_cashier':
            return const MerchantCashierDashboard();
          default:
            return const Scaffold(
              body: Center(
                child: Text('Rol tanınmadı'),
              ),
            );
        }
      },
    );
  }
}

/// ════════════════════════════════════════════════════════════════════════════
/// 1️⃣ PERSONAL DASHBOARD — Bireysel Kullanıcı
/// ════════════════════════════════════════════════════════════════════════════

class PersonalDashboard extends StatelessWidget {
  const PersonalDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0x0AFFE0).withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kişisel Finans Panelim',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text('Portföyünüzü ve harcamalarınızı takip edin'),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Portföy Özeti
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Portföy Değeri'),
                        const SizedBox(height: 8),
                        Text(
                          '₺ 125.450,00',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text('+12.5% bu ay'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Bu Ay Harcamalar
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Aylık Harcamalar'),
                        const SizedBox(height: 8),
                        Text(
                          '₺ 8.450,00',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        // Mini Grafik
                        Container(
                          height: 100,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Text('Harcama Grafiği'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Finansal Hedefler
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Aktif Hedefler'),
                        const SizedBox(height: 12),
                        _GoalCard(
                          title: 'Tatil Fonu',
                          target: 50000,
                          current: 32500,
                          percentage: 0.65,
                        ),
                        const SizedBox(height: 8),
                        _GoalCard(
                          title: 'Ev Peşinatı',
                          target: 100000,
                          current: 45000,
                          percentage: 0.45,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Haberler & Kampanyalar
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Finans Haberleri'),
                        const SizedBox(height: 12),
                        _NewsCard(
                          title: 'Merkez Bankası Faiz Kararı',
                          source: 'Reuters',
                          timestamp: '2 saat önce',
                        ),
                        const SizedBox(height: 8),
                        _NewsCard(
                          title: 'BIST 100 Endeksi Yükselişe Geçti',
                          source: 'Borsa',
                          timestamp: '1 saat önce',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════════════════════
/// 2️⃣ MERCHANT ADMIN DASHBOARD — Esnaf Paneli
/// ════════════════════════════════════════════════════════════════════════════

class MerchantAdminDashboard extends StatelessWidget {
  const MerchantAdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'İşletme Panelim',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text('Satışlar, raporlar ve personel yönetimi'),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Bugünün Satışları
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Bugün Satışlar'),
                              const SizedBox(height: 8),
                              Text(
                                '₺ 15.420',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(color: Colors.green),
                              ),
                              const SizedBox(height: 4),
                              const Text('43 işlem'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ortalama İşlem'),
                              const SizedBox(height: 8),
                              Text(
                                '₺ 358',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              const Text('net ortalama'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Bu Ay Özeti
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bu Ay Özeti'),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Toplam Satış'),
                                Text(
                                  '₺ 456.789',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('İşlem Sayısı'),
                                Text(
                                  '1.240',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Personel Yönetimi
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Personel'),
                            ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Ekle'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _StaffCard(
                          name: 'Ahmet Yılmaz',
                          role: 'Kasiyer',
                          status: 'Aktif',
                          todaySales: 5234,
                        ),
                        const SizedBox(height: 8),
                        _StaffCard(
                          name: 'Fatma Demir',
                          role: 'Kasiyer',
                          status: 'Aktif',
                          todaySales: 3450,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Ayarlar
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hızlı İşlemler'),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.assessment),
                            label: const Text('Detaylı Raporlar'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.settings),
                            label: const Text('İşletme Ayarları'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════════════════════
/// 3️⃣ MERCHANT CASHIER DASHBOARD — Kasiyer Paneli (Sınırlı)
/// ════════════════════════════════════════════════════════════════════════════

class MerchantCashierDashboard extends StatelessWidget {
  const MerchantCashierDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kasiyer Paneli',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text('Bugünün satış işlemleri'),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Bugünün Satışı (Kasiyer'a ait)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Benim Bugünkü Satışlar'),
                        const SizedBox(height: 8),
                        Text(
                          '₺ 5.234',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: Colors.green),
                        ),
                        const SizedBox(height: 4),
                        const Text('12 işlem - Ortalama: ₺ 436'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Son İşlemler
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Son İşlemler'),
                        const SizedBox(height: 12),
                        _TransactionCard(
                          amount: 250.00,
                          method: 'Nakit',
                          time: '14:32',
                        ),
                        const SizedBox(height: 8),
                        _TransactionCard(
                          amount: 125.50,
                          method: 'Kredi Kartı',
                          time: '14:28',
                        ),
                        const SizedBox(height: 8),
                        _TransactionCard(
                          amount: 350.00,
                          method: 'Nakit',
                          time: '14:15',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ⚠️ Admin-only features HIDDEN
                Card(
                  color: Colors.grey[200],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lock, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text(
                          'Raporlar ve Yönetim Paneli',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sadece yöneticiler erişebilir',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════════════════════
/// HELPER WIDGETS
/// ════════════════════════════════════════════════════════════════════════════

class _GoalCard extends StatelessWidget {
  final String title;
  final double target;
  final double current;
  final double percentage;

  const _GoalCard({
    required this.title,
    required this.target,
    required this.current,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Text('${(percentage * 100).toStringAsFixed(0)}%'),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₺ ${current.toStringAsFixed(0)} / ₺ ${target.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  final String title;
  final String source;
  final String timestamp;

  const _NewsCard({
    required this.title,
    required this.source,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              source,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              timestamp,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}

class _StaffCard extends StatelessWidget {
  final String name;
  final String role;
  final String status;
  final double todaySales;

  const _StaffCard({
    required this.name,
    required this.role,
    required this.status,
    required this.todaySales,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              role,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Aktif',
                style: TextStyle(fontSize: 12, color: Colors.green),
              ),
            ),
            Text(
              '₺ ${todaySales.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final double amount;
  final String method;
  final String time;

  const _TransactionCard({
    required this.amount,
    required this.method,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '₺ ${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              method,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        Text(
          time,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
