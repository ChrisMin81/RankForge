--[[
    RankForge - Localization.lua
    Multi-language support: English (enUS/enGB default) and German (deDE)
]]

local addonName, RF = ...

local L = setmetatable({}, {
    __index = function(t, k)
        return rawget(t, k) or k
    end
})
RF.L = L

local locale = GetLocale()

--------------------------------------------------------------------------------
-- English (Default fallback for enUS, enGB and all other locales)
--------------------------------------------------------------------------------
L["ADDON_TITLE"] = "RankForge"
L["SLASH_HELP_1"] = "|cff00ccffRankForge|r commands:"
L["SLASH_HELP_2"] = "/rf or /rankforge - Toggle the user interface"
L["SLASH_HELP_3"] = "/rf update - Immediately update all configured macros"
L["SLASH_HELP_TEST"] = "/rf test - Run automated test suite (Unit-Tests)"
L["SLASH_HELP_4"] = "/rf help - Show this help message"

L["MACRO_SYNC_SUCCESS"] = "|cff00ccffRankForge:|r Macro '|cffffd200%s|r' successfully updated."
L["MACRO_CREATED"] = "|cff00ccffRankForge:|r Macro '|cffffd200%s|r' created."
L["MACRO_DELETED"] = "|cff00ccffRankForge:|r Macro '|cffffd200%s|r' deleted."
L["MACRO_LIMIT_ACCOUNT_FULL"] = "|cffff3333RankForge Warning:|r General macro slots are full (120/120)!"
L["MACRO_LIMIT_CHAR_FULL"] = "|cffff3333RankForge Warning:|r Character-specific macro slots are full (18/18)!"
L["COMBAT_LOCKDOWN_QUEUED"] = "|cffffcc00RankForge:|r Macro update delayed in combat. Will execute after combat ends."
L["COMBAT_LOCKDOWN_EXECUTED"] = "|cff00ccffRankForge:|r Executed queued updates after combat (%d macros updated)."

L["UI_TITLE"] = "RankForge - Downranking Macro Forge"
L["UI_CONFIGURED_MACROS"] = "Configured Macros"
L["UI_NEW_MACRO"] = "+ New Macro"
L["UI_DELETE_MACRO"] = "Delete"
L["UI_SAVE_MACRO"] = "Save & Create"
L["UI_PRESETS_BTN"] = "Presets..."
L["UI_EXPORT_BTN"] = "Profile Import / Export"
L["UI_MACRO_NAME"] = "Macro Name:"
L["UI_SPELL_NAME"] = "Base Spell:"
L["UI_DROP_SPELL_HERE"] = "Drag spell here\n(from spellbook)"
L["UI_SPELL_SELECT_DROPDOWN"] = "Or select from list:"
L["UI_STORAGE_LOCATION"] = "Storage Location:"
L["UI_STORAGE_ACCOUNT"] = "General (Account, 120 Slots)"
L["UI_STORAGE_CHAR"] = "Character (18 Slots)"
L["UI_FALLBACK_MODE"] = "When rank not yet learned:"
L["UI_FALLBACK_OMIT"] = "Omit modifier until learned"
L["UI_FALLBACK_RANK1"] = "Use Rank 1 as fallback"

L["UI_TARGETING_HEADER"] = "Targeting Conditions"
L["UI_TARGET_MOUSEOVER"] = "Mouseover (@mouseover)"
L["UI_TARGET_MOUSEOVER_STRICT"] = "Mouseover only if exists"
L["UI_TARGET_FOCUS"] = "Focus Target (@focus)"
L["UI_TARGET_TARGETOFTARGET"] = "Target of Target (@targettarget)"
L["UI_TARGET_SELFCAST"] = "Auto-Selfcast Fallback ([@player])"
L["UI_COND_HELP"] = "help"
L["UI_COND_HARM"] = "harm"
L["UI_COND_NODEAD"] = "nodead"
L["UI_UTILITY_HEADER"] = "Pre-Cast Utility Actions"
L["UI_USE_TRINKET_1"] = "Trinket 1 (/use 13)"
L["UI_USE_TRINKET_2"] = "Trinket 2 (/use 14)"
L["UI_USE_RACIAL"] = "Racial Ability (Berserking etc.)"
L["UI_PRECAST_CUSTOM"] = "Extra Commands (e.g. /cast Inner Focus, /use Potion, /click Button):"
L["UI_TARGET_CUSTOM"] = "Custom Targeting Condition:"

