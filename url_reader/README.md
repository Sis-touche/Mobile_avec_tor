# URL Reader — App Flutter privée avec navigation Tor

Application mobile Flutter permettant de consulter des URLs en WebView, de sauvegarder des liens dans une base locale, d'ouvrir des fichiers `.epub`, et de router le trafic de navigation via un proxy Tor embarqué afin de masquer le nom de domaine visité à un observateur du réseau local (WiFi).

---

## 1. Objectifs du produit

| # | Fonctionnalité | Statut cible V1 |
|---|---|---|
| 1 | Afficher une URL saisie dans une WebView | Obligatoire |
| 2 | Enregistrer/organiser des liens dans une base locale (titre, url, date, tags) | Obligatoire |
| 3 | Ouvrir et lire des fichiers `.epub` (association d'extension + viewer) | Obligatoire |
| 4 | Router le trafic de la WebView via un proxy Tor local (SOCKS5) pour masquer le domaine au WiFi | Obligatoire, mais isolé comme module activable |
| 5 | Toggle Tor ON/OFF dans les paramètres | Obligatoire |
| 6 | Import/export de la liste de liens | Optionnel V1 |

### Non-objectifs V1
- Pas de synchronisation cloud (tout reste local).
- Pas de compte utilisateur.
- Pas de rendu epub avec pagination avancée type Kindle (V1 = affichage HTML simple, scroll continu).

---

## 2. Contraintes techniques connues (à valider avant tout développement UI)

- **`webview_flutter` officiel ne permet pas de configurer un proxy SOCKS par app.** C'est pourquoi le projet utilise `flutter_inappwebview`, qui expose `ProxyController` sur Android 10+.
- **Le support proxy/Tor sur iOS est nettement plus limité** que sur Android. La V1 doit être conçue Android-first ; iOS peut nécessiter une approche différente (ou être hors scope V1).
- **`flutter_tor` (basé sur Arti, l'implémentation Tor en Rust) est un package jeune**, avec une documentation limitée. Un spike technique (voir §6) doit valider qu'il démarre correctement un proxy SOCKS5 local avant de bâtir le reste de l'architecture dessus.
- Tor introduit une **latence significative** (multi-hop) : l'UX doit prévoir des indicateurs de chargement clairs et un mode "sans Tor" par défaut si l'utilisateur préfère la vitesse.

---

## 3. Architecture générale

Architecture en couches (Clean Architecture allégée), pour isoler le réseau/Tor du reste de l'app et permettre de tester chaque brique indépendamment.

```
lib/
├── main.dart
├── app/
│   ├── app.dart                     # MaterialApp, thème, routes
│   └── router.dart                  # Navigation (go_router recommandé)
│
├── core/
│   ├── constants/
│   ├── errors/                      # Failures, exceptions typées
│   └── utils/
│
├── data/
│   ├── datasources/
│   │   ├── local/
│   │   │   ├── app_database.dart    # Instance Drift
│   │   │   └── tables/              # Définitions des tables Drift
│   │   └── network/
│   │       ├── tor_proxy_client.dart    # Démarrage/gestion du proxy Tor local
│   │       └── http_client_provider.dart # Dio configuré avec/sans proxy
│   ├── models/                      # DTOs / mapping Drift <-> domain
│   └── repositories/                # Implémentations concrètes des repository interfaces
│
├── domain/
│   ├── entities/
│   │   ├── link.dart
│   │   └── epub_file.dart
│   ├── repositories/                # Interfaces abstraites
│   └── usecases/
│       ├── save_link.dart
│       ├── get_links.dart
│       ├── toggle_tor.dart
│       └── open_epub.dart
│
├── presentation/
│   ├── providers/                   # Riverpod providers (state)
│   ├── screens/
│   │   ├── home/                    # Liste des liens sauvegardés
│   │   ├── browser/                 # Écran WebView
│   │   ├── epub_reader/             # Lecteur epub
│   │   └── settings/                # Toggle Tor, gestion stockage
│   └── widgets/                     # Composants réutilisables
│
└── services/
    └── file_association_handler.dart # Réception des intents "ouvrir avec .epub"
```

### Flux de données (exemple : ouverture d'une URL avec Tor activé)

```
UI (browser screen)
  → usecase: LoadUrl
    → repository: BrowserRepository
      → datasource: TorProxyClient (vérifie que le proxy local tourne)
      → datasource: InAppWebViewController.setProxy(proxy: "socks5://127.0.0.1:PORT")
        → WebView charge l'URL via le proxy
```

---

## 4. Stack technique

| Domaine | Choix | Justification |
|---|---|---|
| State management | **Riverpod** | Testable, adapté à un projet avec plusieurs sources async (DB, proxy, fichiers) |
| Navigation | **go_router** | Standard pour la nav déclarative avec deep links (utile pour l'ouverture de fichiers externes) |
| Base de données locale | **Drift** (au-dessus de sqflite) | Requêtes typées, migrations versionnées — préférable à Hive dès qu'il y a des relations (liens/tags) |
| WebView | **flutter_inappwebview** | Seul package avec contrôle du proxy par requête (`ProxyController`) |
| Proxy Tor | **flutter_tor** (Arti) — à valider par spike | Pas d'infra serveur à gérer, réseau décentralisé existant |
| Client HTTP (hors WebView) | **Dio** | Configuration de proxy SOCKS5 simple via `HttpClientAdapter` |
| Parsing epub | **epubx** | Extraction du contenu HTML/XML du epub (qui est un zip structuré) |
| Rendu epub | WebView locale (`loadHtmlString`) à partir du HTML extrait | Évite de dépendre d'un viewer epub tout-fait peu maintenu |
| Tests | `flutter_test`, `mocktail` | Mock des repositories pour tester domain/usecases sans dépendre du proxy réel |

---

## 5. Modèle de données (schéma Drift initial)

```
Table: links
├── id            INTEGER PRIMARY KEY AUTOINCREMENT
├── url           TEXT NOT NULL
├── title         TEXT
├── created_at    DATETIME NOT NULL
├── folder_id     INTEGER NULL (FK → folders.id)
└── opened_via_tor BOOLEAN DEFAULT FALSE

Table: folders
├── id            INTEGER PRIMARY KEY AUTOINCREMENT
└── name          TEXT NOT NULL

Table: epub_files
├── id            INTEGER PRIMARY KEY AUTOINCREMENT
├── file_path     TEXT NOT NULL
├── title         TEXT
├── added_at      DATETIME NOT NULL
└── last_position TEXT NULL   -- pour reprendre la lecture
```

---

## 6. Plan de développement — ordre recommandé

### Phase 0 — Spike technique (à faire AVANT tout le reste)
Objectif : valider le point de risque le plus élevé du projet.
- [ ] Créer un projet Flutter minimal
- [ ] Intégrer `flutter_tor`, démarrer le proxy local
- [ ] Vérifier via `curl` (ou un client HTTP simple dans l'app) que le proxy SOCKS5 répond et que le trafic sort bien via Tor (vérifier l'IP de sortie)
- [ ] **Décision go/no-go** : si le proxy n'est pas stable sur Android, réévaluer (approche alternative : lib native `tor-android`, ou binding Rust maison)

### Phase 1 — Squelette du projet
- [ ] Structure de dossiers (voir §3)
- [ ] `pubspec.yaml` avec dépendances figées
- [ ] Config lint (`analysis_options.yaml`)
- [ ] Riverpod + go_router de base

### Phase 2 — Persistance locale
- [ ] Schéma Drift (§5)
- [ ] Repository `LinkRepository` + usecases (save, get, delete, tag)
- [ ] Tests unitaires du repository (base en mémoire)

### Phase 3 — Réseau (indépendant de la WebView)
- [ ] `TorProxyClient` : démarrage, arrêt, statut du proxy
- [ ] `Dio` configuré pour passer par le proxy quand activé
- [ ] Écran Paramètres : toggle Tor ON/OFF avec indicateur d'état (connecté / en cours / erreur)

### Phase 4 — WebView + proxy
- [ ] Intégration `flutter_inappwebview`
- [ ] `ProxyController.setProxyOverride()` conditionné à l'état du toggle Tor
- [ ] Gestion des erreurs réseau (timeout Tor, proxy indisponible → fallback direct avec avertissement clair à l'utilisateur)
- [ ] Écran Browser : barre d'URL, navigation, bouton "Enregistrer ce lien"

### Phase 5 — Module epub
- [ ] Association d'extension `.epub` (intent filter Android / `CFBundleDocumentTypes` iOS)
- [ ] Réception de l'intent "ouvrir avec" → copie du fichier en local si nécessaire
- [ ] Parsing avec `epubx`, extraction du contenu
- [ ] Écran lecteur : rendu HTML, navigation entre chapitres, sauvegarde de la position de lecture

### Phase 6 — Polish V1
- [ ] Écran d'accueil : liste des liens, recherche, filtres par dossier/tag
- [ ] Gestion des permissions (accès fichiers, stockage)
- [ ] Tests d'intégration des flux critiques (sauvegarde lien, ouverture epub, toggle Tor)
- [ ] Vérification manuelle : sniffer le trafic (Wireshark sur le même WiFi) pour confirmer que le domaine n'apparaît pas en clair quand Tor est actif

---

## 7. Risques identifiés

| Risque | Impact | Mitigation |
|---|---|---|
| `flutter_tor`/Arti instable ou mal maintenu | Bloquant | Spike Phase 0 avant tout engagement sur l'architecture |
| Proxy SOCKS non configurable sur iOS | Réduit le scope iOS | V1 Android-first, iOS en V2 avec approche à redéfinir |
| Latence Tor perçue comme trop lente par l'utilisateur | UX dégradée | Toggle Tor optionnel, indicateurs de progression clairs, mode direct par défaut |
| Rendu epub incomplet (CSS complexe, notes de bas de page) | Qualité de lecture | V1 = rendu HTML simple assumé, amélioration itérative |

---

## 8. Définition de "V1 fonctionnelle"

La V1 est considérée fonctionnelle quand :
1. Un utilisateur peut saisir une URL, la voir s'afficher, et l'enregistrer dans sa liste.
2. Un lien enregistré est persistant après redémarrage de l'app.
3. Un fichier `.epub` ouvert depuis un gestionnaire de fichiers externe s'ouvre dans l'app et son contenu est lisible.
4. Le toggle Tor, quand activé, route effectivement le trafic WebView via le proxy local (vérifié manuellement via sniffing réseau).
5. L'app ne plante pas si le proxy Tor échoue à démarrer (fallback géré proprement).
