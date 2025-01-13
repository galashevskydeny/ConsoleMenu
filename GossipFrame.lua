local ConsoleMenu = LibStub("AceAddon-3.0"):GetAddon("ConsoleMenu")
local parentFrame
local frames = {} -- Хранение всех созданных элементов
local focusedIndex = 1 -- Индекс текущего элемента в фокусе

local function CreateGossipScrollBox()
    -- Главный фрейм
    local GossipScrollBox = CreateFrame("Frame", "GossipScroll", UIParent)
    GossipScrollBox:SetSize(640, 48*3)
    GossipScrollBox:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 64)
    
    -- Создаем ScrollBox
    local ScrollBox = CreateFrame("Frame", "GossipScrollBox", GossipScrollBox, "WowScrollBoxList")
    GossipScrollBox.ScrollBox = ScrollBox
    ScrollBox:SetPoint("TOPLEFT", GossipScrollBox, "TOPLEFT", 0, 0)
    ScrollBox:SetAllPoints()

    -- Создаем ScrollBar
    local ScrollBar = CreateFrame("EventFrame", "GossipScrollBar", GossipScrollBox, "MinimalScrollBar")
    GossipScrollBox.ScrollBar = ScrollBar

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
            frame.icon = frame:CreateTexture(nil, "ARTWORK")
            frame.icon:SetSize(32, 32)
            frame.icon:SetPoint("LEFT", 10, 0)
        end
        frame.icon:SetTexture(data.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

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

    end

    -- Устанавливаем кастомный элемент как шаблон
    ScrollView:SetElementExtent(48)
    ScrollView:SetElementInitializer("Frame", Initializer)

    -- Обновление фокуса
    local function UpdateFocus(newIndex)
        if frames[focusedIndex] then
            frames[focusedIndex]:SetFocused(false)
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

            -- Очищаем DataProvider и добавляем новые данные
            DataProvider:Flush()
            frames = {} -- Сбрасываем список фреймов
            for _, option in ipairs(options) do
                DataProvider:Insert(option)
            end

            GossipScrollBox:Show()
            UpdateFocus(1) -- Устанавливаем фокус на первый элемент
            
        elseif event == "GOSSIP_CLOSED" then
            GossipScrollBox:Hide()
        end
    end)

    -- Изначально скрываем GossipScrollBox
    GossipScrollBox:Hide()

    return GossipScrollBox, UpdateFocus
end

-- Подключение контроллера
local function toggleController(updateFocus)
    local function MoveFocus(delta)
        local newIndex = math.max(1, math.min(focusedIndex + delta, #frames))
        updateFocus(newIndex)
    end

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
                
            elseif button == "PAD2" then
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
