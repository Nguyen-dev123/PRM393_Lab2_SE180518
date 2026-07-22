import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/publication.dart';
import '../models/trend_data.dart';

/// Service class for interacting with the OpenAlex REST API.
/// 
/// OpenAlex is a free, open catalog of the global research system.
/// Base URL: https://api.openalex.org
/// No API key required — uses polite pool via mailto parameter.
class OpenAlexService {
  static const _base = 'https://api.openalex.org';
  static const _email = 'se180518@fpt.edu.vn'; // polite pool
  static const _perPage = 50;

  /// Encodes a map of parameters into a query string.
  static String _params(Map<String, String> p) =>
      p.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

  /// Searches publications by keyword.
  /// 
  /// [query] - The search keyword (e.g. "Artificial Intelligence")
  /// [page] - Page number for pagination (default: 1)
  /// [perPage] - Number of results per page (default: 50)
  /// Returns a list of [Publication] objects sorted by citation count.
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
    
    http.Response? resp;
    int retries = 5;
    while (retries > 0) {
      try {
        resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
        if (resp.statusCode == 429) {
          retries--;
          await Future.delayed(Duration(seconds: 6 - retries)); // Exponential-like backoff
          continue;
        }
        break;
      } catch (e) {
        retries--;
        await Future.delayed(const Duration(seconds: 3));
      }
    }
    
    if (resp == null || resp.statusCode != 200) {
      throw Exception('API error: ${resp?.statusCode ?? "Timeout/Network"}');
    }
    
    final data = jsonDecode(resp.body);
    final results = data['results'] as List? ?? [];
    return results.map((r) => Publication.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Fetches up to 200 publications for trend analysis (4 pages x 50).
  /// Runs in background after initial search results are displayed.
  static Future<List<Publication>> fetchAllForTrend(String query) async {
    final all = <Publication>[];
    for (int page = 1; page <= 4; page++) {
      final batch = await searchPublications(query, page: page, perPage: 50);
      all.addAll(batch);
      if (batch.length < 50) break;
      await Future.delayed(const Duration(milliseconds: 500)); // Rate limit delay
    }
    return all;
  }

  /// Groups publications by year and returns sorted list from 1990 onwards.
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

  /// Returns top [top] journals ranked by publication count, with total citations.
  static List<JournalCount> getTopJournals(List<Publication> pubs, {int top = 10}) {
    final countMap = <String, int>{};
    final citationMap = <String, int>{};
    for (final p in pubs) {
      if (p.journalName != null && p.journalName!.isNotEmpty) {
        countMap[p.journalName!] = (countMap[p.journalName!] ?? 0) + 1;
        citationMap[p.journalName!] =
            (citationMap[p.journalName!] ?? 0) + p.citationCount;
      }
    }
    final list = countMap.entries
        .map((e) => JournalCount(
              name: e.key,
              count: e.value,
              totalCitations: citationMap[e.key] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return list.take(top).toList();
  }

  /// Returns top [top] authors ranked by publication count.
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

  /// Extracts top [top] keywords from publication titles.
  /// Filters out common stop-words so only meaningful terms remain.
  static List<KeywordCount> getTopKeywords(List<Publication> pubs, {int top = 20}) {
    const stopWords = {
      'a', 'an', 'the', 'of', 'in', 'on', 'at', 'to', 'for', 'and', 'or',
      'but', 'with', 'by', 'from', 'is', 'are', 'was', 'be', 'been', 'has',
      'have', 'had', 'this', 'that', 'its', 'it', 'as', 'not', 'no', 'vs',
      'using', 'based', 'via', 'into', 'over', 'under', 'new', 'case',
      'study', 'approach', 'review', 'analysis', 'method', 'model', 'system',
    };

    final wordMap = <String, int>{};
    for (final p in pubs) {
      // Tokenise title into lowercase words of 4+ characters
      final words = p.title
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z\s]'), ' ')
          .split(RegExp(r'\s+'))
          .where((w) => w.length >= 4 && !stopWords.contains(w));
      for (final w in words) {
        wordMap[w] = (wordMap[w] ?? 0) + 1;
      }
    }

    final list = wordMap.entries
        .where((e) => e.value > 1) // must appear in at least 2 publications
        .map((e) => KeywordCount(keyword: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return list.take(top).toList();
  }

  /// Fetches the real total global count from OpenAlex for a query
  static Future<int> getRealTotalCount(String query) async {
    try {
      final params = _params({'search': query, 'per_page': '1', 'mailto': _email});
      final url = '$_base/works?$params';
      
      http.Response? resp;
      int retries = 3;
      while (retries > 0) {
        try {
          resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
          if (resp.statusCode == 429) {
            retries--;
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
          break;
        } catch (e) {
          retries--;
          await Future.delayed(const Duration(seconds: 2));
        }
      }
      
      if (resp != null && resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['meta']?['count'] ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  /// Computes summary dashboard data from a list of publications.
  static DashboardData getDashboard(List<Publication> pubs, {int realTotalPublications = 0}) {
    if (pubs.isEmpty) {
      return DashboardData(
          totalPublications: 0,
          realTotalPublications: 0,
          totalCitations: 0,
          avgCitationCount: 0,
          hIndex: 0);
    }
    final total = pubs.length;
    final totalCitations = pubs.fold(0, (sum, p) => sum + p.citationCount);
    final avgCitation = totalCitations / total;

    // H-Index: largest h such that h papers have >= h citations
    final sorted = List<int>.from(pubs.map((p) => p.citationCount))
      ..sort((a, b) => b.compareTo(a));
    int hIndex = 0;
    for (int i = 0; i < sorted.length; i++) {
      if (sorted[i] >= i + 1) {
        hIndex = i + 1;
      } else {
        break;
      }
    }

    final yearMap = <int, int>{};
    for (final p in pubs) {
      if (p.year != null) yearMap[p.year!] = (yearMap[p.year!] ?? 0) + 1;
    }
    int? mostActiveYear;
    if (yearMap.isNotEmpty) {
      mostActiveYear =
          yearMap.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    // Last 6 years sparkline data
    final trendData = getTrendByYear(pubs);
    final recentYearCounts = trendData.length > 6
        ? trendData.sublist(trendData.length - 6).map((y) => y.count).toList()
        : trendData.map((y) => y.count).toList();

    final topJournals = getTopJournals(pubs, top: 1);
    final topAuthors = getTopAuthors(pubs, top: 1);
    final mostInfluential =
        pubs.reduce((a, b) => a.citationCount > b.citationCount ? a : b);

    return DashboardData(
      totalPublications: total,
      realTotalPublications: realTotalPublications > 0 ? realTotalPublications : total,
      totalCitations: totalCitations,
      avgCitationCount: avgCitation,
      hIndex: hIndex,
      mostActiveYear: mostActiveYear,
      topJournal: topJournals.isNotEmpty ? topJournals.first.name : null,
      topAuthor: topAuthors.isNotEmpty ? topAuthors.first.name : null,
      mostInfluentialPaper: mostInfluential.title,
      mostInfluentialCitations: mostInfluential.citationCount,
      recentYearCounts: recentYearCounts,
    );
  }
}
