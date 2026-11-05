# RankForge (DRM) - Downranking Makro Schmiede

**RankForge** ist ein hochflexibles, intelligentes WoW-Addon zur automatischen Erstellung, Optimierung und Verwaltung von Downranking-Makros für Heiler und Caster in **WoW Forever (Client 1.60.1 / 3.3.5a)**, **Classic Era / SoD / Hardcore** und **TBC Era**.

---

## ✨ Features

### 🌍 Automatische Sprachanpassung & Client-Locale-Erkennung
- **Universelle Zauber-IDs:** RankForge speichert und verknüpft Zauber intern über deren universelle **`spellID`**.
- **Dynamische Übersetzung:** Wechselst du zwischen deutschem und englischem Spielclient (oder spielst auf internationalen Realms), passt RankForge die Makros im Hintergrund **vollautomatisch an deine aktive Spielsprache** an:
  - Auf deutschem Client: `/cast Blitzheilung(Rang 1)`
  - Auf englischem Client: `/cast Flash Heal(Rank 1)`
- **Aktionsleisten-Schutz:** Makronamen (`DR_FlashHeal`, `DR_Renew`, etc.) bleiben unverändert stabil – deine Aktionsleisten verlieren **niemals** ihre Belegung!
- **Klassenübergreifender Zauberkatalog:** Integrierter Übersetzungskatalog für alle 9 Klassen (Priester, Magier, Hexenmeister, Druide, Paladin, Schamane, Jäger, Schurke, Krieger).
- **Internationales Profil-Sharing:** Importiere Makro-Profile von internationalen Spielern oder Streamern – RankForge übersetzt sie sofort für deinen Client.

### 🎯 Dynamisches Downranking & Automatische Synchronisation
- **Relative Ränge:** Weise Modifikatoren (`nomod`, `Shift`, `Ctrl`, `Alt`, `Shift+Ctrl`, etc.) relative Ränge zu (`Max`, `Max - 1`, `Max - 2`, etc.) oder alternative Zauber.
- **Vollautomatisches Update:** Lernst du beim Lehrer einen neuen Rang, aktualisiert RankForge im Hintergrund **automatisch alle Makros** auf deinen Aktionsleisten.
- **Alternative Zauber:** Beliebige Tastenbelegungen können mit alternativen Zaubern belegt werden (z. B. nomod = Große Heilung, Shift = Blitzheilung, Alt = Machtwort: Schild).
- **Fallback-Einstellung:** Wähle pro Makro, ob bei noch nicht erlernten Rängen die Taste weggelassen oder vorübergehend **Rang 1 als Fallback** genutzt wird.

### 💡 Intelligente Tooltip-Steuerung (Smart `#showtooltip`)
- **Dynamische Tooltips:** Bei reinen Zauber-Makros wird ein schlankes `#showtooltip` ohne Zaubernamen generiert. WoW aktualisiert dadurch Tooltip und Icon **live auf deiner Leiste**, sobald du <kbd>Shift</kbd>, <kbd>Alt</kbd> oder <kbd>Strg</kbd> gedrückt hältst!
- **Zeichenersparnis:** Spart bis zu **15–25 Zeichen** im 255-Zeichen-Limit ein.
- **Utility-Schutz:** Sobald Vorab-Befehle wie `/startattack`, Begleiter-Angriffe oder Schmuckstücke aktiv sind, setzt RankForge automatisch den Zaubernamen hinter `#showtooltip`, damit WoW nicht versehentlich das Schwert- oder Schmuckstück-Icon anzeigt.

### ⚡ Downranking-Effizienz-Engine & Sweet-Spot (WoW Forever)
- **Zaubermacht- & Proc-Berechnung:** Berücksichtigt Downranking-Strafen (Spell Power Penalty) und Proc-Chancen:
  - 🟢 **Grün (100% Effizienz):** Zauberstufe $\ge$ Charakterstufe - 18 (volle Zaubermacht-Skalierung).
  - 🟡 **Gelb (Moderate Reduktion):** Zauberstufe $\ge 20$, aber unterhalb der vollen Skalierungsgrenze.
  - 🔴 **Rot (Starke Reduktion):** Pre-Level-20-Abzüge & minimierte Effekt- und Proc-Chancen (z. B. Rang-1-Spam).
