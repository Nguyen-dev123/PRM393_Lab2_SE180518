import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/remote_config_service.dart';

class ConfigProvider extends ChangeNotifier {
  MaterialColor get themeColor => RemoteConfigService.themeColor;

  /// Call this when RemoteConfig data has been fetched and activated
  void refresh() {
    notifyListeners();
  }
}

extension AppThemeExt on BuildContext {
  MaterialColor get appTheme => watch<ConfigProvider>().themeColor;
}
