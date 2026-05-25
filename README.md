# MacDeck

Transforme ton iPhone en StreamDeck pour contrôler ton Mac — volume, luminosité, apps, raccourcis clavier, médias et plus.

![Platform](https://img.shields.io/badge/iOS-16%2B-blue) ![Platform](https://img.shields.io/badge/macOS-12%2B-lightgrey) ![License](https://img.shields.io/badge/license-MIT-green)

---

## Fonctionnalités

- **Volume & luminosité** — sliders verticaux tactiles
- **Contrôle média** — play/pause, suivant, précédent (Spotify, Apple Music)
- **Mute micro & son** — toggle rapide
- **Grille d'apps** — lance n'importe quelle app macOS en un tap
- **Raccourcis clavier** — Screenshot, Spotlight, Mission Control, Cmd+Tab, Verrouiller…
- **Actions système** — Sleep, Ne pas déranger, Vider la corbeille
- **Icônes automatiques** — les vraies icônes de tes apps macOS
- **Portrait & paysage** — layout adaptatif
- **Découverte automatique** — se connecte au Mac via Bonjour sans config manuelle

---

## Prérequis

| Côté Mac | Côté iPhone |
|----------|-------------|
| macOS 12+ | iOS 16+ |
| Node.js 18+ | Xcode 15+ (pour installer l'app) |
| Même réseau Wi-Fi que l'iPhone | Même réseau Wi-Fi que le Mac |

---

## Installation

### 1 — Serveur Mac

```bash
# Cloner le repo
git clone https://github.com/Andre27aj/MacDeck.git
cd MacDeck

# Installer les dépendances
npm install

# Lancer le serveur
npm start
```

Le terminal affiche l'adresse du serveur, ex : `MacDeck running → http://192.168.1.42:3000`

> **Note :** Au premier lancement, macOS peut demander des autorisations réseau — accepte-les.

### 2 — App iOS

```bash
cd ios
```

Ouvre `MacDeck.xcodeproj` dans Xcode :

1. Connecte ton iPhone au Mac via câble USB
2. Dans Xcode, sélectionne ton iPhone comme destination
3. Change le **Team** dans *Signing & Capabilities* pour ton propre compte Apple
4. Appuie sur **⌘R** pour compiler et installer

> Tu n'as pas besoin d'un compte Apple Developer payant — un compte gratuit suffit pour installer sur ton propre iPhone.

---

## Utilisation

1. Lance `npm start` sur le Mac
2. Ouvre **MacDeck** sur l'iPhone
3. L'app détecte le Mac automatiquement via Bonjour
4. Si la connexion échoue, entre l'IP manuellement dans les réglages (icône ⚙️)

---

## Personnaliser les apps

Tape sur l'icône ✏️ dans la grille pour modifier les apps affichées. Tu peux changer le nom, l'icône SF Symbol et le nom de lancement macOS.

---

## Structure du projet

```
MacDeck/
├── server.js          # Serveur Express sur le Mac
├── public/            # Interface web (alternative à l'app native)
└── ios/
    └── MacDeck/
        ├── ContentView.swift      # Layout principal
        ├── LeftPanel.swift        # Volume, luminosité, médias
        ├── DeckGrid.swift         # Grille de boutons
        ├── MutePanel.swift        # Boutons mute micro/son
        ├── ViewModel.swift        # État & appels API
        ├── APIClient.swift        # Client HTTP
        └── ...
```

---

## Permissions macOS

Certaines fonctions nécessitent des autorisations supplémentaires :

- **Raccourcis clavier** (Spotlight, Mission Control…) → *Réglages Système → Confidentialité → Accessibilité* → ajouter Terminal ou Node
- **Contrôle apps** → *Réglages Système → Confidentialité → Automatisation*

---

## Limitations

- iPhone et Mac doivent être sur le **même réseau local**
- Ne fonctionne pas à distance (pas de VPN, pas d'internet)
- L'app iOS doit être compilée avec Xcode (pas disponible sur l'App Store)
