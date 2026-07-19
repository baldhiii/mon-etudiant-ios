# ICÔNE & ÉCRANS CLÉS — Mon Étudiant (v1)

## 1. Icône

### Trois pistes explorées

| Piste | Concept | Verdict |
|---|---|---|
| A — Monogramme | « É » majuscule SF Pro Bold blanc sur indigo plein | Élégant mais froid ; ne dit ni "études" ni "IA" ; risque de confusion avec des apps utilitaires |
| B — Livre + étincelle | Livre ouvert blanc, étincelle ambre en haut à droite, fond dégradé indigo | Lisible à 60 px, raconte exactement le produit (études + IA), zéro texte → international |
| **C** — Bulle Professeur | Bulle de chat contenant un chapeau de diplômé | Trop "chatbot" ; réduit l'app à sa seule fonction IA |

### Finale : piste B
- Fichiers : `app-icon-1024.svg` (source déclinable) + `app-icon-1024.png` (livrable App Store).
- Fond plein cadre, **sans coins arrondis** (masque appliqué par iOS). Dégradé vertical `#6366F1 → #4338CA`.
- Livre blanc pur, étincelle `#FDE68A` = seul écart chromatique (cohérent charte : accent indigo + une chaleur).
- Déclinaisons : pour les petites tailles, aucun ajustement nécessaire (vérifié à 64 px). Variante dark/teintée iOS 18 : le SVG en un seul groupe blanc suffit.

---

## 2. Structure de navigation (figée)

`TabView` à **4 onglets** ; le Professeur s'ouvre en **plein écran (fullScreenCover)** depuis un bouton flottant présent sur les 4 onglets.

| Onglet | Label | SF Symbol |
|---|---|---|
| 1 | Aujourd'hui | `sun.max.fill` |
| 2 | Agenda | `calendar` |
| 3 | Devoirs | `checklist` |
| 4 | Révisions | `rectangle.stack.fill` |

Bouton flottant Professeur : cercle 56 pt, `AccentColor`, symbole `sparkles`, en bas à droite, 16 pt au-dessus de la tab bar. Toujours visible sauf pendant une session de révision.

La gestion des **matières** vit dans Agenda (bouton toolbar), pas dans un 5e onglet.

---

## 3. Maquettes basse fidélité

Conventions : `[ ]` = carte `secondarySystemBackground`, coins 12 pt, padding 16 pt ; ● = pastille couleur de matière 10 pt ; listes = `List` insetGrouped ou `ScrollView` + `LazyVStack`.

### 3.1 Aujourd'hui (tableau de bord)

```
┌──────────────────────────────┐
│ Aujourd'hui            (⚙︎)  │  largeTitle + bouton Réglages
│ samedi 19 juillet            │  subheadline, secondaryLabel
│                              │
│ ┌─────────┐ ┌─────────┐      │  2 compteurs côte à côte (title rounded)
│ │  3      │ │  12     │      │  "Devoirs à faire" / "Cartes à revoir"
│ │ devoirs │ │ cartes  │      │  tap → onglet correspondant
│ └─────────┘ └─────────┘      │
│                              │
│ Prochains cours   (title2)   │
│ [● Maths      08:00–09:00 ]  │  max 3 ; vide → "Pas de cours aujourd'hui."
│ [● Physique   10:00–11:00 ]  │
│                              │
│ À rendre bientôt  (title2)   │
│ [● Dissertation    demain ⚠︎] │  max 3, tri par échéance ;
│ [● Exos ch.4       mardi   ] │  ⚠︎ = SemanticWarning si ≤ 24 h
│                        (✦)   │  bouton flottant Professeur
└──────────────────────────────┘
```

### 3.2 Agenda (emploi du temps)

```
┌──────────────────────────────┐
│ Agenda            (Matières) │  bouton toolbar → liste des matières
│ ‹ Lun Mar Mer Jeu Ven Sam ›  │  sélecteur de jour (segmented horizontal,
│        ────                  │  jour actif souligné AccentColor)
│                              │
│ [● 08:00  Maths        s.12] │  cartes triées par heure ;
│ [● 10:00  Physique     s.07] │  barre latérale gauche 4 pt couleur matière
│ [● 14:00  Anglais      s.03] │
│                              │
│ vide → état vide charte 3.1  │
│                        (+)   │  toolbar : + → formulaire Cours
└──────────────────────────────┘
Formulaire Cours (sheet) : matière (Picker), jour(s), heure début/fin, salle (optionnel).
Écran Matières (push) : liste [● Nom  chevron], + toolbar ; formulaire = nom + couleur (grille des 8).
```

### 3.3 Devoirs

```
┌──────────────────────────────┐
│ Devoirs                  (+) │
│ (À faire | Faits)            │  segmented picker
│                              │
│ En retard          (title2)  │  sections par urgence :
│ [○ ● Exposé histoire  hier ] │  En retard (SemanticError) /
│ Cette semaine                │  Cette semaine / Plus tard
│ [○ ● Exos ch.4       mardi ] │  ○ = checkbox → coche verte + haptic,
│ [○ ● Dissertation    vend. ] │  bascule dans "Faits" après 0,5 s
│                        (✦)   │
└──────────────────────────────┘
Formulaire (sheet) : titre, matière, date, rappel (aucun / J-1 / jour J — notifs charte 3.2), note libre.
Swipe : gauche = supprimer, droite = fait.
```

### 3.4 Révisions (flashcards)

```
┌──────────────────────────────┐
│ Révisions                (+) │  + → Créer un paquet / Demander à l'IA
│                              │
│ [ 12 cartes à revoir       ] │  carte accent (fond AccentColor 12 %,
│ [ ▶ Réviser maintenant     ] │  bouton plein AccentColor) ; masquée si 0
│                              │
│ Mes paquets        (title2)  │
│ [● Maths — Dérivées    24  ] │  nb de cartes, chevron → détail paquet
│ [● Anglais — Verbes    50  ] │
└──────────────────────────────┘
Session (plein écran) : carte centrée (question), tap → flip (réponse),
puis 3 boutons : "À revoir" (rouge) / "Correct" (vert) / "Facile" (accent).
Barre de progression fine en haut. Fin de session → état "Terminé" charte 3.1.
```

### 3.5 Chat Professeur (plein écran)

```
┌──────────────────────────────┐
│ (Fermer)  Professeur   (⋯)  │  ⋯ → Nouvelle conversation / Historique
│                              │
│      [bulle grise IA      ]  │  IA : secondarySystemBackground, alignée
│  [bulle accent utilisateur]  │  gauche ; user : AccentColor, texte blanc,
│      [bulle IA — stream ▍ ]  │  alignée droite ; streaming = curseur
│                              │
│ ┌ Génère des flashcards ┐    │  chips de suggestions au-dessus du champ
│ └ Fais-moi une fiche    ┘    │  (visibles quand conversation vide)
│ [ Écris ta question…    (↑)] │  champ + bouton envoyer (AccentColor)
└──────────────────────────────┘
Hors ligne : contenu remplacé par l'état "Connexion requise" (charte 3.1), symbole wifi.slash SemanticWarning.
Génération de flashcards : l'IA répond avec un aperçu des cartes + bouton "Ajouter au paquet…" (Picker de paquets).
```

**DoD T2** : icône finale livrée (SVG + PNG 1024, lisibilité vérifiée à 64 px) ; 5 écrans spécifiés avec composants, symboles, états vides, formulaires et interactions → l'Agent 1 peut implémenter sans question de mise en page. ✅
