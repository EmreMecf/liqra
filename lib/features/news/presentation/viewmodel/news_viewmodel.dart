import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/news_entity.dart';
import '../../domain/repositories/news_repository.dart';

class NewsViewModel extends ChangeNotifier {
  final NewsRepository _repo;

  NewsViewModel(this._repo) {
    _subscribe();
  }

  List<NewsEntity>  _all      = [];
  bool              _loading  = true;
  String?           _error;
  NewsCategory?     _selectedCategory;
  String?           _selectedSource;
  String            _search   = '';

  bool              get isLoading        => _loading;
  String?           get error            => _error;
  NewsCategory?     get selectedCategory => _selectedCategory;
  String?           get selectedSource   => _selectedSource;
  String            get search           => _search;

  /// Benzersiz kaynaklar
  List<String> get sources {
    final seen = <String>{};
    return _all.map((n) => n.source).where(seen.add).toList();
  }

  /// Filtrelenmiş liste
  List<NewsEntity> get news {
    var list = _all;
    if (_selectedCategory != null) {
      list = list.where((n) => n.category == _selectedCategory).toList();
    }
    if (_selectedSource != null) {
      list = list.where((n) => n.source == _selectedSource).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((n) =>
          n.title.toLowerCase().contains(q) ||
          n.description.toLowerCase().contains(q) ||
          n.source.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  StreamSubscription<List<NewsEntity>>? _sub;

  void _subscribe() {
    _sub = _repo.watchNews().listen(
      (data) {
        _all     = data;
        _loading = false;
        _error   = null;
        notifyListeners();
      },
      onError: (e) {
        _loading = false;
        _error   = 'Haberler yüklenemedi';
        notifyListeners();
      },
    );
  }

  void selectCategory(NewsCategory? cat) {
    _selectedCategory = cat;
    notifyListeners();
  }

  void selectSource(String? source) {
    _selectedSource = source;
    notifyListeners();
  }

  void setSearch(String q) {
    _search = q;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = null;
    _selectedSource   = null;
    _search           = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
