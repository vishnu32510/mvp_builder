import 'package:genui/genui.dart';
import 'widget_catalog.dart';

/// Manages GenUI configuration and catalog
class MvpGenUiManager {
  static MvpGenUiManager? _instance;
  late final GenUiManager genUiManager;

  MvpGenUiManager._internal() {
    final catalog = WidgetCatalog.createCatalog();
    genUiManager = GenUiManager(catalog: catalog);
  }

  factory MvpGenUiManager() {
    _instance ??= MvpGenUiManager._internal();
    return _instance!;
  }

  GenUiManager get instance => genUiManager;
}

