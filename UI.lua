--[[
    RankForge - UI.lua
    User Interface: Macro list, editor, live preview, action-bar drag, presets, and Base64 import/export.
]]

local addonName, RF = ...
local L = RF.L

local currentMacro = nil
local selectedMacroIndex = 1

--------------------------------------------------------------------------------
-- Confirmation Dialog for Deletion
--------------------------------------------------------------------------------
StaticPopupDialogs["RANKFORGE_CONFIRM_DELETE"] = {
    text = L["CONFIRM_DELETE_TEXT"],
    button1 = L["CONFIRM_YES"],
    button2 = L["CONFIRM_NO"],
    OnAccept = function(self, data)
        if data then
            RF:DeleteMacro(data, true)
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

--------------------------------------------------------------------------------
-- Main Frame Creation
--------------------------------------------------------------------------------
local function CreateMainUI()
    if RF.MainFrame then return RF.MainFrame end

    local f = CreateFrame("Frame", "RankForgeMainFrame", UIParent, "BackdropTemplate")
    f:SetSize(1040, 720)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)

    -- Backdrop
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    f:SetBackdropColor(0.08, 0.08, 0.1, 0.95)

    -- Header Title
    local titleBg = f:CreateTexture(nil, "ARTWORK")
    titleBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    titleBg:SetWidth(540)
    titleBg:SetHeight(64)
    titleBg:SetPoint("TOP", f, "TOP", 0, 12)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", titleBg, "TOP", 0, -14)
    title:SetText(L["UI_TITLE"])

    -- Close Button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)

    ----------------------------------------------------------------------------
    -- Left Panel: Macro List
    ----------------------------------------------------------------------------
    local leftPanel = CreateFrame("Frame", nil, f, "BackdropTemplate")
    leftPanel:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -35)
    leftPanel:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 15, 15)
    leftPanel:SetWidth(220)
    leftPanel:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    leftPanel:SetBackdropColor(0.05, 0.05, 0.07, 0.8)

    local listHeader = leftPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
    listHeader:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 10, -10)
    listHeader:SetText(L["UI_CONFIGURED_MACROS"])

    -- Macro Scroll Frame
    local scrollFrame = CreateFrame("ScrollFrame", "RankForgeMacroListScroll", leftPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 8, -32)
    scrollFrame:SetPoint("BOTTOMRIGHT", leftPanel, "BOTTOMRIGHT", -26, 110)

    local listContent = CreateFrame("Frame", nil, scrollFrame)
    listContent:SetSize(185, 10)
    scrollFrame:SetScrollChild(listContent)
    f.listContent = listContent

    -- Buttons on Left Panel
    local newBtn = CreateFrame("Button", nil, leftPanel, "UIPanelButtonTemplate")
    newBtn:SetSize(200, 24)
    newBtn:SetPoint("BOTTOM", leftPanel, "BOTTOM", 0, 75)
    newBtn:SetText(L["UI_NEW_MACRO"])
    newBtn:SetScript("OnClick", function()
        RF:CreateNewMacroConfig()
    end)

    local presetBtn = CreateFrame("Button", nil, leftPanel, "UIPanelButtonTemplate")
    presetBtn:SetSize(200, 24)
    presetBtn:SetPoint("BOTTOM", leftPanel, "BOTTOM", 0, 45)
    presetBtn:SetText(L["UI_PRESETS_BTN"])
    presetBtn:SetScript("OnClick", function()
        RF:OpenPresetsDialog()
    end)

    local exportBtn = CreateFrame("Button", nil, leftPanel, "UIPanelButtonTemplate")
    exportBtn:SetSize(200, 24)
    exportBtn:SetPoint("BOTTOM", leftPanel, "BOTTOM", 0, 15)
    exportBtn:SetText(L["UI_EXPORT_BTN"])
    exportBtn:SetScript("OnClick", function()
        RF:OpenImportExportDialog()
    end)

    -- Slot status text
    local slotStatus = leftPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    slotStatus:SetPoint("BOTTOMLEFT", leftPanel, "BOTTOMLEFT", 10, 105)
    f.slotStatus = slotStatus

    ----------------------------------------------------------------------------
    -- Right Panel: Macro Editor
    ----------------------------------------------------------------------------
    local editor = CreateFrame("Frame", nil, f, "BackdropTemplate")
    editor:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", 10, 0)
    editor:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -15, 15)
    editor:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    editor:SetBackdropColor(0.05, 0.05, 0.07, 0.8)
    f.editor = editor

    -- Macro Name Input
    local nameLabel = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameLabel:SetPoint("TOPLEFT", editor, "TOPLEFT", 15, -15)
    nameLabel:SetText(L["UI_MACRO_NAME"])

    local nameEdit = CreateFrame("EditBox", nil, editor, "InputBoxTemplate")
    nameEdit:SetSize(160, 20)
    nameEdit:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
    nameEdit:SetAutoFocus(false)
    nameEdit:SetScript("OnTextChanged", function(self, userInput)
        if userInput and currentMacro then
            currentMacro.macroName = self:GetText()
            RF:UpdatePreview()
            if selectedMacroIndex and f.listContent and f.listContent.buttons then
                local b = f.listContent.buttons[selectedMacroIndex]
                if b then b:SetText(self:GetText()) end
            end
        end
    end)
    f.nameEdit = nameEdit

    -- Storage Location (Account vs Char) Dropdown
    local storageDropdown = CreateFrame("Frame", "RankForgeStorageDropdown", editor, "UIDropDownMenuTemplate")
    storageDropdown:SetPoint("LEFT", nameEdit, "RIGHT", -5, -2)
    UIDropDownMenu_SetWidth(storageDropdown, 185)

    local function StorageDropdown_OnClick(btn)
        local isAcc = (btn.value == "account")
        UIDropDownMenu_SetSelectedValue(storageDropdown, btn.value)
        UIDropDownMenu_SetText(storageDropdown, isAcc and L["UI_STORAGE_ACCOUNT"] or L["UI_STORAGE_CHAR"])
        if currentMacro then
            currentMacro.isAccount = isAcc
            RF:UpdatePreview()
        end
        CloseDropDownMenus()
    end

    local function StorageDropdown_Initialize()
        local isAcc = (not currentMacro) or (currentMacro.isAccount ~= false)
        local info = UIDropDownMenu_CreateInfo()

        info.text = L["UI_STORAGE_ACCOUNT"]
        info.value = "account"
        info.func = StorageDropdown_OnClick
        info.checked = isAcc
        UIDropDownMenu_AddButton(info)

        info.text = L["UI_STORAGE_CHAR"]
        info.value = "char"
        info.func = StorageDropdown_OnClick
        info.checked = not isAcc
        UIDropDownMenu_AddButton(info)
    end

    UIDropDownMenu_Initialize(storageDropdown, StorageDropdown_Initialize)
    f.storageDropdown = storageDropdown

    -- Base Spell Section (Drag&Drop Slot + Text Edit + Dropdown)
    local spellLabel = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    spellLabel:SetPoint("TOPLEFT", editor, "TOPLEFT", 15, -48)
    spellLabel:SetText(L["UI_SPELL_NAME"])

    -- Drag & Drop Spell Button Slot
    local dropSlot = CreateFrame("Button", nil, editor, "BackdropTemplate")
    dropSlot:SetSize(36, 36)
    dropSlot:SetPoint("LEFT", spellLabel, "RIGHT", 10, 0)
    dropSlot:SetBackdrop({
        edgeFile = "Interface\\Buttons\\UI-Quickslot-Depress",
        edgeSize = 14,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })

    local dropSlotIcon = dropSlot:CreateTexture(nil, "ARTWORK")
    dropSlotIcon:SetAllPoints()
    dropSlotIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    dropSlot.icon = dropSlotIcon

    local dropSlotText = editor:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    dropSlotText:SetPoint("LEFT", dropSlot, "RIGHT", 8, 0)
    dropSlotText:SetText(L["UI_DROP_SPELL_HERE"])

    -- Handle Drag & Drop spell onto drop slot
    dropSlot:SetScript("OnReceiveDrag", function(self)
        local infoType, info1, info2 = GetCursorInfo()
        if infoType == "spell" then
            local spellName = nil
            if C_Spell and C_Spell.GetSpellInfo and info2 then
                local info = C_Spell.GetSpellInfo(info2)
                spellName = info and info.name
            elseif GetSpellInfo and info2 then
                spellName = GetSpellInfo(info2)
            end
            if not spellName and info1 then
                spellName = GetSpellBookItemName(info1, BOOKTYPE_SPELL or "spell")
            end

            if spellName and currentMacro then
                ClearCursor()
                currentMacro.spellName = spellName
                if currentMacro.macroName == "" or currentMacro.macroName:match("^DR_") then
                    currentMacro.macroName = "DR_" .. spellName:gsub("%s+", "")
                end
                RF:LoadMacroIntoEditor(currentMacro)
            end
        end
    end)
    dropSlot:SetScript("OnClick", function(self)
        self:GetScript("OnReceiveDrag")(self)
    end)
    f.dropSlot = dropSlot

    -- Spell Name Manual Input
    local spellEdit = CreateFrame("EditBox", nil, editor, "InputBoxTemplate")
    spellEdit:SetSize(140, 20)
    spellEdit:SetPoint("LEFT", dropSlotText, "RIGHT", 15, 0)
    spellEdit:SetAutoFocus(false)
    spellEdit:SetScript("OnTextChanged", function(self, userInput)
        if userInput and currentMacro then
            currentMacro.spellName = self:GetText()
            RF:UpdatePreview()
        end
    end)
    spellEdit:SetScript("OnEnterPressed", function(self)
        local query = self:GetText():lower():trim()
        local spells = RF:GetLearnedSpellList()
        local matches = {}
        for _, sp in ipairs(spells) do
            if sp.name:lower() == query or sp.name:lower():find(query, 1, true) then
                table.insert(matches, sp)
            end
        end
        if #matches >= 1 then
            local chosen = matches[1].name
            for _, sp in ipairs(matches) do
                if sp.name:lower() == query then
                    chosen = sp.name
                    break
                end
            end
            self:SetText(chosen)
            if currentMacro then
                currentMacro.spellName = chosen
                if currentMacro.macroName == "" or currentMacro.macroName:match("^DR_") then
                    currentMacro.macroName = "DR_" .. chosen:gsub("%s+", "")
                end
                RF:LoadMacroIntoEditor(currentMacro)
            end
        end
        self:ClearFocus()
    end)
    spellEdit:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    f.spellEdit = spellEdit

    -- Fallback Mode Toggle
    local fallbackCheck = CreateFrame("CheckButton", nil, editor, "UICheckButtonTemplate")
    fallbackCheck:SetPoint("TOPLEFT", editor, "TOPLEFT", 15, -90)
    fallbackCheck.text = fallbackCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fallbackCheck.text:SetPoint("LEFT", fallbackCheck, "RIGHT", 2, 0)
    fallbackCheck.text:SetText(L["UI_FALLBACK_RANK1"])
    fallbackCheck:SetScript("OnClick", function(self)
        if currentMacro then
            currentMacro.fallbackMode = self:GetChecked() and "rank1" or "omit"
            RF:UpdatePreview()
        end
    end)
    f.fallbackCheck = fallbackCheck

    ----------------------------------------------------------------------------
    -- Pre-Cast Utility: Trinkets & Racials
    ----------------------------------------------------------------------------
    local function CreateTargetCheck(text, x, y, key)
        local cb = CreateFrame("CheckButton", nil, editor, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", editor, "TOPLEFT", x, y)
        cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        cb.text:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        cb.text:SetText(text)
        cb:SetScript("OnClick", function(self)
            if currentMacro then
                currentMacro[key] = self:GetChecked()
                RF:UpdatePreview()
            end
        end)
        return cb
    end

    f.cbTrinket1  = CreateTargetCheck(L["UI_USE_TRINKET_1"], 15, -114, "useTrinket1")
    f.cbTrinket2  = CreateTargetCheck(L["UI_USE_TRINKET_2"], 175, -114, "useTrinket2")
    f.cbRacial    = CreateTargetCheck(L["UI_USE_RACIAL"], 345, -114, "useRacial")

    -- Pre-Cast Extra Commands Input (Potions, additional spells, /click, etc.)
    local preCastLabel = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    preCastLabel:SetPoint("TOPLEFT", editor, "TOPLEFT", 15, -138)
    preCastLabel:SetText(L["UI_PRECAST_CUSTOM"])

    local preCastEdit = CreateFrame("EditBox", nil, editor, "InputBoxTemplate")
    preCastEdit:SetPoint("TOPLEFT", editor, "TOPLEFT", 18, -154)
    preCastEdit:SetPoint("RIGHT", editor, "RIGHT", -25, 0)
    preCastEdit:SetHeight(20)
    preCastEdit:SetAutoFocus(false)
    preCastEdit:SetScript("OnTextChanged", function(self, userInput)
        if userInput and currentMacro then
            currentMacro.preCastLines = self:GetText()
            RF:UpdatePreview()
        end
    end)
    f.preCastEdit = preCastEdit

    -- Custom Condition Input
    local customTargetLabel = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    customTargetLabel:SetPoint("TOPLEFT", editor, "TOPLEFT", 15, -182)
    customTargetLabel:SetText(L["UI_TARGET_CUSTOM"])

    local customTargetEdit = CreateFrame("EditBox", nil, editor, "InputBoxTemplate")
    customTargetEdit:SetPoint("LEFT", customTargetLabel, "RIGHT", 10, 0)
    customTargetEdit:SetPoint("RIGHT", editor, "RIGHT", -25, 0)
    customTargetEdit:SetHeight(20)
    customTargetEdit:SetAutoFocus(false)
    customTargetEdit:SetScript("OnTextChanged", function(self, userInput)
        if userInput and currentMacro then
            currentMacro.customTarget = self:GetText()
            RF:UpdatePreview()
        end
    end)
    f.customTargetEdit = customTargetEdit

    ----------------------------------------------------------------------------
    -- Matrix Grid Section: Modifiers, Ranks & Targeting per Row
    ----------------------------------------------------------------------------
    local modHeader = editor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    modHeader:SetPoint("TOPLEFT", editor, "TOPLEFT", 15, -210)
    modHeader:SetText(L["UI_MODIFIERS_HEADER"])

    local resetSortBtn = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    resetSortBtn:SetSize(140, 18)
    resetSortBtn:SetPoint("LEFT", modHeader, "RIGHT", 10, 0)
    resetSortBtn:SetText(L["UI_RESET_SORT_BTN"])
    resetSortBtn:SetScript("OnClick", function()
        if currentMacro then
            RF:ResetModifierSortOrder(currentMacro)
        end
    end)
    resetSortBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["UI_RESET_SORT_BTN"])
        GameTooltip:AddLine(L["UI_RESET_SORT_TOOLTIP"], 1, 1, 1, true)
        GameTooltip:Show()
    end)
    resetSortBtn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    f.resetSortBtn = resetSortBtn

    -- Column Headers for the Matrix Grid
    local gridHeader = CreateFrame("Frame", nil, editor)
    gridHeader:SetSize(755, 16)
    gridHeader:SetPoint("TOPLEFT", editor, "TOPLEFT", 15, -232)

    local function CreateColHeader(x, text, tooltipTitle, tooltipDesc)
        local h = gridHeader:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        h:SetPoint("LEFT", gridHeader, "LEFT", x, 0)
        h:SetText(text)
        if tooltipTitle then
            local btn = CreateFrame("Button", nil, gridHeader)
            btn:SetAllPoints(h)
            btn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText(tooltipTitle, 1, 1, 1)
                if tooltipDesc then GameTooltip:AddLine(tooltipDesc, 0.8, 0.8, 0.8, true) end
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
        return h
    end

    CreateColHeader(40,  L["UI_GRID_MOD"])
    CreateColHeader(135, L["UI_GRID_RANK"])
    CreateColHeader(240, L["UI_GRID_MO"], "Mouseover (@mouseover)", "Wirkt auf die Einheit unter dem Mauszeiger")
    CreateColHeader(285, L["UI_GRID_FOCUS"], "Fokus-Ziel (@focus)", "Wirkt auf dein gesetztes Fokus-Ziel")
    CreateColHeader(330, L["UI_GRID_TOT"], "Ziel des Ziels (@targettarget)", "Wirkt auf das Ziel deines aktuellen Ziels")
    CreateColHeader(375, L["UI_GRID_SELF"], "Selbstzauber-Fallback (@player)", "Wirkt auf dich selbst, wenn kein anderes Ziel aktiv ist")
    CreateColHeader(430, L["UI_GRID_FILTER"], "Ziel-Filter (help / nodead)", "Schränkt das Ziel auf freundlich ('help') und/oder lebendig ('nodead') ein")
    CreateColHeader(555, L["UI_GRID_ALTSPELL"])

    f.modRows = {}
    local startY = -252
    local rowHeight = 24

    for i = 1, 7 do
        local row = CreateFrame("Frame", nil, editor)
        row:SetSize(755, rowHeight)
        row:SetPoint("TOPLEFT", editor, "TOPLEFT", 15, startY - (i - 1) * rowHeight)

        -- Up/Down order buttons using native WoW scroll button templates
        local upBtn = CreateFrame("Button", nil, row, "UIPanelScrollUpButtonTemplate")
        upBtn:SetSize(18, 18)
        upBtn:SetPoint("LEFT", row, "LEFT", 0, 0)
        upBtn:SetScript("OnClick", function()
            RF:MoveModifierOrder(i, -1)
        end)
        row.upBtn = upBtn

        local downBtn = CreateFrame("Button", nil, row, "UIPanelScrollDownButtonTemplate")
        downBtn:SetSize(18, 18)
        downBtn:SetPoint("LEFT", upBtn, "RIGHT", 2, 0)
        downBtn:SetScript("OnClick", function()
            RF:MoveModifierOrder(i, 1)
        end)
        row.downBtn = downBtn

        -- Enable Checkbox
        local enableCb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        enableCb:SetPoint("LEFT", downBtn, "RIGHT", 4, 0)
        enableCb:SetScript("OnClick", function(self)
            if currentMacro and currentMacro.modifiers and currentMacro.modifiers[i] then
                currentMacro.modifiers[i].enabled = self:GetChecked()
                RF:UpdatePreview()
            end
        end)
        row.enableCb = enableCb

        -- Mod Label
        local modLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        modLabel:SetPoint("LEFT", row, "LEFT", 62, 0)
        modLabel:SetWidth(68)
        modLabel:SetJustifyH("LEFT")
        row.modLabel = modLabel

        -- Rank Offset Selector
        local offsetLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        offsetLabel:SetPoint("LEFT", row, "LEFT", 132, 0)
        offsetLabel:SetText("Rang:")
        row.offsetLabel = offsetLabel

        local offsetEdit = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
        offsetEdit:SetSize(22, 18)
        offsetEdit:SetPoint("LEFT", row, "LEFT", 166, 0)
        offsetEdit:SetAutoFocus(false)
        offsetEdit:SetNumeric(true)
        offsetEdit:SetMaxLetters(2)
        offsetEdit:SetScript("OnTextChanged", function(self, userInput)
            if userInput and currentMacro and currentMacro.modifiers and currentMacro.modifiers[i] then
                local val = tonumber(self:GetText()) or 0
                currentMacro.modifiers[i].rankOffset = val
                row.descText:SetText(val == 0 and "(Max)" or string.format("(-%d)", val))
                RF:UpdatePreview()
            end
        end)
        row.offsetEdit = offsetEdit

        local descText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        descText:SetPoint("LEFT", row, "LEFT", 192, 0)
        descText:SetWidth(44)
        descText:SetJustifyH("LEFT")
        row.descText = descText

        -- Grid Targeting Checkboxes per Row
        local function CreateRowTargetCheck(x, tooltipTitle, tooltipDesc, onToggle)
            local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
            cb:SetSize(20, 20)
            cb:SetPoint("LEFT", row, "LEFT", x, 0)
            cb:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText(tooltipTitle, 1, 1, 1)
                if tooltipDesc then GameTooltip:AddLine(tooltipDesc, 0.8, 0.8, 0.8, true) end
                GameTooltip:Show()
            end)
            cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
            cb:SetScript("OnClick", function(self)
                if onToggle then onToggle(self:GetChecked()) end
                RF:UpdatePreview()
            end)
            return cb
        end

        row.cbMo = CreateRowTargetCheck(240, "Mouseover (@mouseover)", "Wirkt auf die Einheit unter der Maus", function(checked)
            if currentMacro and currentMacro.modifiers and currentMacro.modifiers[i] then
                currentMacro.modifiers[i].targetMouseover = checked
            end
        end)

        row.cbFocus = CreateRowTargetCheck(285, "Fokus-Ziel (@focus)", "Wirkt auf dein gesetztes Fokus-Ziel", function(checked)
            if currentMacro and currentMacro.modifiers and currentMacro.modifiers[i] then
                currentMacro.modifiers[i].targetFocus = checked
            end
        end)

        row.cbToT = CreateRowTargetCheck(330, "Ziel des Ziels (@targettarget)", "Wirkt auf das Ziel deines aktuellen Ziels", function(checked)
            if currentMacro and currentMacro.modifiers and currentMacro.modifiers[i] then
                currentMacro.modifiers[i].targetToT = checked
            end
        end)

        row.cbSelfcast = CreateRowTargetCheck(375, "Auto-Selfcast Fallback (@player)", "Wirkt auf dich selbst", function(checked)
            if currentMacro and currentMacro.modifiers and currentMacro.modifiers[i] then
                currentMacro.modifiers[i].targetSelfcast = checked
            end
        end)

        row.cbHelp = CreateRowTargetCheck(430, "help", "Nur auf freundliche Ziele wirken", function(checked)
            if currentMacro and currentMacro.modifiers and currentMacro.modifiers[i] then
                currentMacro.modifiers[i].isHelp = checked
                if checked then currentMacro.modifiers[i].isHarm = false end
            end
        end)
        row.cbHelp.text = row.cbHelp:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.cbHelp.text:SetPoint("LEFT", row.cbHelp, "RIGHT", 1, 0)
        row.cbHelp.text:SetText("help")

        row.cbNodead = CreateRowTargetCheck(485, "nodead", "Nur auf lebende Ziele wirken (keine Toten)", function(checked)
            if currentMacro and currentMacro.modifiers and currentMacro.modifiers[i] then
                currentMacro.modifiers[i].isNodead = checked
            end
        end)
        row.cbNodead.text = row.cbNodead:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.cbNodead.text:SetPoint("LEFT", row.cbNodead, "RIGHT", 1, 0)
        row.cbNodead.text:SetText("nodead")

        -- Drop slot icon for Alt. Zauber
        local altDropSlot = CreateFrame("Button", nil, row, "BackdropTemplate")
        altDropSlot:SetSize(18, 18)
        altDropSlot:SetPoint("LEFT", row, "LEFT", 555, 0)
        altDropSlot:SetBackdrop({
            edgeFile = "Interface\\Buttons\\UI-Quickslot-Depress",
            edgeSize = 10,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })

        local altDropIcon = altDropSlot:CreateTexture(nil, "ARTWORK")
        altDropIcon:SetAllPoints()
        altDropIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        altDropIcon:SetAlpha(0.6)
        altDropSlot.icon = altDropIcon
        row.altDropSlot = altDropSlot

        local customSpellEdit = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
        customSpellEdit:SetSize(140, 18)
        customSpellEdit:SetPoint("LEFT", row, "LEFT", 577, 0)
        customSpellEdit:SetAutoFocus(false)
        row.customSpellEdit = customSpellEdit

        -- Search / Picker button
        local searchBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        searchBtn:SetSize(22, 18)
        searchBtn:SetPoint("LEFT", row, "LEFT", 722, 0)
        searchBtn:SetText("...")
        row.searchBtn = searchBtn

        -- Helper to apply a selected spell to this modifier
        local function ApplySpellToModifier(spellName)
            if not spellName or spellName == "" then
                customSpellEdit:SetText("")
                altDropIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                altDropIcon:SetAlpha(0.6)
                if currentMacro and currentMacro.modifiers and currentMacro.modifiers[i] then
                    currentMacro.modifiers[i].customSpell = ""
                    currentMacro.modifiers[i].mode = "relative"
                end
            else
                customSpellEdit:SetText(spellName)
                local tex = GetSpellTexture(spellName) or "Interface\\Icons\\INV_Misc_QuestionMark"
                altDropIcon:SetTexture(tex)
                altDropIcon:SetAlpha(1.0)
                if currentMacro and currentMacro.modifiers and currentMacro.modifiers[i] then
                    currentMacro.modifiers[i].customSpell = spellName
                    currentMacro.modifiers[i].mode = "custom"
                end
            end
            RF:UpdatePreview()
        end

        -- Drag and drop onto DropSlot
        local function HandleSpellDrop()
            local infoType, info1, info2 = GetCursorInfo()
            if infoType == "spell" then
                local spellName = nil
                if C_Spell and C_Spell.GetSpellInfo and info2 then
                    local info = C_Spell.GetSpellInfo(info2)
                    spellName = info and info.name
                elseif GetSpellInfo and info2 then
                    spellName = GetSpellInfo(info2)
                end
                if not spellName and info1 then
                    spellName = GetSpellBookItemName(info1, BOOKTYPE_SPELL or "spell")
                end
                if spellName then
                    ClearCursor()
                    ApplySpellToModifier(spellName)
                end
            end
        end

        altDropSlot:SetScript("OnReceiveDrag", HandleSpellDrop)
        altDropSlot:SetScript("OnClick", function(self)
            local infoType = GetCursorInfo()
            if infoType == "spell" then
                HandleSpellDrop()
            else
                RF:OpenSpellPicker(customSpellEdit, ApplySpellToModifier)
            end
        end)

        customSpellEdit:SetScript("OnReceiveDrag", HandleSpellDrop)
        customSpellEdit:SetScript("OnTextChanged", function(self, userInput)
            if userInput and currentMacro and currentMacro.modifiers and currentMacro.modifiers[i] then
                local text = self:GetText():trim()
                currentMacro.modifiers[i].customSpell = text
                currentMacro.modifiers[i].mode = (text ~= "") and "custom" or "relative"
                local tex = (text ~= "") and GetSpellTexture(text) or "Interface\\Icons\\INV_Misc_QuestionMark"
                altDropIcon:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
                altDropIcon:SetAlpha((text ~= "") and 1.0 or 0.6)
                RF:UpdatePreview()
            end
        end)
        customSpellEdit:SetScript("OnEnterPressed", function(self)
            local query = self:GetText():lower():trim()
            local spells = RF:GetLearnedSpellList()
            local matches = {}
            for _, sp in ipairs(spells) do
                if sp.name:lower() == query or sp.name:lower():find(query, 1, true) then
                    table.insert(matches, sp)
                end
            end
            if #matches >= 1 then
                local chosen = matches[1].name
                for _, sp in ipairs(matches) do
                    if sp.name:lower() == query then
                        chosen = sp.name
                        break
                    end
                end
                ApplySpellToModifier(chosen)
            end
            self:ClearFocus()
        end)
        customSpellEdit:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
        end)

        searchBtn:SetScript("OnClick", function()
            RF:OpenSpellPicker(customSpellEdit, ApplySpellToModifier)
        end)

        table.insert(f.modRows, row)
    end

    ----------------------------------------------------------------------------
    -- Bottom Area: Preview & Action Bar Drag
    ----------------------------------------------------------------------------
    local previewHeader = editor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    previewHeader:SetPoint("TOPLEFT", editor, "TOPLEFT", 15, -436)
    previewHeader:SetText(L["UI_PREVIEW_HEADER"])

    local dragHint = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dragHint:SetPoint("LEFT", previewHeader, "RIGHT", 10, 0)
    dragHint:SetText("|cff00ff00(" .. L["UI_DRAG_HINT"] .. ")|r")

    -- Action Bar Drag Preview Icon
    local previewIcon = CreateFrame("Button", "RankForgePreviewDragButton", editor, "BackdropTemplate")
    previewIcon:SetSize(42, 42)
    previewIcon:SetPoint("TOPLEFT", editor, "TOPLEFT", 15, -458)
    previewIcon:SetBackdrop({
        edgeFile = "Interface\\Buttons\\UI-Quickslot-Depress",
        edgeSize = 14,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    previewIcon:RegisterForDrag("LeftButton")

    local pTex = previewIcon:CreateTexture(nil, "ARTWORK")
    pTex:SetAllPoints()
    pTex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    previewIcon.icon = pTex

    -- Direct Drag to Action Bar!
    previewIcon:SetScript("OnDragStart", function(self)
        if currentMacro and currentMacro.macroName then
            local index = RF:FindMacroIndex(currentMacro.macroName)
            if not index then
                -- Sync/create it first so an index exists
                local ok, status, newIdx = RF:SyncMacro(currentMacro, true)
                index = newIdx or RF:FindMacroIndex(currentMacro.macroName)
            end
            if index and PickupMacro then
                PickupMacro(index)
            end
        end
    end)
    previewIcon:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(currentMacro and currentMacro.macroName or "Makro")
        GameTooltip:AddLine(L["UI_DRAG_HINT"], 0, 1, 0, true)
        GameTooltip:Show()
    end)
    previewIcon:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    f.previewIcon = previewIcon

    -- Preview Text Scroll Frame
    local previewBoxBg = CreateFrame("Frame", nil, editor, "BackdropTemplate")
    previewBoxBg:SetPoint("TOPLEFT", previewIcon, "TOPRIGHT", 10, 0)
    previewBoxBg:SetPoint("BOTTOMRIGHT", editor, "BOTTOMRIGHT", -15, 45)
    previewBoxBg:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })

    local copyHint = editor:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    copyHint:SetPoint("BOTTOMRIGHT", previewBoxBg, "TOPRIGHT", 0, 4)
    copyHint:SetText("|cff888888(Klick = Alles markieren für Strg+C)|r")

    local previewScroll = CreateFrame("ScrollFrame", "RankForgePreviewScrollFrame", previewBoxBg, "UIPanelScrollFrameTemplate")
    previewScroll:SetPoint("TOPLEFT", previewBoxBg, "TOPLEFT", 6, -6)
    previewScroll:SetPoint("BOTTOMRIGHT", previewBoxBg, "BOTTOMRIGHT", -26, 6)

    local previewEdit = CreateFrame("EditBox", "RankForgePreviewEditBox", previewScroll)
    previewEdit:SetMultiLine(true)
    previewEdit:SetAutoFocus(false)
    previewEdit:SetFontObject("GameFontHighlightSmall")
    previewEdit:SetWidth(580)
    previewEdit:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    previewEdit:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    previewEdit:SetScript("OnTextChanged", function(self, userInput)
        if userInput and currentMacro then
            local body = RF:GenerateMacroBody(currentMacro)
            if self:GetText() ~= body then
                self:SetText(body)
                self:HighlightText()
            end
        end
    end)
    previewScroll:SetScrollChild(previewEdit)
    f.previewText = previewEdit
    f.previewScroll = previewScroll

    -- Character Count
    local charCount = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    charCount:SetPoint("BOTTOMLEFT", editor, "BOTTOMLEFT", 15, 18)
    f.charCount = charCount

    -- Save Button
    local saveBtn = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    saveBtn:SetSize(160, 24)
    saveBtn:SetPoint("BOTTOMRIGHT", editor, "BOTTOMRIGHT", -15, 12)
    saveBtn:SetText(L["UI_SAVE_MACRO"])
    saveBtn:SetScript("OnClick", function()
        if currentMacro then
            RF:SyncMacro(currentMacro, false)
            RF:UpdateUI()
        end
    end)
    f.saveBtn = saveBtn

    -- Delete Button
    local deleteBtn = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    deleteBtn:SetSize(90, 24)
    deleteBtn:SetPoint("RIGHT", saveBtn, "LEFT", -10, 0)
    deleteBtn:SetText(L["UI_DELETE_MACRO"])
    deleteBtn:SetScript("OnClick", function()
        if currentMacro then
            StaticPopup_Show("RANKFORGE_CONFIRM_DELETE", currentMacro.macroName, nil, currentMacro)
        end
    end)
    f.deleteBtn = deleteBtn

    RF.MainFrame = f
    return f
