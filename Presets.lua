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
    },

    -- Hunter
    HUNTER = {
        {
            name = "Falke beschwören",
            spellID = 1293526, -- Falke beschwören / Summon Hawk (WoW Forever Custom Spell)
            macroName = "DR_FalkeBeschwoeren",
            targetHelp = false,
            fallbackMode = "omit",
            startAttack = true,
            petAttack = true,
            modifiers = {
                { key = "shift_ctrl", enabled = false, mode = "relative", rankOffset = 3 },
                { key = "shift_alt",  enabled = false, mode = "relative", rankOffset = 4 },
                { key = "ctrl_alt",   enabled = false, mode = "relative", rankOffset = 5 },
                { key = "shift",      enabled = true,  mode = "relative", rankOffset = 1 },
                { key = "ctrl",       enabled = false, mode = "relative", rankOffset = 2 },
                { key = "alt",        enabled = false, mode = "relative", rankOffset = 2 },
                { key = "nomod",      enabled = true,  mode = "relative", rankOffset = 0 },
            }
        },
        {
            name = "Aimed Shot",
            spellID = 19434, -- Aimed Shot / Gezielter Schuss
            macroName = "DR_AimedShot",
            targetHelp = false,
            fallbackMode = "omit",
            startAttack = true,
            petAttack = true,
            modifiers = {
                { key = "shift_ctrl", enabled = false, mode = "relative", rankOffset = 3 },
                { key = "shift_alt",  enabled = false, mode = "relative", rankOffset = 4 },
                { key = "ctrl_alt",   enabled = false, mode = "relative", rankOffset = 5 },
                { key = "shift",      enabled = true,  mode = "relative", rankOffset = 1 },
                { key = "ctrl",       enabled = false, mode = "relative", rankOffset = 2 },
                { key = "alt",        enabled = false, mode = "relative", rankOffset = 2 },
                { key = "nomod",      enabled = true,  mode = "relative", rankOffset = 0 },
            }
        },
        {
            name = "Multi-Shot",
            spellID = 2643, -- Multi-Shot / Mehrfachschuss
            macroName = "DR_MultiShot",
            targetHelp = false,
            fallbackMode = "omit",
            startAttack = true,
            petAttack = true,
            modifiers = {
                { key = "shift_ctrl", enabled = false, mode = "relative", rankOffset = 3 },
                { key = "shift_alt",  enabled = false, mode = "relative", rankOffset = 4 },
                { key = "ctrl_alt",   enabled = false, mode = "relative", rankOffset = 5 },
                { key = "shift",      enabled = true,  mode = "relative", rankOffset = 1 },
                { key = "ctrl",       enabled = false, mode = "relative", rankOffset = 2 },
                { key = "alt",        enabled = false, mode = "relative", rankOffset = 2 },
                { key = "nomod",      enabled = true,  mode = "relative", rankOffset = 0 },
            }
        },
        {
            name = "Serpent Sting",
            spellID = 1978, -- Serpent Sting / Schlangenbiss
            macroName = "DR_SerpentSting",
            targetHelp = false,
            fallbackMode = "omit",
            startAttack = true,
            petAttack = false,
            modifiers = {
                { key = "shift_ctrl", enabled = false, mode = "relative", rankOffset = 3 },
                { key = "shift_alt",  enabled = false, mode = "relative", rankOffset = 4 },
                { key = "ctrl_alt",   enabled = false, mode = "relative", rankOffset = 5 },
                { key = "shift",      enabled = true,  mode = "relative", rankOffset = 1 },
                { key = "ctrl",       enabled = false, mode = "relative", rankOffset = 2 },
                { key = "alt",        enabled = false, mode = "relative", rankOffset = 2 },
                { key = "nomod",      enabled = true,  mode = "relative", rankOffset = 0 },
            }
        },
        {
            name = "Mend Pet",
            spellID = 136, -- Mend Pet / Tier heilen
            macroName = "DR_MendPet",
            targetHelp = true,
            fallbackMode = "omit",
            startAttack = false,
            petAttack = false,
            modifiers = {
                { key = "shift_ctrl", enabled = false, mode = "relative", rankOffset = 3 },
                { key = "shift_alt",  enabled = false, mode = "relative", rankOffset = 4 },
                { key = "ctrl_alt",   enabled = false, mode = "relative", rankOffset = 5 },
                { key = "shift",      enabled = true,  mode = "relative", rankOffset = 1 },
                { key = "ctrl",       enabled = false, mode = "relative", rankOffset = 2 },
                { key = "alt",        enabled = false, mode = "relative", rankOffset = 2 },
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
        
        local isHelp = (p.targetHelp ~= false)
        local isHarm = not isHelp

        -- Deep copy preset definition
        local copy = {
            name = spellName,
            spellName = spellName,
            spellID = p.spellID,
            macroName = p.macroName,
            targetMouseover = true,
            targetMouseoverHelp = isHelp,
            targetMouseoverHarm = isHarm,
            targetMouseoverNodead = true,
            targetFocus = false,
            targetFocusHelp = isHelp,
            targetFocusHarm = isHarm,
            targetFocusNodead = true,
            targetToT = false,
            targetToTHelp = isHelp,
            targetToTHarm = isHarm,
            targetToTNodead = true,
            targetSelfcast = isHelp,
            customTarget = "",
            isAccount = true, -- Default to General (Account, 120 Slots)
            fallbackMode = p.fallbackMode or "omit",
            startAttack = p.startAttack or false,
            petAttack = p.petAttack or false,
            modifiers = {}
        }
        for _, mod in ipairs(p.modifiers) do
            table.insert(copy.modifiers, {
                key = mod.key,
                enabled = mod.enabled,
                mode = mod.mode,
                rankOffset = mod.rankOffset,
                customSpell = "",
                targetMouseover = true,
                targetTarget = true,
                targetFocus = false,
                targetToT = false,
                targetSelfcast = isHelp,
                isHelp = isHelp,
                isHarm = isHarm,
                isNodead = true
            })
        end
        table.insert(result, copy)
    end
    return result
end

--------------------------------------------------------------------------------
-- Cross-Language Spell ID Catalog
-- Maps English and German spell names (case-insensitive) to base Spell IDs.
-- Enables automatic translation of macro /cast lines across WoW client locales.
--------------------------------------------------------------------------------
RF.SpellCatalog = {
    -- Priest
    ["flash heal"] = 2061,
    ["blitzheilung"] = 2061,
    ["greater heal"] = 2060,
    ["große heilung"] = 2060,
    ["power word: shield"] = 17,
    ["machtwort: schild"] = 17,
    ["renew"] = 139,
    ["erneuerung"] = 139,
    ["heal"] = 2054,
    ["heilen"] = 2054,
    ["lesser heal"] = 2050,
    ["geringes heilen"] = 2050,
    ["prayer of healing"] = 596,
    ["gebet der heilung"] = 596,
    ["vampiric touch"] = 34914,
    ["vampirberührung"] = 34914,
    ["shadow word: pain"] = 589,
    ["schattenwort: schmerz"] = 589,
    ["mana burn"] = 8129,
    ["manabrand"] = 8129,
    ["mind blast"] = 8092,
    ["gedankenschlag"] = 8092,
    ["mind flay"] = 15407,
    ["gedankenschinden"] = 15407,
    ["shadowguard"] = 18137,
    ["schattengarde"] = 18137,
    ["inner fire"] = 588,
    ["inneres feuer"] = 588,
    ["vampiric embrace"] = 15286,
    ["vampirumarmung"] = 15286,
    ["holy nova"] = 15237,
    ["heilige nova"] = 15237,
    ["circle of healing"] = 34861,
    ["kreis der heilung"] = 34861,
    ["smite"] = 585,
    ["heilige pein"] = 585,
    ["holy fire"] = 14914,
    ["heiliges feuer"] = 14914,
    ["desperate prayer"] = 19236,
    ["verzweifeltes gebet"] = 19236,
    ["devouring plague"] = 2944,
    ["verschlingende seuche"] = 2944,
    ["power word: fortitude"] = 1243,
    ["machtwort: seelenstärke"] = 1243,
    ["shadow protection"] = 976,
    ["schattenschutz"] = 976,
    ["divine spirit"] = 14752,
    ["göttlicher wille"] = 14752,
    ["fear ward"] = 6346,
    ["furcht-zauberschutz"] = 6346,
    ["silence"] = 15487,
    ["stille"] = 15487,
    ["psychic scream"] = 8122,
    ["psychischer schrei"] = 8122,
    ["dispel magic"] = 527,
    ["magiebannung"] = 527,
    ["cure disease"] = 528,
    ["krankheit aufheben"] = 528,
    ["abolish disease"] = 552,
    ["krankheit heilen"] = 552,
    ["resurrect"] = 2006,
    ["auferstehung"] = 2006,
    ["fade"] = 586,
    ["verblassen"] = 586,
    ["shadowform"] = 15473,
    ["schattengestalt"] = 15473,

    -- Mage
    ["frostbolt"] = 116,
    ["frostblitz"] = 116,
    ["fireball"] = 133,
    ["feuerball"] = 133,
    ["arcane missiles"] = 5143,
    ["arkane geschosse"] = 5143,
    ["blizzard"] = 10,
    ["frost nova"] = 122,
    ["frostnova"] = 122,
    ["fire blast"] = 2136,
    ["feuerschlag"] = 2136,
    ["scorch"] = 2948,
    ["versengen"] = 2948,
    ["cone of cold"] = 120,
    ["kältekegel"] = 120,
    ["arcane explosion"] = 1449,
    ["arkane explosion"] = 1449,
    ["pyroblast"] = 11366,
    ["pyroschlag"] = 11366,
    ["flamestrike"] = 2120,
    ["flammenschlag"] = 2120,
    ["ice barrier"] = 11426,
    ["eisbarriere"] = 11426,
    ["mana shield"] = 1463,
    ["manaschild"] = 1463,
    ["arcane intellect"] = 1459,
    ["arkane intelligenz"] = 1459,
    ["ice armor"] = 7302,
    ["eisrüstung"] = 7302,
    ["frost armor"] = 168,
    ["frostrüstung"] = 168,
    ["mage armor"] = 6117,
    ["magische rüstung"] = 6117,
    ["counterspell"] = 2139,
    ["gegenzauber"] = 2139,
    ["blink"] = 1953,
    ["blinzeln"] = 1953,
    ["evocation"] = 12051,
    ["hervorrufung"] = 12051,

    -- Warlock
    ["corruption"] = 172,
    ["verderbnis"] = 172,
    ["shadow bolt"] = 686,
    ["schattenblitz"] = 686,
    ["immolate"] = 348,
    ["feuerbrand"] = 348,
    ["curse of agony"] = 980,
    ["fluch der pein"] = 980,
    ["siphon life"] = 18265,
    ["lebensentzug"] = 18265,
    ["drain life"] = 689,
    ["blutsauger"] = 689,
    ["drain soul"] = 1120,
    ["seelendieb"] = 1120,
    ["drain mana"] = 5138,
    ["manasauger"] = 5138,
    ["life tap"] = 1454,
    ["aderlass"] = 1454,
    ["hellfire"] = 1949,
    ["höllenfeuer"] = 1949,
    ["rain of fire"] = 5740,
    ["feuerregen"] = 5740,
    ["fear"] = 5782,
    ["furcht"] = 5782,
    ["howl of terror"] = 5484,
    ["schreckensgeheul"] = 5484,
    ["death coil"] = 6789,
    ["todesmantel"] = 6789,
    ["shadowburn"] = 17877,
    ["schattenbrand"] = 17877,
    ["demon armor"] = 706,
    ["dämonenrüstung"] = 706,
    ["fel armor"] = 28176,
    ["teufelsrüstung"] = 28176,
    ["health funnel"] = 755,
    ["lebenslinie"] = 755,

    -- Druid
    ["healing touch"] = 5185,
    ["heilende berührung"] = 5185,
    ["regrowth"] = 8936,
    ["nachwachsen"] = 8936,
    ["rejuvenation"] = 774,
    ["verjüngung"] = 774,
    ["moonfire"] = 8921,
    ["mondfeuer"] = 8921,
    ["wrath"] = 5176,
    ["zorn"] = 5176,
    ["starfire"] = 2912,
    ["sternenfeuer"] = 2912,
    ["tranquility"] = 740,
    ["gelassenheit"] = 740,
    ["swiftmend"] = 18562,
    ["rasche heilung"] = 18562,
    ["insect swarm"] = 5570,
    ["insektenschwarm"] = 5570,
    ["mark of the wild"] = 1126,
    ["mal der wildnis"] = 1126,
    ["thorns"] = 467,
    ["dornen"] = 467,
    ["entangling roots"] = 339,
    ["wucherwurzeln"] = 339,
    ["barkskin"] = 22812,
    ["baumrinde"] = 22812,
    ["innervate"] = 29166,
    ["anregen"] = 29166,

    -- Paladin
    ["holy light"] = 635,
    ["heiliges licht"] = 635,
    ["flash of light"] = 19750,
    ["lichtblitz"] = 19750,
    ["lay on hands"] = 633,
    ["handauflegung"] = 633,
    ["holy shock"] = 20473,
    ["heiliger schock"] = 20473,
    ["blessing of protection"] = 1022,
    ["segen des schutzes"] = 1022,
    ["blessing of might"] = 19740,
    ["segen der macht"] = 19740,
    ["blessing of wisdom"] = 19742,
    ["segen der weisheit"] = 19742,
    ["blessing of kings"] = 20217,
    ["segen der könige"] = 20217,
    ["blessing of freedom"] = 1044,
    ["segen der freiheit"] = 1044,
    ["consecration"] = 26573,
    ["weihe"] = 26573,
    ["hammer of wrath"] = 24275,
    ["hammer des zorns"] = 24275,
    ["judgement"] = 20271,
    ["richturteil"] = 20271,
    ["cleanse"] = 4987,
    ["reinigung"] = 4987,
    ["divine shield"] = 642,
    ["gottesschild"] = 642,

    -- Shaman
    ["healing wave"] = 331,
    ["welle der heilung"] = 331,
    ["lesser healing wave"] = 8004,
    ["geringe welle der heilung"] = 8004,
    ["chain heal"] = 1064,
    ["kettenheilung"] = 1064,
    ["lightning bolt"] = 403,
    ["blitzschlag"] = 403,
    ["chain lightning"] = 421,
    ["kettenblitzschlag"] = 421,
    ["earth shock"] = 8042,
    ["erdschock"] = 8042,
    ["flame shock"] = 8050,
    ["flammenschock"] = 8050,
    ["frost shock"] = 8056,
    ["frostschock"] = 8056,
    ["purge"] = 370,
    ["reinigen"] = 370,
    ["earth shield"] = 974,
    ["erdschild"] = 974,
    ["mana spring totem"] = 5675,
    ["totem der manaquelle"] = 5675,
    ["healing stream totem"] = 5394,
    ["totem des heilenden flusses"] = 5394,

    -- Hunter
    ["falke beschwören"] = 1293526,
    ["falke beschworen"] = 1293526,
    ["falke beschören"] = 1293526,
    ["summon hawk"] = 1293526,
    ["aimed shot"] = 19434,
    ["gezielter schuss"] = 19434,
    ["arcane shot"] = 3044,
    ["arkaner schuss"] = 3044,
    ["multi-shot"] = 2643,
    ["mehrfachschuss"] = 2643,
    ["serpent sting"] = 1978,
    ["schlangenbiss"] = 1978,
    ["hunter's mark"] = 1130,
    ["mal des jägers"] = 1130,
    ["concussive shot"] = 5116,
    ["erschütternder schuss"] = 5116,
    ["mend pet"] = 136,
    ["tier heilen"] = 136,
    ["feign death"] = 5384,
    ["totstellen"] = 5384,

    -- Rogue
    ["sinister strike"] = 1752,
    ["finsterer stoß"] = 1752,
    ["eviscerate"] = 2098,
    ["ausweiden"] = 2098,
    ["slice and dice"] = 5171,
    ["zerhäckseln"] = 5171,
    ["backstab"] = 53,
    ["meucheln"] = 53,
    ["ambush"] = 8676,
    ["hinterhalt"] = 8676,
    ["rupture"] = 1943,
    ["blutung"] = 1943,
    ["kidney shot"] = 408,
    ["nierenhieb"] = 408,
    ["cheap shot"] = 1833,
    ["fieser trick"] = 1833,
    ["blind"] = 2094,
    ["blenden"] = 2094,
    ["kick"] = 1766,
    ["tritt"] = 1766,
    ["stealth"] = 1784,
    ["verstohlenheit"] = 1784,
    ["vanish"] = 1856,
    ["verschwinden"] = 1856,

    -- Warrior
    ["heroic strike"] = 78,
    ["heroischer stoß"] = 78,
    ["rend"] = 772,
    ["verwunden"] = 772,
    ["thunder clap"] = 6343,
    ["donnerknall"] = 6343,
    ["shield slam"] = 23922,
    ["schildschlag"] = 23922,
    ["mortal strike"] = 12294,
    ["tödlicher stoß"] = 12294,
    ["bloodthirst"] = 23881,
    ["blutdurst"] = 23881,
    ["whirlwind"] = 1680,
    ["wirbelwind"] = 1680,
    ["overpower"] = 7384,
    ["überwältigen"] = 7384,
    ["revenge"] = 6572,
    ["rache"] = 6572,
    ["execute"] = 5308,
    ["hinrichten"] = 5308,
    ["sunder armor"] = 7386,
    ["rüstung zerreißen"] = 7386,
    ["shield block"] = 2565,
    ["schildblock"] = 2565,
    ["taunt"] = 355,
    ["spott"] = 355,
    ["battle shout"] = 6673,
    ["schlachtruf"] = 6673,
    ["pummel"] = 6552,
    ["zuschlagen"] = 6552,
    ["charge"] = 100,
    ["sturmangriff"] = 100,
    ["intercept"] = 20252,
    ["abfangen"] = 20252,
}
