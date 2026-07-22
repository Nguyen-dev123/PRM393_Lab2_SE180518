import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/search_provider.dart';
import '../models/publication.dart';
import '../widgets/loading_widget.dart';
import 'publication_detail_screen.dart';
import 'journal_detail_screen.dart';
import '../state/config_provider.dart';

/// Journal Tab: Publications list + Journal Stats + Top Cited
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});
  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _sortBy = 'citations'; // 'citations' | 'year' | 'title'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Publication> _sorted(List<Publication> pubs) {
    final list = List<Publication>.from(pubs);
    switch (_sortBy) {
      case 'citations':
        list.sort((a, b) => b.citationCount.compareTo(a.citationCount));
      case 'year':
        list.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
      case 'title':
        list.sort((a, b) => a.title.compareTo(b.title));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Journal',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: context.appTheme[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: context.appTheme[200],
          tabs: const [
            Tab(icon: Icon(Icons.article, size: 18), text: 'Publications'),
            Tab(icon: Icon(Icons.library_books, size: 18), text: 'Journals'),
            Tab(icon: Icon(Icons.leaderboard, size: 18), text: 'Top Cited'),
          ],
        ),
      ),
      body: Consumer<SearchProvider>(
        builder: (ctx, provider, _) {
          if (provider.state == AppState.idle) {
            return const EmptyState(
              message: 'Search a topic on Home tab\nto explore publications',
              icon: Icons.library_books,
            );
          }
          if (provider.state == AppState.loading && provider.results.isEmpty) {
            return const LoadingList();
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildPublications(provider),
              _buildJournalStats(provider),
              _buildTopCited(provider),
            ],
          );
        },
      ),
    );
  }

  // ── Tab 1: All Publications ──────────────────────────────────
  Widget _buildPublications(SearchProvider provider) {
    final pubs = provider.results;
    if (pubs.isEmpty) {
      return const EmptyState(message: 'No publications found', icon: Icons.search_off);
    }

    return Column(
      children: [
        // Sort bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('${pubs.length} publications',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const Spacer(),
              const Text('Sort: ',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              DropdownButton<String>(
                value: _sortBy,
                isDense: true,
                underline: const SizedBox(),
                style: TextStyle(
                    fontSize: 12,
                    color: context.appTheme[700],
                    fontWeight: FontWeight.w600),
                items: const [
                  DropdownMenuItem(value: 'citations', child: Text('Citations')),
                  DropdownMenuItem(value: 'year', child: Text('Newest')),
                  DropdownMenuItem(value: 'title', child: Text('Title A-Z')),
                ],
                onChanged: (v) => setState(() => _sortBy = v!),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (s) {
              if (s is ScrollEndNotification &&
                  s.metrics.pixels >= s.metrics.maxScrollExtent - 200) {
                provider.loadMore();
              }
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount:
                  _sorted(pubs).length + (provider.hasMore ? 1 : 0),
              itemBuilder: (ctx, i) {
                final sorted = _sorted(pubs);
                if (i == sorted.length) {
                  return provider.loadingMore
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : TextButton(
                          onPressed: provider.loadMore,
                          child: const Text('Load more'),
                        );
                }
                final pub = sorted[i];
                return _JournalPublicationCard(pub: pub, index: i);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── Tab 2: Journal Stats ─────────────────────────────────────
  Widget _buildJournalStats(SearchProvider provider) {
    if (provider.isFetchingAll && provider.topJournals == null) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Loading journal data...', style: TextStyle(color: Colors.grey)),
        ]),
      );
    }

    final journals = provider.topJournals ?? [];
    if (journals.isEmpty) {
      return const EmptyState(
        message: 'No journal data available.\nSearch a topic first.',
        icon: Icons.library_books_outlined,
      );
    }

    final maxCount = journals.first.count;
    final total = journals.fold(0, (s, j) => s + j.count);

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: journals.length,
      itemBuilder: (ctx, i) {
        final j = journals[i];
        final ratio = j.count / maxCount;
        final pct = total > 0 ? (j.count / total * 100).toStringAsFixed(1) : '0';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: i < 3 ? 2 : 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => JournalDetailScreen(journal: j),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    // Rank badge
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.teal[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: Colors.teal[700],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        j.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                  ]),
                  const SizedBox(height: 10),
                  // Progress bar + stats
                  Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          backgroundColor: Colors.grey[100],
                          valueColor: AlwaysStoppedAnimation(Colors.teal[500]!),
                          minHeight: 7,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${j.count} ($pct%)',
                      style: TextStyle(
                        color: Colors.teal[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  // Citation stats row
                  Row(children: [
                    Icon(Icons.format_quote, size: 12, color: context.appTheme[300]),
                    const SizedBox(width: 4),
                    Text(
                      '${j.totalCitations} citations total',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.analytics_outlined, size: 12, color: Colors.orange[300]),
                    const SizedBox(width: 4),
                    Text(
                      '${j.avgCitationsPerPublication.toStringAsFixed(1)} avg/pub',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Tab 3: Top Cited ─────────────────────────────────────────
  Widget _buildTopCited(SearchProvider provider) {
    if (provider.isFetchingAll && provider.allPubs.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Loading all publications...', style: TextStyle(color: Colors.grey)),
        ]),
      );
    }

    final allPubs = List<Publication>.from(
        provider.allPubs.isNotEmpty ? provider.allPubs : provider.results)
      ..sort((a, b) => b.citationCount.compareTo(a.citationCount));
    final top20 = allPubs.take(20).toList();

    if (top20.isEmpty) {
      return const EmptyState(message: 'No data available', icon: Icons.star_border);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: top20.length,
      itemBuilder: (ctx, i) {
        final pub = top20[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.push(ctx,
                MaterialPageRoute(builder: (_) => PublicationDetailScreen(pub: pub))),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                // Rank medal
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: i == 0
                        ? Colors.amber[400]
                        : i == 1
                            ? Colors.grey[400]
                            : i == 2
                                ? Colors.brown[300]
                                : context.appTheme[50],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: i < 3
                        ? Icon(Icons.emoji_events,
                            color: Colors.white, size: 20)
                        : Text('${i + 1}',
                            style: TextStyle(
                                color: context.appTheme[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pub.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.format_quote,
                              size: 13, color: context.appTheme[400]),
                          const SizedBox(width: 4),
                          Text('${pub.citationCount} citations',
                              style: TextStyle(
                                  color: context.appTheme[600],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                          if (pub.year != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.calendar_today,
                                size: 12, color: Colors.teal[400]),
                            const SizedBox(width: 4),
                            Text('${pub.year}',
                                style: TextStyle(
                                    color: Colors.teal[600], fontSize: 12)),
                          ],
                        ]),
                        if (pub.journalName != null) ...[
                          const SizedBox(height: 2),
                          Text(pub.journalName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[500])),
                        ],
                      ]),
                ),
                const Icon(Icons.chevron_right,
                    color: Colors.grey, size: 18),
              ]),
            ),
          ),
        );
      },
    );
  }
}

// ── Journal Publication Card ───────────────────────────────────
class _JournalPublicationCard extends StatelessWidget {
  final Publication pub;
  final int index;
  const _JournalPublicationCard({required this.pub, required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PublicationDetailScreen(pub: pub)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: context.appTheme[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text('${index + 1}',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: context.appTheme[700])),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(pub.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 6),
            if (pub.authors.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 34),
                child: Text(
                  pub.authors.take(3).join(', ') +
                      (pub.authors.length > 3 ? ' et al.' : ''),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Wrap(spacing: 12, children: [
                if (pub.year != null)
                  _chip(Icons.calendar_today, '${pub.year}', Colors.teal),
                _chip(Icons.format_quote, '${pub.citationCount}', context.appTheme),
                if (pub.journalName != null)
                  _chip(Icons.library_books, pub.journalName!, Colors.orange),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 3),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 130),
        child: Text(text,
            style: TextStyle(fontSize: 11, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ),
    ]);
  }
}
