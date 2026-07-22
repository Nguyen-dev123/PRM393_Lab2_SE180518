import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../state/search_provider.dart';
import '../models/trend_data.dart';
import '../widgets/loading_widget.dart';
import 'dashboard_screen.dart';
import 'keyword_detail_screen.dart';
import 'journal_detail_screen.dart';
import 'publication_detail_screen.dart';
import '../state/config_provider.dart';

/// Keywords Tab: Overview + Keywords + Trends + Authors + Journals
class KeywordsScreen extends StatefulWidget {
  const KeywordsScreen({super.key});
  @override
  State<KeywordsScreen> createState() => _KeywordsScreenState();
}

class _KeywordsScreenState extends State<KeywordsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Analytics',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
            Tab(icon: Icon(Icons.dashboard_outlined, size: 17), text: 'Overview'),
            Tab(icon: Icon(Icons.tag, size: 17), text: 'Keywords'),
            Tab(icon: Icon(Icons.show_chart, size: 17), text: 'Trends'),
            Tab(icon: Icon(Icons.people, size: 17), text: 'Authors'),
            Tab(icon: Icon(Icons.library_books, size: 17), text: 'Journals'),
          ],
        ),
      ),
      body: Consumer<SearchProvider>(
        builder: (ctx, provider, _) {
          if (provider.state == AppState.idle) {
            return const EmptyState(
              message: 'Search a topic on Home tab\nto see analytics',
              icon: Icons.insights,
            );
          }
          if (provider.isFetchingAll && provider.trendData == null) {
            return const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Analyzing data...', style: TextStyle(color: Colors.grey)),
              ]),
            );
          }
          return TabBarView(
            controller: _tabController,
            children: [
              DashboardScreen(provider: provider),
              _KeywordsSection(provider: provider),
              _TrendsSection(provider: provider),
              _AuthorsSection(provider: provider),
              _JournalsSection(provider: provider),
            ],
          );
        },
      ),
    );
  }
}

// ── Keywords Section: Frequency list + tap to detail ──────────
class _KeywordsSection extends StatelessWidget {
  final SearchProvider provider;
  const _KeywordsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isFetchingAll && provider.topKeywords == null) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Extracting keywords...', style: TextStyle(color: Colors.grey)),
        ]),
      );
    }

    final keywords = provider.topKeywords ?? [];
    if (keywords.isEmpty) {
      return const EmptyState(
        message: 'No keyword data available.\nSearch a topic first.',
        icon: Icons.tag,
      );
    }

    final maxCount = keywords.first.count;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header summary
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.appTheme[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.appTheme[100]!),
          ),
          child: Row(children: [
            Icon(Icons.tag, color: context.appTheme[600], size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Top ${keywords.length} keywords from "${provider.query}"',
                style: TextStyle(
                  color: context.appTheme[800],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Keyword chips — trending display
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: keywords.asMap().entries.map((entry) {
            final i = entry.key;
            final kw = entry.value;
            // Font size scales with frequency rank
            final fontSize = (16 - i * 0.4).clamp(11.0, 16.0);
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => KeywordDetailScreen(keyword: kw.keyword),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: i < 5
                      ? context.appTheme[600]
                      : i < 10
                          ? context.appTheme[400]
                          : context.appTheme[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    kw.keyword,
                    style: TextStyle(
                      color: i < 10 ? Colors.white : context.appTheme[700],
                      fontSize: fontSize,
                      fontWeight: i < 5 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: i < 10 ? 0.25 : 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${kw.count}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: i < 10 ? Colors.white : context.appTheme[700],
                      ),
                    ),
                  ),
                ]),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Ranked list with progress bars
        const Text(
          'Keyword Frequency',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...keywords.asMap().entries.map((entry) {
          final i = entry.key;
          final kw = entry.value;
          final ratio = kw.count / maxCount;

          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => KeywordDetailScreen(keyword: kw.keyword),
              ),
            ),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    kw.keyword,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          backgroundColor: Colors.grey[100],
                          valueColor: AlwaysStoppedAnimation(context.appTheme[400]!),
                          minHeight: 7,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${kw.count}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: context.appTheme[600],
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: Colors.grey[300]),
              ]),
            ),
          );
        }),
      ],
    );
  }
}

