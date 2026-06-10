import 'package:shared_preferences/shared_preferences.dart';

class HistoryService {
  static const _key = 'search_history';
  static const _maxItems = 10;

  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> add(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.remove(query);
    list.insert(0, query);
    if (list.length > _maxItems) list.removeLast();
    await prefs.setStringList(_key, list);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