end

--------------------------------------------------------------------------------
-- Modifiers Reordering (Up/Down)
--------------------------------------------------------------------------------
function RF:MoveModifierOrder(index, direction)
    if not currentMacro or not currentMacro.modifiers then return end
    local targetIndex = index + direction
    if targetIndex < 1 or targetIndex > #currentMacro.modifiers then return end

    local temp = currentMacro.modifiers[index]
    currentMacro.modifiers[index] = currentMacro.modifiers[targetIndex]
    currentMacro.modifiers[targetIndex] = temp
    currentMacro.customSortOrder = true

    RF:LoadModifiersIntoUI(currentMacro)
    RF:UpdatePreview()
end

local DEFAULT_SPECIFICITY_KEYS = {
    "shift_ctrl",
    "shift_alt",
    "ctrl_alt",
    "shift",
    "ctrl",
    "alt",
    "nomod"
}

local KEY_DEFAULT_INDEX = {}
for idx, k in ipairs(DEFAULT_SPECIFICITY_KEYS) do
    KEY_DEFAULT_INDEX[k] = idx
end

function RF:ResetModifierSortOrder(macroConfig)
    if not macroConfig or not macroConfig.modifiers then return end
    RF:EnsureAllModifiers(macroConfig)
    table.sort(macroConfig.modifiers, function(a, b)
        local orderA = KEY_DEFAULT_INDEX[a.key] or 99
        local orderB = KEY_DEFAULT_INDEX[b.key] or 99
        return orderA < orderB
    end)
    macroConfig.customSortOrder = false
    if RF.LoadModifiersIntoUI then
        RF:LoadModifiersIntoUI(macroConfig)
    end
    if RF.UpdatePreview then
        RF:UpdatePreview()
    end
