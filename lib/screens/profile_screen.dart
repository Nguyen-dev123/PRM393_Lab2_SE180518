import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../services/pdf_export_service.dart';
import '../services/push_notification_service.dart';
import '../services/remote_config_service.dart';
import '../state/search_provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../state/config_provider.dart';
import 'admin_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    PushNotificationService.addListener(_onNotification);
  }

  @override
  void dispose() {
    PushNotificationService.removeListener(_onNotification);
    _tabController.dispose();
    super.dispose();
  }

  void _onNotification() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final unread = PushNotificationService.unreadCount;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: context.appTheme[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: context.appTheme[200],
          tabs: [
            const Tab(icon: Icon(Icons.person_outline, size: 18), text: 'Account'),
            Tab(
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.notifications_outlined, size: 18),
              ),
              text: 'Notifications',
            ),
            const Tab(icon: Icon(Icons.settings_outlined, size: 18), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AccountTab(),
          _NotificationTab(),
          _SettingsTab(),
        ],
      ),
    );
  }
}

// ── Account Tab ───────────────────────────────────────────────
class _AccountTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, auth, _) {
        final user = auth.user;
        if (user == null) return const Center(child: Text('Not signed in'));
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Column(children: [
                CircleAvatar(
                  radius: 44,
                  backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                  backgroundColor: context.appTheme[100],
                  child: user.photoURL == null
                      ? Text((user.displayName ?? 'U')[0].toUpperCase(),
                          style: TextStyle(fontSize: 36, color: context.appTheme[700], fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(height: 14),
                Text(user.displayName ?? 'No Name',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(user.email ?? '', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ]),
            ),
            const SizedBox(height: 28),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 1,
              child: Column(children: [
                _infoTile(context, Icons.person, 'Display Name', user.displayName ?? '—', context.appTheme,
                    onTap: () => _editDisplayName(context, auth, user.displayName ?? '')),
                const Divider(height: 1, indent: 56),
                _infoTile(context, Icons.email_outlined, 'Email', user.email ?? '—', Colors.teal),
                const Divider(height: 1, indent: 56),
                _infoTile(context, Icons.verified_user_outlined, 'UID', '${user.uid.substring(0, 12)}…', Colors.orange),
              ]),
            ),
            const SizedBox(height: 24),
            // Admin Panel button — only visible to admin account
            if (user.email?.endsWith('@fpt.edu.vn') == true ||
                user.email?.endsWith('@gmail.com') == true) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminScreen()),
                  ),
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Admin Panel',
                      style: TextStyle(fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async => auth.signOut(),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Sign Out', style: TextStyle(color: Colors.red, fontSize: 15)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _infoTile(BuildContext ctx, IconData icon, String label, String value, Color color, {VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      subtitle: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      trailing: onTap != null ? Icon(Icons.edit, size: 16, color: Colors.grey[400]) : null,
      onTap: onTap ?? () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('$label copied'), duration: const Duration(seconds: 2)),
        );
      },
    );
  }

  void _editDisplayName(BuildContext context, AuthViewModel auth, String current) {
    final ctrl = TextEditingController(text: current);
    String? error;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Display Name', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: ctrl,
            maxLength: 50,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              border: const OutlineInputBorder(),
              errorText: error,
            ),
            onChanged: (_) => setS(() => error = null),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = ctrl.text.trim();
                if (name.isEmpty || name.length > 50) {
                  setS(() => error = 'Name must be 1–50 characters');
                  return;
                }
                Navigator.pop(ctx);
                await auth.updateDisplayName(name);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Display name updated ✓')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Notification Tab ──────────────────────────────────────────
