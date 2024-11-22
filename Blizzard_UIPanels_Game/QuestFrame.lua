-- QuestFrame.lua

local ConsoleMenu = LibStub("AceAddon-3.0"):GetAddon("ConsoleMenu")
local parentFrame = QuestFrame
local progressPanel = QuestFrameProgressPanel
local rewardPanel = QuestFrameRewardPanel
local detailPanel = QuestFrameDetailPanel
local greetingPanel = QuestFrameGreetingPanel

local offsetX = 40
local offsetY = 40
local scale = 1
local headerText = 24
local regularText = 14

-- Функция для обновления видимости ScrollBar
function UpdateScrollBarVisibility(scrollFrame)
    local scrollBar = scrollFrame.ScrollBar  -- Замените на правильный путь к вашему ScrollBar

    local contentHeight = scrollFrame:GetVerticalScrollRange() + scrollFrame:GetHeight()
    local containerHeight = scrollFrame:GetHeight()
    
    if contentHeight-1 < containerHeight then
        scrollBar:Hide()
    else
        scrollBar:Show()
    end
end

-- Функция для замены анимационной текстуры с возможностью изменения параметров
local function ReplaceAnimatedTextureInString(text, oldTextureName, newTextureName, newWidth, newHeight, newOffsetX, newOffsetY)
    if not text or not oldTextureName or not newTextureName then
        return text
    end

    -- Экранируем специальные символы в имени старой текстуры
    local function EscapePattern(str)
        return str:gsub("([%%%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    end

    local escapedOldTextureName = EscapePattern(oldTextureName)

    -- Шаблон для поиска анимационной текстуры с параметрами
    local pattern = "(|A:)" .. escapedOldTextureName .. ":(%d+):(%d+):([%-%d]+):([%-%d]+)(|a)"

    -- Функция замены, позволяющая изменить параметры
    local newText, count = text:gsub(pattern, function(startTag, width, height, offsetX, offsetY, endTag)
        -- Преобразуем параметры в числа
        width = tonumber(width)
        height = tonumber(height)
        offsetX = tonumber(offsetX)
        offsetY = tonumber(offsetY)

        -- Используем новые значения параметров, если они предоставлены
        local finalWidth = newWidth or width
        local finalHeight = newHeight or height
        local finalOffsetX = newOffsetX or offsetX
        local finalOffsetY = newOffsetY or offsetY

        -- Формируем новую последовательность
        return startTag .. newTextureName .. ":" .. finalWidth .. ":" .. finalHeight .. ":" .. finalOffsetX .. ":" .. finalOffsetY .. endTag
    end)

    return newText
end

-- Перемещение и изменение тточек привязки фреймов
local function moveFrames()

    if parentFrame.CloseButton then
        parentFrame.CloseButton:ClearAllPoints()
        parentFrame.CloseButton:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -3,-3)
    end

    parentFrame:HookScript("OnShow", function()
        if parentFrame:IsShown() then
            parentFrame:SetWidth(296 + offsetX*2)
            parentFrame:SetHeight(424 + offsetY*2+8)
        end
    end)

    if QuestDetailScrollFrame then
        QuestDetailScrollFrame:ClearAllPoints()
        QuestDetailScrollFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", offsetX-10, -offsetY+10)
    end

    if QuestProgressScrollFrame then
        QuestProgressScrollFrame:ClearAllPoints()
        QuestProgressScrollFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", offsetX-10, -offsetY+10)
    end

    if QuestRewardScrollFrame then
        QuestRewardScrollFrame:ClearAllPoints()
        QuestRewardScrollFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", offsetX-10, -offsetY+10)
    end

    if QuestGreetingScrollFrame then
        QuestGreetingScrollFrame:ClearAllPoints()
        QuestGreetingScrollFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", offsetX-10, -offsetY+10)
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
        parentFrame.TitleContainer,
        rewardPanel.SealMaterialBG,
        rewardPanel.Bg,
        progressPanel.SealMaterialBG,
        progressPanel.Bg,
        detailPanel.SealMaterialBG,
        detailPanel.Bg,
        QuestFrameAcceptButton,
        QuestFrameDeclineButton,
        QuestFrameCompleteQuestButton,
        QuestFrameCompleteButton,
        QuestFrameGoodbyeButton,
        greetingPanel.SealMaterialBG,
        greetingPanel.Bg,
        QuestFrameGreetingGoodbyeButton,
    }
        
    -- Скрываем все элементы из списка
    for _, element in ipairs(elementsToHide) do
        if element then
            element:Hide()
            element:SetAlpha(0)
        end
    end