end

--------------------------------------------------------------------------------
-- Modifier Labels & Default Setup
--------------------------------------------------------------------------------
local MOD_DISPLAY_NAMES = {
    ["shift_ctrl"] = L["UI_MOD_SHIFT_CTRL"],
    ["shift_alt"]  = L["UI_MOD_SHIFT_ALT"],
    ["ctrl_alt"]   = L["UI_MOD_CTRL_ALT"],
    ["shift"]      = L["UI_MOD_SHIFT"],
    ["ctrl"]       = L["UI_MOD_CTRL"],
    ["alt"]        = L["UI_MOD_ALT"],
    ["nomod"]      = L["UI_MOD_NOMOD"]
}

local DEFAULT_MODIFIERS_LIST = {
    { key = "shift_ctrl", enabled = false, mode = "relative", rankOffset = 3, customSpell = "", targetMouseover = true, targetFocus = false, targetToT = false, targetSelfcast = false, isHelp = true, isHarm = false, isNodead = true },
    { key = "shift_alt",  enabled = false, mode = "relative", rankOffset = 4, customSpell = "", targetMouseover = true, targetFocus = false, targetToT = false, targetSelfcast = false, isHelp = true, isHarm = false, isNodead = true },
    { key = "ctrl_alt",   enabled = false, mode = "relative", rankOffset = 5, customSpell = "", targetMouseover = true, targetFocus = false, targetToT = false, targetSelfcast = false, isHelp = true, isHarm = false, isNodead = true },
    { key = "shift",      enabled = true,  mode = "relative", rankOffset = 1, customSpell = "", targetMouseover = true, targetFocus = false, targetToT = false, targetSelfcast = false, isHelp = true, isHarm = false, isNodead = true },
    { key = "ctrl",       enabled = false, mode = "relative", rankOffset = 2, customSpell = "", targetMouseover = true, targetFocus = false, targetToT = false, targetSelfcast = false, isHelp = true, isHarm = false, isNodead = true },
    { key = "alt",        enabled = true,  mode = "relative", rankOffset = 2, customSpell = "", targetMouseover = true, targetFocus = false, targetToT = false, targetSelfcast = false, isHelp = true, isHarm = false, isNodead = true },
    { key = "nomod",      enabled = true,  mode = "relative", rankOffset = 0, customSpell = "", targetMouseover = true, targetFocus = false, targetToT = false, targetSelfcast = true,  isHelp = true, isHarm = false, isNodead = true },
}

