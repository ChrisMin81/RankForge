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
    profiles = {
        ["Default"] = {
            macros = {}
        }
    }
}

local defaultCharDB = {
    activeProfile = "Default"
}

--------------------------------------------------------------------------------
-- Utilities: Spell Scanning (Classic Era / TBC / Modern compatible)
--------------------------------------------------------------------------------
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

        -- Check legacy GetSpellBookItemName fallback
        if (not spellName or spellName == "") and GetSpellBookItemName then
            local ok, n, sub = pcall(GetSpellBookItemName, i, BOOKTYPE_SPELL or "spell")
            if ok and n and n ~= "" then
                spellName = n
                if sub and sub ~= "" then
                    subtext = sub
                end
                if GetSpellBookItemInfo then
                    local okInfo, itemType, id = pcall(GetSpellBookItemInfo, i, BOOKTYPE_SPELL or "spell")
                    if okInfo then
                        spellID = id
                    end
                end
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
        end
    end
end

function RF:GetSpellRanksInfo(spellName)
    if not spellName or spellName == "" then return nil end
    local info = RF.knownSpells[spellName]
    if not info then
        -- Refresh scan if not found
        RF:ScanSpellBook()
        info = RF.knownSpells[spellName]
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

function RF:IsSpellHarmful(spellName)
    if not spellName or spellName == "" then return false end
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
            if mod.key == "nomod" then
                mod.targetSelfcast = true
            else
                mod.targetSelfcast = false
            end
            mod.targetTarget = true
        end
    end
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
    local parts = { unit }
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

    local baseSpell = macroConfig.spellName
    local spellInfo = RF:GetSpellRanksInfo(baseSpell)
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
            spellToCast = mod.customSpell
        else
            -- Relative mode
            local offset = tonumber(mod.rankOffset) or 0
            local targetRank = maxRank - offset

            if spellInfo and spellInfo.hasRanks then
                if targetRank >= 1 and targetRank <= maxRank then
                    spellToCast = baseSpell
                    local sub = spellInfo.subtexts[targetRank] or string.format("%s %d", spellInfo.rankWord or L["RANK_WORD"], targetRank)
                    rankSubtext = sub
                else
                    -- Rank not yet learned
                    if fallbackMode == "rank1" then
                        spellToCast = baseSpell
                        local sub = spellInfo.subtexts[1] or string.format("%s 1", spellInfo.rankWord or L["RANK_WORD"])
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
                if isTarget then
                    table.insert(targets, BuildConditionSubstring("@target", tgtHelp, tgtHarm, tgtNodead))
                end
                if isToT then
                    table.insert(targets, BuildConditionSubstring("@targettarget", totHelp, totHarm, totNodead))
                end

                for _, tgt in ipairs(targets) do
                    if modCondition then
                        table.insert(conditionBlocks, string.format("[%s,%s]", modCondition, tgt))
                    else
                        table.insert(conditionBlocks, string.format("[%s]", tgt))
                    end
                end

                if isSelfcast then
                    if modCondition then
                        table.insert(conditionBlocks, string.format("[%s,@player]", modCondition))
                    else
                        table.insert(conditionBlocks, "[@player]")
                    end
                elseif #targets == 0 then
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
    end

    local macroLines = {
        "#showtooltip"
    }

    if macroConfig.useTrinket1 then
        table.insert(macroLines, "/use 13")
    end
    if macroConfig.useTrinket2 then
        table.insert(macroLines, "/use 14")
    end
    if macroConfig.useRacial then
        local racial = RF:GetPlayerRacialSpell()
        if racial then
            table.insert(macroLines, "/cast " .. racial)
        end
    end
    if macroConfig.preCastLines and macroConfig.preCastLines:trim() ~= "" then
        for line in macroConfig.preCastLines:gmatch("[^\r\n]+") do
            local clean = line:trim()
            if clean ~= "" then
                if not clean:match("^/") then
                    clean = "/use " .. clean
                end
                table.insert(macroLines, clean)
            end
        end
    end

    table.insert(macroLines, "/cast " .. table.concat(castParts, ";"))

    return table.concat(macroLines, "\n")
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
    local isAccount = macroConfig.isAccount ~= false -- default true
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

    if RF.UpdateUI then
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

    -- Deep copy the macro configuration
    local cloned = {
        macroName = newName,
        spellName = macroConfig.spellName or "",
        isAccount = (macroConfig.isAccount ~= false),
        fallbackMode = macroConfig.fallbackMode or "omit",
        targetMouseover = macroConfig.targetMouseover,
        customTarget = macroConfig.customTarget or "",
        customSortOrder = macroConfig.customSortOrder or false,
        useTrinket1 = macroConfig.useTrinket1 or false,
        useTrinket2 = macroConfig.useTrinket2 or false,
        useRacial = macroConfig.useRacial or false,
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
-- Default Presets Initializer
--------------------------------------------------------------------------------
function RF:ApplyInitialPresetsIfEmpty()
    local macros = RF:GetMacrosList()
    if #macros == 0 then
        local _, classFileName = UnitClass("player")
        if classFileName then
            local presets = RF:GetPresetsForClass(classFileName)
            for _, preset in ipairs(presets) do
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
        RF:ApplyInitialPresetsIfEmpty()
        if RF.InitMinimapButton then
            RF:InitMinimapButton()
        end
        RF.isInitialized = true

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
                if RF.UpdateUI then
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
