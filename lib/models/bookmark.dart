import 'package:cloud_firestore/cloud_firestore.dart';

class Bookmark {
  final String publicationId;
  final String title;
  final int? year;
  final int citationCount;
  final String? journalName;
  final List<String> authors;
  final String? doi;
  final String? url;
  String note;
  final DateTime savedAt;

  Bookmark({
    required this.publicationId,
    required this.title,
    this.year,
    required this.citationCount,
    this.journalName,
    required this.authors,
    this.doi,
    this.url,
    this.note = '',
    required this.savedAt,
  });

  Map<String, dynamic> toMap() => {
        'publicationId': publicationId,
        'title': title,
        'year': year,
        'citationCount': citationCount,
        'journalName': journalName,
        'authors': authors,
        'doi': doi,
        'url': url,
        'note': note,
        'savedAt': FieldValue.serverTimestamp(),
      };

  factory Bookmark.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Bookmark(
      publicationId: d['publicationId'] ?? doc.id,
      title: d['title'] ?? '',
      year: d['year'],
      citationCount: d['citationCount'] ?? 0,
      journalName: d['journalName'],
      authors: List<String>.from(d['authors'] ?? []),
      doi: d['doi'],
      url: d['url'],
      note: d['note'] ?? '',
      savedAt: (d['savedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
