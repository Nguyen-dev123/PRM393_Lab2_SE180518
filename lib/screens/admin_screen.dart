import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Admin Panel',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.deepPurple[200],
          tabs: const [
            Tab(icon: Icon(Icons.people, size: 18), text: 'Users'),
            Tab(icon: Icon(Icons.bookmark, size: 18), text: 'Bookmarks'),
            Tab(icon: Icon(Icons.trending_up, size: 18), text: 'Report'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UsersTab(),
          _BookmarksTab(),
          _ReportTab(),
        ],
      ),
    );
  }
}

// ── Users Tab ─────────────────────────────────────────────────
class _UsersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text('No users yet',
                  style: TextStyle(color: Colors.grey[500], fontSize: 15)),
            ]),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary card
            Card(
              color: Colors.deepPurple[50],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Icon(Icons.people, color: Colors.deepPurple[600], size: 32),
                  const SizedBox(width: 16),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${docs.length}',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple[700])),
                    Text('Total Users',
                        style: TextStyle(
                            fontSize: 13, color: Colors.deepPurple[400])),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = data['displayName'] ?? 'Unknown';
              final email = data['email'] as String? ?? '${doc.id.substring(0, 12)}…';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple[100],
                    child: Text(
                      (name.isNotEmpty ? name[0] : '?').toUpperCase(),
                      style: TextStyle(
                          color: Colors.deepPurple[700],
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(email,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[600])),
                  trailing: Icon(Icons.circle,
                      size: 10, color: Colors.green[400]),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ── Bookmarks Tab ─────────────────────────────────────────────
class _BookmarksTab extends StatelessWidget {
  Future<List<Map<String, dynamic>>> _getTopBookmarks() async {
    final usersSnap =
        await FirebaseFirestore.instance.collection('users').get();
    final Map<String, int> countMap = {};
    final Map<String, String> titleMap = {};

    for (final userDoc in usersSnap.docs) {
      final bookmarksSnap = await userDoc.reference
          .collection('bookmarks')
          .get();
      for (final bDoc in bookmarksSnap.docs) {
        final data = bDoc.data();
        final id = data['publicationId'] as String? ?? bDoc.id;
        final title = data['title'] as String? ?? 'Unknown';
        countMap[id] = (countMap[id] ?? 0) + 1;
        titleMap[id] = title;
      }
    }

    final sorted = countMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(10).map((e) => {
          'id': e.key,
          'title': titleMap[e.key] ?? 'Unknown',
          'count': e.value,
        }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getTopBookmarks(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Loading bookmark stats...'),
            ]),
          );
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.bookmark_border, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text('No bookmarks yet',
                  style: TextStyle(color: Colors.grey[500], fontSize: 15)),
            ]),
          );
        }
        final maxCount = (items.first['count'] as int).toDouble();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.amber[50],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Icon(Icons.bookmark, color: Colors.amber[700], size: 32),
                  const SizedBox(width: 16),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Top Bookmarked Publications',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[800])),
                    Text('Most saved across all users',
                        style: TextStyle(
                            fontSize: 12, color: Colors.amber[600])),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            ...items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final count = item['count'] as int;
              final ratio = count / maxCount;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: i < 3 ? Colors.amber[100] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text('${i + 1}',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: i < 3
                                    ? Colors.amber[800]
                                    : Colors.grey[600])),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['title'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Row(children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: ratio,
                                    backgroundColor: Colors.grey[100],
                                    valueColor: AlwaysStoppedAnimation(
                                        Colors.amber[400]!),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$count saved',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.amber[700],
                                    fontWeight: FontWeight.bold),
                              ),
                            ]),
                          ]),
                    ),
                  ]),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ── Report Tab ────────────────────────────────────────────────
class _ReportTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('search_topics')
          .orderBy('count', descending: true)
          .limit(10)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.trending_up, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text('No search data yet',
                  style: TextStyle(color: Colors.grey[500], fontSize: 15)),
              const SizedBox(height: 8),
              Text('Search topics will appear here after users search',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[400])),
            ]),
          );
        }

        final maxCount =
            (docs.first.data() as Map<String, dynamic>)['count'] as int? ?? 1;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header card
            Card(
              color: Colors.green[50],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Icon(Icons.trending_up, color: Colors.green[700], size: 32),
                  const SizedBox(width: 16),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Top Search Topics',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800])),
                        Text('Most searched by all users',
                            style: TextStyle(
                                fontSize: 12, color: Colors.green[600])),
                      ]),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            ...docs.asMap().entries.map((entry) {
              final i = entry.key;
              final data = entry.value.data() as Map<String, dynamic>;
              final topic = data['topic'] as String? ?? entry.value.id;
              final count = data['count'] as int? ?? 0;
              final ratio = count / maxCount;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: i < 3 ? Colors.green[100] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text('${i + 1}',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: i < 3
                                    ? Colors.green[800]
                                    : Colors.grey[600])),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(topic,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Row(children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: ratio,
                                    backgroundColor: Colors.grey[100],
                                    valueColor: AlwaysStoppedAnimation(
                                        Colors.green[400]!),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$count searches',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold),
                              ),
                            ]),
                          ]),
                    ),
                  ]),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
