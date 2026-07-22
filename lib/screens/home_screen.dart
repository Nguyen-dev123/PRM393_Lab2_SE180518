import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/search_provider.dart';
import '../models/publication.dart';
import '../widgets/loading_widget.dart';
import 'publication_detail_screen.dart';
import '../state/config_provider.dart';

/// Home Tab: Search Topic + Recent Searches
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _ctrl = TextEditingController();

  final _suggestions = [
    'Artificial Intelligence',
    'Machine Learning',
    'Blockchain',
    'Internet of Things',
    'Cybersecurity',
    'Data Science',
    'Software Engineering',
    'Deep Learning',
    'Natural Language Processing',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _search(String q) {
    if (q.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    context.read<SearchProvider>().search(q.trim());
  }

  void _showHistory(SearchProvider provider) {
    if (provider.history.isEmpty) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(children: [
              Icon(Icons.history, color: context.appTheme, size: 20),
              const SizedBox(width: 8),
              const Text('Recent Searches',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  provider.clearHistory();
                  Navigator.pop(context);
                },
                child: const Text('Clear all', style: TextStyle(color: Colors.red)),
              ),
            ]),
          ),
          const Divider(height: 1),
          ...provider.history.map((h) => ListTile(
            leading: const Icon(Icons.history, color: Colors.grey, size: 18),
            title: Text(h, style: const TextStyle(fontSize: 14)),
            trailing: const Icon(Icons.north_west, color: Colors.grey, size: 16),
            onTap: () {
              Navigator.pop(context);
              _ctrl.text = h;
              _search(h);
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Journal Trend Analyzer',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: context.appTheme[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<SearchProvider>(
            builder: (_, p, child) => p.history.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.history),
                    tooltip: 'Recent Searches',
                    onPressed: () => _showHistory(p),
                  )
                : const SizedBox(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(62),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              key: const Key('searchBox'),
              controller: _ctrl,
              onSubmitted: _search,
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search research topic...',
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search, color: context.appTheme),
                  onPressed: () => _search(_ctrl.text),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Consumer<SearchProvider>(
        builder: (ctx, provider, _) {
          switch (provider.state) {
            case AppState.idle:
              return _buildIdle(provider);
            case AppState.loading:
              return const LoadingList();
            case AppState.error:
              return ErrorState(
                message: provider.errorMsg,
                onRetry: () => provider.search(provider.query),
              );
            case AppState.loaded:
              return _buildResults(provider);
          }
        },
      ),
    );
  }

  Widget _buildIdle(SearchProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Recent searches section
        if (provider.history.isNotEmpty) ...[
          Row(children: [
            Icon(Icons.history, color: context.appTheme[400], size: 18),
            const SizedBox(width: 8),
            const Text('Recent Searches',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton(
              onPressed: () => _showHistory(provider),
              child: Text('See all',
                  style: TextStyle(color: context.appTheme[600], fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provider.history.take(5).map((h) => ActionChip(
              avatar: const Icon(Icons.history, size: 14, color: Colors.grey),
              label: Text(h),
              backgroundColor: Colors.grey[100],
              labelStyle: TextStyle(color: Colors.grey[700], fontSize: 12),
              onPressed: () {
                _ctrl.text = h;
                _search(h);
              },
            )).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Popular Topics
        Row(children: [
          Icon(Icons.tips_and_updates, color: context.appTheme[400], size: 18),
          const SizedBox(width: 8),
          const Text('Popular Topics',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestions
              .map((s) => ActionChip(
                    avatar: const Icon(Icons.trending_up, size: 14),
                    label: Text(s),
                    backgroundColor: context.appTheme[50],
                    labelStyle:
                        TextStyle(color: context.appTheme[700], fontSize: 12),
                    onPressed: () {
                      _ctrl.text = s;
                      _search(s);
                    },
                  ))
              .toList(),
        ),
        const SizedBox(height: 24),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(children: [
                Icon(Icons.analytics, color: context.appTheme[600], size: 22),
                const SizedBox(width: 8),
                const Text('About', style: TextStyle(fontWeight: FontWeight.bold)),
              ]),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Journal Trend Analyzer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 8),
                  Text('Data source: OpenAlex API\n(Free, open catalog of global research)'),
                  SizedBox(height: 8),
                  Text('Cloud platform: Firebase\n(Auth, Storage, Analytics, Crashlytics, FCM, Remote Config)'),
                  SizedBox(height: 8),
                  Text('Course: PRM393 – Mobile Programming'),
                  SizedBox(height: 4),
                  Text('Built with Flutter 3.x + Dart'),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              ],
            ),
          ),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: context.appTheme[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.info, color: context.appTheme[600], size: 18),
                      const SizedBox(width: 8),
                      const Text('About',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: context.appTheme[300], size: 16),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      'Journal Trend Analyzer retrieves real-time publication data '
                      'from OpenAlex — a free, open catalog of global research. '
                      'Explore trends, top papers, influential authors, and dashboards.',
                      style: TextStyle(
                          color: context.appTheme[800], fontSize: 13, height: 1.5),
                    ),
                  ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResults(SearchProvider provider) {
    final results = provider.results;
    if (results.isEmpty) {
      return EmptyState(
        message: 'No results found for "${provider.query}"',
        icon: Icons.search_off,
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(children: [
            Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text('${results.length} results for "${provider.query}"',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ]),
        ),
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
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              itemCount: results.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (ctx2, i) {
                if (i == results.length) {
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
                return _PublicationCard(pub: results[i], rank: i + 1);
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ── Publication Card (reusable) ────────────────────────────────
class PublicationCard extends StatelessWidget {
  final Publication pub;
  final int rank;
  const PublicationCard({super.key, required this.pub, required this.rank});

  @override
  Widget build(BuildContext context) {
    return _PublicationCard(pub: pub, rank: rank);
  }
}

class _PublicationCard extends StatelessWidget {
  final Publication pub;
  final int rank;
  const _PublicationCard({required this.pub, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PublicationDetailScreen(pub: pub)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color:
                      rank <= 3 ? Colors.amber[100] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: rank <= 3
                          ? Colors.amber[800]
                          : Colors.grey[600],
                    ),
                  ),
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
                            fontWeight: FontWeight.w600, fontSize: 13.5)),
                    const SizedBox(height: 5),
                    if (pub.authors.isNotEmpty)
                      Text(
                        pub.authors.take(2).join(', ') +
                            (pub.authors.length > 2 ? ' et al.' : ''),
                        style: TextStyle(
                            fontSize: 11.5, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 5),
                    Wrap(spacing: 8, children: [
                      if (pub.year != null)
                        _tag(Icons.calendar_today, '${pub.year}',
                            Colors.teal),
                      _tag(Icons.format_quote,
                          '${pub.citationCount}', context.appTheme),
                      if (pub.journalName != null)
                        _tag(Icons.library_books, pub.journalName!,
                            Colors.orange,
                            maxWidth: 140),
                    ]),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(IconData icon, String text, Color color,
      {double? maxWidth}) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 3),
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? 100),
        child: Text(text,
            style: TextStyle(fontSize: 11, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ),
    ]);
  }
}

