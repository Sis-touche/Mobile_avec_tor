import '../../core/utils/result.dart';
import '../repositories/tor_repository.dart';

class SetTorPort {
  const SetTorPort(this._repository);
  final TorRepository _repository;

  Future<Result<void>> call(int port) => _repository.setPort(port);
}
