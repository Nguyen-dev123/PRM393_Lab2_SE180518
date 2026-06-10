import 'package:flutter/material.dart';
import '../state/search_provider.dart';

class DashboardScreen extends StatelessWidget {
  final SearchProvider provider;
  const DashboardScreen({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isFetchingAll && provider.dashboard == null) {
      return const Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Building dashboard...', style: TextStyle(color: Colors.grey)),
        ],
      ));
    }

    final d = provider.dashboard;
    if (d == null) return const Center(child: Text('No data available', style: TextStyle(color: Colors.grey)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Research Dashboard: "${provider.query}"',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text('Based on ${provider.allPubs.length} publications from OpenAlex',
            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 16),

          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _statCard('Total Publications', '${d.totalPublications}',
                Icons.article, Colors.indigo),
              _statCard('Avg Citations', d.avgCitationCount.toStringAsFixed(1),
                Icons.format_quote, Colors.teal),
              if (d.mostActiveYear != null)
                _statCard('Most Active Year', '${d.mostActiveYear}',
                  Icons.calendar_today, Colors.orange),
              if (d.mostInfluentialCitations != null)
                _statCard('Max Citations', '${d.mostInfluentialCitations}',
                  Icons.star, Colors.purple),
            ],
          ),
          const SizedBox(height: 16),

          // Top Journal
          if (d.topJournal != null)
            _infoCard('Top Journal', d.topJournal!, Icons.library_books, Colors.teal),
          const SizedBox(height: 10),

          // Top Author
          if (d.topAuthor != null)
            _infoCard('Top Contributing Author', d.topAuthor!, Icons.person, Colors.orange),
          const SizedBox(height: 10),

          // Most Influential Paper
          if (d.mostInfluentialPaper != null)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.emoji_events, color: Colors.amber[700], size: 20),
                    const SizedBox(width: 8),
                    const Text('Most Influential Paper',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ]),
                  const SizedBox(height: 8),
                  Text(d.mostInfluentialPaper!,
                    style: const TextStyle(fontSize: 13, height: 1.4)),
                  const SizedBox(height: 6),
                  Text('${d.mostInfluentialCitations} citations',
                    style: TextStyle(color: Colors.amber[700], fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 22),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String label, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ])),
        ]),
      ),
    );
  }
}