function RF:EnsureAllModifiers(macroConfig)
    if not macroConfig or not macroConfig.modifiers then return end
    local hasKey = {}
    for _, mod in ipairs(macroConfig.modifiers) do
        hasKey[mod.key] = true
        if mod.targetMouseover == nil then mod.targetMouseover = (macroConfig.targetMouseover ~= false) end
        if mod.targetFocus == nil then mod.targetFocus = (macroConfig.targetFocus or false) end
        if mod.targetToT == nil then mod.targetToT = (macroConfig.targetToT or false) end
        if mod.targetSelfcast == nil then mod.targetSelfcast = (mod.key == "nomod") end
        if mod.isHelp == nil then mod.isHelp = true end
        if mod.isHarm == nil then mod.isHarm = false end
        if mod.isNodead == nil then mod.isNodead = true end
    end
    for _, def in ipairs(DEFAULT_MODIFIERS_LIST) do
        if not hasKey[def.key] then
            table.insert(macroConfig.modifiers, {
                key = def.key,
                enabled = def.enabled,
                mode = def.mode,
                rankOffset = def.rankOffset,
                customSpell = "",
                targetMouseover = def.targetMouseover,
                targetFocus = def.targetFocus,
                targetToT = def.targetToT,
                targetSelfcast = def.targetSelfcast,
                isHelp = def.isHelp,
                isHarm = def.isHarm,
                isNodead = def.isNodead
            })
        end
    end
