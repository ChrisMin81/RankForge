--[[
    RankForge - UI.lua
    User Interface: Macro list, editor, live preview, action-bar drag, presets, and Base64 import/export.
]]

local addonName, RF = ...
local L = RF.L

local currentMacro = nil
local selectedMacroIndex = 1

function RF:GetSelectedMacroButton()
    if not RF.MainFrame or not RF.MainFrame.listContent or not RF.MainFrame.listContent.buttons then return nil end
    for _, btn in ipairs(RF.MainFrame.listContent.buttons) do
        if btn:IsShown() and btn.macroIndex == selectedMacroIndex then
            return btn
        end
    end
    return nil
end

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
-- Modern Dark-Theme Styling Helpers
--------------------------------------------------------------------------------
local BACKDROP_SOLID = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 0, edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
}

local BACKDROP_FRAME = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 0, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
}

local function ApplyModernCardStyle(frame, bgColor, borderColor)
    if not frame or not frame.SetBackdrop then return end
    frame:SetBackdrop(BACKDROP_FRAME)
    local bg = bgColor or { 0.05, 0.06, 0.08, 0.88 }
    local border = borderColor or { 0.18, 0.22, 0.32, 0.85 }
    if frame.SetBackdropColor then
        frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
    end
    if frame.SetBackdropBorderColor then
        frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4])
    end
end

local function ApplyModernButtonStyle(btn, theme, fontObject)
    if not btn then return end
    if btn.SetBackdrop then
        btn:SetBackdrop(BACKDROP_SOLID)
    end

    local font = fontObject or "GameFontHighlight"
    if btn.SetNormalFontObject then btn:SetNormalFontObject(font) end
    if btn.SetHighlightFontObject then btn:SetHighlightFontObject(font) end
    if btn.SetDisabledFontObject then btn:SetDisabledFontObject("GameFontDisable") end

    -- Ensure a valid FontString exists on the button
    local fs = btn.GetFontString and btn:GetFontString()
    if not fs and btn.CreateFontString then
        fs = btn:CreateFontString(nil, "OVERLAY", font)
        fs:SetPoint("CENTER", btn, "CENTER", 0, 0)
        if btn.SetFontString then
            btn:SetFontString(fs)
        end
    end
    if fs then
        fs:SetFontObject(font)
        if fs.SetDrawLayer then fs:SetDrawLayer("OVERLAY", 7) end
        fs:ClearAllPoints()
        fs:SetPoint("CENTER", btn, "CENTER", 0, 0)
        if fs.SetTextColor then fs:SetTextColor(1, 1, 1, 1) end
        fs:Show()
    end

    -- Hook SetText so that calling btn:SetText(...) ALWAYS sets the text on fs and makes it visible
    if not btn._rfSetTextHooked then
        btn._rfSetTextHooked = true
        local origSetText = btn.SetText
        btn.SetText = function(self, txt)
            if origSetText then origSetText(self, txt) end
            local s = self.GetFontString and self:GetFontString()
            if s and s.SetText then
                s:SetText(txt or "")
                s:Show()
            end
        end
    end

    -- If the button already had text (e.g. from XML or earlier SetText), ensure fs displays it
    local currentText = btn.GetText and btn:GetText()
    if currentText and currentText ~= "" and fs and fs.SetText then
        fs:SetText(currentText)
        fs:Show()
    end

    -- Hide native Blizzard button border textures if present
    if btn.GetNormalTexture and btn:GetNormalTexture() then btn:GetNormalTexture():SetAlpha(0) end
    if btn.GetHighlightTexture and btn:GetHighlightTexture() then btn:GetHighlightTexture():SetAlpha(0) end
    if btn.GetPushedTexture and btn:GetPushedTexture() then btn:GetPushedTexture():SetAlpha(0) end
    if btn.GetDisabledTexture and btn:GetDisabledTexture() then btn:GetDisabledTexture():SetAlpha(0) end

    local normalBg, hoverBg, pressBg, borderColor
    if theme == "primary" or theme == "green" then
        normalBg    = { 0.10, 0.35, 0.20, 0.95 }
        hoverBg     = { 0.15, 0.50, 0.28, 1.00 }
        pressBg     = { 0.08, 0.26, 0.15, 1.00 }
        borderColor = { 0.28, 0.80, 0.45, 0.95 }
    elseif theme == "danger" or theme == "red" then
        normalBg    = { 0.42, 0.12, 0.15, 0.95 }
        hoverBg     = { 0.58, 0.16, 0.20, 1.00 }
        pressBg     = { 0.30, 0.08, 0.10, 1.00 }
        borderColor = { 0.85, 0.25, 0.30, 0.95 }
    elseif theme == "blue" then
        normalBg    = { 0.12, 0.26, 0.48, 0.95 }
        hoverBg     = { 0.18, 0.38, 0.65, 1.00 }
        pressBg     = { 0.09, 0.20, 0.38, 1.00 }
        borderColor = { 0.30, 0.62, 0.95, 0.95 }
    elseif theme == "gold" then
        normalBg    = { 0.38, 0.30, 0.10, 0.95 }
        hoverBg     = { 0.52, 0.42, 0.14, 1.00 }
        pressBg     = { 0.28, 0.22, 0.08, 1.00 }
        borderColor = { 0.95, 0.80, 0.25, 0.95 }
    else -- neutral / slate
        normalBg    = { 0.12, 0.14, 0.20, 0.95 }
        hoverBg     = { 0.18, 0.22, 0.32, 1.00 }
        pressBg     = { 0.08, 0.10, 0.14, 1.00 }
        borderColor = { 0.25, 0.32, 0.45, 0.85 }
    end

    if btn.SetBackdropColor then
        btn:SetBackdropColor(normalBg[1], normalBg[2], normalBg[3], normalBg[4])
    end
    if btn.SetBackdropBorderColor then
        btn:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    end

    if btn.HookScript then
        btn:HookScript("OnEnter", function(self)
            if not self.IsEnabled or self:IsEnabled() then
                if self.SetBackdropColor then self:SetBackdropColor(hoverBg[1], hoverBg[2], hoverBg[3], hoverBg[4]) end
                local s = self.GetFontString and self:GetFontString()
                if s and s.SetTextColor then s:SetTextColor(1, 1, 1, 1) end
            end
        end)
        btn:HookScript("OnLeave", function(self)
            if self.SetBackdropColor then self:SetBackdropColor(normalBg[1], normalBg[2], normalBg[3], normalBg[4]) end
            local s = self.GetFontString and self:GetFontString()
            if s and s.SetTextColor then s:SetTextColor(0.92, 0.92, 0.95, 1) end
        end)
        btn:HookScript("OnMouseDown", function(self)
            if not self.IsEnabled or self:IsEnabled() then
                if self.SetBackdropColor then self:SetBackdropColor(pressBg[1], pressBg[2], pressBg[3], pressBg[4]) end
            end
        end)
        btn:HookScript("OnMouseUp", function(self)
            if not self.IsEnabled or self:IsEnabled() then
                if self.SetBackdropColor then self:SetBackdropColor(hoverBg[1], hoverBg[2], hoverBg[3], hoverBg[4]) end
            end
        end)
    end
end

local function CreateModernButton(parent, width, height, text, theme, fontObject)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    if width and height then
        btn:SetSize(width, height)
    end
    ApplyModernButtonStyle(btn, theme, fontObject)
    if text then
        btn:SetText(text)
    end
    return btn
end

local function ApplyModernEditBoxStyle(editbox)
    if not editbox or not editbox.SetBackdrop then return end
    editbox:SetBackdrop(BACKDROP_FRAME)
    if editbox.SetBackdropColor then
        editbox:SetBackdropColor(0.04, 0.05, 0.08, 0.95)
    end
    if editbox.SetBackdropBorderColor then
        editbox:SetBackdropBorderColor(0.20, 0.26, 0.38, 0.85)
    end
    if editbox.HookScript then
        editbox:HookScript("OnEditFocusGained", function(self)
            if self.SetBackdropBorderColor then self:SetBackdropBorderColor(0.40, 0.65, 0.95, 1.0) end
        end)
        editbox:HookScript("OnEditFocusLost", function(self)
            if self.SetBackdropBorderColor then self:SetBackdropBorderColor(0.20, 0.26, 0.38, 0.85) end
        end)
    end
end

