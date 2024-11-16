-- MailFrame.lua

local ConsoleMenu = LibStub("AceAddon-3.0"):GetAddon("ConsoleMenu")
local parentFrame = MailFrame
local titleSize = 20

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
            parentFrame:SetWidth(338 + offsetX*2)
            parentFrame:SetHeight(424 + offsetY*2-32+titleSize)
        end
    end)

    if parentFrame.TitleContainer.TitleText then
        -- Устанавливаем новый размер шрифта и выравнивание
        parentFrame.TitleContainer.TitleText:SetFont(CharacterFrameTitleText:GetFont(), titleSize) -- Меняем размер шрифта на 20
        parentFrame.TitleContainer.TitleText:SetJustifyH("LEFT") -- Выравниваем по левому краю
    end

    if parentFrame.TitleContainer then
        -- Очищаем все привязки
        parentFrame.TitleContainer:ClearAllPoints()
        
        -- Устанавливаем новые привязки с отступом слева 24 пикселя и теми же значениями для других параметров
        parentFrame.TitleContainer:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", offsetX + 4, -offsetY-4)
        parentFrame.TitleContainer:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -offsetX, -offsetY-4)
    end

    if InboxFrame then
        InboxFrame:ClearAllPoints()
        InboxFrame:SetPoint("TOPLEFT", parentFrame.TitleContainer, "BOTTOMLEFT", 0, -offsetY+16)
        InboxFrame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -offsetX, offsetY)
    end

    if MailItem1 then
        MailItem1:ClearAllPoints()
        MailItem1:SetPoint("TOPLEFT", InboxFrame, "TOPLEFT", 0, 0)
        MailItem1:SetPoint("TOPRIGHT", InboxFrame, "TOPRIGHT", 0, 0)
    end

    if InboxPrevPageButton then
        InboxPrevPageButton:ClearAllPoints()
        InboxPrevPageButton:SetPoint("BOTTOMLEFT", InboxFrame, "BOTTOMLEFT", 0, 0)
    end

    if OpenAllMail then
        OpenAllMail:ClearAllPoints()
        OpenAllMail:SetPoint("BOTTOM", InboxFrame, "BOTTOM", 0, 0)
    end

    if InboxNextPageButton then
        InboxNextPageButton:ClearAllPoints()
        InboxNextPageButton:SetPoint("BOTTOMRIGHT", InboxFrame, "BOTTOMRIGHT", 0, 0)
    end

    -- Проверяем, существует ли CharacterFrameTab1
    if MailFrameTab1 then
        -- Очищаем текущие привязки
        MailFrameTab1:ClearAllPoints()
        
        -- Устанавливаем новую привязку с изменением смещения по X
        MailFrameTab1:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", offsetX, 2)
    end

    MailFrameTab1:HookScript("OnShow", function()
        MailFrameTab1:SetWidth(136)
        MailFrameTab1.Text:SetWidth(128)
    end)
end

-- Скрытие ненужных фреймов, регионов и текстур
local function hideFramesAndRegions()
    local elementsToHide = {
        MailFrame.NineSlice,
        MailFrame.TopTileStreaks,
        MailFrameInset,
        MailFramePortrait,
        MailFrameBg,
        InboxFrameBg,
        OpenAllMail,
        InboxPrevPageButton,
        InboxNextPageButton,
    }

    -- Скрываем все элементы из списка
    for _, element in ipairs(elementsToHide) do
        if element then
            element:Hide()
            element:SetAlpha(0)
        end
    end

end

-- Функция для создания кнопки "Открыть все"
local function CreateOpenAllMailButton()
    local button = CreateFrame("Button", "MyGoldRedButton", InboxFrame, "SharedGoldRedButtonTemplate")
    button:SetSize(128, 32) -- Устанавливаем размер кнопки
    button:SetPoint("BOTTOM", InboxFrame, "BOTTOM", 0,0) -- Устанавливаем позицию кнопки в центре экрана
    button:SetText(OPEN_ALL_MAIL_BUTTON) -- Устанавливаем текст на кнопке

    Mixin(button, OpenAllMailMixin)
    button:SetScript("OnLoad", function(self)
        button:OnLoad()
    end)

    button:SetScript("OnClick", function(self)
        button:OnClick()
    end)

    button:SetScript("OnUpdate", function(self, dt)
        button:OnUpdate(dt)
    end)    

    button:SetScript("OnEvent", function(self)
        button:OnEvent()
    end)

    button:SetScript("OnHide", function(self)
        button:OnHide()
    end)
end

-- Функция для созданяи кнопки "Далее"
local function CreateNextPageButton()
    -- Создаем кнопку с шаблоном CommonSquareIconButtonTemplate
    local button = CreateFrame("Button", "InboxNextPageButtonNew", InboxFrame, "CommonSquareIconButtonTemplate")
    button:SetPoint("BOTTOMRIGHT") -- Устанавливаем позицию кнопки
    button:SetSize(32, 32) -- Устанавливаем размер кнопки
    
    local buttonText = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buttonText:SetText(NEXT) -- Замените на ваш текст
    buttonText:SetPoint("RIGHT", button, "LEFT", -4, 0)

    -- Устанавливаем иконку из атласа
    button.Icon:SetAtlas("common-icon-forwardarrow")

    -- Уменьшаем размер иконки
    button.Icon:SetScale(0.7)

    -- Центрируем иконку внутри кнопки (на случай, если она сместилась)
    button.Icon:SetPoint("CENTER", button, "CENTER", 0, 0)

    -- Добавляем обработчик события клика
    button:SetScript("OnClick", function(self)
        if InboxNextPageButton:IsEnabled() then
            InboxNextPage()
        end
    end)

    InboxFrame:HookScript("OnUpdate", function()
        if InboxNextPageButton:IsEnabled() then
            button:Enable()
            button.Icon:SetDesaturated(false)
        else
            button:Disable()
            button.Icon:SetDesaturated(true)
        end
    end)
