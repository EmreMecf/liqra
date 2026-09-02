import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/money_flow.dart';
import '../models/transaction_model.dart';
import '../models/recurring_item_model.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/portfolio_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';

/// Ana uygulama state yöneticisi
/// Kullanıcı profili SharedPreferences'ta saklanır, mock veri yok
class AppProvider extends ChangeNotifier {

  // ── Onboarding / profil durumu ─────────────────────────────────────────────
  // AuthService.profileComplete ile senkronize — main.dart'ta birlikte kullanılır
  bool get isOnboarded => AuthService.instance.isLoggedIn &&
      AuthService.instance.profileComplete;

  UserModel? _user;
  UserModel get user => _user ?? UserModel(
    id: AuthService.instance.userId ?? 'guest',
    name: '',
    email: AuthService.instance.userEmail ?? '',
    riskProfile: 'mid',
    monthlyIncome: 0,
    currency: 'TRY',
  );

  /// Kullanıcı rolü — Cloud Functions (onUserCreated) users/{uid}.role alanına yazar.
  /// 'personal' | 'merchant_admin' | 'merchant_cashier'
  String _userRole = 'personal';
  String get userRole => _userRole;

  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  bool _txLoaded = false;
  bool get txLoaded => _txLoaded;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _txSub;

  // ── Ay filtreleme & özet (hesaplama Firestore'a gitmez) ──────────────────
  List<TransactionModel> transactionsForMonth(int year, int month) =>
      _transactions.where((t) => t.date.year == year && t.date.month == month).toList();

  ({double income, double expenses, double net, Map<String, double> byCategory})
      monthlySummary({int? year, int? month}) {
    final now = DateTime.now();
    final txs = transactionsForMonth(year ?? now.year, month ?? now.month);
    double income = 0, expenses = 0;
    final Map<String, double> byCategory = {};
    for (final t in txs) {
      if (t.isIncome) {
        income += t.amount;
      } else if (t.isExpense) {
        // isExpense artık flow tabanlı: yatırım/transfer/kart ödemesi hariç
        expenses += t.amount;
        byCategory[t.category.label] = (byCategory[t.category.label] ?? 0) + t.amount;
      }
    }
    return (income: income, expenses: expenses, net: income - expenses, byCategory: byCategory);
  }

  List<RecurringItemModel> _recurringItems = [];
  List<RecurringItemModel> get recurringItems => List.unmodifiable(_recurringItems);

  List<GoalModel> _goals = [];
  List<GoalModel> get goals => List.unmodifiable(_goals);

  PortfolioModel _portfolio = PortfolioModel(
    id: 'p_empty',
    userId: '',
    assets: [],
  );
  PortfolioModel get portfolio => _portfolio;

  // AI konuşma geçmişi
  final List<Map<String, String>> _aiMessages = [];
  List<Map<String, String>> get aiMessages => List.unmodifiable(_aiMessages);

  String _aiMode = 'budget_audit';
  String get aiMode => _aiMode;

  bool _aiIsTyping = false;
  bool get aiIsTyping => _aiIsTyping;

  // ── Profil Yükleme (giriş sonrası) ────────────────────────────────────────

  Future<void> loadUserProfile() async {
    final uid = AuthService.instance.userId;
    if (uid == null) return;

    try {
      final fs = FirestoreService.instance;

      // Profil belgesi
      final userSnap = await fs.userDoc(uid).get();
      final userData = userSnap.data();

      _user = UserModel(
        id: uid,
        name: userData?['name'] as String? ?? '',
        email: AuthService.instance.userEmail ?? '',
        riskProfile: userData?['riskProfile'] as String? ?? 'mid',
        monthlyIncome: (userData?['monthlyIncome'] as num?)?.toDouble() ?? 0,
        currency: 'TRY',
      );

      _userRole = userData?['role'] as String? ?? 'personal';

      // Hedefler ve bütçe limitleri
      await _loadGoalsFromFirestore(uid);
      await _loadBudget(uid);

      _recurringItems = [];
      _portfolio = PortfolioModel(id: 'p_$uid', userId: uid, assets: []);

      // Real-time stream — bir kez abone ol, her değişimde UI güncellenir
      _listenToTransactions(uid);

      notifyListeners();
    } catch (e) {
      debugPrint('[AppProvider] loadUserProfile error: $e');
    }
  }

