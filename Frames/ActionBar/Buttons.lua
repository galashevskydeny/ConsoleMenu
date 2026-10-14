-- Сборка одной кнопки панели: фон, маска, восстановление, счётчик и значок клавиши.

local ConsoleMenu = _G.ConsoleMenu
local ActionBar = ConsoleMenu.ActionBar

-- Рисунок, подложка, круглая маска, восстановление и число зарядов.
-- Этой заготовкой пользуются и кнопка панели, и значок облака.
local function AttachRoundIcon(buttonFrame, stackName)
    local backgroundSize = ActionBar.buttonSize + 8
    local background = buttonFrame:CreateTexture(nil, "BACKGROUND")
    background:SetSize(backgroundSize, backgroundSize)
    background:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\pad-background.png")
    background:SetVertexColor(0, 0, 0, 1)
    background:SetPoint("CENTER", buttonFrame, "CENTER", 0, 0)
    buttonFrame.background = background

    local texture = buttonFrame:CreateTexture(nil, "ARTWORK")
    texture:SetSize(ActionBar.buttonSize, ActionBar.buttonSize)
    texture:SetPoint("CENTER", buttonFrame, "CENTER", 0, 0)
    local edge = 3 / ActionBar.buttonSize
    texture:SetTexCoord(edge, 1 - edge, edge, 1 - edge)
    buttonFrame.texture = texture

    local mask = buttonFrame:CreateMaskTexture()
    mask:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\MaskCircle.png")
    mask:SetAllPoints(texture)
    texture:AddMaskTexture(mask)
    buttonFrame.mask = mask

    local cooldown = CreateFrame("Cooldown", nil, buttonFrame, "CooldownFrameTemplate")
    cooldown:SetAllPoints(texture)
    cooldown:SetDrawBling(false)
    cooldown:SetDrawSwipe(false)
    cooldown:SetDrawEdge(false)
    buttonFrame.cooldown = cooldown

    local stack = CreateFrame("Frame", stackName, buttonFrame)
    stack:SetSize(ActionBar.stackCountSize, ActionBar.stackCountSize)
    stack:SetPoint("BOTTOMRIGHT", texture, "BOTTOMRIGHT", ActionBar.stackCountOffset, -ActionBar.stackCountOffset)
    ConsoleMenu:InitFadeAnimations(stack, ActionBar.animationDuration)
    stack:Hide()
    stack.Shadow = stack:CreateTexture(nil, "BACKGROUND")
    stack.Shadow:SetPoint("TOPLEFT", stack, "TOPLEFT", -ActionBar.stackCountShadowOffset, ActionBar.stackCountShadowOffset)
    stack.Shadow:SetPoint("BOTTOMRIGHT", stack, "BOTTOMRIGHT", ActionBar.stackCountShadowOffset, -ActionBar.stackCountShadowOffset)
    stack.Shadow:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png")
    stack.Text = stack:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stack.Text:SetAllPoints()
    stack.Text:SetJustifyH("CENTER")
    stack.Text:SetTextColor(1.0, 0.960784, 0.772549, 1)
    stack.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", ActionBar.fontSize, "")
    stack.Text:SetText("")
    buttonFrame.StackCount = stack
    return buttonFrame
end

-- Круглый значок без клавиши и без переворота. Облако собирает из него умения.
function ActionBar.CreateRoundIcon(parent)
    local icon = CreateFrame("Frame", nil, parent)
    icon:SetSize(ActionBar.buttonSize, ActionBar.buttonSize)
    AttachRoundIcon(icon)
    icon:SetScale(0.001)
    icon:Hide()
    return icon
end

