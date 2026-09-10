import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:muhasebe/core/services/account_deletion_service.dart';

/// Hesap silme kapsamı testi.
///
/// ── Neden kaynak kodu tarıyoruz ──────────────────────────────────────────────
/// Firestore'da bir dokümanı silmek alt koleksiyonlarını **silmez**. Bu yüzden
/// `AccountDeletionService` silinecek koleksiyonların adını elle tutar. Elle
/// tutulan her liste eninde sonunda geride kalır: `settings` (bütçe limitleri)
/// aylarca eksikti ve kullanıcı "hesabımı sil" dediği hâlde limitleri
/// sunucuda kalıyordu.
///
/// Firestore'u testte ayağa kaldırmadan bu hatayı yakalamanın tek yolu
/// kaynağa bakmak: `users/{uid}` altında hangi koleksiyonlara dokunuluyorsa
/// hepsi silme listesinde olmalı.
void main() {
  group('Hesap silme kapsamı', () {
    /// `.collection('users')` … `.collection('X')` zincirlerinden X'leri toplar.
    Set<String> subcollectionsUsedInSource() {
      final pattern = RegExp(
        r"""collection\(\s*'users'\s*\)[\s\S]{0,240}?\.collection\(\s*'(\w+)'\s*\)""",
      );

      final found = <String>{};
      final lib = Directory('lib');
      for (final entity in lib.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        for (final m in pattern.allMatches(entity.readAsStringSync())) {
          final name = m.group(1)!;
          // Arka arkaya iki `collection('users')` çağrısı varsa desen
          // ikincisini "alt koleksiyon" sanır. Kök koleksiyonun kendisi
          // silme listesine girmez.
          if (name == 'users') continue;
          found.add(name);
        }
      }
      return found;
    }

    test('kod tabanındaki her alt koleksiyon silme listesinde', () {
      final used = subcollectionsUsedInSource();

      expect(used, isNotEmpty,
          reason: 'Tarama hiçbir şey bulmadıysa desen bozulmuştur.');

      // `accounts` listede değil çünkü altındaki accountTransactions ile
      // birlikte ayrıca ele alınıyor.
      final covered = {...AccountDeletionService.subcollections, 'accounts'};

      final missing = used.difference(covered);
      expect(
        missing,
        isEmpty,
        reason: 'Bu alt koleksiyonlar yazılıyor ama hesap silinince '
            'temizlenmiyor: $missing. AccountDeletionService.subcollections '
            'listesine ekle.',
      );
    });

    test('bütçe limitleri (settings) siliniyor', () {
      // Bu satır bir regresyon kaydıdır: settings unutulmuştu.
      expect(AccountDeletionService.subcollections, contains('settings'));
    });

    test('listede tekrar yok', () {
      final list = AccountDeletionService.subcollections;
      expect(list.toSet().length, list.length);
    });

    test('accounts listede DEĞİL — çift silme denemesi olmasın', () {
      // accounts, accountTransactions temizlendikten sonra ayrıca siliniyor.
      // Listeye de eklenirse aynı koleksiyon iki kez geziliyor demektir.
      expect(AccountDeletionService.subcollections, isNot(contains('accounts')));
    });
  });
}
