-- QuestFrame.lua

local ConsoleMenu = LibStub("AceAddon-3.0"):GetAddon("ConsoleMenu")
local parentFrame = QuestFrame
local progressPanel = QuestFrameProgressPanel
local rewardPanel = QuestFrameRewardPanel
local detailPanel = QuestFrameDetailPanel

local offsetX = 40
local offsetY = 40
local scale = 1

-- Перемещение и изменение тточек привязки фреймов
local function moveFrames()

    if parentFrame.CloseButton then
        parentFrame.CloseButton:ClearAllPoints()
        parentFrame.CloseButton:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -3,-3)
    end

    parentFrame:HookScript("OnShow", function()
        if parentFrame:IsShown() then
            parentFrame:SetWidth(296 + offsetX*2)
            parentFrame:SetHeight(424 + offsetY*2)
        end
    end)

    if QuestDetailScrollFrame then
        QuestDetailScrollFrame:ClearAllPoints()
        QuestDetailScrollFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", offsetX-10, -offsetY+10)
    end

    if QuestFrameAcceptButton then
        QuestFrameAcceptButton:ClearAllPoints()
        QuestFrameAcceptButton:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", offsetX, offsetY)
    end

    if QuestFrameDeclineButton then
        QuestFrameDeclineButton:ClearAllPoints()
        QuestFrameDeclineButton:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -offsetX, offsetY)
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

    if QuestFrameCompleteQuestButton then
        QuestFrameCompleteQuestButton:ClearAllPoints()
        QuestFrameCompleteQuestButton:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", offsetX, offsetY)
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
    QuestDetailScrollChildFrame:HookScript("OnUpdate", function()
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

    QuestProgressScrollChildFrame:HookScript("OnUpdate", function()
        for _, region in ipairs({QuestProgressScrollChildFrame  :GetRegions()}) do
            if region:IsObjectType("FontString") then
                region:SetTextColor(1, 1, 1)
            end
        end
    end)

    QuestRewardScrollChildFrame:HookScript("OnUpdate", function()
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