-- Создание рамки кнопки для ячейки панели.
function ActionBar.CreateButton(parent, slotID)
    local buttonName = "ConsoleMenuActionButton" .. slotID
    local buttonFrame = CreateFrame("Frame", buttonName, parent)
    parent[buttonName] = buttonFrame

    local isSlot12 = ActionBar.slot12Slots[slotID]

    if isSlot12 then
        buttonFrame:SetSize(ActionBar.slot12ContainerWidth, ActionBar.slot12ContainerHeight)
    else
        buttonFrame:SetSize(ActionBar.buttonSize, ActionBar.buttonSize)
    end
    ConsoleMenu:InitFadeAnimations(buttonFrame, ActionBar.animationDuration)
    -- Уровень до подъёма над тенью свечения. Переворот монеты меняет уровень отдельно.
    buttonFrame.glowRestLevel = buttonFrame:GetFrameLevel()
    buttonFrame:HookScript("OnHide", function(self)
        if ActionBar.SetGlowShadow then
            ActionBar.SetGlowShadow(self, false, true)
        end
    end)
    buttonFrame:HookScript("OnShow", function(self)
        if self.glowReady and self.slotID and ActionBar.UpdateGlow then
            ActionBar.UpdateGlow(self.slotID)
        end
    end)

    local textureFileID = C_ActionBar.GetActionTexture(slotID)
    if ActionBar.IsSecretValue(textureFileID) then
        -- Не считаем слот пустым: просто отложим установку текстуры.
        textureFileID = nil
    end

    -- Плашка островка тачпада: торцы остаются круглыми, когда название требует большей ширины.
    if isSlot12 and ActionBar.BuildSlot12Plate then
        ActionBar.BuildSlot12Plate(buttonFrame)
    end

    AttachRoundIcon(buttonFrame, "ConsoleMenuActionButtonStackCount" .. slotID)
    if textureFileID then
        buttonFrame.texture:SetTexture(textureFileID)
    end

    -- Ось кружка не едет вместе с подбросом и не зависит от ширины плашки.
    if isSlot12 then
        ActionBar.PlaceSlot12Icon(buttonFrame)
        local iconAnchor = CreateFrame("Frame", nil, buttonFrame)
        iconAnchor:SetSize(1, 1)
        iconAnchor:SetPoint("LEFT", buttonFrame, "LEFT", ActionBar.Slot12IconCenterOffset(), 0)
        buttonFrame.iconAnchor = iconAnchor
    else
        buttonFrame.texture:SetAllPoints(buttonFrame)
    end

    ActionBar.EnableRangeCheck(slotID, true)

    -- После таймера красим ту сторону, которая сейчас на кнопке, а не ячейку, с которой кнопка создана.
    local function RefreshCooldownPaint()
        if buttonFrame.flipBusy or buttonFrame.coinActive or buttonFrame.coinInAir or (buttonFrame.ctrlFlipOwned and not buttonFrame.ctrlFaceSettled) then
            return
        end
        local paintSlot = buttonFrame.slotID
        if buttonFrame.boostShowingAlt and buttonFrame.boostFlipSlot then
            paintSlot = buttonFrame.boostFlipSlot
        end
        ActionBar.UpdateTextureDesaturation(buttonFrame, paintSlot)
    end

    buttonFrame.cooldown:HookScript("OnHide", function()
        RunNextFrame(RefreshCooldownPaint)
    end)

    buttonFrame.cooldown:SetScript("OnCooldownDone", function()
        RunNextFrame(RefreshCooldownPaint)
    end)

    -- Название действия справа от иконки (слот 12)
    if isSlot12 then
        buttonFrame.Label = buttonFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        -- Левый край привязан к покоящемуся кружку, чтобы подброс не тащил слова за собой.
        buttonFrame.Label:SetPoint(
            "LEFT",
            buttonFrame.iconAnchor,
            "CENTER",
            (ActionBar.buttonSize + 8) / 2 + ActionBar.slot12LabelGap,
            0
        )
        buttonFrame.Label:SetPoint("RIGHT", buttonFrame, "RIGHT", -ActionBar.slot12LabelRightPadding, 0)
        buttonFrame.Label:SetPoint("TOP", buttonFrame, "TOP", 0, -ActionBar.slot12LabelEdgePadding)
        buttonFrame.Label:SetPoint("BOTTOM", buttonFrame, "BOTTOM", 0, ActionBar.slot12LabelEdgePadding)
        buttonFrame.Label:SetJustifyH("LEFT")
        buttonFrame.Label:SetJustifyV("MIDDLE")
        buttonFrame.Label:SetWordWrap(true)
        buttonFrame.Label:SetNonSpaceWrap(false)
        buttonFrame.Label:SetMaxLines(2)
        buttonFrame.Label:SetTextColor(1.0, 0.960784, 0.772549, 1)
        buttonFrame.Label:SetFont("Fonts\\FRIZQT___CYR.TTF", ActionBar.slot12LabelFontSize, "")
        buttonFrame.Label:SetText("")
    end

    -- Иконка клавиши
    if not buttonFrame.Icon then
        buttonFrame.Icon = CreateFrame("Frame", "ConsoleMenuActionButtonIcon" .. slotID, buttonFrame)
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
            buttonFrame.Icon.Shadow:SetPoint("TOPLEFT", buttonFrame.Icon.Background, "TOPLEFT", -ActionBar.stackCountShadowOffset, ActionBar.stackCountShadowOffset)
            buttonFrame.Icon.Shadow:SetPoint("BOTTOMRIGHT", buttonFrame.Icon.Background, "BOTTOMRIGHT", ActionBar.stackCountShadowOffset, -ActionBar.stackCountShadowOffset)

            local texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png"
            buttonFrame.Icon.Shadow:SetTexture(texture)
        end

        -- На тачпаде пиктограмма клавиши без подложки, с тенью как у счётчика.
        if isSlot12 then
            ActionBar.ApplyKeyGlyphStyle(buttonFrame.Icon)
        end
    end

    return buttonFrame
