# MacDeck — Serveur Mac

Le serveur Node.js qui fait tourner MacDeck sur ton Mac. Il expose une API REST locale que les clients (app iOS, PWA sur Android/Windows/navigateur) utilisent pour contrôler le Mac.

![Platform](https://img.shields.io/badge/macOS-12%2B-lightgrey) ![Node](https://img.shields.io/badge/Node.js-18%2B-green) ![License](https://img.shields.io/badge/license-MIT-green)

---

## Écosystème MacDeck

| Repo | Description | Plateforme |
|------|-------------|------------|
| **MacDeck** *(ce repo)* | Serveur Mac + interface web | macOS |
| [MacDeck-iOS](https://github.com/Andre27aj/MacDeck-iOS) | App native Swift | iPhone / iPad |
| [MacDeck-Windows](https://github.com/Andre27aj/MacDeck-Windows) | Serveur Windows + interface web | Windows |

**L'interface web (PWA) incluse dans ce repo fonctionne sur :**
- iPhone / iPad (Safari → "Sur l'écran d'accueil")
- Android (Chrome → "Ajouter à l'écran d'accueil")
- Windows, Linux, tout navigateur sur le même réseau

---

## Ce que tu peux contrôler

- **Volume & luminosité** — sliders précis
- **Mute** son et micro indépendamment
- **Médias** — play/pause, piste suivante/précédente, titre en cours
- **Grille d'apps** — lance n'importe quelle app macOS, bordure verte si déjà ouverte
- **Actions système** — verrouiller, veille écran, veille Mac, capture d'écran, vider la corbeille, Ne pas déranger, Mission Control, Spotlight, mode sombre
- **Raccourcis clavier** — Cmd+Tab, Cmd+Q, et tous les raccourcis personnalisables
- **Batterie Mac** — affichée en temps réel sur le client
- **Profils automatiques** — les raccourcis changent selon l'app active (Figma, Xcode, Safari…)

---

## Installation

### Prérequis

- macOS 12+
- Node.js 18+ → [nodejs.org](https://nodejs.org)
- L'appareil client sur le **même réseau Wi-Fi**

### Lancer le serveur

```bash
git clone https://github.com/Andre27aj/MacDeck.git
cd MacDeck
npm install
npm start
```

Le terminal affiche l'IP du Mac, ex : `MacDeck running → http://192.168.1.42:3000`

---

## Utiliser depuis un navigateur (Android, iPhone, PC…)

Ouvre `http://<ip-du-mac>:3000` depuis n'importe quel appareil sur le même réseau.

### Installer comme app (PWA)

| Appareil | Comment faire |
|----------|---------------|
| **Android** | Chrome → menu ⋮ → "Ajouter à l'écran d'accueil" |
| **iPhone / iPad** | Safari → icône partage → "Sur l'écran d'accueil" |
| **Windows / Mac / Linux** | Chrome ou Edge → icône installation dans la barre d'adresse |

Une fois installée, la PWA s'ouvre comme une vraie app (plein écran, sans barre de navigateur). Elle fonctionne aussi hors ligne pour l'interface, mais a besoin du réseau pour communiquer avec le serveur.

> **Android** : aucune installation d'APK nécessaire, Chrome gère tout. L'expérience est proche d'une app native.

---

## Utiliser l'app iOS native

L'app [MacDeck-iOS](https://github.com/Andre27aj/MacDeck-iOS) offre une meilleure expérience sur iPhone/iPad : détection automatique du Mac via Bonjour (pas besoin d'entrer l'IP), feedback haptique, et gestures natives SwiftUI.

---

## Permissions macOS

Certaines fonctions nécessitent une autorisation dans *Réglages Système → Confidentialité* :

| Fonctionnalité | Permission requise |
|---|---|
| Raccourcis clavier (Spotlight, Mission Control…) | Accessibilité → ajouter Terminal ou Node |
| Contrôle d'autres apps | Automatisation |
| Capture d'écran | Enregistrement d'écran |

Au premier lancement, macOS affiche des popups d'autorisation — accepte-les.

---

## Structure du projet

```
MacDeck/
├── server.js          # Serveur Express (toute la logique macOS)
├── package.json
└── public/            # Interface web PWA (même réseau → n'importe quel appareil)
    ├── index.html     # App complète en un seul fichier HTML/CSS/JS
    ├── manifest.json  # Métadonnées PWA
    ├── sw.js          # Service worker
    ├── icon-192.png
    └── icon-512.png
```

---

## API — Endpoints

| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/system/status` | Volume, mute, médias, batterie, app active, apps ouvertes |
| POST | `/volume` | `{ value: 0-100 }` |
| POST | `/mute` | `{ muted: bool }` |
| POST | `/mic/mute` | Toggle micro |
| POST | `/media/play-pause` | Play/pause |
| POST | `/media/next` | Piste suivante |
| POST | `/media/prev` | Piste précédente |
| POST | `/launch` | `{ app: "Figma" }` — lance une app macOS |
| POST | `/shortcut` | `{ keys: ["cmd","space"] }` — raccourci clavier |
| GET | `/system/brightness` | Luminosité actuelle |
| POST | `/system/brightness` | `{ value: 0-100 }` |
| GET | `/audio/devices` | Liste les sorties audio |
| POST | `/audio/device` | `{ name: "AirPods" }` — change la sortie |
| POST | `/system/sleep` | Veille Mac |
| POST | `/system/lock` | Verrouille l'écran |
| POST | `/system/sleep-display` | Éteint l'écran |
| POST | `/system/dark-mode` | Bascule mode sombre/clair |
| POST | `/system/dnd` | Bascule Ne pas déranger |
| POST | `/system/trash` | Vide la corbeille |
| GET | `/app-icon` | `?name=Figma` — renvoie l'icône de l'app (PNG) |

---

## Limitations

- Mac et client doivent être sur le **même réseau local**
- Ne fonctionne pas à distance sans VPN
- Certaines permissions macOS doivent être accordées manuellement au premier lancement
