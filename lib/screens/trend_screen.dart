import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../state/search_provider.dart';
import '../models/publication.dart';
import 'publication_detail_screen.dart';

class TrendScreen extends StatefulWidget {
  final SearchProvider provider;
  const TrendScreen({super.key, required this.provider});
  @override
  State<TrendScreen> createState() => _TrendScreenState();
}

class _TrendScreenState extends State<TrendScreen> {
  int _section = 0; // 0=trend, 1=top papers, 2=journals, 3=authors

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    if (p.isFetchingAll && p.trendData == null) {
      return const Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Loading trend data...', style: TextStyle(color: Colors.grey)),
        ],
      ));
    }

    return Column(
      children: [
        // Section tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            _chip('Publication Trend', 0, Icons.show_chart),
            _chip('Top Papers', 1, Icons.star),
            _chip('Top Journals', 2, Icons.library_books),
            _chip('Top Authors', 3, Icons.people),
          ]),
        ),
        Expanded(child: _buildSection(p)),
      ],
    );
  }

  Widget _chip(String label, int idx, IconData icon) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14), const SizedBox(width: 4), Text(label),
      ]),
      selected: _section == idx,
      onSelected: (_) => setState(() => _section = idx),
      selectedColor: Colors.indigo[100],
      labelStyle: TextStyle(color: _section == idx ? Colors.indigo[800] : Colors.grey[700], fontSize: 12),
    ),
  );

  Widget _buildSection(SearchProvider p) {
    switch (_section) {
      case 0: return _buildTrendChart(p);
      case 1: return _buildTopPapers(p);
      case 2: return _buildTopJournals(p);
      case 3: return _buildTopAuthors(p);
      default: return const SizedBox();
    }
  }

  Widget _buildTrendChart(SearchProvider p) {
    final data = p.trendData;
    if (data == null || data.isEmpty) {
      return const Center(child: Text('No trend data available', style: TextStyle(color: Colors.grey)));
    }

    final maxY = data.map((d) => d.count).reduce((a, b) => a > b ? a : b).toDouble();
    final spots = data.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble()))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Publications per Year for "${p.query}"',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text('${data.length} years of data • ${p.allPubs.length} total publications',
            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: LineChart(LineChartData(
              gridData: FlGridData(
                drawHorizontalLine: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey[200]!, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
                )),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: (data.length / 5).ceilToDouble(),
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= data.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('${data[idx].year}',
                        style: const TextStyle(fontSize: 9, color: Colors.grey)),
                    );
                  },
                )),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: 0, maxX: (data.length - 1).toDouble(),
              minY: 0, maxY: maxY * 1.2,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.indigo[600],
                  barWidth: 3,
                  dotData: FlDotData(
                    getDotPainter: (p0, p1, p2, p3) => FlDotCirclePainter(
                      radius: 3,
                      color: Colors.indigo[600]!,
                      strokeColor: Colors.white,
                      strokeWidth: 1.5,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.indigo.withValues(alpha: 0.1),
                  ),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPapers(SearchProvider p) {
    final pubs = List<Publication>.from(p.allPubs)
      ..sort((a, b) => b.citationCount.compareTo(a.citationCount));
    final top = pubs.take(20).toList();
    if (top.isEmpty) return const Center(child: Text('No data', style: TextStyle(color: Colors.grey)));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: top.length,
      itemBuilder: (ctx, i) {
        final pub = top[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigo[50],
              child: Text('${i + 1}', style: TextStyle(color: Colors.indigo[700], fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            title: Text(pub.title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            subtitle: Text('${pub.citationCount} citations • ${pub.year ?? "N/A"}',
              style: TextStyle(color: Colors.indigo[400], fontSize: 12)),
            onTap: () => Navigator.push(ctx,
              MaterialPageRoute(builder: (_) => PublicationDetailScreen(pub: pub))),
          ),
        );
      },
    );
  }

  Widget _buildTopJournals(SearchProvider p) {
    final journals = p.topJournals ?? [];
    if (journals.isEmpty) return const Center(child: Text('No data', style: TextStyle(color: Colors.grey)));
    final maxCount = journals.first.count;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: journals.length,
      itemBuilder: (ctx, i) {
        final j = journals[i];
        final ratio = j.count / maxCount;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(radius: 12,
                  backgroundColor: Colors.teal[50],
                  child: Text('${i + 1}', style: TextStyle(color: Colors.teal[700], fontSize: 11, fontWeight: FontWeight.bold))),
                const SizedBox(width: 10),
                Expanded(child: Text(j.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                Text('${j.count}', style: TextStyle(color: Colors.teal[700], fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(Colors.teal[400]),
                  minHeight: 6,
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildTopAuthors(SearchProvider p) {
    final authors = p.topAuthors ?? [];
    if (authors.isEmpty) return const Center(child: Text('No data', style: TextStyle(color: Colors.grey)));
    final maxCount = authors.first.count;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: authors.length,
      itemBuilder: (ctx, i) {
        final a = authors[i];
        final ratio = a.count / maxCount;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(radius: 12,
                  backgroundColor: Colors.orange[50],
                  child: Text('${i + 1}', style: TextStyle(color: Colors.orange[700], fontSize: 11, fontWeight: FontWeight.bold))),
                const SizedBox(width: 10),
                Expanded(child: Text(a.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                Text('${a.count} papers', style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold, fontSize: 12)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(Colors.orange[400]),
                  minHeight: 6,
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}
