import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../data/models/money_flow.dart';
import '../models/account_transaction_dto.dart';
import '../models/financial_account_dto.dart';

/// Hesaplar datasource sözleşmesi
abstract class AccountsFirestoreDataSource {
  Future<List<FinancialAccountDto>> getAccounts();
  Future<FinancialAccountDto> addAccount(FinancialAccountDto dto);
  Future<void> updateAccount(FinancialAccountDto dto);
  Future<void> deleteAccount(String id);
  Future<List<AccountTransactionDto>> getTransactions(String accountId);
  Future<AccountTransactionDto> addTransaction(AccountTransactionDto dto);
  Future<void> addTransactions(List<AccountTransactionDto> dtos);
  Future<void> deleteTransaction(String accountId, String txId);

  // ── Atomik muhasebe işlemleri ──────────────────────────────────────────────

  /// Tek batch: hesap hareketi + ANA DEFTER kaydı + bakiye güncellemesi.
  ///
  /// Ana defter (`users/{uid}/transactions`) kaydı hesap hareketiyle **aynı
  /// doküman ID'sini** kullanır; böylece silme tek adımda yapılır ve tekrar
  /// denemede çift kayıt oluşmaz.
  Future<void> addMovementBatch({
    required AccountTransactionDto tx,
    required MoneyFlow flow,
    required double balanceDelta,
    String balanceField,
  });

  Future<void> addTransactionWithBalanceUpdate({
    required AccountTransactionDto tx,
    required String accountId,
    required double balanceDelta,
    String balanceField,
  });
  Future<void> addCreditPaymentBatch({
    required String bankAccountId,
    required String creditCardId,
    required double amount,
    required String txId,
    required DateTime date,
    required String uid,
  });
  Future<void> addInstallmentPurchaseBatch({
    required List<AccountTransactionDto> installments,
    required String cardId,
    required double totalAmount,
  });
  Future<void> addTransferBatch({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required String txId,
    required DateTime date,
    required String description,
  });
  Future<void> updateStatementBalance({
    required String cardId,
    required double statementBalance,
    required double minimumPayment,
  });
  Future<void> updateBankBalance({
    required String accountId,
    required double newBalance,
  });
}

/// Firestore tabanlı hesap veri kaynağı
/// users/{uid}/accounts/{accountId}/accountTransactions/{txId}
class AccountsFirestoreDataSourceImpl implements AccountsFirestoreDataSource {
  final _fs = FirestoreService.instance;

  String get _uid => AuthService.instance.userId ?? '';

