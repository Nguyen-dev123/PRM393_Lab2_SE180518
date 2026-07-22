import 'package:flutter/foundation.dart';
import '../models/bookmark.dart';
import '../models/publication.dart';
import '../services/bookmark_service.dart';

class BookmarkViewModel extends ChangeNotifier {
  final String uid;

  BookmarkViewModel(this.uid) {
    load();
  }

  List<Bookmark> _bookmarks = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Bookmark> get bookmarks => _bookmarks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isBookmarked(String publicationId) =>
      _bookmarks.any((b) => b.publicationId == publicationId);

  /// Load all bookmarks from Firestore
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _bookmarks = await BookmarkService.getAll(uid);
    } catch (e) {
      _errorMessage = 'Failed to load bookmarks: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add bookmark
  Future<void> add(Publication pub) async {
    try {
      await BookmarkService.add(uid, pub);
      if (!isBookmarked(pub.id)) {
        _bookmarks.insert(
          0,
          Bookmark(
            publicationId: pub.id,
            title: pub.title,
            year: pub.year,
            citationCount: pub.citationCount,
            journalName: pub.journalName,
            authors: pub.authors,
            doi: pub.doi,
            url: pub.url,
            savedAt: DateTime.now(),
          ),
        );
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update note
  Future<void> updateNote(String publicationId, String note) async {
    await BookmarkService.updateNote(uid, publicationId, note);
    final idx = _bookmarks.indexWhere((b) => b.publicationId == publicationId);
    if (idx != -1) {
      _bookmarks[idx].note = note;
      notifyListeners();
    }
  }

  /// Remove bookmark
  Future<void> remove(String publicationId) async {
    await BookmarkService.remove(uid, publicationId);
    _bookmarks.removeWhere((b) => b.publicationId == publicationId);
    notifyListeners();
  }
}
