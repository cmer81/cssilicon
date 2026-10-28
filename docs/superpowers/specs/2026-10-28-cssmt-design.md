# cssmt — Counter-Strike: Source sur Mac Apple Silicon (fork de tf2mt)

Date : 2026-10-28 · Statut : validé ; **avenant du 2026-10-28 (soir) ci-dessous, prioritaire sur le reste**

## Avenant — projet public (décision du propriétaire, 2026-10-28 soir)

Ce qui change par rapport au design d'origine :

- **cssmt sera publié** comme projet propre du propriétaire (pas une contribution à tf2mt). Le non-objectif
  « Publication » est levé.
- **Aucun réglage taillé pour une seule machine.** Par défaut, le jeu tourne à la définition et à la fréquence
  actuelles de l'écran principal (`displaymode current`). Le lanceur propose « Resolution » (Native par défaut) et
  « Refresh rate while playing » (Unchanged par défaut), remplis avec les modes réels de l'écran. Le propriétaire
  choisira 1920×1080 et 120 Hz pour son M1. Les objectifs « 120 fps en 2560×1440 » et la cible 120 Hz deviennent
  des réglages du propriétaire, plus des constantes.
- **Mises à jour** : l'auto-update de tf2mt est à réintroduire, pointé vers le dépôt GitHub du propriétaire (URL à
  fournir par lui).
- **App non signée** (pas de compte Apple Developer) : premier lancement par clic droit → Ouvrir, comme tf2mt.
- **README public en anglais** : prérequis, installation, avertissements VAC, attribution à tf2mt (MIT).
- **Rendu Metal : décision prise, on y va (phases 2 et 4).** Mesures du 2026-10-28 sur le serveur ZE du propriétaire
  (M1 8 cœurs GPU) : DXVK ~40 fps (réglages max) puis ~60 fps (Balanced) avec à-coups de compilation ; Metal 0 gel,
  cache de pipelines persistant, GPU 11–12 ms/image en 1440p et 7,6–8 ms en 1080p (66–72 fps à 120 Hz). Défaut
  connu à corriger dans le rendu avant de le proposer par défaut : la correction colorimétrique sort bleue (le shader
  échantillonne un cube là où le jeu lie une texture 2D, le rendu met une texture vide). Contournement actuel :
  `+mat_colorcorrection 0` quand le rendu Metal est actif.
- Reste à décider avec le propriétaire : nom et URL du dépôt, date de publication.

## Intention

