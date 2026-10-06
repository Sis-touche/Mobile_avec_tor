# Notes sur le README d'origine

## 1. Tags mentionnés en §1 mais absents du schéma §5

L'objectif produit #2 du README dit : « Enregistrer/organiser des liens dans
une base locale (**titre, url, date, tags**) », mais le schéma Drift de la
§5 ne définit que `folder_id` (une seule catégorie par lien), sans table
`tags`. Un lien ne peut donc, tel que spécifié, appartenir qu'à **un seul**
dossier — pas à plusieurs tags.

Ce projet reprend le schéma tel qu'écrit en §5 (dossiers uniquement) pour la
V1, car c'est la source la plus précise (structure de données explicite vs.
mention en une ligne dans un tableau d'objectifs). Si un système de tags
multi-valués est réellement voulu, il faudra ajouter :

```
Table: tags
├── id     INTEGER PRIMARY KEY AUTOINCREMENT
└── name   TEXT NOT NULL

Table: link_tags (association many-to-many)
├── link_id  INTEGER NOT NULL (FK → links.id)
└── tag_id   INTEGER NOT NULL (FK → tags.id)
```

et une migration de schéma (schemaVersion 2) plutôt que de la modéliser dans
`schemaVersion 1`, pour ne pas devoir migrer une base déjà installée en V1.

## 2. Tor embarqué (`flutter_tor`/`tor`) abandonné au profit d'Orbot

Le README d'origine (§4, §6) prévoyait un Tor embarqué via `flutter_tor`,
qui n'existe pas pour Android sur pub.dev. Le remplacement identifié, `tor`
(foundationdevices.com, basé sur Arti), a été intégré et a progressé loin
dans la chaîne de build (Rust, cargo-ndk, NDK, Perl, MSYS2, make tous
installés avec succès), avant de buter sur un bug de compilation croisée
Windows→Android non résolu en amont : `openssl-sys` (vendored) invoqué via
`make`/`/bin/sh` sur Windows corrompt les chemins Windows du compilateur
NDK (les `\` sont interprétés comme des caractères d'échappement par le
shell POSIX de MSYS2). Deux tickets GitHub ouverts sur le dépôt officiel de
`rust-openssl` documentent exactement ce scénario, sans solution confirmée
dans les discussions (issues #2195 et #2352).

**Décision** : abandon du Tor embarqué au profit d'une intégration avec
**Orbot**, l'app officielle du Tor Project pour Android, installée
séparément par l'utilisateur — voir `docs/orbot_setup.md`. Conséquences :

- Plus aucune dépendance native (Rust, NDK côté Tor, Perl, MSYS2, make) :
  `flutter run` redevient un build Flutter standard.
- L'app dépend désormais d'Orbot étant installé et lancé manuellement par
  l'utilisateur, plutôt que d'être un unique APK autonome comme visé
  initialement par le README. Compromis assumé après plusieurs jours de
  blocages de compilation sans issue garantie sur la voie embarquée.
- Seuls `TorProxyClient` (datasources/network) et `TorRepositoryImpl`
  (repositories) ont été réécrits ; le reste de l'architecture — domain,
  écrans, base de données, epub — n'a pas changé, ce qui confirme l'intérêt
  d'avoir isolé `TorRepository` comme interface dès le départ.
