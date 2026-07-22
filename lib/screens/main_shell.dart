import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'journal_screen.dart';
import 'keywords_screen.dart';
import 'profile_screen.dart';
import 'bookmarks_screen.dart';
import 'package:provider/provider.dart';
import '../state/config_provider.dart';

/// Main shell with 4-tab bottom navigation:
/// Home → Search Topic + Recent Searches
/// Journal → Publications + Details
/// Keywords → Trends + Authors + Journals
/// Profile → Settings / About
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          HomeScreen(),
          JournalScreen(),
          KeywordsScreen(),
          const BookmarksScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        indicatorColor: context.appTheme[100],
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: context.appTheme),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books, color: context.appTheme),
            label: 'Journal',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights, color: context.appTheme),
            label: 'Keywords',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark, color: context.appTheme),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: context.appTheme),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
