-- PanelFrame.lua

local ConsoleMenu = _G.ConsoleMenu
local parentFrame
local setItemList

local frameWidth = 440
local viewedItemCount = 3
local sectionHeight = 52
local sectionPadding = 8
local iconSize = sectionHeight - sectionPadding * 2
local titleFontSize = 20
local itemFontSize = 20

local animationDuration = 0.1

local gamePadActive = false
local focusedIndex = 1

local panelTitle = "Панель команд"
local actionBarFirstSlot = 1
local actionBarSlotCount = 12

-- Установка иконки пункту списка
local function SetIcon(frame, data)
    if not frame.icon then
        frame.icon = CreateFrame("Frame", nil, frame)
        frame.icon:SetSize(iconSize, iconSize)
        frame.icon:SetPoint("LEFT", sectionPadding, 0)
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

    frame.icon.texture:SetAllPoints()
    frame.icon.texture:SetTexture(data.texture)
    frame.icon.texture:SetDesaturated(data.isLackingResources or false)
    ApplyMaskToTexture(frame.icon.texture)
    frame.icon.border:Show()
    frame.icon.texture:Show()
end

-- Обновление фокуса
local function UpdateFocus(element, changeFocus)
    if not element then return end
    if InCombatLockdown() then return end

    local frames = parentFrame.ScrollBox:GetFrames()
    for _, frame in ipairs(frames) do
        frame:SetFocused(false)
    end

    focusedIndex = parentFrame.ScrollBox:FindElementDataIndex(element)

    local frame = parentFrame.ScrollBox:FindFrameByPredicate(function(frame, elementData)
        return elementData == element
    end)

    if not frame then return end

    if changeFocus then
        frame:SetFocused(true)
    end

    if gamePadActive then
        parentFrame.ScrollBox:ScrollToElementDataIndex(focusedIndex)
    end

    PanelActiveButton:SetAttribute("type", "action")
    PanelActiveButton:SetAttribute("action", element.id)

    local bindString = "CLICK PanelActiveButton:LeftButton"
    SetOverrideBinding(
        PanelFrame, -- владелец бинда
        true, 
        "PAD1", 
        bindString
    )

end

-- Функция переключения фокуса
local function MoveFocus(delta)
    local newIndex = math.max(1, math.min(focusedIndex + delta, PanelScrollBox:GetDataProviderSize()))
    local element = parentFrame.ScrollBox:GetDataProvider().collection[newIndex]
    UpdateFocus(element, true)
end

