import 'dart:io';

enum LogLevel { debug, info, warn, error }

class LogRecord {
  const LogRecord({
    required this.time,
    required this.level,
    required this.message,
    this.tag,
    this.error,
    this.stackTrace,
  });

  final DateTime time;
  final LogLevel level;
  final String message;
  final String? tag;
  final Object? error;
  final StackTrace? stackTrace;

  String format() {
    final buffer = StringBuffer()
      ..write(time.toUtc().toIso8601String())
      ..write(' [${level.name.toUpperCase().padRight(5)}]');
    if (tag != null) {
      buffer.write(' [$tag]');
    }
    buffer.write(' ${redactSensitive(message)}');
    if (error != null) {
      buffer.write(' | ${redactSensitive(error.toString())}');
    }
    if (stackTrace != null) {
      buffer.write('\n${redactSensitive(stackTrace.toString())}');
    }
    return buffer.toString();
  }
}

abstract interface class LogSink {
  void write(LogRecord record);
}

class ConsoleSink implements LogSink {
  const ConsoleSink();

  @override
  void write(LogRecord record) {
    stderr.writeln(record.format());
  }
}

class RotatingFileSink implements LogSink {
  RotatingFileSink({
    required this.directory,
    this.fileName = 'app.log',
    this.maxBytes = 2 * 1024 * 1024,
    this.maxFiles = 5,
  }) : assert(maxBytes > 0),
       assert(maxFiles > 1) {
    directory.createSync(recursive: true);
  }

  final Directory directory;
  final String fileName;
  final int maxBytes;
  final int maxFiles;

  File get currentFile => File(_pathFor(0));

  String _pathFor(int index) {
    final name = index == 0 ? fileName : '$fileName.$index';
    return '${directory.path}${Platform.pathSeparator}$name';
  }

  File _rotatedFile(int index) => File(_pathFor(index));

  @override
  void write(LogRecord record) {
    try {
      final line = '${record.format()}\n';
      if (currentFile.existsSync() && currentFile.lengthSync() + line.length > maxBytes) {
        _rotate();
      }
      currentFile.writeAsStringSync(line, mode: FileMode.append, flush: true);
    } on FileSystemException {
      // Logging must never take down the application.
    }
  }

  void _rotate() {
    final oldest = _rotatedFile(maxFiles - 1);
    if (oldest.existsSync()) {
      oldest.deleteSync();
    }
    for (var index = maxFiles - 2; index >= 1; index--) {
      final source = _rotatedFile(index);
      if (source.existsSync()) {
        source.renameSync(_rotatedFile(index + 1).path);
      }
    }
    if (currentFile.existsSync()) {
      currentFile.renameSync(_rotatedFile(1).path);
    }
  }
}

class Logger {
  Logger({required List<LogSink> sinks, this.level = LogLevel.info, DateTime Function()? clock})
    : _sinks = List.unmodifiable(sinks),
      _clock = clock ?? DateTime.now;

  final List<LogSink> _sinks;
  final DateTime Function() _clock;

  LogLevel level;

  bool isEnabled(LogLevel level) => level.index >= this.level.index;

  void log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!isEnabled(level)) {
      return;
    }
    final record = LogRecord(
      time: _clock(),
      level: level,
      message: message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
    for (final sink in _sinks) {
      try {
        sink.write(record);
      } catch (_) {
        // A broken sink must not break the application or other sinks.
      }
    }
  }

  void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);

  void info(String message, {String? tag, Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.info, message, tag: tag, error: error, stackTrace: stackTrace);

  void warn(String message, {String? tag, Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.warn, message, tag: tag, error: error, stackTrace: stackTrace);

  void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
}

late Logger appLogger;

final List<RegExp> _secretPatterns = [
  RegExp(r'github_pat_[A-Za-z0-9_]{20,}'),
  RegExp(r'gh[pousr]_[A-Za-z0-9]{20,}'),
  RegExp(r'(Bearer)\s+[A-Za-z0-9._~+/=-]+', caseSensitive: false),
  RegExp(r'(token=)[^&\s]+', caseSensitive: false),
  RegExp(r'(authorization:)[^\r\n]+', caseSensitive: false),
];

String redactSensitive(String input) {
  var output = input;
  for (final pattern in _secretPatterns) {
    output = output.replaceAllMapped(pattern, (match) {
      final prefix = match.groupCount > 0 ? match.group(1) : null;
      return prefix == null ? '<redacted>' : '$prefix <redacted>';
    });
  }
  return output;
}