end

-- Функция для созданяи кнопки "Далее"
local function CreatePrevPageButton()
    -- Создаем кнопку с шаблоном CommonSquareIconButtonTemplate
    local button = CreateFrame("Button", "InboxPrevPageButtonNew", InboxFrame, "CommonSquareIconButtonTemplate")
    button:SetPoint("BOTTOMLEFT") -- Устанавливаем позицию кнопки
    button:SetSize(32, 32) -- Устанавливаем размер кнопки
    
    local buttonText = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buttonText:SetText(PREV) -- Замените на ваш текст
    buttonText:SetPoint("LEFT", button, "RIGHT", 4, 0)

    -- Устанавливаем иконку из атласа
    button.Icon:SetAtlas("common-icon-backarrow")

    -- Уменьшаем размер иконки
    button.Icon:SetScale(0.7)

    -- Центрируем иконку внутри кнопки (на случай, если она сместилась)
    button.Icon:SetPoint("CENTER", button, "CENTER", 0, 0)

    -- Добавляем обработчик события клика
    button:SetScript("OnClick", function(self)
        if InboxPrevPageButton:IsEnabled() then
            InboxPrevPage()
        end
    end)

    InboxFrame:HookScript("OnUpdate", function()
        if InboxPrevPageButton:IsEnabled() then
            button:Enable()
            button.Icon:SetDesaturated(false)
        else
            button:Disable()
            button.Icon:SetDesaturated(true)
        end
    end)
end

-- Обновление текстур фрейсов и регионов
local function updateTextures()
    for i = 1, 7 do
        local frame = _G["MailItem" .. i]
        if i >= 2 then
            local prevItem = _G["MailItem" .. i-1]
            frame:SetPoint("TOPRIGHT", prevItem, "TOPRIGHT", 0 ,0)
        end
        if frame then
            local regions = {frame:GetRegions()}
            
            if regions[1] then
                regions[1]:SetSize(42, 42) -- Устанавливаем размер, равный родительскому фрейму
                regions[1]:SetAtlas("UI-HUD-ActionBar-IconFrame-Slot") -- Первому региону устанавливаем текстуру из атласа
                regions[1]:SetTexCoord(0, 1, 0, 1)
                regions[1]:SetAlpha(0.75)
                local itemSlot = frame:CreateTexture(nil, "BACKGROUND")
                itemSlot:SetSize(56, 56)
                itemSlot:SetAtlas("plunderstorm-actionbar-slot-border")
                itemSlot:SetTexCoord(0, 1, 0, 1)
                itemSlot:SetPoint("CENTER", regions[1], "CENTER", 0,0)
                itemSlot:SetAlpha(0.75)
            end
    
            if regions[2] then
                regions[2]:Hide() -- Второй регион скрываем
            end
    
            if regions[3] then
                regions[3]:SetAtlas("plunderstorm-glues-tutorial-line") -- Третьему региону устанавливаем текстуру из атласа
                regions[3]:SetAlpha(0.5)
                if i == 7 then regions[3]:Hide() end
            end
        else
            print("Frame MailItem" .. i .. " not found.")
        end

        local sender = _G["MailItem" .. i .. "Sender"]
        if sender then
            sender:ClearAllPoints()
            sender:SetPoint("TOPLEFT", frame, 42+16, -7)
        end

        icon = _G["MailItem" .. i .. "ButtonIcon"]
        ApplyMaskToTexture(icon)

        local slot = _G["MailItem" .. i .. "ButtonSlot"]
        if slot then
            slot:ClearAllPoints()
            slot:SetPoint("CENTER", icon, "CENTER", 0, 0)
            slot:SetSize(56, 56)
            slot:SetAtlas("plunderstorm-actionbar-slot-border")
            slot:SetTexCoord(0, 1, 0, 1)
        end
    end    
    
    CreateOpenAllMailButton()
    CreateNextPageButton()
    CreatePrevPageButton()

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
    if not _G["MailFrameNewBG"] and parentFrame then
        -- Создаем фрейм с использованием CPPopupFrameBaseTemplate
        local frame = CreateFrame("Frame", "MailFrameNewBG", parentFrame, "CPPopupFrameBaseTemplate")
        frame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT") -- Привязываем верхнюю левую точку к CharacterFrame
        frame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", 0, -21)
        
        
        -- Устанавливаем уровень слоя фрейма ниже, чтобы текст CharacterLevelText был виден
        frame:SetFrameStrata("MEDIUM")
        frame:SetFrameLevel(CharacterFrame:GetFrameLevel() - 1)
    end
end

function ConsoleMenu:SetMailFrame()

    moveFrames()
    hideFramesAndRegions()
    updateTextures()
    toggleController()
    createBackground()

end
