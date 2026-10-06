class DatabaseException implements Exception {
  DatabaseException(this.message);
  final String message;
  @override
  String toString() => 'DatabaseException: $message';
}

class TorProxyException implements Exception {
  TorProxyException(this.message);
  final String message;
  @override
  String toString() => 'TorProxyException: $message';
}

class EpubParsingException implements Exception {
  EpubParsingException(this.message);
  final String message;
  @override
  String toString() => 'EpubParsingException: $message';
}