end

-- Крутит текстуру, если клиент это умеет.
local function SetPieceRotation(piece, angle)
    if piece and piece.SetRotation then
        piece:SetRotation(angle or 0)
    end
end

-- Подброс рисунка: в середине видна другая сторона.
local function ApplyPictureToss(btn, amount, tilt)
    local texture = btn.texture
    local background = btn.background
    local size = ActionBar.buttonSize
    local turns = ActionBar.boostCoinTurns or 1
    if turns < 1 then
        turns = 1
    end
    local edge = ActionBar.boostFlipEdge or 0.07
    local thin = 1
    local axis = 0
    local slide = 0
    local lift = 0
    local shade = 1
    local scale = 1
    local showAlt = amount >= 1

    if amount > 0 and amount < 1 then
        local rise = amount ^ 0.62
        local hop = math.sin(rise * math.pi)
        local spun = amount * amount * (3 - 2 * amount)
        local spin = spun * turns * math.pi
        thin = math.abs(math.cos(spin))
        if thin < edge then
            thin = edge
        end
        showAlt = math.cos(spin) < 0
        local tiltAmount = tilt or 0.7
        local direction = tiltAmount >= 0 and 1 or -1
        axis = tiltAmount * hop * 0.85
        slide = math.sin(amount * math.pi) * direction * (ActionBar.boostFlipNudge or 6)
        lift = hop * (ActionBar.boostFlipLift or 26)
        scale = 1 + hop * 0.12
        shade = 0.35 + 0.65 * thin
    end

    local height = size * scale
    local width = height * thin
    if width < 0.01 then
        width = 0.01
    end
    local wide = ActionBar.slot12Slots and ActionBar.slot12Slots[btn.slotID]
    if background then
        background:ClearAllPoints()
        background:SetSize(math.max(width + 8, 0.01), height + 8)
        SetPieceRotation(background, axis)
        if wide then
            -- Кружок прыгает на левом краю плашки, сама плашка и подпись не едут.
            background:SetPoint("LEFT", btn, "LEFT", (ActionBar.slot12IconPadding or 0) + slide, lift)
        else
            background:SetPoint("CENTER", btn, "CENTER", slide, lift)
        end
    end
    if texture then
        texture:ClearAllPoints()
        texture:SetSize(width, height)
        texture:SetVertexColor(shade, shade, shade)
        SetPieceRotation(texture, axis)
        if wide and background then
            texture:SetPoint("CENTER", background, "CENTER", 0, 0)
        else
            texture:SetPoint("CENTER", btn, "CENTER", slide, lift)
        end
    end
    return showAlt
end