-- Создание ScrollBox
local function CreatePanelScrollBox()

    local PanelScrollBox = ConsoleMenuFrame.PanelFrame

    local ScrollBox = CreateFrame("Frame", "PanelScrollBox", PanelScrollBox, "WowScrollBoxList")
    PanelScrollBox.ScrollBox = ScrollBox
    ScrollBox:SetPoint("TOPLEFT", PanelScrollBox, "TOPLEFT", 0, -sectionHeight)
    ScrollBox:SetPoint("BOTTOMRIGHT", PanelScrollBox, "BOTTOMRIGHT", 0, 0)

    local ScrollBar = CreateFrame("EventFrame", "PanelScrollBar", PanelScrollBox, "MinimalScrollBar")
    PanelScrollBox.ScrollBox.ScrollBar = ScrollBar

    ScrollBar:SetPoint("TOPLEFT", ScrollBox, "TOPRIGHT")
    ScrollBar:SetPoint("BOTTOMLEFT", ScrollBox, "BOTTOMRIGHT")

    local DataProvider = CreateDataProvider()
    local ScrollView = CreateScrollBoxListLinearView()

    -- Обновление видимости скролл бара
    local function UpdateScrollBarVisibility()
        local totalHeight = ScrollView:GetExtent() - 1
        if totalHeight <= PanelScrollBox:GetHeight() then
            PanelScrollBar:Hide()
        else
            PanelScrollBar:Show()
        end
    end

    -- Инициализатор для элемента списка
    local function Initializer(frame, data)

        if not data or not frame then return end

        -- Иконка
        if not frame.icon then
            frame.icon = CreateFrame("Frame", nil, frame)
            frame.icon:SetSize(iconSize, iconSize)
            frame.icon:SetPoint("LEFT", sectionPadding, 0)
        end

        SetIcon(frame, data)

        -- Текст
        if not frame.text then
            frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            frame.text:SetPoint("LEFT", frame.icon, "RIGHT", sectionPadding * 1.5, -2)
            frame.text:SetPoint("RIGHT", -sectionPadding, -2)
            frame.text:SetJustifyH("LEFT")
        end

        frame.text:SetFont("Fonts\\FRIZQT___CYR.TTF", itemFontSize, "OUTLINE")
        frame.text:SetText(data.name)
        frame.text:SetTextColor(1, 0.976, 0.855) -- Цвет текста FFF9DA

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

    end

    -- Наполнение списка элементами
    local function SetItemList()
        DataProvider:Flush()

        for i = 0, actionBarSlotCount - 1 do
            local actionID = actionBarFirstSlot + i
            if C_ActionBar.HasAction(actionID) then
                local actionType, identifier = GetActionInfo(actionID)
                local name = ""

                if actionType == "outfit" then
                    local outfitInfo = C_TransmogOutfitInfo.GetOutfitInfo(identifier)
                    name = outfitInfo.name
                elseif actionType == "macro" then
                    local macroName = C_Macro.GetMacroName(identifier)
                    name = macroName or ""
                elseif actionType == "summonmount" then
                    if identifier == 268435455 then
                        name = "Избранный маунт"
                    else
                        name = C_MountJournal.GetMountInfoByID(identifier)
                    end
                elseif actionType == "spell" then
                    name = C_Spell.GetSpellInfo(identifier).name
                elseif actionType == "item" then
                    name = C_Item.GetItemNameByID(identifier)
                elseif actionType == "summonpet" then
                    local _, _, _, _, _, _, _, petName = C_PetJournal.GetPetInfoByPetID(identifier)
                    name = petName
                end

                DataProvider:Insert({
                    id = actionID,
                    type = "action",
                    name = name,
                    texture = C_ActionBar.GetActionTexture(actionID),
                })
            end
        end

        UpdateScrollBarVisibility()
    end

    ScrollView:SetElementExtent(sectionHeight)
    ScrollView:SetElementInitializer("Button", Initializer, "SecureActionButtonTemplate")

    ScrollUtil.InitScrollBoxListWithScrollBar(ScrollBox, ScrollBar, ScrollView)
    ScrollBox:SetDataProvider(DataProvider)

    PanelScrollBox:Hide()

    return PanelScrollBox, SetItemList
end

-- Функция предзагрузки данных
local function PreloadData()

end