end

-- Функция для создания кнопки "Принять"
local function CreateAcceptQuestButton()
    local button = CreateFrame("Button", "AccebtQuestButton", detailPanel, "SharedButtonLargeTemplate")
    button:SetSize(128, 32) -- Устанавливаем размер кнопки
    button:SetPoint("BOTTOMLEFT", detailPanel, "BOTTOMLEFT", offsetX-2, offsetY/2) -- Устанавливаем позицию кнопки в центре экрана
    button:SetText(ACCEPT) -- Устанавливаем текст на кнопке

    button:SetScript("OnClick", function(self)
        QuestDetailAcceptButton_OnClick()
    end)
end

-- Функция для создания кнопки "Отказаться"
local function CreateDeclineQuestButton()
    local button = CreateFrame("Button", "AcceptQuestButton", detailPanel, "SharedButtonLargeTemplate")
    button:SetSize(128, 32) -- Устанавливаем размер кнопки
    button:SetPoint("BOTTOMRIGHT", detailPanel, "BOTTOMRIGHT", 2, offsetY/2) -- Устанавливаем позицию кнопки в центре экрана
    button:SetText(DECLINE) -- Устанавливаем текст на кнопке

    button:SetScript("OnClick", function(self)
        QuestDetailDeclineButton_OnClick()
    end)
end

-- Функция для создания кнопки "Завершить"
local function CreateCompleteQuestButton()
    local button = CreateFrame("Button", "CompleteQuestButton", rewardPanel, "SharedButtonLargeTemplate")
    button:SetSize(128, 32) -- Устанавливаем размер кнопки
    button:SetPoint("BOTTOMLEFT", rewardPanel, "BOTTOMLEFT", offsetX-2, offsetY) -- Устанавливаем позицию кнопки в центре экрана
    button:SetText(COMPLETE_QUEST) -- Устанавливаем текст на кнопке

    button:SetScript("OnClick", function(self)
        QuestRewardCompleteButton_OnClick()
    end)
end

-- Функция для создания кнопки "Завершить"
local function CreateContinueQuestButton()
    local button = CreateFrame("Button", "ContinueQuestButton", progressPanel, "SharedButtonLargeTemplate")
    button:SetSize(128, 32) -- Устанавливаем размер кнопки
    button:SetPoint("BOTTOMLEFT", progressPanel, "BOTTOMLEFT", offsetX-2, offsetY) -- Устанавливаем позицию кнопки в центре экрана
    button:SetText(CONTINUE) -- Устанавливаем текст на кнопке

    button:SetScript("OnClick", function(self)
        QuestProgressCompleteButton_OnClick()
    end)
end

-- Функция для создания кнопки "Отказаться"
local function CreateGoodbyeQuestButton()
    local button = CreateFrame("Button", "GoodbyeQuestButton", progressPanel, "SharedButtonLargeTemplate")
    button:SetSize(128, 32) -- Устанавливаем размер кнопки
    button:SetPoint("BOTTOMRIGHT", progressPanel, "BOTTOMRIGHT", -offsetX-2, offsetY) -- Устанавливаем позицию кнопки в центре экрана
    button:SetText(CANCEL) -- Устанавливаем текст на кнопке

    button:SetScript("OnClick", function(self)
        QuestGoodbyeButton_OnClick()
    end)
end

local function CreateGreetingGoodbyeButton()
    local button = CreateFrame("Button", "GoodbyeGreetingButton", greetingPanel, "SharedButtonLargeTemplate")
    button:SetSize(128, 32) -- Устанавливаем размер кнопки
    button:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -offsetX-2, offsetY) -- Устанавливаем позицию кнопки в центре экрана
    button:SetText(GOODBYE) -- Устанавливаем текст на кнопке

    button:SetScript("OnClick", function(self)
        HideUIPanel(QuestFrame)
    end)
end