-- Возвращает рисунок и подложку на обычное место.
local function SeatPicture(btn)
    local texture = btn.texture
    if ActionBar.slot12Slots and ActionBar.slot12Slots[btn.slotID] and ActionBar.PlaceSlot12Icon then
        ActionBar.PlaceSlot12Icon(btn)
    elseif texture then
        texture:ClearAllPoints()
        texture:SetAllPoints(btn)
        texture:SetVertexColor(1, 1, 1)
        SetPieceRotation(texture, 0)
        if btn.background then
            btn.background:ClearAllPoints()
            btn.background:SetPoint("CENTER", btn, "CENTER", 0, 0)
            btn.background:SetSize(ActionBar.buttonSize + 8, ActionBar.buttonSize + 8)
            SetPieceRotation(btn.background, 0)
        end
    end
end

-- Кнопка той же клавиши на панели зажатого модификатора.
local function FindModifierFace(btn, modifier)
    local frame = ActionBar.GetFrame()
    if not frame or not frame.actionButtons or not btn.mainKey or not modifier then
        return nil
    end
    for _, other in pairs(frame.actionButtons) do
        if other ~= btn and other.mainKey == btn.mainKey and other.modifierKey == modifier then
            return other
        end
    end
    return nil
end

-- Этой кнопке при правом рычаге положено остаться серой.
local function StaysOnRightStick(btn, modifier)
    if not modifier or not btn.mainKey then
        return false
    end
    if not ActionBar.ModifierSitsOnRightStick or not ActionBar.ModifierSitsOnRightStick(modifier) then
        return false
    end
    return ActionBar.rightStickStillKeys and ActionBar.rightStickStillKeys[btn.mainKey] == true
end

-- Ставит рисунок стороны и запоминает, чью ячейку сейчас видно.
local function ShowFace(btn, slotID, texture)
    if not btn.texture or not texture then
        return
    end
    if btn.shownTexture == texture and btn.boostFlipSlot == slotID then
        return
    end
    btn.texture:SetTexture(texture)
    btn.shownTexture = texture
    btn.boostShowingAlt = slotID ~= btn.slotID
    btn.boostFlipSlot = slotID ~= btn.slotID and slotID or nil
    if ActionBar.UpdateTextureDesaturation then
        ActionBar.UpdateTextureDesaturation(btn, slotID)
    end
    -- Пока кружок в воздухе, плашка не подгоняется под новое название.
    if not btn.flipBusy and not btn.coinInAir and btn.Label and btn.slotID and ActionBar.UpdateSlot12Label then
        ActionBar.UpdateSlot12Label(btn.slotID)
    end
end

local flipping = {}
local flipDriver

local function StopFlipDriverIfIdle()
    if not flipDriver then
        return
    end
    for index = 1, #flipping do
        if flipping[index].flipBusy then
            return
        end
    end
    flipDriver:Hide()
end

-- Шаг подброса всех кнопок, которые сейчас в воздухе.
local function StepFlips(_, elapsed)
    for index = #flipping, 1, -1 do
        local btn = flipping[index]
        if btn.flipBusy then
            btn.flipElapsed = (btn.flipElapsed or 0) + (elapsed or 0)
            local duration = btn.flipDuration or 0.2
            local amount = duration > 0 and btn.flipElapsed / duration or 1
            if amount >= 1 then
                amount = 1
            end
            local showAlt = ApplyPictureToss(btn, amount, btn.flipTilt)
            local faceSlot = btn.flipFrontSlot or btn.slotID
            local faceTexture = btn.flipFrontTexture or btn.homeTexture
            if showAlt then
                faceSlot = btn.flipSlot or btn.slotID
                faceTexture = btn.flipTexture or faceTexture
            end
            ShowFace(btn, faceSlot, faceTexture)
            local timerReady = showAlt and true or nil
            if btn.coinTimerReady ~= timerReady then
                btn.coinTimerReady = timerReady
                if amount < 1 and ActionBar.SyncButtonCooldown then
                    ActionBar.SyncButtonCooldown(btn)
                end
            end
            if amount >= 1 then
                if btn.flipSlot == btn.slotID and btn.flipTexture then
                    btn.homeTexture = btn.flipTexture
                end
                btn.flipBusy = false
                btn.coinInAir = nil
                btn.coinActive = nil
                btn.coinTimerReady = true
                btn.coinCountReady = true
                btn.flipFrontSlot = nil
                btn.flipFrontTexture = nil
                SeatPicture(btn)
                ShowFace(btn, btn.flipSlot or btn.slotID, btn.flipTexture or btn.homeTexture)
                if btn.Label and btn.slotID and ActionBar.UpdateSlot12Label then
                    ActionBar.UpdateSlot12Label(btn.slotID)
                end
                btn.glowHeld = nil
                btn.glowWanted = nil
                if ActionBar.UpdateCount and btn.slotID then
                    ActionBar.UpdateCount(btn.slotID)
                end
                if ActionBar.UpdateGlow then
                    ActionBar.UpdateGlow(btn.slotID)
                end
                if ActionBar.SyncButtonCooldown then
                    ActionBar.SyncButtonCooldown(btn)
                end
                if ActionBar.SyncGlowButtonSizes then
                    ActionBar.SyncGlowButtonSizes()
                end
                table.remove(flipping, index)
            end
        else
            table.remove(flipping, index)
        end
    end
    StopFlipDriverIfIdle()