function ConsoleMenu:SetPanelFrame()
    PreloadData()

    if ConsoleMenuFrame.PanelFrame then
        return
    end

    local PanelFrame = CreateFrame("Frame", "PanelFrame", ConsoleMenuFrame)
    ConsoleMenuFrame.PanelFrame = PanelFrame
    ConsoleMenu:InitFadeAnimations(PanelFrame, animationDuration)

    PanelFrame:SetSize(frameWidth, sectionHeight * (viewedItemCount + 1))
    PanelFrame:SetPoint("BOTTOMLEFT", ConsoleMenuFrame, "BOTTOMLEFT", 48, 48)

    PanelFrame.Background = PanelFrame:CreateTexture(nil, "BACKGROUND")
    PanelFrame.Background:SetWidth(800)
    PanelFrame.Background:SetHeight(400)
    PanelFrame.Background:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -290, -40)
    PanelFrame.Background:SetAtlas("MapCornerShadow-Right")
    PanelFrame.Background:SetTexCoord(1, 0, 0, 1) -- Отразить по горизонтали
    PanelFrame.Background:SetAlpha(0.85)
    
    -- Включаем обработку клавиатуры для ESC
    PanelFrame:EnableKeyboard(true)
    PanelFrame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            ConsoleMenu:AnimatedHide(self)
        end
    end)

    PanelFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Начало боя
    PanelFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player") -- Игрок начал каст
    PanelFrame:RegisterUnitEvent("UNIT_SPELLCAST_SENT", "player") -- Игрок отправил каст
    PanelFrame:RegisterEvent("GAME_PAD_ACTIVE_CHANGED") -- Событие изменения режима геймпада
    PanelFrame:RegisterEvent("TRANSMOG_DISPLAYED_OUTFIT_CHANGED") -- Событие изменения отображаемого наряда
    PanelFrame:RegisterEvent("COMPANION_UPDATE") -- Событие изменения питомца

    PanelFrame:SetScript("OnEvent", function(self, event, ...)
        local unit = ...

        if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_SENT" then
            if unit ~= "player" then
                return
            end
        end

        if event == "GAME_PAD_ACTIVE_CHANGED" then
            gamePadActive = unit
            return
        end

        if event == "COMPANION_UPDATE" then
            if unit ~= "CRITTER" then
                return
            end
        end

        if PanelFrame:IsShown() then
            PanelFrame:Hide()
        end
    end)

    -- Создаем заголовок
    PanelFrame.Title = CreateFrame("Frame", "PanelFrameTitle", PanelFrame)
    PanelFrame.Title:SetPoint("TOPLEFT", PanelFrame, "TOPLEFT", 0, 0)
    PanelFrame.Title:SetPoint("TOPRIGHT", PanelFrame, "TOPRIGHT", 0, 0)
    PanelFrame.Title:SetHeight(sectionHeight)

    PanelFrame.Title.Text = PanelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    PanelFrame.Title.Text:SetPoint("LEFT", PanelFrameTitle, "LEFT", sectionPadding, 0)
    PanelFrame.Title.Text:SetPoint("RIGHT", PanelFrameTitle, "RIGHT", sectionPadding, 0)
    PanelFrame.Title.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", titleFontSize, "")
    PanelFrame.Title.Text:SetTextColor(1.0, 0.960784, 0.772549, 0.6)
    PanelFrame.Title.Text:SetText(panelTitle)
    PanelFrame.Title.Text:SetJustifyH("LEFT")

    -- Создаём ScrollBox
    parentFrame, setItemList = CreatePanelScrollBox()


    PanelFrame.SecureActionButton = CreateFrame("Button", "PanelActiveButton", PanelFrame, "SecureActionButtonTemplate")
    PanelFrame.SecureActionButton:SetAttribute("useOnKeyDown", false)
    PanelFrame.SecureActionButton:RegisterForClicks("AnyUp", "AnyDown")
    PanelFrame.SecureActionButton:SetAllPoints()

    -- Создаём «невидимые» кнопки для перемещения фокуса и скрытия окна:
    local focusUpButton = CreateFrame("Button", "PanelFocusUpButton", parentFrame)
    focusUpButton:SetSize(1,1)  -- крошечная, невидимая
    focusUpButton:SetPoint("TOPLEFT", parentFrame, "TOPLEFT")
    focusUpButton:SetScript("OnClick", function()
        MoveFocus(-1)
    end)

    local focusDownButton = CreateFrame("Button", "PanelFocusDownButton", parentFrame)
    focusDownButton:SetSize(1,1)
    focusDownButton:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 20)
    focusDownButton:SetScript("OnClick", function()
        MoveFocus(1)
    end)

    local hideButton = CreateFrame("Button", "PanelHideButton", parentFrame)
    hideButton:SetSize(1,1)
    hideButton:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 40)
    hideButton:SetScript("OnClick", function()
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.PanelFrame)
    end)

    -- Вешаем бинды, когда окно показывается:
    parentFrame:HookScript("OnShow", function()
        
        -- Привязываем PADDUP к клику по PanelFocusUpButton
        SetOverrideBindingClick(focusUpButton, true, "PADDUP", "PanelFocusUpButton", "LeftButton")
        -- Привязываем PADDDOWN к клику по PanelFocusDownButton
        SetOverrideBindingClick(focusDownButton, true, "PADDDOWN", "PanelFocusDownButton", "LeftButton")

        -- Привязываем PAD2 к клику по PanelHideButton (чтобы закрывать окно)
        SetOverrideBindingClick(hideButton, true, "PAD2", "PanelHideButton", "LeftButton")

        local firstElement = parentFrame.ScrollBox:GetDataProvider().collection[1]
        if firstElement then
            UpdateFocus(firstElement, true)
        end

    end)

    -- Очищаем бинды, когда окно скрывается:
    parentFrame:HookScript("OnHide", function()

        if InCombatLockdown() then return end
        
        ClearOverrideBindings(parentFrame)
        ClearOverrideBindings(focusUpButton)
        ClearOverrideBindings(focusDownButton)
        ClearOverrideBindings(hideButton)

        ConsoleMenu:DeleteKeysFrameItem("PAD1", "Выбрать")
        ConsoleMenu:DeleteKeysFrameItem("PAD2", "Выйти")

        ConsoleMenu:RemoveWindow("panel")
        ConsoleMenu:ApplyContextUIChanges()

    end)
    