-- Обновление текстур фрейсов и регионов
local function updateTextures()
    CreateAcceptQuestButton()
    CreateDeclineQuestButton()
    CreateCompleteQuestButton()
    CreateContinueQuestButton()
    CreateGoodbyeQuestButton()
    CreateGreetingGoodbyeButton()

    QuestGreetingScrollChildFrame:HookScript("OnUpdate", function()
        UpdateScrollBarVisibility(QuestGreetingScrollFrame)
    
        for _, region in ipairs({QuestGreetingScrollChildFrame:GetRegions()}) do
            if region:IsObjectType("FontString") then
                region:SetTextColor(1, 1, 1)
            end
        end

        -- Функция для удаления цветовых кодов из текста
        local function RemoveColorCodes(text)
            if not text then return "" end
            text = text:gsub("|c%x%x%x%x%x%x%x%x", "")  -- Удаляем цветовые коды начала
            text = text:gsub("|r", "")  -- Удаляем код окончания цвета
            return text
        end

        -- Перебираем все дочерние элементы greetingPanel
        for _, child in ipairs({greetingPanel:GetChildren()}) do
            if child.Icon then  -- Проверяем, содержит ли дочерний элемент свойство Icon
                -- Перебираем все регионы дочернего элемента
                for _, reg in ipairs({child:GetRegions()}) do
                    if reg:IsObjectType("FontString") then  -- Ищем регионы типа FontString
                        -- Получаем текущий текст региона
                        local text = reg:GetText()
                        -- Удаляем цветовые коды из текста
                        local cleanText = RemoveColorCodes(text)
                        -- Устанавливаем очищенный текст обратно в регион
                        reg:SetText(cleanText)
                        -- Устанавливаем желаемый цвет текста
                        reg:SetTextColor(1, 1, 1, 1)  -- Белый цвет с полной непрозрачностью
                    end
                end
            end
        end
        
    end)


    QuestDetailScrollChildFrame:HookScript("OnUpdate", function()
        UpdateScrollBarVisibility(detailPanel.ScrollFrame)

        if QuestInfoTitleHeader then
            QuestInfoTitleHeader:SetFont(QuestInfoTitleHeader:GetFont(), headerText)
            QuestInfoTitleHeader:SetText(ReplaceAnimatedTextureInString(QuestInfoTitleHeader:GetText(), "CampaignAvailableQuestIcon", "Crosshair_campaignquest_128", 14,14,-20,2))
            QuestInfoTitleHeader:SetText(ReplaceAnimatedTextureInString(QuestInfoTitleHeader:GetText(), "Recurringavailablequesticon", "Crosshair_Recurring_128", 14,14,0,0))
            QuestInfoTitleHeader:SetText(ReplaceAnimatedTextureInString(QuestInfoTitleHeader:GetText(), "questlog-questtypeicon-dungeon", "Dungeon", 16,16,-4,0))
            QuestInfoTitleHeader:SetText(ReplaceAnimatedTextureInString(QuestInfoTitleHeader:GetText(), "legendaryavailablequesticon", "Crosshair_legendaryquest_64", 14,14,0,0))
            QuestInfoTitleHeader:SetText(ReplaceAnimatedTextureInString(QuestInfoTitleHeader:GetText(), "questlog-questtypeicon-raid", "Raid", 14,14,0,0))

        end

        if QuestInfoDescriptionText then
            QuestInfoDescriptionText:ClearAllPoints()
            QuestInfoDescriptionText:SetPoint("TOPLEFT", QuestInfoTitleHeader, "BOTTOMLEFT", 0, -offsetY/2+4)
        end
    
        for _, region in ipairs({QuestDetailScrollChildFrame  :GetRegions()}) do
            if region:IsObjectType("FontString") then
                region:SetTextColor(1, 1, 1)
            end
        end

        for _, region in ipairs({QuestInfoRewardsFrame:GetRegions()}) do
            if region:IsObjectType("FontString") then
                region:SetTextColor(1, 1, 1)
            end
        end

        for _, child in ipairs({QuestInfoRewardsFrame:GetChildren()}) do
            for _, reg in ipairs({child:GetRegions()}) do
                if reg:IsObjectType("FontString") then
                    reg:SetTextColor(1, 1, 1)
                end
            end
        end

        for i = 1, 10 do
            local item = _G["QuestInfoRewardsFrameQuestInfoItem" .. i]
            if item then
                item.NameFrame:Hide()
                ApplyMaskToTexture(item.Icon)
            end
        end 
        
    end)

    QuestModelScene:HookScript("OnShow", function()
        UpdateScrollBarVisibility(QuestNPCModelTextScrollFrame)
    end)

    QuestProgressScrollChildFrame:HookScript("OnUpdate", function()
        UpdateScrollBarVisibility(QuestProgressScrollFrame)

        if QuestProgressTitleText then
            QuestProgressTitleText:SetFont(QuestInfoTitleHeader:GetFont(), headerText)
        end

        if QuestProgressText then
            QuestProgressText:ClearAllPoints()
            QuestProgressText:SetPoint("TOPLEFT", QuestProgressTitleText, "BOTTOMLEFT", 0, -offsetY/2+4)
        end

        for _, region in ipairs({QuestProgressScrollChildFrame  :GetRegions()}) do
            if region:IsObjectType("FontString") then
                region:SetTextColor(1, 1, 1)
            end
        end
    end)

    QuestRewardScrollChildFrame:HookScript("OnUpdate", function()
        UpdateScrollBarVisibility(QuestRewardScrollFrame)

        if QuestInfoTitleHeader then
            QuestInfoTitleHeader:SetFont(QuestInfoTitleHeader:GetFont(), headerText)
            QuestInfoTitleHeader:SetText(ReplaceAnimatedTextureInString(QuestInfoTitleHeader:GetText(), "CampaignAvailableQuestIcon", "Crosshair_campaignquest_128", 14,14,-20,2))
            QuestInfoTitleHeader:SetText(ReplaceAnimatedTextureInString(QuestInfoTitleHeader:GetText(), "Recurringavailablequesticon", "Crosshair_Recurring_128", 14,14,0,0))
            QuestInfoTitleHeader:SetText(ReplaceAnimatedTextureInString(QuestInfoTitleHeader:GetText(), "questlog-questtypeicon-dungeon", "Dungeon", 16,16,-4,0))
            QuestInfoTitleHeader:SetText(ReplaceAnimatedTextureInString(QuestInfoTitleHeader:GetText(), "legendaryavailablequesticon", "Crosshair_legendaryquest_64", 14,14,0,0))
            QuestInfoTitleHeader:SetText(ReplaceAnimatedTextureInString(QuestInfoTitleHeader:GetText(), "questlog-questtypeicon-raid", "Raid", 14,14,0,0))
        end

        if QuestInfoRewardText then
            QuestInfoRewardText:ClearAllPoints()
            QuestInfoRewardText:SetPoint("TOPLEFT", QuestInfoTitleHeader, "BOTTOMLEFT", 0, -offsetY/2+4)
        end

        for _, region in ipairs({QuestRewardScrollChildFrame:GetRegions()}) do
            if region:IsObjectType("FontString") then
                region:SetTextColor(1, 1, 1)
            end
        end

        for _, region in ipairs({QuestInfoRewardsFrame:GetRegions()}) do
            if region:IsObjectType("FontString") then
                region:SetTextColor(1, 1, 1)
            end
        end

        for _, child in ipairs({QuestInfoRewardsFrame:GetChildren()}) do
            for _, reg in ipairs({child:GetRegions()}) do
                if reg:IsObjectType("FontString") then
                    reg:SetTextColor(1, 1, 1)
                end
            end
        end

        for i = 1, 10 do
            local item = _G["QuestInfoRewardsFrameQuestInfoItem" .. i]
            if item then
                item.NameFrame:Hide()
                ApplyMaskToTexture(item.Icon)
            end
        end 

    end)

    for i = 1, 6 do
        local item = _G["QuestProgressItem" .. i]
        item.NameFrame:Hide()
        ApplyMaskToTexture(item.Icon)
        item.IconBorder:SetAtlas("plunderstorm-actionbar-slot-border")
        item.IconBorder:Show()
        item.IconBorder:ClearAllPoints()
        item.IconBorder:SetPoint("CENTER", item.Icon, "CENTER")
        item.IconBorder:SetSize(56, 56)
    end

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
    if not _G["QuestFrameNewBG"] then
        -- Создаем фрейм с использованием CPPopupFrameBaseTemplate
        local frame = CreateFrame("Frame", "QuestFrameNewBG", parentFrame, "CPPopupFrameBaseTemplate")
        frame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT") -- Привязываем верхнюю левую точку к CharacterFrame
        frame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", 0, -21)
        
        
        -- Устанавливаем уровень слоя фрейма ниже, чтобы текст CharacterLevelText был виден
        frame:SetFrameStrata("MEDIUM")
        frame:SetFrameLevel(CharacterFrame:GetFrameLevel() - 1)
    end
end

function ConsoleMenu:SetQuestFrame()

    moveFrames()
    hideFramesAndRegions()
    updateTextures()
    toggleController()
    createBackground()

end