  Future<void> _loadGoalsFromFirestore(String uid) async {
    try {
      final snap = await FirestoreService.instance.goals(uid).get();
      _goals = snap.docs.map((doc) {
        final d = doc.data();
        return GoalModel(
          id: doc.id,
          userId: uid,
          title: d['title'] as String? ?? '',
          targetAmount: (d['targetAmount'] as num?)?.toDouble() ?? 0,
          currentAmount: (d['currentAmount'] as num?)?.toDouble() ?? 0,
          manualAmount:  (d['manualAmount'] as num?)?.toDouble() ?? 0,
          deadline: (d['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: d['status'] as String? ?? 'active',
          emoji: d['emoji'] as String? ?? '🎯',
        );
      }).toList();
    } catch (e) {
      debugPrint('[AppProvider] _loadGoalsFromFirestore error: $e');
      _goals = [];
    }
  }

  void _listenToTransactions(String uid) {
    _txSub?.cancel();
    _txLoaded = false;
    _txSub = FirestoreService.instance
        .transactions(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .listen(
      (snap) {
        _transactions = snap.docs.map(_docToModel).toList();
        _txLoaded = true;
        notifyListeners();
      },
      onError: (e) {
        // Çıkış yapıldıktan sonra Firestore son bir hata gönderebilir — yoksay
        if (AuthService.instance.userId == null) return;
        debugPrint('[AppProvider] transactions stream error: $e');
        _txLoaded = true;
        notifyListeners();
      },
    );
  }

  TransactionModel _docToModel(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final rawType = d['type'] as String? ?? 'expense';
    final type = (rawType == 'gelir') ? 'income'
               : (rawType == 'gider') ? 'expense'
               : rawType;
    return TransactionModel(
      id:       doc.id,
      userId:   d['userId'] as String? ?? '',
      amount:   (d['amount'] as num?)?.toDouble() ?? 0,
      // Tek ayrıştırıcı: hem slug hem eski Türkçe etiketleri tanır
      category: TransactionCategoryX.parse(d['category'] as String?),
      type:     type,
      source:   d['source'] as String? ?? 'manual',
      date:     DateTime.tryParse(d['date'] as String? ?? '') ?? DateTime.now(),
      note:     d['note'] as String?,
      // Eski kayıtlarda `flow` yok — type + kategoriden türetilir
      flow: MoneyFlowParser.parse(
        rawFlow: d['flow'] as String?,
        rawType: type,
        categorySlug: TransactionCategoryX.slugOf(d['category'] as String?),
      ),
      accountId: d['accountId'] as String?,
    );
  }


  // ── Onboarding Tamamlama ────────────────────────────────────────────────────

  Future<void> completeOnboarding({
    required String name,
    required double monthlyIncome,
    required String riskProfile,
    required String goalTitle,
    required double goalAmount,
    required DateTime goalDeadline,
  }) async {
    final uid = AuthService.instance.userId;
    if (uid == null) return;

    final fs = FirestoreService.instance;

    // Kullanıcı profilini Firestore'a kaydet.
    // merge:true ZORUNLU — aksi halde onUserCreated'ın yazdığı 'role' ve
    // NotificationService'in yazdığı 'fcmToken' alanları silinir; güvenlik
    // kuralı da 'role' alanına dokunan istemci yazımını reddeder.
    await fs.userDoc(uid).set({
      'name': name,
      'riskProfile': riskProfile,
      'monthlyIncome': monthlyIncome,
      'currency': 'TRY',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // İlk hedefi Firestore'a kaydet
    final goalId = 'goal_${uid}_0';
    await fs.goals(uid).doc(goalId).set({
      'title': goalTitle,
      'targetAmount': goalAmount,
      'currentAmount': 0.0,
      'deadline': Timestamp.fromDate(goalDeadline),
      'status': 'active',
      'emoji': '🎯',
      'createdAt': FieldValue.serverTimestamp(),
    });

    _user = UserModel(
      id: uid,
      name: name,
      email: AuthService.instance.userEmail ?? '',
      riskProfile: riskProfile,
      monthlyIncome: monthlyIncome,
      currency: 'TRY',
    );

    _goals = [
      GoalModel(
        id: goalId,
        userId: uid,
        title: goalTitle,
        targetAmount: goalAmount,
        currentAmount: 0,
        deadline: goalDeadline,
        status: 'active',
        emoji: '🎯',
      ),
    ];

    _transactions = [];
    _recurringItems = [];
    _portfolio = PortfolioModel(id: 'p_$uid', userId: uid, assets: []);

    // AuthService'e profil tamamlandığını bildir
    await AuthService.instance.markProfileComplete();

    notifyListeners();
  }

  // ── Oturumu Kapat ──────────────────────────────────────────────────────────

  Future<void> signOut() async {
    _txSub?.cancel();
    _txSub = null;
    _txLoaded = false;
    _user = null;
    _userRole = 'personal';
    _transactions = [];
    _recurringItems = [];
    _goals = [];
    _portfolio = PortfolioModel(id: 'p_empty', userId: '', assets: []);
    _aiMessages.clear();
    await AuthService.instance.signOut();
    notifyListeners();
  }

  // ── İşlemler ───────────────────────────────────────────────────────────────

  void addTransaction(TransactionModel tx) {
    _transactions.insert(0, tx);
    notifyListeners();
  }

  /// İşlemi Firestore'dan siler. Önce yerel listeden kaldırır (optimistic),
  /// silme başarısız olursa stream bir sonraki snapshot'ta kaydı geri getirir.
  ///
  /// Not: Eskiden yalnızca yerel listeyi temizliyordu; Firestore stream'i
  /// kaydı anında geri yüklediği için silme işlemi kalıcı olmuyordu.
  Future<void> deleteTransaction(String id) async {
    final uid = AuthService.instance.userId;
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();

    if (uid == null) return;
    try {
      await FirestoreService.instance.transactions(uid).doc(id).delete();
    } catch (e) {
      debugPrint('[AppProvider] deleteTransaction error: $e');
    }
  }

  List<TransactionModel> get currentMonthTransactions {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.date.month == now.month && t.date.year == now.year)
        .toList();
  }

  Map<TransactionCategory, double> get monthlyExpensesByCategory =>
      expensesByCategoryForMonth(DateTime.now().year, DateTime.now().month);

  /// Kategori dağılımı — gider sayılan hareketler (flow.countsAsExpense).
  /// Yatırım/transfer/kart ödemesi burada GÖRÜNMEZ; böylece pastanın
  /// dilimlerinin toplamı [expensesForMonth] ile birebir aynı olur.
  Map<TransactionCategory, double> expensesByCategoryForMonth(int year, int month) {
    final Map<TransactionCategory, double> totals = {};
    for (final tx in transactionsForMonth(year, month)) {
      if (tx.isExpense) {
        totals[tx.category] = (totals[tx.category] ?? 0) + tx.amount;
      }
    }
    return totals;
  }

  double incomeForMonth(int year, int month) =>
      transactionsForMonth(year, month)
          .where((t) => t.isIncome)
          .fold(0.0, (acc, t) => acc + t.amount);

  /// TEK gider tanımı — [TransactionModel.isExpense] (flow tabanlı).
  /// Eskiden burada `category != yatirim` özel kontrolü vardı ve uygulamanın
  /// başka yerlerinde bu kontrol YOKTU; aynı ay için farklı toplamlar çıkıyordu.
  double expensesForMonth(int year, int month) =>
      transactionsForMonth(year, month)
          .where((t) => t.isExpense)
          .fold(0.0, (acc, t) => acc + t.amount);

  /// Yatırıma aktarılan tutar — gider değildir, ayrı gösterilir.
  double investedForMonth(int year, int month) =>
      transactionsForMonth(year, month)
          .where((t) => t.flow == MoneyFlow.investment)
          .fold(0.0, (acc, t) => acc + t.amount);

  double get monthlyIncome =>
      incomeForMonth(DateTime.now().year, DateTime.now().month);

  double get monthlyExpenses =>
      expensesForMonth(DateTime.now().year, DateTime.now().month);

  double get netCash => monthlyIncome - monthlyExpenses;

  /// Tüm zamanların NAKİT bakiyesi.
  ///
  /// Akış tipinin nakit yönüne göre hesaplanır: kart harcaması nakdi
  /// etkilemez, kart ödemesi ve yatırım azaltır. Eskiden her gider kaydı
  /// (yatırım dahil) körü körüne düşülüyordu.
  double get totalBalance =>
      _transactions.fold(0.0, (acc, t) => acc + t.cashEffect);

  /// Tüm zamanların toplam geliri
  double get totalIncomeAllTime =>
      _transactions.where((t) => t.isIncome).fold(0.0, (acc, t) => acc + t.amount);

  /// Tüm zamanların toplam gideri — [expensesForMonth] ile aynı tanım
  double get totalExpenseAllTime =>
      _transactions.where((t) => t.isExpense).fold(0.0, (acc, t) => acc + t.amount);

  /// Tüm zamanlarda yatırıma aktarılan tutar (gider değil)
  double get totalInvestedAllTime => _transactions
      .where((t) => t.flow == MoneyFlow.investment)
      .fold(0.0, (acc, t) => acc + t.amount);

  // ── Sabit Kalemler ──────────────────────────────────────────────────────────

  void addRecurringItem(RecurringItemModel item) {
    _recurringItems.add(item);
    notifyListeners();
  }

  void updateRecurringItem(RecurringItemModel updated) {
    final idx = _recurringItems.indexWhere((r) => r.id == updated.id);
    if (idx != -1) {
      _recurringItems[idx] = updated;
      notifyListeners();
    }
  }


  // ── Bütçe Limitleri ────────────────────────────────────────────────────────

  BudgetModel _budget = BudgetModel.empty;
  BudgetModel get budget => _budget;

  Future<void> _loadBudget(String uid) async {
    try {
      final snap = await FirestoreService.instance.budgets(uid).get();
      _budget = BudgetModel.fromMap(snap.data());
    } catch (e) {
      debugPrint('[AppProvider] bütçe okunamadı: $e');
      _budget = BudgetModel.empty;
    }
  }

  /// Bir kategorinin aylık limitini belirler. `null` veya 0 limiti kaldırır.
  Future<void> setBudgetLimit(TransactionCategory category, double? limit) async {
    final uid = AuthService.instance.userId;
    if (uid == null) return;

    final previous = _budget;
    _budget = _budget.withLimit(category, limit);
    notifyListeners();

    try {
      await FirestoreService.instance
          .budgets(uid)
          .set(_budget.toMap(), SetOptions(merge: false));
    } catch (e) {
      // Yazma başarısızsa eski hâle dön — kullanıcı kaydedilmemiş bir limiti
      // kaydedilmiş sanmasın.
      debugPrint('[AppProvider] bütçe yazılamadı: $e');
      _budget = previous;
      notifyListeners();
    }
  }

  /// Verilen ayın bütçe durumu — yalnızca limiti olan kategoriler.
  /// Aşım oranına göre sıralanır: en kritik başta.
  List<BudgetStatus> budgetStatusForMonth(int year, int month) {
    if (_budget.isEmpty) return const [];

    final spent = expensesByCategoryForMonth(year, month);
    final out = <BudgetStatus>[];

    for (final entry in _budget.limits.entries) {
      final category = TransactionCategoryX.parse(entry.key);
      out.add(BudgetStatus(
        category: category,
        limit: entry.value,
        spent: spent[category] ?? 0,
      ));
    }

    out.sort((a, b) => b.rawRatio.compareTo(a.rawRatio));
    return out;
  }

  /// Bu ayın bütçe durumu.
  List<BudgetStatus> get budgetStatus =>
      budgetStatusForMonth(DateTime.now().year, DateTime.now().month);

  /// Limiti aşılmış kategoriler.
  List<BudgetStatus> get overBudget =>
      budgetStatus.where((b) => b.isOver).toList();

  // ── Hedefler ───────────────────────────────────────────────────────────────

  GoalModel? get primaryGoal =>
      _goals.where((g) => g.status == 'active').firstOrNull;

  Future<void> addGoal(GoalModel goal) async {
    _goals.add(goal);
    notifyListeners();
    final uid = AuthService.instance.userId;
    if (uid != null) {
      await FirestoreService.instance.goals(uid).doc(goal.id).set({
        'title':         goal.title,
        'targetAmount':  goal.targetAmount,
        'currentAmount': goal.currentAmount,
        'manualAmount':  goal.manualAmount,
        'deadline':      Timestamp.fromDate(goal.deadline),
        'status':        goal.status,
        'emoji':         goal.emoji ?? '🎯',
        'createdAt':     FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> deleteGoal(String goalId) async {
    _goals.removeWhere((g) => g.id == goalId);
    notifyListeners();
    final uid = AuthService.instance.userId;
    if (uid != null) {
      await FirestoreService.instance.goals(uid).doc(goalId).delete();
    }
  }

  Future<void> updateGoal(GoalModel updated) async {
    final idx = _goals.indexWhere((g) => g.id == updated.id);
    if (idx != -1) {
      _goals[idx] = updated;
      final uid = AuthService.instance.userId;
      if (uid != null) {
        await FirestoreService.instance.goals(uid).doc(updated.id).update({
          'currentAmount': updated.currentAmount,
          'manualAmount':  updated.manualAmount,
          'status':        updated.status,
          'title':         updated.title,
          'targetAmount':  updated.targetAmount,
          'deadline':      Timestamp.fromDate(updated.deadline),
          'emoji':         updated.emoji ?? '🎯',
        });
      }
      notifyListeners();
    }
  }

  /// Portföy bileşenini hedefe senkronize eder.
  ///
  /// ÖNEMLİ: [GoalModel.manualAmount] (kullanıcının "Para Ekle" ile eklediği
  /// nakit birikim) korunur. Eskiden bu fonksiyon currentAmount'ı doğrudan
  /// portföy toplamıyla EZİYORDU; uygulama her açıldığında elle eklenen
  /// birikim siliniyordu.
  Future<void> syncGoalWithPortfolio(List<dynamic> assets) async {
    final goal = primaryGoal;
    if (goal == null) return;

    // Her varlık için miktar × alış fiyatı = yatırılan tutar
    double totalInvested = 0;
    for (final a in assets) {
      final qty      = (a.quantity  as num?)?.toDouble() ?? 0;
      final buyPrice = (a.buyPrice  as num?)?.toDouble() ?? 0;
      totalInvested += qty * buyPrice;
    }

    // Hedef birikimi = elle eklenen nakit + portföye aktarılan tutar
    final newAmount =
        (goal.manualAmount + totalInvested).clamp(0.0, goal.targetAmount);
    if (newAmount == goal.currentAmount) return; // değişiklik yoksa atla

    await updateGoal(goal.copyWith(
      currentAmount: newAmount,
      status: newAmount >= goal.targetAmount ? 'completed' : 'active',
    ));
    debugPrint('[AppProvider] Goal synced: $newAmount / ${goal.targetAmount}');
  }

  // ── Kullanıcı Güncellemesi ──────────────────────────────────────────────────

  Future<void> updateUser(UserModel updated) async {
    _user = updated;
    final uid = AuthService.instance.userId;
    if (uid != null) {
      await FirestoreService.instance.userDoc(uid).update({
        'name': updated.name,
        'riskProfile': updated.riskProfile,
        'monthlyIncome': updated.monthlyIncome,
      });
    }
    notifyListeners();
  }

  // ── AI Asistan ──────────────────────────────────────────────────────────────

  void setAiMode(String mode) {
    _aiMode = mode;
    notifyListeners();
  }

  Future<void> sendAiMessage(String userMessage) async {
    _aiMessages.add({'role': 'user', 'content': userMessage});
    _aiIsTyping = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1500));
    _aiMessages.add({'role': 'assistant', 'content': '...'});
    _aiIsTyping = false;
    notifyListeners();
  }
}
