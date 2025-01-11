-- WorldMapFrame.lua

local ConsoleMenu = LibStub("AceAddon-3.0"):GetAddon("ConsoleMenu")
local parentFrame = WorldMapFrame

local function ResizeWorldMapToScreen()
    -- Убедимся, что WorldMapFrame существует
    if not parentFrame then
        print("WorldMapFrame не найден!");
        return;
    end

    -- Получаем размеры экрана
    local screenWidth = UIParent:GetWidth();
    local screenHeight = UIParent:GetHeight();

    -- Устанавливаем новый размер WorldMapFrame
    parentFrame:SetSize(screenWidth, screenHeight);

    -- Центрируем фрейм
    parentFrame:ClearAllPoints();
    parentFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT");
    parentFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT");


    -- Центрируем ScrollFrame внутри родительского фрейма
    parentFrame.ScrollContainer:ClearAllPoints();
    parentFrame.ScrollContainer:SetPoint("TOPLEFT", parentFrame, "TOPLEFT");
    parentFrame.ScrollContainer:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", 0 ,-32);

end

-- Перемещение и изменение тточек привязки фреймов
local function moveFrames()

    parentFrame.NavBar:SetHeight(40)
    
    parentFrame.NavBar:HookScript("OnUpdate", function()
        
        parentFrame.NavBar:ClearAllPoints();
        parentFrame.NavBar:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 64, -64);
        --parentFrame.NavBar:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", 0 ,-32);
    end)

    parentFrame.QuestLog:SetHeight(502)
    parentFrame.QuestLog:ClearAllPoints();
    parentFrame.QuestLog:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -44, 144);

    parentFrame.QuestLog.DetailsFrame:ClearAllPoints();
    parentFrame.QuestLog.DetailsFrame:SetPoint("TOPLEFT", parentFrame.QuestLog, "TOPLEFT", 0, -26);
    
end

-- Скрытие ненужных фреймов, регионов и текстур
local function hideFramesAndRegions()
    local elementsToHide = {
        parentFrame.BorderFrame,
        parentFrame.NavBar.overlay,
        parentFrame.SidePanelToggle,
        parentFrame.QuestLog.SettingsDropdown,
        parentFrame.QuestLog.QuestsFrame.SearchBox,
        WorldMapFrameBg
    }

    -- Скрываем все элементы из списка
    for _, element in ipairs(elementsToHide) do
        if element then
            element:Hide()
            element:SetAlpha(0)
        end
    end

    parentFrame.QuestLog:HookScript("OnUpdate", function()
        
        UpdateScrollBarVisibility(parentFrame.QuestLog.QuestsFrame)

    end)

end

-- Обновление текстур фрейсов и регионов
local function updateTextures()
    
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
            --print("Button pressed:", button)
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
        -- Закрываем меню при нажатии на кнопку "Круг" (Circle)
        if button == "PAD2" then
            parentFrame:Hide()
        elseif button == "PAD4" then
            if parentFrame.QuestLog:IsShown() then
                parentFrame.QuestLog:Hide()
            else
                parentFrame.QuestLog:Show()
            end
        end
    end

end

function ConsoleMenu:SetWorldMapFrame()

    parentFrame:HookScript("OnShow", function()
        ResizeWorldMapToScreen()
    end)

    parentFrame:HookScript("OnUpdate", function()
        parentFrame.BlackoutFrame:Show()
    end)

    moveFrames()
    hideFramesAndRegions()
    updateTextures()
    toggleController()

end