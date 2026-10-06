# Mise en route

Ce dépôt contient le code Dart/Flutter (`lib/`, `test/`) de l'application,
mais **pas** les dossiers natifs `android/` et `ios/` : leur génération
nécessite le SDK Flutter, auquel l'environnement qui a produit ce projet n'a
pas accès (pas de réseau vers pub.dev/storage Flutter). Rien n'a donc pu être
compilé ni exécuté ici — à valider de ton côté avec les étapes ci-dessous.

Bonne nouvelle par rapport aux versions précédentes de ce document : plus
aucune dépendance native lourde n'est nécessaire (pas de Rust, pas de NDK
côté Tor, pas de Perl, pas de MSYS2, pas de `make`). Voir
`docs/notes_readme.md` §2 pour le contexte — le Tor embarqué a été
remplacé par une intégration avec **Orbot** (app séparée, installée par
l'utilisateur — voir `docs/orbot_setup.md`).

## 1. Générer le squelette natif

Dans un dossier vide :

```bash
flutter create --org com.example --project-name url_reader .
```

(remplace `com.example` par ton propre identifiant d'organisation si tu veux
un `applicationId` différent — dans ce cas, adapte aussi le `package` en tête
de `android_patch/MainActivity.kt`).

## 2. Copier le code de ce projet par-dessus

Copie par-dessus les fichiers générés :
- `lib/` (remplace entièrement le `lib/main.dart` par défaut)
- `test/`
- `pubspec.yaml`
- `analysis_options.yaml`

⚠️ **Supprime `test/widget_test.dart`** (le fichier d'exemple généré par
`flutter create`) au lieu de le laisser à côté du dossier `test/` fourni ici
— il importe `package:<nom_du_projet_flutter_create>/main.dart` et
référence une classe `MyApp` qui n'existent plus une fois `lib/main.dart`
remplacé, ce qui casse l'analyse avec des erreurs sans rapport avec le reste
du projet.

## 3. Appliquer le patch Android (association de fichiers `.epub`)

Suis `android_patch/README_PATCH.md` (permission Internet + intent-filters
`.epub` + `MainActivity.kt`). Sans rapport avec Tor/Orbot — uniquement pour
la Phase 5 (ouvrir un epub depuis un gestionnaire de fichiers externe).

## 4. Installer les dépendances Dart et générer le code Drift

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Si tu obtiens `'dart compile' does not support build hooks, use 'dart build'
instead` : ajoute `--force-jit` à la commande ci-dessus
(`dart run build_runner build --force-jit --delete-conflicting-outputs`).
C'est un problème d'outillage Dart connu (une dépendance transitive de
Drift/sqlite3 utilise le nouveau système de « build hooks »), pas un bug de
ce projet — voir https://github.com/simolus3/drift/discussions/3791.

La génération Drift produit `lib/data/datasources/local/app_database.g.dart`
à partir des tables définies dans `lib/data/datasources/local/tables/` — le
projet ne compile pas sans cette étape.

## 5. Configurer Tor (Orbot)

Suis `docs/orbot_setup.md` — installation d'Orbot, configuration du port
SOCKS5 dans l'écran Paramètres de l'app. Aucune compilation requise pour
cette étape, juste de la configuration.

## 6. Lancer l'app

```bash
flutter run
```

Build Flutter standard — pas de compilation native supplémentaire, donc pas
de temps de build inhabituel au-delà de ce qu'un projet Flutter avec
plusieurs plugins (Drift, WebView, file_picker) demande normalement.

## Ce qui est déjà implémenté

| Couche | Contenu |
|---|---|
| Domain | Entités (`Link`, `Folder`, `EpubFile`, `TorStatus`, `BrowserTab`), interfaces de repository, use cases (save/get/delete link, toggle/check Tor, open epub, save reading position, create folder) |
| Data | Schéma Drift (3 tables + colonnes couverture/nb de chapitres), `AppDatabase` avec requêtes + `watch()` réactif, mappers, implémentations des 4 repositories, `TorProxyClient` (config Orbot), client Dio+SOCKS5, extraction de couverture epub |
| Presentation | Providers Riverpod (dont gestion d'onglets navigateur en mémoire), écrans **Splash**, **Accueil** (carte statut Tor, barre URL, liens récents, stats de stockage réelles), **Tableau de bord de lecture**, **Bibliothèque epub** (grille avec couvertures), **Lecteur epub** (position de lecture persistée), **Navigateur multi-onglets** (page de démarrage, gestionnaire d'onglets, bannières Tor), **Explication du mode Tor**, **Paramètres** (config port Orbot + vérif. IP de sortie — pas encore restylé au thème anthracite) |
| Natif | Patch Android pour l'association `.epub` (`MainActivity.kt` + intent-filters) |
| Tests | Un test de repository sur base Drift en mémoire (`test/data/repositories/link_repository_impl_test.dart`), à prendre comme modèle pour les autres |

## Ce qu'il reste à faire (au-delà de ce point de départ)

- **Écran Paramètres** : fonctionnel mais pas encore restylé au thème
  anthracite des autres écrans (reste sur le thème Material3 par défaut).
- **Favoris / Dossiers / Fichiers** (pills de filtre sur l'écran Accueil) :
  visuels mais non fonctionnels ("Bientôt disponible") — voir
  `docs/notes_readme.md` §3.
- **Décider du sort des tags** — voir `docs/notes_readme.md` §1.
- Persistance des onglets navigateur entre redémarrages complets de l'app
  (actuellement en mémoire uniquement — voir `docs/notes_readme.md` §3).
- Recherche/filtres avancés sur l'écran d'accueil (Phase 6 du README
  d'origine).
- Import/export de la liste de liens (marqué optionnel V1 dans le README).
- iOS : le contrôle de proxy par WebView (`ProxyController`/
  `PROXY_OVERRIDE`) est une API Android uniquement — hors scope V1 comme
  prévu par le README d'origine.

## Point d'attention sur les versions de packages

Les contraintes de version dans `pubspec.yaml` reflètent ce que je connais
des packages au moment de la rédaction, mais je n'ai pas pu les résoudre
contre pub.dev depuis cet environnement. Lance `flutter pub outdated` après
`flutter pub get` pour vérifier qu'il n'y a pas de version plus récente ou de
conflit à corriger.
