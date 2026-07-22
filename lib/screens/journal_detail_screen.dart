import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trend_data.dart';
import '../models/publication.dart';
import '../state/search_provider.dart';
import '../firebase/firebase_analytics_service.dart';
import 'publication_detail_screen.dart';
import '../state/config_provider.dart';

class JournalDetailScreen extends StatefulWidget {
  final JournalCount journal;
  const JournalDetailScreen({super.key, required this.journal});

  @override
  State<JournalDetailScreen> createState() => _JournalDetailScreenState();
}

class _JournalDetailScreenState extends State<JournalDetailScreen> {
  /// Publications from the current search dataset that belong to this journal.
  List<Publication> _relatedPubs = [];

  @override
  void initState() {
    super.initState();
    _loadRelatedPublications();
    _logAnalytics();
  }

  /// Filter allPubs from the provider to find publications in this journal.
  void _loadRelatedPublications() {
    final provider = context.read<SearchProvider>();
    final source = provider.allPubs.isNotEmpty ? provider.allPubs : provider.results;
    _relatedPubs = source
        .where((p) => p.journalName == widget.journal.name)
        .toList()
      ..sort((a, b) => b.citationCount.compareTo(a.citationCount));
  }

  Future<void> _logAnalytics() async {
    await FirebaseAnalyticsService.logViewJournal(widget.journal.name);
  }

  @override
  Widget build(BuildContext context) {
    final journal = widget.journal;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Journal Details'),
        backgroundColor: context.appTheme[700],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Journal name header ──────────────────────────────
          _buildHeader(journal),
          const SizedBox(height: 16),

          // ── Stats row ────────────────────────────────────────
          _buildStatsRow(journal),
          const SizedBox(height: 20),

          // ── Related publications ─────────────────────────────
          _buildRelatedSection(),
        ],
      ),
    );
  }

  // ── Header card ──────────────────────────────────────────────
  Widget _buildHeader(JournalCount journal) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal[700]!, Colors.teal[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.library_books, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  journal.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Academic Journal',
                    style: TextStyle(
                      color: Colors.teal[50],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3 stat cards ─────────────────────────────────────────────
  Widget _buildStatsRow(JournalCount journal) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.article_outlined,
            color: context.appTheme,
            label: 'Publications',
            value: '${journal.count}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.format_quote,
            color: Colors.teal,
            label: 'Total Citations',
            value: _formatNum(journal.totalCitations),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.analytics_outlined,
            color: Colors.orange,
            label: 'Avg Citations',
            value: journal.avgCitationsPerPublication.toStringAsFixed(1),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Related publications ──────────────────────────────────────
  Widget _buildRelatedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.article, color: context.appTheme[400], size: 18),
            const SizedBox(width: 8),
            const Text(
              'Related Publications',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (_relatedPubs.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: context.appTheme[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_relatedPubs.length}',
                  style: TextStyle(
                    color: context.appTheme[700],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_relatedPubs.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: Colors.grey[400], size: 18),
                const SizedBox(width: 8),
                Text(
                  'No related publications in current dataset',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          )
        else
          ..._relatedPubs.asMap().entries.map(
            (entry) => _RelatedPubCard(pub: entry.value, rank: entry.key + 1),
          ),
      ],
    );
  }

  String _formatNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ── Related Publication Card ──────────────────────────────────
class _RelatedPubCard extends StatelessWidget {
  final Publication pub;
  final int rank;
  const _RelatedPubCard({required this.pub, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PublicationDetailScreen(pub: pub),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rank badge
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: rank <= 3 ? Colors.teal[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: rank <= 3 ? Colors.teal[700] : Colors.grey[600],
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
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (pub.authors.isNotEmpty)
                      Text(
                        pub.authors.take(2).join(', ') +
                            (pub.authors.length > 2 ? ' et al.' : ''),
                        style:
                            TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 10,
                      children: [
                        if (pub.year != null)
                          _tag(Icons.calendar_today, '${pub.year}', Colors.teal),
                        _tag(
                          Icons.format_quote,
                          '${pub.citationCount} citations',
                          context.appTheme,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}
