-- CharacterFrame.lua

local ConsoleMenu = LibStub("AceAddon-3.0"):GetAddon("ConsoleMenu")

local offsetX = 40
local offsetY = 40
local scale = 1

local inventorySlots = {
    CharacterHeadSlot,
    CharacterNeckSlot,
    CharacterShoulderSlot,
    CharacterBackSlot,
    CharacterChestSlot,
    CharacterShirtSlot,
    CharacterTabardSlot,
    CharacterWristSlot,
    CharacterMainHandSlot,
    CharacterSecondaryHandSlot,
    CharacterHandsSlot,
    CharacterWaistSlot,
    CharacterLegsSlot,
    CharacterFeetSlot,
    CharacterFinger0Slot,
    CharacterFinger1Slot,
    CharacterTrinket0Slot,
    CharacterTrinket1Slot,
}

local statsItems = {}
local currentStatsIndex = nil
local currentSlotIndex = nil

-- Перемещение и изменение тточек привязки фреймов
local function moveFrames()
    if CharacterFrameCloseButton then
        CharacterFrameCloseButton:ClearAllPoints()
        CharacterFrameCloseButton:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", -3,-3)
    end

    -- Создаем хуки для отслеживания открытия окна персонажа, репутации и токенов
    hooksecurefunc("ToggleCharacter", function()
            if CharacterFrame:IsShown() then
                CharacterFrame:SetWidth(540 + offsetX*2)
                CharacterFrame:SetHeight(424 + offsetY*2-32)
            end
    end)

    -- Проверяем, существует ли CharacterFrameTab1
    if CharacterFrameTab1 then
        -- Очищаем текущие привязки
        CharacterFrameTab1:ClearAllPoints()
        
        -- Устанавливаем новую привязку с изменением смещения по X
        CharacterFrameTab1:SetPoint("TOPLEFT", CharacterFrame, "BOTTOMLEFT", offsetX, 2) -- Заменяем 11 на 32
    end
end

-- Скрытие ненужных фреймов, регионов и текстур
local function hideFramesAndRegions()
    local elementsToHide = {
        CharacterFrame.NineSlice,
        CharacterFramePortrait,
        CharacterFrameBg,
        CharacterFrameInset.Bg,
        CharacterFrameInset.NineSlice,
        CharacterFrameInsetRight.NineSlice,
        CharacterFrameInsetRight.Bg,
        CharacterFrame.Background,
        CharacterFrame.TopTileStreaks,
    }

    -- Скрываем все элементы из списка
    for _, element in ipairs(elementsToHide) do
        if element then
            element:Hide()
            element:SetAlpha(0)
        end
    end

    -- Привязываем события к CharacterFrameCloseButton
    CharacterFrameCloseButton:RegisterEvent("GAME_PAD_CONNECTED")
    CharacterFrameCloseButton:RegisterEvent("GAME_PAD_DISCONNECTED")

    -- Обработчик событий
    CharacterFrameCloseButton:SetScript("OnEvent", function(self, event)
        if event == "GAME_PAD_CONNECTED" then
            if C_GamePad and C_GamePad.GetAllDeviceIDs and #C_GamePad.GetAllDeviceIDs() > 0 then
                CharacterFrameCloseButton:Hide()
            end
        elseif event == "GAME_PAD_DISCONNECTED" then
            CharacterFrameCloseButton:Show()
        end
    end)

end

-- Подключение контроллера
local function toggleController()
    -- Создаем фрейм для обработки событий геймпада
    local controllerHandler = CreateFrame("Frame", "ControllerHandler", CharacterFrame)

    CharacterFrame:HookScript("OnShow", function()
        -- Включаем обработку геймпада
        controllerHandler:EnableGamePadButton(true)

        -- Добавляем обработчик событий геймпада
        controllerHandler:SetScript("OnGamePadButtonDown", function(_, button)
            --print("Button pressed:", button)
            controllerHandler:OnGamePadButtonDown(button)
        end)
    end)

    CharacterFrame:HookScript("OnHide", function()
        -- Отключаем обработку геймпада
        controllerHandler:EnableGamePadButton(false)
        controllerHandler:SetScript("OnGamePadButtonDown", nil) -- Очищаем обработчик событий
    end)

    -- Обработка нажатия кнопок геймпада
    function controllerHandler:OnGamePadButtonDown(button)
        -- print("Inside OnGamePadButtonDown function:", button)
        -- Закрываем меню при нажатии на кнопку "Круг" (Circle)
        if button == "PAD2" then
            HideUIPanel(CharacterFrame)
        -- Переключаем вкладки Character Frame
        elseif button == "PADRTRIGGER" then
            if CharacterFrame.selectedTab == 1 then ToggleCharacter("ReputationFrame")
            elseif CharacterFrame.selectedTab == 2 then ToggleCharacter("TokenFrame")
            elseif CharacterFrame.selectedTab == 3 then ToggleCharacter("PaperDollFrame")
            end
        elseif button == "PADLTRIGGER" then
            if CharacterFrame.selectedTab == 1 then ToggleCharacter("TokenFrame")
            elseif CharacterFrame.selectedTab == 2 then ToggleCharacter("PaperDollFrame")
            elseif CharacterFrame.selectedTab == 3 then ToggleCharacter("ReputationFrame")
            end
        else
            if CharacterFrame.selectedTab == 1 then PaperDollFrame.ControllerHandler:OnGamePadButtonDown(button)
            elseif CharacterFrame.selectedTab == 2 then 
            elseif CharacterFrame.selectedTab == 3 then 
            end
        end


    end

end

-- Создание фона
local function createBackground()
    if not _G["CharacterFrameNewBG"] then
        -- Создаем фрейм с использованием CPPopupFrameBaseTemplate
        local frame = CreateFrame("Frame", "CharacterFrameNewBG", CharacterFrame, "CPPopupFrameBaseTemplate")
        frame:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT") -- Привязываем верхнюю левую точку к CharacterFrame
        frame:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", 0, -21)
        
        
        -- Устанавливаем уровень слоя фрейма ниже, чтобы текст CharacterLevelText был виден
        frame:SetFrameStrata("MEDIUM")
        frame:SetFrameLevel(CharacterFrame:GetFrameLevel() - 1)
    end
end

-- Применение модификаций
function ConsoleMenu:SetCharacterFrame()

    if scale then
        CharacterFrame:SetScale(scale)
    end

    moveFrames()
    hideFramesAndRegions()
    toggleController()
    createBackground()

end
