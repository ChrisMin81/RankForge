--[[
    RankForge - Core.lua
    Spellbook scanner, downrank calculation, macro generation, and combat-safe synchronization.
    Compatible with WoW Forever, Classic Era, and TBC Era.
]]

local addonName, RF = ...
local L = RF.L

-- Global addon reference
_G["RankForge"] = RF

-- State
RF.knownSpells = {}          -- [spellName] = { maxRank = X, ranks = { [1] = subtext, ... } }
RF.queuedMacroUpdates = false
RF.isInitialized = false

--------------------------------------------------------------------------------
-- Database & Profile Defaults
--------------------------------------------------------------------------------
local defaultDB = {
    locale = "auto",
    minimapPos = 215,
    showMinimap = true,
    debugMode = false,
    profiles = {
        ["Default"] = {
            macros = {}
        }
    }
}

local defaultCharDB = {
    activeProfile = "Default",
    filterCurrentCharOnly = true
}

--------------------------------------------------------------------------------
-- Utilities
--------------------------------------------------------------------------------
function RF:DeepCopy(orig)
    if type(orig) ~= "table" then
        return orig
    end
    local copy = {}
    for k, v in pairs(orig) do
        copy[RF:DeepCopy(k)] = RF:DeepCopy(v)
    end
    return copy
end

local function ParseRankNumber(subtext)
    if not subtext or subtext == "" then return nil end
    local rank = subtext:match("(%d+)")
    return rank and tonumber(rank) or nil
end

function RF:ScanSpellBook()
    wipe(RF.knownSpells)

    local maxSlot = 0
    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetSpellBookSkillLineInfo then
        local numLines = C_SpellBook.GetNumSpellBookSkillLines()
        for l = 1, (numLines or 0) do
            local lineInfo = C_SpellBook.GetSpellBookSkillLineInfo(l)
            if lineInfo and lineInfo.itemIndexOffset and lineInfo.numSpellBookItems then
                local endSlot = lineInfo.itemIndexOffset + lineInfo.numSpellBookItems
                if endSlot > maxSlot then maxSlot = endSlot end
            end
        end
    elseif GetNumSpellTabs and GetSpellTabInfo then
        local numTabs = GetNumSpellTabs()
        for t = 1, (numTabs or 0) do
            local _, _, offset, numSpells = GetSpellTabInfo(t)
            if offset and numSpells then
                local endSlot = offset + numSpells
                if endSlot > maxSlot then maxSlot = endSlot end
            end
        end
    end
    if maxSlot < 300 then maxSlot = 500 end

    local consecutiveEmpty = 0
    for i = 1, maxSlot do
        local spellName, subtext, spellID = nil, nil, nil

        -- Check modern C_SpellBook API first
        if C_SpellBook and C_SpellBook.GetSpellBookItemName then
            local ok, n = pcall(C_SpellBook.GetSpellBookItemName, i, Enum.SpellBookSpellBank.Player)
            if ok and n and n ~= "" then
                spellName = n
                if C_SpellBook.GetSpellBookItemSubtext then
                    local okSub, sub = pcall(C_SpellBook.GetSpellBookItemSubtext, i, Enum.SpellBookSpellBank.Player)
                    if okSub and sub and sub ~= "" then
                        subtext = sub
                    end
                end
                if C_SpellBook.GetSpellBookItemType then
                    local okType, itemType, actionID, sID = pcall(C_SpellBook.GetSpellBookItemType, i, Enum.SpellBookSpellBank.Player)
                    if okType then
                        spellID = sID or actionID
                    end
                end
            end
        end

        -- Check legacy GetSpellBookItemName fallback (Cataclysm+)
        if (not spellName or spellName == "") and GetSpellBookItemName then
            local ok, n, sub = pcall(GetSpellBookItemName, i, BOOKTYPE_SPELL or "spell")
            if ok and n and n ~= "" then
                spellName = n
                if sub and sub ~= "" then
                    subtext = sub
                end
            end
        end

        -- Check WotLK 3.3.5a / Vanilla / TBC GetSpellName fallback
        if (not spellName or spellName == "") and GetSpellName then
            local ok, n, sub = pcall(GetSpellName, i, BOOKTYPE_SPELL or "spell")
            if ok and n and n ~= "" then
                spellName = n
                if sub and sub ~= "" then
                    subtext = sub
                end
            end
        end

        -- Query slot item info for spellID across 3.3.5a and legacy versions
        if (not spellID or spellID == 0) and GetSpellBookItemInfo then
            local okInfo, itemType, id = pcall(GetSpellBookItemInfo, i, BOOKTYPE_SPELL or "spell")
            if okInfo and id then
                spellID = id
            end
        end

        if not spellName or spellName == "" then
            consecutiveEmpty = consecutiveEmpty + 1
            if consecutiveEmpty >= 30 and i > 40 then
                break
            end
        else
            consecutiveEmpty = 0

            -- Query slot subtext if missing (only for valid spell slots!)
            if (not subtext or subtext == "") and GetSpellSubtext then
                local ok, res = pcall(GetSpellSubtext, i, BOOKTYPE_SPELL or "spell")
                if ok and res and res ~= "" then
                    subtext = res
                end
            end

            -- Query ID subtext if missing
            if (not subtext or subtext == "") and spellID then
                if C_Spell and C_Spell.GetSpellSubtext then
                    local ok, res = pcall(C_Spell.GetSpellSubtext, spellID)
                    if ok and res and res ~= "" then
                        subtext = res
                    end
                elseif GetSpellSubtext then
                    local ok, res = pcall(GetSpellSubtext, spellID)
                    if ok and res and res ~= "" then
                        subtext = res
                    end
                end
            end

            local rankNum = ParseRankNumber(subtext)
            local rankWord = (subtext and subtext:match("^(%a+)")) or L["RANK_WORD"]

            if not RF.knownSpells[spellName] then
                RF.knownSpells[spellName] = {
                    name = spellName,
                    maxRank = 0,
                    ranks = {},
                    subtexts = {},
                    hasRanks = false,
                    rankWord = rankWord,
                    spellID = spellID
                }
            end

            local entry = RF.knownSpells[spellName]
            if rankWord and not entry.rankWord then
                entry.rankWord = rankWord
            end

            if rankNum then
                entry.hasRanks = true
                if rankNum > entry.maxRank then
                    entry.maxRank = rankNum
                end
                -- Ensure all lower ranks up to maxRank are registered as learned
                for r = 1, entry.maxRank do
                    entry.ranks[r] = true
                    if not entry.subtexts[r] then
                        entry.subtexts[r] = string.format("%s %d", entry.rankWord or L["RANK_WORD"], r)
                    end
                end
                entry.subtexts[rankNum] = subtext or string.format("%s %d", entry.rankWord or L["RANK_WORD"], rankNum)
            else
                -- Unranked spell
                entry.ranks[1] = true
                entry.subtexts[1] = ""
                if entry.maxRank == 0 then
                    entry.maxRank = 1
                end
            end

            -- Index by numeric spellID for instant multi-language matching
            if spellID and spellID > 0 then
                RF.knownSpellsByID = RF.knownSpellsByID or {}
                RF.knownSpellsByID[spellID] = entry
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Multi-Language & Spell ID Resolution
--------------------------------------------------------------------------------
function RF:ResolveSpellID(spellName)
    if not spellName or spellName == "" then return nil end

    -- 1. Check known spells scanned from spellbook
    if RF.knownSpells and RF.knownSpells[spellName] and RF.knownSpells[spellName].spellID then
        return RF.knownSpells[spellName].spellID
    end

    -- 2. Check cross-language catalog in Presets.lua (case-insensitive)
    local lower = spellName:lower():trim()
    if RF.SpellCatalog and RF.SpellCatalog[lower] then
        return RF.SpellCatalog[lower]
    end

    -- 3. Query WoW API directly (in WoW, GetSpellInfo accepts spell name and returns spellID as 7th return value)
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, spellName)
        if ok and info and info.spellID and info.spellID > 0 then
            return info.spellID
        end
    end
    if GetSpellInfo then
        local ok, _, _, _, _, _, _, sID = pcall(GetSpellInfo, spellName)
        if ok and sID and type(sID) == "number" and sID > 0 then
            return sID
        end
    end

    -- 4. Check Presets list
    if RF.PresetSpells then
        for class, list in pairs(RF.PresetSpells) do
            for _, p in ipairs(list) do
                if p.name and p.name:lower() == lower and p.spellID then
                    return p.spellID
                end
            end
        end
    end

    return nil
end

function RF:GetLocalizedSpellName(spellName, spellID)
    if (not spellID or spellID == 0) and spellName and spellName ~= "" then
        spellID = RF:ResolveSpellID(spellName)
    end

    if spellID and type(spellID) == "number" and spellID > 0 then
        -- Query current client language for this spellID
        if C_Spell and C_Spell.GetSpellInfo then
            local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
            if ok and info and info.name and info.name ~= "" then
                return info.name, spellID
            end
        end
        if GetSpellInfo then
            local ok, name = pcall(GetSpellInfo, spellID)
            if ok and name and name ~= "" and type(name) == "string" then
                return name, spellID
            end
        end
    end

    return spellName or "", spellID
end

function RF:GetSpellRanksInfo(spellNameOrID)
    if not spellNameOrID or spellNameOrID == "" then return nil end
    local info = nil

    if type(spellNameOrID) == "number" then
        info = RF.knownSpellsByID and RF.knownSpellsByID[spellNameOrID]
        if not info then
            local locName = RF:GetLocalizedSpellName(nil, spellNameOrID)
            if locName and locName ~= "" then
                info = RF.knownSpells[locName]
            end
        end
    else
        info = RF.knownSpells[spellNameOrID]
        if not info then
            -- Try resolving localized name if given an English or foreign name
            local locName, sID = RF:GetLocalizedSpellName(spellNameOrID)
            if locName and locName ~= spellNameOrID then
                info = RF.knownSpells[locName]
            end
            if not info and sID then
                info = RF.knownSpellsByID and RF.knownSpellsByID[sID]
            end
        end
    end

    if not info then
        -- Refresh scan if not found
        RF:ScanSpellBook()
        if type(spellNameOrID) == "number" then
            info = RF.knownSpellsByID and RF.knownSpellsByID[spellNameOrID]
        else
            info = RF.knownSpells[spellNameOrID]
            if not info then
                local locName = RF:GetLocalizedSpellName(spellNameOrID)
                if locName then info = RF.knownSpells[locName] end
            end
        end
    end
    return info
end

function RF:GetLearnedSpellList()
    local list = {}
    for name, data in pairs(RF.knownSpells) do
        table.insert(list, {
            name = name,
            maxRank = data.maxRank,
            hasRanks = data.hasRanks,
            spellID = data.spellID
        })
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

