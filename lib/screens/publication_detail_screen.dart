import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/publication.dart';

class PublicationDetailScreen extends StatelessWidget {
  final Publication pub;
  const PublicationDetailScreen({super.key, required this.pub});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Publication Details'),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
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
                      _statChip(Icons.format_quote, '${pub.citationCount}', 'Citations', Colors.indigo),
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
                    backgroundColor: Colors.indigo[700],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: Colors.indigo[400]),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          Text(value, style: const TextStyle(fontSize: 13)),
        ])),
      ]),
    );
  }
}
