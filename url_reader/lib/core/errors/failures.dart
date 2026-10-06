/// Représente un échec au niveau du domaine, découplé de l'exception
/// technique sous-jacente (réseau, base de données, système de fichiers…).
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class TorProxyFailure extends Failure {
  const TorProxyFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class EpubParsingFailure extends Failure {
  const EpubParsingFailure(super.message);
}

class FileSystemFailure extends Failure {
  const FileSystemFailure(super.message);
}
