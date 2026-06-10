class Publication {
  final String id;
  final String title;
  final int? year;
  final int citationCount;
  final String? doi;
  final String? abstract;
  final String? journalName;
  final List<String> authors;
  final String? url;

  Publication({
    required this.id,
    required this.title,
    this.year,
    this.citationCount = 0,
    this.doi,
    this.abstract,
    this.journalName,
    this.authors = const [],
    this.url,
  });

  factory Publication.fromJson(Map<String, dynamic> json) {
    // Authors
    final authorships = json['authorships'] as List? ?? [];
    final authors = authorships
        .map((a) => a['author']?['display_name'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .toList();

    // Journal
    String? journal;
    final locations = json['primary_location'];
    if (locations != null) {
      journal = locations['source']?['display_name'] as String?;
    }

    // Abstract from inverted index
    String? abstract;
    final abstractIndex = json['abstract_inverted_index'] as Map?;
    if (abstractIndex != null) {
      abstract = _reconstructAbstract(abstractIndex);
    }

    return Publication(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'No title',
      year: json['publication_year'] as int?,
      citationCount: json['cited_by_count'] as int? ?? 0,
      doi: json['doi'] as String?,
      abstract: abstract,
      journalName: journal,
      authors: authors,
      url: json['primary_location']?['landing_page_url'] as String?,
    );
  }

  static String _reconstructAbstract(Map abstractIndex) {
    final wordPositions = <int, String>{};
    abstractIndex.forEach((word, positions) {
      for (final pos in (positions as List)) {
        wordPositions[pos as int] = word as String;
      }
    });
    final sorted = wordPositions.keys.toList()..sort();
    return sorted.map((pos) => wordPositions[pos]).join(' ');
  }
}
