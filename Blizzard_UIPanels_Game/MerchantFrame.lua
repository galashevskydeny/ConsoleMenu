-- MerchantFrame.lua

local ConsoleMenu = LibStub("AceAddon-3.0"):GetAddon("ConsoleMenu")
local parentFrame = MerchantFrame

local offsetX = 40
local offsetY = 40
local scale = 1

-- Перемещение и изменение тточек привязки фреймов
local function moveFrames()

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

-- Создание фона
local function createBackground()
    if not _G["MerchantFrameNewBG"] then
        -- Создаем фрейм с использованием CPPopupFrameBaseTemplate
        local frame = CreateFrame("Frame", "MerchantFrameNewBG", parentFrame, "CPPopupFrameBaseTemplate")
        frame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT") -- Привязываем верхнюю левую точку к CharacterFrame
        frame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", 0, -21)
        
        
        -- Устанавливаем уровень слоя фрейма ниже, чтобы текст CharacterLevelText был виден
        frame:SetFrameStrata("MEDIUM")
        frame:SetFrameLevel(CharacterFrame:GetFrameLevel() - 1)
    end
end

function ConsoleMenu:SetMerchantFrame()

    moveFrames()
    hideFramesAndRegions()
    updateTextures()
    toggleController()

end