class _NotificationTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final notifications = PushNotificationService.notifications;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: notifications.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No notifications yet', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                const SizedBox(height: 8),
                Text('Notifications from Firebase Cloud Messaging\nwill appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ]),
            )
          : Column(children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [
                  Text('${notifications.length} notifications',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => PushNotificationService.markAllRead(),
                    child: const Text('Mark all read', style: TextStyle(fontSize: 12)),
                  ),
                ]),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                  itemBuilder: (ctx, i) {
                    final n = notifications[i];
                    return ListTile(
                      leading: Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: n.isRead ? Colors.grey[100] : context.appTheme[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.notifications,
                            color: n.isRead ? Colors.grey[400] : context.appTheme[600], size: 20),
                      ),
                      title: Text(n.title,
                          style: TextStyle(
                              fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 14)),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(n.body,
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(height: 2),
                        Text(_formatTime(n.receivedAt),
                            style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                      ]),
                      isThreeLine: true,
                      onTap: () {
                        n.markRead();
                        // Force UI refresh to update the bold text immediately
                        if (context.mounted) {
                          (context as Element).markNeedsBuild();
                        }
                        
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Row(
                              children: [
                                Icon(Icons.notifications_active, color: context.appTheme[600]),
                                const SizedBox(width: 8),
                                Expanded(child: Text(n.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.body, style: const TextStyle(fontSize: 14, height: 1.5)),
                                const SizedBox(height: 16),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(_formatTime(n.receivedAt), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Đóng'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ]),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ── Settings Tab ──────────────────────────────────────────────
class _SettingsTab extends StatefulWidget {
  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  bool _exporting = false;
  bool _refreshingConfig = false;
  int _configVersion = 0; // incremented on each refresh to force rebuild

  static const _configDesc = {
    'welcome_message': 'The greeting message shown in the app.\nChange it in Firebase Console → Remote Config.',
    'app_theme_color': 'Controls the primary color scheme.\nValues: indigo, blue, teal, green, red, purple, orange.',
    'max_journals': 'Maximum number of journals shown in analytics tabs.',
    'max_keywords': 'Maximum number of keywords extracted from publication titles.',
  };

  Future<void> _refreshRemoteConfig() async {
    setState(() => _refreshingConfig = true);
    try {
      await FirebaseRemoteConfig.instance.fetchAndActivate();
      if (mounted) {
        // Force the app to rebuild with the new theme
        context.read<ConfigProvider>().refresh();
        
        setState(() {
          _refreshingConfig = false;
          _configVersion++;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Remote Config refreshed ✓'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _refreshingConfig = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Refresh failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showConfigDetail(String key, String value) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(key,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: context.appTheme[50], borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(Icons.circle, color: Colors.green[600], size: 10),
              const SizedBox(width: 8),
              Expanded(child: Text('Current value: $value',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
            ]),
          ),
          const SizedBox(height: 12),
          Text(_configDesc[key] ?? 'Firebase Remote Config parameter.',
              style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showResultsSheet(SearchProvider provider) {
    if (provider.results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No results yet. Search a topic on Home tab.')));
      return;
    }
    final top5 = provider.results.take(5).toList();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            Icon(Icons.article_outlined, color: Colors.teal[600], size: 20),
            const SizedBox(width: 8),
            Text('Top ${top5.length} Results for "${provider.query}"',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
        ),
        const Divider(height: 1),
        ...top5.map((pub) => ListTile(
          dense: true,
          leading: Icon(Icons.article, color: context.appTheme[300], size: 18),
          title: Text(pub.title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          subtitle: Text('${pub.citationCount} citations • ${pub.year ?? "N/A"}',
              style: TextStyle(fontSize: 11, color: context.appTheme[400])),
        )),
        const SizedBox(height: 12),
      ]),
    );
  }

  void _showDatasetStats(SearchProvider provider) {
    if (provider.allPubs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(provider.isFetchingAll ? 'Dataset is still loading…' : 'No dataset yet.')));
      return;
    }
    final pubs = provider.allPubs;
    final years = pubs.where((p) => p.year != null).map((p) => p.year!).toList();
    final minYear = years.isEmpty ? 0 : years.reduce((a, b) => a < b ? a : b);
    final maxYear = years.isEmpty ? 0 : years.reduce((a, b) => a > b ? a : b);
    final totalCitations = pubs.fold(0, (s, p) => s + p.citationCount);
    final mostCited = pubs.reduce((a, b) => a.citationCount > b.citationCount ? a : b);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.dataset_outlined, color: Colors.orange[600], size: 20),
          const SizedBox(width: 8),
          const Text('Analytics Dataset', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _statRow('Total publications', '${pubs.length}', context.appTheme),
          _statRow('Year range', '$minYear – $maxYear', Colors.teal),
          _statRow('Total citations', '$totalCitations', Colors.orange),
          _statRow('Avg citations/pub', (totalCitations / pubs.length).toStringAsFixed(1), Colors.purple),
          const Divider(height: 16),
          Align(alignment: Alignment.centerLeft,
              child: Text('Most cited:', style: TextStyle(fontSize: 11, color: Colors.grey[500]))),
          const SizedBox(height: 4),
          Text(mostCited.title, maxLines: 3, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Text('${mostCited.citationCount} citations',
              style: TextStyle(fontSize: 11, color: context.appTheme[400])),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  void _showHistorySheet(SearchProvider provider) {
    if (provider.history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No search history yet.')));
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            Icon(Icons.history, color: Colors.purple[600], size: 20),
            const SizedBox(width: 8),
            const Text('Search History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Spacer(),
            TextButton(
              onPressed: () {
                provider.clearHistory();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('History cleared')));
              },
              child: const Text('Clear All', style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
          ]),
        ),
        const Divider(height: 1),
        ...provider.history.map((h) => ListTile(
          leading: const Icon(Icons.history, color: Colors.grey, size: 18),
          title: Text(h, style: const TextStyle(fontSize: 14)),
          trailing: const Icon(Icons.north_west, color: Colors.grey, size: 16),
          onTap: () {
            Navigator.pop(ctx);
            provider.search(h);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Searching "$h"… Switch to Home tab'),
                duration: const Duration(seconds: 3)));
          },
        )),
        const SizedBox(height: 16),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Remote Config ──────────────────────────────────────
        Row(children: [
          _sectionLabel('Remote Config'),
          const Spacer(),
          _refreshingConfig
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : TextButton.icon(
                  onPressed: _refreshRemoteConfig,
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      foregroundColor: context.appTheme[600]),
                ),
        ]),
        const SizedBox(height: 8),
        Card(
          key: ValueKey(_configVersion),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1,
          child: Column(children: [
            _configTile(icon: Icons.message_outlined, color: context.appTheme,
                configKey: 'welcome_message', value: RemoteConfigService.welcomeMessage),
            const Divider(height: 1, indent: 56),
            _configTile(icon: Icons.color_lens_outlined, color: Colors.purple,
                configKey: 'app_theme_color', value: RemoteConfigService.themeColorName),
            const Divider(height: 1, indent: 56),
            _configTile(icon: Icons.library_books_outlined, color: Colors.teal,
                configKey: 'max_journals', value: '${RemoteConfigService.maxJournals}'),
            const Divider(height: 1, indent: 56),
            _configTile(icon: Icons.tag, color: Colors.orange,
                configKey: 'max_keywords', value: '${RemoteConfigService.maxKeywords}'),
          ]),
        ),
        const SizedBox(height: 20),

        // ── Report Export ──────────────────────────────────────
        _sectionLabel('Report Export'),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1,
          child: ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.picture_as_pdf, color: Colors.red[600], size: 18),
            ),
            title: const Text('Export PDF Report',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: const Text('Generate analytics PDF → upload to Firebase Storage',
                style: TextStyle(fontSize: 11)),
            trailing: _exporting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: _exporting ? null : _exportPdf,
          ),
        ),
        const SizedBox(height: 20),

        // ── Crashlytics Demo ───────────────────────────────────
        _sectionLabel('Crashlytics Demo'),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1,
          child: Column(children: [
            ListTile(
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.warning_amber_outlined, color: Colors.orange[700], size: 18),
              ),
              title: const Text('Log Handled Exception',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: const Text('Records a caught error to Crashlytics without crashing',
                  style: TextStyle(fontSize: 11)),
              onTap: _logHandledException,
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.bug_report_outlined, color: Colors.red[700], size: 18),
              ),
              title: const Text('Force Test Crash',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: const Text('Triggers a forced crash to test Crashlytics reporting',
                  style: TextStyle(fontSize: 11)),
              onTap: _confirmCrash,
            ),
          ]),
        ),
        const SizedBox(height: 20),

        // ── Search Activity ────────────────────────────────────
        _sectionLabel('Search Activity'),
        const SizedBox(height: 8),
        Consumer<SearchProvider>(
          builder: (ctx, provider, _) => Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 1,
            child: Column(children: [
              ListTile(
                leading: _activityIcon(Icons.search, context.appTheme),
                title: Text('Last Topic', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                subtitle: Text(provider.query.isNotEmpty ? '"${provider.query}"' : '—',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                trailing: provider.query.isNotEmpty
                    ? Icon(Icons.replay, color: context.appTheme[400], size: 18)
                    : null,
                onTap: provider.query.isNotEmpty
                    ? () {
                        provider.search(provider.query);
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text('Re-searching "${provider.query}"… Go to Home tab'),
                            duration: const Duration(seconds: 3)));
                      }
                    : null,
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: _activityIcon(Icons.article_outlined, Colors.teal),
                title: Text('Results Loaded', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                subtitle: Text(
                    provider.results.isNotEmpty ? '${provider.results.length} publications' : '—',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                trailing: provider.results.isNotEmpty
                    ? Icon(Icons.chevron_right, color: Colors.teal[400], size: 18)
                    : null,
                onTap: () => _showResultsSheet(provider),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: _activityIcon(Icons.dataset_outlined, Colors.orange),
                title: Text('Analytics Dataset', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                subtitle: Text(
                    provider.allPubs.isNotEmpty
                        ? '${provider.allPubs.length} publications'
                        : provider.isFetchingAll ? 'Fetching…' : '—',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                trailing: provider.allPubs.isNotEmpty
                    ? Icon(Icons.info_outline, color: Colors.orange[400], size: 18)
                    : null,
                onTap: () => _showDatasetStats(provider),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: _activityIcon(Icons.history, Colors.purple),
                title: Text('Search History', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                subtitle: Text(
                    provider.history.isNotEmpty
                        ? '${provider.history.length} recent searches'
                        : 'No history yet',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                trailing: provider.history.isNotEmpty
                    ? Icon(Icons.chevron_right, color: Colors.purple[400], size: 18)
                    : null,
                onTap: () => _showHistorySheet(provider),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(label.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                color: Colors.grey[500], letterSpacing: 1.1)),
      );

  Widget _activityIcon(IconData icon, Color color) => Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      );

  Widget _configTile({
    required IconData icon,
    required Color color,
    required String configKey,
    required String value,
  }) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(configKey,
          style: TextStyle(fontSize: 11, color: Colors.grey[500], fontFamily: 'monospace')),
      subtitle: Text(value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.info_outline, size: 16, color: Colors.grey[400]),
      onTap: () => _showConfigDetail(configKey, value),
    );
  }

  Future<void> _exportPdf() async {
    final provider = context.read<SearchProvider>();
    if (provider.query.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('No data to export'),
          content: const Text('Please search a topic on the Home tab first.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      return;
    }
    setState(() => _exporting = true);
    final uid = context.read<AuthViewModel>().user?.uid ?? 'anonymous';
    final url = await PdfExportService.exportAndUploadPdf(
        provider.query, provider.allPubs.length, uid);
    if (!mounted) return;
    setState(() => _exporting = false);
    if (url != null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 22),
            const SizedBox(width: 8),
            const Text('PDF Uploaded!', style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Topic: "${provider.query}"',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 12),
            const Text('Firebase Storage URL:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: SelectableText(url, style: const TextStyle(fontSize: 11)),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ElevatedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: url));
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('URL copied to clipboard ✓'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2)));
                }
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy URL'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: context.appTheme[700], foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Export failed. Check Firebase Storage rules.'),
          backgroundColor: Colors.red));
    }
  }

  void _logHandledException() {
    try {
      throw Exception('Handled exception demo — PRM393 Lab 03');
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack,
          reason: 'Handled exception triggered from Profile screen', fatal: false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Handled exception logged to Crashlytics ✓'),
          backgroundColor: Colors.orange));
    }
  }

  void _confirmCrash() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Force Crash'),
        content: const Text(
            'This will crash the app to test Crashlytics reporting.\n\nReopen the app after the crash to see the report uploaded.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              FirebaseCrashlytics.instance.crash();
            },
            child: const Text('Crash Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