--------------------------------------------------------------------------------
-- Main Frame Creation
--------------------------------------------------------------------------------
local function CreateMainUI()
    if RF.MainFrame then return RF.MainFrame end

    local f = CreateFrame("Frame", "RankForgeMainFrame", UIParent, "BackdropTemplate")
    f:Hide() -- Hidden by default on start / reload
    f:SetSize(1040, 720)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    f:SetClampedToScreen(true)
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)

    if UISpecialFrames then
        local found = false
        for _, name in ipairs(UISpecialFrames) do
            if name == "RankForgeMainFrame" then found = true break end
        end
        if not found then
            table.insert(UISpecialFrames, "RankForgeMainFrame")
        end
    end

    -- Modern Outer Backdrop (Deep Obsidian with Champagne Gold Accent Border)
    f:SetBackdrop(BACKDROP_FRAME)
    f:SetBackdropColor(0.04, 0.05, 0.07, 0.98)
    f:SetBackdropBorderColor(0.68, 0.55, 0.26, 0.90)

    -- Modern Top Header Bar (36px high)
    local headerBar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    headerBar:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    headerBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    headerBar:SetHeight(38)
    headerBar:SetBackdrop(BACKDROP_SOLID)
    headerBar:SetBackdropColor(0.07, 0.09, 0.13, 0.98)
    headerBar:SetBackdropBorderColor(0.18, 0.22, 0.32, 0.85)
    f.headerBar = headerBar

    -- Header Icon
    local headerIcon = headerBar:CreateTexture(nil, "ARTWORK")
    headerIcon:SetSize(22, 22)
    headerIcon:SetPoint("LEFT", headerBar, "LEFT", 12, 0)
    headerIcon:SetTexture("Interface\\Icons\\INV_Hammer_01")
    headerIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local title = headerBar:CreateFontString(nil, "OVERLAY", "GameFontNormalMed2")
    title:SetPoint("LEFT", headerIcon, "RIGHT", 10, 0)
    title:SetText("|cffffd200RankForge|r  |cff557799•|r  |cffffffff" .. (L["UI_TITLE"] or "Downranking Makro Schmiede") .. "|r")
    f.title = title

    -- Modern Close Button
    local closeBtn = CreateFrame("Button", nil, headerBar, "BackdropTemplate")
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("RIGHT", headerBar, "RIGHT", -8, 0)
    local closeFs = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
    closeFs:SetPoint("CENTER", 0, 0)
    closeFs:SetText("|cffff5555×|r")
    closeBtn.fs = closeFs
    ApplyModernButtonStyle(closeBtn, "danger")
    closeBtn:SetScript("OnClick", function()
        f:Hide()
    end)

    -- Language Selection Dropdown
    local langDropdown = CreateFrame("Frame", "RankForgeLanguageDropdown", headerBar, "UIDropDownMenuTemplate")
    langDropdown:SetPoint("RIGHT", closeBtn, "LEFT", 15, -2)
    UIDropDownMenu_SetWidth(langDropdown, 105)

    -- Debug Mode Checkbox (Auto-Open on reload)
    local cbDebug = CreateFrame("CheckButton", nil, headerBar, "UICheckButtonTemplate")
    cbDebug:SetSize(18, 18)
    cbDebug:SetPoint("RIGHT", langDropdown, "LEFT", -110, 2)
    local debugText = cbDebug:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    debugText:SetPoint("LEFT", cbDebug, "RIGHT", 2, 0)
    debugText:SetText(L["UI_DEBUG_AUTO_OPEN"] or "Debug (Auto-Open)")
    cbDebug.text = debugText
    cbDebug:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(L["UI_DEBUG_AUTO_OPEN"] or "Debug-Modus", 1, 1, 1)
        GameTooltip:AddLine(L["UI_DEBUG_AUTO_OPEN_TOOLTIP"] or "Öffnet das RankForge-Fenster nach jedem /reload automatisch.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    cbDebug:SetScript("OnLeave", function() GameTooltip:Hide() end)
    cbDebug:SetScript("OnClick", function(self)
        if RankForgeDB then
            RankForgeDB.debugMode = self:GetChecked()
        end
    end)
    f.cbDebug = cbDebug

    local function LanguageDropdown_OnClick(btn)
        local val = btn.value
        UIDropDownMenu_SetSelectedValue(langDropdown, val)
        if RankForgeDB then
            RankForgeDB.locale = val
        end
        RF:SetLocale(val)
        RF:RefreshUILabels()
        RF:UpdateUI()
        CloseDropDownMenus()
    end

    local function LanguageDropdown_Initialize()
        local cur = (RankForgeDB and RankForgeDB.locale) or "auto"
        local info = UIDropDownMenu_CreateInfo()

        info.text = L["UI_LANG_AUTO"] or "Auto (Client)"
        info.value = "auto"
        info.func = LanguageDropdown_OnClick
        info.checked = (cur == "auto")
        UIDropDownMenu_AddButton(info)

        info.text = L["UI_LANG_EN"] or "English"
        info.value = "enUS"
        info.func = LanguageDropdown_OnClick
        info.checked = (cur == "enUS")
        UIDropDownMenu_AddButton(info)

        info.text = L["UI_LANG_DE"] or "Deutsch"
        info.value = "deDE"
        info.func = LanguageDropdown_OnClick
        info.checked = (cur == "deDE")
        UIDropDownMenu_AddButton(info)
    end

    UIDropDownMenu_Initialize(langDropdown, LanguageDropdown_Initialize)
    local cur = (RankForgeDB and RankForgeDB.locale) or "auto"
    local curText = L["UI_LANG_AUTO"] or "Auto (Client)"
    if cur == "enUS" then curText = L["UI_LANG_EN"] elseif cur == "deDE" then curText = L["UI_LANG_DE"] end
    UIDropDownMenu_SetText(langDropdown, curText)
    f.langDropdown = langDropdown

    ----------------------------------------------------------------------------
    -- Left Panel: Macro List Card
    ----------------------------------------------------------------------------
    local leftPanel = CreateFrame("Frame", nil, f, "BackdropTemplate")
    leftPanel:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -48)
    leftPanel:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12, 12)
    leftPanel:SetWidth(225)
    ApplyModernCardStyle(leftPanel, { 0.05, 0.06, 0.09, 0.92 }, { 0.16, 0.20, 0.28, 0.85 })

    local listHeader = leftPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
    listHeader:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 12, -10)
    listHeader:SetText(L["UI_CONFIGURED_MACROS"])
    f.listHeader = listHeader

    -- Filter Current Character Checkbox
    local filterCharCb = CreateFrame("CheckButton", nil, leftPanel, "UICheckButtonTemplate")
    filterCharCb:SetSize(18, 18)
    filterCharCb:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 10, -28)
    local filterText = filterCharCb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    filterText:SetPoint("LEFT", filterCharCb, "RIGHT", 4, 0)
    filterText:SetText(L["UI_FILTER_CURRENT_CHAR"] or "Nur dieser Charakter")
    filterCharCb.text = filterText
    filterCharCb:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(L["UI_FILTER_CURRENT_CHAR"] or "Nur dieser Charakter", 1, 1, 1)
        GameTooltip:AddLine(L["UI_FILTER_CURRENT_CHAR_TOOLTIP"] or "Filtert die Liste, um nur Makros für diesen Charakter bzw. diese Klasse anzuzeigen. Deaktivieren, um alle Makros zu sehen.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    filterCharCb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    filterCharCb:SetScript("OnClick", function(self)
        if RankForgeCharDB then
            RankForgeCharDB.filterCurrentCharOnly = self:GetChecked()
        end
        RF:UpdateUI()
    end)
    f.filterCharCb = filterCharCb

    -- Macro Scroll Frame
    local scrollFrame = CreateFrame("ScrollFrame", "RankForgeMacroListScroll", leftPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 8, -52)
    scrollFrame:SetPoint("BOTTOMRIGHT", leftPanel, "BOTTOMRIGHT", -26, 115)

    local listContent = CreateFrame("Frame", nil, scrollFrame)
    listContent:SetSize(188, 10)
    scrollFrame:SetScrollChild(listContent)
    f.listContent = listContent

    -- Buttons on Left Panel
    local newBtn = CreateModernButton(leftPanel, 205, 24, "+ " .. L["UI_NEW_MACRO"], "blue")
    newBtn:SetPoint("BOTTOM", leftPanel, "BOTTOM", 0, 75)
    newBtn:SetScript("OnClick", function()
        RF:CreateNewMacroConfig()
    end)
    f.newBtn = newBtn

    local cloneBtn = CreateModernButton(leftPanel, 205, 24, L["UI_CLONE_BTN"], "slate")
    cloneBtn:SetPoint("BOTTOM", leftPanel, "BOTTOM", 0, 45)
    cloneBtn:SetScript("OnClick", function()
        if currentMacro then
            local cloned = RF:CloneMacro(currentMacro)
            if cloned then
                local macros = RF:GetMacrosList()
                selectedMacroIndex = #macros
                RF:SyncMacro(cloned, true)
                RF:UpdateUI()
                RF:LoadMacroIntoEditor(cloned)
                local msg = L["MACRO_CLONED_SUCCESS"] or "|cff00ccffRankForge:|r Macro duplicated: '|cffffd200%s|r'."
                print(string.format(msg, cloned.macroName))
            end
        end
    end)
    f.cloneBtn = cloneBtn

    local exportBtn = CreateModernButton(leftPanel, 205, 24, L["UI_EXPORT_BTN"], "slate")
    exportBtn:SetPoint("BOTTOM", leftPanel, "BOTTOM", 0, 15)
    exportBtn:SetScript("OnClick", function()
        RF:OpenImportExportDialog()
    end)
    f.exportBtn = exportBtn

    -- Slot status text
    local slotStatus = leftPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    slotStatus:SetPoint("BOTTOMLEFT", leftPanel, "BOTTOMLEFT", 12, 104)
    f.slotStatus = slotStatus

    ----------------------------------------------------------------------------
    -- Right Panel: Macro Editor Card
    ----------------------------------------------------------------------------
    local editor = CreateFrame("Frame", nil, f, "BackdropTemplate")
    editor:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", 10, 0)
    editor:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 12)
    ApplyModernCardStyle(editor, { 0.05, 0.06, 0.09, 0.92 }, { 0.16, 0.20, 0.28, 0.85 })
    f.editor = editor

    -- Macro Name Input
    local nameLabel = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameLabel:SetPoint("TOPLEFT", editor, "TOPLEFT", 15, -15)
    nameLabel:SetText(L["UI_MACRO_NAME"])
    f.nameLabel = nameLabel

    local nameEdit = CreateFrame("EditBox", nil, editor, "BackdropTemplate")
    nameEdit:SetSize(160, 22)
    nameEdit:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
    nameEdit:SetAutoFocus(false)
    nameEdit:SetFontObject("GameFontHighlightSmall")
    nameEdit:SetTextInsets(6, 6, 0, 0)
    ApplyModernEditBoxStyle(nameEdit)
    nameEdit:SetScript("OnTextChanged", function(self, userInput)
        if userInput and currentMacro then
            currentMacro.macroName = self:GetText()
            RF:UpdatePreview()
            local b = RF:GetSelectedMacroButton()
            if b then
                RF:UpdateMacroListItem(b, currentMacro, selectedMacroIndex)
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
        local isAcc = (currentMacro and currentMacro.isAccount == true)
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
    f.spellLabel = spellLabel

    -- Drag & Drop Spell Button Slot
    local dropSlot = CreateFrame("Button", nil, editor, "BackdropTemplate")
    dropSlot:SetSize(36, 36)
    dropSlot:SetPoint("LEFT", spellLabel, "RIGHT", 10, 0)
    dropSlot:SetBackdrop(BACKDROP_FRAME)
    if dropSlot.SetBackdropColor then
        dropSlot:SetBackdropColor(0.08, 0.10, 0.15, 0.95)
    end
    if dropSlot.SetBackdropBorderColor then
        dropSlot:SetBackdropBorderColor(0.28, 0.45, 0.70, 0.90)
    end
    if dropSlot.HookScript then
        dropSlot:HookScript("OnEnter", function(self)
            if self.SetBackdropBorderColor then self:SetBackdropBorderColor(0.85, 0.70, 0.25, 1.0) end
        end)
        dropSlot:HookScript("OnLeave", function(self)
            if self.SetBackdropBorderColor then self:SetBackdropBorderColor(0.28, 0.45, 0.70, 0.90) end
        end)
    end

    local dropSlotIcon = dropSlot:CreateTexture(nil, "ARTWORK")
    dropSlotIcon:SetPoint("TOPLEFT", dropSlot, "TOPLEFT", 2, -2)
    dropSlotIcon:SetPoint("BOTTOMRIGHT", dropSlot, "BOTTOMRIGHT", -2, 2)
    dropSlotIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    dropSlotIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    dropSlot.icon = dropSlotIcon

    local function ApplyBaseSpell(spellName)
        if not spellName or spellName == "" or not currentMacro then return end
        currentMacro.spellName = spellName
        currentMacro.spellID = RF:ResolveSpellID(spellName)
        if currentMacro.macroName == "" or currentMacro.macroName:match("^DR_") then
            currentMacro.macroName = "DR_" .. spellName:gsub("%s+", "")
        end
        RF:AutoConfigureSpellType(currentMacro, spellName)
        RF:LoadMacroIntoEditor(currentMacro)
    end

    local function HandleBaseSpellDrop()
        local spellName = RF:GetSpellFromCursor()
        if spellName then
            ApplyBaseSpell(spellName)
            return true
        end
        return false
    end

    -- Handle Drag & Drop spell onto drop slot
    dropSlot:SetScript("OnReceiveDrag", HandleBaseSpellDrop)
    dropSlot:SetScript("OnClick", function(self)
        if not HandleBaseSpellDrop() then
            RF:OpenSpellPicker(f.spellEdit, ApplyBaseSpell)
        end
    end)
    f.dropSlot = dropSlot

    -- Clickable and drop-friendly label next to drop slot
    local dropSlotBtn = CreateFrame("Button", nil, editor)
    dropSlotBtn:SetPoint("LEFT", dropSlot, "RIGHT", 4, 0)
    dropSlotBtn:SetSize(130, 26)
    dropSlotBtn:SetScript("OnReceiveDrag", HandleBaseSpellDrop)
    dropSlotBtn:SetScript("OnClick", function(self)
        if not HandleBaseSpellDrop() then
            RF:OpenSpellPicker(f.spellEdit, ApplyBaseSpell)
        end
    end)
    local dropSlotText = dropSlotBtn:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    dropSlotText:SetPoint("LEFT", dropSlotBtn, "LEFT", 4, 0)
    dropSlotText:SetText(L["UI_DROP_SPELL_HERE"])
    f.dropSlotText = dropSlotText
    f.dropSlotBtn = dropSlotBtn

    -- Spell Name Manual Input
    local spellEdit = CreateFrame("EditBox", nil, editor, "BackdropTemplate")
    spellEdit:SetSize(140, 22)
    spellEdit:SetPoint("LEFT", dropSlotBtn, "RIGHT", 10, 0)
    spellEdit:SetAutoFocus(false)
    spellEdit:SetFontObject("GameFontHighlightSmall")
    if spellEdit.SetTextInsets then spellEdit:SetTextInsets(6, 6, 0, 0) end
    ApplyModernEditBoxStyle(spellEdit)
    spellEdit:SetScript("OnReceiveDrag", HandleBaseSpellDrop)
    spellEdit:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            local infoType = GetCursorInfo and GetCursorInfo()
            if infoType == "spell" or infoType == "action" then
                if HandleBaseSpellDrop() then
                    self:ClearFocus()
                    return
                end
            end
        end
    end)
    spellEdit:SetScript("OnTextChanged", function(self, userInput)
        if userInput and currentMacro then
            currentMacro.spellName = self:GetText()
            RF:UpdatePreview()
            local b = RF:GetSelectedMacroButton()
            if b then
                RF:UpdateMacroListItem(b, currentMacro, selectedMacroIndex)
            end
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
                currentMacro.spellID = RF:ResolveSpellID(chosen)
                if currentMacro.macroName == "" or currentMacro.macroName:match("^DR_") then
                    currentMacro.macroName = "DR_" .. chosen:gsub("%s+", "")
                end
                RF:AutoConfigureSpellType(currentMacro, chosen)
                RF:LoadMacroIntoEditor(currentMacro)
            end
        end
        self:ClearFocus()
    end)
    spellEdit:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    f.spellEdit = spellEdit

    -- Omit Rank Checkbox (for spells like Power Word: Shield, buffs, or max-rank casting)
    local cbNoRank = CreateFrame("CheckButton", nil, editor, "UICheckButtonTemplate")
    cbNoRank:SetPoint("LEFT", spellEdit, "RIGHT", 14, 0)
    cbNoRank.text = cbNoRank:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cbNoRank.text:SetPoint("LEFT", cbNoRank, "RIGHT", 2, 0)
    cbNoRank.text:SetText(L["UI_OMIT_RANK"] or "Ohne Rang casten")
    cbNoRank:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["UI_OMIT_RANK_TITLE"] or "Ohne Rang casten (Höchstrang)", 1, 0.82, 0)
        GameTooltip:AddLine(L["UI_OMIT_RANK_DESC"] or "Lässt die Rangangabe '(Rang X)' im Makro weg. WoW zaubert dadurch automatisch immer den höchsten erlernten Rang. Ideal für Machtwort: Schild, Buffs oder wenn kein Downranking gewünscht ist.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    cbNoRank:SetScript("OnLeave", function() GameTooltip:Hide() end)
    cbNoRank:SetScript("OnClick", function(self)
        if currentMacro then
            currentMacro.omitRank = self:GetChecked()
            RF:LoadModifiersIntoUI(currentMacro)
            RF:UpdatePreview()
        end
    end)
    f.cbNoRank = cbNoRank

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
    local function CreateTargetCheck(text, x, y, key, tooltipTitle, tooltipDesc)
        local cb = CreateFrame("CheckButton", nil, editor, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", editor, "TOPLEFT", x, y)
        cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        cb.text:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        cb.text:SetText(text)
        if tooltipTitle then
            cb:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText(tooltipTitle, 1, 0.82, 0)
                if tooltipDesc then GameTooltip:AddLine(tooltipDesc, 0.8, 0.8, 0.8, true) end
                GameTooltip:Show()
            end)
            cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
        cb:SetScript("OnClick", function(self)
            if currentMacro then
                currentMacro[key] = self:GetChecked()
                RF:UpdatePreview()
            end
        end)
        return cb
    end

    f.cbStartAttack = CreateTargetCheck(L["UI_START_ATTACK"] or "Start Attack (/startattack)", 220, -90, "startAttack", "/startattack", L["UI_START_ATTACK_DESC"])
    f.cbPetAttack   = CreateTargetCheck(L["UI_PET_ATTACK"] or "Pet Attack (/petattack)", 440, -90, "petAttack", "/petattack", L["UI_PET_ATTACK_DESC"])

    f.cbTrinket1  = CreateTargetCheck(L["UI_USE_TRINKET_1"], 15, -114, "useTrinket1")
    f.cbTrinket2  = CreateTargetCheck(L["UI_USE_TRINKET_2"], 175, -114, "useTrinket2")
    f.cbRacial    = CreateTargetCheck(L["UI_USE_RACIAL"], 345, -114, "useRacial")

    -- Pre-Cast Extra Commands Input (Potions, additional spells, /click, etc.)
    local preCastLabel = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    preCastLabel:SetPoint("TOPLEFT", editor, "TOPLEFT", 15, -138)
    preCastLabel:SetText(L["UI_PRECAST_CUSTOM"])
    f.preCastHeader = preCastLabel

    local preCastEdit = CreateFrame("EditBox", nil, editor, "BackdropTemplate")
    preCastEdit:SetPoint("TOPLEFT", editor, "TOPLEFT", 18, -154)
    preCastEdit:SetPoint("RIGHT", editor, "RIGHT", -25, 0)
    preCastEdit:SetHeight(22)
    preCastEdit:SetAutoFocus(false)
    preCastEdit:SetFontObject("GameFontHighlightSmall")
    if preCastEdit.SetTextInsets then preCastEdit:SetTextInsets(6, 6, 0, 0) end
    ApplyModernEditBoxStyle(preCastEdit)
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
    f.customTargetHeader = customTargetLabel

    local customTargetEdit = CreateFrame("EditBox", nil, editor, "BackdropTemplate")
    customTargetEdit:SetPoint("LEFT", customTargetLabel, "RIGHT", 10, 0)
    customTargetEdit:SetPoint("RIGHT", editor, "RIGHT", -25, 0)
    customTargetEdit:SetHeight(22)
    customTargetEdit:SetAutoFocus(false)
    customTargetEdit:SetFontObject("GameFontHighlightSmall")
    if customTargetEdit.SetTextInsets then customTargetEdit:SetTextInsets(6, 6, 0, 0) end
    ApplyModernEditBoxStyle(customTargetEdit)
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
    f.modifiersHeader = modHeader

    local resetSortBtn = CreateModernButton(editor, 140, 20, L["UI_RESET_SORT_BTN"], "slate", "GameFontHighlightSmall")
    resetSortBtn:SetPoint("LEFT", modHeader, "RIGHT", 10, 0)
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

    -- Column Headers for the Matrix Grid with Toggle-All capability
    local gridHeader = CreateFrame("Frame", nil, editor)
    gridHeader:SetSize(755, 16)
    gridHeader:SetPoint("TOPLEFT", editor, "TOPLEFT", 15, -232)

    local function ToggleAllModifiersField(field, mutuallyExclude)
        if not currentMacro or not currentMacro.modifiers then return end
        local allTrue = true
        for _, mod in ipairs(currentMacro.modifiers) do
            if not mod[field] then
                allTrue = false
                break
            end
        end
        local targetVal = not allTrue
        for _, mod in ipairs(currentMacro.modifiers) do
            mod[field] = targetVal
            if targetVal and mutuallyExclude then
                for _, exField in ipairs(mutuallyExclude) do
                    mod[exField] = false
                end
            end
        end
        RF:LoadModifiersIntoUI(currentMacro)
        RF:UpdatePreview()
    end

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
                if tooltipDesc and tooltipDesc ~= "" then GameTooltip:AddLine(tooltipDesc, 0.8, 0.8, 0.8, true) end
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
        return h
    end

    local function CreateToggleColHeader(x, text, tooltipTitle, tooltipDesc, onClick)
        local btn = CreateFrame("Button", nil, gridHeader)
        btn:SetPoint("LEFT", gridHeader, "LEFT", x, 0)
        btn:SetHeight(16)

        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        fs:SetPoint("LEFT", btn, "LEFT", 0, 0)
        fs:SetText(text)
        btn:SetWidth(fs:GetStringWidth() + 4)
        btn.fs = fs

        btn:SetScript("OnEnter", function(self)
            fs:SetTextColor(1, 0.82, 0) -- Highlight gold
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(tooltipTitle or text, 1, 1, 1)
            if tooltipDesc and tooltipDesc ~= "" then
                GameTooltip:AddLine(tooltipDesc, 0.8, 0.8, 0.8, true)
            end
            GameTooltip:AddLine(L["UI_TOGGLE_ALL_CLICK"] or "|cff00ff00[Click]|r Toggle all / none for this column", 0, 1, 0)
            GameTooltip:Show()
        end)

        btn:SetScript("OnLeave", function(self)
            fs:SetTextColor(0.6, 0.6, 0.6) -- Normal gray
            GameTooltip:Hide()
        end)

        if onClick then
            btn:SetScript("OnClick", function(self)
                pcall(PlaySound, SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
                onClick()
            end)
        end

        return btn
    end

    f.colHeaders = {}
    f.colHeaders.mod    = CreateColHeader(40,  L["UI_GRID_MOD"])
    f.colHeaders.rank   = CreateColHeader(168, L["UI_GRID_RANK"])
    f.colHeaders.mo     = CreateToggleColHeader(266, L["UI_GRID_MO"], L["UI_GRID_MO_TOOLTIP_TITLE"], L["UI_GRID_MO_TOOLTIP_DESC"], function()
        ToggleAllModifiersField("targetMouseover")
    end)
    f.colHeaders.target = CreateToggleColHeader(296, L["UI_GRID_TARGET"], L["UI_GRID_TARGET_TOOLTIP_TITLE"], L["UI_GRID_TARGET_TOOLTIP_DESC"], function()
        ToggleAllModifiersField("targetTarget")
    end)
    f.colHeaders.focus  = CreateToggleColHeader(326, L["UI_GRID_FOCUS"], L["UI_GRID_FOCUS_TOOLTIP_TITLE"], L["UI_GRID_FOCUS_TOOLTIP_DESC"], function()
        ToggleAllModifiersField("targetFocus")
    end)
    f.colHeaders.tot    = CreateToggleColHeader(356, L["UI_GRID_TOT"], L["UI_GRID_TOT_TOOLTIP_TITLE"], L["UI_GRID_TOT_TOOLTIP_DESC"], function()
        ToggleAllModifiersField("targetToT")
    end)
    f.colHeaders.self   = CreateToggleColHeader(386, L["UI_GRID_SELF"], L["UI_GRID_SELF_TOOLTIP_TITLE"], L["UI_GRID_SELF_TOOLTIP_DESC"], function()
        ToggleAllModifiersField("targetSelfcast")
    end)
    f.colHeaders.help   = CreateToggleColHeader(420, L["UI_COND_HELP"], L["UI_COND_HELP_TOOLTIP_TITLE"], L["UI_COND_HELP_TOOLTIP_DESC"], function()
        ToggleAllModifiersField("isHelp", {"isHarm"})
    end)
    f.colHeaders.harm   = CreateToggleColHeader(462, L["UI_COND_HARM"], L["UI_COND_HARM_TOOLTIP_TITLE"], L["UI_COND_HARM_TOOLTIP_DESC"], function()
        ToggleAllModifiersField("isHarm", {"isHelp", "targetSelfcast"})
    end)
    f.colHeaders.nodead = CreateToggleColHeader(508, L["UI_COND_NODEAD"], L["UI_COND_NODEAD_TOOLTIP_TITLE"], L["UI_COND_NODEAD_TOOLTIP_DESC"], function()
        ToggleAllModifiersField("isNodead")
    end)
    f.colHeaders.alt    = CreateColHeader(565, L["UI_GRID_ALTSPELL"])

    f.modRows = {}
    local startY = -252
    local rowHeight = 24

    for i = 1, 7 do
        local row = CreateFrame("Frame", nil, editor, "BackdropTemplate")
        row:SetSize(755, rowHeight)
        row:SetPoint("TOPLEFT", editor, "TOPLEFT", 15, startY - (i - 1) * (rowHeight + 1))
        row:SetBackdrop(BACKDROP_FRAME)

        local isEven = (i % 2 == 0)
        local rowBg = isEven and { 0.04, 0.05, 0.08, 0.50 } or { 0.07, 0.09, 0.13, 0.50 }
        local rowBorder = { 0.12, 0.15, 0.22, 0.35 }

        if row.SetBackdropColor then
            row:SetBackdropColor(rowBg[1], rowBg[2], rowBg[3], rowBg[4])
        end
        if row.SetBackdropBorderColor then
            row:SetBackdropBorderColor(rowBorder[1], rowBorder[2], rowBorder[3], rowBorder[4])
        end

        row:EnableMouse(true)
        if row.HookScript then
            row:HookScript("OnEnter", function(self)
                if self.SetBackdropColor then self:SetBackdropColor(0.10, 0.14, 0.22, 0.85) end
                if self.SetBackdropBorderColor then self:SetBackdropBorderColor(0.25, 0.35, 0.50, 0.80) end
            end)
            row:HookScript("OnLeave", function(self)
                if self.SetBackdropColor then self:SetBackdropColor(rowBg[1], rowBg[2], rowBg[3], rowBg[4]) end
                if self.SetBackdropBorderColor then self:SetBackdropBorderColor(rowBorder[1], rowBorder[2], rowBorder[3], rowBorder[4]) end
            end)
        end

        -- Up/Down order buttons using native WoW scroll button templates
        local upBtn = CreateFrame("Button", nil, row, "UIPanelScrollUpButtonTemplate")
        upBtn:SetSize(16, 16)
        upBtn:SetPoint("LEFT", row, "LEFT", 0, 0)
        upBtn:SetScript("OnClick", function()
            RF:MoveModifierOrder(i, -1)
        end)
        row.upBtn = upBtn

        local downBtn = CreateFrame("Button", nil, row, "UIPanelScrollDownButtonTemplate")
        downBtn:SetSize(16, 16)
        downBtn:SetPoint("LEFT", upBtn, "RIGHT", 2, 0)
        downBtn:SetScript("OnClick", function()
            RF:MoveModifierOrder(i, 1)
        end)
        row.downBtn = downBtn

        -- Enable Checkbox (explicit size 20x20 to prevent default 32x32 template overlap)
        local enableCb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        enableCb:SetSize(20, 20)
        enableCb:SetPoint("LEFT", downBtn, "RIGHT", 3, 0)
        enableCb:SetScript("OnClick", function(self)
            if currentMacro and currentMacro.modifiers and currentMacro.modifiers[i] then
                currentMacro.modifiers[i].enabled = self:GetChecked()
                RF:UpdatePreview()
            end
        end)
        row.enableCb = enableCb

        -- Mod Label (anchored to enableCb RIGHT with generous width so text never overlaps)
        local modLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        modLabel:SetPoint("LEFT", enableCb, "RIGHT", 4, 0)
        modLabel:SetWidth(105)
        modLabel:SetJustifyH("LEFT")
        row.modLabel = modLabel

        -- Rank Offset Selector
        local offsetLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        offsetLabel:SetPoint("LEFT", row, "LEFT", 168, 0)
        offsetLabel:SetText((L["RANK_WORD"] or "Rank") .. ":")
        row.offsetLabel = offsetLabel

        local offsetEdit = CreateFrame("EditBox", nil, row, "BackdropTemplate")
        offsetEdit:SetSize(22, 18)
        offsetEdit:SetPoint("LEFT", row, "LEFT", 204, 0)
        offsetEdit:SetAutoFocus(false)
        offsetEdit:SetNumeric(true)
        offsetEdit:SetMaxLetters(2)
        offsetEdit:SetFontObject("GameFontHighlightSmall")
        if offsetEdit.SetTextInsets then offsetEdit:SetTextInsets(2, 2, 0, 0) end
        ApplyModernEditBoxStyle(offsetEdit)
        local function UpdateRowDesc(val)
            local off = tonumber(val) or 0
            local spName = currentMacro and currentMacro.spellName
            local pct, status, procChance, reqLvl, desc = RF:GetDownrankingEfficiency(spName, off)
            local text = (off == 0) and "MAX" or string.format("(-%d)", off)
            if status == "green" then
                row.descText:SetText("|cff00ff00" .. text .. "|r")
            elseif status == "yellow" then
                row.descText:SetText("|cffffcc00" .. text .. "|r")
            else
                row.descText:SetText("|cffff3333" .. text .. "|r")
            end
        end
        row.UpdateRowDesc = UpdateRowDesc

        offsetEdit:SetScript("OnTextChanged", function(self, userInput)
            if userInput and currentMacro and currentMacro.modifiers and currentMacro.modifiers[i] then
                local val = tonumber(self:GetText()) or 0
                currentMacro.modifiers[i].rankOffset = val
                UpdateRowDesc(val)
                RF:UpdatePreview()
            end
        end)
        row.offsetEdit = offsetEdit

        local descText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        descText:SetPoint("LEFT", row, "LEFT", 228, 0)
        descText:SetWidth(25)
        descText:SetJustifyH("LEFT")
        row.descText = descText

        local function ShowRowEfficiencyTooltip(owner)
            local spName = currentMacro and currentMacro.spellName
            if not spName or spName == "" then return end
            local off = tonumber(row.offsetEdit:GetText()) or 0
            local spellInfo = RF.knownSpells and RF.knownSpells[spName]
            local maxRank = (spellInfo and spellInfo.maxRank and spellInfo.maxRank > 0) and spellInfo.maxRank or 1
            local targetRank = math.max(1, maxRank - off)
            local pct, status, procChance, reqLvl, desc = RF:GetDownrankingEfficiency(spName, off, targetRank)

            GameTooltip:SetOwner(owner, "ANCHOR_TOP")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(string.format("%s (%s %d)", spName, L["RANK_WORD"] or "Rank", targetRank), 1, 0.82, 0)
            GameTooltip:AddLine(string.format(L["UI_EFFICIENCY_REQ_LVL"] or "Required Level: %d", reqLvl), 0.8, 0.8, 0.8)

            local spColor = (status == "green" and "|cff00ff00") or (status == "yellow" and "|cffffcc00") or "|cffff3333"
            GameTooltip:AddLine(string.format((L["UI_EFFICIENCY_SP_SCALING"] or "Spell Power Scaling: %s"), spColor .. pct .. "%|r"), 1, 1, 1)

            local procColor = (status == "green" and "|cff00ff00") or (status == "yellow" and "|cffffcc00") or "|cffff3333"
            GameTooltip:AddLine(string.format((L["UI_EFFICIENCY_PROC_CHANCE"] or "Talent & Proc Chance: %s"), procColor .. procChance .. "|r"), 1, 1, 1)

            GameTooltip:AddLine(desc, 0.7, 0.7, 0.7, true)
            if status ~= "green" then
                GameTooltip:AddLine("|cffffcc00" .. (L["UI_SWEET_SPOT_CLICK"] or "[Click]") .. "|r Klicke auf den Stern (*), um den sicheren Sweet Spot einzustellen.", 0.9, 0.9, 0.5, true)
            end
            GameTooltip:Show()
        end

        offsetEdit:SetScript("OnEnter", ShowRowEfficiencyTooltip)
        offsetEdit:SetScript("OnLeave", function() GameTooltip:Hide() end)

        -- Sweet Spot Recommendation Button (Gold Star)
        local starBtn = CreateFrame("Button", nil, row)
        starBtn:SetSize(14, 14)
        starBtn:SetPoint("LEFT", row, "LEFT", 251, 0)

        local starIcon = starBtn:CreateTexture(nil, "ARTWORK")
        starIcon:SetAllPoints()
        starIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
        starBtn.icon = starIcon
        row.starBtn = starBtn

        starBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(L["UI_SWEET_SPOT_TITLE"] or "Sweet Spot (Optimal Downrank)", 1, 0.82, 0)
            local spName = currentMacro and currentMacro.spellName
            if spName and spName ~= "" then
                local bestOffset, bestRank, reqLvl = RF:GetSpellSweetSpot(spName)
                GameTooltip:AddLine(string.format(L["UI_SWEET_SPOT_RECOMMENDED"] or "Optimal: Rank %d (Level %d+)", bestRank, reqLvl), 0, 1, 0)
                GameTooltip:AddLine("• 100% Zaubermacht-Skalierung (Kein Malus)", 0.8, 1, 0.8)
                GameTooltip:AddLine("• 100% Talent- & Schmuckstück-Proc-Chance (Sicher)", 0.8, 1, 0.8)
                GameTooltip:AddLine(L["UI_SWEET_SPOT_DESC"] or "Lowest rank with 100% spell power scaling for maximum mana efficiency.", 0.8, 0.8, 0.8, true)
                GameTooltip:AddLine(L["UI_SWEET_SPOT_CLICK"] or "|cff00ff00[Click]|r Set this rank offset automatically", 0, 1, 0)
            else
                GameTooltip:AddLine(L["UI_SWEET_SPOT_NO_SPELL"] or "Select a base spell first.", 0.8, 0.8, 0.8)
            end
            GameTooltip:Show()
        end)

        starBtn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        starBtn:SetScript("OnClick", function(self)
            local spName = currentMacro and currentMacro.spellName
            if spName and spName ~= "" and currentMacro.modifiers and currentMacro.modifiers[i] then
                local bestOffset, bestRank, reqLvl = RF:GetSpellSweetSpot(spName)
                currentMacro.modifiers[i].rankOffset = bestOffset
                row.offsetEdit:SetText(tostring(bestOffset))
                UpdateRowDesc(bestOffset)
                pcall(PlaySound, SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
                RF:UpdatePreview()
            end
        end)

        -- Grid Targeting Checkboxes per Row
        local function CreateRowTargetCheck(x, tooltipTitle, tooltipDesc, onToggle)
            local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
            cb:SetSize(20, 20)
            cb:SetPoint("LEFT", row, "LEFT", x, 0)
            cb:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText(tooltipTitle, 1, 1, 1)
                if tooltipDesc and tooltipDesc ~= "" then GameTooltip:AddLine(tooltipDesc, 0.8, 0.8, 0.8, true) end
                GameTooltip:Show()
            end)
            cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
            cb:SetScript("OnClick", function(self)
                if onToggle then onToggle(self:GetChecked()) end
                RF:UpdatePreview()
            end)
            return cb
        end

        row.cbMo = CreateRowTargetCheck(266, L["UI_GRID_MO_TOOLTIP_TITLE"], L["UI_GRID_MO_TOOLTIP_DESC"], function(checked)
            if currentMacro and currentMacro.modifiers and currentMacro.modifiers[i] then
                currentMacro.modifiers[i].targetMouseover = checked
            end
        end)

        row.cbTarget = CreateRowTargetCheck(296, L["UI_GRID_TARGET_TOOLTIP_TITLE"], L["UI_GRID_TARGET_TOOLTIP_DESC"], function(checked)
            if currentMacro and currentMacro.modifiers and currentMacro.modifiers[i] then
                currentMacro.modifiers[i].targetTarget = checked
            end
        end)

        row.cbFocus = CreateRowTargetCheck(326, L["UI_GRID_FOCUS_TOOLTIP_TITLE"], L["UI_GRID_FOCUS_TOOLTIP_DESC"], function(checked)
            if currentMacro and currentMacro.modifiers and currentMacro.modifiers[i] then
                currentMacro.modifiers[i].targetFocus = checked
            end
        end)

        row.cbToT = CreateRowTargetCheck(356, L["UI_GRID_TOT_TOOLTIP_TITLE"], L["UI_GRID_TOT_TOOLTIP_DESC"], function(checked)
            if currentMacro and currentMacro.modifiers and currentMacro.modifiers[i] then
                currentMacro.modifiers[i].targetToT = checked
            end
        end)

        row.cbSelfcast = CreateRowTargetCheck(386, L["UI_GRID_SELF_TOOLTIP_TITLE"], L["UI_GRID_SELF_TOOLTIP_DESC"], function(checked)
            if currentMacro and currentMacro.modifiers and currentMacro.modifiers[i] then
                currentMacro.modifiers[i].targetSelfcast = checked
            end
        end)

        row.cbHelp = CreateRowTargetCheck(420, L["UI_COND_HELP_TOOLTIP_TITLE"], L["UI_COND_HELP_TOOLTIP_DESC"], function(checked)
            if currentMacro and currentMacro.modifiers and currentMacro.modifiers[i] then
                currentMacro.modifiers[i].isHelp = checked
                if checked then
                    currentMacro.modifiers[i].isHarm = false
                    if row.cbHarm then row.cbHarm:SetChecked(false) end
                end
            end
        end)
        row.cbHelp.text = row.cbHelp:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.cbHelp.text:SetPoint("LEFT", row.cbHelp, "RIGHT", 1, 0)
        row.cbHelp.text:SetText("help")

        row.cbHarm = CreateRowTargetCheck(462, L["UI_COND_HARM_TOOLTIP_TITLE"], L["UI_COND_HARM_TOOLTIP_DESC"], function(checked)
            if currentMacro and currentMacro.modifiers and currentMacro.modifiers[i] then
                currentMacro.modifiers[i].isHarm = checked
                if checked then
                    currentMacro.modifiers[i].isHelp = false
                    if row.cbHelp then row.cbHelp:SetChecked(false) end
                    -- Mutually exclude selfcast when harm is selected
                    currentMacro.modifiers[i].targetSelfcast = false
                    if row.cbSelfcast then row.cbSelfcast:SetChecked(false) end
                end
            end
        end)
        row.cbHarm.text = row.cbHarm:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.cbHarm.text:SetPoint("LEFT", row.cbHarm, "RIGHT", 1, 0)
        row.cbHarm.text:SetText("harm")

        row.cbNodead = CreateRowTargetCheck(508, L["UI_COND_NODEAD_TOOLTIP_TITLE"], L["UI_COND_NODEAD_TOOLTIP_DESC"], function(checked)
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
        altDropSlot:SetPoint("LEFT", row, "LEFT", 565, 0)
        altDropSlot:SetBackdrop(BACKDROP_FRAME)
        if altDropSlot.SetBackdropColor then
            altDropSlot:SetBackdropColor(0.06, 0.08, 0.12, 0.95)
        end
        if altDropSlot.SetBackdropBorderColor then
            altDropSlot:SetBackdropBorderColor(0.20, 0.26, 0.38, 0.85)
        end

        local altDropIcon = altDropSlot:CreateTexture(nil, "ARTWORK")
        altDropIcon:SetPoint("TOPLEFT", altDropSlot, "TOPLEFT", 1, -1)
        altDropIcon:SetPoint("BOTTOMRIGHT", altDropSlot, "BOTTOMRIGHT", -1, 1)
        altDropIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        altDropIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        altDropIcon:SetAlpha(0.6)
        altDropSlot.icon = altDropIcon
        row.altDropSlot = altDropSlot

        local customSpellEdit = CreateFrame("EditBox", nil, row, "BackdropTemplate")
        customSpellEdit:SetSize(142, 18)
        customSpellEdit:SetPoint("LEFT", row, "LEFT", 587, 0)
        customSpellEdit:SetAutoFocus(false)
        customSpellEdit:SetFontObject("GameFontHighlightSmall")
        if customSpellEdit.SetTextInsets then customSpellEdit:SetTextInsets(4, 4, 0, 0) end
        ApplyModernEditBoxStyle(customSpellEdit)
        row.customSpellEdit = customSpellEdit

        -- Search / Picker button
        local searchBtn = CreateModernButton(row, 22, 18, "...", "slate", "GameFontHighlightSmall")
        searchBtn:SetPoint("LEFT", row, "LEFT", 733, 0)
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
                local tex = RF:GetSpellTexture(spellName) or "Interface\\Icons\\INV_Misc_QuestionMark"
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
            local spellName = RF:GetSpellFromCursor()
            if spellName then
                ApplySpellToModifier(spellName)
                return true
            end
            return false
        end

        altDropSlot:SetScript("OnReceiveDrag", HandleSpellDrop)
        altDropSlot:SetScript("OnClick", function(self)
            if not HandleSpellDrop() then
                RF:OpenSpellPicker(customSpellEdit, ApplySpellToModifier)
            end
        end)

        customSpellEdit:SetScript("OnReceiveDrag", HandleSpellDrop)
        customSpellEdit:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                local infoType = GetCursorInfo and GetCursorInfo()
                if infoType == "spell" or infoType == "action" then
                    if HandleSpellDrop() then
                        self:ClearFocus()
                        return
                    end
                end
            end
        end)
        customSpellEdit:SetScript("OnTextChanged", function(self, userInput)
            if userInput and currentMacro and currentMacro.modifiers and currentMacro.modifiers[i] then
                local text = self:GetText():trim()
                currentMacro.modifiers[i].customSpell = text
                currentMacro.modifiers[i].mode = (text ~= "") and "custom" or "relative"
                local tex = (text ~= "") and RF:GetSpellTexture(text) or "Interface\\Icons\\INV_Misc_QuestionMark"
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
    f.previewHeader = previewHeader

    local dragHint = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dragHint:SetPoint("LEFT", previewHeader, "RIGHT", 10, 0)
    dragHint:SetText("|cff00ff00(" .. L["UI_DRAG_HINT"] .. ")|r")
    f.dragHint = dragHint

    -- Action Bar Drag Preview Icon
    local previewIcon = CreateFrame("Button", "RankForgePreviewDragButton", editor, "BackdropTemplate")
    previewIcon:SetSize(42, 42)
    previewIcon:SetPoint("TOPLEFT", editor, "TOPLEFT", 15, -458)
    previewIcon:SetBackdrop(BACKDROP_FRAME)
    if previewIcon.SetBackdropColor then
        previewIcon:SetBackdropColor(0.08, 0.10, 0.14, 0.95)
    end
    if previewIcon.SetBackdropBorderColor then
        previewIcon:SetBackdropBorderColor(0.28, 0.45, 0.70, 0.90)
    end
    if previewIcon.HookScript then
        previewIcon:HookScript("OnEnter", function(self)
            if self.SetBackdropBorderColor then self:SetBackdropBorderColor(0.85, 0.70, 0.25, 1.0) end
        end)
        previewIcon:HookScript("OnLeave", function(self)
            if self.SetBackdropBorderColor then self:SetBackdropBorderColor(0.28, 0.45, 0.70, 0.90) end
        end)
    end
    previewIcon:RegisterForDrag("LeftButton")

    local pTex = previewIcon:CreateTexture(nil, "ARTWORK")
    pTex:SetPoint("TOPLEFT", previewIcon, "TOPLEFT", 2, -2)
    pTex:SetPoint("BOTTOMRIGHT", previewIcon, "BOTTOMRIGHT", -2, 2)
    pTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
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
        GameTooltip:SetText(currentMacro and currentMacro.macroName or (L["UI_MACRO_NAME"] and L["UI_MACRO_NAME"]:gsub(":", "") or "Macro"))
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
    ApplyModernCardStyle(previewBoxBg, { 0.03, 0.04, 0.06, 0.95 }, { 0.18, 0.22, 0.32, 0.85 })

    local copyHint = editor:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    copyHint:SetPoint("BOTTOMRIGHT", previewBoxBg, "TOPRIGHT", 0, 4)
    copyHint:SetText(L["UI_COPY_HINT"] or "|cff888888(Click = Select all for Ctrl+C)|r")
    f.copyHint = copyHint

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
    local saveBtn = CreateModernButton(editor, 160, 24, L["UI_SAVE_MACRO"], "primary")
    saveBtn:SetPoint("BOTTOMRIGHT", editor, "BOTTOMRIGHT", -15, 12)
    saveBtn:SetScript("OnClick", function()
        if currentMacro then
            if not currentMacro.spellID or currentMacro.spellID == 0 then
                currentMacro.spellID = RF:ResolveSpellID(currentMacro.spellName)
            end
            RF:SyncMacro(currentMacro, false)
            RF:UpdateUI()
        end
    end)
    f.saveBtn = saveBtn

    -- Delete Button
    local deleteBtn = CreateModernButton(editor, 90, 24, L["UI_DELETE_MACRO"], "danger")
    deleteBtn:SetPoint("RIGHT", saveBtn, "LEFT", -10, 0)
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
local function GetModifierDisplayName(key)
    if key == "nomod" then return "|cffffd200" .. L["UI_MOD_NOMOD"] .. "|r" end
    if key == "shift_ctrl" then return "|cff00e5ff" .. L["UI_MOD_SHIFT"] .. "|r+|cffa855f7" .. L["UI_MOD_CTRL"] .. "|r" end
    if key == "shift_alt" then return "|cff00e5ff" .. L["UI_MOD_SHIFT"] .. "|r+|cff22c55e" .. L["UI_MOD_ALT"] .. "|r" end
    if key == "ctrl_alt" then return "|cffa855f7" .. L["UI_MOD_CTRL"] .. "|r+|cff22c55e" .. L["UI_MOD_ALT"] .. "|r" end
    if key == "shift" then return "|cff00e5ff" .. L["UI_MOD_SHIFT"] .. "|r" end
    if key == "ctrl" then return "|cffa855f7" .. L["UI_MOD_CTRL"] .. "|r" end
    if key == "alt" then return "|cff22c55e" .. L["UI_MOD_ALT"] .. "|r" end
    return key
end

local DEFAULT_MODIFIERS_LIST = {
    { key = "shift_ctrl", enabled = false, mode = "relative", rankOffset = 3, customSpell = "", targetMouseover = true, targetTarget = true, targetFocus = false, targetToT = false, targetSelfcast = true,  isHelp = true, isHarm = false, isNodead = true },
    { key = "shift_alt",  enabled = false, mode = "relative", rankOffset = 4, customSpell = "", targetMouseover = true, targetTarget = true, targetFocus = false, targetToT = false, targetSelfcast = true,  isHelp = true, isHarm = false, isNodead = true },
    { key = "ctrl_alt",   enabled = false, mode = "relative", rankOffset = 5, customSpell = "", targetMouseover = true, targetTarget = true, targetFocus = false, targetToT = false, targetSelfcast = true,  isHelp = true, isHarm = false, isNodead = true },
    { key = "shift",      enabled = true,  mode = "relative", rankOffset = 1, customSpell = "", targetMouseover = true, targetTarget = true, targetFocus = false, targetToT = false, targetSelfcast = true,  isHelp = true, isHarm = false, isNodead = true },
    { key = "ctrl",       enabled = false, mode = "relative", rankOffset = 2, customSpell = "", targetMouseover = true, targetTarget = true, targetFocus = false, targetToT = false, targetSelfcast = true,  isHelp = true, isHarm = false, isNodead = true },
    { key = "alt",        enabled = true,  mode = "relative", rankOffset = 2, customSpell = "", targetMouseover = true, targetTarget = true, targetFocus = false, targetToT = false, targetSelfcast = true,  isHelp = true, isHarm = false, isNodead = true },
    { key = "nomod",      enabled = true,  mode = "relative", rankOffset = 0, customSpell = "", targetMouseover = true, targetTarget = true, targetFocus = false, targetToT = false, targetSelfcast = true,  isHelp = true, isHarm = false, isNodead = true },
}

function RF:EnsureAllModifiers(macroConfig)
    if not macroConfig or not macroConfig.modifiers then return end
    local hasKey = {}
    for _, mod in ipairs(macroConfig.modifiers) do
        hasKey[mod.key] = true
        if mod.targetMouseover == nil then mod.targetMouseover = (macroConfig.targetMouseover ~= false) end
        if mod.targetTarget == nil then mod.targetTarget = true end
        if mod.targetFocus == nil then mod.targetFocus = (macroConfig.targetFocus or false) end
        if mod.targetToT == nil then mod.targetToT = (macroConfig.targetToT or false) end
        if mod.targetSelfcast == nil then mod.targetSelfcast = (mod.isHarm ~= true) end
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
                targetTarget = def.targetTarget,
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
    local charName, realm, classFileName = RF:GetCurrentCharacterKey()
    local newCfg = {
        macroName = L["UI_DEFAULT_MACRO_NAME"] or "DR_New",
        spellName = "",
        character = charName,
        realm = realm,
        class = classFileName,
        isAccount = true, -- Default to General (Account, 120 Slots)
        fallbackMode = "omit",
        omitRank = false,
        targetMouseover = true,
        customTarget = "",
        customSortOrder = false,
        useTrinket1 = false,
        useTrinket2 = false,
        useRacial = false,
        startAttack = false,
        petAttack = false,
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
            targetTarget = def.targetTarget,
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
            row.modLabel:SetText(GetModifierDisplayName(modData.key))
            row.offsetEdit:SetText(tostring(modData.rankOffset or 0))
            local off = tonumber(modData.rankOffset) or 0
            if macroConfig.omitRank then
                row.descText:SetText("|cff888888(ohne)|r")
                if row.offsetEdit.SetAlpha then row.offsetEdit:SetAlpha(0.35) end
                if row.starBtn and row.starBtn.SetAlpha then row.starBtn:SetAlpha(0.2) end
            else
                if row.offsetEdit.SetAlpha then row.offsetEdit:SetAlpha(1.0) end
                if row.starBtn and row.starBtn.SetAlpha then row.starBtn:SetAlpha(1.0) end
                if row.UpdateRowDesc then
                    row.UpdateRowDesc(off)
                else
                    row.descText:SetText(off == 0 and "MAX" or string.format("(-%d)", off))
                end
            end

            -- Grid Targeting Checkboxes per Row
            if row.cbMo then row.cbMo:SetChecked(modData.targetMouseover ~= false) end
            if row.cbTarget then row.cbTarget:SetChecked(modData.targetTarget ~= false) end
            if row.cbFocus then row.cbFocus:SetChecked(modData.targetFocus == true) end
            if row.cbToT then row.cbToT:SetChecked(modData.targetToT == true) end
            if row.cbSelfcast then row.cbSelfcast:SetChecked(modData.targetSelfcast == true) end
            if row.cbHelp then row.cbHelp:SetChecked(modData.isHelp == true) end
            if row.cbHarm then row.cbHarm:SetChecked(modData.isHarm == true) end
            if row.cbNodead then row.cbNodead:SetChecked(modData.isNodead ~= false) end

            if row.starBtn and row.starBtn.icon then
                local bestOffset = RF:GetSpellSweetSpot(macroConfig.spellName)
                if bestOffset and off == bestOffset then
                    row.starBtn.icon:SetAlpha(1.0)
                else
                    row.starBtn.icon:SetAlpha(0.4)
                end
            end

            local cSpell = modData.customSpell or ""
            row.customSpellEdit:SetText(cSpell)
            local tex = (cSpell ~= "") and RF:GetSpellTexture(cSpell) or "Interface\\Icons\\INV_Misc_QuestionMark"
            if row.altDropSlot and row.altDropSlot.icon then
                row.altDropSlot.icon:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
                row.altDropSlot.icon:SetAlpha((cSpell ~= "") and 1.0 or 0.6)
            end
        else
            row:Hide()
        end
    end
end

function RF:UpdateMacroListItem(btn, macroCfg, index)
    if not btn or not macroCfg then return end
    btn.macroConfig = macroCfg
    btn.macroIndex = index

    local mName = macroCfg.macroName
    if not mName or mName == "" then
        mName = "Macro " .. (index or 1)
    end
    if btn.nameText then
        btn.nameText:SetText(mName)
    else
        btn:SetText(mName)
    end

    local sName, sID = RF:GetLocalizedSpellName(macroCfg.spellName, macroCfg.spellID)
    if sID and not macroCfg.spellID then
        macroCfg.spellID = sID
    end

    if btn.subText then
        if sName and sName ~= "" then
            btn.subText:SetText(sName)
            if btn.subText.SetTextColor then
                btn.subText:SetTextColor(0.65, 0.78, 0.95)
            end
        else
            btn.subText:SetText(L["UI_NO_SPELL"] or "(No spell)")
            if btn.subText.SetTextColor then
                btn.subText:SetTextColor(0.5, 0.5, 0.5)
            end
        end
    end

    local tex = nil
    if sName and sName ~= "" then
        local spellInfo = RF:GetSpellRanksInfo(macroCfg.spellID or sName)
        if spellInfo and spellInfo.spellID then
            tex = RF:GetSpellTexture(spellInfo.spellID)
        end
        if not tex or tex == "Interface\\Icons\\INV_Misc_QuestionMark" then
            tex = RF:GetSpellTexture(macroCfg.spellID or sName)
        end
    end
    if btn.icon then
        btn.icon:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
    end
end

function RF:LoadMacroIntoEditor(macroConfig)
    if macroConfig then
        RF:EnsureAllModifiers(macroConfig)
    end
    currentMacro = macroConfig
    if not RF.MainFrame or not macroConfig then return end
    local f = RF.MainFrame

    local locSpell, sID = RF:GetLocalizedSpellName(macroConfig.spellName, macroConfig.spellID)
    if sID and not macroConfig.spellID then
        macroConfig.spellID = sID
    end

    f.nameEdit:SetText(macroConfig.macroName or "")
    f.spellEdit:SetText(locSpell or macroConfig.spellName or "")
    if f.cbNoRank then
        f.cbNoRank:SetChecked(macroConfig.omitRank == true)
    end
    local isAcc = (macroConfig.isAccount == true)
    UIDropDownMenu_SetSelectedValue(f.storageDropdown, isAcc and "account" or "char")
    UIDropDownMenu_SetText(f.storageDropdown, isAcc and L["UI_STORAGE_ACCOUNT"] or L["UI_STORAGE_CHAR"])
    f.fallbackCheck:SetChecked(macroConfig.fallbackMode == "rank1")

    f.cbStartAttack:SetChecked(macroConfig.startAttack or false)
    f.cbPetAttack:SetChecked(macroConfig.petAttack or false)
    f.cbTrinket1:SetChecked(macroConfig.useTrinket1 or false)
    f.cbTrinket2:SetChecked(macroConfig.useTrinket2 or false)
    f.cbRacial:SetChecked(macroConfig.useRacial or false)
    f.preCastEdit:SetText(macroConfig.preCastLines or "")

    f.customTargetEdit:SetText(macroConfig.customTarget or "")

    -- Update icon
    local spellInfo = RF:GetSpellRanksInfo(macroConfig.spellID or locSpell or macroConfig.spellName)
    local tex = "Interface\\Icons\\INV_Misc_QuestionMark"
    if spellInfo and spellInfo.spellID then
        local t = RF:GetSpellTexture(spellInfo.spellID)
        if t then tex = t end
    end
    if not tex or tex == "Interface\\Icons\\INV_Misc_QuestionMark" then
        tex = RF:GetSpellTexture(macroConfig.spellID or locSpell or macroConfig.spellName)
    end
    f.dropSlot.icon:SetTexture(tex)
    f.previewIcon.icon:SetTexture(tex)

    local b = RF:GetSelectedMacroButton()
    if b then
        RF:UpdateMacroListItem(b, macroConfig, selectedMacroIndex)
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

function RF:RefreshUILabels()
    if not RF.MainFrame then return end
    local f = RF.MainFrame

    if f.title then f.title:SetText(L["UI_TITLE"]) end
    if f.listHeader then f.listHeader:SetText(L["UI_CONFIGURED_MACROS"]) end
    if f.newBtn then f.newBtn:SetText("+ " .. L["UI_NEW_MACRO"]) end
    if f.cloneBtn then f.cloneBtn:SetText(L["UI_CLONE_BTN"]) end
    if f.exportBtn then f.exportBtn:SetText(L["UI_EXPORT_BTN"]) end
    if f.nameLabel then f.nameLabel:SetText(L["UI_MACRO_NAME"]) end
    if f.spellLabel then f.spellLabel:SetText(L["UI_SPELL_NAME"]) end
    if f.cbNoRank and f.cbNoRank.text then f.cbNoRank.text:SetText(L["UI_OMIT_RANK"] or "Ohne Rang casten") end
    if f.dropSlotText then f.dropSlotText:SetText(L["UI_DROP_SPELL_HERE"]) end
    if f.targetHeader then f.targetHeader:SetText(L["UI_TARGETING_HEADER"]) end
    if f.fallbackCheck and f.fallbackCheck.text then f.fallbackCheck.text:SetText(L["UI_FALLBACK_RANK1"]) end
    if f.cbTrinket1 and f.cbTrinket1.text then f.cbTrinket1.text:SetText(L["UI_USE_TRINKET_1"]) end
    if f.cbTrinket2 and f.cbTrinket2.text then f.cbTrinket2.text:SetText(L["UI_USE_TRINKET_2"]) end
    if f.cbRacial and f.cbRacial.text then f.cbRacial.text:SetText(L["UI_USE_RACIAL"]) end
    if f.preCastHeader then f.preCastHeader:SetText(L["UI_PRECAST_CUSTOM"]) end
    if f.customTargetHeader then f.customTargetHeader:SetText(L["UI_TARGET_CUSTOM"]) end
    if f.modifiersHeader then f.modifiersHeader:SetText(L["UI_MODIFIERS_HEADER"]) end
    if f.resetSortBtn then f.resetSortBtn:SetText(L["UI_RESET_SORT_BTN"]) end
    if f.previewHeader then f.previewHeader:SetText(L["UI_PREVIEW_HEADER"]) end
    if f.dragHint then f.dragHint:SetText("|cff00ff00(" .. L["UI_DRAG_HINT"] .. ")|r") end
    if f.copyHint then f.copyHint:SetText(L["UI_COPY_HINT"] or "|cff888888(Click = Select all for Ctrl+C)|r") end
    if f.saveBtn then f.saveBtn:SetText(L["UI_SAVE_MACRO"]) end
    if f.deleteBtn then f.deleteBtn:SetText(L["UI_DELETE_MACRO"]) end

    if f.colHeaders then
        local function SetHeaderLabel(btnOrFs, text)
            if not btnOrFs or not text then return end
            if btnOrFs.fs then
                btnOrFs.fs:SetText(text)
                btnOrFs:SetWidth(btnOrFs.fs:GetStringWidth() + 4)
            elseif btnOrFs.SetText then
                btnOrFs:SetText(text)
            end
        end

        SetHeaderLabel(f.colHeaders.mod, L["UI_GRID_MOD"])
        SetHeaderLabel(f.colHeaders.rank, L["UI_GRID_RANK"])
        SetHeaderLabel(f.colHeaders.mo, L["UI_GRID_MO"])
        SetHeaderLabel(f.colHeaders.target, L["UI_GRID_TARGET"])
        SetHeaderLabel(f.colHeaders.focus, L["UI_GRID_FOCUS"])
        SetHeaderLabel(f.colHeaders.tot, L["UI_GRID_TOT"])
        SetHeaderLabel(f.colHeaders.self, L["UI_GRID_SELF"])
        SetHeaderLabel(f.colHeaders.help, L["UI_COND_HELP"])
        SetHeaderLabel(f.colHeaders.harm, L["UI_COND_HARM"])
        SetHeaderLabel(f.colHeaders.nodead, L["UI_COND_NODEAD"])
        SetHeaderLabel(f.colHeaders.alt, L["UI_GRID_ALTSPELL"])
    end

    if f.modRows then
        for _, row in ipairs(f.modRows) do
            if row.offsetLabel then
                row.offsetLabel:SetText((L["RANK_WORD"] or "Rank") .. ":")
            end
        end
    end

    if f.langDropdown then
        local cur = (RankForgeDB and RankForgeDB.locale) or "auto"
        local curText = L["UI_LANG_AUTO"] or "Auto (Client)"
        if cur == "enUS" then
            curText = L["UI_LANG_EN"] or "English"
        elseif cur == "deDE" then
            curText = L["UI_LANG_DE"] or "Deutsch"
        end
        UIDropDownMenu_SetText(f.langDropdown, curText)
    end

    if f.filterCharCb then
        if f.filterCharCb.text then
            f.filterCharCb.text:SetText(L["UI_FILTER_CURRENT_CHAR"] or "Nur dieser Charakter")
        end
        local filterVal = (RankForgeCharDB and RankForgeCharDB.filterCurrentCharOnly ~= false)
        f.filterCharCb:SetChecked(filterVal)
    end

    if f.cbDebug then
        if f.cbDebug.text then
            f.cbDebug.text:SetText(L["UI_DEBUG_AUTO_OPEN"] or "Debug (Auto-Open)")
        end
        f.cbDebug:SetChecked(RankForgeDB and RankForgeDB.debugMode == true)
    end

    if f.listContent and f.listContent.buttons then
        local macros = RF:GetMacrosList()
        for _, b in ipairs(f.listContent.buttons) do
            if b:IsShown() and b.macroIndex and macros[b.macroIndex] then
                RF:UpdateMacroListItem(b, macros[b.macroIndex], b.macroIndex)
            end
        end
    end

    if currentMacro then
        RF:LoadMacroIntoEditor(currentMacro)
    end
end

function RF:UpdateSlotStatus()
    if not RF.MainFrame or not RF.MainFrame.slotStatus then return end
    local freeAcc, usedAcc, maxAcc = RF:GetAvailableMacroSlots(true)
    local freeChar, usedChar, maxChar = RF:GetAvailableMacroSlots(false)
    local pattern = L["UI_SLOT_STATUS"] or "Gen.: %d/%d | Char: %d/%d"
    RF.MainFrame.slotStatus:SetText(string.format(pattern, usedAcc, maxAcc or 120, usedChar, maxChar or 18))
end

function RF:UpdateUI()
    local f = CreateMainUI()
    local macros = RF:GetMacrosList()

    -- Update Slot Status
    RF:UpdateSlotStatus()

    -- Sync Checkbox states
    local filterOnlyChar = (RankForgeCharDB and RankForgeCharDB.filterCurrentCharOnly ~= false)
    if f.filterCharCb then
        f.filterCharCb:SetChecked(filterOnlyChar)
    end
    if f.cbDebug then
        f.cbDebug:SetChecked(RankForgeDB and RankForgeDB.debugMode == true)
    end

    -- Build visible macro entries based on character / class filter
    local visibleMacros = {}
    for i, macroCfg in ipairs(macros) do
        if not filterOnlyChar or RF:IsMacroForCurrentCharacter(macroCfg) then
            table.insert(visibleMacros, { index = i, macro = macroCfg })
        end
    end

    -- Ensure selectedMacroIndex points to a visible macro
    local selectedVisible = false
    for _, entry in ipairs(visibleMacros) do
        if entry.index == selectedMacroIndex then
            selectedVisible = true
            break
        end
    end

    if not selectedVisible then
        if #visibleMacros > 0 then
            selectedMacroIndex = visibleMacros[1].index
        else
            selectedMacroIndex = nil
        end
    end

    -- Render Macro Buttons in Left List
    local listContent = f.listContent
    listContent.buttons = listContent.buttons or {}

    for _, btn in ipairs(listContent.buttons) do
        btn:Hide()
    end

    local yOffset = 0
    local btnHeight = 34

    for i, entry in ipairs(visibleMacros) do
        local macroCfg = entry.macro
        local origIdx = entry.index
        local btn = listContent.buttons[i]
        if not btn then
            btn = CreateFrame("Button", nil, listContent, "BackdropTemplate")
            btn:SetSize(188, btnHeight)
            ApplyModernCardStyle(btn, { 0.06, 0.08, 0.12, 0.85 }, { 0.15, 0.18, 0.25, 0.80 })

            -- Hide default button textures if any
            if btn.GetNormalTexture and btn:GetNormalTexture() then btn:GetNormalTexture():SetAlpha(0) end
            if btn.GetHighlightTexture and btn:GetHighlightTexture() then btn:GetHighlightTexture():SetAlpha(0) end

            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetSize(24, 24)
            icon:SetPoint("LEFT", btn, "LEFT", 5, 0)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            btn.icon = icon

            local fs = btn:GetFontString()
            if fs then
                fs:Hide()
            end

            local nameText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 6, -1)
            nameText:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
            nameText:SetHeight(14)
            nameText:SetJustifyH("LEFT")
            btn.nameText = nameText

            local subText = btn:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            subText:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 6, 2)
            subText:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
            subText:SetHeight(12)
            subText:SetJustifyH("LEFT")
            btn.subText = subText

            btn:SetText("")
            listContent.buttons[i] = btn
        end

        btn.macroIndex = origIdx
        btn.macroConfig = macroCfg
        btn:SetPoint("TOPLEFT", listContent, "TOPLEFT", 0, -yOffset)
        RF:UpdateMacroListItem(btn, macroCfg, origIdx)

        -- Highlight currently selected macro button
        local isSel = (origIdx == selectedMacroIndex)
        if isSel then
            if btn.SetBackdropColor then btn:SetBackdropColor(0.12, 0.16, 0.25, 0.98) end
            if btn.SetBackdropBorderColor then btn:SetBackdropBorderColor(0.85, 0.70, 0.25, 0.95) end
            if btn.LockHighlight then btn:LockHighlight() end
        else
            if btn.SetBackdropColor then btn:SetBackdropColor(0.06, 0.08, 0.12, 0.85) end
            if btn.SetBackdropBorderColor then btn:SetBackdropBorderColor(0.15, 0.18, 0.25, 0.80) end
            if btn.UnlockHighlight then btn:UnlockHighlight() end
        end

        btn:Show()

        btn:SetScript("OnEnter", function(self)
            if self.macroIndex ~= selectedMacroIndex then
                if self.SetBackdropColor then self:SetBackdropColor(0.10, 0.14, 0.22, 0.95) end
                if self.SetBackdropBorderColor then self:SetBackdropBorderColor(0.28, 0.45, 0.70, 0.90) end
            end
            local cfg = self.macroConfig or macroCfg
            if not cfg then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(cfg.macroName or ("Macro " .. origIdx), 1, 0.82, 0)
            if cfg.spellName and cfg.spellName ~= "" then
                GameTooltip:AddLine(cfg.spellName, 0.7, 0.8, 1)
            else
                GameTooltip:AddLine(L["UI_NO_SPELL"] or "(No spell)", 0.5, 0.5, 0.5)
            end
            local activeMods = 0
            if cfg.modifiers then
                for _, m in pairs(cfg.modifiers) do
                    if m and m.enabled ~= false and ((m.offset and m.offset > 0) or m.customRank or m.altSpell) then
                        activeMods = activeMods + 1
                    end
                end
            end
            GameTooltip:AddLine(string.format(L["UI_LIST_TOOLTIP_MODS"] or "Modifiers configured: %d", activeMods), 0.6, 0.6, 0.6, true)
            GameTooltip:AddLine("|cff00ff00" .. (L["UI_LIST_DRAG_HINT"] or "Drag: Place directly onto action bar") .. "|r")
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self)
            if self.macroIndex ~= selectedMacroIndex then
                if self.SetBackdropColor then self:SetBackdropColor(0.06, 0.08, 0.12, 0.85) end
                if self.SetBackdropBorderColor then self:SetBackdropBorderColor(0.15, 0.18, 0.25, 0.80) end
            end
            GameTooltip:Hide()
        end)

        -- Enable Drag & Drop directly from the left macro list onto action bars
        btn:RegisterForDrag("LeftButton")
        btn:SetScript("OnDragStart", function(self)
            local cfg = self.macroConfig or macroCfg
            if cfg and cfg.macroName then
                local index = RF:FindMacroIndex(cfg.macroName)
                if not index then
                    local ok, status, newIdx = RF:SyncMacro(cfg, true)
                    index = newIdx or RF:FindMacroIndex(cfg.macroName)
                end
                if index and PickupMacro then
                    PickupMacro(index)
                end
            end
        end)

        btn:SetScript("OnClick", function()
            selectedMacroIndex = origIdx
            for _, b in ipairs(listContent.buttons) do
                local sel = (b.macroIndex == origIdx)
                if sel then
                    if b.LockHighlight then b:LockHighlight() end
                    if b.SetBackdropColor then b:SetBackdropColor(0.12, 0.16, 0.25, 0.98) end
                    if b.SetBackdropBorderColor then b:SetBackdropBorderColor(0.85, 0.70, 0.25, 0.95) end
                else
                    if b.UnlockHighlight then b:UnlockHighlight() end
                    if b.SetBackdropColor then b:SetBackdropColor(0.06, 0.08, 0.12, 0.85) end
                    if b.SetBackdropBorderColor then b:SetBackdropBorderColor(0.15, 0.18, 0.25, 0.80) end
                end
            end
            RF:LoadMacroIntoEditor(macroCfg)
        end)

        yOffset = yOffset + btnHeight + 2
    end

    listContent:SetHeight(math.max(yOffset, 10))

    if selectedMacroIndex and macros[selectedMacroIndex] then
        RF:LoadMacroIntoEditor(macros[selectedMacroIndex])
    end
