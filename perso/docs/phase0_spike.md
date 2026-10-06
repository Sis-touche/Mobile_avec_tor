# Phase 0 — Spike technique Tor (à faire avant tout le reste)

## Mise à jour importante

Le README d'origine citait un package `flutter_tor`. En vérifiant sur
pub.dev, le seul package portant ce nom est **iOS/macOS uniquement** — donc
inutilisable pour le besoin Android-first de ce projet. Le package réel
utilisé ici est **`tor` (verified publisher `foundationdevices.com`, basé
sur Arti, multi-plateforme dont Android)** — voir `pubspec.yaml`. Son API a
été vérifiée contre l'exemple officiel du package (version 0.1.1) et
`lib/data/datasources/network/tor_proxy_client.dart` a été réécrit contre
cette API confirmée : `Tor.init()`, `Tor.instance.start()/.stop()`,
`Tor.instance.started`, `Tor.instance.port`.

Point non négociable pour ce package : il compile un binaire **Rust** via
Cargokit au moment du build. Sans le toolchain suivant installé, `flutter
run`/`flutter build` échoueront au moment de compiler la dépendance native —
pas au moment de `flutter pub get`.

## Prérequis toolchain (avant `flutter run`)

1. **Rust** — installer via [rustup](https://rustup.rs/) (pas via un
   gestionnaire de paquets système type Homebrew/apt, la doc du package le
   déconseille explicitement).
2. **cargo-ndk** (nécessaire pour compiler vers Android) :
   ```bash
   cargo install cargo-ndk
   ```
3. Le NDK Android doit être installé (normalement déjà le cas si tu as un
   environnement Flutter Android fonctionnel via Android Studio).

## Étapes du spike

1. **Installer les dépendances**
   ```bash
   flutter pub get
   ```
2. **Lancer l'app sur un appareil/émulateur Android 10+**
   ```bash
   flutter run
   ```
   La première compilation sera plus longue que d'habitude (compilation
   Rust via Cargokit).
3. **Activer Tor depuis l'écran Paramètres**, attendre l'état "Connecté" (ou
   l'erreur affichée si le démarrage échoue ou dépasse le délai de 45s fixé
   dans `TorProxyClient.start()`).
4. **Utiliser le bouton "Vérifier l'IP de sortie"** (aussi dans Paramètres) :
   il fait un appel HTTP via `dio` + `socks5_proxy` routé sur le port SOCKS5
   local (`Tor.instance.port`), vers `https://api.ipify.org`. Compare l'IP
   affichée à celle de ta connexion WiFi habituelle (par ex. via
   https://whatismyip.com sur un autre appareil du même réseau) : elle doit
   être différente si Tor fonctionne.
5. **Vérifier la navigation elle-même** : ouvre une URL depuis l'écran
   Navigateur pendant que Tor est actif, et si possible, capture le trafic
   WiFi (Wireshark, ou l'outil réseau d'un routeur) pour confirmer que le
   nom de domaine visité n'apparaît pas en clair.

## Décision go/no-go

- **Go** : le proxy démarre de façon fiable en quelques dizaines de secondes,
  le port SOCKS5 répond, l'IP de sortie change bien. → Continuer sur les
  phases suivantes telles quelles.
- **No-go** : proxy instable, crashe, build Rust qui échoue de façon non
  résolvable sur ta configuration. → Réévaluer une alternative (binding
  natif `tor-android` séparé, ou un processus Tor externe piloté en
  subprocess), en gardant `TorProxyClient` comme unique point de contact à
  réécrire — le reste de l'architecture (repository, use case, écrans) n'a
  pas à changer.
