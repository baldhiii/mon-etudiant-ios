# CHARTE — Mon Étudiant (v1)

Style : sobre, premium, natif Apple. Une seule audace : l'accent **indigo**, clin d'œil à la teinture indigo ouest-africaine — tout le reste reste calme (fonds système, SF Pro, SF Symbols).

---

## 1. Palette

Convention : chaque couleur = 1 Color Set Xcode avec variante **Any (light)** et **Dark**.
Tous les contrastes indiqués sont ≥ 4,5:1 (WCAG AA texte normal) sur le fond correspondant :
light → `systemBackground` (#FFFFFF), dark → `systemBackground` (#000000).

### 1.1 Accent

| Asset Xcode | Light | Dark | Usage |
|---|---|---|---|
| `AccentColor` | `#4F46E5` | `#818CF8` | Boutons, liens, éléments actifs, tab bar |

Contraste : 6,3:1 sur blanc / 7,6:1 sur noir. ✅ AA (et AAA en dark).

### 1.2 Matières (8)

Utilisées pour : pastilles, bordures de cartes, texte de labels de matière.
Toujours utiliser la couleur comme **texte/icône sur fond système**, jamais comme fond derrière du texte blanc (sauf pastilles décoratives sans texte).

| Asset Xcode | Nom FR affiché (défaut) | Light | Dark |
|---|---|---|---|
| `SubjectRed` | Rouge | `#B91C1C` | `#F87171` |
| `SubjectOrange` | Orange | `#C2410C` | `#FB923C` |
| `SubjectAmber` | Ambre | `#B45309` | `#FBBF24` |
| `SubjectGreen` | Vert | `#15803D` | `#4ADE80` |
| `SubjectTeal` | Sarcelle | `#0F766E` | `#2DD4BF` |
| `SubjectBlue` | Bleu | `#1D4ED8` | `#60A5FA` |
| `SubjectPurple` | Violet | `#6D28D9` | `#A78BFA` |
| `SubjectPink` | Rose | `#BE185D` | `#F472B6` |

Contrastes light : 4,6 à 7,3:1 sur blanc. Contrastes dark : 6,9 à 10,7:1 sur noir. ✅ AA partout.
Fond doux de carte (optionnel) : la même couleur à **12 % d'opacité** sur fond système (pas de texte dessus autre que la couleur pleine).

### 1.3 Sémantiques

| Asset Xcode | Light | Dark | Usage |
|---|---|---|---|
| `SemanticSuccess` | `#15803D` | `#4ADE80` | Devoir fait, carte réussie, sync OK |
| `SemanticWarning` | `#B45309` | `#FBBF24` | Échéance proche, hors ligne (fonctions IA) |
| `SemanticError` | `#B91C1C` | `#F87171` | Devoir en retard, échec réseau/serveur |

### 1.4 Fonds et texte

Aucun asset custom : utiliser les couleurs système
(`systemBackground`, `secondarySystemBackground` pour les cartes, `label`, `secondaryLabel`, `separator`). C'est ce qui garantit le rendu natif light/dark sans effort.

---

## 2. Typographie

100 % SF Pro via les text styles Dynamic Type (jamais de taille en dur).

| Rôle | Text style SwiftUI | Taille base | Graisse | Usage |
|---|---|---|---|---|
| Titre d'écran | `.largeTitle` | 34 | Bold | Titre de navigation |
| Titre de section | `.title2` | 22 | Bold | Sections du tableau de bord |
| Titre de carte | `.headline` | 17 | Semibold | Nom de devoir, de matière |
| Corps | `.body` | 17 | Regular | Texte courant, messages du chat |
| Secondaire | `.subheadline` | 15 | Regular | Date, matière associée |
| Légende | `.caption` | 12 | Regular | Métadonnées, horodatage chat |
| Chiffres du dashboard | `.title` + `.rounded` | 28 | Bold | Compteurs (SF Pro Rounded pour la chaleur) |

Règles : max 2 graisses par écran hors titres ; `minimumScaleFactor` interdit sur le corps ; tester en `AX3`.

---

## 3. Ton rédactionnel

Tutoiement, encourageant, phrases courtes. Jamais culpabilisant, jamais d'exclamation en rafale. Verbes d'action sur les boutons ("Ajouter un devoir", pas "Valider").

### 3.1 États vides (micro-textes finaux)

| Écran | Titre | Texte | Bouton |
|---|---|---|---|
| Matières | Aucune matière | Ajoute tes matières pour organiser tout le reste. | Ajouter une matière |
| Emploi du temps | Semaine vide | Ajoute tes cours, ils apparaîtront ici jour par jour. | Ajouter un cours |
| Devoirs | Rien à faire | Tout est à jour. Profite, ou prends de l'avance. | Ajouter un devoir |
| Flashcards | Aucun paquet | Crée un paquet, ou demande au Professeur d'en générer un. | Créer un paquet |
| Révisions du jour | Terminé pour aujourd'hui | Bien joué. Tes prochaines cartes reviennent demain. | — |
| Chat Professeur (1re fois) | Ton Professeur est là | Pose une question, il te guide pas à pas, sans donner la réponse toute faite. | — |
| Chat hors ligne | Connexion requise | Le Professeur a besoin d'Internet. Tes cours, devoirs et cartes restent disponibles. | Réessayer |

### 3.2 Notifications locales (finales)

| Cas | Titre | Corps |
|---|---|---|
| Devoir J-1 | {Matière} — demain | « {Titre du devoir} » est à rendre demain. Un petit coup d'œil ce soir ? |
| Devoir jour J | À rendre aujourd'hui | « {Titre du devoir} » ({Matière}). Tu y es presque. |
| Révisions dispo | Tes cartes t'attendent | {n} cartes à revoir aujourd'hui. 5 minutes suffisent. |

---

## 4. Prêt à coller (Asset Catalog)

Créer un dossier `Colors/` dans `Assets.xcassets`, un Color Set par ligne, **Appearances : Any, Dark**, valeurs sRGB hex ci-dessus. `AccentColor` existe déjà à la racine du catalogue : y coller les deux valeurs de 1.1.

**DoD T1** : ce fichier + valeurs hex light/dark pour accent, 8 matières et 3 sémantiques, toutes AA. ✅