L["UI_MODIFIERS_HEADER"] = "Keybinds, Ranks & Targeting Matrix (Change order with arrow buttons)"
L["UI_RESET_SORT_BTN"] = "Default Order"
L["UI_RESET_SORT_TOOLTIP"] = "Reset modifiers to recommended priority order (dual-keys first, nomod last)."
L["UI_GRID_MOD"] = "Key / Mod"
L["UI_GRID_RANK"] = "Rank"
L["UI_GRID_MO"] = "MO"
L["UI_GRID_FOCUS"] = "Focus"
L["UI_GRID_TOT"] = "ToT"
L["UI_GRID_SELF"] = "Self"
L["UI_GRID_FILTER"] = "Filter (help/nodead)"
L["UI_GRID_ALTSPELL"] = "Alternative Spell"
L["UI_MOD_NOMOD"] = "No Modifier (nomod)"
L["UI_MOD_SHIFT"] = "Shift"
L["UI_MOD_CTRL"] = "Ctrl"
L["UI_MOD_ALT"] = "Alt"
L["UI_MOD_SHIFT_CTRL"] = "Shift + Ctrl"
L["UI_MOD_SHIFT_ALT"] = "Shift + Alt"
L["UI_MOD_CTRL_ALT"] = "Ctrl + Alt"

L["UI_PREVIEW_HEADER"] = "Macro Preview (Draggable to Action Bar):"
L["UI_CHAR_COUNT"] = "%d / 255 Characters"
L["UI_CHAR_COUNT_WARNING"] = "|cffff3333Warning: Macro exceeds 255 characters!|r"
L["UI_DRAG_HINT"] = "Tip: Drag the icon directly onto your action bar!"
L["UI_COPY_HINT"] = "|cff888888(Click = Select all for Ctrl+C)|r"
L["UI_SLOT_STATUS"] = "Gen.: %d/%d | Char: %d/%d"
L["UI_DEFAULT_MACRO_NAME"] = "DR_New"

L["CONFIRM_DELETE_TITLE"] = "Delete Macro?"
L["CONFIRM_DELETE_TEXT"] = "Do you really want to delete the macro '|cffffd200%s|r'?\nIt will also be removed from your WoW macro window."
L["CONFIRM_YES"] = "Yes, delete"
L["CONFIRM_NO"] = "Cancel"

L["PRESETS_TITLE"] = "Select Preset"
L["PRESETS_APPLY"] = "Apply Preset"
L["PRESETS_CLOSE"] = "Close"

L["PROFILE_TITLE"] = "Profile Import / Export"
L["PROFILE_EXPORT_HINT"] = "Copy this Base64 string (Ctrl+C) to share your profile:"
L["PROFILE_IMPORT_HINT"] = "Paste a profile string here (Ctrl+V) and click Import:"
L["PROFILE_IMPORT_BTN"] = "Import Profile"
L["PROFILE_COPY_BTN"] = "Copy to Clipboard"
L["PROFILE_IMPORT_SUCCESS"] = "|cff00ccffRankForge:|r Profile successfully imported (%d macros)!"
L["PROFILE_IMPORT_INVALID"] = "|cffff3333RankForge Error:|r Invalid profile string!"

L["MINIMAP_TOOLTIP_TITLE"] = "|cff00ccffRankForge|r"
L["MINIMAP_TOOLTIP_L1"] = "Left Click: Open / Close window"
L["MINIMAP_TOOLTIP_L2"] = "Right Click: Update all macros"
L["MINIMAP_TOOLTIP_DRAG"] = "Drag: Move minimap button"

L["RANK_WORD"] = "Rank"

--------------------------------------------------------------------------------
-- German (deDE) Localization
--------------------------------------------------------------------------------
if locale == "deDE" then
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
    L["UI_MOD_CTRL"] = "Strg / Ctrl"
    L["UI_MOD_ALT"] = "Alt"
    L["UI_MOD_SHIFT_CTRL"] = "Shift + Strg"
    L["UI_MOD_SHIFT_ALT"] = "Shift + Alt"
    L["UI_MOD_CTRL_ALT"] = "Strg + Alt"

    L["UI_PREVIEW_HEADER"] = "Makro-Vorschau (Auf Leiste ziehbar):"
    L["UI_CHAR_COUNT"] = "%d / 255 Zeichen"
    L["UI_CHAR_COUNT_WARNING"] = "|cffff3333Warnung: Makro überschreitet 255 Zeichen!|r"
    L["UI_DRAG_HINT"] = "Tipp: Ziehe das Icon direkt auf deine Aktionsleiste!"
    L["UI_COPY_HINT"] = "|cff888888(Klick = Alles markieren für Strg+C)|r"
    L["UI_SLOT_STATUS"] = "Allg.: %d/%d | Char: %d/%d"
    L["UI_DEFAULT_MACRO_NAME"] = "DR_Neu"

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

    L["RANK_WORD"] = "Rang"
end
