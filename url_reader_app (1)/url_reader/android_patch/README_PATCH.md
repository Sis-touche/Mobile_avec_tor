# Comment appliquer ces fichiers

Ce dossier n'est **pas** un dossier `android/` complet : je n'ai pas pu
exécuter `flutter create` dans mon environnement d'exécution (pas d'accès à
pub.dev / au SDK Flutter depuis ce sandbox), donc je ne peux pas générer les
projets natifs Android/iOS complets moi-même.

Une fois que tu as toi-même lancé `flutter create` (voir `SETUP.md` à la
racine du projet) :

1. Ouvre `android/app/src/main/AndroidManifest.xml` et ajoute-y le contenu de
   `AndroidManifest_additions.xml` aux emplacements indiqués en commentaire.
2. Repère `android/app/src/main/kotlin/<ton_package>/MainActivity.kt` et
   remplace son contenu par celui de `MainActivity.kt` — en adaptant la ligne
   `package com.example.url_reader` pour qu'elle corresponde exactement à ton
   `applicationId` (visible dans `android/app/build.gradle`).
