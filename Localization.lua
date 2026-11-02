--[[
    RankForge - Localization.lua
    Multi-language support (deDE, enUS fallback)
]]

local addonName, RF = ...

local L = setmetatable({}, {
    __index = function(t, k)
        return rawget(t, k) or k
    end
})
RF.L = L

local locale = GetLocale()

-- English (Default fallback)
L["ADDON_TITLE"] = "RankForge"
L["SLASH_HELP_1"] = "|cff00ccffRankForge|r Befehle:"
L["SLASH_HELP_2"] = "/rf oder /rankforge - Öffnet die Benutzeroberfläche"
L["SLASH_HELP_3"] = "/rf update - Aktualisiert alle konfigurierten Makros sofort"
L["SLASH_HELP_TEST"] = "/rf test - Führt die automatische Test-Suite (Unit-Tests) aus"
L["SLASH_HELP_4"] = "/rf help - Zeigt diese Hilfe an"

L["MACRO_SYNC_SUCCESS"] = "|cff00ccffRankForge:|r Makro '|cffffd200%s|r' erfolgreich aktualisiert."
L["MACRO_CREATED"] = "|cff00ccffRankForge:|r Makro '|cffffd200%s|r' wurde neu erstellt."
L["MACRO_DELETED"] = "|cff00ccffRankForge:|r Makro '|cffffd200%s|r' wurde gelöscht."
L["MACRO_LIMIT_ACCOUNT_FULL"] = "|cffff3333RankForge Warnung:|r Allgemeine Makro-Slots sind voll (120/120)!"
L["MACRO_LIMIT_CHAR_FULL"] = "|cffff3333RankForge Warnung:|r Charakterspezifische Makro-Slots sind voll (18/18)!"
L["COMBAT_LOCKDOWN_QUEUED"] = "|cffffcc00RankForge:|r Makro-Aktualisierung im Kampf verzögert. Wird nach Kampfende ausgeführt."
L["COMBAT_LOCKDOWN_EXECUTED"] = "|cff00ccffRankForge:|r Warteschlange nach dem Kampf verarbeitet (%d Makros aktualisiert)."

L["UI_TITLE"] = "RankForge - Downranking Makro Schmiede"
L["UI_CONFIGURED_MACROS"] = "Konfigurierte Makros"
L["UI_NEW_MACRO"] = "+ Neues Makro"
L["UI_DELETE_MACRO"] = "Löschen"
L["UI_SAVE_MACRO"] = "Speichern & Erstellen"
L["UI_PRESETS_BTN"] = "Vorlagen..."
L["UI_EXPORT_BTN"] = "Profil Import / Export"
L["UI_MACRO_NAME"] = "Makro-Name:"
L["UI_SPELL_NAME"] = "Basis-Zauber:"
L["UI_DROP_SPELL_HERE"] = "Zauber hierher ziehen\n(aus Zauberbuch)"
L["UI_SPELL_SELECT_DROPDOWN"] = "Oder aus Liste wählen:"
L["UI_STORAGE_LOCATION"] = "Speicherort:"
L["UI_STORAGE_ACCOUNT"] = "Allgemein (Account, 120 Slots)"
L["UI_STORAGE_CHAR"] = "Charakter (18 Slots)"
L["UI_FALLBACK_MODE"] = "Wenn Rang noch nicht gelernt:"
L["UI_FALLBACK_OMIT"] = "Modifikator weglassen bis gelernt"
L["UI_FALLBACK_RANK1"] = "Rang 1 als Fallback nutzen"

L["UI_TARGETING_HEADER"] = "Zielbedingungen (Targeting)"
L["UI_TARGET_MOUSEOVER"] = "Mouseover (@mouseover)"
L["UI_TARGET_MOUSEOVER_STRICT"] = "Mouseover nur wenn existiert"
L["UI_TARGET_FOCUS"] = "Fokus-Ziel (@focus)"
L["UI_TARGET_TARGETOFTARGET"] = "Ziel des Ziels (@targettarget)"
L["UI_TARGET_SELFCAST"] = "Auto-Selfcast Fallback ([@player])"
L["UI_COND_HELP"] = "help"
L["UI_COND_HARM"] = "harm"
L["UI_COND_NODEAD"] = "nodead"
L["UI_UTILITY_HEADER"] = "Zusatz-Aktionen vor dem Zauber (Pre-Cast Utility)"
L["UI_USE_TRINKET_1"] = "Trinket 1 (/use 13)"
L["UI_USE_TRINKET_2"] = "Trinket 2 (/use 14)"
L["UI_USE_RACIAL"] = "Volksfähigkeit (Berserking etc.)"
L["UI_PRECAST_CUSTOM"] = "Zusätzliche Befehle (z. B. /cast Innerer Fokus, /use Trank, /click Button):"
L["UI_TARGET_CUSTOM"] = "Benutzerdefinierte Zielbedingung:"

