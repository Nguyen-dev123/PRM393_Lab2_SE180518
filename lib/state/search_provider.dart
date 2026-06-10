import 'package:flutter/material.dart';
import '../models/publication.dart';
import '../models/trend_data.dart';
import '../services/openalex_service.dart';
import '../services/history_service.dart';

enum AppState { idle, loading, loaded, error }

class SearchProvider extends ChangeNotifier {
  String _query = '';
  String get query => _query;

  AppState _state = AppState.idle;
  AppState get state => _state;

  String _errorMsg = '';
  String get errorMsg => _errorMsg;

  List<Publication> _results = [];
  List<Publication> get results => _results;

  // Pagination
  int _currentPage = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  bool get hasMore => _hasMore;
  bool get loadingMore => _loadingMore;

  // For trend/dashboard - full dataset
  List<Publication> _allPubs = [];
  List<Publication> get allPubs => _allPubs;

  bool _isFetchingAll = false;
  bool get isFetchingAll => _isFetchingAll;

  // Cached analytics
  List<YearCount>? _trendData;
  List<JournalCount>? _topJournals;
  List<AuthorCount>? _topAuthors;
  DashboardData? _dashboard;

  List<YearCount>? get trendData => _trendData;
  List<JournalCount>? get topJournals => _topJournals;
  List<AuthorCount>? get topAuthors => _topAuthors;
  DashboardData? get dashboard => _dashboard;

  // Search history
  List<String> _history = [];
  List<String> get history => _history;

  SearchProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    _history = await HistoryService.load();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await HistoryService.clear();
    _history = [];
    notifyListeners();
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;
    _query = query.trim();
    _state = AppState.loading;
    _results = [];
    _allPubs = [];
    _trendData = null;
    _topJournals = null;
    _topAuthors = null;
    _dashboard = null;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();

    try {
      final batch = await OpenAlexService.searchPublications(_query, page: 1);
      _results = batch;
      _hasMore = batch.length >= 50;
      _state = AppState.loaded;
      notifyListeners();

      // Save to history
      await HistoryService.add(_query);
      _history = await HistoryService.load();
      notifyListeners();

      // Fetch full dataset for analytics in background
      _fetchAllForAnalytics();
    } catch (e) {
      _state = AppState.error;
      _errorMsg = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || _state != AppState.loaded) return;
    _loadingMore = true;
    notifyListeners();
    try {
      _currentPage++;
      final batch = await OpenAlexService.searchPublications(_query, page: _currentPage);
      _results.addAll(batch);
      _hasMore = batch.length >= 50;
    } catch (_) {
      _hasMore = false;
    }
    _loadingMore = false;
    notifyListeners();
  }

  Future<void> _fetchAllForAnalytics() async {
    _isFetchingAll = true;
    notifyListeners();
    try {
      _allPubs = await OpenAlexService.fetchAllForTrend(_query);
      _trendData = OpenAlexService.getTrendByYear(_allPubs);
      _topJournals = OpenAlexService.getTopJournals(_allPubs);
      _topAuthors = OpenAlexService.getTopAuthors(_allPubs);
      _dashboard = OpenAlexService.getDashboard(_allPubs);
    } catch (_) {}
    _isFetchingAll = false;
    notifyListeners();
  }
}