// ── Trends Section: Publication Trend Line Chart ───────────────
class _TrendsSection extends StatefulWidget {
  final SearchProvider provider;
  const _TrendsSection({required this.provider});
  @override
  State<_TrendsSection> createState() => _TrendsSectionState();
}

class _TrendsSectionState extends State<_TrendsSection> {
  @override
  Widget build(BuildContext context) {
    final data = widget.provider.trendData ?? [];
    if (data.isEmpty) {
      return const EmptyState(
          message: 'No trend data available', icon: Icons.show_chart);
    }

    final maxY = data
        .map((d) => d.count)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble()))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Text('Publication Trend: "${widget.provider.query}"',
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 4),
        Text(
          '${data.length} years of data  •  '
          '${widget.provider.allPubs.length} total publications',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 20),

        // Line chart
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Publications per Year',
                style:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
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
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(
                            fontSize: 10, color: Colors.grey),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: (data.length / 5).ceilToDouble(),
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= data.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('${data[idx].year}',
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.grey)),
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
                maxX: (data.length - 1).toDouble(),
                minY: 0,
                maxY: maxY * 1.2,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                              '${data[s.spotIndex].year}\n${s.y.toInt()} papers',
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
                      getDotPainter: (p0, p1, p2, p3) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: context.appTheme[600]!,
                        strokeColor: Colors.white,
                        strokeWidth: 1.5,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: context.appTheme.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              )),
            ),
          ]),
        ),
        const SizedBox(height: 20),

        // Peak year card
        _peakYearCard(data),
      ]),
    );
  }

  Widget _peakYearCard(List<YearCount> data) {
    final peak = data.reduce((a, b) => a.count > b.count ? a : b);
    return GestureDetector(
      onTap: () {
        // Show top publications in that year
        final pubs = widget.provider.allPubs
            .where((p) => p.year == peak.year)
            .toList()
          ..sort((a, b) => b.citationCount.compareTo(a.citationCount));
        final top = pubs.take(5).toList();
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              Icon(Icons.trending_up, color: context.appTheme),
              const SizedBox(width: 8),
              Text('Peak Year: ${peak.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${peak.count} publications in ${peak.year}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 12),
                  if (top.isNotEmpty) ...[
                    const Text('Top cited papers that year:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    ...top.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.article_outlined, size: 14, color: context.appTheme[300]),
                        const SizedBox(width: 6),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12)),
                          Text('${p.citationCount} citations',
                              style: TextStyle(fontSize: 10, color: context.appTheme[400])),
                        ])),
                      ]),
                    )),
                  ] else
                    Text('No detailed publication data available for ${peak.year}.',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.appTheme[700]!, context.appTheme[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          const Icon(Icons.trending_up, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Peak Publication Year',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('${peak.year}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              Text('${peak.count} publications — tap for details',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
          const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
        ]),
      ),
    );
  }
}

