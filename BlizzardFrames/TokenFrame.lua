-- TokenFrame.lua

local ConsoleMenu = _G.ConsoleMenu
local parentFrame = TokenFrame

local offsetX = 40
local offsetY = 40
local scale = 1

-- Перемещение и изменение тточек привязки фреймов
local function moveFrames()

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

    -- Проверяем, существует ли ReputationFrame.filterDropdown
    if parentFrame.filterDropdown then
        -- Очищаем текущие привязки
        parentFrame.filterDropdown:ClearAllPoints()
        
        -- Устанавливаем новые привязки с использованием -offsetX
        parentFrame.filterDropdown:SetPoint("TOPRIGHT", TokenFrame, "TOPRIGHT", 0, 0)
    end

    -- Проверяем, существуют ли TokenFrame.filterDropdown и TokenFrame.CurrencyTransferLogToggleButton
    if parentFrame and parentFrame.filterDropdown and parentFrame.CurrencyTransferLogToggleButton then
        local filterDropdown = parentFrame.filterDropdown
        local toggleButton = parentFrame.CurrencyTransferLogToggleButton
        
        -- Очищаем все привязки кнопки
        toggleButton:ClearAllPoints()
        
        -- Устанавливаем привязку слева от filterDropdown с отступом 12 пикселей
        toggleButton:SetPoint("RIGHT", filterDropdown, "LEFT", -12, 0)
        toggleButton:SetHeight(filterDropdown:GetHeight())
        toggleButton:SetWidth(filterDropdown:GetHeight())
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

function ConsoleMenu:SetTokenFrame()

    if ConsoleMenuDB and ConsoleMenuDB["characterWindowStyle"] == 2 then
        return
    end

    moveFrames()
    hideFramesAndRegions()
    updateTextures()
    toggleController()

end
