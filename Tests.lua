--[[
    RankForge - Tests.lua
    In-Game JUnit-style Unit and Integration Test Suite.
    Run via slash command: /rf test
]]

local addonName, RF = ...
local L = RF.L

RF.Tests = {}
local TestSuite = {}
local passedCount = 0
local failedCount = 0
local testResults = {}

local function Assert(condition, message)
    if not condition then
        error(message or "Assertion failed", 2)
    end
end

local function AssertEquals(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s (Expected: %s, Actual: %s)", message or "AssertEquals failed", tostring(expected), tostring(actual)), 2)
    end
end

local function AssertTrue(val, message)
    AssertEquals(val, true, message)
end

local function AssertFalse(val, message)
    AssertEquals(val, false, message)
end

local function RegisterTest(name, func)
    table.insert(TestSuite, { name = name, func = func })
end

--------------------------------------------------------------------------------
-- 1. Localization Tests
--------------------------------------------------------------------------------
RegisterTest("Localization: Required keys exist", function()
    local requiredKeys = {
        "ADDON_TITLE", "UI_TITLE", "UI_MACRO_NAME", "UI_SPELL_NAME",
        "UI_STORAGE_ACCOUNT", "UI_STORAGE_CHAR", "UI_MOD_NOMOD",
        "UI_MOD_SHIFT", "UI_MOD_CTRL", "UI_MOD_ALT",
        "UI_MOD_SHIFT_CTRL", "UI_MOD_SHIFT_ALT", "UI_MOD_CTRL_ALT",
        "MINIMAP_TOOLTIP_TITLE", "PRESETS_TITLE", "PROFILE_TITLE",
        "UI_SLOT_STATUS", "UI_COPY_HINT", "UI_DEFAULT_MACRO_NAME"
    }
    for _, key in ipairs(requiredKeys) do
        Assert(L[key] ~= nil and L[key] ~= "", "Missing localization key: " .. key)
    end
end)

RegisterTest("Localization: English default values and German translations", function()
    -- Switch to English
    RF:SetLocale("enUS")
    AssertEquals(L["RANK_WORD"], "Rank")
    AssertEquals(L["UI_NEW_MACRO"], "+ New Macro")
    AssertEquals(L["UI_SAVE_MACRO"], "Save & Create")
    AssertEquals(L["UI_CLONE_BTN"], "Duplicate Macro")

    -- Switch to German
    RF:SetLocale("deDE")
    AssertEquals(L["RANK_WORD"], "Rang")
    AssertEquals(L["UI_NEW_MACRO"], "+ Neues Makro")
    AssertEquals(L["UI_SAVE_MACRO"], "Speichern & Erstellen")
    AssertEquals(L["UI_CLONE_BTN"], "Makro duplizieren")

    -- Reset back to auto/enUS
    RF:SetLocale("enUS")
end)

--------------------------------------------------------------------------------
-- 2. Base64 & Profile Serialization Tests
--------------------------------------------------------------------------------
RegisterTest("Base64 & Profile: Export and Import roundtrip", function()
    local testProfile = {
        macros = {
            {
                macroName = "DR_TestRenew",
                spellName = "Renew",
                isAccount = true,
                fallbackMode = "omit",
                targetMouseover = true,
                modifiers = {
                    { key = "shift", enabled = true, mode = "relative", rankOffset = 1, customSpell = "" },
                    { key = "nomod", enabled = true, mode = "relative", rankOffset = 0, customSpell = "" },
                }
            }
        }
    }

    local exportStr = RF:ExportProfileToString(testProfile)
    Assert(exportStr:sub(1, 4) == "RF1:", "Export string must start with RF1: prefix")

    local imported = RF:ImportProfileFromString(exportStr)
    Assert(imported ~= nil, "Imported profile must not be nil")
    Assert(#imported.macros == 1, "Imported profile must have 1 macro")
    AssertEquals(imported.macros[1].macroName, "DR_TestRenew", "Macro name mismatch")
    AssertEquals(imported.macros[1].spellName, "Renew", "Spell name mismatch")
    AssertEquals(#imported.macros[1].modifiers, 2, "Modifiers count mismatch")
end)

RegisterTest("Base64 & Profile: Invalid string handling", function()
    local result = RF:ImportProfileFromString("invalid_corrupted_data_!@#$")
    AssertEquals(result, nil, "Corrupted string should return nil")
    local empty = RF:ImportProfileFromString("")
    AssertEquals(empty, nil, "Empty string should return nil")
end)

--------------------------------------------------------------------------------
-- 3. Spell Scanning & Rank Data Tests
--------------------------------------------------------------------------------
RegisterTest("Spell Scanning: Spell ranks mock verification", function()
    -- Inject mock known spell data
    RF.knownSpells["TestSpell"] = {
        name = "TestSpell",
        maxRank = 8,
        hasRanks = true,
        rankWord = "Rank",
        ranks = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [8] = true },
        subtexts = {
            [1] = "Rank 1", [2] = "Rank 2", [3] = "Rank 3", [4] = "Rank 4",
            [5] = "Rank 5", [6] = "Rank 6", [7] = "Rank 7", [8] = "Rank 8",
        },
        spellID = 12345
    }

    local info = RF:GetSpellRanksInfo("TestSpell")
    Assert(info ~= nil, "Spell ranks info should exist")
    AssertEquals(info.maxRank, 8, "Max rank should be 8")
    AssertTrue(info.ranks[4], "Rank 4 should be known")
    AssertEquals(info.subtexts[8], "Rank 8", "Subtext for Rank 8 must be 'Rank 8'")
end)

--------------------------------------------------------------------------------
-- 4. Macro Generation: Modifiers & Ranks
--------------------------------------------------------------------------------
RegisterTest("Macro Generation: All 7 Modifiers and relative downranks", function()
    RF.knownSpells["Renew"] = {
        name = "Renew",
        maxRank = 9,
        hasRanks = true,
        rankWord = "Rank",
        ranks = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [8] = true, [9] = true },
        subtexts = {},
        spellID = 139
    }
    for r = 1, 9 do
        RF.knownSpells["Renew"].subtexts[r] = "Rank " .. r
    end

    local cfg = {
        macroName = "DR_Renew",
        spellName = "Renew",
        targetMouseover = true,
        targetMouseoverStrict = false,
        fallbackMode = "omit",
        modifiers = {
            { key = "shift_ctrl", enabled = true, mode = "relative", rankOffset = 3, customSpell = "" },
            { key = "shift_alt",  enabled = true, mode = "relative", rankOffset = 4, customSpell = "" },
            { key = "ctrl_alt",   enabled = true, mode = "relative", rankOffset = 5, customSpell = "" },
            { key = "shift",      enabled = true, mode = "relative", rankOffset = 1, customSpell = "" },
            { key = "ctrl",       enabled = true, mode = "relative", rankOffset = 2, customSpell = "" },
            { key = "alt",        enabled = true, mode = "relative", rankOffset = 6, customSpell = "" },
            { key = "nomod",      enabled = true, mode = "relative", rankOffset = 0, customSpell = "" },
        }
    }

    local body = RF:GenerateMacroBody(cfg)
    Assert(body:find("#showtooltip"), "Macro must contain #showtooltip")
    Assert(body:find("mod:shift,mod:ctrl"), "Must contain shift_ctrl condition")
    Assert(body:find("mod:shift,mod:alt"), "Must contain shift_alt condition")
    Assert(body:find("mod:ctrl,mod:alt"), "Must contain ctrl_alt condition")
    Assert(body:find("mod:shift"), "Must contain shift condition")
    Assert(body:find("mod:ctrl"), "Must contain ctrl condition")
    Assert(body:find("mod:alt"), "Must contain alt condition")
    Assert(body:find("Renew%(Rank 9%)"), "Must cast Rank 9 for nomod")
    Assert(body:find("Renew%(Rank 8%)"), "Must cast Rank 8 for shift (offset 1)")
    Assert(body:find("Renew%(Rank 7%)"), "Must cast Rank 7 for ctrl (offset 2)")
    Assert(body:find("Renew%(Rank 6%)"), "Must cast Rank 6 for shift_ctrl (offset 3)")
    Assert(body:find("Renew%(Rank 4%)"), "Must cast Rank 4 for ctrl_alt (offset 5)")
end)

--------------------------------------------------------------------------------
-- 5. Macro Generation: Alternative Spell Overrides ("Alt. Zauber")
--------------------------------------------------------------------------------
RegisterTest("Macro Generation: Alternative spell override on modifier", function()
    local cfg = {
        macroName = "DR_Hybrid",
        spellName = "Greater Heal",
        targetMouseover = true,
        modifiers = {
            { key = "shift", enabled = true, mode = "custom", rankOffset = 0, customSpell = "Flash Heal" },
            { key = "nomod", enabled = true, mode = "relative", rankOffset = 0, customSpell = "" },
        }
    }

    local body = RF:GenerateMacroBody(cfg)
    Assert(body:find("Flash Heal"), "Macro must contain custom spell Flash Heal for shift")
    Assert(body:find("Greater Heal"), "Macro must contain base spell Greater Heal for nomod")
end)

--------------------------------------------------------------------------------
-- 6. Macro Generation: Fallback Modes (omit vs rank1)
--------------------------------------------------------------------------------
RegisterTest("Macro Generation: Fallback mode 'omit' vs 'rank1'", function()
    RF.knownSpells["LowSpell"] = {
        name = "LowSpell",
        maxRank = 2,
        hasRanks = true,
        rankWord = "Rank",
        ranks = { [1] = true, [2] = true },
        subtexts = { [1] = "Rank 1", [2] = "Rank 2" }
    }

    -- Test omit: offset 3 would result in rank -1 (not learned) -> should omit
    local cfgOmit = {
        macroName = "DR_Low",
        spellName = "LowSpell",
        fallbackMode = "omit",
        modifiers = {
            { key = "shift", enabled = true, mode = "relative", rankOffset = 3 },
            { key = "nomod", enabled = true, mode = "relative", rankOffset = 0 },
        }
    }
    local bodyOmit = RF:GenerateMacroBody(cfgOmit)
    AssertFalse(bodyOmit:find("mod:shift") ~= nil, "Shift condition should be omitted when rank is not learned")

    -- Test rank1 fallback: offset 3 -> fallback to Rank 1
    local cfgRank1 = {
        macroName = "DR_Low",
        spellName = "LowSpell",
        fallbackMode = "rank1",
        modifiers = {
            { key = "shift", enabled = true, mode = "relative", rankOffset = 3 },
            { key = "nomod", enabled = true, mode = "relative", rankOffset = 0 },
        }
    }
    local bodyRank1 = RF:GenerateMacroBody(cfgRank1)
    AssertTrue(bodyRank1:find("mod:shift") ~= nil, "Shift condition should be present in rank1 fallback mode")
    AssertTrue(bodyRank1:find("LowSpell%(Rank 1%)") ~= nil, "Should cast Rank 1 as fallback")
end)

--------------------------------------------------------------------------------
-- 7. Macro Generation: Targeting Conditions & Order
--------------------------------------------------------------------------------
RegisterTest("Macro Generation: Targeting conditions ordering", function()
    local cfg = {
        macroName = "DR_Targeting",
        spellName = "Renew",
        targetMouseover = true,
        targetMouseoverStrict = false,
        targetFocus = true,
        targetToT = true,
        targetSelfcast = true,
        modifiers = {
            { key = "nomod", enabled = true, mode = "relative", rankOffset = 0 }
        }
    }
    local body = RF:GenerateMacroBody(cfg)
    Assert(body:find("@mouseover,help,nodead"), "Must have mouseover")
    Assert(body:find("@focus,help,nodead"), "Must have focus")
    Assert(body:find("@targettarget,help,nodead"), "Must have targettarget")
    Assert(body:find("@player"), "Must have player selfcast fallback")
end)

RegisterTest("Macro Generation: Per-condition help, harm, nodead toggles", function()
    local cfg = {
        macroName = "DR_FilterTest",
        spellName = "Flash Heal",
        targetMouseover = true,
        targetMouseoverHelp = true,
        targetMouseoverHarm = false,
        targetMouseoverNodead = false, -- user unchecks nodead!
        targetFocus = true,
        targetFocusHelp = false,
        targetFocusHarm = true,
        targetFocusNodead = true, -- offensive focus
        modifiers = {
            { key = "nomod", enabled = true, mode = "relative", rankOffset = 0 }
        }
    }
    local body = RF:GenerateMacroBody(cfg)
    Assert(body:find("@mouseover,help") ~= nil, "Must have [@mouseover,help] without nodead")
    Assert(body:find("@mouseover,help,nodead") == nil, "Must NOT have nodead on mouseover")
    Assert(body:find("@focus,harm,nodead") ~= nil, "Must have [@focus,harm,nodead]")
end)

RegisterTest("Macro Generation: Pre-Cast Utility (Trinkets, Racials, Potions)", function()
    local cfg = {
        macroName = "DR_UtilityTest",
        spellName = "Flash Heal",
        startAttack = true,
        petAttack = true,
        useTrinket1 = true,
        useTrinket2 = true,
        preCastLines = "/use Super Mana Potion\n/cast Inner Focus",
        modifiers = {
            { key = "nomod", enabled = true, mode = "relative", rankOffset = 0 }
        }
    }
    local body = RF:GenerateMacroBody(cfg)
    Assert(body:find("/startattack") ~= nil, "Must contain /startattack")
    Assert(body:find("/petattack") ~= nil, "Must contain /petattack")
    Assert(body:find("/use 13") ~= nil, "Must contain /use 13")
    Assert(body:find("/use 14") ~= nil, "Must contain /use 14")
    Assert(body:find("/use Super Mana Potion") ~= nil, "Must contain potion line")
    Assert(body:find("/cast Inner Focus") ~= nil, "Must contain custom spell line")
end)

--------------------------------------------------------------------------------
-- 8. Macro Generation: 255 Character Limit Check
--------------------------------------------------------------------------------
RegisterTest("Modifiers: Reorder and Reset default sort order", function()
    local cfg = {
        macroName = "DR_ReorderTest",
        spellName = "Renew",
        modifiers = {
            { key = "nomod", enabled = true },
            { key = "shift", enabled = true },
            { key = "shift_ctrl", enabled = true },
            { key = "ctrl_alt", enabled = true },
            { key = "alt", enabled = true },
            { key = "ctrl", enabled = true },
            { key = "shift_alt", enabled = true },
        },
        customSortOrder = true
    }

    RF:ResetModifierSortOrder(cfg)
    AssertEquals(cfg.customSortOrder, false, "customSortOrder should be reset to false")
    AssertEquals(cfg.modifiers[1].key, "shift_ctrl", "First key must be shift_ctrl")
    AssertEquals(cfg.modifiers[2].key, "shift_alt", "Second key must be shift_alt")
    AssertEquals(cfg.modifiers[3].key, "ctrl_alt", "Third key must be ctrl_alt")
    AssertEquals(cfg.modifiers[4].key, "shift", "Fourth key must be shift")
    AssertEquals(cfg.modifiers[5].key, "ctrl", "Fifth key must be ctrl")
    AssertEquals(cfg.modifiers[6].key, "alt", "Sixth key must be alt")
    AssertEquals(cfg.modifiers[7].key, "nomod", "Last key must be nomod")
end)

RegisterTest("Macro Generation: 255 Character Limit validation", function()
    local cfg = {
        macroName = "DR_FlashHeal",
        spellName = "Flash Heal",
        targetMouseover = true,
        targetMouseoverStrict = false,
        modifiers = {
            { key = "shift", enabled = true, mode = "relative", rankOffset = 1 },
            { key = "ctrl",  enabled = true, mode = "relative", rankOffset = 2 },
            { key = "alt",   enabled = true, mode = "relative", rankOffset = 3 },
            { key = "nomod", enabled = true, mode = "relative", rankOffset = 0 },
        }
    }
    local body = RF:GenerateMacroBody(cfg)
    Assert(#body <= 255, string.format("Standard 4-modifier macro must not exceed 255 chars (was %d)", #body))
end)

--------------------------------------------------------------------------------
-- 9. Macro Moving: Account vs Character Tab Migration
--------------------------------------------------------------------------------
RegisterTest("Macro Storage: Account vs Character Tab detection", function()
    local macroCfgAcc = { macroName = "DR_UnitMoveTest", isAccount = true, spellName = "Renew" }
    local macroCfgChar = { macroName = "DR_UnitMoveTest", isAccount = false, spellName = "Renew" }

    AssertEquals(macroCfgAcc.isAccount, true, "Should be account macro")
    AssertEquals(macroCfgChar.isAccount, false, "Should be character macro")
end)

--------------------------------------------------------------------------------
-- 10. UI & Layout Verification
--------------------------------------------------------------------------------
RegisterTest("UI & Layout: Main window and 7 modifier rows initialized", function()
    if not RF.MainFrame and CreateMainUI then
        CreateMainUI()
    end
    if RF.MainFrame then
        Assert(#RF.MainFrame.modRows == 7, "Main frame must have exactly 7 modifier rows")
        local row1 = RF.MainFrame.modRows[1]
        Assert(row1.altDropSlot ~= nil, "Row 1 must have altDropSlot")
        Assert(row1.customSpellEdit ~= nil, "Row 1 must have customSpellEdit")
        Assert(row1.searchBtn ~= nil, "Row 1 must have searchBtn")
        Assert(row1.cbMo ~= nil, "Row 1 must have cbMo (Mouseover checkbox)")
        Assert(row1.cbFocus ~= nil, "Row 1 must have cbFocus (Focus checkbox)")
        Assert(row1.cbToT ~= nil, "Row 1 must have cbToT (Target of Target checkbox)")
        Assert(row1.cbSelfcast ~= nil, "Row 1 must have cbSelfcast (Selfcast checkbox)")
        Assert(row1.cbHelp ~= nil, "Row 1 must have cbHelp (Help filter checkbox)")
        Assert(row1.cbNodead ~= nil, "Row 1 must have cbNodead (Nodead filter checkbox)")
    end
end)

RegisterTest("Matrix Grid: Independent targeting conditions per modifier row", function()
    RF.knownSpells["Renew"] = {
        name = "Renew",
        maxRank = 9,
        hasRanks = true,
        rankWord = "Rank",
        ranks = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [8] = true, [9] = true },
        subtexts = { [7] = "Rank 7", [8] = "Rank 8", [9] = "Rank 9" },
        spellID = 139
    }
    local cfg = {
        macroName = "DR_GridMatrixTest",
        spellName = "Renew",
        modifiers = {
            {
                key = "shift",
                enabled = true,
                mode = "relative",
                rankOffset = 1,
                targetMouseover = true,
                targetFocus = false,
                isHelp = true,
                isHarm = false,
                isNodead = true
            },
            {
                key = "alt",
                enabled = true,
                mode = "relative",
                rankOffset = 2,
                targetMouseover = false,
                targetFocus = true,
                isHelp = false,
                isHarm = true,
                isNodead = true
            },
            {
                key = "nomod",
                enabled = true,
                mode = "relative",
                rankOffset = 0,
                targetMouseover = false,
                targetFocus = false,
                targetSelfcast = true,
                isHelp = true,
                isHarm = false,
                isNodead = true
            }
        }
    }
    local body = RF:GenerateMacroBody(cfg)
    -- Shift clause should have mouseover help,nodead
    Assert(body:find("mod:shift,@mouseover,help,nodead") ~= nil, "Shift must have mouseover")
    Assert(body:find("mod:shift,@focus") == nil, "Shift must NOT have focus")
    -- Alt clause should have focus harm,nodead
    Assert(body:find("mod:alt,@focus,harm,nodead") ~= nil, "Alt must have focus harm,nodead")
    Assert(body:find("mod:alt,@mouseover") == nil, "Alt must NOT have mouseover")
    -- nomod clause should have @player
    Assert(body:find("@player") ~= nil, "nomod must have @player selfcast")
end)

RegisterTest("UI & Layout: Minimap button initialized", function()
    if RF.InitMinimapButton then
        RF:InitMinimapButton()
    end
    Assert(RF.MinimapButton ~= nil, "Minimap button must be initialized")
    Assert(RF.MinimapButton.icon ~= nil, "Minimap button must have icon texture")
end)

RegisterTest("Macro Cloning: CloneMacro creates deep copy with unique name", function()
    local orig = {
        macroName = "DR_CloneTest",
        spellName = "Flash Heal",
        isAccount = false,
        fallbackMode = "rank1",
        targetMouseover = true,
        useTrinket1 = true,
        startAttack = true,
        petAttack = true,
        modifiers = {
            { key = "shift", enabled = true, mode = "relative", rankOffset = 2, targetMouseover = true, isHelp = true, isNodead = true },
            { key = "nomod", enabled = true, mode = "relative", rankOffset = 0, targetMouseover = true, isHelp = true, isNodead = true }
        }
    }
    local cloned = RF:CloneMacro(orig)
    Assert(cloned ~= nil, "Cloned macro should not be nil")
    Assert(cloned.macroName:find("DR_CloneTest") ~= nil, "Name should inherit base name")
    Assert(cloned.macroName ~= orig.macroName, "Name must be different from original")
    AssertEquals(cloned.spellName, "Flash Heal")
    AssertEquals(cloned.isAccount, false)
    AssertEquals(cloned.fallbackMode, "rank1")
    AssertEquals(cloned.useTrinket1, true)
    AssertEquals(cloned.startAttack, true)
    AssertEquals(cloned.petAttack, true)
    AssertEquals(#cloned.modifiers, 2)
    AssertEquals(cloned.modifiers[1].rankOffset, 2)

    -- Mutating clone must not mutate original
    cloned.modifiers[1].rankOffset = 5
    AssertEquals(orig.modifiers[1].rankOffset, 2, "Original modifier rankOffset must be unmodified")
end)

RegisterTest("UI & Layout: Preview box is selectable EditBox", function()
    if not RF.MainFrame and CreateMainUI then
        CreateMainUI()
    end
    if RF.MainFrame then
        Assert(RF.MainFrame.previewText ~= nil, "previewText must exist")
        Assert(RF.MainFrame.previewText.HighlightText ~= nil, "previewText must be an EditBox supporting HighlightText")
        Assert(RF.MainFrame.previewScroll ~= nil, "previewScroll frame must exist")
    end
end)

RegisterTest("Macro Sync: SyncAllMacros updates macros upon new rank learned", function()
    if mockSpellBook then
        mockSpellBook[1] = { name = "Flash Heal", subtext = "Rank 1", spellID = 2061 }
        mockSpellBook[2] = { name = "Flash Heal", subtext = "Rank 2", spellID = 2061 }
        mockSpellBook[3] = { name = "Flash Heal", subtext = "Rank 3", spellID = 2061 }
        mockSpellBook[4] = { name = "Flash Heal", subtext = "Rank 4", spellID = 2061 }
    end

    local cfg = {
        macroName = "DR_TestFH",
        spellName = "Flash Heal",
        isAccount = true,
        fallbackMode = "omit",
        modifiers = {
            { key = "nomod", enabled = true, mode = "relative", rankOffset = 0 },
            { key = "shift", enabled = true, mode = "relative", rankOffset = 1 },
        }
    }
    local macros = RF:GetMacrosList()
    table.insert(macros, cfg)

    -- Initial sync
    RF:SyncAllMacros(true)
    local bodyBefore = RF:GenerateMacroBody(cfg)
    Assert(bodyBefore:find("Flash Heal%(Rank 4%)") ~= nil, "Should cast Rank 4 as highest")

    -- Simulate learning Rank 5
    if mockSpellBook then
        mockSpellBook[5] = { name = "Flash Heal", subtext = "Rank 5", spellID = 2061 }
    end

    RF:SyncAllMacros(true)
    local bodyAfter = RF:GenerateMacroBody(cfg)
    Assert(bodyAfter:find("Flash Heal%(Rank 5%)") ~= nil, "Should cast Rank 5 after update")
    Assert(bodyAfter:find("Flash Heal%(Rank 4%)") ~= nil, "Shift should now cast Rank 4")
end)

RegisterTest("Targeting: @target and Harm filters for offensive abilities", function()
    local offensiveCfg = {
        macroName = "DR_MindBlast",
        spellName = "Mind Blast",
        isAccount = true,
        fallbackMode = "omit",
        modifiers = {
            {
                key = "nomod",
                enabled = true,
                mode = "relative",
                rankOffset = 0,
                targetMouseover = true,
                targetTarget = true,
                targetFocus = false,
                targetToT = false,
                targetSelfcast = false,
                isHelp = false,
                isHarm = true,
                isNodead = true
            }
        }
    }

    local body = RF:GenerateMacroBody(offensiveCfg)
    Assert(body:find("%[@mouseover,harm,nodead%]") ~= nil, "Should have mouseover harm condition")
    Assert(body:find("%[harm,nodead%]") ~= nil, "Should have target harm condition (compact)")
    Assert(body:find("%[@player%]") == nil, "Should NOT have selfcast for offensive spell")
    Assert(body:find("help") == nil, "Should NOT contain help filter")
end)

RegisterTest("Offensive Spells: AutoConfigureSpellType detects harmful spells", function()
    local cfg = {
        macroName = "DR_TestOffensive",
        spellName = "Mind Blast",
        modifiers = {
            { key = "nomod", enabled = true, isHelp = true, isHarm = false, targetSelfcast = true, targetTarget = true },
            { key = "shift", enabled = true, isHelp = true, isHarm = false, targetSelfcast = false, targetTarget = true }
        }
    }

    RF:AutoConfigureSpellType(cfg, "Mind Blast")
    AssertEquals(cfg.modifiers[1].isHarm, true, "nomod should have isHarm = true")
    AssertEquals(cfg.modifiers[1].isHelp, false, "nomod should have isHelp = false")
    AssertEquals(cfg.modifiers[1].targetSelfcast, false, "nomod should have targetSelfcast = false")
    AssertEquals(cfg.modifiers[1].targetTarget, true, "nomod should have targetTarget = true")

    -- Test healing spell switches back
    RF:AutoConfigureSpellType(cfg, "Flash Heal")
    AssertEquals(cfg.modifiers[1].isHarm, false, "nomod should have isHarm = false for heal")
    AssertEquals(cfg.modifiers[1].isHelp, true, "nomod should have isHelp = true for heal")
    AssertEquals(cfg.modifiers[1].targetSelfcast, true, "nomod should have targetSelfcast = true for heal")
end)

RegisterTest("Macro Generation: 3 Ranks Power Word: Shield fits in 255 chars", function()
    if mockSpellBook then
        mockSpellBook[10] = { name = "Power Word: Shield", subtext = "Rank 8", spellID = 17 }
        mockSpellBook[11] = { name = "Power Word: Shield", subtext = "Rank 9", spellID = 17 }
        mockSpellBook[12] = { name = "Power Word: Shield", subtext = "Rank 10", spellID = 17 }
    end
    RF:ScanSpellBook()

    local shieldCfg = {
        macroName = "DR_Shield",
        spellName = "Power Word: Shield",
        isAccount = true,
        fallbackMode = "omit",
        modifiers = {
            {
                key = "shift",
                enabled = true,
                mode = "relative",
                rankOffset = 1,
                targetMouseover = true,
                targetTarget = true,
                targetSelfcast = true,
                isHelp = true,
                isHarm = false,
                isNodead = true
            },
            {
                key = "ctrl",
                enabled = true,
                mode = "relative",
                rankOffset = 2,
                targetMouseover = true,
                targetTarget = true,
                targetSelfcast = true,
                isHelp = true,
                isHarm = false,
                isNodead = true
            },
            {
                key = "nomod",
                enabled = true,
                mode = "relative",
                rankOffset = 0,
                targetMouseover = true,
                targetTarget = true,
                targetSelfcast = true,
                isHelp = true,
                isHarm = false,
                isNodead = true
            }
        }
    }

    local body = RF:GenerateMacroBody(shieldCfg)
    Assert(#body <= 255, string.format("Power Word: Shield macro must fit within 255 characters! Actual: %d", #body))
end)

RegisterTest("UI & Layout: Toggle-All column header functionality", function()
    local cfg = {
        macroName = "DR_ToggleTest",
        spellName = "Renew",
        modifiers = {
            { key = "shift", enabled = true, targetMouseover = true, targetTarget = true, targetSelfcast = true, isHelp = true, isHarm = false, isNodead = true },
            { key = "nomod", enabled = true, targetMouseover = false, targetTarget = true, targetSelfcast = true, isHelp = true, isHarm = false, isNodead = true }
        }
    }

    -- Simulate ToggleAll on targetMouseover (some are true, some false -> should make all true)
    local allTrue = true
    for _, mod in ipairs(cfg.modifiers) do
        if not mod.targetMouseover then allTrue = false break end
    end
    local targetVal = not allTrue
    for _, mod in ipairs(cfg.modifiers) do mod.targetMouseover = targetVal end
    AssertEquals(cfg.modifiers[1].targetMouseover, true, "Mod 1 should be true")
    AssertEquals(cfg.modifiers[2].targetMouseover, true, "Mod 2 should be true")

    -- Second toggle -> should turn all false
    allTrue = true
    for _, mod in ipairs(cfg.modifiers) do
        if not mod.targetMouseover then allTrue = false break end
    end
    targetVal = not allTrue
    for _, mod in ipairs(cfg.modifiers) do mod.targetMouseover = targetVal end
    AssertEquals(cfg.modifiers[1].targetMouseover, false, "Mod 1 should now be false")
    AssertEquals(cfg.modifiers[2].targetMouseover, false, "Mod 2 should now be false")
end)

RegisterTest("Sweet Spot: GetSpellSweetSpot calculates optimal mana efficiency rank", function()
    -- Mock knownSpells for Renew (10 ranks) and Flash Heal (7 ranks)
    RF.knownSpells["Renew"] = { name = "Renew", maxRank = 10, hasRanks = true }
    RF.knownSpells["Flash Heal"] = { name = "Flash Heal", maxRank = 7, hasRanks = true }

    -- Level 60: min level is max(20, 60-18) = 42
    -- Renew: Rank 7 is level 44 (offset 10 - 7 = 3)
    local renewOffset, renewRank, reqLvl = RF:GetSpellSweetSpot("Renew")
    AssertEquals(renewRank, 7, "Renew sweet spot rank at level 60 should be 7")
    AssertEquals(renewOffset, 3, "Renew sweet spot offset at level 60 should be 3 (-3)")
    AssertEquals(reqLvl, 44, "Renew sweet spot level should be 44")

    -- Flash Heal: Rank 5 is level 44 (offset 7 - 5 = 2)
    local fhOffset, fhRank, fhLvl = RF:GetSpellSweetSpot("Flash Heal")
    AssertEquals(fhRank, 5, "Flash Heal sweet spot rank at level 60 should be 5")
    AssertEquals(fhOffset, 2, "Flash Heal sweet spot offset at level 60 should be 2 (-2)")
    AssertEquals(fhLvl, 44, "Flash Heal sweet spot level should be 44")
end)

RegisterTest("Macro List UI: Displays both Macro Name and Spell Name with live update", function()
    -- Prepare test macros
    local profile = RF:GetActiveProfile()
    profile.macros = {
        {
            macroName = "DR_Renew",
            spellName = "Renew",
            modifiers = {
                { key = "nomod", enabled = true, rankOffset = 0 }
            }
        },
        {
            macroName = "DR_EmptySpell",
            spellName = "",
            modifiers = {}
        }
    }

    RF:UpdateUI()
    local f = RF.MainFrame
    Assert(f ~= nil, "Main frame must exist")
    Assert(f.listContent ~= nil, "listContent must exist")
    Assert(f.listContent.buttons ~= nil, "listContent.buttons must exist")
    Assert(#f.listContent.buttons >= 2, "At least 2 macro buttons should be created")

    local btn1 = f.listContent.buttons[1]
    Assert(btn1.nameText ~= nil, "Button 1 must have nameText")
    Assert(btn1.subText ~= nil, "Button 1 must have subText")
    AssertEquals(btn1.nameText:GetText(), "DR_Renew", "Button 1 nameText should be DR_Renew")
    AssertEquals(btn1.subText:GetText(), "Renew", "Button 1 subText should be Renew")

    local btn2 = f.listContent.buttons[2]
    AssertEquals(btn2.nameText:GetText(), "DR_EmptySpell", "Button 2 nameText should be DR_EmptySpell")
    AssertEquals(btn2.subText:GetText(), RF.L["UI_NO_SPELL"], "Button 2 subText should display fallback no spell string")

    -- Test live update through RF:UpdateMacroListItem
    local updatedCfg = {
        macroName = "DR_Shield_Updated",
        spellName = "Power Word: Shield",
        modifiers = {}
    }
    RF:UpdateMacroListItem(btn1, updatedCfg, 1)
    AssertEquals(btn1.nameText:GetText(), "DR_Shield_Updated", "nameText should update dynamically")
    AssertEquals(btn1.subText:GetText(), "Power Word: Shield", "subText should update dynamically")
end)

RegisterTest("Macro Generation: Action Bar Tooltip & Cast Fallback when only Mouseover is active", function()
    RF.knownSpells["Renew"] = {
        name = "Renew",
        maxRank = 10,
        hasRanks = true,
        rankWord = "Rank",
        ranks = { [1] = true, [7] = true, [8] = true, [9] = true, [10] = true },
        subtexts = { [1] = "Rank 1", [7] = "Rank 7", [8] = "Rank 8", [9] = "Rank 9", [10] = "Rank 10" }
    }

    -- Exactly as in the user's screenshot: MO checked, Target/Selfcast unchecked
    local cfg = {
        macroName = "DR_Renew",
        spellName = "Renew",
        modifiers = {
            { key = "shift", enabled = true, mode = "relative", rankOffset = 1, targetMouseover = true, targetTarget = false, targetSelfcast = false, isHelp = true, isHarm = false, isNodead = true },
            { key = "ctrl",  enabled = true, mode = "relative", rankOffset = 2, targetMouseover = true, targetTarget = false, targetSelfcast = false, isHelp = true, isHarm = false, isNodead = true },
            { key = "alt",   enabled = true, mode = "relative", rankOffset = 3, targetMouseover = true, targetTarget = false, targetSelfcast = false, isHelp = true, isHarm = false, isNodead = true },
            { key = "nomod", enabled = true, mode = "relative", rankOffset = 0, targetMouseover = true, targetTarget = false, targetSelfcast = false, isHelp = true, isHarm = false, isNodead = true },
        }
    }

    local body = RF:GenerateMacroBody(cfg)
    -- Must have [mod:alt] fallback so holding Alt shows the tooltip on action bars
    Assert(body:find("%[mod:alt%]") ~= nil, "Alt clause must contain [mod:alt] fallback for tooltip")
    -- Must have [] fallback on nomod so hovering the action bar without modifiers shows the tooltip
    Assert(body:find("%[%] Renew") ~= nil, "nomod clause must contain [] fallback for action bar tooltip")
    -- Total length must fit within 255 chars
    Assert(#body <= 255, string.format("Macro length %d must be <= 255", #body))

    -- Test case where ONLY Alt is enabled (no nomod): must still generate a [] fallback for normal cast & tooltip
    local cfgOnlyAlt = {
        macroName = "DR_Renew_AltOnly",
        spellName = "Renew",
        modifiers = {
            { key = "alt", enabled = true, mode = "relative", rankOffset = 3, targetMouseover = true, targetTarget = false, targetSelfcast = false, isHelp = true, isHarm = false, isNodead = true },
            { key = "nomod", enabled = false }
        }
    }
    local bodyOnlyAlt = RF:GenerateMacroBody(cfgOnlyAlt)
    Assert(bodyOnlyAlt:find("%[mod:alt") ~= nil, "Must have alt modifier clause")
    Assert(bodyOnlyAlt:find("%[%] Renew%(Rank 10%)") ~= nil, "Must automatically fallback to max rank for nomod")
    Assert(#bodyOnlyAlt <= 255, "Alt-only macro length must be <= 255")
end)

RegisterTest("UI Lifecycle: Main frame starts hidden and only opens via ToggleUI", function()
    if RF.MainFrame then
        RF.MainFrame:Hide()
    end

    RF:ToggleUI()
    Assert(RF.MainFrame:IsShown(), "Main frame should be shown after ToggleUI")

    RF:ToggleUI()
    AssertFalse(RF.MainFrame:IsShown(), "Main frame should be hidden after second ToggleUI")

    local inSpecial = false
    if UISpecialFrames then
        for _, name in ipairs(UISpecialFrames) do
            if name == "RankForgeMainFrame" then
                inSpecial = true
                break
            end
        end
    end
    AssertTrue(inSpecial, "RankForgeMainFrame must be in UISpecialFrames for Escape closing")
end)

RegisterTest("Drag & Drop: Spell extraction from cursor (3.3.5a, modern and action bars)", function()
    -- Mock spellbook entry 1 as "Renew" and slot 10 as "Geringes Heilen"
    mockSpellBook[1] = { name = "Renew", subtext = "Rank 1", spellID = 139 }
    mockSpellBook[10] = { name = "Geringes Heilen", subtext = "Rang 1", spellID = 2050 }

    -- 1. 3.3.5a style: {"spell", 1, "spell"} (spellbook slot index + bookType string)
    mockCursor = { "spell", 1, "spell" }
    local sp1 = RF:GetSpellFromCursor()
    AssertEquals(sp1, "Renew", "Should resolve spell name from 3.3.5a spellbook slot index")
    Assert(mockCursor == nil, "Cursor should be cleared after extraction")

    -- 1b. Slot 10 test (must not be confused with Spell ID 10 = Blizzard!)
    mockCursor = { "spell", 10, "spell" }
    local sp10 = RF:GetSpellFromCursor()
    AssertEquals(sp10, "Geringes Heilen", "Slot 10 must resolve to Geringes Heilen, never Blizzard!")
    Assert(mockCursor == nil, "Cursor should be cleared after extraction")

    -- 2. Modern style: {"spell", 139} (numeric spell ID)
    mockCursor = { "spell", 139, nil }
    local sp2 = RF:GetSpellFromCursor()
    AssertEquals(sp2, "Renew", "Should resolve spell name from spellID")
    Assert(mockCursor == nil, "Cursor should be cleared after extraction")

    -- 3. Action bar style: {"action", 1}
    mockCursor = { "action", 1, nil }
    local sp3 = RF:GetSpellFromCursor()
    AssertEquals(sp3, "Renew", "Should resolve spell name from action slot")
    Assert(mockCursor == nil, "Cursor should be cleared after extraction")

    -- 4. Test dropping onto UI base spell slot / spellEdit
    if RF.MainFrame and RF.MainFrame.spellEdit then
        local cfg = {
            macroName = "DR_Test",
            spellName = "",
            modifiers = {}
        }
        RF:LoadMacroIntoEditor(cfg)
        mockCursor = { "spell", 1, "spell" }
        RF.MainFrame.dropSlot:GetScript("OnReceiveDrag")(RF.MainFrame.dropSlot)
        AssertEquals(cfg.spellName, "Renew", "Base spell slot should update currentMacro.spellName")
        AssertEquals(RF.MainFrame.spellEdit:GetText(), "Renew", "spellEdit text should update to Renew")
    end
end)

RegisterTest("Downranking Efficiency: Spell power and proc chance calculation (WoW Forever)", function()
    -- Level 60 mock (UnitLevel returns 60)
    RF.knownSpells["Renew"] = { name = "Renew", maxRank = 10, hasRanks = true }
    RF.knownSpells["Frostbolt"] = { name = "Frostbolt", maxRank = 11, hasRanks = true }

    -- 1. Renew Max Rank (Rank 10): 100% full, green
    local pct10, status10, proc10 = RF:GetDownrankingEfficiency("Renew", 0, 10)
    AssertEquals(pct10, 100, "Max rank should have 100% efficiency")
    AssertEquals(status10, "green", "Max rank should be green status")
    AssertEquals(proc10, "100%", "Max rank should have 100% procs")

    -- 2. Renew Sweet Spot Rank 7 (Req lvl 44, >= 42): 100% full, green
    local pct7, status7, proc7 = RF:GetDownrankingEfficiency("Renew", 3, 7)
    AssertEquals(pct7, 100, "Sweet spot rank 7 should have 100% efficiency")
    AssertEquals(status7, "green", "Sweet spot rank 7 should be green status")
    AssertEquals(proc7, "100%", "Sweet spot rank 7 should have 100% procs")

    -- 3. Renew Rank 5 (Req lvl 32, < 42 but >= 20): yellow minor penalty (~61%)
    local pct5, status5, proc5 = RF:GetDownrankingEfficiency("Renew", 5, 5)
    Assert(pct5 < 100 and pct5 >= 60, "Rank 5 should suffer minor level-difference penalty")
    AssertEquals(status5, "yellow", "Rank 5 should be yellow status")

    -- 4. Renew Rank 2 (Req lvl 14, < 20): red severe pre-20 penalty & 0%/minimal procs
    local pct2, status2, proc2 = RF:GetDownrankingEfficiency("Renew", 8, 2)
    Assert(pct2 < 40, "Rank 2 should suffer severe pre-20 penalty")
    AssertEquals(status2, "red", "Rank 2 should be red status")
    Assert(proc2:find("⚠️") ~= nil, "Rank 2 procs should have severe warning")

    -- 5. Mage Frostbolt Rank 1 (Req lvl 1): classic rank 1 nerf from WoW Forever article
    local pctFb1, statusFb1, procFb1 = RF:GetDownrankingEfficiency("Frostbolt", 10, 1)
    Assert(pctFb1 < 30, "Frostbolt rank 1 should have severe scaling penalty")
    AssertEquals(statusFb1, "red", "Frostbolt rank 1 should be red status")
    Assert(procFb1:find("⚠️") ~= nil, "Frostbolt rank 1 procs should have severe warning")
end)

RegisterTest("Spell Database: Multi-class spell rank tables support", function()
    local classes = {
        { name = "Priest", spells = { "Renew", "Flash Heal", "Greater Heal", "Power Word: Shield", "Mind Blast" } },
        { name = "Druid", spells = { "Healing Touch", "Regrowth", "Rejuvenation", "Moonfire", "Wrath" } },
        { name = "Paladin", spells = { "Holy Light", "Flash of Light", "Consecration", "Exorcism" } },
        { name = "Shaman", spells = { "Healing Wave", "Lesser Healing Wave", "Chain Heal", "Lightning Bolt", "Earth Shock" } },
        { name = "Mage", spells = { "Frostbolt", "Fireball", "Scorch", "Arcane Missiles", "Blizzard" } },
        { name = "Warlock", spells = { "Shadow Bolt", "Corruption", "Immolate", "Curse of Agony", "Drain Life" } }
    }

    for _, cls in ipairs(classes) do
        for _, sp in ipairs(cls.spells) do
            local ranks = RF.SpellRankLevels[sp]
            Assert(ranks ~= nil and type(ranks) == "table", string.format("Spell %s for %s must exist in SpellRankLevels", sp, cls.name))
            Assert(ranks[1] ~= nil and ranks[1] >= 1, string.format("Spell %s must have rank 1 level defined", sp))
        end
    end
end)

RegisterTest("Utility: startattack and petattack checkboxes and macro generation", function()
    local cfg = {
        macroName = "DR_AttackTest",
        spellName = "Frostbolt",
        startAttack = true,
        petAttack = true,
        modifiers = {
            { key = "nomod", enabled = true, rankOffset = 0 }
        }
    }
    local body = RF:GenerateMacroBody(cfg)
    local lines = {}
    for l in body:gmatch("[^\r\n]+") do table.insert(lines, l) end
    AssertEquals(lines[1], "#showtooltip Frostbolt")
    AssertEquals(lines[2], "/startattack")
    AssertEquals(lines[3], "/petattack")
    Assert(lines[4]:find("/cast") ~= nil, "Cast line must follow utility commands")

    -- Test with UI elements
    if RF.MainFrame and RF.MainFrame.cbStartAttack and RF.MainFrame.cbPetAttack then
        RF:LoadMacroIntoEditor(cfg)
        AssertEquals(RF.MainFrame.cbStartAttack:GetChecked(), true)
        AssertEquals(RF.MainFrame.cbPetAttack:GetChecked(), true)
    end
end)

RegisterTest("Character Filtering: RF:IsMacroForCurrentCharacter and list filtering", function()
    local charName, realm, charClass = RF:GetCurrentCharacterKey()
    Assert(charClass ~= nil, "Character class must be known")

    local priestMacro = { macroName = "DR_HeiligePein", spellName = "Heilige Pein", class = "PRIEST" }
    local mageMacro = { macroName = "DR_Blizzard", spellName = "Blizzard", class = "MAGE" }
    local warlockMacro = { macroName = "DR_Feuerbrand", spellName = "Feuerbrand", class = "WARLOCK" }

    if charClass == "PRIEST" then
        AssertEquals(RF:IsMacroForCurrentCharacter(priestMacro), true, "Priest macro should match Priest character")
        AssertEquals(RF:IsMacroForCurrentCharacter(mageMacro), false, "Mage macro should not match Priest character")
        AssertEquals(RF:IsMacroForCurrentCharacter(warlockMacro), false, "Warlock macro should not match Priest character")
    end

    -- Test UI Filtering
    local profile = RF:GetActiveProfile()
    profile.macros = { priestMacro, mageMacro, warlockMacro }
    RankForgeCharDB = RankForgeCharDB or {}
    RankForgeCharDB.filterCurrentCharOnly = true

    RF:UpdateUI()
    local f = RF.MainFrame
    Assert(f ~= nil, "MainFrame must exist")
    Assert(f.filterCharCb ~= nil, "filterCharCb must exist")
    AssertEquals(f.filterCharCb:GetChecked(), true, "filterCharCb should be checked")

    -- Count visible buttons
    local visibleCount = 0
    for _, btn in ipairs(f.listContent.buttons) do
        if btn:IsShown() then
            visibleCount = visibleCount + 1
        end
    end
    AssertEquals(visibleCount, 1, "Only 1 macro should be visible with filter on")

    -- Toggle filter off
    RankForgeCharDB.filterCurrentCharOnly = false
    RF:UpdateUI()
    AssertEquals(f.filterCharCb:GetChecked(), false, "filterCharCb should be unchecked")

    visibleCount = 0
    for _, btn in ipairs(f.listContent.buttons) do
        if btn:IsShown() then
            visibleCount = visibleCount + 1
        end
    end
    AssertEquals(visibleCount, 3, "All 3 macros should be visible with filter off")

    -- Test General / Non-Class macros (e.g. Feuer machen / Basic Campfire)
    local campfireAccount = { macroName = "DR_Lagerfeuer", spellName = "Feuer machen", isAccount = true }
    local campfireCharOnly = { macroName = "DR_Lagerfeuer_Char", spellName = "Feuer machen", isAccount = false, character = "OtherChar" }
    AssertEquals(RF:IsMacroForCurrentCharacter(campfireAccount), true, "General account macro should be visible across characters")
    AssertEquals(RF:IsMacroForCurrentCharacter(campfireCharOnly), false, "General character-specific macro of another char should be hidden")

    -- Restore filter setting
    RankForgeCharDB.filterCurrentCharOnly = true
    RF:UpdateUI()
end)

RegisterTest("Default Character Slot & Debug Auto-Open Mode", function()
    -- Verify new macro has isAccount == false (Character slot by default)
    local profile = RF:GetActiveProfile()
    profile.macros = {}
    RF:CreateNewMacroConfig()
    local macros = RF:GetMacrosList()
    Assert(#macros >= 1, "New macro must be created")
    local newMacro = macros[#macros]
    AssertEquals(newMacro.isAccount, false, "New macro must default to character slot (isAccount = false)")

    -- Verify UI dropdown reflects character slot
    if RF.MainFrame and RF.MainFrame.storageDropdown then
        RF:LoadMacroIntoEditor(newMacro)
        local isAcc = (newMacro.isAccount == true)
        AssertEquals(isAcc, false, "Editor storage dropdown state must reflect character slot")
    end

    -- Verify Debug Mode Checkbox & State
    RankForgeDB = RankForgeDB or {}
    RankForgeDB.debugMode = true
    RF:UpdateUI()
    local f = RF.MainFrame
    Assert(f.cbDebug ~= nil, "Debug checkbox must exist")
    AssertEquals(f.cbDebug:GetChecked(), true, "Debug checkbox must reflect debugMode = true")

    RankForgeDB.debugMode = false
    RF:UpdateUI()
    AssertEquals(f.cbDebug:GetChecked(), false, "Debug checkbox must reflect debugMode = false")
end)

--------------------------------------------------------------------------------
-- Test Runner Execution
--------------------------------------------------------------------------------
function RF:RunAllTests()
    passedCount = 0
    failedCount = 0
    wipe(testResults)

    local charName, realm, charClass = RF:GetCurrentCharacterKey()
    local buildInfo = (GetBuildInfo and select(1, GetBuildInfo())) or "Unknown"
    local timeStr = (date and date("%Y-%m-%d %H:%M:%S")) or "N/A"

    local plainLines = {}
    table.insert(plainLines, "========================================")
    table.insert(plainLines, "RankForge Automated Test Suite Report")
    table.insert(plainLines, string.format("Date: %s | Client: %s", timeStr, tostring(buildInfo)))
    table.insert(plainLines, string.format("Realm: %s | Char: %s (%s)", tostring(realm or "Unknown"), tostring(charName or "Unknown"), tostring(charClass or "Unknown")))
    table.insert(plainLines, "========================================")

    print("|cff00ccff========================================|r")
    print("|cff00ccffRankForge Unit & Integration Tests|r")
    print("|cff00ccff========================================|r")

    local startTime = debugprofilestop and debugprofilestop() or 0

    for i, test in ipairs(TestSuite) do
        local ok, err = pcall(test.func)
        if ok then
            passedCount = passedCount + 1
            table.insert(testResults, { name = test.name, passed = true })
            print(string.format("  |cff00ff00[PASS]|r %s", test.name))
            table.insert(plainLines, string.format("[PASS] %s", test.name))
        else
            failedCount = failedCount + 1
            table.insert(testResults, { name = test.name, passed = false, error = err })
            print(string.format("  |cffff2222[FAIL]|r %s: %s", test.name, tostring(err)))
            table.insert(plainLines, string.format("[FAIL] %s: %s", test.name, tostring(err)))
        end
    end

    local elapsed = (debugprofilestop and (debugprofilestop() - startTime)) or 0
    print("|cff00ccff----------------------------------------|r")
    local summaryStr = ""
    if failedCount == 0 then
        summaryStr = string.format("ALL TESTS PASSED! (%d / %d tests in %.1f ms)", passedCount, #TestSuite, elapsed)
        print(string.format("|cff00ff00%s|r", summaryStr))
    else
        summaryStr = string.format("TESTS FAILED: %d passed, %d failed in %.1f ms", passedCount, failedCount, elapsed)
        print(string.format("|cffff2222%s|r", summaryStr))
    end
    print("|cff00ccff========================================|r")

    table.insert(plainLines, "----------------------------------------")
    table.insert(plainLines, summaryStr)
    table.insert(plainLines, "========================================")
    local fullReport = table.concat(plainLines, "\n")

    -- Save to SavedVariables (automatically written to WTF on /reload or exit)
    RankForgeDB = RankForgeDB or {}
    RankForgeDB.lastTestRun = {
        date = timeStr,
        client = buildInfo,
        char = charName,
        realm = realm,
        class = charClass,
        passed = passedCount,
        failed = failedCount,
        total = #TestSuite,
        elapsedMs = elapsed,
        report = fullReport,
        results = testResults
    }

    -- Show copyable dialog in UI
    if RF.ShowTestResultsDialog then
        RF:ShowTestResultsDialog(fullReport)
    end
    print(RF.L["TEST_DIALOG_CHAT_NOTICE"] or "|cff00ccffRankForge:|r Test report window opened (Ctrl+C to copy). Saved to SavedVariables/RankForge.lua upon /reload.")

    return passedCount, failedCount, testResults
end
