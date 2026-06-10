import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/publication.dart';
import '../models/trend_data.dart';

class OpenAlexService {
  static const _base = 'https://api.openalex.org';
  static const _email = 'se180518@fpt.edu.vn'; // polite pool
  static const _perPage = 50;

  static String _params(Map<String, String> p) =>
      p.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

  // Tìm publications theo keyword, trả về trang đầu
  static Future<List<Publication>> searchPublications(
    String query, {
    int page = 1,
    int perPage = _perPage,
  }) async {
    final params = _params({
      'search': query,
      'per_page': perPage.toString(),
      'page': page.toString(),
      'sort': 'cited_by_count:desc',
      'mailto': _email,
    });
    final url = '$_base/works?$params';
    final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) throw Exception('API error: ${resp.statusCode}');
    final data = jsonDecode(resp.body);
    final results = data['results'] as List? ?? [];
    return results.map((r) => Publication.fromJson(r as Map<String, dynamic>)).toList();
  }

  // Lấy TẤT CẢ publications cho trend analysis (tối đa 200)
  static Future<List<Publication>> fetchAllForTrend(String query) async {
    final all = <Publication>[];
    for (int page = 1; page <= 4; page++) {
      final batch = await searchPublications(query, page: page, perPage: 50);
      all.addAll(batch);
      if (batch.length < 50) break;
    }
    return all;
  }

  // Trend theo năm
  static List<YearCount> getTrendByYear(List<Publication> pubs) {
    final map = <int, int>{};
    for (final p in pubs) {
      if (p.year != null && p.year! >= 1990) {
        map[p.year!] = (map[p.year!] ?? 0) + 1;
      }
    }
    final list = map.entries.map((e) => YearCount(year: e.key, count: e.value)).toList();
    list.sort((a, b) => a.year.compareTo(b.year));
    return list;
  }

  // Top journals
  static List<JournalCount> getTopJournals(List<Publication> pubs, {int top = 10}) {
    final map = <String, int>{};
    for (final p in pubs) {
      if (p.journalName != null && p.journalName!.isNotEmpty) {
        map[p.journalName!] = (map[p.journalName!] ?? 0) + 1;
      }
    }
    final list = map.entries
        .map((e) => JournalCount(name: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return list.take(top).toList();
  }

  // Top authors
  static List<AuthorCount> getTopAuthors(List<Publication> pubs, {int top = 10}) {
    final map = <String, int>{};
    for (final p in pubs) {
      for (final a in p.authors) {
        map[a] = (map[a] ?? 0) + 1;
      }
    }
    final list = map.entries
        .map((e) => AuthorCount(name: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return list.take(top).toList();
  }

  // Dashboard summary
  static DashboardData getDashboard(List<Publication> pubs) {
    if (pubs.isEmpty) {
      return DashboardData(totalPublications: 0, avgCitationCount: 0);
    }
    final total = pubs.length;
    final avgCitation = pubs.fold(0, (sum, p) => sum + p.citationCount) / total;

    final yearMap = <int, int>{};
    for (final p in pubs) {
      if (p.year != null) yearMap[p.year!] = (yearMap[p.year!] ?? 0) + 1;
    }
    int? mostActiveYear;
    if (yearMap.isNotEmpty) {
      mostActiveYear = yearMap.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    final topJournals = getTopJournals(pubs, top: 1);
    final topAuthors = getTopAuthors(pubs, top: 1);
    final mostInfluential = pubs.reduce((a, b) => a.citationCount > b.citationCount ? a : b);

    return DashboardData(
      totalPublications: total,
      avgCitationCount: avgCitation,
      mostActiveYear: mostActiveYear,
      topJournal: topJournals.isNotEmpty ? topJournals.first.name : null,
      topAuthor: topAuthors.isNotEmpty ? topAuthors.first.name : null,
      mostInfluentialPaper: mostInfluential.title,
      mostInfluentialCitations: mostInfluential.citationCount,
    );
  }
}
