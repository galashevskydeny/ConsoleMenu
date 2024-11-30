-- GossipFrame.lua

local ConsoleMenu = LibStub("AceAddon-3.0"):GetAddon("ConsoleMenu")
local parentFrame = GossipFrame
local titleSize = 20

local offsetX = 40
local offsetY = 40
local scale = 1

-- Перемещение и изменение тточек привязки фреймов
local function moveFrames()

    parentFrame:HookScript("OnShow", function()
        if parentFrame:IsShown() then
            -- parentFrame:SetWidth()
            -- parentFrame:SetHeight()
        end
    end)

    parentFrame:HookScript("OnUpdate", function()
        if parentFrame:IsShown() then
            if parentFrame.GreetingPanel then
                parentFrame.GreetingPanel:ClearAllPoints()
                parentFrame.GreetingPanel:SetPoint("LEFT", parentFrame, "LEFT", offsetX, 0)
        
                if parentFrame.FriendshipStatusBar:IsShown() then
                    parentFrame.GreetingPanel:SetPoint("TOP", parentFrame.FriendshipStatusBar, "BOTTOM", 0, -offsetY/2)
                else
                    parentFrame.GreetingPanel:SetPoint("TOP", parentFrame.TitleContainer.TitleText, "BOTTOM", 0, -offsetY/2)
                end
        
                parentFrame.GreetingPanel:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -offsetX, offsetY)
            end
        end
    end)

    if parentFrame.CloseButton then
        parentFrame.CloseButton:ClearAllPoints()
        parentFrame.CloseButton:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -3,-3)
    end

    if parentFrame.TitleContainer.TitleText then
        -- Устанавливаем новый размер шрифта и выравнивание
        parentFrame.TitleContainer.TitleText:SetFont(parentFrame.TitleContainer.TitleText:GetFont(), titleSize) -- Меняем размер шрифта на 20
        parentFrame.TitleContainer.TitleText:SetJustifyH("LEFT") -- Выравниваем по левому краю
    end

    if parentFrame.TitleContainer then
        -- Очищаем все привязки
        parentFrame.TitleContainer:ClearAllPoints()
        
        parentFrame.TitleContainer:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", offsetX, -offsetY)
        parentFrame.TitleContainer:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -offsetX, -offsetY)
    end

    if parentFrame.FriendshipStatusBar then
        parentFrame.FriendshipStatusBar:ClearAllPoints()
        if parentFrame.TitleContainer.TitleText:IsShown() then
            parentFrame.FriendshipStatusBar:SetPoint("TOPLEFT", parentFrame.TitleContainer.TitleText, "TOPLEFT", 16, -offsetY/2-24)
        else
            parentFrame.FriendshipStatusBar:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", -offsetX, -offsetY)
        end
    end

    if parentFrame.GreetingPanel.ScrollBox then
        parentFrame.GreetingPanel.ScrollBox:ClearAllPoints()
        parentFrame.GreetingPanel.ScrollBox:SetPoint("TOPLEFT", parentFrame.GreetingPanel, "TOPLEFT", -12, 12)
        parentFrame.GreetingPanel.ScrollBox:SetPoint("BOTTOMRIGHT", parentFrame.GreetingPanel, "BOTTOMRIGHT", 12, 0)
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
    parentFrame.GreetingPanel:HookScript("OnUpdate", function()
        local contentHeight = parentFrame.GreetingPanel.ScrollBox.ScrollTarget:GetHeight()
        local containerHeight = parentFrame.GreetingPanel.ScrollBox:GetHeight()

        if contentHeight <= containerHeight then
            parentFrame.GreetingPanel.ScrollBar:Hide()
        else
            parentFrame.GreetingPanel.ScrollBar:Show()
        end

        for _, child in ipairs({parentFrame.GreetingPanel.ScrollBox.ScrollTarget:GetChildren()}) do
            for _, reg in ipairs({child:GetRegions()}) do
                if reg:IsObjectType("FontString") then
                    -- Получаем текущий текст
                    local text = reg:GetText()
                    if text then
                        -- Удаляем цветовые коды из текста
                        -- Удаляем коды цвета типа "|cFFFFFFFF"
                        text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
                        -- Удаляем код сброса цвета "|r"
                        text = text:gsub("|r", "")
                        
                        -- Устанавливаем очищенный текст
                        reg:SetText(text)
                    end

                    -- Устанавливаем цвет текста в белый
                    reg:SetTextColor(1, 1, 1)
                elseif reg:IsObjectType("Texture") then
                    if reg:GetTexture() == 132053 then
                        reg:SetAtlas("crosshair_speak_64")
                        -- gossip
                    elseif reg:GetTexture() == 132049 then
                        --quest
                        reg:SetAtlas("Crosshair_Quest_64")
                    elseif reg:GetTexture() == 132060 then
                        --vendor
                        reg:SetAtlas("Crosshair_buy_64")
                    elseif reg:GetTexture() == 5666025 then
                        if reg:GetAtlas() == "WrapperInProgressquesticon" then
                        elseif reg:GetAtlas() == "SideInProgressquesticon" then
                        end
                    elseif reg:GetTexture() == 3595324 then
                        if reg:GetAtlas() == "CampaignAvailableQuestIcon" then
                            --campaign quest
                            reg:SetAtlas("Quest-Campaign-Available")
                        elseif reg:GetAtlas() == "" then
                        end
                    end
                    print(reg:GetTexture())
                end
            end
        end
    end)
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
    if not _G["GossipFrameNewBG"] then
        local frame = CreateFrame("Frame", "GossipFrameNewBG", parentFrame, "BackdropTemplate")
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

function ConsoleMenu:SetGossipFrame()

    moveFrames()
    hideFramesAndRegions()
    updateTextures()
    --toggleController()
    createBackground()

end
