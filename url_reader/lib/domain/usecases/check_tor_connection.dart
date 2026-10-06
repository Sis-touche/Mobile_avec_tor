import '../../core/utils/result.dart';
import '../entities/tor_status.dart';
import '../repositories/tor_repository.dart';

/// Vérifie qu'un service répond sur le port SOCKS5 configuré.
class CheckTorConnection {
  const CheckTorConnection(this._repository);
  final TorRepository _repository;

  Future<Result<TorStatus>> call() => _repository.checkConnection();
}
