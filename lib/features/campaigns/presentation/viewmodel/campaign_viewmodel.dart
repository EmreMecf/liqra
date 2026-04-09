import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/campaign_entity.dart';
import '../../domain/repositories/campaign_repository.dart';

enum CampaignFilter { all, yemek, market, akaryakit, seyahat, alisveris, fatura }

class CampaignViewModel extends ChangeNotifier {
  final CampaignRepository _repo;

  CampaignViewModel(this._repo) {
    _subscribe();
  }

  List<CampaignEntity> _all      = [];
  bool                 _loading  = true;
  String?              _error;
  String?              _selectedBank;     // null = tüm bankalar
  CampaignCategory?    _selectedCategory; // null = tüm kategoriler
  String               _search   = '';

  bool                 get isLoading       => _loading;
  String?              get error           => _error;
  String?              get selectedBank    => _selectedBank;
  CampaignCategory?    get selectedCategory => _selectedCategory;
  String               get search          => _search;

  /// Benzersiz bankalar
  List<String> get banks {
    final seen = <String>{};
    return _all.map((c) => c.bank).where(seen.add).toList();
  }

  /// Filtre uygulanmış liste
  List<CampaignEntity> get campaigns {
    var list = _all;

    if (_selectedBank != null) {
      list = list.where((c) => c.bank == _selectedBank).toList();
    }
    if (_selectedCategory != null) {
      list = list.where((c) => c.category == _selectedCategory).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((c) =>
          c.title.toLowerCase().contains(q) ||
          c.bank.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  StreamSubscription<List<CampaignEntity>>? _sub;

  void _subscribe() {
    _sub = _repo.watchCampaigns().listen(
      (data) {
        _all     = data;
        _loading = false;
        _error   = null;
        notifyListeners();
      },
      onError: (e) {
        _loading = false;
        _error   = 'Kampanyalar yüklenemedi';
        notifyListeners();
      },
    );
  }

  void selectBank(String? bank) {
    _selectedBank = bank;
    notifyListeners();
  }

  void selectCategory(CampaignCategory? cat) {
    _selectedCategory = cat;
    notifyListeners();
  }

  void setSearch(String q) {
    _search = q;
    notifyListeners();
  }

  void clearFilters() {
    _selectedBank     = null;
    _selectedCategory = null;
    _search           = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
