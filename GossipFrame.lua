local ConsoleMenu = LibStub("AceAddon-3.0"):GetAddon("ConsoleMenu")
local parentFrame
local frames = {} -- Хранение всех созданных элементов
local focusedIndex = 1 -- Индекс текущего элемента в фокусе

local function setIcon(frame, data)
    if not frame.icon.texture then
        frame.icon.texture = frame.icon:CreateTexture(nil, "ARTWORK")
    end

    if data.type == "gossip" then
        print("file: " .. data.icon)
        if data.icon == 132053 then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -2, 4)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -2, 4)
            frame.icon.texture:SetAtlas("crosshair_speak_128")
        elseif data.icon == 136458 then
            frame.icon.texture:SetAllPoints()
            frame.icon.texture:SetAtlas("Crosshair_innkeeper_128")
        elseif data.icon == 132060 then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -2, 2)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -2, 0)
            frame.icon.texture:SetAtlas("Crosshair_pickup_128")
        elseif data.icon == 1673939 then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -2, 0)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -2, 0)
            frame.icon.texture:SetAtlas("Crosshair_Transmogrify_128")
        elseif data.icon == 132057 then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", 0, 4)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", 0, 4)
            frame.icon.texture:SetAtlas("Crosshair_Taxi_128")
        end
    elseif data.type == "availableQuest" then
        print("quest classification: " .. C_QuestInfoSystem.GetQuestClassification(data.questID))

        local classification = C_QuestInfoSystem.GetQuestClassification(data.questID)
        if classification == 1 then
        elseif classification == 4 then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -1, 2)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -1, 2)
            frame.icon.texture:SetAtlas("Crosshair_Wrapper_128")
        elseif classification == 7 then
            frame.icon.texture:SetAllPoints()
            frame.icon.texture:SetAtlas("Crosshair_Quest_128")
        end

    elseif data.type == "activeQuest" then
    elseif data.type == "goodbye" then
        frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -2, 2)
        frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -2, 2)
        frame.icon.texture:SetAtlas("crosshair_speak_128")
    else
        print("Unknown data type:", data.type)
    end
end

