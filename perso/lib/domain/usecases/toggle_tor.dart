import '../../core/utils/result.dart';
import '../entities/tor_status.dart';
import '../repositories/tor_repository.dart';

/// Active/désactive le routage de la WebView via le proxy Orbot configuré.
/// Ne démarre rien : Orbot doit déjà tourner séparément (voir
/// docs/orbot_setup.md). Déclenche un test de connexion à l'activation.
class ToggleTor {
  const ToggleTor(this._repository);
  final TorRepository _repository;

  Future<Result<TorStatus>> call(bool enable) => _repository.setEnabled(enable);
}