end

function RF:CreateNewMacroConfig()
    local _, classFileName = UnitClass("player")
    local newCfg = {
        macroName = "DR_Neu",
        spellName = "",
        isAccount = true,
        fallbackMode = "omit",
        targetMouseover = true,
        customTarget = "",
        customSortOrder = false,
        useTrinket1 = false,
        useTrinket2 = false,
        useRacial = false,
        preCastLines = "",
        modifiers = {}
    }

    for _, def in ipairs(DEFAULT_MODIFIERS_LIST) do
        table.insert(newCfg.modifiers, {
            key = def.key,
            enabled = def.enabled,
            mode = def.mode,
            rankOffset = def.rankOffset,
            customSpell = "",
            targetMouseover = def.targetMouseover,
            targetFocus = def.targetFocus,
            targetToT = def.targetToT,
            targetSelfcast = def.targetSelfcast,
            isHelp = def.isHelp,
            isHarm = def.isHarm,
            isNodead = def.isNodead
        })
    end

    local macros = RF:GetMacrosList()
    table.insert(macros, newCfg)
    selectedMacroIndex = #macros
    RF:UpdateUI()
    RF:LoadMacroIntoEditor(newCfg)
end

--------------------------------------------------------------------------------
-- UI Updating & Loading
--------------------------------------------------------------------------------
function RF:LoadModifiersIntoUI(macroConfig)
    if not RF.MainFrame or not macroConfig then return end
    local f = RF.MainFrame

    for i, row in ipairs(f.modRows) do
        local modData = macroConfig.modifiers and macroConfig.modifiers[i]
        if modData then
            row:Show()
            row.enableCb:SetChecked(modData.enabled)
            row.modLabel:SetText(MOD_DISPLAY_NAMES[modData.key] or modData.key)
            row.offsetEdit:SetText(tostring(modData.rankOffset or 0))
            local off = tonumber(modData.rankOffset) or 0
            row.descText:SetText(off == 0 and "(Max)" or string.format("(-%d)", off))

            -- Grid Targeting Checkboxes per Row
            if row.cbMo then row.cbMo:SetChecked(modData.targetMouseover ~= false) end
            if row.cbFocus then row.cbFocus:SetChecked(modData.targetFocus == true) end
            if row.cbToT then row.cbToT:SetChecked(modData.targetToT == true) end
            if row.cbSelfcast then row.cbSelfcast:SetChecked(modData.targetSelfcast == true) end
            if row.cbHelp then row.cbHelp:SetChecked(modData.isHelp ~= false) end
            if row.cbNodead then row.cbNodead:SetChecked(modData.isNodead ~= false) end

            local cSpell = modData.customSpell or ""
            row.customSpellEdit:SetText(cSpell)
            local tex = (cSpell ~= "") and GetSpellTexture(cSpell) or "Interface\\Icons\\INV_Misc_QuestionMark"
            if row.altDropSlot and row.altDropSlot.icon then
                row.altDropSlot.icon:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
                row.altDropSlot.icon:SetAlpha((cSpell ~= "") and 1.0 or 0.6)
            end
        else
            row:Hide()
        end
    end
