class YearCount {
  final int year;
  final int count;
  YearCount({required this.year, required this.count});
}

class JournalCount {
  final String name;
  final int count;
  // Total citations across all publications in this journal (from the sampled dataset)
  final int totalCitations;

  JournalCount({required this.name, required this.count, this.totalCitations = 0});

  String get journalName => name;

  double get avgCitationsPerPublication =>
      count > 0 ? totalCitations / count : 0.0;
}

class AuthorCount {
  final String name;
  final int count;
  AuthorCount({required this.name, required this.count});
}

/// Represents a keyword extracted from publication titles/abstracts.
class KeywordCount {
  final String keyword;
  final int count;
  KeywordCount({required this.keyword, required this.count});
}

class DashboardData {
  final int totalPublications;
  final int realTotalPublications;
  final int totalCitations;
  final double avgCitationCount;
  final int hIndex;
  final int? mostActiveYear;
  final String? topJournal;
  final String? topAuthor;
  final String? mostInfluentialPaper;
  final int? mostInfluentialCitations;
  // Mini sparkline — last 6 year counts for the header cards
  final List<int> recentYearCounts;

  DashboardData({
    required this.totalPublications,
    required this.realTotalPublications,
    required this.totalCitations,
    required this.avgCitationCount,
    required this.hIndex,
    this.mostActiveYear,
    this.topJournal,
    this.topAuthor,
    this.mostInfluentialPaper,
    this.mostInfluentialCitations,
    this.recentYearCounts = const [],
  });
}
