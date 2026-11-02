# RankForge (DRM)

**RankForge** ist ein hochflexibles WoW-Addon zur automatischen Erstellung und Verwaltung von Downranking-Makros für Heiler und Caster in **WoW Forever**, **Classic Era / SoD / Hardcore** und **TBC Era**.

---

## ✨ Features

- **Dynamisches Downranking:**
  - Wähle Zauber und weise Tasten (`nomod`, `Shift`, `Ctrl`, `Alt`, `Shift+Ctrl`, `Shift+Alt`) relative Ränge zu (`Max`, `Max - 1`, `Max - 2`, etc.) oder alternative Zauber.
  - Beim Lernen neuer Zauberränge beim Lehrer werden alle Makros im Hintergrund **vollautomatisch aktualisiert**.
- **Direktes Drag & Drop auf die Aktionsleiste:**
  - Greife das Vorschau-Icon in der GUI mit der Maus und ziehe das Makro direkt auf deine Aktionsleiste! Du musst das Makro-Menü (`/m`) nie wieder öffnen.
  - Das Makro muss nur einmal auf die Leiste gelegt werden – RankForge aktualisiert den Inhalt im Hintergrund, wenn du levelst oder neue Ränge lernst.
- **Drei Wege zur Zauberauswahl:**
  1. Zauber direkt aus dem Zauberbuch in das Vorschaufeld ziehen (Drag & Drop).
  2. Schnellauswahl aus der Liste aller gelernten Zauber.
  3. Freie Texteingabe.
- **Frei sortierbare Modifikator-Reihenfolge:**
  - Tasten können über die Pfeiltasten (▲ / ▼) in jede beliebige Auswertungs-Reihenfolge gebracht werden.
  - Standardmäßig sind Doppel-Modifikatoren (`Shift+Ctrl`, `Shift+Alt`) priorisiert, damit kein unbeabsichtigtes Auslösen einfacher Modifikatoren passiert.
- **Fallback-Einstellung bei fehlenden Rängen:**
  - Wählbar pro Makro: Fehlen noch Ränge (z. B. auf niedrigen Leveln), wird die Bedingung entweder **weggelassen** oder vorübergehend auf **Rang 1** zurückgegriffen.
- **Umfangreiches Targeting:**
  - Checkboxen für Mouseover mit Ziel-Fallback (`[@mouseover,help,nodead][]`), striktes Mouseover, Fokus, Ziel-des-Ziels (`[@targettarget]`) und Auto-Selfcast (`[@player]`).
  - Freitextfeld für eigene fortgeschrittene Bedingungen.
- **Live-Vorschau mit Zeichenlimit-Warnung:**
  - Live-Codevorschau und Zeichenzähler (`165 / 255`).
  - Warnt optisch in Gelb/Rot bei Annäherung an das 255-Zeichen-Limit von WoW.
- **Kampf-Schutz (`InCombatLockdown`):**
  - Werden im Kampf neue Ränge gelernt oder ein Levelup erreicht, wartet RankForge automatisch bis zum Kampfende (`PLAYER_REGEN_ENABLED`) und aktualisiert die Makros ohne UI-Fehler oder Taint.
- **1-Klick-Vorlagen (Presets):**
  - Vorkonfigurierte Makros für Priester (Erneuerung, Blitzheilung, Große Heilung, Schild), Paladine (Heiliges Licht, Lichtblitz), Druiden (Heilende Berührung, Nachwachsen, Verjüngung) und Schamanen (Kettenheilung, Welle der Heilung).
- **Profil-System mit Base64-Import/Export:**
  - Speichere Profile für Twinks oder teile Konfigurationen über einen Base64-String.
- **Sicherheitsabfrage:**
  - Beim Löschen eines Makros fragt ein Popup, ob das Makro auch aus den WoW-Makros gelöscht werden soll.

---

## ⌨️ Slash-Befehle

| Befehl | Funktion |
| :--- | :--- |
| `/rf` oder `/rankforge` | Öffnet / schließt die grafische Benutzeroberfläche |
| `/rf update` | Erzwingt eine sofortige Aktualisierung aller Makros |
| `/rf help` | Zeigt eine Übersicht aller Befehle im Chat an |

---

## 📁 Installation & Multi-Client Softlinks

RankForge ist über Verzeichnis-Junctions (Softlinks) direkt verknüpft mit:
- `D:\Blizzard\World of Warcraft\_forever_\Interface\AddOns\RankForge`
- `D:\Blizzard\World of Warcraft\_classic_era_\Interface\AddOns\RankForge`
- `D:\Blizzard\World of Warcraft\_anniversary_\Interface\AddOns\RankForge` (TBC 2.5.6)

Jede Änderung im Entwicklungsordner `d:\Wow-Addons\downrank-macros` ist somit **ohne Kopieren sofort in allen Clients aktiv**!
