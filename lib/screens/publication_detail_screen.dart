import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/publication.dart';
import '../firebase/firebase_analytics_service.dart';
import 'package:provider/provider.dart';
import '../state/config_provider.dart';
import '../viewmodels/bookmark_viewmodel.dart';

class PublicationDetailScreen extends StatefulWidget {
  final Publication pub;
  const PublicationDetailScreen({super.key, required this.pub});

  @override
  State<PublicationDetailScreen> createState() => _PublicationDetailScreenState();
}

class _PublicationDetailScreenState extends State<PublicationDetailScreen> {
  @override
  void initState() {
    super.initState();
    _logAnalytics();
  }

  Future<void> _logAnalytics() async {
    await FirebaseAnalyticsService.logViewPublication(
      widget.pub.title,
      widget.pub.year ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pub = widget.pub;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Publication Details'),
        backgroundColor: context.appTheme[700],
        foregroundColor: Colors.white,
        actions: [
          Builder(
            builder: (ctx) {
              final bvm = ctx.watch<BookmarkViewModel?>();
              if (bvm == null) return const SizedBox.shrink();
              final saved = bvm.isBookmarked(pub.id);
              return IconButton(
                icon: Icon(
                  saved ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                ),
                tooltip: saved ? 'Saved' : 'Save',
                onPressed: () async {
                  if (saved) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Already saved ✓')),
                    );
                    return;
                  }
                  try {
                    await bvm.add(pub);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Publication saved ✓')),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Failed: $e')),
                      );
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pub.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.4)),
                    const SizedBox(height: 12),
                    // Stats row
                    Row(children: [
                      _statChip(Icons.format_quote, '${pub.citationCount}', 'Citations', context.appTheme),
                      const SizedBox(width: 8),
                      if (pub.year != null)
                        _statChip(Icons.calendar_today, '${pub.year}', 'Year', Colors.teal),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Info
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Publication Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const Divider(),
                    if (pub.journalName != null) _infoRow(Icons.library_books, 'Journal', pub.journalName!),
                    if (pub.doi != null) _infoRow(Icons.link, 'DOI', pub.doi!),
                    if (pub.authors.isNotEmpty)
                      _infoRow(Icons.people, 'Authors', pub.authors.take(5).join(', ') + (pub.authors.length > 5 ? ' +${pub.authors.length - 5} more' : '')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Abstract
            if (pub.abstract != null && pub.abstract!.isNotEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Abstract', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const Divider(),
                      Text(pub.abstract!,
                        style: TextStyle(color: Colors.grey[700], height: 1.6, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Open link button
            if (pub.url != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Full Paper'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.appTheme[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final uri = Uri.parse(pub.url!);
                    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10)),
        ]),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    final bool isDoi = label == 'DOI';
    final bool isAuthors = label == 'Authors';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: isDoi
            ? () async {
                await Clipboard.setData(ClipboardData(text: value));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('DOI copied to clipboard ✓'),
                        duration: Duration(seconds: 2)),
                  );
                }
              }
            : isAuthors
                ? () {
                    final authors = widget.pub.authors;
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20))),
                      builder: (_) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40, height: 4,
                            margin: const EdgeInsets.only(top: 12),
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2)),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                            child: Row(children: [
                              Icon(Icons.people, color: context.appTheme[600], size: 20),
                              const SizedBox(width: 8),
                              Text('${authors.length} Authors',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 15)),
                            ]),
                          ),
                          const Divider(height: 1),
                          ...authors.asMap().entries.map((e) => ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: context.appTheme[50],
                              child: Text(e.value.isNotEmpty ? e.value[0].toUpperCase() : '?',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: context.appTheme[700])),
                            ),
                            title: Text(e.value, style: const TextStyle(fontSize: 13)),
                            trailing: IconButton(
                              icon: Icon(Icons.copy, size: 16, color: Colors.grey[400]),
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: e.value));
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Copied: ${e.value}'),
                                        duration: const Duration(seconds: 2)),
                                  );
                                }
                              },
                            ),
                          )),
                          const SizedBox(height: 16),
                        ],
                      ),
                    );
                  }
                : null,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: context.appTheme[400]),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              if (isDoi) ...[
                const SizedBox(width: 4),
                Icon(Icons.copy, size: 11, color: Colors.grey[400]),
              ],
              if (isAuthors) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 13, color: Colors.grey[400]),
              ],
            ]),
            Text(value, style: const TextStyle(fontSize: 13)),
          ])),
        ]),
      ),
    );
  }
}
