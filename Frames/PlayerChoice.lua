function ConsoleMenu:SetPlayerChoice()
    local function Log(message)
        print("[ConsoleMenu][PlayerChoice] " .. tostring(message))
    end

    local frameWidth = 440
    local viewedItemCount = 3
    local sectionHeight = 52
    local titleSectionHeight = sectionHeight
    local sectionPadding = 8
    local iconSize = sectionHeight - sectionPadding * 2
    local frameAnchorX = 48
    local frameAnchorY = 48
    local titleFontSize = 20
    local itemFontSize = 20
    local itemTextYOffset = -2

    local animationDuration = 0.1

    local hiddenButtonSize = 1
    local hiddenButtonStepY = 20

    local function GetChoiceInfo()
        local choiceInfo = C_PlayerChoice.GetCurrentPlayerChoiceInfo()
        if choiceInfo then
            return choiceInfo
        end
        if C_PlayerChoice.GetPlayerChoiceInfo then
            return C_PlayerChoice.GetPlayerChoiceInfo()
        end
    end

    local function CollectChoiceButtons(choiceInfo)
        local list = {}
        if not choiceInfo or not choiceInfo.options then
            return list
        end

        local multiOptionMode = #choiceInfo.options > 1

        for _, option in ipairs(choiceInfo.options) do
            if option.buttons and #option.buttons > 0 then
                for _, buttonInfo in ipairs(option.buttons) do
                    local itemText
                    if multiOptionMode then
                        itemText = option.header or buttonInfo.text or ("Option " .. tostring(option.id))
                    else
                        itemText = buttonInfo.text or option.header or ("Option " .. tostring(option.id))
                    end

                    list[#list + 1] = {
                        id = buttonInfo.id,
                        text = itemText,
                        disabled = buttonInfo.disabled or option.disabledOption,
                        selected = buttonInfo.selected,
                    }
                end
            end
        end

        return list
    end

    if not self.PlayerChoiceBindingFrame then
        local frame = CreateFrame("Frame", "ConsoleMenuPlayerChoiceBindingFrame", ConsoleMenuFrame)
        self.PlayerChoiceBindingFrame = frame
    end
    local bindingFrame = self.PlayerChoiceBindingFrame

    if not bindingFrame.ListFrame then
        local listFrame = CreateFrame("Frame", "ConsoleMenuPlayerChoiceListFrame", ConsoleMenuFrame)
        bindingFrame.ListFrame = listFrame
        listFrame:SetSize(frameWidth, sectionHeight * viewedItemCount + titleSectionHeight)
        listFrame:SetPoint("BOTTOMLEFT", ConsoleMenuFrame, "BOTTOMLEFT", frameAnchorX, frameAnchorY)
        listFrame:Hide()

        listFrame.Background = listFrame:CreateTexture(nil, "BACKGROUND")
        listFrame.Background:SetWidth(800)
        listFrame.Background:SetHeight(400)
        listFrame.Background:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -290, -40)
        listFrame.Background:SetAtlas("MapCornerShadow-Right")
        listFrame.Background:SetTexCoord(1, 0, 0, 1)
        listFrame.Background:SetAlpha(0.85)

        -- Title layout mirrors PanelFrame title geometry/style.
        listFrame.Title = CreateFrame("Frame", "ConsoleMenuPlayerChoiceTitle", listFrame)
        listFrame.Title:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 0, 0)
        listFrame.Title:SetPoint("TOPRIGHT", listFrame, "TOPRIGHT", 0, 0)
        listFrame.Title:SetHeight(titleSectionHeight)

        listFrame.Title.Text = listFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        listFrame.Title.Text:SetPoint("LEFT", listFrame.Title, "LEFT", sectionPadding, 0)
        listFrame.Title.Text:SetPoint("RIGHT", listFrame.Title, "RIGHT", -sectionPadding, 0)
        listFrame.Title.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", titleFontSize, "")
        listFrame.Title.Text:SetJustifyH("LEFT")
        listFrame.Title.Text:SetTextColor(1.0, 0.960784, 0.772549, 0.6)
        listFrame.Title.Text:SetShadowOffset(1, -1)
        listFrame.Title.Text:SetShadowColor(0, 0, 0, 1)

        local scrollBox = CreateFrame("Frame", "ConsoleMenuPlayerChoiceScrollBox", listFrame, "WowScrollBoxList")
        listFrame.ScrollBox = scrollBox
        scrollBox:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 0, -titleSectionHeight)
        scrollBox:SetPoint("BOTTOMRIGHT", listFrame, "BOTTOMRIGHT", 0, 0)

        local scrollBar = CreateFrame("EventFrame", "ConsoleMenuPlayerChoiceScrollBar", listFrame, "MinimalScrollBar")
        listFrame.ScrollBar = scrollBar
        scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT")
        scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT")

        local dataProvider = CreateDataProvider()
        listFrame.DataProvider = dataProvider
        local scrollView = CreateScrollBoxListLinearView()

        local function UpdateScrollBarVisibility()
            local totalHeight = scrollView:GetExtent() - 1
            if totalHeight <= listFrame.ScrollBox:GetHeight() then
                listFrame.ScrollBar:Hide()
            else
                listFrame.ScrollBar:Show()
            end
        end

        local function Initializer(frame, data)
            if not frame.text then
                frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                frame.text:SetPoint("LEFT", frame, "LEFT", sectionPadding, itemTextYOffset)
                frame.text:SetPoint("RIGHT", frame, "RIGHT", -sectionPadding, itemTextYOffset)
                frame.text:SetJustifyH("LEFT")
            end

            if not frame.bg then
                frame.bg = frame:CreateTexture(nil, "BACKGROUND")
                frame.bg:SetAllPoints()
                frame.bg:SetAtlas("Garr_BuildingInfoShadow")
                frame.bg:Hide()
            end

            frame.text:SetFont("Fonts\\FRIZQT___CYR.TTF", itemFontSize, "OUTLINE")
            frame.text:SetText(data.text)

            if data.disabled then
                frame.text:SetTextColor(0.55, 0.55, 0.55)
            else
                frame.text:SetTextColor(1, 0.976, 0.855)
            end

            function frame:SetFocused(isFocused)
                if isFocused then
                    frame.bg:Show()
                else
                    frame.bg:Hide()
                end
            end

            frame:SetFocused(data.focused == true)
        end

        scrollView:SetElementExtent(sectionHeight)
        scrollView:SetElementInitializer("Button", Initializer)
        ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)
        scrollBox:SetDataProvider(dataProvider)

        -- Navigation buttons in PanelFrame style.
        local focusUpButton = CreateFrame("Button", "PlayerChoiceFocusUpButton", listFrame)
        focusUpButton:SetSize(hiddenButtonSize, hiddenButtonSize)
        focusUpButton:SetPoint("TOPLEFT", listFrame, "TOPLEFT")

        local focusDownButton = CreateFrame("Button", "PlayerChoiceFocusDownButton", listFrame)
        focusDownButton:SetSize(hiddenButtonSize, hiddenButtonSize)
        focusDownButton:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 0, hiddenButtonStepY)

        local selectButton = CreateFrame("Button", "PlayerChoiceSelectButton", listFrame)
        selectButton:SetSize(hiddenButtonSize, hiddenButtonSize)
        selectButton:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 0, hiddenButtonStepY * 2)

        local function ClearFocus()
            local collection = dataProvider.collection or {}
            for i = 1, #collection do
                collection[i].focused = false
            end
        end

        local function GetFocusedIndex()
            local collection = dataProvider.collection or {}
            for i = 1, #collection do
                if collection[i].focused then
                    return i
                end
            end
            return #collection > 0 and 1 or nil
        end

        local function UpdateFocus(index)
            local collection = dataProvider.collection or {}
            if #collection == 0 then
                return
            end

            if index < 1 then
                index = 1
            elseif index > #collection then
                index = #collection
            end

            ClearFocus()
            collection[index].focused = true

            local frames = scrollBox:GetFrames()
            for _, frame in ipairs(frames) do
                frame:SetFocused(false)
            end

            local element = collection[index]
            local frame = scrollBox:FindFrameByPredicate(function(_, elementData)
                return elementData == element
            end)
            if frame then
                frame:SetFocused(true)
            end

            scrollBox:ScrollToElementDataIndex(index)
        end

        local function MoveFocus(delta)
            local currentIndex = GetFocusedIndex()
            if not currentIndex then
                return
            end
            UpdateFocus(currentIndex + delta)
        end

        local function SelectFocused()
            local currentIndex = GetFocusedIndex()
            if not currentIndex then
                Log("No focused element")
                return
            end

            local data = dataProvider.collection[currentIndex]
            if not data or not data.id then
                Log("Focused element has no response id")
                return
            end

            if data.disabled then
                Log("Focused element is disabled")
                return
            end

            Log("Send response id=" .. tostring(data.id) .. ", index=" .. tostring(currentIndex) .. ", text=" .. tostring(data.text))
            C_PlayerChoice.SendPlayerChoiceResponse(data.id)
            listFrame:Hide()
            if _G.PlayerChoiceFrame then
                HideUIPanel(_G.PlayerChoiceFrame)
            end
        end

        focusUpButton:SetScript("OnClick", function()
            MoveFocus(-1)
        end)
        focusDownButton:SetScript("OnClick", function()
            MoveFocus(1)
        end)
        selectButton:SetScript("OnClick", function()
            SelectFocused()
        end)

        listFrame:HookScript("OnShow", function()
            ConsoleMenu:AddWindow("playerchoice")
            ConsoleMenu:ApplyContextUIChanges()

            SetOverrideBindingClick(listFrame, true, "PADDUP", "PlayerChoiceFocusUpButton", "LeftButton")
            SetOverrideBindingClick(listFrame, true, "PADDDOWN", "PlayerChoiceFocusDownButton", "LeftButton")
            SetOverrideBindingClick(listFrame, true, "PAD1", "PlayerChoiceSelectButton", "LeftButton")
            SetOverrideBindingClick(listFrame, true, "PAD2", "PlayerChoiceSelectButton", "RightButton")
        end)

        listFrame:HookScript("OnHide", function()
            ConsoleMenu:RemoveWindow("playerchoice")
            ConsoleMenu:ApplyContextUIChanges()

            if InCombatLockdown() then return end
            ClearOverrideBindings(listFrame)
        end)

        -- Right click / PAD2 closes list only.
        selectButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        selectButton:SetScript("OnClick", function(_, button)
            if button == "RightButton" then
                listFrame:Hide()
                if _G.PlayerChoiceFrame then
                    HideUIPanel(_G.PlayerChoiceFrame)
                end
                return
            end
            SelectFocused()
        end)

        listFrame.SetChoiceList = function(_, choiceInfo)
            dataProvider:Flush()

            local buttons = CollectChoiceButtons(choiceInfo)
            for i = 1, #buttons do
                dataProvider:Insert({
                    id = buttons[i].id,
                    text = buttons[i].text,
                    disabled = buttons[i].disabled,
                    focused = false,
                    selected = buttons[i].selected,
                })
            end

            if #buttons == 0 then
                listFrame:Hide()
                return
            end

            local initialFocus = 1
            for i = 1, #buttons do
                if buttons[i].selected and not buttons[i].disabled then
                    initialFocus = i
                    break
                end
            end

            UpdateFocus(initialFocus)
            UpdateScrollBarVisibility()
            listFrame:Show()
        end

        listFrame.UpdateLayout = function(_, isMultiOptionMode)
            local currentTitleHeight = titleSectionHeight
            listFrame.Title:Show()
            listFrame.Title:SetHeight(currentTitleHeight)
            listFrame:SetHeight(sectionHeight * viewedItemCount + currentTitleHeight)
            scrollBox:ClearAllPoints()
            scrollBox:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 0, -currentTitleHeight)
            scrollBox:SetPoint("BOTTOMRIGHT", listFrame, "BOTTOMRIGHT", 0, 0)
            UpdateScrollBarVisibility()
        end
    end

    local listFrame = bindingFrame.ListFrame

    local function UpdatePlayerChoiceList()
        if InCombatLockdown() then
            return
        end

        local choiceInfo = GetChoiceInfo()
        if not choiceInfo or not choiceInfo.options then
            listFrame:Hide()
            return
        end

        listFrame:UpdateLayout(#choiceInfo.options > 1)
        listFrame.Title.Text:SetText(choiceInfo.questionText or "Выбор")
        listFrame:SetChoiceList(choiceInfo)
        Log("Updated list for choiceID=" .. tostring(choiceInfo.choiceID))
    end

    self:RegisterEvent("PLAYER_CHOICE_UPDATE", function()
        if PlayerChoiceFrame then
            local choiceInfo = GetChoiceInfo()
            local isMultiOptionMode = choiceInfo and choiceInfo.options and #choiceInfo.options > 1
            PlayerChoiceFrame:SetAlpha(isMultiOptionMode and 1 or 0)
        end
        C_Timer.After(animationDuration, function()
            UpdatePlayerChoiceList()
        end)
    end)

    self:RegisterEvent("PLAYER_CHOICE_CLOSE", function()
        listFrame:Hide()
    end)
end
