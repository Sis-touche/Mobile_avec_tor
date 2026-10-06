import 'dart:async';

import '../../core/utils/result.dart';
import '../../domain/entities/tor_status.dart';
import '../../domain/repositories/tor_repository.dart';
import '../datasources/network/tor_proxy_client.dart';

class TorRepositoryImpl implements TorRepository {
  TorRepositoryImpl(this._client) {
    unawaited(_hydrate());
  }

  final TorProxyClient _client;

  final _controller = StreamController<TorStatus>.broadcast();
  TorStatus _status = TorStatus.initial;

  @override
  TorStatus get currentStatus => _status;

  @override
  Stream<TorStatus> watchStatus() => _controller.stream;

  void _emit(TorStatus status) {
    _status = status;
    _controller.add(status);
  }

  /// Recharge l'état persistant (port + activé/désactivé) au démarrage de
  /// l'app, et relance un test de connexion si l'utilisateur avait laissé
  /// le routage Tor activé lors de la dernière session.
  Future<void> _hydrate() async {
    final enabled = await _client.isEnabled();
    final port = await _client.getPort();
    _emit(
      TorStatus(
        state: enabled ? TorConnectionState.connected : TorConnectionState.disabled,
        socksPort: port,
      ),
    );
    if (enabled) {
      await checkConnection();
    }
  }

  @override
  Future<Result<TorStatus>> setEnabled(bool enabled) async {
    await _client.setEnabled(enabled);
    if (!enabled) {
      final port = await _client.getPort();
      final status = TorStatus(state: TorConnectionState.disabled, socksPort: port);
      _emit(status);
      return Success(status);
    }
    return checkConnection();
  }

  @override
  Future<Result<TorStatus>> checkConnection() async {
    final port = await _client.getPort();
    _emit(TorStatus(state: TorConnectionState.checking, socksPort: port));
    final ok = await _client.checkPort(port);
    final status = TorStatus(
      state: ok ? TorConnectionState.connected : TorConnectionState.error,
      socksPort: port,
      errorMessage: ok
          ? null
          : "Aucun service ne répond sur le port $port — vérifie qu'Orbot est bien lancé "
              '(mode proxy, pas VPN).',
    );
    _emit(status);
    return Success(status);
  }

  @override
  Future<Result<void>> setPort(int port) async {
    await _client.setPort(port);
    _emit(_status.copyWith(socksPort: port));
    return const Success(null);
  }

  @override
  Future<int> getPort() => _client.getPort();

  void dispose() => _controller.close();
}
