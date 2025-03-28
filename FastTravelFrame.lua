local ConsoleMenu = LibStub("AceAddon-3.0"):GetAddon("ConsoleMenu")
local parentFrame
local frames = {}
local focusedIndex = 1

-- Установка иконки пункту списка
local function setIcon(frame, data)
    if not frame.icon then
        frame.icon = CreateFrame("Frame", nil, frame)
        frame.icon:SetSize(32, 32)
        frame.icon:SetPoint("LEFT", 10, 0)
    end

    if not frame.icon.texture then
        frame.icon.texture = frame.icon:CreateTexture(nil, "ARTWORK")
        frame.icon.texture:Hide()
    end

    if not frame.icon.border then
        frame.icon.border = frame.icon:CreateTexture(nil, "OVERLAY")
        frame.icon.border:SetPoint("TOPLEFT", frame.icon.texture, "TOPLEFT", -6, 6)
        frame.icon.border:SetPoint("BOTTOMRIGHT", frame.icon.texture, "BOTTOMRIGHT", 6, -6)
        frame.icon.border:SetAtlas("plunderstorm-actionbar-slot-border")
        frame.icon.border:Hide()
    else
        frame.icon.border:Hide()
    end

    if data.type == "stone" then
        frame.icon.texture:SetAllPoints()
        frame.icon.texture:SetTexture(data.texture)
        ApplyMaskToTexture(frame.icon.texture)
        frame.icon.border:Show()
        frame.icon.texture:Show()
    else
        frame.icon.texture:Hide()
    end
end

-- Создание ScrollBox
local function CreateFastTravelScrollBox()
    local FastTravelScrollBox = CreateFrame("Frame", "FastTravelScroll", UIParent)
    FastTravelScrollBox:SetSize(480, 48 * 3)
    FastTravelScrollBox:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 48, 96)

    local ScrollBox = CreateFrame("Frame", "FastTravelScrollBox", FastTravelScrollBox, "WowScrollBoxList")
    FastTravelScrollBox.ScrollBox = ScrollBox
    ScrollBox:SetPoint("TOPLEFT", FastTravelScrollBox, "TOPLEFT", 0, 0)
    ScrollBox:SetAllPoints()

    local ScrollBar = CreateFrame("EventFrame", "FastTravelScrollBar", FastTravelScrollBox, "MinimalScrollBar")
    FastTravelScrollBox.ScrollBox.ScrollBar = ScrollBar

    ScrollBar:SetPoint("TOPLEFT", ScrollBox, "TOPRIGHT")
    ScrollBar:SetPoint("BOTTOMLEFT", ScrollBox, "BOTTOMRIGHT")

    local DataProvider = CreateDataProvider()
    local ScrollView = CreateScrollBoxListLinearView()
    ScrollView:SetDataProvider(DataProvider)
    ScrollUtil.InitScrollBoxListWithScrollBar(ScrollBox, ScrollBar, ScrollView)

    local function UpdateScrollBarVisibility()
        local totalHeight = ScrollView:GetElementExtent() * DataProvider:GetSize() - 1
        if totalHeight <= FastTravelScrollBox:GetHeight() then
            FastTravelScrollBar:Hide()
        else
            FastTravelScrollBar:Show()
        end
    end

    -- Обновление фокуса
    local function UpdateFocus(newIndex)
        -- Сброс фокуса для всех элементов
        for _, frame in ipairs(frames) do
            if frame and frame.SetFocused then
                frame:SetFocused(false)
            end
        end

        focusedIndex = newIndex
        
        if frames[focusedIndex] then
            frames[focusedIndex]:SetFocused(true)

            -- Прокрутить ScrollBox до текущего элемента
            parentFrame.ScrollBox:ScrollToElementDataIndex(newIndex)

            -- Устанавливаем бинд: при нажатии PAD1 будет использоваться предмет, 
            -- соответствующий текущему элементу (через SetOverrideBindingItem)
            local item = frames[focusedIndex]:GetData()
            SetOverrideBindingItem(
                FastTravelScrollBox, -- владелец бинда
                true, 
                "PAD1", 
                item.name
            )
        end
    end

    -- Инициализатор для элемента списка
    local function Initializer(frame, data)
        table.insert(frames, frame)

        local hearthstoneButton = CreateFrame("Button", nil, frame, "SecureActionButtonTemplate")
        frame.SecureActionButton = hearthstoneButton

        hearthstoneButton:SetSize(64, 64)
        hearthstoneButton:SetPoint("CENTER", 0, 0)
        hearthstoneButton:RegisterForClicks("AnyDown")

        hearthstoneButton:SetAttribute("type1", "item")
        hearthstoneButton:SetAttribute("item1", data.name)

        local texture = hearthstoneButton:CreateTexture(nil, "BACKGROUND")
        texture:SetAllPoints(hearthstoneButton)
        texture:SetTexture(data.texture)

        -- Тень (фон)
        if not frame.bg then
            frame.bg = frame:CreateTexture(nil, "BACKGROUND")
            frame.bg:SetAllPoints()
            frame.bg:SetAtlas("Garr_BuildingInfoShadow")
            frame.bg:Hide()
        end

        function frame:SetFocused(isFocused)
            if isFocused then
                frame.bg:Show()
            else
                frame.bg:Hide()
            end
        end

        -- Сохраняем данные, чтобы потом получить их через frame:GetData()
        frame.data = data
        function frame:GetData()
            return self.data
        end
    end

    ScrollView:SetElementExtent(48)
    ScrollView:SetElementInitializer("Button", Initializer, "SecureActionButtonTemplate")

    DataProvider:Flush()
    frames = {}

    local itemInfo = 6948
    local itemName, _, _, _, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(itemInfo)
    DataProvider:Insert({
        id = itemInfo,
        type = "stone",
        name = itemName or "Камень возвращения",
        texture = itemTexture,
    })

    DataProvider:Insert({
        type = "stone",
        name = "stone1",
        texture = "Interface\\Icons\\INV_Misc_Rune_01",
    })

    DataProvider:Insert({
        type = "stone",
        name = "stone2",
        texture = "Interface\\Icons\\INV_Misc_Rune_01",
    })

    UpdateScrollBarVisibility()

    FastTravelScrollBox:Hide()
    return FastTravelScrollBox, UpdateFocus