end

function RF:LoadMacroIntoEditor(macroConfig)
    if macroConfig then
        RF:EnsureAllModifiers(macroConfig)
    end
    currentMacro = macroConfig
    if not RF.MainFrame or not macroConfig then return end
    local f = RF.MainFrame

    f.nameEdit:SetText(macroConfig.macroName or "")
    f.spellEdit:SetText(macroConfig.spellName or "")
    local isAcc = (macroConfig.isAccount ~= false)
    UIDropDownMenu_SetSelectedValue(f.storageDropdown, isAcc and "account" or "char")
    UIDropDownMenu_SetText(f.storageDropdown, isAcc and L["UI_STORAGE_ACCOUNT"] or L["UI_STORAGE_CHAR"])
    f.fallbackCheck:SetChecked(macroConfig.fallbackMode == "rank1")

    f.cbTrinket1:SetChecked(macroConfig.useTrinket1 or false)
    f.cbTrinket2:SetChecked(macroConfig.useTrinket2 or false)
    f.cbRacial:SetChecked(macroConfig.useRacial or false)
    f.preCastEdit:SetText(macroConfig.preCastLines or "")

    f.customTargetEdit:SetText(macroConfig.customTarget or "")

    -- Update icon
    local spellInfo = RF:GetSpellRanksInfo(macroConfig.spellName)
    local tex = "Interface\\Icons\\INV_Misc_QuestionMark"
    if spellInfo and spellInfo.spellID then
        local t = GetSpellTexture(spellInfo.spellID)
        if t then tex = t end
    end
    f.dropSlot.icon:SetTexture(tex)
    f.previewIcon.icon:SetTexture(tex)

    if selectedMacroIndex and f.listContent and f.listContent.buttons then
        local b = f.listContent.buttons[selectedMacroIndex]
        if b and b.icon then
            b.icon:SetTexture(tex)
            b:SetText(macroConfig.macroName or "")
        end
    end

    RF:LoadModifiersIntoUI(macroConfig)
    RF:UpdatePreview()
end

function RF:UpdatePreview()
    if not RF.MainFrame or not currentMacro then return end
    local f = RF.MainFrame

    local body = RF:GenerateMacroBody(currentMacro)
    f.previewText:SetText(body)

    local charCount = #body
    local countStr = string.format(L["UI_CHAR_COUNT"], charCount)

    if charCount > 255 then
        f.charCount:SetText("|cffff2222" .. countStr .. " - " .. L["UI_CHAR_COUNT_WARNING"] .. "|r")
    elseif charCount > 220 then
        f.charCount:SetText("|cffffcc00" .. countStr .. "|r")
    else
        f.charCount:SetText("|cff00ff00" .. countStr .. "|r")
    end
end

function RF:UpdateSlotStatus()
    if not RF.MainFrame or not RF.MainFrame.slotStatus then return end
    local freeAcc, usedAcc, maxAcc = RF:GetAvailableMacroSlots(true)
    local freeChar, usedChar, maxChar = RF:GetAvailableMacroSlots(false)
    RF.MainFrame.slotStatus:SetText(string.format("Allg.: %d/%d | Char: %d/%d", usedAcc, maxAcc or 120, usedChar, maxChar or 18))
end

