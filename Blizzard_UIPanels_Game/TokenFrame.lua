-- CharacterFrame.lua

local ConsoleMenu = LibStub("AceAddon-3.0"):GetAddon("ConsoleMenu")

local offsetX = 40
local offsetY = 40
local scale = 1

-- Перемещение и изменение тточек привязки фреймов
local function moveFrames()

    -- Очищаем текущие привязки
    TokenFrame:ClearAllPoints()
        
    -- Устанавливаем новые привязки
    TokenFrame:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", offsetX, -offsetY+2) -- Отступ слева и сверху
    TokenFrame:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", -offsetX, 2) -- Отступ справа и снизу

    -- Очищаем текущие привязки
    TokenFrame.ScrollBar:ClearAllPoints()
    
    -- Устанавливаем новые привязки
    TokenFrame.ScrollBar:SetPoint("TOPLEFT", TokenFrame, "TOPRIGHT", 12, -offsetY) -- Отступ справа и снизу
    TokenFrame.ScrollBar:SetPoint("BOTTOMLEFT", TokenFrame, "BOTTOMRIGHT", 12, offsetY) -- Отступ справа и снизу

    -- Очищаем текущие привязки
    TokenFrame.ScrollBox:ClearAllPoints()
    
    -- Устанавливаем новые привязки
    TokenFrame.ScrollBox:SetPoint("TOPLEFT", TokenFrame, "TOPLEFT", -offsetX+24, -offsetY) -- Отступ слева и сверху
    TokenFrame.ScrollBox:SetPoint("BOTTOMRIGHT", TokenFrame, "BOTTOMRIGHT", 10, 2) -- Отступ слева и сверху

    -- Проверяем, существует ли ReputationFrame.filterDropdown
    if TokenFrame.filterDropdown then
        -- Очищаем текущие привязки
        TokenFrame.filterDropdown:ClearAllPoints()
        
        -- Устанавливаем новые привязки с использованием -offsetX
        TokenFrame.filterDropdown:SetPoint("TOPRIGHT", TokenFrame, "TOPRIGHT", 0, 0)
    end

    -- Проверяем, существуют ли TokenFrame.filterDropdown и TokenFrame.CurrencyTransferLogToggleButton
    if TokenFrame and TokenFrame.filterDropdown and TokenFrame.CurrencyTransferLogToggleButton then
        local filterDropdown = TokenFrame.filterDropdown
        local toggleButton = TokenFrame.CurrencyTransferLogToggleButton
        
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
    local controllerHandler = CreateFrame("Frame", "ControllerHandlerFrame", TokenFrame)

    -- Обработка нажатия кнопок геймпада
    function controllerHandler:OnGamePadButtonDown(button)
        
    end

end

function ConsoleMenu:SetTokenFrame()

    moveFrames()
    hideFramesAndRegions()
    updateTextures()
    toggleController()

end