function RF:GetSpellTexture(nameOrID)
    if not nameOrID or nameOrID == "" then
        return "Interface\\Icons\\INV_Misc_QuestionMark"
    end

    -- Modern WoW (9.0+ / 10.0+ / 11.0+)
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, res = pcall(C_Spell.GetSpellTexture, nameOrID)
        if ok and res then return res end
    end

    -- Universal WoW: GetSpellInfo accepts BOTH spellID number AND spellName string
    -- and returns the icon texture as its 3rd return value without requiring a 2nd argument.
    if GetSpellInfo then
        local ok, _, _, icon = pcall(GetSpellInfo, nameOrID)
        if ok and icon then return icon end
    end

    -- Legacy string fallback (in 3.3.5a GetSpellTexture only accepts string)
    if type(nameOrID) == "string" and GetSpellTexture then
        local ok, res = pcall(GetSpellTexture, nameOrID)
        if ok and res then return res end
    end

    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

function RF:GetSpellFromCursor()
    if not GetCursorInfo then return nil end
    local infoType, info1, info2, info3 = GetCursorInfo()
    if not infoType then return nil end

    local spellName = nil

    if infoType == "spell" then
        -- 1. Modern WoW 1.15 / 1.60 / Dragonflight:
        -- In modern Classic Era (1.15+ / 1.60+), info3 is often the actual numeric spellID! (e.g. 589 for Shadow Word: Pain)
        if type(info3) == "number" and info3 > 0 then
            if C_Spell and C_Spell.GetSpellInfo then
                local ok, info = pcall(C_Spell.GetSpellInfo, info3)
                if ok and info and info.name and info.name ~= "" then
                    spellName = info.name
                end
            elseif GetSpellInfo then
                local ok, name = pcall(GetSpellInfo, info3)
                if ok and name and name ~= "" and type(name) == "string" then
                    spellName = name
                end
            end
        end

        -- 2. Modern C_SpellBook API (Client 1.15+ / 1.60+):
        if not spellName or spellName == "" then
            local bank = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or 0
            if type(info2) == "number" then
                bank = info2
            end

            if C_SpellBook and type(info1) == "number" then
                -- 2a. C_SpellBook.GetSpellBookItemName
                if C_SpellBook.GetSpellBookItemName then
                    local ok, name = pcall(C_SpellBook.GetSpellBookItemName, info1, bank)
                    if ok and name and name ~= "" and type(name) == "string" then
                        spellName = name
                    end
                end

                -- 2b. C_SpellBook.GetSpellBookItemInfo (table in modern 11.0+, or itemType, spellID in earlier versions)
                if (not spellName or spellName == "") and C_SpellBook.GetSpellBookItemInfo then
                    local ok, info, extraID = pcall(C_SpellBook.GetSpellBookItemInfo, info1, bank)
                    if ok then
                        if type(info) == "table" then
                            if info.name and info.name ~= "" then
                                spellName = info.name
                            elseif info.spellID and info.spellID > 0 then
                                local sid = info.spellID
                                if C_Spell and C_Spell.GetSpellInfo then
                                    local ok2, sInfo = pcall(C_Spell.GetSpellInfo, sid)
                                    if ok2 and sInfo and sInfo.name then spellName = sInfo.name end
                                elseif GetSpellInfo then
                                    local ok2, n = pcall(GetSpellInfo, sid)
                                    if ok2 and n and n ~= "" then spellName = n end
                                end
                            end
                        elseif type(extraID) == "number" and extraID > 0 then
                            if C_Spell and C_Spell.GetSpellInfo then
                                local ok2, sInfo = pcall(C_Spell.GetSpellInfo, extraID)
                                if ok2 and sInfo and sInfo.name then spellName = sInfo.name end
                            elseif GetSpellInfo then
                                local ok2, n = pcall(GetSpellInfo, extraID)
                                if ok2 and n and n ~= "" then spellName = n end
                            end
                        end
                    end
                end

                -- 2c. C_SpellBook.GetSpellBookItemType (extract sID)
                if (not spellName or spellName == "") and C_SpellBook.GetSpellBookItemType then
                    local ok, itemType, actionID, sID = pcall(C_SpellBook.GetSpellBookItemType, info1, bank)
                    local trueID = sID or actionID
                    if ok and trueID and trueID > 0 then
                        if C_Spell and C_Spell.GetSpellInfo then
                            local ok2, sInfo = pcall(C_Spell.GetSpellInfo, trueID)
                            if ok2 and sInfo and sInfo.name then spellName = sInfo.name end
                        elseif GetSpellInfo then
                            local ok2, n = pcall(GetSpellInfo, trueID)
                            if ok2 and n and n ~= "" then spellName = n end
                        end
                    end
                end
            end
        end

        -- 3. Legacy WotLK 3.3.5a / Vanilla / TBC:
        if not spellName or spellName == "" then
            local bookType = (type(info2) == "string" and info2 ~= "") and info2 or (BOOKTYPE_SPELL or "spell")
            if type(info1) == "number" then
                -- 3a. Native 3.3.5a / Vanilla / TBC API: GetSpellName(slot, bookType)
                if GetSpellName then
                    local ok, name = pcall(GetSpellName, info1, bookType)
                    if ok and name and name ~= "" and type(name) == "string" then
                        spellName = name
                    end
                end

                -- 3b. Cataclysm+ API: GetSpellBookItemName(slot, bookType)
                if (not spellName or spellName == "") and GetSpellBookItemName then
                    local ok, name = pcall(GetSpellBookItemName, info1, bookType)
                    if ok and name and name ~= "" and type(name) == "string" then
                        spellName = name
                    end
                end

                -- 3c. Get actual global spellID from slot via GetSpellBookItemInfo, THEN query GetSpellInfo(spellID)
                if (not spellName or spellName == "") and GetSpellBookItemInfo then
                    local ok, itemType, sID = pcall(GetSpellBookItemInfo, info1, bookType)
                    if ok and sID and type(sID) == "number" and sID > 0 then
                        if C_Spell and C_Spell.GetSpellInfo then
                            local okInfo, info = pcall(C_Spell.GetSpellInfo, sID)
                            if okInfo and info and info.name then spellName = info.name end
                        elseif GetSpellInfo then
                            local okInfo, name = pcall(GetSpellInfo, sID)
                            if okInfo and name and name ~= "" and type(name) == "string" then
                                spellName = name
                            end
                        end
                    end
                end
            end
        end

        -- 4. In modern WoW or when info2 is a numeric spellID
        if not spellName or spellName == "" then
            if type(info2) == "number" and info2 > 0 then
                if C_Spell and C_Spell.GetSpellInfo then
                    local ok, info = pcall(C_Spell.GetSpellInfo, info2)
                    if ok and info and info.name then spellName = info.name end
                elseif GetSpellInfo then
                    local ok, name = pcall(GetSpellInfo, info2)
                    if ok and name and name ~= "" then spellName = name end
                end
            end
        end

        -- 5. If info1 is directly a numeric spellID (only when info2 is nil, meaning it's not a spellbook slot)
        if not spellName or spellName == "" then
            if type(info1) == "number" and (info2 == nil or info2 == "") then
                if C_Spell and C_Spell.GetSpellInfo then
                    local ok, info = pcall(C_Spell.GetSpellInfo, info1)
                    if ok and info and info.name then spellName = info.name end
                elseif GetSpellInfo then
                    local ok, name = pcall(GetSpellInfo, info1)
                    if ok and name and name ~= "" and type(name) == "string" then
                        spellName = name
                    end
                end
            elseif type(info1) == "string" and info1 ~= "" then
                spellName = info1
            end
        end

    elseif infoType == "action" then
        -- Dragged from action bar slot
        if type(info1) == "number" and GetActionInfo then
            local actionType, id = GetActionInfo(info1)
            if actionType == "spell" and id then
                if C_Spell and C_Spell.GetSpellInfo then
                    local ok, info = pcall(C_Spell.GetSpellInfo, id)
                    if ok and info and info.name then spellName = info.name end
                elseif GetSpellInfo then
                    local ok, name = pcall(GetSpellInfo, id)
                    if ok and name and name ~= "" then spellName = name end
                end
            end
        end
    end

    if spellName and spellName ~= "" then
        if ClearCursor then
            pcall(ClearCursor)
        end
        return spellName
    end

    return nil
end

local HARMFUL_SPELLS = {
    ["Mind Blast"] = true, ["Gedankenschlag"] = true,
    ["Shadow Word: Pain"] = true, ["Schattenwort: Schmerz"] = true,
    ["Smite"] = true, ["Heilige Pein"] = true, ["Göttliche Pein"] = true,
    ["Holy Fire"] = true, ["Heiliges Feuer"] = true,
    ["Mana Burn"] = true, ["Manabrand"] = true,
    ["Frostbolt"] = true, ["Frostblitz"] = true,
    ["Fireball"] = true, ["Feuerball"] = true,
    ["Scorch"] = true, ["Sengen"] = true, ["Sengende Hitze"] = true,
    ["Arcane Missiles"] = true, ["Arkane Geschosse"] = true,
    ["Cone of Cold"] = true, ["Kältekegel"] = true,
    ["Flamestrike"] = true, ["Flammenstoß"] = true,
    ["Blizzard"] = true,
    ["Shadow Bolt"] = true, ["Schattenblitz"] = true,
    ["Corruption"] = true, ["Verderbnis"] = true,
    ["Immolate"] = true, ["Feuerbrand"] = true,
    ["Curse of Agony"] = true, ["Fluch der Pein"] = true,
    ["Drain Life"] = true, ["Blutsauger"] = true,
    ["Hellfire"] = true, ["Höllenfeuer"] = true,
    ["Rain of Fire"] = true, ["Feuerregen"] = true,
    ["Moonfire"] = true, ["Mondfeuer"] = true,
    ["Wrath"] = true, ["Zorn"] = true,
    ["Starfire"] = true, ["Sternenfeuer"] = true,
    ["Lightning Bolt"] = true, ["Blitzschlag"] = true,
    ["Chain Lightning"] = true, ["Kettenblitz"] = true,
    ["Earth Shock"] = true, ["Erdschock"] = true,
    ["Flame Shock"] = true, ["Flammenschock"] = true,
    ["Frost Shock"] = true, ["Frostschock"] = true,
    ["Exorcism"] = true, ["Exorzismus"] = true,
    ["Consecration"] = true, ["Weihe"] = true,
}

local HELPFUL_SPELLS = {
    ["Renew"] = true, ["Erneuerung"] = true,
    ["Flash Heal"] = true, ["Blitzheilung"] = true,
    ["Greater Heal"] = true, ["Große Heilung"] = true,
    ["Heal"] = true, ["Heilung"] = true,
    ["Lesser Heal"] = true, ["Geringes Heilen"] = true, ["Geringe Heilung"] = true,
    ["Prayer of Healing"] = true, ["Gebet der Heilung"] = true,
    ["Power Word: Shield"] = true, ["Machtwort: Schild"] = true,
    ["Healing Touch"] = true, ["Heilende Berührung"] = true,
    ["Regrowth"] = true, ["Nachwachsen"] = true,
    ["Rejuvenation"] = true, ["Verjüngung"] = true,
    ["Holy Light"] = true, ["Heiliges Licht"] = true,
    ["Flash of Light"] = true, ["Lichtblitz"] = true,
    ["Holy Shock"] = true, ["Heiliger Schock"] = true,
    ["Healing Wave"] = true, ["Welle der Heilung"] = true,
    ["Lesser Healing Wave"] = true, ["Geringe Welle der Heilung"] = true,
    ["Chain Heal"] = true, ["Kettenheilung"] = true,
}

function RF:IsSpellHarmful(spellName)
    if not spellName or spellName == "" then return false end
    if HARMFUL_SPELLS[spellName] then return true end
    if HELPFUL_SPELLS[spellName] then return false end
    if C_Spell and C_Spell.IsSpellHarmful then
        local ok, res = pcall(C_Spell.IsSpellHarmful, spellName)
        if ok and res ~= nil then return res end
    end
    if IsHarmfulSpell then
        local ok, res = pcall(IsHarmfulSpell, spellName)
        if ok and res ~= nil then return res end
    end
    return false
end

function RF:IsSpellHelpful(spellName)
    if not spellName or spellName == "" then return false end
    if HELPFUL_SPELLS[spellName] then return true end
    if HARMFUL_SPELLS[spellName] then return false end
    if C_Spell and C_Spell.IsSpellHelpful then
        local ok, res = pcall(C_Spell.IsSpellHelpful, spellName)
        if ok and res ~= nil then return res end
    end
    if IsHelpfulSpell then
        local ok, res = pcall(IsHelpfulSpell, spellName)
        if ok and res ~= nil then return res end
    end
    return false
end

function RF:AutoConfigureSpellType(macroConfig, spellName)
    if not macroConfig or not macroConfig.modifiers then return end
    local isHarm = RF:IsSpellHarmful(spellName)
    local isHelp = RF:IsSpellHelpful(spellName)

    if isHarm and not isHelp then
        for _, mod in ipairs(macroConfig.modifiers) do
            mod.isHelp = false
            mod.isHarm = true
            mod.targetSelfcast = false
            mod.targetTarget = true
        end
    elseif isHelp and not isHarm then
        for _, mod in ipairs(macroConfig.modifiers) do
            mod.isHelp = true
            mod.isHarm = false
            mod.targetSelfcast = true
            mod.targetTarget = true
        end
    end
end

RF.SpellRankLevels = {
    -- Priest
    ["Renew"] = { [1]=8, [2]=14, [3]=20, [4]=26, [5]=32, [6]=38, [7]=44, [8]=50, [9]=56, [10]=60 },
    ["Erneuerung"] = { [1]=8, [2]=14, [3]=20, [4]=26, [5]=32, [6]=38, [7]=44, [8]=50, [9]=56, [10]=60 },
    ["Flash Heal"] = { [1]=20, [2]=26, [3]=32, [4]=38, [5]=44, [6]=50, [7]=56 },
    ["Blitzheilung"] = { [1]=20, [2]=26, [3]=32, [4]=38, [5]=44, [6]=50, [7]=56 },
    ["Greater Heal"] = { [1]=40, [2]=46, [3]=52, [4]=58, [5]=60 },
    ["Große Heilung"] = { [1]=40, [2]=46, [3]=52, [4]=58, [5]=60 },
    ["Heal"] = { [1]=16, [2]=22, [3]=28, [4]=34 },
    ["Heilung"] = { [1]=16, [2]=22, [3]=28, [4]=34 },
    ["Lesser Heal"] = { [1]=1, [2]=4, [3]=10 },
    ["Geringes Heilen"] = { [1]=1, [2]=4, [3]=10 },
    ["Geringe Heilung"] = { [1]=1, [2]=4, [3]=10 },
    ["Prayer of Healing"] = { [1]=30, [2]=40, [3]=50, [4]=60 },
    ["Gebet der Heilung"] = { [1]=30, [2]=40, [3]=50, [4]=60 },
    ["Power Word: Shield"] = { [1]=6, [2]=12, [3]=18, [4]=24, [5]=30, [6]=36, [7]=42, [8]=48, [9]=54, [10]=60 },
    ["Machtwort: Schild"] = { [1]=6, [2]=12, [3]=18, [4]=24, [5]=30, [6]=36, [7]=42, [8]=48, [9]=54, [10]=60 },
    ["Smite"] = { [1]=1, [2]=6, [3]=14, [4]=22, [5]=30, [6]=38, [7]=46, [8]=54, [9]=61, [10]=69 },
    ["Heilige Pein"] = { [1]=1, [2]=6, [3]=14, [4]=22, [5]=30, [6]=38, [7]=46, [8]=54, [9]=61, [10]=69 },
    ["Göttliche Pein"] = { [1]=1, [2]=6, [3]=14, [4]=22, [5]=30, [6]=38, [7]=46, [8]=54, [9]=61, [10]=69 },
    ["Pein"] = { [1]=1, [2]=6, [3]=14, [4]=22, [5]=30, [6]=38, [7]=46, [8]=54, [9]=61, [10]=69 },
    ["Mind Blast"] = { [1]=10, [2]=16, [3]=22, [4]=28, [5]=34, [6]=40, [7]=46, [8]=52, [9]=58 },
    ["Gedankenschlag"] = { [1]=10, [2]=16, [3]=22, [4]=28, [5]=34, [6]=40, [7]=46, [8]=52, [9]=58 },
    ["Shadow Word: Pain"] = { [1]=4, [2]=10, [3]=18, [4]=26, [5]=34, [6]=42, [7]=50, [8]=58 },
    ["Schattenwort: Schmerz"] = { [1]=4, [2]=10, [3]=18, [4]=26, [5]=34, [6]=42, [7]=50, [8]=58 },

    -- Druid
    ["Healing Touch"] = { [1]=1, [2]=8, [3]=14, [4]=20, [5]=26, [6]=32, [7]=38, [8]=44, [9]=50, [10]=56, [11]=60 },
    ["Heilende Berührung"] = { [1]=1, [2]=8, [3]=14, [4]=20, [5]=26, [6]=32, [7]=38, [8]=44, [9]=50, [10]=56, [11]=60 },
    ["Regrowth"] = { [1]=12, [2]=18, [3]=24, [4]=30, [5]=36, [6]=42, [7]=48, [8]=54, [9]=60 },
    ["Nachwachsen"] = { [1]=12, [2]=18, [3]=24, [4]=30, [5]=36, [6]=42, [7]=48, [8]=54, [9]=60 },
    ["Rejuvenation"] = { [1]=4, [2]=10, [3]=16, [4]=22, [5]=28, [6]=34, [7]=40, [8]=46, [9]=52, [10]=58, [11]=60 },
    ["Verjüngung"] = { [1]=4, [2]=10, [3]=16, [4]=22, [5]=28, [6]=34, [7]=40, [8]=46, [9]=52, [10]=58, [11]=60 },
    ["Moonfire"] = { [1]=4, [2]=10, [3]=16, [4]=22, [5]=28, [6]=34, [7]=40, [8]=46, [9]=52, [10]=58, [11]=60 },
    ["Mondfeuer"] = { [1]=4, [2]=10, [3]=16, [4]=22, [5]=28, [6]=34, [7]=40, [8]=46, [9]=52, [10]=58, [11]=60 },
    ["Wrath"] = { [1]=1, [2]=6, [3]=14, [4]=22, [5]=30, [6]=38, [7]=46, [8]=54 },
    ["Zorn"] = { [1]=1, [2]=6, [3]=14, [4]=22, [5]=30, [6]=38, [7]=46, [8]=54 },
    ["Starfire"] = { [1]=20, [2]=26, [3]=34, [4]=42, [5]=50, [6]=58 },
    ["Sternenfeuer"] = { [1]=20, [2]=26, [3]=34, [4]=42, [5]=50, [6]=58 },

    -- Paladin
    ["Holy Light"] = { [1]=1, [2]=6, [3]=14, [4]=22, [5]=30, [6]=38, [7]=46, [8]=54, [9]=60 },
    ["Heiliges Licht"] = { [1]=1, [2]=6, [3]=14, [4]=22, [5]=30, [6]=38, [7]=46, [8]=54, [9]=60 },
    ["Flash of Light"] = { [1]=20, [2]=26, [3]=34, [4]=42, [5]=50, [6]=58 },
    ["Lichtblitz"] = { [1]=20, [2]=26, [3]=34, [4]=42, [5]=50, [6]=58 },
    ["Holy Shock"] = { [1]=40, [2]=48, [3]=56, [4]=64, [5]=72, [6]=80 },
    ["Heiliger Schock"] = { [1]=40, [2]=48, [3]=56, [4]=64, [5]=72, [6]=80 },
    ["Consecration"] = { [1]=20, [2]=30, [3]=40, [4]=50, [5]=60, [6]=70, [7]=78, [8]=80 },
    ["Weihe"] = { [1]=20, [2]=30, [3]=40, [4]=50, [5]=60, [6]=70, [7]=78, [8]=80 },
    ["Exorcism"] = { [1]=20, [2]=28, [3]=36, [4]=44, [5]=52, [6]=60, [7]=68, [8]=73, [9]=79 },
    ["Exorzismus"] = { [1]=20, [2]=28, [3]=36, [4]=44, [5]=52, [6]=60, [7]=68, [8]=73, [9]=79 },

    -- Shaman
    ["Healing Wave"] = { [1]=1, [2]=6, [3]=12, [4]=18, [5]=24, [6]=30, [7]=36, [8]=42, [9]=48, [10]=54, [11]=60 },
    ["Welle der Heilung"] = { [1]=1, [2]=6, [3]=12, [4]=18, [5]=24, [6]=30, [7]=36, [8]=42, [9]=48, [10]=54, [11]=60 },
    ["Lesser Healing Wave"] = { [1]=20, [2]=28, [3]=36, [4]=44, [5]=52, [6]=60 },
    ["Geringe Welle der Heilung"] = { [1]=20, [2]=28, [3]=36, [4]=44, [5]=52, [6]=60 },
    ["Chain Heal"] = { [1]=40, [2]=46, [3]=54 },
    ["Kettenheilung"] = { [1]=40, [2]=46, [3]=54 },
    ["Lightning Bolt"] = { [1]=1, [2]=8, [3]=14, [4]=20, [5]=26, [6]=32, [7]=38, [8]=44, [9]=50, [10]=56, [11]=60 },
    ["Blitzschlag"] = { [1]=1, [2]=8, [3]=14, [4]=20, [5]=26, [6]=32, [7]=38, [8]=44, [9]=50, [10]=56, [11]=60 },
    ["Chain Lightning"] = { [1]=32, [2]=40, [3]=48, [4]=56, [5]=63, [6]=70, [7]=75, [8]=80 },
    ["Kettenblitz"] = { [1]=32, [2]=40, [3]=48, [4]=56, [5]=63, [6]=70, [7]=75, [8]=80 },
    ["Earth Shock"] = { [1]=4, [2]=8, [3]=14, [4]=24, [5]=36, [6]=48, [7]=60, [8]=69, [9]=74, [10]=79 },
    ["Erdschock"] = { [1]=4, [2]=8, [3]=14, [4]=24, [5]=36, [6]=48, [7]=60, [8]=69, [9]=74, [10]=79 },
    ["Flame Shock"] = { [1]=10, [2]=18, [3]=28, [4]=40, [5]=52, [6]=60, [7]=70, [8]=75, [9]=80 },
    ["Flammenschock"] = { [1]=10, [2]=18, [3]=28, [4]=40, [5]=52, [6]=60, [7]=70, [8]=75, [9]=80 },
    ["Frost Shock"] = { [1]=20, [2]=34, [3]=46, [4]=58, [5]=68, [6]=73, [7]=78 },
    ["Frostschock"] = { [1]=20, [2]=34, [3]=46, [4]=58, [5]=68, [6]=73, [7]=78 },

    -- Mage
    ["Frostbolt"] = { [1]=1, [2]=8, [3]=14, [4]=20, [5]=26, [6]=32, [7]=38, [8]=44, [9]=50, [10]=56, [11]=60 },
    ["Frostblitz"] = { [1]=1, [2]=8, [3]=14, [4]=20, [5]=26, [6]=32, [7]=38, [8]=44, [9]=50, [10]=56, [11]=60 },
    ["Fireball"] = { [1]=1, [2]=6, [3]=12, [4]=18, [5]=24, [6]=30, [7]=36, [8]=42, [9]=48, [10]=54, [11]=60 },
    ["Feuerball"] = { [1]=1, [2]=6, [3]=12, [4]=18, [5]=24, [6]=30, [7]=36, [8]=42, [9]=48, [10]=54, [11]=60 },
    ["Scorch"] = { [1]=22, [2]=28, [3]=34, [4]=40, [5]=46, [6]=52, [7]=58, [8]=64, [9]=70, [10]=76 },
    ["Sengen"] = { [1]=22, [2]=28, [3]=34, [4]=40, [5]=46, [6]=52, [7]=58, [8]=64, [9]=70, [10]=76 },
    ["Arcane Missiles"] = { [1]=8, [2]=16, [3]=24, [4]=32, [5]=40, [6]=48, [7]=56, [8]=63, [9]=69, [10]=75, [11]=80 },
    ["Arkane Geschosse"] = { [1]=8, [2]=16, [3]=24, [4]=32, [5]=40, [6]=48, [7]=56, [8]=63, [9]=69, [10]=75, [11]=80 },
    ["Cone of Cold"] = { [1]=26, [2]=34, [3]=42, [4]=50, [5]=58, [6]=66, [7]=72, [8]=78 },
    ["Kältekegel"] = { [1]=26, [2]=34, [3]=42, [4]=50, [5]=58, [6]=66, [7]=72, [8]=78 },
    ["Flamestrike"] = { [1]=16, [2]=24, [3]=32, [4]=40, [5]=48, [6]=56, [7]=64, [8]=71, [9]=78 },
    ["Flammenstoß"] = { [1]=16, [2]=24, [3]=32, [4]=40, [5]=48, [6]=56, [7]=64, [8]=71, [9]=78 },
    ["Blizzard"] = { [1]=20, [2]=28, [3]=36, [4]=44, [5]=52, [6]=60 },

    -- Warlock
    ["Shadow Bolt"] = { [1]=1, [2]=6, [3]=12, [4]=20, [5]=28, [6]=36, [7]=44, [8]=52, [9]=60 },
    ["Schattenblitz"] = { [1]=1, [2]=6, [3]=12, [4]=20, [5]=28, [6]=36, [7]=44, [8]=52, [9]=60 },
    ["Corruption"] = { [1]=4, [2]=14, [3]=24, [4]=34, [5]=44, [6]=54 },
    ["Verderbnis"] = { [1]=4, [2]=14, [3]=24, [4]=34, [5]=44, [6]=54 },
    ["Immolate"] = { [1]=1, [2]=10, [3]=20, [4]=30, [5]=40, [6]=50, [7]=60 },
    ["Feuerbrand"] = { [1]=1, [2]=10, [3]=20, [4]=30, [5]=40, [6]=50, [7]=60 },
    ["Curse of Agony"] = { [1]=8, [2]=18, [3]=28, [4]=38, [5]=48, [6]=58, [7]=67, [8]=73, [9]=79 },
    ["Fluch der Pein"] = { [1]=8, [2]=18, [3]=28, [4]=38, [5]=48, [6]=58, [7]=67, [8]=73, [9]=79 },
    ["Drain Life"] = { [1]=14, [2]=22, [3]=30, [4]=38, [5]=46, [6]=54, [7]=62, [8]=69, [9]=75 },
    ["Blutsauger"] = { [1]=14, [2]=22, [3]=30, [4]=38, [5]=46, [6]=54, [7]=62, [8]=69, [9]=75 },
    ["Hellfire"] = { [1]=30, [2]=38, [3]=46, [4]=54, [5]=62, [6]=68, [7]=74, [8]=80 },
    ["Höllenfeuer"] = { [1]=30, [2]=38, [3]=46, [4]=54, [5]=62, [6]=68, [7]=74, [8]=80 },
    ["Rain of Fire"] = { [1]=20, [2]=28, [3]=36, [4]=44, [5]=52, [6]=58, [7]=65, [8]=71, [9]=77 },
    ["Feuerregen"] = { [1]=20, [2]=28, [3]=36, [4]=44, [5]=52, [6]=58, [7]=65, [8]=71, [9]=77 }
}

RF.SpellClassLookup = {
    -- Priest
    ["Renew"] = "PRIEST", ["Erneuerung"] = "PRIEST",
    ["Flash Heal"] = "PRIEST", ["Blitzheilung"] = "PRIEST",
    ["Greater Heal"] = "PRIEST", ["Große Heilung"] = "PRIEST",
    ["Heal"] = "PRIEST", ["Heilung"] = "PRIEST",
    ["Lesser Heal"] = "PRIEST", ["Geringes Heilen"] = "PRIEST", ["Geringe Heilung"] = "PRIEST",
    ["Prayer of Healing"] = "PRIEST", ["Gebet der Heilung"] = "PRIEST",
    ["Power Word: Shield"] = "PRIEST", ["Machtwort: Schild"] = "PRIEST",
    ["Smite"] = "PRIEST", ["Heilige Pein"] = "PRIEST", ["Göttliche Pein"] = "PRIEST", ["Pein"] = "PRIEST",
    ["Mind Blast"] = "PRIEST", ["Gedankenschlag"] = "PRIEST",
    ["Shadow Word: Pain"] = "PRIEST", ["Schattenwort: Schmerz"] = "PRIEST",

    -- Druid
    ["Healing Touch"] = "DRUID", ["Heilende Berührung"] = "DRUID",
    ["Regrowth"] = "DRUID", ["Nachwachsen"] = "DRUID",
    ["Rejuvenation"] = "DRUID", ["Verjüngung"] = "DRUID",
    ["Moonfire"] = "DRUID", ["Mondfeuer"] = "DRUID",
    ["Wrath"] = "DRUID", ["Zorn"] = "DRUID",
    ["Starfire"] = "DRUID", ["Sternenfeuer"] = "DRUID",

    -- Paladin
    ["Holy Light"] = "PALADIN", ["Heiliges Licht"] = "PALADIN",
    ["Flash of Light"] = "PALADIN", ["Lichtblitz"] = "PALADIN",
    ["Holy Shock"] = "PALADIN", ["Heiliger Schock"] = "PALADIN",
    ["Consecration"] = "PALADIN", ["Weihe"] = "PALADIN",
    ["Exorcism"] = "PALADIN", ["Exorzismus"] = "PALADIN",

    -- Shaman
    ["Healing Wave"] = "SHAMAN", ["Welle der Heilung"] = "SHAMAN",
    ["Lesser Healing Wave"] = "SHAMAN", ["Geringe Welle der Heilung"] = "SHAMAN",
    ["Chain Heal"] = "SHAMAN", ["Kettenheilung"] = "SHAMAN",
    ["Lightning Bolt"] = "SHAMAN", ["Blitzschlag"] = "SHAMAN",
    ["Chain Lightning"] = "SHAMAN", ["Kettenblitz"] = "SHAMAN",
    ["Earth Shock"] = "SHAMAN", ["Erdschock"] = "SHAMAN",
    ["Flame Shock"] = "SHAMAN", ["Flammenschock"] = "SHAMAN",
    ["Frost Shock"] = "SHAMAN", ["Frostschock"] = "SHAMAN",

    -- Mage
    ["Frostbolt"] = "MAGE", ["Frostblitz"] = "MAGE",
    ["Fireball"] = "MAGE", ["Feuerball"] = "MAGE",
    ["Scorch"] = "MAGE", ["Sengen"] = "MAGE", ["Sengende Hitze"] = "MAGE",
    ["Arcane Missiles"] = "MAGE", ["Arkane Geschosse"] = "MAGE",
    ["Cone of Cold"] = "MAGE", ["Kältekegel"] = "MAGE",
    ["Flamestrike"] = "MAGE", ["Flammenstoß"] = "MAGE",
    ["Blizzard"] = "MAGE",

    -- Warlock
    ["Shadow Bolt"] = "WARLOCK", ["Schattenblitz"] = "WARLOCK",
    ["Corruption"] = "WARLOCK", ["Verderbnis"] = "WARLOCK",
    ["Immolate"] = "WARLOCK", ["Feuerbrand"] = "WARLOCK",
    ["Curse of Agony"] = "WARLOCK", ["Fluch der Pein"] = "WARLOCK",
    ["Drain Life"] = "WARLOCK", ["Blutsauger"] = "WARLOCK",
    ["Hellfire"] = "WARLOCK", ["Höllenfeuer"] = "WARLOCK",
    ["Rain of Fire"] = "WARLOCK", ["Feuerregen"] = "WARLOCK",
}

function RF:GetClassForSpell(spellName)
    if not spellName or spellName == "" then return nil end
    return RF.SpellClassLookup and RF.SpellClassLookup[spellName]
end

function RF:GetCurrentCharacterKey()
    local charName = (UnitName and UnitName("player")) or "Unknown"
    local realm = (GetRealmName and GetRealmName()) or ""
    local _, charClass = nil, nil
    if UnitClass then
        local _, c = UnitClass("player")
        charClass = c
    end
    if not charClass or charClass == "" then charClass = "PRIEST" end
    return charName, realm, charClass
end

function RF:IsMacroForCurrentCharacter(macroConfig)
    if not macroConfig then return true end
    local charName, realm, charClass = RF:GetCurrentCharacterKey()

    -- 1. Direct character name match (always visible on the character who created / owns it)
    if macroConfig.character and macroConfig.character ~= "" then
        if macroConfig.character == charName then
            return true
        end
    end

    -- 2. Spell class lookup: if spell belongs strictly to another class, always hide it
    local spName = macroConfig.spellName
    if (not spName or spName == "") and macroConfig.macroName then
        spName = macroConfig.macroName:gsub("^DR_", "")
    end
    local spellClass = spName and RF:GetClassForSpell(spName)

    if spellClass and charClass and spellClass ~= charClass then
        -- This spell belongs to another class (e.g. Blizzard on Priest, Feuerbrand on Mage)
        return false
    end

    -- 3. General / Account-wide macros:
    -- If a macro is saved in the Account tab (isAccount == true) and does not belong to another class
    -- (e.g. Basic Campfire / Feuer machen, mounts, professions, food/drink), it is shared across all characters!
    if macroConfig.isAccount == true and not spellClass then
        return true
    end

    -- 4. Class match
    if macroConfig.class and macroConfig.class ~= "" and charClass and charClass ~= "" then
        if macroConfig.class == charClass then
            return true
        else
            return false
        end
    end

    -- 5. Spell class matches current class
    if spellClass and charClass and spellClass == charClass then
        return true
    end

    -- 6. Untagged legacy macro with unknown spell class: visible by default
    if (not macroConfig.character or macroConfig.character == "") and (not macroConfig.class or macroConfig.class == "") then
        return true
    end

    return false
end

function RF:GetSpellSweetSpot(spellName, customLevel)
    if not spellName or spellName == "" then
        return 0, 1, 60
    end
    local spellInfo = RF.knownSpells[spellName]
    local maxRank = (spellInfo and spellInfo.maxRank and spellInfo.maxRank > 0) and spellInfo.maxRank or 1
    local playerLevel = customLevel or (UnitLevel and UnitLevel("player")) or 60

    local rankLevels = RF.SpellRankLevels[spellName]
    if not rankLevels then
        local bestOffset = math.min(1, maxRank - 1)
        if bestOffset < 0 then bestOffset = 0 end
        return bestOffset, maxRank - bestOffset, playerLevel
    end

    -- Rule in WoW Forever: rank must not be older than (playerLevel - 18)
    -- In Classic Vanilla: rank must be learned at level >= 20
    local minLevelNeeded = math.max(20, playerLevel - 18)

    local optimalRank = maxRank
    for r = 1, maxRank do
        local reqLvl = rankLevels[r] or 1
        if reqLvl >= minLevelNeeded and r <= maxRank then
            optimalRank = r
            break
        end
    end

    local offset = maxRank - optimalRank
    if offset < 0 then offset = 0 end
    local reqLvl = rankLevels[optimalRank] or playerLevel
    return offset, optimalRank, reqLvl
end

function RF:GetDownrankingEfficiency(spellName, rankOffset, targetRank, customLevel)
    if not spellName or spellName == "" then
        return 100, "green", "100%", 60, L["UI_EFFICIENCY_FULL"] or "Volle Effizienz"
    end

    local spellInfo = RF.knownSpells and RF.knownSpells[spellName]
    local maxRank = (spellInfo and spellInfo.maxRank and spellInfo.maxRank > 0) and spellInfo.maxRank or 1
    local playerLevel = customLevel or (UnitLevel and UnitLevel("player")) or 60

    local rank = targetRank
    if not rank then
        local off = tonumber(rankOffset) or 0
        rank = maxRank - off
    end
    if rank < 1 then rank = 1 end

    local rankLevels = RF.SpellRankLevels and RF.SpellRankLevels[spellName]
    local reqLvl = (rankLevels and rankLevels[rank]) or playerLevel

    -- Max rank or higher: always 100% full efficiency
    if rank >= maxRank then
        return 100, "green", "100%", reqLvl, (L["UI_EFFICIENCY_MAX_RANK"] or "Max-Rang (100% Zaubermacht & 100% Procs)")
    end

    -- Rule 1: Pre-20 penalty multiplier
    local multPre20 = 1.0
    if reqLvl < 20 then
        multPre20 = math.max(0, (reqLvl + 11) / 31)
    end

    -- Rule 2: Level difference penalty (WoW Forever / WotLK 3.0: playerLevel - 18)
    local multLevel = 1.0
    local levelThreshold = math.max(20, playerLevel - 18)
    if reqLvl < levelThreshold then
        multLevel = math.max(0, (reqLvl + 11) / (playerLevel + 11))
    end

    local spScaling = math.min(1.0, multPre20 * multLevel)
    local pct = math.floor(spScaling * 100 + 0.5)

    -- Status classification & Proc chance analysis (per WoW Forever update)
    local status = "green"
    local procChance = "100%"
    local desc = ""

    if reqLvl < 20 then
        status = "red"
        procChance = (L["UI_PROC_ZERO"] or "0% - Stark reduziert ⚠️")
        desc = string.format(L["UI_EFFICIENCY_DESC_PRE20"] or "Pre-20 Malus: Stufe %d < 20! Zaubermacht stark verringert (%d%%), Talent-Procs deaktiviert/minimal.", reqLvl, pct)
    elseif reqLvl < levelThreshold then
        if pct < 60 then
            status = "red"
            procChance = (L["UI_PROC_HEAVILY_REDUCED"] or "Stark reduziert ⚠️")
            desc = string.format(L["UI_EFFICIENCY_DESC_SEVERE"] or "Downranking-Malus: Stufe %d zu weit unter Level %d! Zaubermacht %d%%, Talent-Procs massiv gedrosselt.", reqLvl, playerLevel, pct)
        else
            status = "yellow"
            procChance = string.format(L["UI_PROC_REDUCED"] or "Reduziert (~%d%%)", pct)
            desc = string.format(L["UI_EFFICIENCY_DESC_MINOR"] or "Leichter Malus: Stufe %d. Zaubermacht bei %d%%, leichte Drosselung von Procs.", reqLvl, pct)
        end
    else
        status = "green"
        procChance = "100%"
        desc = string.format(L["UI_EFFICIENCY_DESC_OPTIMAL"] or "Optimaler Sweet Spot: Stufe %d >= %d. Volle Zaubermacht (100%%) & 100%% Talent-Procs!", reqLvl, levelThreshold)
    end

    return pct, status, procChance, reqLvl, desc
end

--------------------------------------------------------------------------------
-- Active Profile Helpers
--------------------------------------------------------------------------------
function RF:GetActiveProfile()
    RankForgeDB = RankForgeDB or { profiles = {} }
    RankForgeDB.profiles = RankForgeDB.profiles or {}
    RankForgeCharDB = RankForgeCharDB or {}
    local profileName = RankForgeCharDB.activeProfile or "Default"
    if not RankForgeDB.profiles[profileName] then
        RankForgeDB.profiles[profileName] = { macros = {} }
    end
    return RankForgeDB.profiles[profileName]
end

function RF:GetMacrosList()
    local profile = RF:GetActiveProfile()
    return profile.macros
end

--------------------------------------------------------------------------------
-- Macro Generator Logic
--------------------------------------------------------------------------------
-- Order priority for modifier specificity
local MODIFIER_SPECIFICITY = {
    ["shift_ctrl"] = 7,
    ["shift_alt"]  = 6,
    ["ctrl_alt"]   = 5,
    ["shift"]      = 4,
    ["ctrl"]       = 3,
    ["alt"]        = 2,
    ["nomod"]      = 1
}

local MODIFIER_CLAUSES = {
    ["shift_ctrl"] = "mod:shift,mod:ctrl",
    ["shift_alt"]  = "mod:shift,mod:alt",
    ["ctrl_alt"]   = "mod:ctrl,mod:alt",
    ["shift"]      = "mod:shift",
    ["ctrl"]       = "mod:ctrl",
    ["alt"]        = "mod:alt",
    ["nomod"]      = nil
}

local function BuildConditionSubstring(unit, isHelp, isHarm, isNodead)
    local parts = {}
    if unit and unit ~= "" and unit ~= "@target" then
        table.insert(parts, unit)
    end
    if isHelp then
        table.insert(parts, "help")
    elseif isHarm then
        table.insert(parts, "harm")
    end
    if isNodead then
        table.insert(parts, "nodead")
    end
    return table.concat(parts, ",")
end

function RF:BuildTargetConditionString(macroConfig)
    if macroConfig.customTarget and macroConfig.customTarget:trim() ~= "" then
        return macroConfig.customTarget:trim()
    end

    local clauses = {}

    -- Checkboxes
    if macroConfig.targetMouseoverStrict or macroConfig.targetMouseover then
        local isHelp = (macroConfig.targetMouseoverHelp ~= false) and not macroConfig.targetMouseoverHarm
        local isHarm = (macroConfig.targetMouseoverHarm == true)
        local isNodead = (macroConfig.targetMouseoverNodead ~= false)
        table.insert(clauses, BuildConditionSubstring("@mouseover", isHelp, isHarm, isNodead))
    end

    if macroConfig.targetFocus then
        local isHelp = (macroConfig.targetFocusHelp ~= false) and not macroConfig.targetFocusHarm
        local isHarm = (macroConfig.targetFocusHarm == true)
        local isNodead = (macroConfig.targetFocusNodead ~= false)
        table.insert(clauses, BuildConditionSubstring("@focus", isHelp, isHarm, isNodead))
    end

    if macroConfig.targetToT then
        local isHelp = (macroConfig.targetToTHelp ~= false) and not macroConfig.targetToTHarm
        local isHarm = (macroConfig.targetToTHarm == true)
        local isNodead = (macroConfig.targetToTNodead ~= false)
        table.insert(clauses, BuildConditionSubstring("@targettarget", isHelp, isHarm, isNodead))
    end

    return clauses
end

function RF:GetPlayerRacialSpell()
    local _, raceFile = UnitRace("player")
    local racialMap = {
        ["Troll"] = "Berserking",
        ["Orc"] = "Blood Fury",
        ["Scourge"] = "Will of the Forsaken",
        ["BloodElf"] = "Arcane Torrent",
        ["Tauren"] = "War Stomp",
        ["Dwarf"] = "Stoneform",
        ["Gnome"] = "Escape Artist",
        ["NightElf"] = "Shadowmeld",
        ["Draenei"] = "Gift of the Naaru",
        ["Human"] = "Perception"
    }
    local spellName = racialMap[raceFile]
    if spellName then
        local localized = (GetSpellInfo and GetSpellInfo(spellName)) or spellName
        return localized
    end
    return nil
end

-- Generates the macro text based on configuration and current learned spell ranks
function RF:GenerateMacroBody(macroConfig)
    if not macroConfig or not macroConfig.spellName or macroConfig.spellName == "" then
        return "#showtooltip\n/cast " .. (macroConfig and macroConfig.spellName or "")
    end

    -- Dynamically resolve localized spell name for current game client language
    local baseSpell, sID = RF:GetLocalizedSpellName(macroConfig.spellName, macroConfig.spellID)
    if sID and not macroConfig.spellID then
        macroConfig.spellID = sID
    end

    local spellInfo = RF:GetSpellRanksInfo(sID or baseSpell)
    local maxRank = spellInfo and spellInfo.maxRank or 1
    local fallbackMode = macroConfig.fallbackMode or "omit" -- "omit" or "rank1"

    -- Target clauses
    local targetClauses = RF:BuildTargetConditionString(macroConfig)

    -- Sort modifiers based on user order or default specificity
    local sortedMods = {}
    if macroConfig.modifiers and #macroConfig.modifiers > 0 then
        for idx, mod in ipairs(macroConfig.modifiers) do
            if mod.enabled then
                table.insert(sortedMods, {
                    mod = mod,
                    userIndex = idx,
                    priority = MODIFIER_SPECIFICITY[mod.key] or 0
                })
            end
        end
    end

    -- If user hasn't explicitly customized order, sort by specificity (two-keys first)
    if not macroConfig.customSortOrder then
        table.sort(sortedMods, function(a, b)
            return a.priority > b.priority
        end)
    end

    local castParts = {}

    for _, entry in ipairs(sortedMods) do
        local mod = entry.mod
        local modKey = mod.key
        local modCondition = MODIFIER_CLAUSES[modKey]

        local spellToCast = nil
        local rankSubtext = nil

        if mod.mode == "custom" and mod.customSpell and mod.customSpell ~= "" then
            spellToCast = RF:GetLocalizedSpellName(mod.customSpell, mod.customSpellID)
        else
            -- Relative mode
            local offset = tonumber(mod.rankOffset) or 0
            local targetRank = maxRank - offset

            if macroConfig.omitRank or macroConfig.noRank then
                -- When omitRank is enabled, cast clean spell name without any (Rank X) suffix
                spellToCast = baseSpell
                rankSubtext = nil
            elseif spellInfo and spellInfo.hasRanks then
                if targetRank >= 1 and targetRank <= maxRank then
                    spellToCast = baseSpell
                    local sub = (spellInfo.subtexts and spellInfo.subtexts[targetRank]) or string.format("%s %d", spellInfo.rankWord or L["RANK_WORD"], targetRank)
                    rankSubtext = sub
                else
                    -- Rank not yet learned
                    if fallbackMode == "rank1" then
                        spellToCast = baseSpell
                        local sub = (spellInfo.subtexts and spellInfo.subtexts[1]) or string.format("%s 1", spellInfo.rankWord or L["RANK_WORD"])
                        rankSubtext = sub
                    else
                        -- omit modifier until learned
                        spellToCast = nil
                    end
                end
            else
                -- Spell has no ranks
                if offset == 0 or fallbackMode == "rank1" then
                    spellToCast = baseSpell
                else
                    spellToCast = nil
                end
            end
        end

        if spellToCast then
            local fullSpellString = spellToCast
            if rankSubtext and rankSubtext ~= "" then
                fullSpellString = string.format("%s(%s)", spellToCast, rankSubtext)
            end

            -- Build bracketed conditions
            local conditionBlocks = {}
            if macroConfig.customTarget and macroConfig.customTarget:trim() ~= "" then
                local custom = macroConfig.customTarget:trim()
                if modCondition then
                    local formatted = custom:gsub("%[", "[" .. modCondition .. ",")
                    table.insert(conditionBlocks, formatted)
                else
                    table.insert(conditionBlocks, custom)
                end
            else
                local isMo = (macroConfig.targetMouseover ~= false)
                if mod.targetMouseover ~= nil then isMo = mod.targetMouseover end

                local isTarget = true
                if mod.targetTarget ~= nil then isTarget = mod.targetTarget end

                local isFocus = (macroConfig.targetFocus or false)
                if mod.targetFocus ~= nil then isFocus = mod.targetFocus end

                local isToT = (macroConfig.targetToT or false)
                if mod.targetToT ~= nil then isToT = mod.targetToT end

                local isSelfcast = (macroConfig.targetSelfcast or false)
                if mod.targetSelfcast ~= nil then isSelfcast = mod.targetSelfcast end

                local function ResolveFilter(unitKey, cfgHelp, cfgHarm, cfgNodead)
                    local h = false
                    local ha = false
                    local nd = true

                    if mod.isHelp ~= nil then
                        h = (mod.isHelp == true)
                    elseif cfgHelp ~= nil then
                        h = (cfgHelp == true and not cfgHarm)
                    else
                        h = true
                    end

                    if mod.isHarm ~= nil then
                        ha = (mod.isHarm == true)
                    elseif cfgHarm ~= nil then
                        ha = (cfgHarm == true)
                    else
                        ha = false
                    end

                    if mod.isNodead ~= nil then
                        nd = (mod.isNodead == true)
                    elseif cfgNodead ~= nil then
                        nd = (cfgNodead ~= false)
                    else
                        nd = true
                    end

                    -- Help and harm are mutually exclusive!
                    if h and ha then
                        ha = false
                    end

                    return h, ha, nd
                end

                local moHelp, moHarm, moNodead = ResolveFilter("mo", macroConfig.targetMouseoverHelp, macroConfig.targetMouseoverHarm, macroConfig.targetMouseoverNodead)
                local tgtHelp, tgtHarm, tgtNodead = ResolveFilter("target", macroConfig.targetHelp, macroConfig.targetHarm, macroConfig.targetNodead)
                local focusHelp, focusHarm, focusNodead = ResolveFilter("focus", macroConfig.targetFocusHelp, macroConfig.targetFocusHarm, macroConfig.targetFocusNodead)
                local totHelp, totHarm, totNodead = ResolveFilter("tot", macroConfig.targetToTHelp, macroConfig.targetToTHarm, macroConfig.targetToTNodead)

                local targets = {}
                if isMo then
                    table.insert(targets, BuildConditionSubstring("@mouseover", moHelp, moHarm, moNodead))
                end
                if isFocus then
                    table.insert(targets, BuildConditionSubstring("@focus", focusHelp, focusHarm, focusNodead))
                end
                if isToT then
                    table.insert(targets, BuildConditionSubstring("@targettarget", totHelp, totHarm, totNodead))
                end

                for _, tgt in ipairs(targets) do
                    if tgt ~= "" then
                        if modCondition then
                            table.insert(conditionBlocks, string.format("[%s,%s]", modCondition, tgt))
                        else
                            table.insert(conditionBlocks, string.format("[%s]", tgt))
                        end
                    end
                end

                if isTarget and isSelfcast then
                    -- Both Target and Selfcast active:
                    local tgtCond = BuildConditionSubstring("@target", tgtHelp, tgtHarm, tgtNodead)
                    if tgtCond ~= "" then
                        if modCondition then
                            table.insert(conditionBlocks, string.format("[%s,%s]", modCondition, tgtCond))
                        else
                            table.insert(conditionBlocks, string.format("[%s]", tgtCond))
                        end
                    end
                    if modCondition then
                        table.insert(conditionBlocks, string.format("[%s,@player]", modCondition))
                    else
                        table.insert(conditionBlocks, "[@player]")
                    end
                elseif isTarget then
                    local tgtCond = BuildConditionSubstring("@target", tgtHelp, tgtHarm, tgtNodead)
                    if tgtCond ~= "" then
                        if modCondition then
                            table.insert(conditionBlocks, string.format("[%s,%s]", modCondition, tgtCond))
                        else
                            table.insert(conditionBlocks, string.format("[%s]", tgtCond))
                            table.insert(conditionBlocks, "[]")
                        end
                    else
                        if modCondition then
                            table.insert(conditionBlocks, string.format("[%s]", modCondition))
                        else
                            table.insert(conditionBlocks, "[]")
                        end
                    end
                elseif isSelfcast then
                    if modCondition then
                        table.insert(conditionBlocks, string.format("[%s,@player]", modCondition))
                    else
                        table.insert(conditionBlocks, "[@player]")
                        table.insert(conditionBlocks, "[]")
                    end
                elseif #targets == 0 then
                    if modCondition then
                        table.insert(conditionBlocks, string.format("[%s]", modCondition))
                    else
                        table.insert(conditionBlocks, "[]")
                    end
                else
                    -- Specific target unit(s) like @mouseover only (no explicit Target or Selfcast).
                    -- For modifiers, add [modCondition] fallback so holding the modifier displays its tooltip on action bars.
                    -- For nomod, add [] fallback so the action bar displays the default tooltip without mouseover!
                    if modCondition then
                        table.insert(conditionBlocks, string.format("[%s]", modCondition))
                    else
                        table.insert(conditionBlocks, "[]")
                    end
                end
            end

            local condStr = table.concat(conditionBlocks, "")
            if condStr ~= "" then
                table.insert(castParts, condStr .. " " .. fullSpellString)
            else
                table.insert(castParts, fullSpellString)
            end
        end
    end

    -- If no conditions were met or all omitted, fallback to base spell
    if #castParts == 0 then
        table.insert(castParts, baseSpell)
    else
        local hasNomod = false
        for _, entry in ipairs(sortedMods) do
            if entry.mod.key == "nomod" then
                hasNomod = true
                break
            end
        end
        if not hasNomod then
            local maxRankString = baseSpell
            if not macroConfig.omitRank and not macroConfig.noRank and spellInfo and spellInfo.hasRanks and maxRank > 0 then
                local sub = (spellInfo.subtexts and spellInfo.subtexts[maxRank]) or string.format("%s %d", spellInfo.rankWord or L["RANK_WORD"], maxRank)
                maxRankString = string.format("%s(%s)", baseSpell, sub)
            end
            table.insert(castParts, "[] " .. maxRankString)
        end
    end

    local preCastLines = {}
    if macroConfig.startAttack then
        table.insert(preCastLines, "/startattack")
    end
    if macroConfig.petAttack then
        table.insert(preCastLines, "/petattack")
    end
    if macroConfig.useTrinket1 then
        table.insert(preCastLines, "/use 13")
    end
    if macroConfig.useTrinket2 then
        table.insert(preCastLines, "/use 14")
    end
    if macroConfig.useRacial then
        local racial = RF:GetPlayerRacialSpell()
        if racial then
            table.insert(preCastLines, "/cast " .. racial)
        end
    end
    if macroConfig.preCastLines and macroConfig.preCastLines:trim() ~= "" then
        for line in macroConfig.preCastLines:gmatch("[^\r\n]+") do
            local clean = line:trim()
            if clean ~= "" then
                if not clean:match("^/") then
                    clean = "/use " .. clean
                end
                table.insert(preCastLines, clean)
            end
        end
    end

    -- Write spell name in #showtooltip ONLY when pre-cast commands (/startattack, /use etc.) precede /cast.
    -- When no pre-cast commands exist, bare "#showtooltip" lets WoW dynamically evaluate the /cast conditions
    -- (showing the exact rank / spell for the currently held modifier) and saves precious characters!
    local tooltipHeader = "#showtooltip"
    if #preCastLines > 0 and baseSpell and baseSpell ~= "" then
        tooltipHeader = "#showtooltip " .. baseSpell
    end

    local macroLines = {
        tooltipHeader
    }

    for _, line in ipairs(preCastLines) do
        table.insert(macroLines, line)
    end

    table.insert(macroLines, "/cast " .. table.concat(castParts, ";"))

    local macroBody = table.concat(macroLines, "\n")

    -- Smart length optimizer: if macro exceeds 255 chars, progressively compress
    if #macroBody > 255 then
        macroBody = macroBody:gsub("%[help,nodead%]%[@player%]%[%]", "[]")
        macroBody = macroBody:gsub("%[help,nodead%]%[@player%]", "[]")
        macroBody = macroBody:gsub("%[@target,help,nodead%]%[@player%]%[%]", "[]")
        macroBody = macroBody:gsub("%[@target,help,nodead%]%[@player%]", "[]")
        macroBody = macroBody:gsub("%[@target,help,nodead%]", "[help,nodead]")
        macroBody = macroBody:gsub("%[@target,harm,nodead%]", "[harm,nodead]")
    end
    if #macroBody > 255 then
        macroBody = macroBody:gsub(",nodead", "")
    end
    if #macroBody > 255 and macroBody:find("^#showtooltip .-\n") then
        macroBody = macroBody:gsub("^#showtooltip [^\n]+", "#showtooltip")
    end

    return macroBody
end

--------------------------------------------------------------------------------
-- WoW Macro Synchronization & Slot Management
--------------------------------------------------------------------------------
function RF:GetAvailableMacroSlots(isAccount)
    local numAccount, numCharacter = GetNumMacros()
    local maxAccount = MAX_ACCOUNT_MACROS or 120
    local maxCharacter = MAX_CHARACTER_MACROS or 18

    if isAccount then
        return maxAccount - numAccount, numAccount, maxAccount
    else
        return maxCharacter - numCharacter, numCharacter, maxCharacter
    end
end

function RF:FindMacroIndex(macroName)
    if not macroName or macroName == "" then return nil, nil end
    local numAccount, numCharacter = GetNumMacros()
    local maxAccount = MAX_ACCOUNT_MACROS or 120

    -- 1. Search account macros (1 to numAccount)
    local accLimit = (numAccount and numAccount > 0) and numAccount or maxAccount
    for i = 1, accLimit do
        local name, icon, body, isLocal = GetMacroInfo(i)
        if name and name:lower() == macroName:lower() then
            local isAcc = true
            if isLocal ~= nil then
                isAcc = not isLocal
            end
            return i, isAcc
        end
    end

    -- 2. Search character macros (maxAccount + 1 to maxAccount + numCharacter)
    local charLimit = (numCharacter and numCharacter > 0) and numCharacter or 36
    for i = maxAccount + 1, maxAccount + charLimit do
        local name, icon, body, isLocal = GetMacroInfo(i)
        if name and name:lower() == macroName:lower() then
            local isAcc = false
            if isLocal ~= nil then
                isAcc = not isLocal
            end
            return i, isAcc
        end
    end

    -- 3. Fallback scan across all slots 1 to 200
    for i = 1, 200 do
        local name, icon, body, isLocal = GetMacroInfo(i)
        if name and name:lower() == macroName:lower() then
            local isAcc = (i <= maxAccount)
            if isLocal ~= nil then
                isAcc = not isLocal
            end
            return i, isAcc
        end
    end

    return nil, nil
end

function RF:SyncMacro(macroConfig, silent)
    if InCombatLockdown() then
        RF.queuedMacroUpdates = true
        if not silent then
            print(L["COMBAT_LOCKDOWN_QUEUED"])
        end
        return false, "combat"
    end

    if not macroConfig or not macroConfig.macroName or macroConfig.macroName == "" then
        return false, "invalid_name"
    end

    local macroName = macroConfig.macroName
    local isAccount = (macroConfig.isAccount ~= false) -- default true (General / Account slot with 120 slots)
    local macroBody = RF:GenerateMacroBody(macroConfig)
    local icon = "INV_MISC_QUESTIONMARK"

    local existingIndex, existingIsAccount = RF:FindMacroIndex(macroName)

    if existingIndex then
        local _, currIcon = GetMacroInfo(existingIndex)
        local targetIcon = currIcon or icon

        if existingIsAccount ~= isAccount then
            -- Storage location changed (Account <-> Character tab)! Move macro
            local freeSlots, used, maxSlots = RF:GetAvailableMacroSlots(isAccount)
            if freeSlots <= 0 then
                local warn = isAccount and L["MACRO_LIMIT_ACCOUNT_FULL"] or L["MACRO_LIMIT_CHAR_FULL"]
                print(warn)
                return false, "limit_reached"
            end

            DeleteMacro(existingIndex)
            local newIndex = CreateMacro(macroName, targetIcon, macroBody, not isAccount)
            if not silent then
                print(string.format(L["MACRO_CREATED"], macroName))
            end
            return true, "moved", newIndex
        else
            -- Macro already exists in correct tab: update body
            EditMacro(existingIndex, macroName, targetIcon, macroBody)
            if not silent then
                print(string.format(L["MACRO_SYNC_SUCCESS"], macroName))
            end
            return true, "updated", existingIndex
        end
    else
        -- Create new macro
        local freeSlots, used, maxSlots = RF:GetAvailableMacroSlots(isAccount)
        if freeSlots <= 0 then
            local warn = isAccount and L["MACRO_LIMIT_ACCOUNT_FULL"] or L["MACRO_LIMIT_CHAR_FULL"]
            print(warn)
            return false, "limit_reached"
        end

        local newIndex = CreateMacro(macroName, icon, macroBody, not isAccount)
        if not silent then
            print(string.format(L["MACRO_CREATED"], macroName))
        end
        return true, "created", newIndex
    end
end

function RF:SyncAllMacros(silent)
    if InCombatLockdown() then
        RF.queuedMacroUpdates = true
        if not silent then
            print(L["COMBAT_LOCKDOWN_QUEUED"])
        end
        return
    end

    RF:ScanSpellBook()
    local macros = RF:GetMacrosList()
    local count = 0

    for _, macroConfig in ipairs(macros) do
        local success = RF:SyncMacro(macroConfig, true)
        if success then count = count + 1 end
    end

    if not silent then
        local msg = L["MACRO_SYNC_ALL_SUCCESS"] or "|cff00ccffRankForge:|r %d macros updated."
        print(string.format(msg, count))
    end

    if RF.UpdateUI and RF.MainFrame and RF.MainFrame:IsShown() then
        RF:UpdateUI()
    end
end

function RF:DeleteMacro(macroConfig, deleteFromWoW)
    if not macroConfig then return end

    if deleteFromWoW then
        if not InCombatLockdown() then
            local index = RF:FindMacroIndex(macroConfig.macroName)
            if index then
                DeleteMacro(index)
                print(string.format(L["MACRO_DELETED"], macroConfig.macroName))
            end
        else
            print(L["COMBAT_LOCKDOWN_QUEUED"])
        end
    end

    local macros = RF:GetMacrosList()
    for i, cfg in ipairs(macros) do
        if cfg == macroConfig or cfg.macroName == macroConfig.macroName then
            table.remove(macros, i)
            break
        end
    end

    if RF.UpdateUI and RF.MainFrame and RF.MainFrame:IsShown() then
        RF:UpdateUI()
    end
end

function RF:CloneMacro(macroConfig)
    if not macroConfig then return nil end

    local baseName = macroConfig.macroName or "DR_Macro"
    local macros = RF:GetMacrosList()

    -- Generate a unique clone name
    local suffix = L["MACRO_COPY_SUFFIX"] or "_Copy"
    local newName = baseName .. suffix
    local counter = 2
    local function NameExists(n)
        for _, m in ipairs(macros) do
            if m.macroName and m.macroName:lower() == n:lower() then
                return true
            end
        end
        return false
    end

    while NameExists(newName) do
        newName = string.format("%s%s%d", baseName, suffix, counter)
        counter = counter + 1
    end

    local charName, realm, charClass = RF:GetCurrentCharacterKey()

    -- Deep copy the macro configuration
    local cloned = {
        macroName = newName,
        spellName = macroConfig.spellName or "",
        character = charName,
        realm = realm,
        class = macroConfig.class or charClass,
        isAccount = (macroConfig.isAccount == true),
        fallbackMode = macroConfig.fallbackMode or "omit",
        omitRank = (macroConfig.omitRank == true),
        targetMouseover = macroConfig.targetMouseover,
        customTarget = macroConfig.customTarget or "",
        customSortOrder = macroConfig.customSortOrder or false,
        useTrinket1 = macroConfig.useTrinket1 or false,
        useTrinket2 = macroConfig.useTrinket2 or false,
        useRacial = macroConfig.useRacial or false,
        startAttack = macroConfig.startAttack or false,
        petAttack = macroConfig.petAttack or false,
        preCastLines = macroConfig.preCastLines or "",
        modifiers = {}
    }

    if macroConfig.modifiers then
        for _, mod in ipairs(macroConfig.modifiers) do
            table.insert(cloned.modifiers, {
                key = mod.key,
                enabled = mod.enabled,
                mode = mod.mode or "relative",
                rankOffset = mod.rankOffset or 0,
                customSpell = mod.customSpell or "",
                targetMouseover = mod.targetMouseover,
                targetTarget = mod.targetTarget,
                targetFocus = mod.targetFocus,
                targetToT = mod.targetToT,
                targetSelfcast = mod.targetSelfcast,
                isHelp = mod.isHelp,
                isHarm = mod.isHarm,
                isNodead = mod.isNodead,
            })
        end
    end

    table.insert(macros, cloned)
    return cloned
end

--------------------------------------------------------------------------------
-- Automatic Macro Recovery from WoW Native Macro Window
--------------------------------------------------------------------------------
function RF:RecoverMacrosFromWoW()
    local macros = RF:GetMacrosList()
    local charName, realm, charClass = RF:GetCurrentCharacterKey()

    -- Check if profile is empty or only contains a fresh dummy macro
    local onlyDummy = (#macros == 0)
    if #macros == 1 and macros[1].macroName == "DR_New" and (not macros[1].spellName or macros[1].spellName == "") then
        onlyDummy = true
    end

    if not onlyDummy then
        return false
    end

    local recovered = {}
    local numAccount, numCharacter = GetNumMacros()
    local maxAccount = MAX_ACCOUNT_MACROS or 120

    local function ParseWoWMacro(name, body, isAccount)
        if not name or not name:match("^DR_") then return nil end
        if name:match("^DR_Test") or name:match("^DR_CloneTest") or name == "DR_New" then return nil end

        -- Extract spellName from #showtooltip or /cast
        local spellName = body:match("#showtooltip[ \t]+([^\r\n]+)")
        if not spellName or spellName == "" then
            spellName = body:match("/[cC][aA][sS][tT]%s+.-%]%s*([^%(%[\r\n;]+)")
        end
        if not spellName or spellName == "" then
            spellName = body:match("/[cC][aA][sS][tT]%s+([^%(%[\r\n;]+)")
        end
        if not spellName or spellName == "" then
            spellName = body:match("/cast%s+.-([%a%s]+)%(Rang")
        end
        if not spellName or spellName == "" then
            spellName = body:match("/cast%s+.-([%a%s]+)%(")
        end
        if not spellName or spellName == "" then
            spellName = body:match("/cast%s+.-([%a%s]+)")
        end
        if spellName then spellName = spellName:trim() end

        local macroClass = (spellName and RF:GetClassForSpell(spellName)) or charClass

        local cfg = {
            macroName = name,
            spellName = spellName or name:gsub("^DR_", ""),
            character = isAccount and "" or charName,
            realm = realm,
            class = macroClass,
            isAccount = isAccount,
            fallbackMode = "omit",
            targetMouseover = (body:find("@mouseover") ~= nil),
            customTarget = "",
            customSortOrder = false,
            useTrinket1 = (body:find("/use 13") ~= nil),
            useTrinket2 = (body:find("/use 14") ~= nil),
            useRacial = (body:find("/cast Berserking") ~= nil or body:find("/cast Kochendes Blut") ~= nil or body:find("/cast Blutrausch") ~= nil),
            startAttack = (body:find("/startattack") ~= nil),
            petAttack = (body:find("/petattack") ~= nil),
            preCastLines = "",
            modifiers = {}
        }

        local isHelp = (body:find("help") ~= nil)
        local isHarm = (body:find("harm") ~= nil) or cfg.startAttack

        local mods = {
            { key = "shift_ctrl", enabled = false, mode = "relative", rankOffset = 3 },
            { key = "shift_alt",  enabled = false, mode = "relative", rankOffset = 4 },
            { key = "ctrl_alt",   enabled = false, mode = "relative", rankOffset = 5 },
            { key = "shift",      enabled = (body:find("mod:shift") ~= nil), mode = "relative", rankOffset = 1 },
            { key = "ctrl",       enabled = (body:find("mod:ctrl") ~= nil),  mode = "relative", rankOffset = 2 },
            { key = "alt",        enabled = (body:find("mod:alt") ~= nil),   mode = "relative", rankOffset = 2 },
            { key = "nomod",      enabled = true, mode = "relative", rankOffset = 0 },
        }

        for _, m in ipairs(mods) do
            table.insert(cfg.modifiers, {
                key = m.key,
                enabled = m.enabled,
                mode = m.mode,
                rankOffset = m.rankOffset,
                customSpell = "",
                targetMouseover = cfg.targetMouseover,
                targetTarget = true,
                targetFocus = false,
                targetToT = false,
                targetSelfcast = isHelp,
                isHelp = isHelp,
                isHarm = isHarm,
                isNodead = true
            })
        end

        return cfg
    end

    -- 1. Scan Account macros
    local accLimit = (numAccount and numAccount > 0) and numAccount or 0
    for i = 1, accLimit do
        local name, icon, body = GetMacroInfo(i)
        if name and body then
            local parsed = ParseWoWMacro(name, body, true)
            if parsed then
                table.insert(recovered, parsed)
            end
        end
    end

    -- 2. Scan Character macros
    local charLimit = (numCharacter and numCharacter > 0) and numCharacter or 0
    for i = maxAccount + 1, maxAccount + charLimit do
        local name, icon, body = GetMacroInfo(i)
        if name and body then
            local parsed = ParseWoWMacro(name, body, false)
            if parsed then
                table.insert(recovered, parsed)
            end
        end
    end

    if #recovered > 0 then
        wipe(macros)
        for _, rec in ipairs(recovered) do
            table.insert(macros, rec)
        end
        return true
    end

    return false
end

--------------------------------------------------------------------------------
-- Default Presets Initializer
--------------------------------------------------------------------------------
function RF:ApplyInitialPresetsIfEmpty()
    local macros = RF:GetMacrosList()
    if #macros == 0 then
        local charName, realm, charClass = RF:GetCurrentCharacterKey()
        if charClass then
            local presets = RF:GetPresetsForClass(charClass)
            for _, preset in ipairs(presets) do
                preset.class = charClass
                preset.character = charName
                preset.realm = realm
                table.insert(macros, preset)
            end
            RF:SyncAllMacros(true)
        end
    end
end

--------------------------------------------------------------------------------
-- Event Frame & Slash Commands
--------------------------------------------------------------------------------
local EventFrame = CreateFrame("Frame")

local function SafeRegisterEvent(frame, eventName)
    pcall(frame.RegisterEvent, frame, eventName)
end

SafeRegisterEvent(EventFrame, "ADDON_LOADED")
SafeRegisterEvent(EventFrame, "PLAYER_LOGIN")
SafeRegisterEvent(EventFrame, "PLAYER_REGEN_ENABLED")
SafeRegisterEvent(EventFrame, "PLAYER_LEVEL_UP")
SafeRegisterEvent(EventFrame, "SPELLS_CHANGED")
SafeRegisterEvent(EventFrame, "TRAINER_UPDATE")
SafeRegisterEvent(EventFrame, "UPDATE_MACROS")

EventFrame:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Initialize SavedVariables
        RankForgeDB = RankForgeDB or {}
        for k, v in pairs(defaultDB) do
            if RankForgeDB[k] == nil then
                RankForgeDB[k] = v
            end
        end

        RankForgeCharDB = RankForgeCharDB or {}
        for k, v in pairs(defaultCharDB) do
            if RankForgeCharDB[k] == nil then
                RankForgeCharDB[k] = v
            end
        end

        if RF.SetLocale then
            RF:SetLocale(RankForgeDB.locale or "auto")
        end

    elseif event == "PLAYER_LOGIN" then
        RF:ScanSpellBook()
        local recovered = RF:RecoverMacrosFromWoW()
        if not recovered then
            RF:ApplyInitialPresetsIfEmpty()
        end
        if RF.InitMinimapButton then
            RF:InitMinimapButton()
        end
        RF.isInitialized = true

        if RankForgeDB and RankForgeDB.debugMode then
            if C_Timer and C_Timer.After then
                C_Timer.After(0.1, function()
                    if RF.ToggleUI and (not RF.MainFrame or not RF.MainFrame:IsShown()) then
                        RF:ToggleUI()
                    end
                end)
            else
                if RF.ToggleUI and (not RF.MainFrame or not RF.MainFrame:IsShown()) then
                    RF:ToggleUI()
                end
            end
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        if RF.queuedMacroUpdates then
            RF.queuedMacroUpdates = false
            RF:SyncAllMacros(false)
        end

    elseif event == "PLAYER_LEVEL_UP" or event == "SPELLS_CHANGED" or event == "TRAINER_UPDATE" then
        if RF.isInitialized then
            RF:ScanSpellBook()
            if not InCombatLockdown() then
                RF:SyncAllMacros(true)
                if RF.UpdateUI and RF.MainFrame and RF.MainFrame:IsShown() then
                    RF:UpdateUI()
                end
            else
                RF.queuedMacroUpdates = true
            end
        end

    elseif event == "UPDATE_MACROS" then
        if RF.UpdateSlotStatus then
            RF:UpdateSlotStatus()
        end
    end
end)

--------------------------------------------------------------------------------
-- Slash Commands
--------------------------------------------------------------------------------
local function SlashHandler(msg)
    msg = msg and msg:trim():lower() or ""

    if msg == "update" or msg == "sync" then
        RF:SyncAllMacros(false)
    elseif msg == "debug" then
        RankForgeDB = RankForgeDB or {}
        RankForgeDB.debugMode = not RankForgeDB.debugMode
        if RankForgeDB.debugMode then
            print(L["SLASH_DEBUG_ON"] or "|cff00ccffRankForge:|r Debug mode |cff00ff00ENABLED|r (Window will open automatically after reload).")
        else
            print(L["SLASH_DEBUG_OFF"] or "|cff00ccffRankForge:|r Debug mode |cffff2222DISABLED|r.")
        end
        if RF.MainFrame and RF.MainFrame.cbDebug then
            RF.MainFrame.cbDebug:SetChecked(RankForgeDB.debugMode)
        end
    elseif msg == "test" then
        if RF.RunAllTests then
            RF:RunAllTests()
        else
            print("|cffff3333RankForge:|r Test-Suite nicht geladen.")
        end
    elseif msg == "help" then
        print(L["SLASH_HELP_1"])
        print(L["SLASH_HELP_2"])
        print(L["SLASH_HELP_3"])
        print(L["SLASH_HELP_5"])
        print(L["SLASH_HELP_TEST"])
        print(L["SLASH_HELP_4"])
    else
        if RF.ToggleUI then
            RF:ToggleUI()
        else
            print(L["SLASH_HELP_1"])
        end
    end
end

SLASH_RANKFORGE1 = "/rankforge"
SLASH_RANKFORGE2 = "/rf"
SLASH_RANKFORGE3 = "/drm"
SlashCmdList["RANKFORGE"] = SlashHandler
