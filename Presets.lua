--[[
    RankForge - Presets.lua
    Pre-configured macro templates for healing and utility spells.
    Uses SpellIDs for full multi-language client compatibility.
]]

local addonName, RF = ...

RF.PresetSpells = {
    -- Priest
    PRIEST = {
        {
            name = "Renew",
            spellID = 139, -- Renew / Erneuerung
            macroName = "DR_Renew",
            targetHelp = true,
            fallbackMode = "omit",
            modifiers = {
                { key = "shift_ctrl", enabled = false, mode = "relative", rankOffset = 3 },
                { key = "shift_alt",  enabled = false, mode = "relative", rankOffset = 4 },
                { key = "ctrl_alt",   enabled = false, mode = "relative", rankOffset = 5 },
                { key = "shift",      enabled = true,  mode = "relative", rankOffset = 1 },
                { key = "ctrl",       enabled = false, mode = "relative", rankOffset = 2 },
                { key = "alt",        enabled = true,  mode = "relative", rankOffset = 2 },
                { key = "nomod",      enabled = true,  mode = "relative", rankOffset = 0 },
            }
        },
        {
            name = "Flash Heal",
            spellID = 2061, -- Flash Heal / Blitzheilung
            macroName = "DR_FlashHeal",
            targetHelp = true,
            fallbackMode = "omit",
            modifiers = {
                { key = "shift_ctrl", enabled = false, mode = "relative", rankOffset = 3 },
                { key = "shift_alt",  enabled = false, mode = "relative", rankOffset = 4 },
                { key = "ctrl_alt",   enabled = false, mode = "relative", rankOffset = 5 },
                { key = "shift",      enabled = true,  mode = "relative", rankOffset = 1 },
                { key = "ctrl",       enabled = false, mode = "relative", rankOffset = 2 },
                { key = "alt",        enabled = true,  mode = "relative", rankOffset = 2 },
                { key = "nomod",      enabled = true,  mode = "relative", rankOffset = 0 },
            }
        },
        {
            name = "Greater Heal",
            spellID = 2060, -- Greater Heal / Große Heilung
            macroName = "DR_GreaterHeal",
            targetHelp = true,
            fallbackMode = "omit",
            modifiers = {
                { key = "shift_ctrl", enabled = false, mode = "relative", rankOffset = 3 },
                { key = "shift_alt",  enabled = false, mode = "relative", rankOffset = 4 },
                { key = "ctrl_alt",   enabled = false, mode = "relative", rankOffset = 5 },
                { key = "shift",      enabled = true,  mode = "relative", rankOffset = 1 },
                { key = "ctrl",       enabled = false, mode = "relative", rankOffset = 2 },
                { key = "alt",        enabled = true,  mode = "relative", rankOffset = 2 },
                { key = "nomod",      enabled = true,  mode = "relative", rankOffset = 0 },
            }
        },
        {
            name = "Power Word: Shield",
            spellID = 17, -- Power Word: Shield / Machtwort: Schild
            macroName = "DR_Shield",
            targetHelp = true,
            fallbackMode = "omit",
            modifiers = {
                { key = "shift_ctrl", enabled = false, mode = "relative", rankOffset = 2 },
                { key = "shift_alt",  enabled = false, mode = "relative", rankOffset = 3 },
                { key = "ctrl_alt",   enabled = false, mode = "relative", rankOffset = 4 },
                { key = "shift",      enabled = true,  mode = "relative", rankOffset = 1 },
                { key = "ctrl",       enabled = true,  mode = "relative", rankOffset = 2 },
                { key = "alt",        enabled = false, mode = "relative", rankOffset = 3 },
                { key = "nomod",      enabled = true,  mode = "relative", rankOffset = 0 },
            }
        },
    },

    -- Paladin
    PALADIN = {
        {
            name = "Holy Light",
            spellID = 635, -- Holy Light / Heiliges Licht
            macroName = "DR_HolyLight",
            targetHelp = true,
            fallbackMode = "omit",
            modifiers = {
                { key = "shift_ctrl", enabled = false, mode = "relative", rankOffset = 3 },
                { key = "shift_alt",  enabled = false, mode = "relative", rankOffset = 4 },
                { key = "ctrl_alt",   enabled = false, mode = "relative", rankOffset = 5 },
                { key = "shift",      enabled = true,  mode = "relative", rankOffset = 1 },
                { key = "ctrl",       enabled = false, mode = "relative", rankOffset = 2 },
                { key = "alt",        enabled = true,  mode = "relative", rankOffset = 2 },
                { key = "nomod",      enabled = true,  mode = "relative", rankOffset = 0 },
            }
        },
        {
            name = "Flash of Light",
            spellID = 19750, -- Flash of Light / Lichtblitz
            macroName = "DR_FlashOfLight",
            targetHelp = true,
            fallbackMode = "omit",
            modifiers = {
                { key = "shift_ctrl", enabled = false, mode = "relative", rankOffset = 2 },
                { key = "shift_alt",  enabled = false, mode = "relative", rankOffset = 3 },
                { key = "ctrl_alt",   enabled = false, mode = "relative", rankOffset = 4 },
                { key = "shift",      enabled = true,  mode = "relative", rankOffset = 1 },
                { key = "ctrl",       enabled = true,  mode = "relative", rankOffset = 2 },
                { key = "alt",        enabled = false, mode = "relative", rankOffset = 3 },
                { key = "nomod",      enabled = true,  mode = "relative", rankOffset = 0 },
            }
        },
    },

    -- Druid
    DRUID = {
        {
            name = "Healing Touch",
            spellID = 5185, -- Healing Touch / Heilende Berührung
            macroName = "DR_HealingTouch",
            targetHelp = true,
            fallbackMode = "omit",
            modifiers = {
                { key = "shift_ctrl", enabled = false, mode = "relative", rankOffset = 3 },
                { key = "shift_alt",  enabled = false, mode = "relative", rankOffset = 4 },
                { key = "ctrl_alt",   enabled = false, mode = "relative", rankOffset = 5 },
                { key = "shift",      enabled = true,  mode = "relative", rankOffset = 1 },
                { key = "ctrl",       enabled = false, mode = "relative", rankOffset = 2 },
                { key = "alt",        enabled = true,  mode = "relative", rankOffset = 2 },
                { key = "nomod",      enabled = true,  mode = "relative", rankOffset = 0 },
            }
        },
        {
            name = "Regrowth",
            spellID = 8936, -- Regrowth / Nachwachsen
            macroName = "DR_Regrowth",
            targetHelp = true,
            fallbackMode = "omit",
            modifiers = {
                { key = "shift_ctrl", enabled = false, mode = "relative", rankOffset = 3 },
                { key = "shift_alt",  enabled = false, mode = "relative", rankOffset = 4 },
                { key = "ctrl_alt",   enabled = false, mode = "relative", rankOffset = 5 },
                { key = "shift",      enabled = true,  mode = "relative", rankOffset = 1 },
                { key = "ctrl",       enabled = false, mode = "relative", rankOffset = 2 },
                { key = "alt",        enabled = true,  mode = "relative", rankOffset = 2 },
                { key = "nomod",      enabled = true,  mode = "relative", rankOffset = 0 },
            }
        },
        {
            name = "Rejuvenation",
            spellID = 774, -- Rejuvenation / Verjüngung
            macroName = "DR_Rejuvenation",
            targetHelp = true,
            fallbackMode = "omit",
            modifiers = {
                { key = "shift_ctrl", enabled = false, mode = "relative", rankOffset = 3 },
                { key = "shift_alt",  enabled = false, mode = "relative", rankOffset = 4 },
                { key = "ctrl_alt",   enabled = false, mode = "relative", rankOffset = 5 },
                { key = "shift",      enabled = true,  mode = "relative", rankOffset = 1 },
                { key = "ctrl",       enabled = false, mode = "relative", rankOffset = 2 },
                { key = "alt",        enabled = true,  mode = "relative", rankOffset = 2 },
                { key = "nomod",      enabled = true,  mode = "relative", rankOffset = 0 },
            }
        },
    },

    -- Shaman
    SHAMAN = {
        {
            name = "Chain Heal",
            spellID = 1064, -- Chain Heal / Kettenheilung
            macroName = "DR_ChainHeal",
            targetHelp = true,
            fallbackMode = "omit",
            modifiers = {
                { key = "shift_ctrl", enabled = false, mode = "relative", rankOffset = 2 },
                { key = "shift_alt",  enabled = false, mode = "relative", rankOffset = 3 },
                { key = "ctrl_alt",   enabled = false, mode = "relative", rankOffset = 4 },
                { key = "shift",      enabled = true,  mode = "relative", rankOffset = 1 },
                { key = "ctrl",       enabled = true,  mode = "relative", rankOffset = 2 },
                { key = "alt",        enabled = false, mode = "relative", rankOffset = 3 },
                { key = "nomod",      enabled = true,  mode = "relative", rankOffset = 0 },
            }
        },
        {
            name = "Healing Wave",
            spellID = 331, -- Healing Wave / Welle der Heilung
            macroName = "DR_HealingWave",
            targetHelp = true,
            fallbackMode = "omit",
            modifiers = {
                { key = "shift_ctrl", enabled = false, mode = "relative", rankOffset = 3 },
                { key = "shift_alt",  enabled = false, mode = "relative", rankOffset = 4 },
                { key = "ctrl_alt",   enabled = false, mode = "relative", rankOffset = 5 },
                { key = "shift",      enabled = true,  mode = "relative", rankOffset = 1 },
                { key = "ctrl",       enabled = false, mode = "relative", rankOffset = 2 },
                { key = "alt",        enabled = true,  mode = "relative", rankOffset = 2 },
                { key = "nomod",      enabled = true,  mode = "relative", rankOffset = 0 },
            }
        },
    }
}

