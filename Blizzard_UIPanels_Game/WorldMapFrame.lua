-- WorldMapFrame.lua

local ConsoleMenu = LibStub("AceAddon-3.0"):GetAddon("ConsoleMenu")
local parentFrame = WorldMapFrame

local function ResizeWorldMapToScreen()
    -- Убедимся, что WorldMapFrame существует
    if not parentFrame then
        print("WorldMapFrame не найден!");
        return;
    end

    -- Центрируем фрейм
    parentFrame:ClearAllPoints();
    parentFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT");
    parentFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT");


    -- Центрируем ScrollFrame внутри родительского фрейма
    parentFrame.ScrollContainer:ClearAllPoints();
    parentFrame.ScrollContainer:SetPoint("TOPLEFT", parentFrame, "TOPLEFT");
    parentFrame.ScrollContainer:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", 0 ,-36);

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

    for i, child in ipairs({parentFrame:GetChildren()}) do
        if child.Eye and child.Background then
            child:ClearAllPoints();
            child:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", 0, 0);
        elseif child.BountyName then
            child:ClearAllPoints();
            child:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", 64, 100);
        end
    end

    for i, child in ipairs({parentFrame.ScrollContainer:GetChildren()}) do
        if child ~= parentFrame.ScrollContainer.Child then
            child:ClearAllPoints();
            child:SetPoint("TOP", parentFrame.ScrollContainer, "TOP", 0, -74);
        end
    end
    
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
        -- Получаем текущую привязку команды TOGGLEWORLDMAP
        local toggleWorldMapBinding = GetBindingKey("TOGGLEWORLDMAP")
        
        -- Проверяем нажатую кнопку или привязку команды TOGGLEWORLDMAP
        if button == "PAD2" or (toggleWorldMapBinding and button == toggleWorldMapBinding) then
            ToggleWorldMap()
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

        ResizeWorldMapToScreen()
        
        if parentFrame:IsMinimized() then
            parentFrame.BorderFrame.MaximizeMinimizeFrame.MaximizeButton:Click()
        end

        for i, child in ipairs({parentFrame:GetChildren()}) do
            if child.BountyName then
                child:ClearAllPoints();
                child:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", 64, 64);
            elseif child.bounties then
                child:ClearAllPoints();
                child:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", 64, 64);
            end
        end

    end)

    moveFrames()
    hideFramesAndRegions()
    updateTextures()
    toggleController()

end