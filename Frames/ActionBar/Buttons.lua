-- Сборка одной кнопки панели: фон, маска, восстановление, счётчик и значок клавиши.

local ConsoleMenu = _G.ConsoleMenu
local ActionBar = ConsoleMenu.ActionBar

-- Создание рамки кнопки для ячейки панели.
function ActionBar.CreateButton(parent, slotID)
    local buttonFrame = CreateFrame("Frame", "ActionButton" .. slotID, parent)
    parent["ActionButton" .. slotID] = buttonFrame

    local isSlot12 = ActionBar.slot12Slots[slotID]

    if isSlot12 then
        buttonFrame:SetSize(ActionBar.slot12ContainerWidth, ActionBar.slot12ContainerHeight)
    else
        buttonFrame:SetSize(ActionBar.buttonSize, ActionBar.buttonSize)
    end
    ConsoleMenu:InitFadeAnimations(buttonFrame, ActionBar.animationDuration)

    local textureFileID = C_ActionBar.GetActionTexture(slotID)
    if issecretvalue(textureFileID) then
        -- Не считаем слот пустым: просто отложим установку текстуры.
        textureFileID = nil
    end

    local backgroundSize = ActionBar.buttonSize + 8

    -- Контейнерный фон GroupIcon3 для слота 12 (тачпад)
    if isSlot12 then
        local groupBackground = buttonFrame:CreateTexture(nil, "BACKGROUND", nil, -1)
        groupBackground:SetAllPoints(buttonFrame)
        groupBackground:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\GroupIcon3.png")
        buttonFrame.groupBackground = groupBackground
    end

    -- Добавляем фон под иконку, тоже текстура (создаем первым, чтобы был ниже)
    local background = buttonFrame:CreateTexture(nil, "BACKGROUND")
    background:SetSize(backgroundSize, backgroundSize)
    background:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\pad-background.png")
    background:SetVertexColor(0, 0, 0, 1)
    buttonFrame.background = background

    local texture = buttonFrame:CreateTexture(nil, "ARTWORK")
    texture:SetSize(ActionBar.buttonSize, ActionBar.buttonSize)
    if textureFileID then
        texture:SetTexture(textureFileID)
        local edge = 3 / ActionBar.buttonSize
        texture:SetTexCoord(edge, 1 - edge, edge, 1 - edge)
    end

    if isSlot12 then
        background:SetPoint("LEFT", buttonFrame, "LEFT", ActionBar.slot12IconPadding, 0)
        texture:SetPoint("CENTER", background, "CENTER", 0, 0)
    else
        background:SetPoint("CENTER", buttonFrame, "CENTER", 0, 0)
        texture:SetAllPoints(buttonFrame)
    end
    
    -- Создаём маску для текстуры
    local mask = buttonFrame:CreateMaskTexture()
    mask:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\MaskCircle.png")
    mask:SetAllPoints(texture)
    texture:AddMaskTexture(mask)
    
    -- Сохраняем ссылку на текстуру в buttonFrame
    buttonFrame.texture = texture
    
    -- Создаём CooldownFrame для автоматической обработки кулдаунов
    local cooldown = CreateFrame("Cooldown", nil, buttonFrame, "CooldownFrameTemplate")
    cooldown:SetAllPoints(texture)
    cooldown:SetDrawBling(false)
    cooldown:SetDrawSwipe(false)
    cooldown:SetDrawEdge(false)

    
    buttonFrame.cooldown = cooldown
    
    buttonFrame.cooldown:HookScript("OnHide", function()
        -- Кулдаун исчез
        RunNextFrame(function()
            ActionBar.UpdateTextureDesaturation(buttonFrame, slotID)
        end)
    end)

    buttonFrame.cooldown:SetScript("OnCooldownDone", function()
        -- Кулдаун закончился
        RunNextFrame(function()
            ActionBar.UpdateTextureDesaturation(buttonFrame, slotID)
        end)
    end)

    -- Название действия справа от иконки (слот 12)
    if isSlot12 then
        buttonFrame.Label = buttonFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        buttonFrame.Label:SetPoint("LEFT", background, "RIGHT", ActionBar.slot12LabelGap, 0)
        buttonFrame.Label:SetPoint("RIGHT", buttonFrame, "RIGHT", -ActionBar.slot12LabelRightPadding, 0)
        buttonFrame.Label:SetPoint("TOP", buttonFrame, "TOP", 0, -ActionBar.slot12LabelEdgePadding)
        buttonFrame.Label:SetPoint("BOTTOM", buttonFrame, "BOTTOM", 0, ActionBar.slot12LabelEdgePadding)
        buttonFrame.Label:SetJustifyH("LEFT")
        buttonFrame.Label:SetJustifyV("MIDDLE")
        buttonFrame.Label:SetWordWrap(true)
        buttonFrame.Label:SetNonSpaceWrap(true)
        buttonFrame.Label:SetMaxLines(2)
        buttonFrame.Label:SetTextColor(1.0, 0.960784, 0.772549, 1)
        buttonFrame.Label:SetFont("Fonts\\FRIZQT___CYR.TTF", ActionBar.slot12LabelFontSize, "")
        buttonFrame.Label:SetText("")
    end

    -- Счетчик стаков
    if not buttonFrame.StackCount then
        buttonFrame.StackCount = CreateFrame("Frame", "ActionButtonStackCount" .. slotID, buttonFrame)
        buttonFrame.StackCount:SetSize(ActionBar.stackCountSize, ActionBar.stackCountSize)
        buttonFrame.StackCount:SetPoint("BOTTOMRIGHT", buttonFrame.texture, "BOTTOMRIGHT", ActionBar.stackCountOffset, -ActionBar.stackCountOffset)
        ConsoleMenu:InitFadeAnimations(buttonFrame.StackCount, ActionBar.animationDuration)

        buttonFrame.StackCount:Hide()

        -- Фон счетчика
        if not buttonFrame.StackCount.Background then
            buttonFrame.StackCount.Background = buttonFrame.StackCount:CreateTexture(nil, "ARTWORK")
            buttonFrame.StackCount.Background:SetAllPoints()
            buttonFrame.StackCount.Background:SetAlpha(0.5)

            local texture = ConsoleMenu.Backgrounds["PAD"]
            buttonFrame.StackCount.Background:SetTexture(texture)
        end

        -- Тень счетчика
        if not buttonFrame.StackCount.Shadow then
            buttonFrame.StackCount.Shadow = buttonFrame.StackCount:CreateTexture(nil, "BACKGROUND")
            buttonFrame.StackCount.Shadow:SetPoint("TOPLEFT", buttonFrame.StackCount.Background, "TOPLEFT", -ActionBar.stackCountShadowOffsef, ActionBar.stackCountShadowOffsef)
            buttonFrame.StackCount.Shadow:SetPoint("BOTTOMRIGHT", buttonFrame.StackCount.Background, "BOTTOMRIGHT", ActionBar.stackCountShadowOffsef, -ActionBar.stackCountShadowOffsef)

            local texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png"
            buttonFrame.StackCount.Shadow:SetTexture(texture)
        end

        -- Текст счетчика
        if not buttonFrame.StackCount.Text then
            buttonFrame.StackCount.Text = buttonFrame.StackCount:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            buttonFrame.StackCount.Text:SetAllPoints()
            buttonFrame.StackCount.Text:SetJustifyH("CENTER")
            buttonFrame.StackCount.Text:SetTextColor(1.0, 0.960784, 0.772549, 1)
            buttonFrame.StackCount.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", ActionBar.fontSize, "")
            buttonFrame.StackCount.Text:SetText("")
        end
    end

    -- Иконка клавиши
    if not buttonFrame.Icon then
        buttonFrame.Icon = CreateFrame("Frame", "ActionButtonIcon" .. slotID, buttonFrame)
        buttonFrame.Icon:SetSize(ActionBar.iconSize, ActionBar.iconSize)
        buttonFrame.Icon:SetPoint("TOPRIGHT", buttonFrame.texture, "TOPRIGHT", ActionBar.stackCountOffset, ActionBar.stackCountOffset)
        ConsoleMenu:InitFadeAnimations(buttonFrame.Icon, ActionBar.animationDuration)

        buttonFrame.Icon:Hide()

        --Иконка бинда
        if not buttonFrame.Icon.Texture then
            buttonFrame.Icon.Texture = buttonFrame.Icon:CreateTexture(nil, "ARTWORK")
            buttonFrame.Icon.Texture:SetAllPoints()
            buttonFrame.Icon.Texture:SetAlpha(1)

            local texture = ConsoleMenu.Backgrounds["PAD"]
            buttonFrame.Icon.Texture:SetTexture(texture)
        end

        -- Фон
        if not buttonFrame.Icon.Background then
            buttonFrame.Icon.Background = buttonFrame.Icon:CreateTexture(nil, "BACKGROUND")
            buttonFrame.Icon.Background:SetAllPoints()
            buttonFrame.Icon.Background:SetAlpha(0.75)

            local texture = ConsoleMenu.Backgrounds["STICK"]
            buttonFrame.Icon.Background:SetTexture(texture)
        end

        --Тень
        if not buttonFrame.Icon.Shadow then
            buttonFrame.Icon.Shadow = buttonFrame.Icon:CreateTexture(nil, "BACKGROUND")
            buttonFrame.Icon.Shadow:SetPoint("TOPLEFT", buttonFrame.Icon.Background, "TOPLEFT", -ActionBar.stackCountShadowOffsef, ActionBar.stackCountShadowOffsef)
            buttonFrame.Icon.Shadow:SetPoint("BOTTOMRIGHT", buttonFrame.Icon.Background, "BOTTOMRIGHT", ActionBar.stackCountShadowOffsef, -ActionBar.stackCountShadowOffsef)

            local texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png"
            buttonFrame.Icon.Shadow:SetTexture(texture)
        end
    end

    return buttonFrame
end