end

local function EnsureFlipDriver()
    if flipDriver then
        return flipDriver
    end
    flipDriver = CreateFrame("Frame")
    flipDriver:Hide()
    flipDriver:SetScript("OnUpdate", StepFlips)
    return flipDriver
end

-- Снимает кнопку из списка хода, чтобы второе нажатие не ускоряло подброс.
local function ForgetFlip(btn)
    for index = #flipping, 1, -1 do
        if flipping[index] == btn then
            table.remove(flipping, index)
        end
    end
end

-- Отмечает, что рисунок ещё крутится, и оставляет в списке только одну запись.
local function BeginToss(btn)
    ForgetFlip(btn)
    btn.flipBusy = true
    btn.coinInAir = true
    btn.coinActive = true
    btn.coinTimerReady = nil
    btn.coinCountReady = nil
    if ActionBar.SyncButtonCooldown then
        ActionBar.SyncButtonCooldown(btn)
    end
    btn.flipElapsed = 0
    btn.flipDuration = ActionBar.boostExpandDuration and ActionBar.boostExpandDuration * 0.55 or 0.26
    btn.flipTilt = (btn.slotID % 2 == 0) and 0.7 or -0.6
    flipping[#flipping + 1] = btn
    -- Начальная память о кольце. Более поздняя просьба заменит её, не показывая кольцо.
    btn.glowWanted = btn.Glow and btn.Glow:IsShown() and true or false
    if btn.Glow then
        btn.Glow:Hide()
    end
    EnsureFlipDriver():Show()
end

-- Рисунок лёг ровно: подброс больше не держит кнопку.
local function EndToss(btn)
    ForgetFlip(btn)
    btn.flipBusy = false
    btn.coinInAir = nil
    btn.coinActive = nil
    btn.coinTimerReady = true
    btn.coinCountReady = true
    btn.flipFrontSlot = nil
    btn.flipFrontTexture = nil
    btn.glowHeld = nil
end

-- Включает или выключает свечение кнопки. Во время переворота просьба ждёт.
function ActionBar.SetButtonGlowShown(btn, shown)
    if not btn then
        return
    end
    btn.glowWanted = shown and true or false
    if btn.flipBusy or btn.coinInAir then
        if btn.Glow then
            btn.Glow:Hide()
        end
        return
    end
    if not btn.Glow then
        return
    end
    if btn.glowWanted then
        ConsoleMenu:AnimatedShow(btn.Glow)
        local ring = btn.Glow.Ring
        local body = btn.Glow.Body
        local core = btn.Glow.Core
        if ring and ring.sheet and not ring.sheet:IsPlaying() then
            ring.sheet:Play()
        end
        if body and body.sheet and not body.sheet:IsPlaying() then
            body.sheet:Play()
        end
        if core and core.sheet and not core.sheet:IsPlaying() then
            core.sheet:Play()
        end
    else
        ConsoleMenu:AnimatedHide(btn.Glow)
    end
end

-- Задаёт размер рисунка. Подложка и кольцо следуют за ним.
function ActionBar.SetButtonPictureSize(btn, size)
    if not btn or not btn.texture or not size or size < 1 then
        return
    end
    if btn.flipBusy then
        return
    end
    if ActionBar.slot12Slots and ActionBar.slot12Slots[btn.slotID] then
        return
    end
    btn.texture:ClearAllPoints()
    btn.texture:SetPoint("CENTER", btn, "CENTER", 0, 0)
    btn.texture:SetSize(size, size)
    if btn.background then
        btn.background:SetSize(size + 8, size + 8)
    end
    if btn.Glow then
        local glowSize = ActionBar.buttonSize * (ActionBar.glowScale or 1) - 2 + (size - ActionBar.buttonSize)
        if glowSize < 1 then
            glowSize = 1
        end
        btn.Glow:SetSize(glowSize, glowSize)
    end
end

-- Свежий рисунок ячейки. Скрытое боевое значение не подменяет уже известное.
local function FreshSlotTexture(slotID, fallback)
    local texture, hidden = ActionBar.GetSlotTexture(slotID)
    if hidden or not texture then
        return fallback, hidden
    end
    return texture, false
end

-- Сообщает кнопке зажатую дополнительную клавишу. Она сама переворачивается или сереет.
function ActionBar.SetButtonModifier(btn, modifier, instant)
    if not btn or btn.modifierKey then
        return
    end

    local home = FreshSlotTexture(btn.slotID, btn.homeTexture)
    if home then
        btn.homeTexture = home
    end

    local face = modifier and FindModifierFace(btn, modifier)
    local stay = modifier and StaysOnRightStick(btn, modifier)
    local canFlip = face and not stay and C_ActionBar.HasAction(face.slotID)
    local targetSlot = btn.slotID
    local targetTexture = home
    if canFlip then
        local faceTexture, faceHidden = FreshSlotTexture(face.slotID, nil)
        if faceHidden or not faceTexture then
            canFlip = false
        else
            targetSlot = face.slotID
            targetTexture = faceTexture
        end
    end
    btn.heldGray = (modifier and not canFlip) and true or false

    local returning = not instant and not modifier and (btn.flipBusy or btn.boostShowingAlt)
    local alreadyThere = not btn.flipBusy and btn.heldModifier == modifier and (
        (canFlip and btn.boostFlipSlot == targetSlot) or (not canFlip and not btn.boostShowingAlt)
    )
    -- Сторона уже та, что нужна: число, свечение и рисунок не перечитываем.
    if alreadyThere then
        return
    end
    if instant or (not canFlip and not returning) then
        EndToss(btn)
        btn.heldModifier = modifier
        btn.flipSlot = canFlip and targetSlot or nil
        btn.flipTexture = canFlip and targetTexture or nil
        SeatPicture(btn)
        ShowFace(btn, canFlip and targetSlot or btn.slotID, (canFlip and targetTexture) or home)
        if ActionBar.UpdateTextureDesaturation then
            ActionBar.UpdateTextureDesaturation(btn, canFlip and targetSlot or btn.slotID)
        end
        if ActionBar.UpdateCount and btn.slotID then
            ActionBar.UpdateCount(btn.slotID)
        end
        if ActionBar.UpdateGlow then
            ActionBar.UpdateGlow(btn.slotID)
        end
        if ActionBar.SyncButtonCooldown then
            ActionBar.SyncButtonCooldown(btn)
        end
        return
    end

    if btn.flipBusy and btn.heldModifier == modifier and btn.flipSlot == targetSlot and not returning then
        if targetTexture then
            btn.flipTexture = targetTexture
        end
        return
    end

    -- Уже летит на свою ячейку: второе отпускание не начинает ход сначала.
    if btn.flipBusy and not instant and not modifier and btn.flipSlot == btn.slotID then
        if home then
            btn.flipTexture = home
        end
        return
    end

    if returning then
        btn.flipFrontSlot = btn.boostFlipSlot or btn.slotID
        btn.flipFrontTexture = btn.shownTexture or btn.flipTexture or home
        btn.heldModifier = nil
        btn.heldGray = false
        btn.flipSlot = btn.slotID
        btn.flipTexture = home
    else
        btn.flipFrontSlot = nil
        btn.flipFrontTexture = nil
        btn.heldModifier = modifier
        btn.flipSlot = targetSlot
        btn.flipTexture = targetTexture
    end
    BeginToss(btn)
end

