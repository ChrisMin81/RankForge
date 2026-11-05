# -*- coding: utf-8 -*-
"""
RankForge - Automated JUnit-style Test Runner
Runs the actual Lua test suite headlessly via Lupa (LuaJIT/Lua 5.1) and generates a JUnit XML report.
"""

import os
import sys
import time
import xml.etree.ElementTree as ET
from lupa import LuaRuntime

def build_wow_environment(lua):
    mock_env = """
    -- WoW Environment Mock for Unit Testing
    _G = _G or {}
    _G["RankForgeDB"] = {}
    _G["RankForgeCharDB"] = {}
    _G["StaticPopupDialogs"] = {}
    _G["SlashCmdList"] = {}
    _G["UISpecialFrames"] = {}
    UISpecialFrames = _G["UISpecialFrames"]

    function GetLocale() return "enUS" end
    function GetTime() return os.clock() end
    function debugprofilestop() return os.clock() * 1000 end

    function wipe(t)
        if type(t) == "table" then
            for k in pairs(t) do
                t[k] = nil
            end
        end
        return t
    end

    function string.trim(s)
        return s:match("^%s*(.-)%s*$")
    end

    function InCombatLockdown() return false end

    -- Macro API mocks
    local mockMacros = {}
    function GetNumMacros()
        local acc, char = 0, 0
        for i = 1, 120 do if mockMacros[i] then acc = acc + 1 end end
        for i = 121, 138 do if mockMacros[i] then char = char + 1 end end
        return acc, char
    end

    function GetMacroInfo(idx)
        if mockMacros[idx] then
            return mockMacros[idx].name, mockMacros[idx].icon, mockMacros[idx].body
        end
        return nil, nil, nil
    end

    function CreateMacro(name, icon, body, isChar)
        local startIdx = isChar and 121 or 1
        local endIdx = isChar and 138 or 120
        for i = startIdx, endIdx do
            if not mockMacros[i] then
                mockMacros[i] = { name = name, icon = icon, body = body }
                return i
            end
        end
        return nil
    end

    function EditMacro(idx, name, icon, body)
        if mockMacros[idx] then
            mockMacros[idx].name = name
            mockMacros[idx].icon = icon
            mockMacros[idx].body = body
            return idx
        end
        return nil
    end

    function DeleteMacro(idx)
        mockMacros[idx] = nil
    end

    function PickupMacro(idx) end

    -- Spell API mocks
    mockSpellBook = {}
    function GetNumSpellTabs() return 1 end
    function GetSpellTabInfo(tab) return "General", "", 0, #mockSpellBook end
    function GetSpellName(idx, bank)
        if mockSpellBook[idx] then
            return mockSpellBook[idx].name, mockSpellBook[idx].subtext
        end
        return nil, nil
    end
    function GetSpellBookItemName(idx, bank)
        if mockSpellBook[idx] then
            return mockSpellBook[idx].name, mockSpellBook[idx].subtext
        end
        return nil, nil
    end
    function GetSpellBookItemInfo(idx, bank)
        if mockSpellBook[idx] then
            return "SPELL", mockSpellBook[idx].spellID
        end
        return nil, nil
    end
    function GetSpellSubtext(idx, bank)
        if type(idx) == "number" and mockSpellBook[idx] then
            return mockSpellBook[idx].subtext
        end
        return nil
    end

    mockCursor = nil
    function GetCursorInfo()
        if mockCursor then
            return mockCursor[1], mockCursor[2], mockCursor[3]
        end
        return nil
    end
    function ClearCursor()
        mockCursor = nil
    end
    function GetActionInfo(slot)
        return "spell", 139
    end

    function GetSpellInfo(id, bookType)
        if id == 139 then return "Renew", "", "Interface\\\\Icons\\\\Spell_Holy_Renew" end
        if id == 2050 then return "Geringes Heilen", "", "Interface\\\\Icons\\\\Spell_Holy_LesserHeal" end
        if id == 2061 then return "Flash Heal", "", "Interface\\\\Icons\\\\Spell_Holy_FlashHeal" end
        if id == 2060 then return "Greater Heal", "", "Interface\\\\Icons\\\\Spell_Holy_GreaterHeal" end
        if id == 17 then return "Power Word: Shield", "", "Interface\\\\Icons\\\\Spell_Holy_PowerWordShield" end
        if id == 12 then return "Hot Foot (TEST)", "", "Interface\\\\Icons\\\\INV_Misc_QuestionMark" end
        if id == 10 then return "Blizzard", "", "Interface\\\\Icons\\\\Spell_Frost_IceStorm" end
        if id == 589 then return "Schattenwort: Schmerz", "", "Interface\\\\Icons\\\\Spell_Shadow_ShadowWordPain" end
        return "Spell_" .. tostring(id), "", "Interface\\\\Icons\\\\INV_Misc_QuestionMark"
    end

    function GetSpellTexture(idx, bookType)
        if type(idx) == "number" and not bookType then
            error("bad argument #2 to 'GetSpellTexture' (string expected, got no value)")
        end
        return "Interface\\\\Icons\\\\Spell_Holy_Renew"
    end

    function UnitClass(unit)
        return "Priest", "PRIEST"
    end

    function UnitLevel(unit)
        return 60
    end

    function IsHarmfulSpell(name)
        if name == "Mind Blast" or name == "Shadow Word: Pain" or name == "Smite" or name == "Frostbolt" then
            return true
        end
        return false
    end

    function IsHelpfulSpell(name)
        if name == "Flash Heal" or name == "Greater Heal" or name == "Renew" or name == "Power Word: Shield" then
            return true
        end
        return false
    end

    -- Frame UI Mocks
    local function CreateDummyObject(name, objType)
        local obj = { name = name, type = objType, visible = false }
        function obj:SetSize(w, h) self.width, self.height = w, h end
        function obj:SetWidth(w) self.width = w end
        function obj:SetHeight(h) self.height = h end
        function obj:GetWidth() return self.width or 100 end
        function obj:GetHeight() return self.height or 20 end
        function obj:GetStringWidth() return 50 end
        function obj:SetPoint(...) end
        function obj:ClearAllPoints() end
        function obj:SetText(t) self.text = t end
        function obj:GetText() return self.text or "" end
        function obj:SetScript(evt, fn) self[evt] = fn end
        function obj:GetScript(evt) return self[evt] end
        function obj:SetBackdrop(...) end
        function obj:SetBackdropColor(...) end
        function obj:SetFrameStrata(s) self.strata = s end
        function obj:SetFrameLevel(l) self.level = l end
        function obj:SetToplevel(t) end
        function obj:SetMovable(m) end
        function obj:EnableMouse(e) end
        function obj:RegisterForDrag(...) end
        function obj:RegisterForClicks(...) end
        function obj:SetHighlightTexture(...) end
        function obj:SetClampedToScreen(...) end
        function obj:SetFontObject(...) end
        function obj:SetMultiLine(...) end
        function obj:SetAutoFocus(...) end
        function obj:SetNumeric(...) end
        function obj:SetMaxLetters(...) end
        function obj:ClearFocus() end
        function obj:SetFocus() end
        function obj:HighlightText() end
        function obj:SetChecked(c) self.checked = c end
        function obj:GetChecked() return self.checked end
        function obj:Show() self.visible = true end
        function obj:Hide() self.visible = false end
        function obj:IsShown() return self.visible end
        function obj:LockHighlight() end
        function obj:UnlockHighlight() end
        function obj:SetAlpha(a) end
        function obj:SetTextColor(...) end
        function obj:SetTexture(t) self.texture = t end
        function obj:SetColorTexture(...) end
        function obj:SetTexCoord(...) end
        function obj:SetJustifyH(...) end
        function obj:SetJustifyV(...) end
        function obj:SetAllPoints(...) end
        function obj:CreateTexture(...)
            return CreateDummyObject("Texture", "Texture")
        end
        function obj:CreateFontString(...)
            return CreateDummyObject("FontString", "FontString")
        end
        function obj:GetFontString()
            self.fontString = self.fontString or CreateDummyObject("FontString", "FontString")
            return self.fontString
        end
        function obj:SetScrollChild(...) end
        function obj:RegisterEvent(...) end
        return obj
    end

    UIParent = CreateDummyObject("UIParent", "Frame")
    Minimap = CreateDummyObject("Minimap", "Frame")
    function Minimap:GetCenter() return 100, 100 end
    function Minimap:GetEffectiveScale() return 1 end

    function CreateFrame(frameType, name, parent, template)
        return CreateDummyObject(name or "AnonymousFrame", frameType)
    end

    function UIDropDownMenu_SetWidth(...) end
    function UIDropDownMenu_SetText(...) end
    function UIDropDownMenu_SetSelectedValue(...) end
    function UIDropDownMenu_Initialize(...) end
    function UIDropDownMenu_CreateInfo() return {} end
    function UIDropDownMenu_AddButton(...) end
    function CloseDropDownMenus() end
    """
    lua.execute(mock_env)

