-- ReputationFrame.lua

local ConsoleMenu = _G.ConsoleMenu
local parentFrame = ReputationFrame

local offsetX = 40
local offsetY = 40
local scale = 1

-- Перемещение и изменение тточек привязки фреймов
local function moveFrames()
    -- Проверяем, существует ли ReputationFrame.ScrollBox
    if parentFrame then
        -- Очищаем текущие привязки
        parentFrame:ClearAllPoints()
        
        -- Устанавливаем новые привязки
        parentFrame:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", offsetX, -offsetY+2) -- Отступ слева и сверху
        parentFrame:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", -offsetX, 2) -- Отступ справа и снизу

        -- Очищаем текущие привязки
        parentFrame.ScrollBar:ClearAllPoints()
        
        -- Устанавливаем новые привязки
        parentFrame.ScrollBar:SetPoint("TOPLEFT", parentFrame, "TOPRIGHT", 12, -offsetY) -- Отступ справа и снизу
        parentFrame.ScrollBar:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMRIGHT", 12, offsetY) -- Отступ справа и снизу

        -- Очищаем текущие привязки
        parentFrame.ScrollBox:ClearAllPoints()
        
        -- Устанавливаем новые привязки
        parentFrame.ScrollBox:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", -offsetX+24, -offsetY) -- Отступ слева и сверху
        parentFrame.ScrollBox:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", 10, 2) -- Отступ слева и сверху

    end

    -- Проверяем, существует ли ReputationFrame.filterDropdown
    if parentFrame.filterDropdown then
        -- Очищаем текущие привязки
        parentFrame.filterDropdown:ClearAllPoints()
        
        -- Устанавливаем новые привязки с использованием -offsetX
        parentFrame.filterDropdown:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", 0, 0)
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
    local controllerHandler = CreateFrame("Frame", "ControllerHandlerFrame", parentFrame)

    -- Обработка нажатия кнопок геймпада
    function controllerHandler:OnGamePadButtonDown(button)
        
    end

end

function ConsoleMenu:SetReputationFrame()

    if ConsoleMenuDB and ConsoleMenuDB["characterWindowStyle"] == 2 then
        return
    end

    moveFrames()
    hideFramesAndRegions()
    updateTextures()
    toggleController()

end