end

function RF:ToggleUI()
    local f = CreateMainUI()
    if f:IsShown() then
        f:Hide()
    else
        f:Show()
        RF:UpdateUI()
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

    ApplyModernCardStyle(d, { 0.04, 0.05, 0.07, 0.98 }, { 0.68, 0.55, 0.26, 0.90 })

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
        local btn = CreateModernButton(content, 330, 30, p.name .. " (" .. p.macroName .. ")", "slate")
        btn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)

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

    local close = CreateModernButton(d, 100, 24, L["PRESETS_CLOSE"], "slate")
    close:SetPoint("BOTTOM", d, "BOTTOM", 0, 12)
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

    ApplyModernCardStyle(d, { 0.04, 0.05, 0.07, 0.98 }, { 0.68, 0.55, 0.26, 0.90 })

    local title = d:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
    title:SetPoint("TOP", d, "TOP", 0, -16)
    title:SetText(L["PROFILE_TITLE"])

    local hint = d:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", d, "TOPLEFT", 20, -45)
    hint:SetText(L["PROFILE_EXPORT_HINT"])

    -- Scrollable EditBox Card Box
    local scrollBox = CreateFrame("Frame", nil, d, "BackdropTemplate")
    scrollBox:SetPoint("TOPLEFT", d, "TOPLEFT", 20, -65)
    scrollBox:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", -20, 50)
    ApplyModernCardStyle(scrollBox, { 0.02, 0.03, 0.05, 0.96 }, { 0.18, 0.22, 0.30, 0.85 })

    local scroll = CreateFrame("ScrollFrame", nil, scrollBox, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", scrollBox, "TOPLEFT", 6, -6)
    scroll:SetPoint("BOTTOMRIGHT", scrollBox, "BOTTOMRIGHT", -26, 6)

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
    local importBtn = CreateModernButton(d, 140, 24, L["PROFILE_IMPORT_BTN"], "primary")
    importBtn:SetPoint("BOTTOMLEFT", d, "BOTTOMLEFT", 20, 15)
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
    local closeBtn = CreateModernButton(d, 100, 24, L["PRESETS_CLOSE"], "slate")
    closeBtn:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", -20, 15)
    closeBtn:SetScript("OnClick", function() d:Hide() end)

    RF.ImportExportDialog = d
    d:Show()
end

--------------------------------------------------------------------------------
-- Test Results Dialog (Copyable with Ctrl+C)
--------------------------------------------------------------------------------
function RF:ShowTestResultsDialog(reportText)
    local d = RF.TestResultsDialog
    if not d then
        d = CreateFrame("Frame", "RankForgeTestResultsDialog", UIParent, "BackdropTemplate")
        d:SetSize(620, 440)
        d:SetPoint("CENTER")
        d:SetMovable(true)
        d:EnableMouse(true)
        d:RegisterForDrag("LeftButton")
        d:SetScript("OnDragStart", d.StartMoving)
        d:SetScript("OnDragStop", d.StopMovingOrSizing)
        d:SetFrameStrata("FULLSCREEN_DIALOG")
        d:SetFrameLevel(600)
        d:SetToplevel(true)
        ApplyModernCardStyle(d, { 0.04, 0.05, 0.07, 0.98 }, { 0.68, 0.55, 0.26, 0.90 })

        local title = d:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
        title:SetPoint("TOP", d, "TOP", 0, -16)
        title:SetText(L["TEST_DIALOG_TITLE"] or "RankForge - Test Results")
        d.title = title

        local hint = d:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hint:SetPoint("TOPLEFT", d, "TOPLEFT", 20, -42)
        hint:SetPoint("RIGHT", d, "RIGHT", -20, 0)
        hint:SetJustifyH("LEFT")
        hint:SetText(L["TEST_DIALOG_HINT"] or "Press Ctrl+C to copy test report. Saved to SavedVariables/RankForge.lua on /reload:")
        d.hint = hint

        local scrollBox = CreateFrame("Frame", nil, d, "BackdropTemplate")
        scrollBox:SetPoint("TOPLEFT", d, "TOPLEFT", 20, -68)
        scrollBox:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", -20, 50)
        ApplyModernCardStyle(scrollBox, { 0.02, 0.03, 0.05, 0.96 }, { 0.18, 0.22, 0.30, 0.85 })

        local scroll = CreateFrame("ScrollFrame", nil, scrollBox, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", scrollBox, "TOPLEFT", 6, -6)
        scroll:SetPoint("BOTTOMRIGHT", scrollBox, "BOTTOMRIGHT", -26, 6)

        local editBox = CreateFrame("EditBox", nil, scroll)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(false)
        editBox:SetFontObject("GameFontHighlightSmall")
        editBox:SetWidth(540)
        scroll:SetScrollChild(editBox)
        d.editBox = editBox

        editBox:SetScript("OnEscapePressed", function() d:Hide() end)

        local closeBtn = CreateModernButton(d, 120, 24, L["TEST_DIALOG_CLOSE"] or "Close", "slate")
        closeBtn:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", -20, 15)
        closeBtn:SetScript("OnClick", function() d:Hide() end)

        RF.TestResultsDialog = d
    end

    if d.title then d.title:SetText(L["TEST_DIALOG_TITLE"] or "RankForge - Test Results") end
    if d.hint then d.hint:SetText(L["TEST_DIALOG_HINT"] or "Press Ctrl+C to copy test report. Saved to SavedVariables/RankForge.lua on /reload:") end
    if d.editBox then
        d.editBox:SetText(reportText or "")
        d.editBox:SetFocus()
        d.editBox:HighlightText()
    end

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

        ApplyModernCardStyle(p, { 0.04, 0.05, 0.07, 0.98 }, { 0.28, 0.45, 0.70, 0.95 })

        local title = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        title:SetPoint("TOPLEFT", p, "TOPLEFT", 10, -8)
        title:SetText("Zauber auswählen:")

        local closeBtn = CreateFrame("Button", nil, p, "UIPanelCloseButton")
        closeBtn:SetSize(20, 20)
        closeBtn:SetPoint("TOPRIGHT", p, "TOPRIGHT", -2, -2)
        closeBtn:SetScript("OnClick", function() p:Hide() end)

        -- Filter input box
        local filterEdit = CreateFrame("EditBox", nil, p, "BackdropTemplate")
        filterEdit:SetSize(210, 20)
        filterEdit:SetPoint("TOPLEFT", p, "TOPLEFT", 12, -28)
        filterEdit:SetAutoFocus(false)
        filterEdit:SetFontObject("GameFontHighlightSmall")
        if filterEdit.SetTextInsets then filterEdit:SetTextInsets(4, 4, 0, 0) end
        ApplyModernEditBoxStyle(filterEdit)
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
                btn = CreateFrame("Button", nil, content, "BackdropTemplate")
                btn:SetSize(195, 22)
                ApplyModernCardStyle(btn, { 0.06, 0.08, 0.12, 0.85 }, { 0.15, 0.18, 0.25, 0.70 })

                if btn.GetNormalTexture and btn:GetNormalTexture() then btn:GetNormalTexture():SetAlpha(0) end
                if btn.GetHighlightTexture and btn:GetHighlightTexture() then btn:GetHighlightTexture():SetAlpha(0) end

                local icon = btn:CreateTexture(nil, "ARTWORK")
                icon:SetSize(16, 16)
                icon:SetPoint("LEFT", btn, "LEFT", 4, 0)
                icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                btn.icon = icon

                local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                text:SetPoint("LEFT", icon, "RIGHT", 6, 0)
                text:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
                text:SetJustifyH("LEFT")
                btn.text = text

                if btn.HookScript then
                    btn:HookScript("OnEnter", function(self)
                        if self.SetBackdropColor then self:SetBackdropColor(0.12, 0.16, 0.25, 0.95) end
                        if self.SetBackdropBorderColor then self:SetBackdropBorderColor(0.28, 0.45, 0.70, 0.90) end
                    end)
                    btn:HookScript("OnLeave", function(self)
                        if self.SetBackdropColor then self:SetBackdropColor(0.06, 0.08, 0.12, 0.85) end
                        if self.SetBackdropBorderColor then self:SetBackdropBorderColor(0.15, 0.18, 0.25, 0.70) end
                    end)
                end

                buttons[count] = btn
            end

            btn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
            local tex = (sp.spellID and RF:GetSpellTexture(sp.spellID)) or RF:GetSpellTexture(sp.name) or "Interface\\Icons\\INV_Misc_QuestionMark"
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
    icon:SetTexture("Interface\\Icons\\Spell_ChargeDown")
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
