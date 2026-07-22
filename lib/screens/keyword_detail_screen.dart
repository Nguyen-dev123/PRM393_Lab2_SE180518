import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/publication.dart';
import '../models/trend_data.dart';
import '../state/search_provider.dart';
import '../firebase/firebase_analytics_service.dart';
import 'publication_detail_screen.dart';
import 'journal_detail_screen.dart';
import '../state/config_provider.dart';
/// Shows: publication trends, related journals, related publications, top authors.
/// Data is derived from the current search dataset filtered by keyword match.
class KeywordDetailScreen extends StatefulWidget {
  final String keyword;
  const KeywordDetailScreen({super.key, required this.keyword});

  @override
  State<KeywordDetailScreen> createState() => _KeywordDetailScreenState();
}

class _KeywordDetailScreenState extends State<KeywordDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Derived data — computed once from the provider dataset
  List<Publication> _relatedPubs = [];
  List<YearCount> _trendByYear = [];
  List<JournalCount> _relatedJournals = [];
  List<AuthorCount> _topAuthors = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _computeData();
    _logAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Filter publications that contain the keyword in title or abstract,
  /// then derive journals, authors, and trends from that subset.
  void _computeData() {
    final provider = context.read<SearchProvider>();
    final source = provider.allPubs.isNotEmpty ? provider.allPubs : provider.results;
    final kw = widget.keyword.toLowerCase();

    // Publications matching this keyword
    _relatedPubs = source.where((p) {
      final inTitle = p.title.toLowerCase().contains(kw);
      final inAbstract = p.abstract?.toLowerCase().contains(kw) ?? false;
      return inTitle || inAbstract;
    }).toList()
      ..sort((a, b) => b.citationCount.compareTo(a.citationCount));

    // If no exact match, fall back to the full dataset (keyword IS the search topic)
    if (_relatedPubs.isEmpty) _relatedPubs = List.from(source);

    // Trend by year
    final yearMap = <int, int>{};
    for (final p in _relatedPubs) {
      if (p.year != null && p.year! >= 1990) {
        yearMap[p.year!] = (yearMap[p.year!] ?? 0) + 1;
      }
    }
    _trendByYear = (yearMap.entries
        .map((e) => YearCount(year: e.key, count: e.value))
        .toList())
      ..sort((a, b) => a.year.compareTo(b.year));

    // Related journals — ranked by pub count in this keyword subset
    final jCountMap = <String, int>{};
    final jCiteMap = <String, int>{};
    for (final p in _relatedPubs) {
      if (p.journalName != null && p.journalName!.isNotEmpty) {
        jCountMap[p.journalName!] = (jCountMap[p.journalName!] ?? 0) + 1;
        jCiteMap[p.journalName!] =
            (jCiteMap[p.journalName!] ?? 0) + p.citationCount;
      }
    }
    _relatedJournals = jCountMap.entries
        .map((e) => JournalCount(
              name: e.key,
              count: e.value,
              totalCitations: jCiteMap[e.key] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    if (_relatedJournals.length > 10) _relatedJournals = _relatedJournals.sublist(0, 10);

    // Top authors — ranked by pub count in this keyword subset
    final aMap = <String, int>{};
    for (final p in _relatedPubs) {
      for (final a in p.authors) {
        aMap[a] = (aMap[a] ?? 0) + 1;
      }
    }
    _topAuthors = aMap.entries
        .map((e) => AuthorCount(name: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    if (_topAuthors.length > 10) _topAuthors = _topAuthors.sublist(0, 10);
  }

  Future<void> _logAnalytics() async {
    await FirebaseAnalyticsService.logViewKeyword(widget.keyword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.keyword,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: context.appTheme[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: context.appTheme[200],
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.show_chart, size: 16), text: 'Trend'),
            Tab(icon: Icon(Icons.library_books, size: 16), text: 'Journals'),
            Tab(icon: Icon(Icons.article, size: 16), text: 'Publications'),
            Tab(icon: Icon(Icons.people, size: 16), text: 'Authors'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTrendTab(),
          _buildJournalsTab(),
          _buildPublicationsTab(),
          _buildAuthorsTab(),
        ],
      ),
    );
  }

  // ── Tab 1: Trend ─────────────────────────────────────────────
  Widget _buildTrendTab() {
    if (_trendByYear.length < 2) {
      return const Center(
        child: Text('Not enough trend data for this keyword.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    final maxY = _trendByYear
        .map((d) => d.count)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    final spots = _trendByYear
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble()))
        .toList();

    final peak = _trendByYear.reduce((a, b) => a.count > b.count ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.appTheme[700]!, context.appTheme[500]!],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryItem('Publications', '${_relatedPubs.length}', Colors.white),
                _vDivider(),
                _summaryItem('Years', '${_trendByYear.length}', Colors.white),
                _vDivider(),
                _summaryItem('Peak Year', '${peak.year}', Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Line chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Publication Trend — "${widget.keyword}"',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: LineChart(LineChartData(
                    gridData: FlGridData(
                      drawHorizontalLine: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: Colors.grey[200]!, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (v, _) => Text(
                            v.toInt().toString(),
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 26,
                          interval: (_trendByYear.length / 5).ceilToDouble(),
                          getTitlesWidget: (v, _) {
                            final idx = v.toInt();
                            if (idx < 0 || idx >= _trendByYear.length) {
                              return const SizedBox();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "'${_trendByYear[idx].year % 100}",
                                style: const TextStyle(
                                    fontSize: 9, color: Colors.grey),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (_trendByYear.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxY * 1.2,
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (spots) => spots
                            .map((s) => LineTooltipItem(
                                  '${_trendByYear[s.spotIndex].year}\n${s.y.toInt()} papers',
                                  const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ))
                            .toList(),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: context.appTheme[600],
                        barWidth: 3,
                        dotData: FlDotData(
                          getDotPainter: (p0, p1, p2, p3) => FlDotCirclePainter(
                            radius: 3,
                            color: Colors.indigo,
                            strokeColor: Colors.white,
                            strokeWidth: 1.5,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.indigo.withValues(alpha: 0.07),
                        ),
                      ),
                    ],
                  )),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Peak card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.appTheme[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.appTheme[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: context.appTheme[600], size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Peak year: ${peak.year}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: context.appTheme[800])),
                    Text('${peak.count} publications',
                        style: TextStyle(
                            color: context.appTheme[600], fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Related Journals ───────────────────────────────────
  Widget _buildJournalsTab() {
    if (_relatedJournals.isEmpty) {
      return const Center(
        child: Text('No journal data for this keyword.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    final maxCount = _relatedJournals.first.count;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _relatedJournals.length,
      itemBuilder: (ctx, i) {
        final j = _relatedJournals[i];
        final ratio = j.count / maxCount;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => JournalDetailScreen(journal: j)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: Colors.teal[50], borderRadius: BorderRadius.circular(6)),
                      child: Center(child: Text('${i + 1}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal[700]))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(j.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 2, overflow: TextOverflow.ellipsis)),
                    const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: Colors.grey[100],
                        valueColor: AlwaysStoppedAnimation(Colors.teal[500]!),
                        minHeight: 7,
                      ),
                    )),
                    const SizedBox(width: 10),
                    Text('${j.count} pubs',
                        style: TextStyle(color: Colors.teal[700], fontWeight: FontWeight.bold, fontSize: 12)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.format_quote, size: 12, color: context.appTheme[300]),
                    const SizedBox(width: 4),
                    Text('${j.totalCitations} citations · avg ${j.avgCitationsPerPublication.toStringAsFixed(1)}/pub',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Tab 3: Related Publications ───────────────────────────────
  Widget _buildPublicationsTab() {
    if (_relatedPubs.isEmpty) {
      return const Center(
        child: Text('No publications found for this keyword.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _relatedPubs.length,
      itemBuilder: (ctx, i) {
        final pub = _relatedPubs[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(
                  builder: (_) => PublicationDetailScreen(pub: pub)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: i < 3 ? Colors.amber[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: i < 3 ? Colors.amber[800] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pub.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        if (pub.authors.isNotEmpty)
                          Text(
                            pub.authors.take(2).join(', ') +
                                (pub.authors.length > 2 ? ' et al.' : ''),
                            style: TextStyle(
                                fontSize: 11.5, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Wrap(spacing: 10, children: [
                          if (pub.year != null)
                            _chip(Icons.calendar_today, '${pub.year}', Colors.teal),
                          _chip(Icons.format_quote,
                              '${pub.citationCount}', context.appTheme),
                        ]),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Tab 4: Top Authors ────────────────────────────────────────
  Widget _buildAuthorsTab() {
    if (_topAuthors.isEmpty) {
      return const Center(
        child: Text('No author data for this keyword.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    final maxCount = _topAuthors.first.count;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _topAuthors.length,
      itemBuilder: (ctx, i) {
        final a = _topAuthors[i];
        final ratio = a.count / maxCount;

        return InkWell(
          onTap: () {
            final authorPubs = _relatedPubs
                .where((p) => p.authors.any(
                      (auth) => auth.toLowerCase() == a.name.toLowerCase(),
                    ))
                .toList()
              ..sort((x, y) => y.citationCount.compareTo(x.citationCount));
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (bsCtx) => DraggableScrollableSheet(
                initialChildSize: 0.5,
                maxChildSize: 0.85,
                minChildSize: 0.3,
                expand: false,
                builder: (bsCtx2, sc) => Column(children: [
                  Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: context.appTheme[100],
                        child: Text(a.name[0].toUpperCase(),
                            style: TextStyle(fontWeight: FontWeight.bold, color: context.appTheme[700], fontSize: 16)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('${a.count} publication${a.count > 1 ? "s" : ""} for "${widget.keyword}"',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ])),
                    ]),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: authorPubs.isEmpty
                        ? Center(child: Text('No detailed data.',
                            style: TextStyle(color: Colors.grey[500])))
                        : ListView.separated(
                            controller: sc,
                            padding: const EdgeInsets.all(12),
                            itemCount: authorPubs.length,
                            separatorBuilder: (_, j) => const Divider(height: 1),
                            itemBuilder: (ctx3, idx) {
                              final pub = authorPubs[idx];
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: context.appTheme[50],
                                  child: Text('${idx + 1}',
                                      style: TextStyle(fontSize: 10, color: context.appTheme[700])),
                                ),
                                title: Text(pub.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                subtitle: Text('${pub.citationCount} citations • ${pub.year ?? "N/A"}',
                                    style: TextStyle(fontSize: 11, color: context.appTheme[400])),
                                trailing: const Icon(Icons.chevron_right, size: 16),
                                onTap: () {
                                  Navigator.pop(bsCtx);
                                  Navigator.push(context, MaterialPageRoute(
                                      builder: (navCtx) => PublicationDetailScreen(pub: pub)));
                                },
                              );
                            },
                          ),
                  ),
                ]),
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              SizedBox(
                width: 24,
                child: Text('${i + 1}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400]),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 18,
                backgroundColor: context.appTheme[100],
                child: Text(a.name.isNotEmpty ? a.name[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appTheme[700])),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Expanded(child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: Colors.grey[100],
                      valueColor: AlwaysStoppedAnimation(context.appTheme[400]!),
                      minHeight: 6,
                    ),
                  )),
                  const SizedBox(width: 8),
                  Text('${a.count} paper${a.count > 1 ? "s" : ""}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.appTheme[600])),
                ]),
              ])),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 14, color: Colors.grey[300]),
            ]),
          ),
        );
      },
    );
  }

  // ── Helpers ──────────────────────────────────────────────────
  Widget _summaryItem(String label, String value, Color color) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 11)),
    ]);
  }

  Widget _vDivider() => Container(
        width: 1, height: 36, color: Colors.white.withValues(alpha: 0.3));

  Widget _chip(IconData icon, String text, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 3),
      Text(text, style: TextStyle(fontSize: 11, color: color)),
    ]);
  }
}
