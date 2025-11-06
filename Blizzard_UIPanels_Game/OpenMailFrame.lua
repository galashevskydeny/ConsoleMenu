-- OpenMailFrame.lua

local ConsoleMenu = _G.ConsoleMenu
local parentFrame = OpenMailFrame
local titleSize = 20

local offsetX = 40
local offsetY = 40
local scale = 1

-- Перемещение и изменение тточек привязки фреймов
local function moveFrames()

    if parentFrame then
        parentFrame:ClearAllPoints()
        parentFrame:SetPoint("TOPLEFT", MailFrame, "TOPRIGHT", 8,0)
    end

    if parentFrame.CloseButton then
        parentFrame.CloseButton:ClearAllPoints()
        parentFrame.CloseButton:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", 2,2)
    end

    parentFrame:HookScript("OnShow", function()
        if parentFrame:IsShown() then
            parentFrame:SetWidth(296 + offsetX*2)
            parentFrame:SetHeight(424 + offsetY*2-32+titleSize)
        end
    end)

    if parentFrame.TitleContainer.TitleText then
        -- Устанавливаем новый размер шрифта и выравнивание
        parentFrame.TitleContainer.TitleText:SetFont(CharacterFrameTitleText:GetFont(), titleSize) -- Меняем размер шрифта
        parentFrame.TitleContainer.TitleText:SetJustifyH("LEFT") -- Выравниваем по левому краю
    end

    if parentFrame.TitleContainer then
        -- Очищаем все привязки
        parentFrame.TitleContainer:ClearAllPoints()
        
        parentFrame.TitleContainer:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", offsetX + 4, -offsetY-4)
        parentFrame.TitleContainer:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -offsetX, -offsetY-4)
    end

    if OpenMailSenderLabel then
        OpenMailSenderLabel:ClearAllPoints()
        OpenMailSenderLabel:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", offsetX, -offsetY)
    end
    
    if OpenMailSubjectLabel then
        OpenMailSubjectLabel:ClearAllPoints()
        OpenMailSubjectLabel:SetPoint("TOPLEFT", OpenMailSenderLabel, "BOTTOMLEFT", 0, -4)
        OpenMailSubjectLabel:SetFont(OpenMailSubjectLabel:GetFont(), 14)
        OpenMailSubject:SetFont(OpenMailSubjectLabel:GetFont(), 14)
        OpenMailSubject:ClearAllPoints()
        OpenMailSubject:SetPoint("TOPLEFT", OpenMailSubjectLabel, "TOPRIGHT", 4, -2)
        OpenMailSubject:SetPoint("RIGHT", parentFrame, "RIGHT", -offsetX, 0)
    end

    if OpenMailScrollFrame then
        OpenMailScrollFrame:ClearAllPoints()
        OpenMailScrollFrame:SetPoint("TOP", OpenMailSubject, "BOTTOM", 0, -offsetY/2)
        OpenMailScrollFrame:SetPoint("RIGHT", parentFrame, "RIGHT", -offsetX, 0)
    end

    if OpenMailScrollChildFrame then
        OpenMailScrollChildFrame:ClearAllPoints()
        OpenMailScrollChildFrame:SetPoint("TOPLEFT", OpenMailScrollFrame, "TOPLEFT", 0, 0)
        OpenMailScrollChildFrame:SetPoint("TOPRIGHT", OpenMailScrollFrame, "TOPRIGHT", 0, 0)
    end

    if OpenMailBodyText then
        OpenMailBodyText:ClearAllPoints()
        OpenMailBodyText:SetPoint("TOPLEFT", OpenMailScrollChildFrame, "TOPLEFT", 0, 0)
        OpenMailBodyText:SetPoint("RIGHT", OpenMailScrollChildFrame, "RIGHT", 0, 0)
    end

    OpenMailBodyText:HookScript("OnUpdate", function()
        local height = 0
        for _, region in ipairs({OpenMailBodyText:GetRegions()}) do
            if region:IsObjectType("FontString") then
                region:SetPoint("TOPRIGHT", OpenMailScrollChildFrame, "TOPRIGHT", 0, 0)
                region:SetTextColor(1, 1, 1)
                height = height + region:GetStringHeight()
            end
        end
        if height ~= 0 then
            OpenMailBodyText:SetHeight(height)
            OpenMailScrollChildFrame:SetHeight(height)
            OpenMailScrollFrame:SetHeight(height)
        end
    end)

    OpenMailInvoiceFrame:HookScript("OnUpdate", function()
        for _, region in ipairs({OpenMailInvoiceFrame:GetRegions()}) do
            if region:IsObjectType("FontString") then
                region:SetTextColor(1, 1, 1)
            end
        end

        OpenMailInvoiceItemLabel:ClearAllPoints()
        OpenMailInvoiceItemLabel:SetPoint("TOPLEFT", OpenMailInvoiceFrame, "TOPLEFT", 0, 0)
        OpenMailSalePriceMoneyFrame.Count:SetTextColor(1, 1, 1)

        OpenMailInvoiceSalePrice:ClearAllPoints()
        OpenMailInvoiceSalePrice:SetPoint("RIGHT", OpenMailInvoiceFrame, "RIGHT", -12, 0)
        OpenMailInvoiceSalePrice:SetPoint("TOP", OpenMailInvoicePurchaser, "BOTTOM", 0, -offsetY/2)

    end)

    OpenMailFrame:HookScript("OnUpdate", function()
        UpdateScrollBarVisibility(OpenMailScrollFrame)

        if OpenMailAttachmentText then
            OpenMailAttachmentText:ClearAllPoints()
            OpenMailAttachmentText:SetPoint("TOPLEFT", OpenMailScrollFrame, "BOTTOMLEFT", 0, -offsetY/2)
            OpenMailAttachmentText:SetFont(OpenMailAttachmentText:GetFont(), 14)
            OpenMailAttachmentText:SetTextColor(OpenMailSubject:GetTextColor())

            if not OpenMailMoneyButton:IsShown() and not OpenMailMoneyButton:IsShown() then
                OpenMailAttachmentButton1:ClearAllPoints()
                OpenMailAttachmentButton1:SetPoint("TOPLEFT", OpenMailAttachmentText, "BOTTOMLEFT", 0, -8)
            end
        end

        if OpenMailLetterButton then
            OpenMailLetterButton:ClearAllPoints()
            OpenMailLetterButton:SetPoint("TOPLEFT", OpenMailAttachmentText, "BOTTOMLEFT", 0, -8)
        end

        if OpenMailMoneyButton then
            if OpenMailLetterButton:IsVisible() then
                OpenMailMoneyButton:ClearAllPoints()
                OpenMailMoneyButton:SetPoint("TOPLEFT", OpenMailLetterButton, "TOPRIGHT", 8, 0)
            else
                OpenMailMoneyButton:ClearAllPoints()
                OpenMailMoneyButton:SetPoint("TOPLEFT", OpenMailAttachmentText, "BOTTOMLEFT", 0, -8)
            end
        end

        for i = 1, 16 do
            local item = _G["OpenMailAttachmentButton" .. i]
            if i >= 2 and i <= 7 then
                local prevItem = _G["OpenMailAttachmentButton" .. i-1]
                item:ClearAllPoints()
                item:SetPoint("TOPLEFT", prevItem, "TOPRIGHT", 8 ,0)
            elseif i == 8 then
                local prevItem = _G["OpenMailAttachmentButton" .. 1]
                item:ClearAllPoints()
                item:SetPoint("TOPLEFT", prevItem, "BOTTOMLEFT", 0 ,-8)
            elseif i > 8 and i <= 14 then
                local prevItem = _G["OpenMailAttachmentButton" .. i-1]
                item:ClearAllPoints()
                item:SetPoint("TOPLEFT", prevItem, "TOPRIGHT", 8 ,0)
            elseif i == 15 then
                local prevItem = _G["OpenMailAttachmentButton" .. 8]
                item:ClearAllPoints()
                item:SetPoint("TOPLEFT", prevItem, "BOTTOMLEFT", 0 ,-8)
            elseif i > 15 and i <=16 then
                local prevItem = _G["OpenMailAttachmentButton" .. i-1]
                item:ClearAllPoints()
                item:SetPoint("TOPLEFT", prevItem, "TOPRIGHT", 8 ,0)
            end
        end 
    end)