end

-- Разбор аргументов: заголовок, первый слот, количество слотов
-- Пример: /panel Наряды 145 12
-- Заголовок может содержать пробелы — последние два токена должны быть числами
local function ParsePanelSlashArgs(msg)
    local title = panelTitle
    local firstSlot = actionBarFirstSlot
    local slotCount = actionBarSlotCount

    if not msg or msg:match("^%s*$") then
        return title, firstSlot, slotCount
    end

    local parts = { strsplit(" ", strtrim(msg)) }
    local partCount = #parts

    if partCount >= 3 then
        local count = tonumber(parts[partCount])
        local first = tonumber(parts[partCount - 1])
        if count and first then
            slotCount = count
            firstSlot = first
            local titleParts = {}
            for i = 1, partCount - 2 do
                titleParts[#titleParts + 1] = parts[i]
            end
            if #titleParts > 0 then
                title = table.concat(titleParts, " ")
            end
        elseif partCount >= 1 then
            title = table.concat(parts, " ")
        end
    elseif partCount == 2 then
        local first = tonumber(parts[2])
        if first then
            firstSlot = first
            title = parts[1]
        else
            title = table.concat(parts, " ")
        end
    elseif partCount == 1 then
        local first = tonumber(parts[1])
        if first then
            firstSlot = first
        else
            title = parts[1]
        end
    end

    return title, firstSlot, slotCount
end

-- Слеш-команда: /panel <заголовок> <первый_слот> <количество_слотов>
-- Пример: /panel Наряды 145 12
SLASH_PANEL1 = "/panel"
SlashCmdList["PANEL"] = function(msg)
    if parentFrame and parentFrame:IsShown() then
        return
    end

    panelTitle, actionBarFirstSlot, actionBarSlotCount = ParsePanelSlashArgs(msg)

    if not parentFrame then
        ConsoleMenu:SetPanelFrame()
    end

    if parentFrame then
        if ConsoleMenuFrame.PanelFrame.Title and ConsoleMenuFrame.PanelFrame.Title.Text then
            ConsoleMenuFrame.PanelFrame.Title.Text:SetText(panelTitle)
        end
        setItemList()
        ConsoleMenu:AnimatedShow(ConsoleMenuFrame.PanelFrame)
        ConsoleMenu:AddWindow("panel")
        ConsoleMenu:ApplyContextUIChanges()
    end
end