function RF:GetPresetsForClass(classFileName)
    local presets = RF.PresetSpells[classFileName] or {}
    local result = {}
    for _, p in ipairs(presets) do
        local spellName = nil
        if p.spellID then
            local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(p.spellID)
            if info and info.name then
                spellName = info.name
            elseif GetSpellInfo then
                spellName = GetSpellInfo(p.spellID)
            end
        end
        spellName = spellName or p.name
        
        -- Deep copy preset definition
        local copy = {
            name = spellName,
            spellName = spellName,
            macroName = p.macroName,
            targetMouseover = true,
            targetMouseoverHelp = true,
            targetMouseoverHarm = false,
            targetMouseoverNodead = true,
            targetFocus = false,
            targetFocusHelp = true,
            targetFocusHarm = false,
            targetFocusNodead = true,
            targetToT = false,
            targetToTHelp = true,
            targetToTHarm = false,
            targetToTNodead = true,
            targetSelfcast = false,
            customTarget = "",
            isAccount = true,
            fallbackMode = p.fallbackMode or "omit",
            modifiers = {}
        }
        for _, mod in ipairs(p.modifiers) do
            table.insert(copy.modifiers, {
                key = mod.key,
                enabled = mod.enabled,
                mode = mod.mode,
                rankOffset = mod.rankOffset,
                customSpell = ""
            })
        end
        table.insert(result, copy)
    end
    return result
end