- **Sweet-Spot-Erkennung:** Markiert automatisch den manaschonendsten Rang, der noch den vollen 100% Zaubermacht-Bonus erhält.

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
- **Aus dem Zauberbuch:** Ziehe einen Zauber direkt aus deinem Zauberbuch auf das Icon **oder** in das Eingabefeld (unterstützt moderne `C_SpellBook`-APIs, Classic-Slots und Aktionsleisten ohne ID-Kollisionen).
- **Aus der Makro-Liste auf die Aktionsleiste:** Klicke ein Makro in der linken Liste an und ziehe es direkt mit gedrückter Maustaste auf deine Aktionsleiste.
- **Vorschau-Icon:** Ziehe alternativ das große Vorschau-Icon auf deine Leiste.

### 🛡️ Sicherheit, Charakter-Filter & Profile
- **Charakterspezifische Filterung:** Mit der Checkbox `[x] Nur dieser Charakter` werden nur Makros angezeigt, die zu deinem aktuellen Charakter bzw. deiner Klasse gehören. Allgemeine Makros im Account-Tab bleiben für alle sichtbar.
- **Standard-Speicherort:** Neue Makros werden standardmäßig im **charakterspezifischen Tab (18 Slots)** angelegt, um die 120 allgemeinen Account-Slots nicht zu überfüllen.
- **Auto-Recovery:** Erkennt bestehende `DR_`-Makros aus dem nativen WoW-Cache und stellt sie automatisch wieder her.
- **Debug-Modus (Auto-Öffnen):** Über den Schalter `Debug (Auto-Öffnen)` in der Titelleiste oder via `/rf debug` öffnet sich RankForge nach jedem `/reload` oder Login automatisch.
- **Kampf-Schutz (`InCombatLockdown`):** Verhindert UI-Fehler oder Taint im Kampf. Änderungen und Updates werden bei Kampfende (`PLAYER_REGEN_ENABLED`) sicher angewendet.
- **Base64 Profil-System:** Importiere und exportiere Makro-Sets für Twinks oder zum Teilen mit Gildenmitgliedern.

---

## ⌨️ Slash-Befehle

| Befehl | Funktion |
| :--- | :--- |
| `/rf` oder `/rankforge` | Öffnet / schließt die grafische Benutzeroberfläche |
| `/rf update` oder `/rf sync` | Erzwingt eine sofortige Überprüfung und Aktualisierung aller Makros |
| `/rf debug` | Schaltet den Debug-Modus (automatisches Öffnen nach Reload/Login) um |
| `/rf test` | Führt die 37 automatisierten Unit-Tests aus und öffnet das kopierbare Bericht-Fenster |
| `/rf help` | Zeigt eine Übersicht aller verfügbaren Befehle im Chat an |

---

## 🧪 Integrierte Test-Suite (`/rf test`)

RankForge verfügt über eine vollständige automatisierte Test-Suite mit **37 Unit- & Integrationstests**:
- **Kopierbarer Test-Report:** Öffnet ein Dialogfenster mit <kbd>Strg</kbd>+<kbd>C</kbd> zum einfachen Kopieren von Testergebnissen.
- **SavedVariables-Export:** Speichert Testberichte in `SavedVariables/RankForge.lua` zur externen Prüfung.
- **Test-Isolierung:** Benutzermakros werden vor Testläufen gesichert und danach verlustfrei wiederhergestellt.

---

## 📁 Installation & Multi-Client Softlinks

RankForge ist über Verzeichnis-Junctions (Softlinks) direkt verknüpft mit:
- `D:\Blizzard\World of Warcraft\_forever_\Interface\AddOns\RankForge` (Client 1.60.1 / Modern Classic Engine)
- `D:\Blizzard\World of Warcraft\_classic_era_\Interface\AddOns\RankForge`
- `D:\Blizzard\World of Warcraft\_anniversary_\Interface\AddOns\RankForge`

Jede Änderung im Entwicklungsordner ist somit **ohne Kopieren sofort in allen Clients aktiv**!