// ── Authors Section: Top Authors Bar Chart ─────────────────────
class _AuthorsSection extends StatelessWidget {
  final SearchProvider provider;
  const _AuthorsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final authors = provider.topAuthors ?? [];
    if (authors.isEmpty) {
      return const EmptyState(
          message: 'No author data available', icon: Icons.people_outline);
    }
    final maxCount = authors.first.count;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Top Authors: "${provider.query}"',
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 4),
        Text('Ranked by number of publications',
            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 16),

        // Bar chart
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: authors.asMap().entries.map((entry) {
              final i = entry.key;
              final a = entry.value;
              final ratio = a.count / maxCount;
              final barColors = [
                context.appTheme[700]!,
                context.appTheme[500]!,
                context.appTheme[400]!,
                context.appTheme[300]!,
                context.appTheme[200]!,
              ];
              final barColor = barColors[i.clamp(0, barColors.length - 1)];

              return InkWell(
                onTap: () {
                  final authorPubs = provider.allPubs
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
                    builder: (_) => DraggableScrollableSheet(
                      initialChildSize: 0.5,
                      maxChildSize: 0.85,
                      minChildSize: 0.3,
                      expand: false,
                      builder: (ctx, sc) => Column(
                        children: [
                          Container(
                            width: 40, height: 4,
                            margin: const EdgeInsets.only(top: 12),
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2)),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Row(children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: barColor.withValues(alpha: 0.15),
                                child: Text(a.name[0].toUpperCase(),
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: barColor)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(a.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15)),
                                      Text(
                                          '${a.count} publication${a.count > 1 ? "s" : ""} in dataset',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600])),
                                    ]),
                              ),
                            ]),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: authorPubs.isEmpty
                                ? Center(
                                    child: Text(
                                        'No detailed data available.',
                                        style: TextStyle(color: Colors.grey[500])))
                                : ListView.separated(
                                    controller: sc,
                                    padding: const EdgeInsets.all(12),
                                    itemCount: authorPubs.length,
                                    separatorBuilder: (_, i) =>
                                        const Divider(height: 1),
                                    itemBuilder: (ctx2, idx) {
                                      final pub = authorPubs[idx];
                                      return ListTile(
                                        dense: true,
                                        leading: CircleAvatar(
                                          radius: 12,
                                          backgroundColor: context.appTheme[50],
                                          child: Text('${idx + 1}',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: context.appTheme[700])),
                                        ),
                                        title: Text(pub.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500)),
                                        subtitle: Text(
                                            '${pub.citationCount} citations • ${pub.year ?? "N/A"}',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: context.appTheme[400])),
                                        trailing: const Icon(Icons.chevron_right,
                                            size: 16),
                                        onTap: () {
                                          Navigator.pop(ctx2);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (navCtx) =>
                                                    PublicationDetailScreen(
                                                        pub: pub)),
                                          );
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(children: [
                    SizedBox(
                      width: 22,
                      child: Text('${i + 1}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[500])),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(a.name,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                              Text('${a.count}',
                                  style: TextStyle(
                                      color: barColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                              const SizedBox(width: 4),
                              Text('papers',
                                  style: TextStyle(
                                      color: Colors.grey[400], fontSize: 10)),
                            ]),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                backgroundColor: Colors.grey[100],
                                valueColor: AlwaysStoppedAnimation(barColor),
                                minHeight: 8,
                              ),
                            ),
                          ]),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 14, color: Colors.grey[300]),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Journals Section: Top Journals ────────────────────────────
class _JournalsSection extends StatelessWidget {
  final SearchProvider provider;
  const _JournalsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final journals = provider.topJournals ?? [];
    if (journals.isEmpty) {
      return const EmptyState(
          message: 'No journal data available',
          icon: Icons.library_books_outlined);
    }
    final maxCount = journals.first.count;
    final total = journals.fold(0, (sum, j) => sum + j.count);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Top Journals: "${provider.query}"',
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 4),
        Text('Ranked by number of publications',
            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 16),

        // Journal list with progress
        ...journals.asMap().entries.map((entry) {
          final i = entry.key;
          final j = entry.value;
          final ratio = j.count / maxCount;
          final pct = total > 0 ? (j.count / total * 100).toStringAsFixed(1) : '0';

          final colors = [
            Colors.teal[700]!,
            Colors.teal[500]!,
            Colors.teal[400]!,
            Colors.teal[300]!,
            Colors.teal[200]!,
          ];
          final barColor = colors[i.clamp(0, colors.length - 1)];

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: i < 3 ? 2 : 1,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => JournalDetailScreen(journal: j)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: barColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text('${i + 1}',
                                style: TextStyle(
                                    color: barColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(j.name,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const Icon(Icons.chevron_right,
                            color: Colors.grey, size: 18),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              backgroundColor: Colors.grey[100],
                              valueColor: AlwaysStoppedAnimation(barColor),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('${j.count} ($pct%)',
                            style: TextStyle(
                                color: barColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ]),
                    ]),
              ),
            ),
          );
        }),
      ],
    );
  }
}








