import '../../../../core/utils/result.dart';
import '../../../../data/models/money_flow.dart';
import '../repositories/accounts_repository.dart';

/// Kredi kartı ödemesi — banka hesabından karta.
///
/// Tek Firestore batch'inde çalışır: iki işlem kaydı + iki bakiye güncellemesi
/// ya hep birlikte yazılır ya hiç yazılmaz.
class RecordCreditPaymentUseCase {
  final AccountsRepository _repository;
  const RecordCreditPaymentUseCase(this._repository);

  Future<Result<void>> call({
    required String bankAccountId,
    required String creditCardId,
    required double amount,
    DateTime? date,
  }) =>
      _repository.recordCreditPayment(
        bankAccountId: bankAccountId,
        creditCardId:  creditCardId,
        amount:        amount,
        date:          date ?? DateTime.now(),
      );
}

/// İki banka hesabı arasında transfer — tek batch, atomik.
class RecordTransferUseCase {
  final AccountsRepository _repository;
  const RecordTransferUseCase(this._repository);

  Future<Result<void>> call({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String description = '',
    DateTime? date,
  }) =>
      _repository.recordTransfer(
        fromAccountId: fromAccountId,
        toAccountId:   toAccountId,
        amount:        amount,
        date:          date ?? DateTime.now(),
        description:   description,
      );
}

/// Tek hesabı ilgilendiren para hareketi — gelir, banka harcaması, kart harcaması.
///
/// Hesap hareketi, ANA DEFTER kaydı ve bakiye güncellemesi tek Firestore
/// batch'inde yazılır. Eskiden bunlar üç ayrı yazmaydı: ortada hata olursa
/// bakiye tutarsız kalıyordu ve ana deftere hiç yazılmadığı için Dashboard
/// cüzdan hareketlerini hiç görmüyordu.
class RecordAccountMovementUseCase {
  final AccountsRepository _repository;
  const RecordAccountMovementUseCase(this._repository);

  Future<Result<void>> call({
    required String accountId,
    required double amount,
    required String description,
    required String category,
    required MoneyFlow flow,
    DateTime? date,
    bool isInstallment = false,
    int installmentCount = 1,
    String? merchantName,
  }) =>
      _repository.recordAccountMovement(
        accountId:        accountId,
        amount:           amount,
        description:      description,
        category:         category,
        flow:             flow,
        date:             date ?? DateTime.now(),
        isInstallment:    isInstallment,
        installmentCount: installmentCount,
        merchantName:     merchantName,
      );
}

/// Taksitli kredi kartı alışverişi.
///
/// Kart limiti satın alma anında toplam tutar kadar bloke olur, gider ise
/// taksitlerin vadelerine dağıtılır. Böylece 12 taksitli bir alışveriş o ayın
/// giderini şişirmez ve gelecek ayların ödeme yükü görünür olur.
class RecordInstallmentPurchaseUseCase {
  final AccountsRepository _repository;
  const RecordInstallmentPurchaseUseCase(this._repository);

  Future<Result<void>> call({
    required String creditCardId,
    required double totalAmount,
    required int installmentCount,
    required String description,
    required String category,
    DateTime? date,
    String? merchantName,
  }) =>
      _repository.recordInstallmentPurchase(
        creditCardId:     creditCardId,
        totalAmount:      totalAmount,
        installmentCount: installmentCount,
        description:      description,
        category:         category,
        date:             date ?? DateTime.now(),
        merchantName:     merchantName,
      );
}
