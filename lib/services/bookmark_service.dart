import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bookmark.dart';
import '../models/publication.dart';

class BookmarkService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference _col(String uid) =>
      _db.collection('users').doc(uid).collection('bookmarks');

  /// Sanitize publication ID for use as Firestore document ID
  static String _docId(String publicationId) =>
      publicationId.replaceAll(RegExp(r'[/.]'), '_').replaceAll('https:__openalex.org_', '');

  /// Create — save a publication as bookmark
  static Future<void> add(String uid, Publication pub) async {
    final docId = _docId(pub.id);
    final docRef = _col(uid).doc(docId);
    final snap = await docRef.get();
    if (snap.exists) return;
    await docRef.set(Bookmark(
      publicationId: pub.id,
      title: pub.title,
      year: pub.year,
      citationCount: pub.citationCount,
      journalName: pub.journalName,
      authors: pub.authors,
      doi: pub.doi,
      url: pub.url,
      savedAt: DateTime.now(),
    ).toMap());
  }

  /// Read — fetch all bookmarks ordered by savedAt desc
  static Future<List<Bookmark>> getAll(String uid) async {
    final snap = await _col(uid)
        .orderBy('savedAt', descending: true)
        .get();
    return snap.docs.map((d) => Bookmark.fromDoc(d)).toList();
  }

  /// Update — edit note field only
  static Future<void> updateNote(String uid, String publicationId, String note) async {
    await _col(uid).doc(_docId(publicationId)).update({'note': note});
  }

  /// Delete — remove bookmark
  static Future<void> remove(String uid, String publicationId) async {
    await _col(uid).doc(_docId(publicationId)).delete();
  }

  /// Check if a publication is bookmarked
  static Future<bool> isBookmarked(String uid, String publicationId) async {
    final snap = await _col(uid).doc(_docId(publicationId)).get();
    return snap.exists;
  }
}