function RF:UpdateUI()
    local f = CreateMainUI()
    local macros = RF:GetMacrosList()

    -- Update Slot Status
    RF:UpdateSlotStatus()

    -- Render Macro Buttons in Left List
    local listContent = f.listContent
    listContent.buttons = listContent.buttons or {}

    for _, btn in ipairs(listContent.buttons) do
        btn:Hide()
    end

    local yOffset = 0
    local btnHeight = 28

    for i, macroCfg in ipairs(macros) do
        local btn = listContent.buttons[i]
        if not btn then
            btn = CreateFrame("Button", nil, listContent, "UIPanelButtonTemplate")
            btn:SetSize(185, btnHeight)

            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetSize(20, 20)
            icon:SetPoint("LEFT", btn, "LEFT", 5, 0)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            btn.icon = icon

            local fs = btn:GetFontString()
            if fs then
                fs:ClearAllPoints()
                fs:SetPoint("LEFT", icon, "RIGHT", 6, 0)
                fs:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
                fs:SetJustifyH("LEFT")
            end

            listContent.buttons[i] = btn
        end

        btn:SetPoint("TOPLEFT", listContent, "TOPLEFT", 0, -yOffset)
        btn:SetText(macroCfg.macroName or ("Makro " .. i))

        -- Resolve spell icon for list button
        local tex = nil
        if macroCfg.spellName and macroCfg.spellName ~= "" then
            local spellInfo = RF:GetSpellRanksInfo(macroCfg.spellName)
            if spellInfo and spellInfo.spellID then
                tex = GetSpellTexture(spellInfo.spellID)
            end
            if not tex then
                tex = GetSpellTexture(macroCfg.spellName)
            end
        end
        btn.icon:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")

        -- Highlight currently selected macro button
        if i == selectedMacroIndex then
            btn:LockHighlight()
        else
            btn:UnlockHighlight()
        end

        btn:Show()

        btn:SetScript("OnClick", function()
            selectedMacroIndex = i
            for idx, b in ipairs(listContent.buttons) do
                if idx == i then
                    b:LockHighlight()
                else
                    b:UnlockHighlight()
                end
            end
            RF:LoadMacroIntoEditor(macroCfg)
        end)

        yOffset = yOffset + btnHeight + 2
    end

    listContent:SetHeight(math.max(yOffset, 10))

    if #macros > 0 then
        if not selectedMacroIndex or selectedMacroIndex > #macros then
            selectedMacroIndex = 1
        end
        RF:LoadMacroIntoEditor(macros[selectedMacroIndex])
    end
end

function RF:ToggleUI()
    local f = CreateMainUI()
    if f:IsShown() then
        f:Hide()
    else
        RF:UpdateUI()
        f:Show()
    end
end

