/// `checking` : test de connexion au proxy Orbot en cours.
/// `connected` : le dernier test a trouvé un service qui répond sur le port.
/// `error` : le dernier test a échoué (Orbot probablement non lancé).
/// `disabled` : l'utilisateur n'a pas activé le routage via Tor.
enum TorConnectionState { disabled, checking, connected, error }

class TorStatus {
  const TorStatus({
    required this.state,
    this.socksPort,
    this.errorMessage,
  });

  final TorConnectionState state;
  final int? socksPort;
  final String? errorMessage;

  static const initial = TorStatus(state: TorConnectionState.disabled);

  TorStatus copyWith({
    TorConnectionState? state,
    int? socksPort,
    String? errorMessage,
  }) {
    return TorStatus(
      state: state ?? this.state,
      socksPort: socksPort ?? this.socksPort,
      errorMessage: errorMessage,
    );
  }
}