Jouer à **Counter-Strike: Source** (version Windows officielle, appid 240) sur le Mac du propriétaire, sur les
**serveurs communautaires Steam sécurisés VAC**, avec une image **fluide à 120 Hz sans saccades**. Valve ne fournit
plus de client macOS jouable. Le projet est un fork de [tf2mt](https://github.com/HorrorPills/tf2mt) (MIT) :
même approche (Wine + rendu D3D9 → Metal maison + lanceur macOS), réorientée vers CS:S uniquement.

L'alternative native (nillerusr/source-engine) a été écartée : protocole réseau 25 et tables de classes issues de la
fuite 2018, incompatibles avec les serveurs CS:S réels (Steam ou no-steam).

## Objectifs

1. CS:S Windows lancé depuis une app macOS (`cssmt.app`), connecté à Steam Windows dans Wine, capable de rejoindre
   un serveur communautaire VAC.
2. **120 fps stables à 120 Hz** en 2560×1440 sur le Mac cible, sans à-coups perceptibles (même critères que les
   rapports tf2mt : temps d'image, hitches > 20 ms, latence début d'image → écran).
3. Souris fluide (correctif winemac de tf2mt, logique de pacing / drain de file de tf2mt).
4. Lanceur au **même niveau de fonctionnalités que tf2mt v0.3.5** : onglets Game / Configs / Setup / Debug, choix du
   rendu (DXVK / Metal), préréglages graphiques, choix du micro, dossiers de configs, logs, afficher/masquer Steam,
   fermeture propre de Steam/Wine en fin de session, Load .exe (debug).

## Non-objectifs

- TF2 (l'app est mono-jeu CS:S ; pas de couche multi-jeux).
- Publication : pas de releases GitHub, pas d'auto-updater actif, pas de signature/notarisation. Usage perso.
- Serveurs no-steam, version native, CS:S 32-bit.
- Mac Intel.

## Anti-objectifs (échec même si ça « marche »)

- **Tout risque VAC** : on ne modifie jamais les binaires du jeu ni sa mémoire, on n'injecte rien dans le
  processus du jeu en dehors d'un `d3d9.dll` (comme tf2mt/DXVK). Les outils de test ne rejoignent jamais de serveur
  en ligne d'eux-mêmes (règle tf2mt reprise : les tests automatisés restent en serveur local / démo).
- Laisser Steam/Wine tourner en arrière-plan après la partie.
- Abîmer la config macOS (fréquence écran non restaurée, etc.).

## Contraintes (machine cible, relevé du 2026-10-28)

- MacBook Pro 13" **M1 (8 cœurs GPU), 16 Go**, macOS 27.0.1, 92 Go libres.
- Écran externe G27UP, 2560×1440 HiDPI (backing 5K) à **160 Hz** natif. Le propriétaire accepte de jouer à
  **120 Hz**. Le jeu doit rendre en 2560×1440 (pas en 5K).
- Outils présents : Homebrew, clang, swiftc (Command Line Tools, pas Xcode). **À installer : `mingw-w64`** (brew).
- Wine x86_64 sous Rosetta (runtime tf2mt `wine10.0-0.6.11`, téléchargé depuis la release tf2mt v0.1.0, SHA-256
  vérifié).
- Le M1 de base est plus faible que la machine sur laquelle tf2mt a été mesuré : la marge à 120 fps est à
  **mesurer** avant d'investir dans l'optimisation.

## Ce que le propriétaire a décidé

- Option A (Wine + tf2mt), pas le moteur natif.
- CS:S uniquement, usage perso.
- Cible 120 Hz.
- Garder toutes les fonctionnalités du lanceur tf2mt, **sauf l'auto-update** (voir ci-dessous).
- Le rendu Metal reste au plan, mais **la décision d'engager les phases 2 et 4 se prend après les mesures DXVK de la
  phase 1**, avec le propriétaire.
- Configuration de jeu : **capot fermé, seul écran = G27UP** (c'est donc l'écran principal et le seul écran actif).

## Conception

### Dépôt
`~/Documents/css-osx` = clone git de tf2mt avec `upstream` → HorrorPills/tf2mt (pour récupérer les correctifs du
rendu), branche de travail propre au fork. Historique tf2mt conservé, licence MIT et attribution conservées.
*(mon choix)*

### Renommage et paramétrage du jeu
Toute référence TF2 en dur (≈ 300 occurrences dans scripts, lanceur, Makefile) devient une constante CS:S, regroupée
dans `scripts/_env.sh` :

| tf2mt | cssmt |
|---|---|
| `TF2_HOME=~/Games/tf2` | `CSS_HOME=~/Games/css` |
| appid 440, `steam://install/440`, `-applaunch 440` | 240 |
| `Team Fortress 2/`, `-game tf`, `tf.exe` → `tf_win64.exe` | `Counter-Strike Source/`, `-game cstrike`, lanceur et exe 64-bit **à relever après installation** (attendu : `cstrike.exe` → `cstrike_win64.exe`, par analogie avec TF2) |
| `tf2_pids`, `AppDefaults\tf_win64.exe` | idem avec l'exe 64-bit CS:S |
| `tf2mt.app`, `TF2Launcher.swift`, `tf2mt.dll` | `cssmt.app`, `CSSLauncher.swift` ; la DLL du rendu peut garder son nom interne *(mon choix : renommer uniquement ce que voit l'utilisateur, pour faciliter les merges upstream)* |

Les variables d'environnement `TF2MT_*` du rendu restent telles quelles (même raison).

### Préréglages graphiques (remplace mastercomfig)
mastercomfig n'existe que pour TF2. cssmt fournit ses propres préréglages **Low / Balanced / High / None (config
perso)** sous forme de `.cfg` installés dans `cstrike/custom/cssmt/cfg/` et appelés par un `autoexec` géré, sans
écraser `config.cfg` ni un `autoexec.cfg` du joueur. Contenu initial : `fps_max` adapté à 120 Hz, `mat_*`
(qualité ombres/eau/AA), `cl_*` réseau standards communautaires (`rate`, `cl_cmdrate`, `cl_updaterate`,
`cl_interp_ratio`). Les valeurs Balanced sont calées sur les mesures de la phase 1. *(mon choix)*

### Fréquence d'écran
Option du lanceur « Passer l'écran à 120 Hz pendant la partie » (défaut : activée). Basculement via CoreGraphics
(`CGDisplayCopyAllDisplayModes` / `CGDisplaySetDisplayMode`) sur l'écran principal, mode 2560×1440 HiDPI @ 120 Hz ;
restauration du mode précédent à la fin de session (y compris crash), réutilisant le mécanisme de fin de session de
tf2mt. Si le mode 120 Hz n'existe pas, on n'y touche pas et on l'écrit dans le log.

### Choix du constructeur déjà tranchés
- **Rendu par défaut : DXVK** tant que le Metal n'a pas passé le critère de la phase 2 ; ensuite Metal par défaut.
  L'overlay Steam (`-applaunch 240`) ne fonctionne qu'en DXVK, comme dans tf2mt. *(mon choix)*
- **Niveau de shaders : celui que CS:S choisit sous DXVK** avec l'identité d'adaptateur de tf2mt (attendu : SM2 /
  dxlevel 95, comme TF2, ADR-001). Si CS:S choisit SM3 / dxlevel 98, on s'arrête et on demande au propriétaire avant
  d'écrire le support SM3. *(mon choix)*
- **Auto-update supprimé** : bouton Update, affichage « nouvelle version » et vérification des releases GitHub
  retirés (ils visent les releases tf2mt et remplaceraient l'app par TF2). `config/release.conf` ne garde que l'URL et
  le SHA-256 du runtime Wine. *(mon choix)*
- **Écran** : la bascule 120 Hz et la lecture de fréquence du pacing ciblent l'écran principal ; capot fermé, c'est
  le G27UP. Si un autre écran est actif au lancement, on logue un avertissement et on bascule quand même l'écran
  principal. *(mon choix)*

### Fonctionnalités TF2 à réévaluer
- **Friends hors ligne** (contournement d'un bug du panneau amis du menu TF2) : conservé comme option, **défaut
  désactivé** pour CS:S, réactivé seulement si la phase 1 montre le même effondrement de fps en menu.
- **Bots / nav mesh / démo de bench** : CS:S a des bots intégrés (`bot_add`, nav auto). Une démo locale
  `cstrike/bench.dem` (de_dust2, bots) remplace `tf/bench.dem`.

### Rendu Metal : ce qui doit être revalidé pour CS:S
Le rendu D3D9 est générique, mais ses données viennent de TF2 :
- `src/frontend/caps_table.h` : n'accepte que les combinaisons format/caps que **TF2** a demandées pendant le
  recensement. CS:S peut en demander d'autres → refaire un recensement CS:S (`tools/census`, mode DXVK oracle) et
  fusionner les tables.
- Corpus de shaders et goldens (SSIM vs DXVK) : relancer sur des maps CS:S (de_dust2, cs_office, de_nuke, de_inferno
  au minimum ; eau, fumigènes, flashbang, lunette AWP, HDR).
- Le pacing / drain (`TF2MT_DRAIN`) et les réglages de latence : remesurer à 120 Hz sur le M1.

### Phases et critères de passage
0. **Base** : fork, renommage, setup, Steam Windows, installation CS:S, lancement en **DXVK**. *Passage* : CS:S se
   lance, rejoint un serveur communautaire VAC (test fait par le propriétaire), quitte proprement.
1. **Mesure M1 en DXVK** : bench démo + partie bots, 2560×1440. *Passage* : connaître fps moyen, 1 % low, hitches.
   **Point de décision avec le propriétaire** : engager ou non les phases 2 et 4 (Metal), au vu des mesures (fps,
   1 % low, hitches, latence). Le Metal apporte dans tf2mt ~+15 % fps et ~10–15 ms de latence en moins.
2. **Rendu Metal** : recensement CS:S, mise à jour des caps, goldens CS:S. *Passage* : SSIM ≥ 0.997 vs DXVK sur
   les goldens CS:S, aucune erreur de création de ressource, 120 fps stables en bench.
3. **Lanceur complet** : toutes les fonctionnalités listées, préréglages CS:S, bascule 120 Hz.
4. **Fluidité 120 Hz** : drain/pacing validés, session de jeu en ligne du propriétaire sans saccade perçue.

## Laissé au constructeur
- Ordre exact des renommages, structure des commits.
- Contenu précis des `.cfg` de préréglages (dans les limites ci-dessus).
- Outils de mesure à réutiliser tels quels ou à adapter.
- Que faire si la phase 1 montre que le M1 ne tient pas 120 fps : proposer des options au propriétaire (baisse de
  résolution de rendu, préréglage Low), ne pas décider seul de changer la cible.