  @override
  Future<List<FinancialAccountDto>> getAccounts() async {
    if (_uid.isEmpty) return [];
    final snap = await _fs.accounts(_uid).orderBy('createdAt').get();
    return snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data() as Map);
      data['id'] = doc.id;
      return FinancialAccountDto.fromJson(data);
    }).toList();
  }

  @override
  Future<FinancialAccountDto> addAccount(FinancialAccountDto dto) async {
    if (_uid.isEmpty) return dto;
    final data = dto.toJson();
    data.remove('id');
    await _fs.accounts(_uid).doc(dto.id).set(data);
    return dto;
  }

  @override
  Future<void> updateAccount(FinancialAccountDto dto) async {
    if (_uid.isEmpty) return;
    final data = dto.toJson();
    data.remove('id');
    await _fs.accounts(_uid).doc(dto.id).update(data);
  }

  @override
  Future<void> deleteAccount(String id) async {
    if (_uid.isEmpty) return;
    // Hesap hareketleri + AYNI id'li ana defter kayıtları + hesabın kendisi.
    // Ana defter kayıtları silinmezse hesabı silen kullanıcının Dashboard'ında
    // öksüz gelir/gider kalır.
    //
    // Her hareket 2 doküman siler; taksitli alışverişlerle işlem sayısı hızla
    // artabildiği için 500'lük Firestore batch limitine karşı parçalanır.
    final txSnap = await _fs.accountTransactions(_uid, id).get();
    final db = FirebaseFirestore.instance;
    const chunkSize = 200;

    for (var i = 0; i < txSnap.docs.length; i += chunkSize) {
      final batch = db.batch();
      for (final doc in txSnap.docs.skip(i).take(chunkSize)) {
        batch.delete(doc.reference);
        batch.delete(_fs.transactions(_uid).doc(doc.id));
      }
      await batch.commit();
    }

    await _fs.accounts(_uid).doc(id).delete();
  }

  @override
  Future<List<AccountTransactionDto>> getTransactions(String accountId) async {
    if (_uid.isEmpty) return [];
    final snap = await _fs
        .accountTransactions(_uid, accountId)
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data() as Map);
      data['id'] = doc.id;
      return AccountTransactionDto.fromJson(data);
    }).toList();
  }

  @override
  Future<AccountTransactionDto> addTransaction(
      AccountTransactionDto dto) async {
    if (_uid.isEmpty) return dto;
    final data = dto.toJson();
    data.remove('id');
    await _fs
        .accountTransactions(_uid, dto.accountId)
        .doc(dto.id)
        .set(data);
    return dto;
  }

  @override
  Future<void> addTransactions(List<AccountTransactionDto> dtos) async {
    if (_uid.isEmpty || dtos.isEmpty) return;
    final db = FirebaseFirestore.instance;
    // Her hareket 2 doküman yazar (hesap + ana defter) → 500'lük Firestore
    // batch limiti için chunk boyutu 200.
    const chunkSize = 200;
    for (var i = 0; i < dtos.length; i += chunkSize) {
      final chunk = dtos.skip(i).take(chunkSize).toList();
      final batch = db.batch();
      for (final dto in chunk) {
        final data = dto.toJson()..remove('id');
        batch.set(_fs.accountTransactions(_uid, dto.accountId).doc(dto.id), data);

        // Ekstre satırının akış tipi: gelir mi, kart ödemesi mi, gider mi
        final flow = MoneyFlowParser.parse(
          rawFlow: dto.flow,
          rawType: dto.type,
          categorySlug: dto.category,
        );
        _stageLedgerWrite(batch, tx: dto, flow: flow);
      }
      await batch.commit();
    }
  }

  @override
  Future<void> deleteTransaction(String accountId, String txId) async {
    if (_uid.isEmpty) return;
    // Ana defter kaydı aynı id ile yazılıyor — ikisi birlikte silinir,
    // aksi hâlde Dashboard'da öksüz bir hareket kalırdı.
    final batch = FirebaseFirestore.instance.batch();
    batch.delete(_fs.accountTransactions(_uid, accountId).doc(txId));
    batch.delete(_fs.transactions(_uid).doc(txId));
    await batch.commit();
  }

  // ── Ana defter köprüsü ─────────────────────────────────────────────────────
  //
  // Cüzdan hareketleri eskiden YALNIZCA accountTransactions'a yazılıyordu;
  // Dashboard bu koleksiyonu okumadığı için kredi kartı ve banka harcamaları
  // hiçbir toplamda görünmüyordu. Artık her hareket ana deftere de yazılır.

  /// Ana defter (`users/{uid}/transactions`) kaydını hazırlar.
  /// Alanlar TransactionDto şemasıyla birebir uyumludur.
  Map<String, dynamic> _ledgerDoc({
    required AccountTransactionDto tx,
    required MoneyFlow flow,
  }) =>
      {
        'userId':    _uid,
        'amount':    tx.amount,
        'category':  tx.category,
        'type':      flow.countsAsIncome ? 'income' : 'expense',
        'source':    tx.source,
        'date':      tx.date,          // ISO string — TransactionDto beklediği tip
        'note':      tx.description,
        'flow':      flow.slug,
        'accountId': tx.accountId,
      };

  /// Ana defter kaydını batch'e ekler. Hesap hareketiyle AYNI id kullanılır.
  void _stageLedgerWrite(
    WriteBatch batch, {
    required AccountTransactionDto tx,
    required MoneyFlow flow,
  }) {
    batch.set(
      _fs.transactions(_uid).doc(tx.id),
      _ledgerDoc(tx: tx, flow: flow),
    );
  }

  @override
  Future<void> addMovementBatch({
    required AccountTransactionDto tx,
    required MoneyFlow flow,
    required double balanceDelta,
    String balanceField = 'balance',
  }) async {
    if (_uid.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();

    // 1) Hesap hareketi (hesap detay ekranı için)
    final data = tx.toJson()..remove('id');
    batch.set(_fs.accountTransactions(_uid, tx.accountId).doc(tx.id), data);

    // 2) Ana defter kaydı (Dashboard / raporlama için)
    _stageLedgerWrite(batch, tx: tx, flow: flow);

    // 3) Bakiye — increment ile yarış koşulu yok
    if (balanceDelta != 0) {
      batch.update(_fs.accounts(_uid).doc(tx.accountId), {
        balanceField: FieldValue.increment(balanceDelta),
      });
    }

    await batch.commit();
  }

  // ── Atomik muhasebe işlemleri ──────────────────────────────────────────────

  /// Atomik: işlem yaz + hesap bakiyesini güncelle
  @override
  Future<void> addTransactionWithBalanceUpdate({
    required AccountTransactionDto tx,
    required String accountId,
    required double balanceDelta,
    String balanceField = 'balance',
  }) async {
    if (_uid.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    final data = tx.toJson()..remove('id');
    batch.set(_fs.accountTransactions(_uid, accountId).doc(tx.id), data);
    batch.update(_fs.accounts(_uid).doc(accountId), {
      balanceField: FieldValue.increment(balanceDelta),
    });
    await batch.commit();
  }

  /// Atomik: taksitli kart alışverişi.
  ///
  /// Her taksit AYRI bir hareket olarak yazılır (kendi ayının tarihiyle), kart
  /// borcu ise TEK seferde toplam tutar kadar artar — kart limiti satın alma
  /// anında tamamen bloke olur.
  ///
  /// Geleceğe tarihli taksitler ekstre devrinde doğru davranır:
  /// `yeniEkstre = toplamBorç − kesim sonrası harcamalar` formülü, henüz
  /// gelmemiş taksitleri "kesim sonrası" saydığı için o ayki ekstreye yalnızca
  /// vadesi gelen taksit girer.
  @override
  Future<void> addInstallmentPurchaseBatch({
    required List<AccountTransactionDto> installments,
    required String cardId,
    required double totalAmount,
  }) async {
    if (_uid.isEmpty || installments.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();

    for (final dto in installments) {
      batch.set(
        _fs.accountTransactions(_uid, cardId).doc(dto.id),
        dto.toJson()..remove('id'),
      );
      _stageLedgerWrite(batch, tx: dto, flow: MoneyFlow.cardExpense);
    }

    batch.update(_fs.accounts(_uid).doc(cardId), {
      'usedAmount': FieldValue.increment(totalAmount),
    });

    await batch.commit();
  }

  /// Atomik: kredi kartı ödemesi — banka bakiyesi düşer, kart borcu azalır
  @override
  Future<void> addCreditPaymentBatch({
    required String bankAccountId,
    required String creditCardId,
    required double amount,
    required String txId,
    required DateTime date,
    required String uid,
  }) async {
    if (_uid.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    // DTO 'date' alanını String bekler — Timestamp yazılırsa okuma sırasında
    // AccountTransactionDto.fromJson tip hatası verir.
    final now = date.toIso8601String();

    // Banka: gider işlemi
    batch.set(_fs.accountTransactions(_uid, bankAccountId).doc('${txId}_b'), {
      'accountId': bankAccountId,
      'userId': _uid,
      'amount': amount,
      'description': 'Kredi Kartı Ödemesi',
      'date': now,
      'type': 'creditPayment',
      'category': creditCardId,
      'isInstallment': false,
      'installmentCount': 1,
      'installmentNumber': 1,
      'source': 'manual',
    });
    batch.update(_fs.accounts(_uid).doc(bankAccountId), {
      'balance': FieldValue.increment(-amount),
    });

    // Kart: ödeme alındı işlemi
    batch.set(_fs.accountTransactions(_uid, creditCardId).doc('${txId}_c'), {
      'accountId': creditCardId,
      'userId': _uid,
      'amount': amount,
      'description': 'Ödeme Alındı',
      'date': now,
      'type': 'income',
      'category': 'odeme',
      'isInstallment': false,
      'installmentCount': 1,
      'installmentNumber': 1,
      'source': 'manual',
    });
    batch.update(_fs.accounts(_uid).doc(creditCardId), {
      'usedAmount': FieldValue.increment(-amount),
      'statementBalance': FieldValue.increment(-amount),
    });

    // Ana defter: TEK kayıt — nakit çıkışı. flow=cardPayment olduğu için
    // GİDER SAYILMAZ (gider zaten kart harcaması anında yazıldı).
    batch.set(_fs.transactions(_uid).doc('${txId}_b'), {
      'userId':           _uid,
      'amount':           amount,
      'category':         'diger',
      'type':             'expense',
      'source':           'wallet',
      'date':             now,
      'note':             'Kredi Kartı Ödemesi',
      'flow':             MoneyFlow.cardPayment.slug,
      'accountId':        bankAccountId,
      'counterAccountId': creditCardId,
    });

    await batch.commit();
  }

  /// Atomik: iki banka hesabı arasında transfer
  @override
  Future<void> addTransferBatch({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required String txId,
    required DateTime date,
    required String description,
  }) async {
    if (_uid.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    // DTO 'date' alanı String — bkz. addCreditPaymentBatch notu
    final now = date.toIso8601String();

    // Gönderen hesap: gider
    batch.set(
        _fs.accountTransactions(_uid, fromAccountId).doc('${txId}_from'), {
      'accountId': fromAccountId,
      'userId': _uid,
      'amount': amount,
      'description': description.isEmpty ? 'Transfer Gönderildi' : description,
      'date': now,
      'type': 'transfer',
      'category': toAccountId,
      'isInstallment': false,
      'installmentCount': 1,
      'installmentNumber': 1,
      'source': 'manual',
    });
    batch.update(_fs.accounts(_uid).doc(fromAccountId), {
      'balance': FieldValue.increment(-amount),
    });

    // Alıcı hesap: gelir
    batch.set(_fs.accountTransactions(_uid, toAccountId).doc('${txId}_to'), {
      'accountId': toAccountId,
      'userId': _uid,
      'amount': amount,
      'description': description.isEmpty ? 'Transfer Alındı' : description,
      'date': now,
      'type': 'income',
      'category': fromAccountId,
      'isInstallment': false,
      'installmentCount': 1,
      'installmentNumber': 1,
      'source': 'manual',
    });
    batch.update(_fs.accounts(_uid).doc(toAccountId), {
      'balance': FieldValue.increment(amount),
    });

    // Ana defter: TEK kayıt. flow=transfer hiçbir toplamı etkilemez —
    // para kullanıcının kendi hesapları arasında yer değiştirdi.
    batch.set(_fs.transactions(_uid).doc('${txId}_from'), {
      'userId':           _uid,
      'amount':           amount,
      'category':         'diger',
      'type':             'expense',
      'source':           'wallet',
      'date':             now,
      'note':             description.isEmpty ? 'Transfer' : description,
      'flow':             MoneyFlow.transfer.slug,
      'accountId':        fromAccountId,
      'counterAccountId': toAccountId,
    });

    await batch.commit();
  }

  /// Ekstre değerlerini güncelle
  @override
  Future<void> updateStatementBalance({
    required String cardId,
    required double statementBalance,
    required double minimumPayment,
  }) async {
    if (_uid.isEmpty) return;
    await _fs.accounts(_uid).doc(cardId).update({
      'statementBalance': statementBalance,
      'minimumPayment': minimumPayment,
    });
  }

  /// Banka bakiyesini direkt güncelle
  @override
  Future<void> updateBankBalance({
    required String accountId,
    required double newBalance,
  }) async {
    if (_uid.isEmpty) return;
    await _fs.accounts(_uid).doc(accountId).update({'balance': newBalance});
  }
}
