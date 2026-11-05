# RankForge (DRM) - Downranking Makro Schmiede

**RankForge** ist ein hochflexibles, intelligentes WoW-Addon zur automatischen Erstellung, Optimierung und Verwaltung von Downranking-Makros für Heiler und Caster in **WoW Forever (3.3.5a)**, **Classic Era / SoD / Hardcore** und **TBC Era**.

---

## ✨ Features

### 🎯 Dynamisches Downranking & Automatische Synchronisation
- **Relative Ränge:** Weise Modifikatoren (`nomod`, `Shift`, `Ctrl`, `Alt`, `Shift+Ctrl`, etc.) relative Ränge zu (`Max`, `Max - 1`, `Max - 2`, etc.) oder alternative Zauber.
- **Vollautomatisches Update:** Lernst du beim Lehrer einen neuen Rang, aktualisiert RankForge im Hintergrund **automatisch alle Makros** auf deinen Aktionsleisten.
- **Alternative Zauber:** Beliebige Tastenbelegungen können mit alternativen Zaubern belegt werden (z. B. nomod = Große Heilung, Shift = Blitzheilung, Alt = Machtwort: Schild).
- **Fallback-Einstellung:** Wähle pro Makro, ob bei noch nicht erlernten Rängen die Taste weggelassen oder vorübergehend **Rang 1 als Fallback** genutzt wird.

### ⚡ Downranking-Effizienz-Engine & Sweet-Spot (WoW Forever)
- **Zaubermacht- & Proc-Berechnung:** Berücksichtigt die Downranking-Strafen (Spell Power Penalty) und Proc-Chancen:
  - 🟢 **Grün (100% Effizienz):** Zauberstufe $\ge$ Charakterstufe - 18 (volle Zaubermacht-Skalierung).
  - 🟡 **Gelb (Moderate Reduktion):** Zauberstufe $\ge 20$, aber unterhalb der vollen Skalierungsgrenze.
  - 🔴 **Rot (Starke Reduktion):** Pre-Level-20-Abzüge & minimierte Effekt- und Proc-Chancen (z. B. Rang-1-Spam).
- **Sweet-Spot-Erkennung:** Markiert automatisch den manaschonendsten Rang, der noch die vollen 100% Zaubermacht-Bonus erhält.

### 🎛️ Matrix-Grid für zielgenaue Bedingungen
- **Unabhängige Ziel-Bedingungen:** Jede Modifikator-Zeile verfügt über eigene Checkboxen für:
  - **MO:** `@mouseover`
  - **Ziel:** Aktuelles Ziel
  - **Fokus:** `@focus`
  - **ToT:** Ziel des Ziels (`@targettarget`)
  - **Selbst:** Auto-Selfcast (`@player`)
  - **Filter:** `help`, `harm`, `nodead`
- **Spalten-Umschalter:** Ein Klick auf die Spaltenüberschriften aktiviert oder deaktiviert die Bedingung für alle Zeilen gleichzeitig.
- **Automatische Typ-Erkennung:** Beim Auswählen eines Zaubers erkennt RankForge schädliche vs. hilfreiche Sprüche und konfiguriert Ziele und Filter (`harm` vs. `help`, Deaktivierung von Selbstzauber) automatisch passend vor.

### ⚔️ Pre-Cast Utility & Burst-Optionen
- **Kampfbefehle:** Integrierte Checkboxen für automatischen Nahkampfangriff (`/startattack`) und Begleiter-Angriff (`/petattack`).
- **Trinkets & Volksfähigkeiten:** 1-Klick-Aktivierung für Trinket 1 (`/use 13`), Trinket 2 (`/use 14`) und Rassenfähigkeiten (`/cast Berserking`, `/cast Kochendes Blut`, etc.).
- **Zusätzliche Befehle:** Freitextfeld für individuelle Pre-Cast Zeilen (z. B. Tränke, `/cast Innerer Fokus`, Runen).

