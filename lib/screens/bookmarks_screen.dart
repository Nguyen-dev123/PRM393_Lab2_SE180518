import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/bookmark_viewmodel.dart';
import '../models/bookmark.dart';
import '../state/config_provider.dart';
import 'publication_detail_screen.dart';
import '../models/publication.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bvm = context.watch<BookmarkViewModel?>();
    if (bvm == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Saved Publications',
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: context.appTheme[700],
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Please sign in to view saved publications')),
      );
    }
    final vm = bvm;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Saved Publications',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: context.appTheme[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => vm.load(),
          ),
        ],
      ),
      body: Builder(builder: (ctx) {
        if (vm.isLoading && vm.bookmarks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (vm.errorMessage != null) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.error_outline, color: Colors.red[300], size: 48),
              const SizedBox(height: 12),
              Text(vm.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: vm.load, child: const Text('Retry')),
            ]),
          );
        }
        if (vm.bookmarks.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.bookmark_border, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('No saved publications yet',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text('Tap the bookmark icon on any publication to save it',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[400])),
            ]),
          );
        }

        return RefreshIndicator(
          onRefresh: vm.load,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: vm.bookmarks.length,
            itemBuilder: (ctx, i) =>
                _BookmarkCard(bookmark: vm.bookmarks[i]),
          ),
        );
      }),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final Bookmark bookmark;
  const _BookmarkCard({required this.bookmark});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<BookmarkViewModel>();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Open publication detail
          final pub = Publication(
            id: bookmark.publicationId,
            title: bookmark.title,
            year: bookmark.year,
            citationCount: bookmark.citationCount,
            journalName: bookmark.journalName,
            authors: bookmark.authors,
            doi: bookmark.doi,
            url: bookmark.url,
          );
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => PublicationDetailScreen(pub: pub)));
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.bookmark, color: context.appTheme[600], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(bookmark.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13.5)),
                ),
              ]),
              const SizedBox(height: 8),
              // Stats row
              Wrap(spacing: 12, children: [
                if (bookmark.year != null)
                  _chip(Icons.calendar_today, '${bookmark.year}', Colors.teal),
                _chip(Icons.format_quote, '${bookmark.citationCount}',
                    context.appTheme),
                if (bookmark.journalName != null)
                  _chip(Icons.library_books, bookmark.journalName!,
                      Colors.orange),
              ]),
              // Note
              if (bookmark.note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.appTheme[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Icon(Icons.notes, size: 14, color: context.appTheme[400]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(bookmark.note,
                          style: TextStyle(
                              fontSize: 12, color: context.appTheme[700])),
                    ),
                  ]),
                ),
              ],
              const SizedBox(height: 6),
              // Saved date + actions
              Row(children: [
                Icon(Icons.access_time, size: 12, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  _formatDate(bookmark.savedAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
                const Spacer(),
                // Edit note
                IconButton(
                  icon: Icon(Icons.edit_note,
                      size: 20, color: context.appTheme[400]),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Edit note',
                  onPressed: () => _editNote(context, vm),
                ),
                const SizedBox(width: 12),
                // Delete
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Colors.red),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Remove bookmark',
                  onPressed: () => _confirmDelete(context, vm),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 3),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 120),
        child: Text(text,
            style: TextStyle(fontSize: 11, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ),
    ]);
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _editNote(BuildContext context, BookmarkViewModel vm) async {
    final ctrl = TextEditingController(text: bookmark.note);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Note',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Add a personal note...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Save')),
        ],
      ),
    );
    if (result == null) return;
    try {
      await vm.updateNote(bookmark.publicationId, result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note updated ✓')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update note: $e')));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, BookmarkViewModel vm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Bookmark'),
        content: const Text('Remove this publication from your saved list?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await vm.remove(bookmark.publicationId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bookmark removed')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove: $e')));
      }
    }
  }
}