local function CreateGossipScrollBox()
    -- Главный фрейм
    local GossipScrollBox = CreateFrame("Frame", "GossipScroll", UIParent)
    GossipScrollBox:SetSize(640, 48*3)
    GossipScrollBox:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 96)
    
    -- Создаем ScrollBox
    local ScrollBox = CreateFrame("Frame", "GossipScrollBox", GossipScrollBox, "WowScrollBoxList")
    GossipScrollBox.ScrollBox = ScrollBox
    ScrollBox:SetPoint("TOPLEFT", GossipScrollBox, "TOPLEFT", 0, 0)
    ScrollBox:SetAllPoints()

    -- Создаем ScrollBar
    local ScrollBar = CreateFrame("EventFrame", "GossipScrollBar", GossipScrollBox, "MinimalScrollBar")
    GossipScrollBox.ScrollBox.ScrollBar = ScrollBar

    ScrollBar:SetPoint("TOPLEFT", ScrollBox, "TOPRIGHT")
    ScrollBar:SetPoint("BOTTOMLEFT", ScrollBox, "BOTTOMRIGHT")

    -- Создаем DataProvider и ScrollView
    local DataProvider = CreateDataProvider()
    local ScrollView = CreateScrollBoxListLinearView()
    ScrollView:SetDataProvider(DataProvider)

    -- Инициализируем ScrollBox с ScrollBar
    ScrollUtil.InitScrollBoxListWithScrollBar(ScrollBox, ScrollBar, ScrollView)

    -- Кастомный инициализатор
    local function Initializer(frame, data)
        table.insert(frames, frame) -- Добавляем элемент в массив

        -- Иконка
        if not frame.icon then
            frame.icon = CreateFrame("Frame", nil, frame)
            frame.icon:SetSize(32, 32)
            frame.icon:SetPoint("LEFT", 10, 0)
        end
        setIcon(frame, data)

        -- Текст
        if not frame.text then
            frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            frame.text:SetPoint("LEFT", frame.icon, "RIGHT", 10, 0)
            frame.text:SetPoint("RIGHT", -10, 0)
            frame.text:SetJustifyH("LEFT")
        end

        frame.text:SetFont("Fonts\\FRIZQT___CYR.TTF", 20, "OUTLINE")
        frame.text:SetText(data.name)
        frame.text:SetTextColor(1, 0.976, 0.855) -- Цвет текста FFF9DA

        -- Тень (фон)
        if not frame.bg then
            frame.bg = frame:CreateTexture(nil, "BACKGROUND")
            frame.bg:SetAllPoints()
            frame.bg:SetAtlas("Garr_BuildingInfoShadow") -- Прозрачный фон при наведении
            frame.bg:Hide() -- Скрываем фон по умолчанию
        end

        -- Обновление фокуса
        function frame:SetFocused(isFocused)
            if isFocused then
                frame.text:SetTextColor(1, 0.768, 0.071) -- Цвет текста FFC412
                frame.bg:Show() -- Показываем тень
            else
                frame.text:SetTextColor(1, 0.976, 0.855) -- Цвет текста FFF9DA
                frame.bg:Hide() -- Скрываем тень
            end
        end

        function frame:SelectOption()
            if data.type == "gossip" then
                C_GossipInfo.SelectOption(data.gossipOptionID)
            elseif data.type == "availableQuest" then
                C_GossipInfo.SelectAvailableQuest(data.questID)
            elseif data.type == "activeQuest" then
                C_GossipInfo.SelectActiveQuest(data.questID)
            elseif data.type == "goodbye" then
                C_GossipInfo.CloseGossip()
            else
                print("Unknown data type:", data.type)
            end
        end

        -- -- Фокус (изменение подложки при наведении)
        -- frame:SetScript("OnEnter", function()
        --     frame:SetFocused(true)
        -- end)
        -- frame:SetScript("OnLeave", function()
        --     frame:SetFocused(false)
        -- end)

        frame:SetScript("OnMouseDown", function()
            frame:SelectOption()
        end)

    end

    -- Устанавливаем кастомный элемент как шаблон
    ScrollView:SetElementExtent(48)
    ScrollView:SetElementInitializer("Frame", Initializer)

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

            -- Смещаем скролл до текущего элемента
            parentFrame.ScrollBox:ScrollToElementDataIndex(newIndex)
        end
    end

    -- Обработка событий GOSSIP_SHOW и GOSSIP_CLOSED
    local EventFrame = CreateFrame("Frame", nil, GossipScrollBox)
    EventFrame:RegisterEvent("GOSSIP_SHOW")
    EventFrame:RegisterEvent("GOSSIP_CLOSED")

    EventFrame:SetScript("OnEvent", function(self, event)
        if event == "GOSSIP_SHOW" then
            -- Получаем данные госсипа
            local options = C_GossipInfo.GetOptions()
            local activeQuests = C_GossipInfo.GetActiveQuests()
            local availableQuests = C_GossipInfo.GetAvailableQuests()

            -- Очищаем DataProvider и добавляем новые данные
            DataProvider:Flush()
            frames = {} -- Сбрасываем список фреймов

            -- Добавляем активные квесты
            for _, quest in ipairs(activeQuests) do
                DataProvider:Insert({
                    type = "activeQuest",
                    name = quest.title,
                    questLevel = quest.questLevel,
                    isTrivial = quest.isTrivial,
                    frequency = quest.frequency,
                    repeatable = quest.repeatable,
                    isComplete = quest.isComplete,
                    isLegendary = quest.isLegendary,
                    isIgnored = quest.isIgnored,
                    questID = quest.questID
                })
            end

            -- Добавляем доступные квесты
            for _, quest in ipairs(availableQuests) do
                DataProvider:Insert({
                    type = "availableQuest",
                    name = quest.title,
                    questLevel = quest.questLevel,
                    isTrivial = quest.isTrivial,
                    frequency = quest.frequency,
                    repeatable = quest.repeatable,
                    isComplete = quest.isComplete,
                    isLegendary = quest.isLegendary,
                    isIgnored = quest.isIgnored,
                    questID = quest.questID
                })
            end

            -- Добавляем опции госсипа
            for _, option in ipairs(options) do
                DataProvider:Insert({
                    type = "gossip",
                    name = option.name,
                    icon = option.icon,
                    gossipOptionID = option.gossipOptionID,
                })
            end

            -- Добавить опцию выхода
            DataProvider:Insert({
                type = "goodbye",
                name = GOODBYE,
            })

            GossipScrollBox:Show()
            UpdateFocus(1) -- Устанавливаем фокус на первый элемент

            local totalHeight = ScrollView:GetElementExtent() * DataProvider:GetSize()
            if totalHeight <= GossipScroll:GetHeight() then
                GossipScrollBar:Hide()
            else
                GossipScrollBar:Show()
            end
            
        elseif event == "GOSSIP_CLOSED" then
            GossipScrollBox:Hide()
        end
    end)

    -- Изначально скрываем GossipScrollBox
    GossipScrollBox:Hide()

    return GossipScrollBox, UpdateFocus
end

local function MoveFocus(delta)
    local newIndex = math.max(1, math.min(focusedIndex + delta, #frames))
    updateFocus(newIndex)
end

-- Подключение контроллера
local function toggleController(updateFocus)

    -- Создаем фрейм для обработки событий геймпада
    local controllerHandler = CreateFrame("Frame", "ControllerHandlerFrame", parentFrame)

    parentFrame:HookScript("OnShow", function()
        controllerHandler:EnableGamePadButton(true)
        controllerHandler:SetScript("OnGamePadButtonDown", function(_, button)
            if button == "PADDUP" then
                MoveFocus(-1)
            elseif button == "PADDDOWN" then
                MoveFocus(1)
            elseif button == "PAD1" then
                if frames[focusedIndex] then
                    frames[focusedIndex]:SelectOption()
                end
            elseif button == "PAD2" then
                C_GossipInfo.CloseGossip()
            end
        end)
    end)

    parentFrame:HookScript("OnHide", function()
        controllerHandler:EnableGamePadButton(false)
        controllerHandler:SetScript("OnGamePadButtonDown", nil)
    end)
end

function ConsoleMenu:SetCustomGossipFrame()
    -- Создаем основной фрейм
    parentFrame, updateFocus = CreateGossipScrollBox()

    -- Добавляем обработку геймпада
    toggleController(updateFocus)
end