def run_tests():
    print("=" * 60)
    print(" RankForge - Running Automated JUnit Test Suite")
    print("=" * 60)

    lua = LuaRuntime(unpack_returned_tuples=True)
    build_wow_environment(lua)

    addon_path = os.path.dirname(os.path.abspath(__file__))
    lua_files = [
        "Localization.lua",
        "Base64.lua",
        "Presets.lua",
        "Core.lua",
        "UI.lua",
        "Tests.lua",
    ]

    # Shared addon table
    lua.execute("local addonName, RF = 'RankForge', {}; _G['RankForgeAddon'] = RF; _G['RF_Shared'] = RF")
    RF = lua.globals()["RF_Shared"]

    # Load and execute each file
    for filename in lua_files:
        filepath = os.path.join(addon_path, filename)
        if not os.path.exists(filepath):
            print(f"Error: Missing {filepath}")
            sys.exit(1)
        with open(filepath, "r", encoding="utf-8") as f:
            code = f.read()
        try:
            loader = lua.eval(f"(function(...)\n{code}\nend)")
            loader('RankForge', RF)
        except Exception as e:
            print(f"FAILED loading {filename}: {e}")
            sys.exit(1)

    # Execute tests
    start_time = time.time()
    try:
        passed, failed, results = RF.RunAllTests(RF)
    except Exception as e:
        print(f"Execution Error running tests: {e}")
        sys.exit(1)

    total_time = time.time() - start_time

    # Generate JUnit XML Report
    testsuites_elem = ET.Element("testsuites", name="RankForgeTests", time=f"{total_time:.3f}")
    testsuite_elem = ET.SubElement(
        testsuites_elem,
        "testsuite",
        name="RankForge.AllTests",
        tests=str(len(results)),
        failures=str(failed),
        errors="0",
        skipped="0",
        time=f"{total_time:.3f}",
        timestamp=time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    )

    for i in range(1, len(results) + 1):
        res = results[i]
        testcase = ET.SubElement(
            testsuite_elem,
            "testcase",
            name=str(res["name"]),
            classname="RankForge.TestSuite",
            time="0.001",
        )
        if not res["passed"]:
            fail_elem = ET.SubElement(testcase, "failure", message="Test Assertion Failed")
            fail_elem.text = str(res["error"])

    report_dir = os.path.join(addon_path, "test-reports")
    os.makedirs(report_dir, exist_ok=True)
    report_file = os.path.join(report_dir, "junit.xml")
    tree = ET.ElementTree(testsuites_elem)
    tree.write(report_file, encoding="utf-8", xml_declaration=True)

    print(f"\nJUnit XML report generated: {report_file}")
    print("=" * 60)
    if failed == 0:
        print(f"RESULT: ALL {passed} TESTS PASSED! (0 failures)")
        return 0
    else:
        print(f"RESULT: {failed} TESTS FAILED out of {passed + failed}!")
        return 1

if __name__ == "__main__":
    exit_code = run_tests()
    sys.exit(exit_code)
