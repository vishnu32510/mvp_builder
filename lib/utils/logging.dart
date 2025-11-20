import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

Logger? _logger;

Logger configureGenUiLogging({Level level = Level.ALL}) {
  Logger.root.level = level;
  Logger.root.onRecord.listen((record) {
    debugPrint(
      '${record.level.name}: ${record.loggerName}: ${record.message}',
    );
    if (record.error != null) {
      debugPrint('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      debugPrint('Stack trace: ${record.stackTrace}');
    }
  });

  _logger = Logger('GenUI');
  
  return _logger!;
}

Logger get logger => _logger ?? Logger('GenUI');

