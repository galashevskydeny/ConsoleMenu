-- PVEFrame.lua

local ConsoleMenu = LibStub("AceAddon-3.0"):GetAddon("ConsoleMenu")
local parentFrame = PVEFrame
local titleSize = 20

local offsetX = 40
local offsetY = 40
local scale = 1

-- Перемещение и изменение тточек привязки фреймов
local function moveFrames()

    parentFrame:HookScript("OnShow", function()
        if parentFrame:IsShown() then
            --parentFrame:SetWidth()
            -- parentFrame:SetHeight()
        end
    end)

    if parentFrame.CloseButton then
        parentFrame.CloseButton:ClearAllPoints()
        parentFrame.CloseButton:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", 2,2)
    end

    if parentFrame.TitleContainer.TitleText then
        -- Устанавливаем новый размер шрифта и выравнивание
        parentFrame.TitleContainer.TitleText:SetFont(parentFrame.TitleContainer.TitleText:GetFont(), titleSize) -- Меняем размер шрифта на 20
        parentFrame.TitleContainer.TitleText:SetJustifyH("LEFT") -- Выравниваем по левому краю

         -- Включаем перенос слов
         parentFrame.TitleContainer.TitleText:SetWordWrap(true)

         -- Опционально, устанавливаем максимальное количество строк (0 означает неограниченное количество)
         parentFrame.TitleContainer.TitleText:SetMaxLines(0)
    end

    if parentFrame.TitleContainer then
        -- Очищаем все привязки
        parentFrame.TitleContainer:ClearAllPoints()
        
        parentFrame.TitleContainer:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", offsetX, -offsetY)
        parentFrame.TitleContainer:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -offsetX, -offsetY)
    end

end

-- Скрытие ненужных фреймов, регионов и текстур
local function hideFramesAndRegions()
    local elementsToHide = {
        parentFrame.NineSlice,
        parentFrame.TopTileStreaks,
        parentFrame.Inset,
        parentFrame.PortraitContainer.portrait,
        parentFrame.Bg,
        parentFrame.Background,
    }

    for _, region in ipairs({parentFrame:GetRegions()}) do
        table.insert(elementsToHide, region)
    end

    local elementsTo

    -- Скрываем все элементы из списка
    for _, element in ipairs(elementsToHide) do
        if element then
            element:Hide()
            element:SetAlpha(0)
        end
    end

    parentFrame:HookScript("OnUpdate", function()
        parentFrame.shadows:Hide()
        RaidFinderFrameRoleBackground:Hide()
        RaidFinderFrameRoleInset:Hide()
        LFDParentFrameRoleBackground:Hide()
        LFDParentFrameInset:Hide()
        if DelvesDashboardFrame then
            DelvesDashboardFrame.DashboardBackground:Hide()
        end
    end)


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
    if not _G["PVEFrameNewBG"] then
        local frame = CreateFrame("Frame", "PVEFrameNewBG", parentFrame, "BackdropTemplate")
        frame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT") -- Привязываем верхнюю левую точку к CharacterFrame
        frame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", 0, -21)
        
        -- Устанавливаем уровень слоя фрейма ниже, чтобы текст CharacterLevelText был виден
        frame:SetFrameStrata("MEDIUM")
        frame:SetFrameLevel(CharacterFrame:GetFrameLevel() - 1)

        -- Применяем стиль
        NineSliceUtil.ApplyLayoutByName(frame, "CharacterCreateDropdown")
        frame:SetAlpha(0.75)
    end
end

function ConsoleMenu:SetPVEFrame()

    moveFrames()
    hideFramesAndRegions()
    updateTextures()
    --toggleController()
    createBackground()

end