end

-- Функция переключения фокуса
local function MoveFocus(delta)
    local newIndex = math.max(1, math.min(focusedIndex + delta, #frames))
    updateFocus(newIndex)
end

function ConsoleMenu:SetFastTravelFrame()
    parentFrame, updateFocus = CreateFastTravelScrollBox()

    -- Создаём «невидимые» кнопки для перемещения фокуса и скрытия окна:
    local focusUpButton = CreateFrame("Button", "FocusUpButton", parentFrame)
    focusUpButton:SetSize(1,1)  -- крошечная, невидимая
    focusUpButton:SetPoint("TOPLEFT", parentFrame, "TOPLEFT")
    focusUpButton:SetScript("OnClick", function()
        MoveFocus(-1)
    end)

    local focusDownButton = CreateFrame("Button", "FocusDownButton", parentFrame)
    focusDownButton:SetSize(1,1)
    focusDownButton:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 20)
    focusDownButton:SetScript("OnClick", function()
        MoveFocus(1)
    end)

    local hideButton = CreateFrame("Button", "FastTravelHideButton", parentFrame)
    hideButton:SetSize(1,1)
    hideButton:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 40)
    hideButton:SetScript("OnClick", function()
        parentFrame:Hide()
    end)

    -- Вешаем бинды, когда окно показывается:
    parentFrame:HookScript("OnShow", function()
        -- Привязываем PADDUP к клику по FocusUpButton
        SetOverrideBindingClick(parentFrame, true, "PADDUP", "FocusUpButton", "LeftButton")
        -- Привязываем PADDDOWN к клику по FocusDownButton
        SetOverrideBindingClick(parentFrame, true, "PADDDOWN", "FocusDownButton", "LeftButton")
        -- Привязываем PAD2 к клику по FastTravelHideButton (чтобы закрывать окно)
        SetOverrideBindingClick(parentFrame, true, "PAD2", "FastTravelHideButton", "LeftButton")

        -- Устанавливаем фокус на первый элемент (по желанию)
        if updateFocus then
            updateFocus(1)
        end
    end)

    -- Очищаем бинды, когда окно скрывается:
    parentFrame:HookScript("OnHide", function()
        ClearOverrideBindings(parentFrame)
    end)
end

-- Слеш-команда
SLASH_FASTTRAVEL1 = "/fasttravel"
SlashCmdList["FASTTRAVEL"] = function()
    if parentFrame and parentFrame:IsShown() then
        print("FastTravel уже открыт.")
        return
    end

    if not parentFrame or not updateFocus then
        ConsoleMenu:SetFastTravelFrame()
    end

    if parentFrame then
        parentFrame:Show()
    end
end
