# Configurer Tor via Orbot

Cette app ne fait pas tourner Tor elle-même : elle se connecte au proxy local
exposé par **Orbot**, l'app officielle du Tor Project pour Android. Ce choix
est délibéré (voir `docs/notes_readme.md`) : le README d'origine prévoyait un
Tor embarqué directement dans l'app, abandonné après un bug de compilation
croisée Windows→Android non résolu en amont sur `openssl-sys`/Cargokit.

## Pourquoi une configuration manuelle plutôt qu'automatique

Une ancienne API "Intent" permettait à une app tierce de démarrer Orbot et de
détecter son port automatiquement. Elle s'est cassée entre versions d'Orbot
par le passé (voir
[github.com/guardianproject/orbot-android/issues/638](https://github.com/guardianproject/orbot-android/issues/638))
et n'est pas fiable à long terme. La configuration manuelle du port, elle, ne
peut pas casser — c'est la méthode que suivent des apps activement
maintenues comme RethinkDNS pour s'intégrer à Orbot.

## Étapes (côté utilisateur de l'app)

1. Installer **Orbot** — Play Store ou F-Droid (bouton dédié dans l'écran
   Paramètres de cette app).
2. Ouvrir Orbot et le démarrer en **mode proxy standard** ("Power User
   Mode"), **pas** en mode VPN — le mode VPN route tout le trafic du
   téléphone via un tunnel système et n'expose pas un port SOCKS5 local
   utilisable par une autre app de la même façon.
3. Noter le port **SOCKS5** affiché sur l'écran d'accueil d'Orbot (9050 par
   défaut, configurable dans les réglages d'Orbot).
4. Dans cette app, écran Paramètres : renseigner ce port, appuyer sur
   "Enregistrer et vérifier". Si Orbot est bien lancé, le statut passe à
   "Orbot détecté sur le port XXXX".
5. Activer le switch "Utiliser Tor pour la navigation".
6. Optionnel mais recommandé : bouton "Vérifier l'IP de sortie" (dans le
   même écran) — fait un vrai appel HTTP à travers le port configuré et
   affiche l'IP visible depuis Internet. Elle doit différer de l'IP WiFi
   habituelle si le routage fonctionne réellement (le test de port de
   l'étape 4 confirme seulement qu'*un* service répond sur ce port, pas que
   c'est un proxy SOCKS5 qui fonctionne).

## Limite connue

Si Orbot change son port par défaut ou si l'utilisateur le modifie dans
Orbot sans le reporter ici, la vérification échouera avec un message clair
("Aucun service ne répond sur le port XXXX") plutôt qu'un échec silencieux —
comportement voulu (voir `_saveAndCheck`/`checkConnection` dans le code).