end

-- Скрытие ненужных фреймов, регионов и текстур
local function hideFramesAndRegions()

    local function HideAllTextures(frame)
        if not frame then
            print("Указан пустой фрейм.")
            return
        end
    
        -- Перебираем все регионы фрейма
        for _, region in ipairs({frame:GetRegions()}) do
            if region:IsObjectType("Texture") then
                region:Hide() -- Скрываем текстуру
            end
        end
    end

    HideAllTextures(OpenMailFrame)
    HideAllTextures(OpenMailScrollFrame)

    local elementsToHide = {
        parentFrame.NineSlice,
        parentFrame.TopTileStreaks,
        parentFrame.Inset,
        parentFrame.PortraitContainer.portrait,
        parentFrame.Bg,
        parentFrame.TitleContainer,
        OpenMailFrameIcon,
        OpenMailHorizontalBarLeft,
        OpenMailReportSpamButton,
        OpenMailCancelButton,
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
    if not _G["OpenMailFrameNewBG"] and parentFrame then
        local frame = CreateFrame("Frame", "OpenMailFrameNewBG", parentFrame, "BackdropTemplate")
        frame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT") -- Привязываем верхнюю левую точку к CharacterFrame
        frame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", 0, -21)
        
        
        -- Устанавливаем уровень слоя фрейма ниже, чтобы текст CharacterLevelText был виден
        frame:SetFrameStrata("MEDIUM")
        frame:SetFrameLevel(OpenMailFrame:GetFrameLevel() - 1)

        -- Применяем стиль
        NineSliceUtil.ApplyLayoutByName(frame, "CharacterCreateDropdown")
        frame:SetAlpha(0.75)
    end
end

function ConsoleMenu:SetOpenMailFrame()

    moveFrames()
    hideFramesAndRegions()
    updateTextures()
    toggleController()
    createBackground()

end
