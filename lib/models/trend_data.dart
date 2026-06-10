class YearCount {
  final int year;
  final int count;
  YearCount({required this.year, required this.count});
}

class JournalCount {
  final String name;
  final int count;
  JournalCount({required this.name, required this.count});
}

class AuthorCount {
  final String name;
  final int count;
  AuthorCount({required this.name, required this.count});
}

class DashboardData {
  final int totalPublications;
  final double avgCitationCount;
  final int? mostActiveYear;
  final String? topJournal;
  final String? topAuthor;
  final String? mostInfluentialPaper;
  final int? mostInfluentialCitations;

  DashboardData({
    required this.totalPublications,
    required this.avgCitationCount,
    this.mostActiveYear,
    this.topJournal,
    this.topAuthor,
    this.mostInfluentialPaper,
    this.mostInfluentialCitations,
  });
}
