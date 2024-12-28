-- MerchantFrame.lua

local ConsoleMenu = LibStub("AceAddon-3.0"):GetAddon("ConsoleMenu")
local parentFrame = MerchantFrame
local titleSize = 20

local offsetX = 40
local offsetY = 40
local scale = 1

-- Перемещение и изменение тточек привязки фреймов
local function moveFrames()

    parentFrame:HookScript("OnShow", function()
        if parentFrame:IsShown() then
            parentFrame:SetWidth(318 + offsetX*2)
            parentFrame:SetHeight(offsetY*2+parentFrame.TitleContainer.TitleText:GetStringHeight()+offsetY+44*5+8+offsetY+36*2)
        end
    end)

    if parentFrame.CloseButton then
        parentFrame.CloseButton:ClearAllPoints()
        parentFrame.CloseButton:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", 2,2)
    end

    if MerchantFrameTab1 then
        MerchantFrameTab1:ClearAllPoints()
        MerchantFrameTab1:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", offsetX, 0)
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
        
        -- Устанавливаем новые привязки с отступом слева 24 пикселя и теми же значениями для других параметров
        parentFrame.TitleContainer:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", offsetX, -offsetY)
        parentFrame.TitleContainer:SetWidth(MerchantItem1:GetWidth())
        
    end

    if parentFrame.FilterDropdown then
        parentFrame.FilterDropdown:ClearAllPoints()
        parentFrame.FilterDropdown:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -offsetX, -offsetY)
    end

    if MerchantItem1 then
        MerchantItem1:ClearAllPoints()
        MerchantItem1:SetPoint("TOPLEFT", parentFrame.TitleContainer.TitleText, "BOTTOMLEFT", 0, -offsetY+16)
    end

    if MerchantPrevPageButton then
        MerchantPrevPageButton:ClearAllPoints()
        MerchantPrevPageButton:SetPoint("TOPLEFT", MerchantItem9, "BOTTOMLEFT", 0, -offsetY/2)
    end

    if MerchantNextPageButton then
        MerchantNextPageButton:ClearAllPoints()
        MerchantNextPageButton:SetPoint("TOPRIGHT", MerchantItem10, "BOTTOMRIGHT", 0, -offsetY/2)
    end

    if MerchantPageText then
        MerchantPageText:ClearAllPoints()
        MerchantPageText:SetPoint("LEFT", MerchantPrevPageButton, "RIGHT", 0, 0)
        MerchantPageText:SetPoint("RIGHT", MerchantNextPageButton, "LEFT", 0, 0)
    end

    MerchantRepairAllButton:HookScript("OnUpdate", function()
        if MerchantRepairAllButton then
            MerchantRepairAllButton:ClearAllPoints()
            MerchantRepairAllButton:SetPoint("LEFT", parentFrame, "LEFT", offsetX, 0)
            MerchantRepairAllButton:SetPoint("TOP", MerchantNextPageButton, "BOTTOM", 0, -offsetY/2)
        end
    end)

    MerchantRepairItemButton:HookScript("OnUpdate", function()
        if MerchantRepairItemButton then
            MerchantRepairItemButton:ClearAllPoints()
            if MerchantRepairAllButton:IsShown() then
                MerchantRepairItemButton:SetPoint("LEFT", MerchantRepairAllButton, "RIGHT", 8, 0)
            else
                MerchantRepairItemButton:SetPoint("LEFT", parentFrame, "LEFT", offsetX, 0)
                MerchantRepairItemButton:SetPoint("TOP", MerchantNextPageButton, "BOTTOM", 0, -offsetY/2)
            end
        end
    end)

    MerchantSellAllJunkButton:HookScript("OnUpdate", function()
        if MerchantSellAllJunkButton then
            MerchantSellAllJunkButton:ClearAllPoints()
            if MerchantRepairItemButton:IsShown() then
                MerchantSellAllJunkButton:SetPoint("LEFT", MerchantRepairItemButton, "RIGHT", 8, 0)
            else
                MerchantSellAllJunkButton:SetPoint("LEFT", parentFrame, "LEFT", offsetX, 0)
                MerchantSellAllJunkButton:SetPoint("TOP", MerchantNextPageButton, "BOTTOM", 0, -offsetY/2)
            end
        end
    end)

    MerchantBuyBackItem:HookScript("OnUpdate", function()
        if MerchantBuyBackItem then
            MerchantBuyBackItem:ClearAllPoints()
            MerchantBuyBackItem:SetPoint("LEFT", MerchantItem10, "LEFT", 0, 0)
            MerchantBuyBackItem:SetPoint("TOP", MerchantSellAllJunkButton, "TOP", 0, 0)
        end
    end)

    if MerchantMoneyFrame then
        MerchantMoneyFrame:ClearAllPoints()
        MerchantMoneyFrame:SetPoint("RIGHT", parentFrame, "RIGHT", -offsetX, 0)
        MerchantMoneyFrame:SetPoint("TOP", parentFrame, "BOTTOM", 0, -offsetY+4)
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
        MerchantMoneyBg,
        MerchantMoneyInset,
        MerchantFrameBottomLeftBorder,
        BuybackBG,
        MerchantExtraCurrencyBg,
        MerchantExtraCurrencyInset,
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
        local frame = CreateFrame("Frame", "MerchantFrameNewBG", parentFrame, "BackdropTemplate")
        frame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT") -- Привязываем верхнюю левую точку к CharacterFrame
        frame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", 0, -23)
        
        -- Устанавливаем уровень слоя фрейма ниже, чтобы текст CharacterLevelText был виден
        frame:SetFrameStrata("MEDIUM")
        frame:SetFrameLevel(CharacterFrame:GetFrameLevel() - 1)

        -- Применяем стиль
        NineSliceUtil.ApplyLayoutByName(frame, "CharacterCreateDropdown")
        frame:SetAlpha(0.75)
    end
end

function ConsoleMenu:SetMerchantFrame()

    moveFrames()
    hideFramesAndRegions()
    updateTextures()
    toggleController()
    createBackground()

end