### ✂️ Zeichenlimit-Optimierung (Maximal 255 Zeichen)
- **Kompakte Syntax-Engine:** Redundante Bedingungen (wie doppelte Fallbacks) werden eliminiert.
- **Modifier-Kompression:** Spart bis zu **11–23 Zeichen pro Modifier-Zeile**, sodass selbst komplexe Makros mit Trinkets, Angriffs-Befehlen und 7 Rängen garantiert in die 255-Zeichen-Grenze von WoW passen.
- **Live-Vorschau:** Interaktive Vorschau mit dynamischer Längenanzeige und Farbumschlag (Grün $\to$ Gelb $\to$ Rot).

### 🖱️ Komfortables Drag & Drop
- **Aus dem Zauberbuch:** Ziehe einen Zauber direkt aus deinem Zauberbuch auf das Icon **oder** in das Eingabefeld (unterstützt WoW 3.3.5a Buch-Slots, moderne SpellIDs und Aktionsleisten).
- **Direkt auf die Aktionsleiste:** Greife das Vorschau-Icon in RankForge und lege es direkt auf deine Aktionsleiste. Das Makro muss nie wieder manuell verschoben oder über `/m` bearbeitet werden!

### 📚 Umfassende Multi-Klassen-Datenbank
- Vollständige Ränge- und Leveltabellen für alle relevanten Heiler und Caster (Priester, Paladin, Schamane, Druide, Magier, Hexenmeister).
- Vollständig zweisprachig (Deutsch und Englisch) mit automatischer Client-Erkennung.

### 🛡️ Sicherheit, Charakter-Filter & Profile
- **Charakterspezifische Filterung:** Mit der Checkbox `[x] Nur dieser Charakter` oberhalb der Makroliste werden nur Makros angezeigt, die zu deinem aktuellen Charakter bzw. deiner Klasse gehören. Allgemeine Makros im Account-Tab (z. B. *Feuer machen / Lagerfeuer*, Reittiere, Berufe) bleiben dabei für alle Charaktere sichtbar, während Makros fremder Klassen (z. B. *Blizzard* auf einem Priester) automatisch ausgeblendet werden. Deaktiviere die Checkbox jederzeit, um alle Makros accountweit einzusehen.
- **Standard-Speicherort:** Neue Makros werden standardmäßig im **charakterspezifischen Tab (18 Slots)** angelegt, um die 120 allgemeinen Account-Slots nicht zu überfüllen.
- **Debug-Modus (Auto-Öffnen):** Über den Schalter `Debug (Auto-Öffnen)` in der Titelleiste oder via `/rf debug` öffnet sich RankForge nach jedem `/reload` oder Login automatisch.
- **Kampf-Schutz (`InCombatLockdown`):** Verhindert UI-Fehler oder Taint im Kampf. Änderungen und Updates werden bei Kampfende (`PLAYER_REGEN_ENABLED`) sicher angewendet.
- **Account vs. Charakter:** Wähle flexibel, ob Makros im allgemeinen (Account) oder im charakterspezifischen Makro-Tab gespeichert werden.
- **Base64 Profil-System:** Importiere und exportiere Makro-Sets für Twinks oder zum Teilen mit Gildenmitgliedern.

---

## ⌨️ Slash-Befehle

| Befehl | Funktion |
| :--- | :--- |
| `/rf` oder `/rankforge` | Öffnet / schließt die grafische Benutzeroberfläche |
| `/rf update` | Erzwingt eine sofortige Überprüfung und Aktualisierung aller Makros |
| `/rf debug` | Schaltet den Debug-Modus (automatisches Öffnen nach Reload/Login) um |
| `/rf test` | Führt die integrierte Unit-Test-Suite aus |
| `/rf help` | Zeigt eine Übersicht aller verfügbaren Befehle im Chat an |

---

## 📁 Installation & Multi-Client Softlinks

RankForge ist über Verzeichnis-Junctions (Softlinks) direkt verknüpft mit:
- `D:\Blizzard\World of Warcraft\_forever_\Interface\AddOns\RankForge`
- `D:\Blizzard\World of Warcraft\_classic_era_\Interface\AddOns\RankForge`
- `D:\Blizzard\World of Warcraft\_anniversary_\Interface\AddOns\RankForge` (TBC 2.5.6)

Jede Änderung im Entwicklungsordner ist somit **ohne Kopieren sofort in allen Clients aktiv**!
