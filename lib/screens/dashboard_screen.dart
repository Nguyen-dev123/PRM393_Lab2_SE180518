import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../state/search_provider.dart';
import '../models/trend_data.dart';
import '../widgets/loading_widget.dart';
import 'publication_detail_screen.dart';
import 'journal_detail_screen.dart';
import 'package:provider/provider.dart';
import '../state/config_provider.dart';

class DashboardScreen extends StatefulWidget {
  final SearchProvider provider;
  const DashboardScreen({super.key, required this.provider});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Flux chart toggle: 0=Time, 1=Journal, 2=Author
  int _fluxMode = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;

    if (p.isFetchingAll && p.dashboard == null) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Building dashboard...', style: TextStyle(color: Colors.grey)),
        ]),
      );
    }

    final d = p.dashboard;
    if (d == null) {
      return const EmptyState(
          message: 'No data available', icon: Icons.dashboard_outlined);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──────────────────────────────────────────────
        _buildHeader(p, d),
        const SizedBox(height: 16),

        // ── 4 Stat Cards ────────────────────────────────────────
        _buildStatGrid(d),
        const SizedBox(height: 20),

        // ── Ecosystem Flux ──────────────────────────────────────
        _buildFluxSection(p, d),
        const SizedBox(height: 20),

        // ── Field Distribution ──────────────────────────────────
        _buildFieldDistribution(p),
        const SizedBox(height: 20),

        // ── Bottom Highlights ───────────────────────────────────
        _buildHighlights(d),
      ]),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader(SearchProvider p, DashboardData d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.appTheme[800]!, context.appTheme[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.analytics, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text('Research Ecosystem',
              style: TextStyle(color: context.appTheme[200], fontSize: 12)),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${_formatNum(d.realTotalPublications)} papers globally',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 8),
        Text('"${p.query}"',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text('Comprehensive bibliometric overview',
            style: TextStyle(color: context.appTheme[200], fontSize: 12)),
      ]),
    );
  }

  // ── 4 Stat Cards ──────────────────────────────────────────────
  Widget _buildStatGrid(DashboardData d) {
    final cards = [
      _StatCardData(
        label: 'Global Papers',
        value: _formatNum(d.realTotalPublications),
        icon: Icons.article_outlined,
        color: context.appTheme,
        sparkline: d.recentYearCounts,
        onTap: () => _showEvidence(context, 'Tổng số bài báo (Global Papers)', 'Dữ liệu được truy xuất Real-time từ API OpenAlex. Hiện tại có tổng cộng ${_formatNum(d.realTotalPublications)} bài báo khoa học đã được công bố trên toàn cầu về từ khóa này. Con số này được tổng hợp từ kho dữ liệu hơn 250 triệu tài liệu, phản ánh chính xác quy mô nghiên cứu của chủ đề.'),
      ),
      _StatCardData(
        label: 'Core Citations',
        value: _formatNum(d.totalCitations),
        icon: Icons.format_quote,
        color: Colors.teal,
        sparkline: d.recentYearCounts,
        onTap: () => _showEvidence(context, 'Trích dẫn cốt lõi (Core Citations)', 'Phân tích tập trung vào dải dữ liệu cốt lõi (các bài báo có ảnh hưởng lớn nhất). Tổng lượt trích dẫn của dải dữ liệu này đạt ${_formatNum(d.totalCitations)} lượt, với trung bình mỗi bài đạt ${d.avgCitationCount.toStringAsFixed(1)} lượt trích dẫn. Điều này cho thấy mức độ quan tâm của cộng đồng học thuật đối với mảng nghiên cứu này.'),
      ),
      _StatCardData(
        label: 'H-Index',
        value: '${d.hIndex}',
        icon: Icons.bar_chart,
        color: Colors.orange,
        sparkline: d.recentYearCounts,
        onTap: () => _showEvidence(context, 'Chỉ số H-Index', 'Chỉ số H-Index của chủ đề đạt ${d.hIndex}, được thuật toán tính toán tự động dựa trên phân phối trích dẫn. H-Index = ${d.hIndex} mang ý nghĩa học thuật là có ít nhất ${d.hIndex} bài báo cốt lõi nhận được từ ${d.hIndex} lượt trích dẫn trở lên. Chỉ số này đại diện cho sức ảnh hưởng và chất lượng nghiên cứu thực tế của toàn bộ lĩnh vực.'),
      ),
      _StatCardData(
        label: 'Peak Year',
        value: d.mostActiveYear != null ? '${d.mostActiveYear}' : '—',
        icon: Icons.calendar_today,
        color: Colors.purple,
        sparkline: d.recentYearCounts,
        onTap: () => _showEvidence(context, 'Năm bùng nổ (Peak Year)', 'Đỉnh điểm nghiên cứu (Peak Year) được hệ thống ghi nhận vào năm ${d.mostActiveYear}, đánh dấu thời kỳ bùng nổ số lượng công bố khoa học. Biểu đồ Sparkline ở góc thẻ cũng phác họa đường cong xu hướng xuất bản trong 6 năm gần nhất, giúp nhận diện chu kỳ thoái trào hoặc phát triển của chủ đề.'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.45,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => _StatCard(data: cards[i]),
    );
  }

  // ── Ecosystem Flux ────────────────────────────────────────────
  Widget _buildFluxSection(SearchProvider p, DashboardData d) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Ecosystem Flux',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Multi-dimensional research velocity',
                  style:
                      TextStyle(color: Colors.grey[500], fontSize: 11)),
            ]),
            const Spacer(),
            // Toggle chips
            _fluxToggle('Time', 0),
            const SizedBox(width: 6),
            _fluxToggle('Journal', 1),
            const SizedBox(width: 6),
            _fluxToggle('Author', 2),
          ]),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 8),
            child: _buildFluxChart(p),
          ),
        ),
        // Bottom stats
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            _fluxStat('Peak', d.mostActiveYear != null ? "${d.mostActiveYear}" : '—',
                context.appTheme),
            _divider(),
            _fluxStat('Top Journal',
                d.topJournal != null
                    ? _truncate(d.topJournal!, 14)
                    : '—',
                Colors.teal),
            _divider(),
            _fluxStat('Core Author',
                d.topAuthor != null
                    ? _truncate(d.topAuthor!, 12)
                    : '—',
                Colors.orange),
          ]),
        ),
      ]),
    );
  }

  Widget _fluxToggle(String label, int idx) {
    final selected = _fluxMode == idx;
    return GestureDetector(
      onTap: () => setState(() => _fluxMode = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? context.appTheme[700] : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey[600])),
      ),
    );
  }

  Widget _buildFluxChart(SearchProvider p) {
    final trendData = p.trendData ?? [];
    if (trendData.isEmpty) {
      return const Center(
          child: Text('No data', style: TextStyle(color: Colors.grey)));
    }

    List<FlSpot> spots;
    Color lineColor;

    switch (_fluxMode) {
      case 1: // Journal — cumulative journal count by year (simulated)
        int cumulative = 0;
        spots = trendData.asMap().entries.map((e) {
          cumulative += (e.value.count * 0.6).round();
          return FlSpot(e.key.toDouble(), cumulative.toDouble());
        }).toList();
        lineColor = Colors.teal;
      case 2: // Author — simulated author velocity
        spots = trendData.asMap().entries.map((e) {
          final authorCount = (e.value.count * 2.3).roundToDouble();
          return FlSpot(e.key.toDouble(), authorCount);
        }).toList();
        lineColor = Colors.orange;
      default: // Time
        spots = trendData.asMap().entries
            .map((e) =>
                FlSpot(e.key.toDouble(), e.value.count.toDouble()))
            .toList();
        lineColor = context.appTheme;
    }

    final maxY = spots
        .map((s) => s.y)
        .reduce((a, b) => a > b ? a : b);

    return LineChart(LineChartData(
      gridData: FlGridData(
        drawHorizontalLine: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: Colors.grey[100]!, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: (trendData.length / 4).ceilToDouble(),
            getTitlesWidget: (v, _) {
              final idx = v.toInt();
              if (idx < 0 || idx >= trendData.length) {
                return const SizedBox();
              }
              return Text("'${trendData[idx].year % 100}",
                  style: const TextStyle(
                      fontSize: 9, color: Colors.grey));
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (spots.length - 1).toDouble(),
      minY: 0,
      maxY: maxY * 1.25,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) => touchedSpots
              .map((s) => LineTooltipItem(
                    '${trendData[s.spotIndex].year}\n${s.y.toInt()}',
                    const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ))
              .toList(),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: lineColor,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                lineColor.withValues(alpha: 0.2),
                lineColor.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    ));
  }

  Widget _fluxStat(String label, String value, Color color) {
    return Expanded(
      child: Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ]),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 28,
        color: Colors.grey[200],
        margin: const EdgeInsets.symmetric(horizontal: 8),
      );

  // ── Field Distribution (simulated from journals) ──────────────
  Widget _buildFieldDistribution(SearchProvider p) {
    final journals = p.topJournals ?? [];
    if (journals.isEmpty) return const SizedBox();

    // Simulate fields from journal names
    final total = journals.fold(0, (s, j) => s + j.count);
    if (total == 0) return const SizedBox();

    // Map journals to fields by keywords in name
    final fieldMap = <String, int>{};
    for (final j in journals) {
      final name = j.name.toLowerCase();
      String field;
      if (name.contains('comput') || name.contains('software') || name.contains('digital')) {
        field = 'Computer Sci';
      } else if (name.contains('physics') || name.contains('phys')) {
        field = 'Physics';
      } else if (name.contains('bio') || name.contains('med') || name.contains('health')) {
        field = 'Bio & Med';
      } else if (name.contains('chem')) {
        field = 'Chemistry';
      } else if (name.contains('environ') || name.contains('ecol')) {
        field = 'Env Sci';
      } else if (name.contains('engin')) {
        field = 'Engineering';
      } else {
        field = 'Others';
      }
      fieldMap[field] = (fieldMap[field] ?? 0) + j.count;
    }

    final fields = fieldMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    const fieldColors = [
      Color(0xFF3730A3),
      Color(0xFF0F766E),
      Color(0xFFB45309),
      Color(0xFF7C3AED),
      Color(0xFF0369A1),
      Color(0xFF4D7C0F),
      Color(0xFF9F1239),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Field Distribution',
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Text('Research landscape mapping',
            style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        const SizedBox(height: 16),

        // Treemap-style blocks
        _buildTreemap(fields, total, fieldColors),
        const SizedBox(height: 12),

        // Legend
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: fields.asMap().entries.map((e) {
            final color = fieldColors[e.key % fieldColors.length];
            final pct = (e.value.value / total * 100).toStringAsFixed(1);
            return Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Text('${e.value.key} $pct%',
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey[700])),
            ]);
          }).toList(),
        ),
      ]),
    );
  }

  Widget _buildTreemap(
      List<MapEntry<String, int>> fields, int total, List<Color> fieldColors) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      const height = 120.0;

      // Simple horizontal treemap
      return SizedBox(
        height: height,
        child: Row(
          children: fields.asMap().entries.map((entry) {
            final i = entry.key;
            final field = entry.value;
            final ratio = field.value / total;
            final color = fieldColors[i % fieldColors.length];
            final blockWidth = width * ratio;

            return Flexible(
              flex: field.value,
              child: Container(
                height: height,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: blockWidth > 40
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              field.key,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${(ratio * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.8),
                                  fontSize: 9),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  // ── Bottom Highlights ─────────────────────────────────────────
  Widget _buildHighlights(DashboardData d) {
    final p = widget.provider;
    return Column(children: [
      if (d.mostInfluentialPaper != null)
        _highlightCard(
          icon: Icons.emoji_events,
          iconColor: Colors.amber[700]!,
          label: 'Most Influential Paper',
          content: d.mostInfluentialPaper!,
          badge: '${d.mostInfluentialCitations} citations',
          badgeColor: Colors.amber[700]!,
          onTap: () {
            // Find the publication object and navigate
            final matches = p.allPubs.where((pub) =>
                pub.title == d.mostInfluentialPaper);
            if (matches.isNotEmpty) {
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => PublicationDetailScreen(pub: matches.first)));
            }
          },
        ),
      if (d.topJournal != null) ...[
        const SizedBox(height: 10),
        _highlightCard(
          icon: Icons.library_books,
          iconColor: Colors.teal[600]!,
          label: 'Top Journal',
          content: d.topJournal!,
          badge: '#1 ranked',
          badgeColor: Colors.teal[600]!,
          onTap: () {
            final journals = p.topJournals ?? [];
            final match = journals.where((j) => j.name == d.topJournal);
            if (match.isNotEmpty) {
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => JournalDetailScreen(journal: match.first)));
            }
          },
        ),
      ],
      if (d.topAuthor != null) ...[
        const SizedBox(height: 10),
        _highlightCard(
          icon: Icons.person,
          iconColor: Colors.orange[700]!,
          label: 'Core Author',
          content: d.topAuthor!,
          badge: 'Most papers',
          badgeColor: Colors.orange[700]!,
          onTap: () {
            final authorPubs = p.allPubs
                .where((pub) => pub.authors.any(
                      (a) => a.toLowerCase() == d.topAuthor!.toLowerCase(),
                    ))
                .toList()
              ..sort((a, b) => b.citationCount.compareTo(a.citationCount));
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
                builder: (ctx, sc) => Column(children: [
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
                        backgroundColor: Colors.orange[100],
                        child: Text(d.topAuthor![0].toUpperCase(),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700])),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.topAuthor!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('${authorPubs.length} publications in dataset',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600])),
                          ])),
                    ]),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: authorPubs.isEmpty
                        ? Center(
                            child: Text('No detailed data available.',
                                style: TextStyle(color: Colors.grey[500])))
                        : ListView.separated(
                            controller: sc,
                            padding: const EdgeInsets.all(12),
                            itemCount: authorPubs.length,
                            separatorBuilder: (_, i) => const Divider(height: 1),
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
                                trailing: const Icon(Icons.chevron_right, size: 16),
                                onTap: () {
                                  Navigator.pop(ctx2);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (navCtx) =>
                                            PublicationDetailScreen(pub: pub)),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ]),
              ),
            );
          },
        ),
      ],
    ]);
  }

  Widget _highlightCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String content,
    required String badge,
    required Color badgeColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[500])),
                const SizedBox(height: 2),
                Text(content,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ]),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(badge,
                  style: TextStyle(
                      fontSize: 10,
                      color: badgeColor,
                      fontWeight: FontWeight.w600)),
            ),
            if (onTap != null) ...[
              const SizedBox(height: 4),
              Icon(Icons.chevron_right, size: 14, color: Colors.grey[400]),
            ],
          ],
        ),
      ]),
    ));
  }

  // ── Helpers ───────────────────────────────────────────────────
  void _showEvidence(BuildContext context, String title, String evidenceText) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(evidenceText, style: const TextStyle(height: 1.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  String _formatNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  String _truncate(String s, int max) =>
      s.length > max ? '${s.substring(0, max)}.' : s;
}

// ── Stat Card ──────────────────────────────────────────────────
class _StatCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final List<int> sparkline;
  final VoidCallback? onTap;
  const _StatCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.sparkline,
    this.onTap,
  });
}

class _StatCard extends StatelessWidget {
  final _StatCardData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(data.icon, color: data.color, size: 16),
            ),
            const Spacer(),
            // Mini sparkline
            if (data.sparkline.isNotEmpty)
              SizedBox(
                width: 40,
                height: 22,
                child: _MiniSparkline(
                    data: data.sparkline, color: data.color),
              ),
          ]),
          const SizedBox(height: 8),
          Text(data.value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: data.color,
                  height: 1.1)),
          const SizedBox(height: 2),
          Text(data.label,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    ));
  }
}

// ── Mini Sparkline (custom painter) ───────────────────────────
class _MiniSparkline extends StatelessWidget {
  final List<int> data;
  final Color color;
  const _MiniSparkline({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(data: data, color: color),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<int> data;
  final Color color;
  _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final maxVal = data.reduce(math.max).toDouble();
    if (maxVal == 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - (data[i] / maxVal) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}