L["UI_MODIFIERS_HEADER"] = "Tastenbelegung, Ränge & Ziel-Matrix (Reihenfolge mit Pfeiltasten änderbar)"
L["UI_RESET_SORT_BTN"] = "Standard-Reihenfolge"
L["UI_RESET_SORT_TOOLTIP"] = "Setzt die Modifikatoren auf die empfohlene Reihenfolge zurück (Doppel-Tasten zuerst, nomod zuletzt)."
L["UI_GRID_MOD"] = "Taste / Mod"
L["UI_GRID_RANK"] = "Rang"
L["UI_GRID_MO"] = "MO"
L["UI_GRID_FOCUS"] = "Fokus"
L["UI_GRID_TOT"] = "ToT"
L["UI_GRID_SELF"] = "Selbst"
L["UI_GRID_FILTER"] = "Filter (help/nodead)"
L["UI_GRID_ALTSPELL"] = "Alternativer Zauber"
L["UI_MOD_NOMOD"] = "Kein Modifikator (nomod)"
L["UI_MOD_SHIFT"] = "Shift"
L["UI_MOD_CTRL"] = "Ctrl / Strg"
L["UI_MOD_ALT"] = "Alt"
L["UI_MOD_SHIFT_CTRL"] = "Shift + Ctrl"
L["UI_MOD_SHIFT_ALT"] = "Shift + Alt"
L["UI_MOD_CTRL_ALT"] = "Ctrl + Alt"

L["UI_PREVIEW_HEADER"] = "Makro-Vorschau (Auf Leiste ziehbar):"
L["UI_CHAR_COUNT"] = "%d / 255 Zeichen"
L["UI_CHAR_COUNT_WARNING"] = "|cffff3333Warnung: Makro überschreitet 255 Zeichen!|r"
L["UI_DRAG_HINT"] = "Tipp: Ziehe das Icon direkt auf deine Aktionsleiste!"

L["CONFIRM_DELETE_TITLE"] = "Makro wirklich löschen?"
L["CONFIRM_DELETE_TEXT"] = "Möchtest du das Makro '|cffffd200%s|r' wirklich löschen?\nEs wird auch aus deinem WoW-Makrofenster entfernt."
L["CONFIRM_YES"] = "Ja, löschen"
L["CONFIRM_NO"] = "Abbrechen"

L["PRESETS_TITLE"] = "Vorlagen auswählen"
L["PRESETS_APPLY"] = "Vorlage anwenden"
L["PRESETS_CLOSE"] = "Schließen"

L["PROFILE_TITLE"] = "Profil Import / Export"
L["PROFILE_EXPORT_HINT"] = "Kopiere diesen Base64-String (Strg+C), um dein Profil zu teilen:"
L["PROFILE_IMPORT_HINT"] = "Füge hier einen Profil-String ein (Strg+V) und klicke auf Importieren:"
L["PROFILE_IMPORT_BTN"] = "Profil importieren"
L["PROFILE_COPY_BTN"] = "In Zwischenablage kopieren"
L["PROFILE_IMPORT_SUCCESS"] = "|cff00ccffRankForge:|r Profil erfolgreich importiert (%d Makros)!"
L["PROFILE_IMPORT_INVALID"] = "|cffff3333RankForge Fehler:|r Ungültiger Profil-String!"

L["MINIMAP_TOOLTIP_TITLE"] = "|cff00ccffRankForge|r"
L["MINIMAP_TOOLTIP_L1"] = "Linksklick: Fenster öffnen / schließen"
L["MINIMAP_TOOLTIP_L2"] = "Rechtsklick: Alle Makros aktualisieren"
L["MINIMAP_TOOLTIP_DRAG"] = "Ziehen: Symbol um Minimap bewegen"

-- German adjustments (if German locale)
if locale == "deDE" then
    L["RANK_WORD"] = "Rang"
else
    L["RANK_WORD"] = "Rank"
end
