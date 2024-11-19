-- QuestFrame.lua

local ConsoleMenu = LibStub("AceAddon-3.0"):GetAddon("ConsoleMenu")
local parentFrame = QuestFrame
local progressPanel = QuestFrameProgressPanel
local rewardPanel = QuestFrameRewardPanel
local detailPanel = QuestFrameDetailPanel

local offsetX = 40
local offsetY = 40
local scale = 1
local headerText = 24

-- Функция для обновления видимости ScrollBar
 function UpdateScrollBarVisibility(scrollFrame)
    local scrollBar = scrollFrame.ScrollBar  -- Замените на правильный путь к вашему ScrollBar

    local contentHeight = scrollFrame:GetVerticalScrollRange() + scrollFrame:GetHeight()
    local containerHeight = scrollFrame:GetHeight()
    
    if contentHeight <= containerHeight then
        scrollBar:Hide()
    else
        scrollBar:Show()
    end
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

    if QuestFrameCompleteButton then
        QuestFrameCompleteButton:ClearAllPoints()
        QuestFrameCompleteButton:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", offsetX, offsetY)
    end

    if QuestFrameGoodbyeButton then
        QuestFrameGoodbyeButton:ClearAllPoints()
        QuestFrameGoodbyeButton:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -offsetX, offsetY)
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

-- Обновление текстур фрейсов и регионов
local function updateTextures()
    QuestDetailScrollChildFrame:HookScript("OnUpdate", function()
        UpdateScrollBarVisibility(detailPanel.ScrollFrame)
        if QuestInfoTitleHeader then
            QuestInfoTitleHeader:SetFont(QuestInfoTitleHeader:GetFont(), headerText)
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

    CreateAcceptQuestButton()
    CreateDeclineQuestButton()
    CreateCompleteQuestButton()
    CreateContinueQuestButton()
    CreateGoodbyeQuestButton()

    QuestProgressScrollChildFrame:HookScript("OnUpdate", function()
        UpdateScrollBarVisibility(QuestProgressScrollFrame)

        if QuestProgressTitleText then
            QuestProgressTitleText:SetFont(QuestInfoTitleHeader:GetFont(), headerText)
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
