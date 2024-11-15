-- CharacterFrame.lua

local ConsoleMenu = LibStub("AceAddon-3.0"):GetAddon("ConsoleMenu")

local offsetX = 40
local offsetY = 40
local scale = 1

-- Перемещение и изменение тточек привязки фреймов
local function moveFrames()
    -- Проверяем, существует ли ReputationFrame.ScrollBox
    if ReputationFrame then
        -- Очищаем текущие привязки
        ReputationFrame:ClearAllPoints()
        
        -- Устанавливаем новые привязки
        ReputationFrame:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", offsetX, -offsetY+2) -- Отступ слева и сверху
        ReputationFrame:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", -offsetX, 2) -- Отступ справа и снизу

        -- Очищаем текущие привязки
        ReputationFrame.ScrollBar:ClearAllPoints()
        
        -- Устанавливаем новые привязки
        ReputationFrame.ScrollBar:SetPoint("TOPLEFT", ReputationFrame, "TOPRIGHT", 12, -offsetY) -- Отступ справа и снизу
        ReputationFrame.ScrollBar:SetPoint("BOTTOMLEFT", ReputationFrame, "BOTTOMRIGHT", 12, offsetY) -- Отступ справа и снизу

        -- Очищаем текущие привязки
        ReputationFrame.ScrollBox:ClearAllPoints()
        
        -- Устанавливаем новые привязки
        ReputationFrame.ScrollBox:SetPoint("TOPLEFT", ReputationFrame, "TOPLEFT", -offsetX+24, -offsetY) -- Отступ слева и сверху
        ReputationFrame.ScrollBox:SetPoint("BOTTOMRIGHT", ReputationFrame, "BOTTOMRIGHT", 10, 2) -- Отступ слева и сверху

    end

    -- Проверяем, существует ли ReputationFrame.filterDropdown
    if ReputationFrame.filterDropdown then
        -- Очищаем текущие привязки
        ReputationFrame.filterDropdown:ClearAllPoints()
        
        -- Устанавливаем новые привязки с использованием -offsetX
        ReputationFrame.filterDropdown:SetPoint("TOPRIGHT", ReputationFrame, "TOPRIGHT", 0, 0)
    end

end

-- Скрытие ненужных фреймов, регионов и текстур
local function hideFramesAndRegions()
    local elementsToHide = {
        
    }

    -- Скрываем все элементы из списка
    for _, element in ipairs(elementsToHide) do
        if element then
            element:Hide()
            element:SetAlpha(0)
        end
    end

end

-- Обновление текстур фрейсов и регионов
local function updateTextures()
    
end

-- Подключение контроллера
local function toggleController()
    -- Создаем фрейм для обработки событий геймпада
    local controllerHandler = CreateFrame("Frame", "ControllerHandlerFrame", TokenFrame)

    -- Обработка нажатия кнопок геймпада
    function controllerHandler:OnGamePadButtonDown(button)
        
    end

end

function ConsoleMenu:SetReputationFrame()

    moveFrames()
    hideFramesAndRegions()
    updateTextures()
    toggleController()

end
