local ConsoleMenu = LibStub("AceAddon-3.0"):GetAddon("ConsoleMenu")
local parentFrame

local function CreateGossipScrollBox()
    -- Главный фрейм
    local GossipScrollBox = CreateFrame("Frame", "GossipScroll", UIParent)
    GossipScrollBox:SetSize(640, 196)
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

        frame.text:SetFont("Fonts\\FRIZQT___CYR.TTF", 20, "OUTLINE") -- Шрифт, размер, флаги
        frame.text:SetText(data.name)
        frame.text:SetTextColor(1, 0.976, 0.855) -- Цвет текста FFF9DA

        -- Фокус (изменение текста и фона при наведении)
        frame:SetScript("OnEnter", function()
            frame.text:SetTextColor(1, 0.768, 0.071) -- Цвет текста FFC412
            if not frame.bg then
                frame.bg = frame:CreateTexture(nil, "BACKGROUND")
                frame.bg:SetAllPoints()
                frame.bg:SetAtlas("Garr_BuildingInfoShadow") -- Прозрачный фон при наведении
            end
            frame.bg:Show()
        end)
        frame:SetScript("OnLeave", function()
            frame.text:SetTextColor(1, 0.976, 0.855) -- Цвет текста FFF9DA
            if frame.bg then
                frame.bg:Hide()
            end
        end)

        -- Действие при клике
        frame:SetScript("OnMouseDown", function()
            C_GossipInfo.SelectOption(data.gossipOptionID)
            print("Выбрано:", data.name)
        end)
    end

    -- Устанавливаем кастомный элемент как шаблон
    ScrollView:SetElementExtent(48) -- Высота каждого элемента
    ScrollView:SetElementInitializer("Frame", Initializer)

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
            for _, option in ipairs(options) do
                DataProvider:Insert(option)
            end

            GossipScrollBox:Show()
            
        elseif event == "GOSSIP_CLOSED" then
            GossipScrollBox:Hide()
        end
    end)

    -- Изначально скрываем GossipScrollBox
    GossipScrollBox:Hide()

    return GossipScrollBox
end

-- Подключение контроллера
local function toggleController()
    -- Создаем фрейм для обработки событий геймпада
    local controllerHandler = CreateFrame("Frame", "ControllerHandlerFrame", parentFrame)

    parentFrame:HookScript("OnShow", function()
        -- Включаем обработку геймпада
        controllerHandler:EnableGamePadButton(true)

        -- Добавляем обработчик событий геймпада
        controllerHandler:SetScript("OnGamePadButtonDown", function(_, button)
            controllerHandler:OnGamePadButtonDown(button)
        end)
    end)

    parentFrame:HookScript("OnHide", function()
        -- Отключаем обработку геймпада
        controllerHandler:EnableGamePadButton(false)
        controllerHandler:SetScript("OnGamePadButtonDown", nil) -- Очищаем обработчик событий
    end)

    -- Обработка нажатия кнопок геймпада
    function controllerHandler:OnGamePadButtonDown(button)
        if button == "PADDUP" then
        elseif button == "PADDDOWN" then
        elseif button == "PAD2" then
            C_GossipInfo.CloseGossip()
        end
    end
end

function ConsoleMenu:SetCustomGossipFrame()
    -- Создаем основной фрейм
    parentFrame = CreateGossipScrollBox()

    -- Добавляем обработку геймпада
    toggleController()
end