--------------------------------------------------------------------------------
-- Presets Dialog
--------------------------------------------------------------------------------
function RF:OpenPresetsDialog()
    if RF.PresetsDialog then
        RF.PresetsDialog:Show()
        return
    end

    local d = CreateFrame("Frame", "RankForgePresetsDialog", UIParent, "BackdropTemplate")
    d:SetSize(400, 360)
    d:SetPoint("CENTER")
    d:SetMovable(true)
    d:EnableMouse(true)
    d:RegisterForDrag("LeftButton")
    d:SetScript("OnDragStart", d.StartMoving)
    d:SetScript("OnDragStop", d.StopMovingOrSizing)
    d:SetFrameStrata("FULLSCREEN_DIALOG")
    d:SetFrameLevel(500)
    d:SetToplevel(true)

    d:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    d:SetBackdropColor(0.04, 0.04, 0.06, 1.0)

    -- Fully opaque background blocker so nothing underneath shows through
    local bgTex = d:CreateTexture(nil, "BACKGROUND", nil, -5)
    bgTex:SetPoint("TOPLEFT", d, "TOPLEFT", 10, -10)
    bgTex:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", -10, 10)
    bgTex:SetColorTexture(0.05, 0.05, 0.08, 1.0)

    local title = d:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
    title:SetPoint("TOP", d, "TOP", 0, -16)
    title:SetText(L["PRESETS_TITLE"])

    local scroll = CreateFrame("ScrollFrame", nil, d, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", d, "TOPLEFT", 15, -45)
    scroll:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", -35, 45)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(340, 10)
    scroll:SetScrollChild(content)

    local _, classFileName = UnitClass("player")
    local presets = RF:GetPresetsForClass(classFileName or "PRIEST")
    local y = 0

    for i, p in ipairs(presets) do
        local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        btn:SetSize(330, 30)
        btn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
        btn:SetText(p.name .. " (" .. p.macroName .. ")")

        btn:SetScript("OnClick", function()
            local macros = RF:GetMacrosList()
            table.insert(macros, p)
            selectedMacroIndex = #macros
            RF:SyncMacro(p, false)
            RF:UpdateUI()
            d:Hide()
        end)

        y = y + 34
    end
    content:SetHeight(math.max(y, 10))

    local close = CreateFrame("Button", nil, d, "UIPanelButtonTemplate")
    close:SetSize(100, 24)
    close:SetPoint("BOTTOM", d, "BOTTOM", 0, 12)
    close:SetText(L["PRESETS_CLOSE"])
    close:SetScript("OnClick", function() d:Hide() end)

    RF.PresetsDialog = d
    d:Show()
end

--------------------------------------------------------------------------------
-- Base64 Profile Import / Export Dialog
--------------------------------------------------------------------------------
function RF:OpenImportExportDialog()
    if RF.ImportExportDialog then
        RF.ImportExportDialog:Show()
        return
    end

    local d = CreateFrame("Frame", "RankForgeImportExportDialog", UIParent, "BackdropTemplate")
    d:SetSize(520, 340)
    d:SetPoint("CENTER")
    d:SetMovable(true)
    d:EnableMouse(true)
    d:RegisterForDrag("LeftButton")
    d:SetScript("OnDragStart", d.StartMoving)
    d:SetScript("OnDragStop", d.StopMovingOrSizing)
    d:SetFrameStrata("FULLSCREEN_DIALOG")
    d:SetFrameLevel(500)
    d:SetToplevel(true)

    d:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    d:SetBackdropColor(0.04, 0.04, 0.06, 1.0)

    -- Fully opaque background blocker so nothing underneath shows through
    local bgTex = d:CreateTexture(nil, "BACKGROUND", nil, -5)
    bgTex:SetPoint("TOPLEFT", d, "TOPLEFT", 10, -10)
    bgTex:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", -10, 10)
    bgTex:SetColorTexture(0.05, 0.05, 0.08, 1.0)

    local title = d:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
    title:SetPoint("TOP", d, "TOP", 0, -16)
    title:SetText(L["PROFILE_TITLE"])

    local hint = d:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", d, "TOPLEFT", 20, -45)
    hint:SetText(L["PROFILE_EXPORT_HINT"])

    -- Scrollable EditBox
    local scroll = CreateFrame("ScrollFrame", nil, d, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", d, "TOPLEFT", 20, -65)
    scroll:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", -38, 50)

    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetWidth(450)
    scroll:SetScrollChild(editBox)

    -- Fill with current profile export
    local currentProfile = RF:GetActiveProfile()
    local exportStr = RF:ExportProfileToString(currentProfile)
    editBox:SetText(exportStr)
    editBox:HighlightText()

    -- Import Button
    local importBtn = CreateFrame("Button", nil, d, "UIPanelButtonTemplate")
    importBtn:SetSize(140, 24)
    importBtn:SetPoint("BOTTOMLEFT", d, "BOTTOMLEFT", 20, 15)
    importBtn:SetText(L["PROFILE_IMPORT_BTN"])
    importBtn:SetScript("OnClick", function()
        local text = editBox:GetText()
        local imported = RF:ImportProfileFromString(text)
        if imported and imported.macros then
            local profile = RF:GetActiveProfile()
            profile.macros = imported.macros
            RF:SyncAllMacros(false)
            RF:UpdateUI()
            print(string.format(L["PROFILE_IMPORT_SUCCESS"], #imported.macros))
            d:Hide()
        else
            print(L["PROFILE_IMPORT_INVALID"])
        end
    end)

    -- Close Button
    local closeBtn = CreateFrame("Button", nil, d, "UIPanelButtonTemplate")
    closeBtn:SetSize(100, 24)
    closeBtn:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", -20, 15)
    closeBtn:SetText(L["PRESETS_CLOSE"])
    closeBtn:SetScript("OnClick", function() d:Hide() end)

    RF.ImportExportDialog = d
    d:Show()
end

--------------------------------------------------------------------------------
-- Spell Search / Picker Popup Frame
--------------------------------------------------------------------------------
function RF:OpenSpellPicker(anchorEditBox, onSelectCallback)
    if not anchorEditBox then return end

    if not RF.SpellPickerFrame then
        local p = CreateFrame("Frame", "RankForgeSpellPickerFrame", UIParent, "BackdropTemplate")
        p:SetSize(240, 260)
        p:SetFrameStrata("FULLSCREEN_DIALOG")
        p:SetFrameLevel(600)
        p:SetToplevel(true)
        p:EnableMouse(true)

        p:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        p:SetBackdropColor(0.04, 0.04, 0.07, 1.0)

        local bgTex = p:CreateTexture(nil, "BACKGROUND", nil, -5)
        bgTex:SetPoint("TOPLEFT", p, "TOPLEFT", 4, -4)
        bgTex:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -4, 4)
        bgTex:SetColorTexture(0.05, 0.05, 0.08, 1.0)

        local title = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        title:SetPoint("TOPLEFT", p, "TOPLEFT", 10, -8)
        title:SetText("Zauber auswählen:")

        local closeBtn = CreateFrame("Button", nil, p, "UIPanelCloseButton")
        closeBtn:SetSize(20, 20)
        closeBtn:SetPoint("TOPRIGHT", p, "TOPRIGHT", -2, -2)
        closeBtn:SetScript("OnClick", function() p:Hide() end)

        -- Filter input box
        local filterEdit = CreateFrame("EditBox", nil, p, "InputBoxTemplate")
        filterEdit:SetSize(210, 18)
        filterEdit:SetPoint("TOPLEFT", p, "TOPLEFT", 12, -28)
        filterEdit:SetAutoFocus(false)
        p.filterEdit = filterEdit

        -- Scroll list
        local scroll = CreateFrame("ScrollFrame", "RankForgeSpellPickerScroll", p, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", p, "TOPLEFT", 10, -52)
        scroll:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -26, 8)

        local content = CreateFrame("Frame", nil, scroll)
        content:SetSize(200, 10)
        scroll:SetScrollChild(content)
        p.content = content
        p.buttons = {}

        filterEdit:SetScript("OnTextChanged", function(self)
            RF:RefreshSpellPickerList()
        end)
        filterEdit:SetScript("OnEnterPressed", function(self)
            local spells = p.filteredSpells or {}
            local query = self:GetText():lower():trim()
            if #spells == 1 then
                if p.currentCallback then
                    p.currentCallback(spells[1].name)
                end
                p:Hide()
            elseif #spells > 1 then
                for _, sp in ipairs(spells) do
                    if sp.name:lower() == query then
                        if p.currentCallback then
                            p.currentCallback(sp.name)
                        end
                        p:Hide()
                        return
                    end
                end
                if p.currentCallback then
                    p.currentCallback(spells[1].name)
                end
                p:Hide()
            end
        end)
        filterEdit:SetScript("OnEscapePressed", function(self)
            p:Hide()
        end)

        RF.SpellPickerFrame = p
    end

    local p = RF.SpellPickerFrame
    p.currentCallback = onSelectCallback
    p.anchorEditBox = anchorEditBox

    -- Anchor popup directly below the edit box
    p:ClearAllPoints()
    p:SetPoint("TOPLEFT", anchorEditBox, "BOTTOMLEFT", -24, -2)

    -- Pre-fill search filter from anchor EditBox text if present
    local existingText = anchorEditBox:GetText() or ""
    p.filterEdit:SetText(existingText)

    RF:RefreshSpellPickerList()
    p:Show()
    p.filterEdit:SetFocus()
end

function RF:RefreshSpellPickerList()
    local p = RF.SpellPickerFrame
    if not p or not p:IsShown() then return end

    local filter = p.filterEdit:GetText():lower():trim()
    local spells = RF:GetLearnedSpellList()
    local content = p.content
    local buttons = p.buttons
    p.filteredSpells = {}

    for _, btn in ipairs(buttons) do
        btn:Hide()
    end

    local y = 0
    local count = 0
    for _, sp in ipairs(spells) do
        if filter == "" or sp.name:lower():find(filter, 1, true) then
            count = count + 1
            table.insert(p.filteredSpells, sp)
            local btn = buttons[count]
            if not btn then
                btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
                btn:SetSize(195, 22)

                local icon = btn:CreateTexture(nil, "ARTWORK")
                icon:SetSize(16, 16)
                icon:SetPoint("LEFT", btn, "LEFT", 4, 0)
                btn.icon = icon

                local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                text:SetPoint("LEFT", icon, "RIGHT", 4, 0)
                text:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
                text:SetJustifyH("LEFT")
                btn.text = text

                buttons[count] = btn
            end

            btn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
            local tex = (sp.spellID and GetSpellTexture(sp.spellID)) or GetSpellTexture(sp.name) or "Interface\\Icons\\INV_Misc_QuestionMark"
            btn.icon:SetTexture(tex)
            btn.text:SetText(sp.name)
            btn:Show()

            local spellName = sp.name
            btn:SetScript("OnClick", function()
                if p.currentCallback then
                    p.currentCallback(spellName)
                end
                p:Hide()
            end)

            y = y + 24
        end
    end

    content:SetHeight(math.max(y, 10))
end

--------------------------------------------------------------------------------
-- Minimap Button
--------------------------------------------------------------------------------
function RF:InitMinimapButton()
    if RF.MinimapButton then return end

    local btn = CreateFrame("Button", "RankForgeMinimapButton", Minimap)
    btn:SetSize(32, 32)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:EnableMouse(true)
    btn:SetMovable(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture("Interface\\Icons\\Spell_Holy_Renew")
    btn.icon = icon

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    local function UpdatePosition(angle)
        local rad = math.rad(angle or 215)
        local radius = 80
        if Minimap and Minimap.GetWidth then
            radius = (Minimap:GetWidth() / 2) + 10
        end
        local x = math.cos(rad) * radius
        local y = math.sin(rad) * radius
        btn:ClearAllPoints()
        btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end

    btn:SetScript("OnDragStart", function(self)
        self.isDragging = true
        self:SetScript("OnUpdate", function(self)
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale
            local angle = math.deg(math.atan2(cy - my, cx - mx))
            if angle < 0 then angle = angle + 360 end
            if RankForgeDB then
                RankForgeDB.minimapPos = angle
            end
            UpdatePosition(angle)
        end)
    end)

    btn:SetScript("OnDragStop", function(self)
        self.isDragging = false
        self:SetScript("OnUpdate", nil)
    end)

    btn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            RF:ToggleUI()
        elseif button == "RightButton" then
            RF:SyncAllMacros(false)
        end
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(L["MINIMAP_TOOLTIP_TITLE"])
        GameTooltip:AddLine(L["MINIMAP_TOOLTIP_L1"], 1, 1, 1)
        GameTooltip:AddLine(L["MINIMAP_TOOLTIP_L2"], 0.9, 0.9, 0.2)
        GameTooltip:AddLine(L["MINIMAP_TOOLTIP_DRAG"], 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    local initialAngle = (RankForgeDB and RankForgeDB.minimapPos) or 215
    UpdatePosition(initialAngle)
    btn:Show()

    RF.MinimapButton = btn
end
