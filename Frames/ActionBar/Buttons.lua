-- Кнопка панели: способность, перезарядка, заряды, свечение, тень и пиктограмма.

local ConsoleMenu = _G.ConsoleMenu
local ActionBar = ConsoleMenu.ActionBar

local ICON_EDGE = 3

-- Показывает кадр проявлением и не перезапускает его, если он уже виден.
local function FadeIn(frame)
    if not frame then
        return
    end
    if frame.fadeOut and frame.fadeOut:IsPlaying() then
        ConsoleMenu:AnimatedShow(frame)
        return
    end
    local ceiling = frame.fadeAlpha or 1
    if frame:IsShown() and (frame:GetAlpha() or 0) >= ceiling - 0.01 then
        return
    end
    ConsoleMenu:AnimatedShow(frame)
end

-- Гасит незаконченное проявление или исчезновение, чтобы оно не спрятало кадр после нового показа.
local function ReleaseFade(frame)
    if not frame then
        return
    end
    if frame.fadeOut then
        frame.fadeOut:SetScript("OnFinished", nil)
        if frame.fadeOut:IsPlaying() then
            frame.fadeOut:Stop()
        end
    end
    if frame.fadeIn and frame.fadeIn:IsPlaying() then
        frame.fadeIn:Stop()
    end
end

-- Прячет кадр исчезновением и не начинает его заново, пока прошлое ещё идёт.
local function FadeOut(frame)
    if not frame or not frame:IsShown() then
        return
    end
    if frame.fadeOut and frame.fadeOut:IsPlaying() then
        return
    end
    ConsoleMenu:AnimatedHide(frame)
end

-- Рисунок, подложка, круглая маска, восстановление и число зарядов.
-- Этой заготовкой пользуется значок облака.
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
    local edge = ICON_EDGE / ActionBar.buttonSize
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

-- Сторона монеты: свой рисунок и круглая маска.
local function CreateFace(parent)
    local face = CreateFrame("Frame", nil, parent)
    face:SetAllPoints(parent)
    local texture = face:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints(face)
    local edge = ICON_EDGE / ActionBar.buttonSize
    texture:SetTexCoord(edge, 1 - edge, edge, 1 - edge)
    local mask = face:CreateMaskTexture()
    mask:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\MaskCircle.png")
    mask:SetAllPoints(texture)
    texture:AddMaskTexture(mask)
    face.texture = texture
    face.mask = mask
    return face
end

-- Записывает слот без модификатора или со Shift, Ctrl либо Alt.
local function SetIconSlot(icon, modifier, slotID)
    if modifier == nil or modifier == "" then
        icon.slots.base = slotID
    else
        icon.slots[modifier] = slotID
    end
end

-- Убирает слот из таблицы сочетаний.
local function ClearIconSlot(icon, modifier)
    if modifier == nil or modifier == "" then
        icon.slots.base = nil
    else
        icon.slots[modifier] = nil
    end
end

-- Заменяет слот сочетания новым значением.
local function UpdateIconSlot(icon, modifier, slotID)
    SetIconSlot(icon, modifier, slotID)
end

-- Очищает всю таблицу слотов иконки.
local function ClearIconSlots(icon)
    icon.slots.base = nil
    icon.slots.SHIFT = nil
    icon.slots.CTRL = nil
    icon.slots.ALT = nil
end

-- Включает обесцвечивание видимой стороны.
local function EnableIconDesaturation(icon)
    local button = icon.button
    local texture = button and button.texture
    if not texture then
        return
    end
    local keepShade = button.flipBusy or button.coinInAir
    if ActionBar.SetIconGray then
        ActionBar.SetIconGray(texture, true, keepShade)
        return
    end
    if texture.SetDesaturated then
        texture:SetDesaturated(true)
    end
    if texture.SetDesaturation then
        texture:SetDesaturation(1)
    end
    texture.iconGray = true
end

-- Снимает обесцвечивание и возвращает обычный цвет рисунка.
local function DisableIconDesaturation(icon)
    local button = icon.button
    local texture = button and button.texture
    if not texture then
        return
    end
    local keepShade = button.flipBusy or button.coinInAir
    if ActionBar.SetIconGray then
        ActionBar.SetIconGray(texture, false, keepShade)
        return
    end
    if texture.SetDesaturated then
        texture:SetDesaturated(false)
    end
    if texture.SetDesaturation then
        texture:SetDesaturation(0)
    end
    texture.iconGray = false
    if not button.flipBusy then
        texture:SetVertexColor(1, 1, 1)
    end
end

-- Увеличивает кадр иконки до размера со свечением.
local function GrowIcon(icon)
    local button = icon and icon.button
    if not button or (ActionBar.slot12Slots and ActionBar.slot12Slots[button.slotID]) then
        return
    end
    if button.flipBusy then
        return
    end
    local ability = button.Ability
    if ability and math.abs((ability:GetWidth() or 0) - ActionBar.buttonSize) > 0.5 then
        ability:SetSize(ActionBar.buttonSize, ActionBar.buttonSize)
    end
    if math.abs((icon:GetWidth() or 0) - ActionBar.buttonSize) > 0.5 then
        icon:SetSize(ActionBar.buttonSize, ActionBar.buttonSize)
    end
    local grow = ActionBar.glowGrowSize or 6
    local target = (ActionBar.buttonSize + grow) / ActionBar.buttonSize
    ConsoleMenu:InitScaleAnimations(icon, ActionBar.glowMotionDuration or 0.2)
    ConsoleMenu:AnimatedScaleUp(icon, target)
end

-- Возвращает кадру иконки обычный размер.
local function RestoreIcon(icon)
    local button = icon and icon.button
    if not button or button.flipBusy then
        return
    end
    ConsoleMenu:InitScaleAnimations(icon, ActionBar.glowMotionDuration or 0.2)
    ConsoleMenu:AnimatedScaleDown(icon, 1)
end

-- Кнопка той же клавиши должна остаться серой на правом рычаге.
local function StaysOnRightStick(btn, modifier)
    if not modifier or not btn.mainKey then
        return false
    end
    if not ActionBar.ModifierSitsOnRightStick or not ActionBar.ModifierSitsOnRightStick(modifier) then
        return false
    end
    return ActionBar.rightStickStillKeys and ActionBar.rightStickStillKeys[btn.mainKey] == true
end

-- Слот, который кнопка показывает: свой или слот зажатого модификатора.
local function ResolveShownSlot(btn)
    local icon = btn.IconFrame
    local base = (icon and icon.slots and icon.slots.base) or btn.slotID
    local modifier = btn.heldModifier
    if not modifier then
        btn.heldGray = false
        return base
    end
    if StaysOnRightStick(btn, modifier) then
        btn.heldGray = true
        return base
    end
    local slot = icon and icon.slots and icon.slots[modifier]
    if slot and ActionBar.SlotHasAction(slot) then
        btn.heldGray = false
        return slot
    end
    btn.heldGray = true
    if btn.flipBusy and btn.flipTargetSlot and btn.flipTargetSlot ~= base then
        btn.heldGray = false
    end
    return base
end

-- Показывает одну сторону и запоминает, какая способность сейчас видна.
local function ShowSide(btn, face, slotID, texture)
    local base = (btn.IconFrame.slots and btn.IconFrame.slots.base) or btn.slotID
    local sameFace = btn.texture == face.texture and btn.shownSlot == slotID and btn.shownTexture == texture and face:IsShown()
    if not sameFace then
        btn.Front:Hide()
        btn.Back:Hide()
        face:Show()
        if texture and face.texture.shownFile ~= texture then
            face.texture:SetTexture(texture)
            face.texture.shownFile = texture
        end
        if texture and btn.IconFrame.background then
            btn.IconFrame.background:Show()
        end
    end
    btn.texture = face.texture
    btn.mask = face.mask
    btn.shownSlot = slotID
    btn.shownTexture = texture
    btn.boostShowingAlt = slotID ~= base
    btn.boostFlipSlot = btn.boostShowingAlt and slotID or nil
end

-- Убирает рисунок пустой ячейки.
local function ClearSide(btn)
    btn.Front:Show()
    btn.Back:Hide()
    btn.Front.texture.shownFile = nil
    btn.Front.texture:SetTexture(nil)
    btn.texture = btn.Front.texture
    btn.shownSlot = (btn.IconFrame.slots and btn.IconFrame.slots.base) or btn.slotID
    btn.shownTexture = nil
    btn.boostShowingAlt = nil
    btn.boostFlipSlot = nil
    if btn.IconFrame.background then
        btn.IconFrame.background:Hide()
    end
end

-- Меняет рисунок: с переворотом, если способность сменяется между своим слотом и слотом модификатора.
local function SwitchIcon(icon, slotID, texture, animate)
    local btn = icon.button
    if not btn then
        return
    end
    local base = (icon.slots and icon.slots.base) or btn.slotID
    if btn.flipBusy and btn.flipTargetSlot == slotID then
        if texture then
            btn.flipTargetTexture = texture
            btn.Back.texture:SetTexture(texture)
        end
        return
    end
    if not texture then
        ConsoleMenu:StopModelFlight(btn)
        ClearSide(btn)
        return
    end
    if not animate then
        ConsoleMenu:StopModelFlight(btn)
        ShowSide(btn, btn.Front, slotID, texture)
        return
    end
    local fromSlot = btn.shownSlot or base
    local fromTexture = btn.shownTexture
    if fromSlot == slotID and fromTexture == texture then
        return
    end
    ConsoleMenu:StartModelFlight(btn, fromSlot, fromTexture or texture, slotID, texture)
end

-- Выбирает способность и запускает переворот только при смене между своим слотом и слотом модификатора.
local function UpdateFace(btn)
    -- Скрытие без своей иконки оставляет видимый рисунок: переворот здесь не нужен.
    if btn.keepFaceOnHide then
        if btn.flipBusy then
            ConsoleMenu:StopModelFlight(btn)
        end
        return
    end
    local slotID = ResolveShownSlot(btn)
    local texture, hidden = ActionBar.GetSlotTexture(slotID)
    if hidden then
        return
    end
    local base = (btn.IconFrame.slots and btn.IconFrame.slots.base) or btn.slotID
    local previous = btn.shownSlot or base
    local crosses = (previous == base) ~= (slotID == base)
    local animate = crosses and not btn.swapInstant
    if btn.shownSlot == slotID and btn.shownTexture == texture and not btn.flipBusy then
        return
    end
    SwitchIcon(btn.IconFrame, slotID, texture, animate)
    if not btn.flipBusy and btn.Label and btn.slotID and ActionBar.UpdateSlot12Label then
        ActionBar.UpdateSlot12Label(btn.slotID)
    end
end

-- Ключ способности. Пустая ячейка ключа не даёт.
local function ChargeKey(slotID)
    if not ActionBar.ReadActionKey then
        return nil
    end
    local key = ActionBar.ReadActionKey(slotID)
    if not key or key == "" then
        return nil
    end
    return key
end

-- Слот, чьи заряды и перезарядку сейчас можно показывать.
local function VisibleSlot(btn)
    if btn.flipBusy and btn.coinTimerReady and btn.flipTargetSlot then
        return btn.flipTargetSlot
    end
    if btn.flipBusy then
        return btn.flipFromSlot or btn.shownSlot or btn.slotID
    end
    return btn.shownSlot or btn.slotID
end

-- Показывает число зарядов. Само число записывает функция обновления счётчика.
local function ShowCharges(btn, count)
    local stack = btn.Charges
    if not stack then
        return
    end
    if stack.UpdateCharges then
        stack:UpdateCharges(count)
    end
    FadeIn(stack)
end

-- Прячет число зарядов.
local function HideCharges(btn)
    FadeOut(btn.Charges)
end

-- Обновляет счётчик по признаку панели заклинаний для этой способности.
local function UpdateCharges(btn)
    local slotID = VisibleSlot(btn)
    -- Без ячейки число запрашивать нельзя: у кнопки может остаться ключ прошлой способности.
    if not slotID then
        HideCharges(btn)
        return
    end
    local readableKey = ChargeKey(slotID)
    local key = readableKey or btn.chargeKey
    if not key then
        HideCharges(btn)
        return
    end
    local shown = ActionBar.EnsureChargeShown()
    if readableKey and shown[readableKey] then
        btn.chargeKey = readableKey
    end
    local raw
    if C_ActionBar and C_ActionBar.GetActionDisplayCount then
        raw = C_ActionBar.GetActionDisplayCount(slotID)
    end
    if ActionBar.IsSecretValue(raw) then
        if shown[key] then
            ShowCharges(btn, raw)
        else
            HideCharges(btn)
        end
        return
    end
    local count = raw
    if (count == nil or count == "") and ActionBar.ReadDisplayCount then
        local extra = ActionBar.ReadDisplayCount(slotID)
        if ActionBar.IsSecretValue(extra) then
            if shown[key] then
                ShowCharges(btn, extra)
            else
                HideCharges(btn)
            end
            return
        end
        if extra ~= nil and extra ~= "" then
            count = extra
        end
    end
    if count ~= nil and count ~= "" and not ActionBar.IsSecretValue(count) then
        shown[key] = true
    end
    if readableKey and shown[readableKey] then
        btn.chargeKey = readableKey
    end
    if shown[key] then
        ShowCharges(btn, count)
    else
        HideCharges(btn)
    end
end

-- Забывает последнюю способность кнопки, когда в ячейке другое умение.
-- Признак показа счётчика остаётся у панели заклинаний.
local function ForgetCharges(btn)
    btn.chargeKey = nil
end

-- Делает кадр перезарядки видимым сразу.
local function ShowCooldown(btn)
    local cooldown = btn.cooldown
    if not cooldown then
        return
    end
    if cooldown.fadeOut then
        cooldown.fadeOut:Stop()
        cooldown.fadeOut:SetScript("OnFinished", nil)
    end
    cooldown:Show()
    cooldown:SetAlpha(1)
    local level = btn:GetFrameLevel()
    -- Цифры перезарядки над рисунком, но под счётчиком зарядов и его тенью.
    cooldown:SetFrameLevel(level + 3)
    if btn.Charges then
        btn.Charges:SetFrameLevel(level + 5)
    end
    if btn.Pictogram then
        btn.Pictogram:SetFrameLevel(level + 6)
    end
end

-- Прячет перезарядку исчезновением.
local function HideCooldown(btn)
    FadeOut(btn.cooldown)
end

-- Записывает объект длительности как есть, не читая скрытые числа.
local function RefreshCooldown(btn, duration)
    local cooldown = btn.cooldown
    if not cooldown or not duration or not cooldown.SetCooldownFromDurationObject then
        return
    end
    cooldown:SetCooldownFromDurationObject(duration)
end

-- Ставит отсчёт на кружок или в центр кнопки, пока та ещё переворачивается.
-- У кадра должен быть свой размер: растягивание на иконку оставляет отсчёт невидимым.
local function PlaceCooldown(btn, inFlight)
    local cooldown = btn.cooldown
    if not cooldown then
        return
    end
    local anchor = inFlight and "button" or "icon"
    if btn.coinTimerAnchor == anchor and (cooldown:GetWidth() or 0) > 1 then
        return
    end
    cooldown:ClearAllPoints()
    cooldown:SetSize(ActionBar.buttonSize, ActionBar.buttonSize)
    if inFlight then
        local wide = ActionBar.slot12Slots and ActionBar.slot12Slots[btn.slotID]
        if wide and ActionBar.Slot12IconCenterOffset then
            cooldown:SetPoint("CENTER", btn, "LEFT", ActionBar.Slot12IconCenterOffset(), 0)
        else
            cooldown:SetPoint("CENTER", btn, "CENTER", 0, 0)
        end
    else
        cooldown:SetPoint("CENTER", btn.Ability or btn, "CENTER", 0, 0)
    end
    btn.coinTimerAnchor = anchor
end

-- Показывает, обновляет или прячет перезарядку видимой способности.
local function UpdateCooldown(btn)
    local cooldown = btn.cooldown
    if not cooldown then
        return
    end
    local inFlight = btn.flipBusy or btn.coinInAir
    if inFlight and not btn.coinTimerReady then
        HideCooldown(btn)
        return
    end
    PlaceCooldown(btn, inFlight and true or false)
    local slotID = VisibleSlot(btn)
    if not slotID or not C_ActionBar or not C_ActionBar.GetActionCooldownDuration then
        HideCooldown(btn)
        return
    end
    -- Второй аргумент отсекает общее восстановление. Поля состояния не читаем: в бою они скрыты.
    local duration = C_ActionBar.GetActionCooldownDuration(slotID, true)
    ShowCooldown(btn)
    RefreshCooldown(btn, duration)
end

-- Готовит повторяющееся проигрывание листа кадров.
local function StartGlowSheet(texture, path, blendMode, color, duration)
    texture:SetAllPoints()
    texture:SetTexture(path)
    texture:SetBlendMode(blendMode)
    texture:SetVertexColor(color[1], color[2], color[3], 1)
    local group = texture:CreateAnimationGroup()
    group:SetLooping("REPEAT")
    local sheet = group:CreateAnimation("FlipBook")
    sheet:SetOrder(1)
    sheet:SetDuration(duration or ActionBar.glowDuration)
    sheet:SetFlipBookRows(ActionBar.glowRows)
    sheet:SetFlipBookColumns(ActionBar.glowColumns)
    sheet:SetFlipBookFrames(ActionBar.glowFrames)
    sheet:SetFlipBookFrameWidth(0)
    sheet:SetFlipBookFrameHeight(0)
    texture.sheet = group
end

-- Готовит разовую вспышку искр.
local function StartGlowBurst(texture)
    texture:SetTexture(ActionBar.glowBurstTexture)
    texture:SetBlendMode("ADD")
    texture:SetVertexColor(1, 1, 1, 1)
    texture:SetAllPoints()
    local group = texture:CreateAnimationGroup()
    group:SetToFinalAlpha(true)
    local show = group:CreateAnimation("Alpha")
    show:SetOrder(0)
    show:SetDuration(0.001)
    show:SetFromAlpha(1)
    show:SetToAlpha(1)
    local sheet = group:CreateAnimation("FlipBook")
    sheet:SetOrder(1)
    sheet:SetDuration(ActionBar.glowBurstDuration)
    sheet:SetFlipBookRows(ActionBar.glowBurstRows)
    sheet:SetFlipBookColumns(ActionBar.glowBurstColumns)
    sheet:SetFlipBookFrames(ActionBar.glowBurstFrames)
    sheet:SetFlipBookFrameWidth(0)
    sheet:SetFlipBookFrameHeight(0)
    local hide = group:CreateAnimation("Alpha")
    hide:SetOrder(2)
    hide:SetDuration(0.001)
    hide:SetFromAlpha(1)
    hide:SetToAlpha(0)
    texture.sheet = group
end

-- Запускает повторяющееся вращение свечения.
local function PlaySpin(spin)
    spin:Show()
    spin:SetAlpha(1)
    local function Play(texture)
        if texture and texture.sheet and not texture.sheet:IsPlaying() then
            texture.sheet:Play()
        end
    end
    Play(spin.Ring)
    Play(spin.Body)
    Play(spin.Core)
end

-- Останавливает повторяющееся вращение.
local function StopSpin(spin)
    local function Stop(texture)
        if texture and texture.sheet then
            texture.sheet:Stop()
        end
    end
    Stop(spin.Ring)
    Stop(spin.Body)
    Stop(spin.Core)
end

-- Запускает вспышку один раз за загорание.
local function PlayBurst(burst)
    if not burst or burst.played then
        return
    end
    burst.played = true
    burst:Show()
    burst:SetAlpha(1)
    if burst.Texture and burst.Texture.sheet then
        burst.Texture:SetAlpha(1)
        burst.Texture.sheet:Stop()
        burst.Texture.sheet:Play()
    end
end

-- Останавливает вспышку.
local function StopBurst(burst)
    if not burst then
        return
    end
    if burst.Texture and burst.Texture.sheet then
        burst.Texture.sheet:Stop()
        burst.Texture:SetAlpha(0)
    end
end

-- Показывает свечение: крутит ореол и один раз вспыхивает искрами.
local function ShowGlowFrame(glow)
    if not glow then
        return
    end
    ReleaseFade(glow)
    ReleaseFade(glow.Spin)
    ReleaseFade(glow.BurstFrame)
    glow:Show()
    glow:SetAlpha(1)
    if glow.Spin and glow.Spin.PlayLoop then
        glow.Spin:PlayLoop()
    end
    if glow.BurstFrame and glow.BurstFrame.PlayOnce then
        glow.BurstFrame:PlayOnce()
    end
    if glow.BurstFrame then
        glow.burstPlayed = glow.BurstFrame.played
    end
end

-- Прячет свечение: останавливает оба ролика и убирает их кадры.
local function HideGlowFrame(glow)
    if not glow then
        return
    end
    if glow.Spin and glow.Spin.StopLoop then
        glow.Spin:StopLoop()
    end
    if glow.BurstFrame and glow.BurstFrame.StopOnce then
        glow.BurstFrame:StopOnce()
    end
    FadeOut(glow.Spin)
    FadeOut(glow.BurstFrame)
end

-- Обычный размер кольца свечения вокруг иконки.
local function GlowHomeSize()
    return ActionBar.buttonSize * ActionBar.glowScale - 2
end

-- Увеличивает фрейм свечения вместе с иконкой.
local function GrowGlow(glow)
    local button = glow and glow.button
    if not button or (ActionBar.slot12Slots and ActionBar.slot12Slots[button.slotID]) then
        return
    end
    if button.flipBusy then
        return
    end
    local home = GlowHomeSize()
    if math.abs((glow:GetWidth() or 0) - home) > 0.5 then
        glow:SetSize(home, home)
    end
    local grow = ActionBar.glowGrowSize or 6
    local target = (ActionBar.buttonSize + grow) / ActionBar.buttonSize
    ConsoleMenu:InitScaleAnimations(glow, ActionBar.glowMotionDuration or 0.2)
    ConsoleMenu:AnimatedScaleUp(glow, target)
end

-- Возвращает фрейму свечения обычный размер.
local function RestoreGlow(glow)
    local button = glow and glow.button
    if not button or button.flipBusy then
        return
    end
    ConsoleMenu:InitScaleAnimations(glow, ActionBar.glowMotionDuration or 0.2)
    ConsoleMenu:AnimatedScaleDown(glow, 1)
end

-- Показывает свечение кнопки через функцию её кадра.
local function ShowGlow(btn)
    if btn and btn.Glow and btn.Glow.ShowGlow then
        btn.Glow:ShowGlow()
    end
end

-- Прячет свечение кнопки через функцию её кадра.
local function HideGlow(btn)
    if btn and btn.Glow and btn.Glow.HideGlow then
        btn.Glow:HideGlow()
    end
end

-- Держит тень под рисунком, а счётчик и пиктограмму над свечением.
local function RaiseButtonContents(btn)
    local level = btn:GetFrameLevel()
    if btn.Shadow then
        btn.Shadow:SetFrameLevel(level)
    end
    if btn.Ability then
        btn.Ability:SetFrameLevel(level + 1)
    end
    if btn.IconFrame then
        btn.IconFrame:SetFrameLevel(level + 1)
    end
    if btn.Front then
        btn.Front:SetFrameLevel(level + 1)
    end
    if btn.Back then
        btn.Back:SetFrameLevel(level + 1)
    end
    if btn.Glow then
        btn.Glow:SetFrameLevel(level + 2)
        if btn.Glow.Spin then
            btn.Glow.Spin:SetFrameLevel(level + 2)
        end
        if btn.Glow.BurstFrame then
            btn.Glow.BurstFrame:SetFrameLevel(level + 2)
        end
    end
    if btn.cooldown then
        btn.cooldown:SetFrameLevel(level + 3)
    end
    if btn.Charges then
        btn.Charges:SetFrameLevel(level + 5)
    end
    if btn.Pictogram then
        btn.Pictogram:SetFrameLevel(level + 6)
    end
end

-- Показывает тень под кнопкой.
local function ShowShadow(btn)
    if ActionBar.SetGlowShadow then
        ActionBar.SetGlowShadow(btn, true)
    else
        FadeIn(btn.Shadow)
    end
    RaiseButtonContents(btn)
end

-- Прячет тень под кнопкой.
local function HideShadow(btn, instant)
    if ActionBar.SetGlowShadow then
        ActionBar.SetGlowShadow(btn, false, instant and true or false)
        return
    end
    if instant and btn.Shadow then
        btn.Shadow:Hide()
        return
    end
    FadeOut(btn.Shadow)
end

-- Запоминает, должно ли свечение гореть, чтобы соседи могли сдвинуться.
local function NoteGlow(btn, ready)
    ready = ready and true or false
    local changed = btn.glowReady ~= ready
    btn.glowReady = ready
    if not ready and btn.Glow and btn.Glow.BurstFrame then
        btn.Glow.BurstFrame.played = nil
        btn.Glow.burstPlayed = nil
    end
    if changed and ActionBar.SyncGlowButtonSizes then
        ActionBar.SyncGlowButtonSizes()
    end
end

-- Зажигает или гасит свечение, тень и размер иконки со свечением.
local function ApplyGlow(btn, ready)
    NoteGlow(btn, ready)
    if btn.flipBusy or btn.coinInAir then
        HideGlow(btn)
        HideShadow(btn, true)
        return
    end
    if ready then
        ShowGlow(btn)
        ShowShadow(btn)
        GrowIcon(btn.IconFrame)
        if btn.Glow and btn.Glow.Grow then
            btn.Glow:Grow()
        end
    else
        HideGlow(btn)
        HideShadow(btn)
        RestoreIcon(btn.IconFrame)
        if btn.Glow and btn.Glow.Restore then
            btn.Glow:Restore()
        end
    end
end

-- Запоминает, нужно ли свечение у ячейки, даже если сейчас видна другая способность.
local function RememberGlowWanted(btn, slotID, ready)
    if not btn or not slotID then
        return
    end
    btn.glowWantedBySlot = btn.glowWantedBySlot or {}
    btn.glowWantedBySlot[slotID] = ready and true or false
end

-- Умение сейчас подсвечено оверлеем готовности.
local function OverlayReady(spellID)
    if not spellID or ActionBar.IsSecretValue(spellID) or not C_SpellActivationOverlay or not C_SpellActivationOverlay.IsSpellOverlayed then
        return false
    end
    return C_SpellActivationOverlay.IsSpellOverlayed(spellID) and true or false
end

-- Проверяет, нужно ли свечение у видимой способности.
local function UpdateGlow(btn, spellID)
    local slotID = VisibleSlot(btn)
    local eventSlot = btn.glowEventSlot
    local spellKnown = spellID and not ActionBar.IsSecretValue(spellID)
    if spellKnown and eventSlot and slotID and eventSlot ~= slotID then
        RememberGlowWanted(btn, eventSlot, OverlayReady(spellID))
        return
    end
    if spellKnown and GetActionInfo and slotID then
        local ok, actionType, actionID = pcall(GetActionInfo, slotID)
        local readable = ok
            and not ActionBar.IsSecretValue(actionType)
            and not ActionBar.IsSecretValue(actionID)
        if readable and actionType == "spell" and actionID ~= spellID then
            return
        end
    end
    local actionType, actionID
    if GetActionInfo and slotID then
        local ok, kind, id = pcall(GetActionInfo, slotID)
        if ok then
            actionType, actionID = kind, id
        end
    end
    local secretKind = actionType and ActionBar.IsSecretValue(actionType)
    if not spellID then
        if secretKind then
            local wanted = btn.glowWantedBySlot and slotID and btn.glowWantedBySlot[slotID]
            if wanted ~= nil then
                ApplyGlow(btn, wanted)
            elseif btn.glowReady then
                ApplyGlow(btn, true)
            end
            return
        end
        if actionType ~= "spell" and actionType ~= "macro" then
            RememberGlowWanted(btn, slotID, false)
            ApplyGlow(btn, false)
            return
        end
        spellID = actionID
    end
    local ready = OverlayReady(spellID)
    if spellID and not ActionBar.IsSecretValue(spellID) then
        RememberGlowWanted(btn, slotID, ready)
    elseif secretKind then
        local wanted = btn.glowWantedBySlot and slotID and btn.glowWantedBySlot[slotID]
        if wanted ~= nil then
            ready = wanted
        elseif btn.glowReady then
            ready = true
        end
    end
    ApplyGlow(btn, ready)
end

-- Показывает уже разрешённое свечение, если после переворота или появления кнопки его кадр так и не включился.
local function EnsureGlowVisible(btn)
    if not btn or not btn.glowReady or btn.flipBusy or btn.coinInAir then
        return
    end
    local spin = btn.Glow and btn.Glow.Spin
    local fading = spin and spin.fadeOut and spin.fadeOut:IsPlaying()
    local visible = spin and spin:IsShown() and not fading and (spin:GetAlpha() or 0) > 0.5
    if not visible then
        ApplyGlow(btn, true)
        return
    end
    if spin.PlayLoop then
        spin:PlayLoop()
    end
end

-- Красит видимую сторону функциями включения и выключения обесцвечивания.
local function UpdateDesaturation(btn)
    local icon = btn.IconFrame
    if not icon or not icon.EnableDesaturation or not icon.DisableDesaturation then
        return
    end
    local slotID = VisibleSlot(btn)
    local usable = btn.usableHint
    local lacking = btn.resourceHint
    btn.usableHint = nil
    btn.resourceHint = nil
    local gray = false
    if ActionBar.IconNeedsDesaturation then
        gray = ActionBar.IconNeedsDesaturation(btn, slotID, usable, lacking)
    elseif btn.heldGray then
        gray = true
    end
    if gray then
        icon:EnableDesaturation()
    else
        icon:DisableDesaturation()
    end
end

-- Клавиша, чью пиктограмму сейчас нужно показать. Пустой ответ прячет пиктограмму.
local function PictogramKey(btn)
    if btn.mainKey == ActionBar.rightStickKey then
        return ActionBar.rightStickKey
    end
    -- Низ крестовины занят рычагом только без модификатора, и только тогда нужна его пиктограмма.
    if btn.baseFromStick and not btn.heldModifier then
        return ActionBar.leftStickKey
    end
    return nil
end

-- Обновляет пиктограмму, когда меняется обозначение кнопки.
local function UpdatePictogram(btn)
    local icon = btn.Pictogram
    if not icon or not icon.Texture or not btn.mainKey then
        return
    end
    local slotID = VisibleSlot(btn)
    local hasAction = ActionBar.SlotHasAction(slotID)
    local glyphKey = PictogramKey(btn)
    if not hasAction or not glyphKey then
        FadeOut(icon)
        return
    end
    local textureInfo = ConsoleMenu.Textures and ConsoleMenu.Textures[glyphKey]
    local texture = textureInfo and textureInfo.texture
    if not texture or texture == "" then
        if ActionBar.IsInCombat and ActionBar.IsInCombat() then
            return
        end
        FadeOut(icon)
        return
    end
    if btn.pictogramKey ~= glyphKey then
        icon.Texture:SetTexture(texture)
        btn.pictogramKey = glyphKey
        if glyphKey == ActionBar.leftStickKey or (ActionBar.slot12Slots and ActionBar.slot12Slots[btn.slotID]) then
            ActionBar.ApplyKeyGlyphStyle(icon)
        elseif icon.Background then
            icon:SetSize(ActionBar.iconSize, ActionBar.iconSize)
            icon.Background:Show()
        end
    end
    FadeIn(icon)
end

-- Обновляет заряды, перезарядку, свечение, цвет и пиктограмму уже выбранной стороны.
local function UpdateRest(btn, spellID)
    UpdateCharges(btn)
    UpdateCooldown(btn)
    UpdateGlow(btn, spellID)
    EnsureGlowVisible(btn)
    UpdateDesaturation(btn)
    UpdatePictogram(btn)
    if btn.group and btn.group.RefreshShift then
        btn.group:RefreshShift()
    end
end

-- Полёт кружка показывает сторону сам и после шага обновляет остальное содержимое.
ConsoleMenu:BindModelFlight(ShowSide, UpdateRest)

-- Обновляет кнопку целиком: сторону, заряды, перезарядку, свечение, цвет и пиктограмму.
local function UpdateButtonState(btn, spellID)
    if btn.updating then
        btn.updateAgain = true
        btn.updateSpell = spellID
        return
    end
    btn.updating = true
    UpdateFace(btn)
    -- Пока кнопка исчезает без своей иконки, заряды и перезарядку заново не показываем.
    if not btn.keepFaceOnHide then
        UpdateRest(btn, spellID)
    end
    btn.updating = false
    if btn.updateAgain then
        btn.updateAgain = nil
        local nextSpell = btn.updateSpell
        btn.updateSpell = nil
        UpdateButtonState(btn, nextSpell)
    end
end

-- Кнопка показывает этот слот сама или может показать его через модификатор.
local function ShowsSlot(btn, slotID)
    if not slotID then
        return false
    end
    if btn.slotID == slotID or btn.shownSlot == slotID then
        return true
    end
    local slots = btn.IconFrame and btn.IconFrame.slots
    if not slots then
        return false
    end
    return slots.base == slotID or slots.SHIFT == slotID or slots.CTRL == slotID or slots.ALT == slotID
end

-- Ставит центр кнопки на её место у центра группы. Пока размер меньше обычного, отступ увеличивается, чтобы клиент не подтянул кнопку к середине.
function ActionBar.SeatButton(btn)
    if not btn or not btn.mainKey then
        return
    end
    if ActionBar.ignoredSlot and ActionBar.ignoredSlot[btn.slotID] then
        return
    end
    local position = ActionBar.buttonPositions and ActionBar.buttonPositions[btn.mainKey]
    local frame = ActionBar.GetFrame()
    local anchor = position and ActionBar.ResolveAnchor(frame, position[2])
    if not anchor then
        return
    end
    local shiftX, shiftY = 0, 0
    if ActionBar.ButtonGlowShift then
        shiftX, shiftY = ActionBar.ButtonGlowShift(btn)
    end
    local scale = btn:GetScale() or 1
    btn:ClearAllPoints()
    btn:SetPoint(
        position[1],
        anchor,
        position[3],
        ActionBar.StableOffset(position[4] + shiftX, scale),
        ActionBar.StableOffset(position[5] + shiftY, scale)
    )
end

-- Пока кнопка меняет размер, заново ставит её на место.
local function WatchSeat(btn)
    if btn.seatWatch then
        return
    end
    btn.seatWatch = true
    btn:SetScript("OnUpdate", function(self)
        local growing = self.scaleUp and self.scaleUp:IsPlaying()
        local shrinking = self.scaleDown and self.scaleDown:IsPlaying()
        ActionBar.SeatButton(self)
        if not growing and not shrinking then
            self.seatWatch = nil
            self:SetScript("OnUpdate", nil)
            ActionBar.SeatButton(self)
        end
    end)
end

-- Когда кнопка уже скрыта, ставит свою иконку без переворота.
local function SettleHiddenFace(btn)
    if not btn or not btn.keepFaceOnHide then
        return
    end
    btn.keepFaceOnHide = nil
    btn.swapInstant = true
    if btn.Update then
        btn:Update()
    end
    btn.swapInstant = nil
end

-- Готовит анимации полупрозрачности кнопки и задаёт им длительность кнопки.
local function PrepareButtonFade(btn)
    local duration = ActionBar.buttonFadeDuration or 0.2
    ConsoleMenu:InitFadeAnimations(btn, duration)
    if btn.fadeIn and btn.fadeIn.alpha then
        btn.fadeIn.alpha:SetDuration(duration)
    end
    if btn.fadeOut and btn.fadeOut.alpha then
        btn.fadeOut.alpha:SetDuration(duration)
    end
end

-- Проявляет кнопку до полной непрозрачности. Повторно не запускает, если проявление уже идёт.
local function RevealButton(btn)
    if not btn then
        return
    end
    if btn.fadeIn and btn.fadeIn:IsPlaying() then
        return
    end
    PrepareButtonFade(btn)
    local fadingOut = btn.fadeOut and btn.fadeOut:IsPlaying()
    local alpha = btn:GetAlpha() or 1
    if btn:IsShown() and not fadingOut and alpha >= 0.99 then
        return
    end
    ConsoleMenu:AnimatedShow(btn)
end

-- Гасит полупрозрачность кнопки до нуля. Кадр не прячет: его спрячет уменьшение размера.
local function ConcealButton(btn)
    if not btn or not btn:IsShown() then
        return
    end
    if btn.fadeOut and btn.fadeOut:IsPlaying() then
        return
    end
    PrepareButtonFade(btn)
    ConsoleMenu:AnimatedFadeOut(btn)
end

-- Останавливает проявление и погасание, чтобы после скрытия кнопка не вспыхнула.
local function StopButtonFade(btn)
    if not btn then
        return
    end
    if btn.fadeOut then
        btn.fadeOut:SetScript("OnFinished", nil)
        if btn.fadeOut:IsPlaying() then
            btn.fadeOut:Stop()
        end
    end
    if btn.fadeIn and btn.fadeIn:IsPlaying() then
        btn.fadeIn:Stop()
    end
end

-- Показывает кнопку: сначала обновляет её, затем растит до обычного размера и проявляет до полной непрозрачности.
local function ShowButton(btn)
    if not btn then
        return
    end
    btn.hiding = nil
    btn.glowShiftRelease = nil
    local keptFace = btn.keepFaceOnHide
    btn.keepFaceOnHide = nil
    if keptFace then
        btn.swapInstant = true
    end
    if btn.Update then
        btn:Update()
    end
    if keptFace then
        btn.swapInstant = nil
    end
    ConsoleMenu:InitScaleAnimations(btn, ActionBar.glowMotionDuration or 0.2)
    local growing = btn.scaleUp and btn.scaleUp:IsPlaying()
    local shrinking = btn.scaleDown and btn.scaleDown:IsPlaying()
    local atHome = btn:IsShown() and not shrinking and not btn.scaleZero and math.abs((btn:GetScale() or 1) - 1) < 0.02
    RevealButton(btn)
    ActionBar.SeatButton(btn)
    EnsureGlowVisible(btn)
    if growing or atHome then
        return
    end
    WatchSeat(btn)
    ConsoleMenu:AnimatedScaleUp(btn, 1, nil, function(frame)
        EnsureGlowVisible(frame)
    end)
end

-- Скрытие возвращает кнопку её собственной функцией, а не назначает место само.
local function ReleaseShiftForHide(btn)
    if btn.ReturnHome then
        btn:ReturnHome()
    end
end

-- Прячет кнопку уменьшением до нуля и погасанием полупрозрачности, убирает свечение, тень, заряды, перезарядку и сдвиг.
local function HideButton(btn)
    if not btn then
        return
    end
    ReleaseShiftForHide(btn)
    HideGlow(btn)
    HideShadow(btn)
    HideCharges(btn)
    HideCooldown(btn)
    RestoreIcon(btn.IconFrame)
    if btn.Glow and btn.Glow.Restore then
        btn.Glow:Restore()
    end
    if btn.hiding or not btn:IsShown() then
        if not btn:IsShown() then
            SettleHiddenFace(btn)
        end
        return
    end
    ConsoleMenu:InitScaleAnimations(btn, ActionBar.glowMotionDuration or 0.2)
    if btn.scaleDown and btn.scaleDown:IsPlaying() then
        btn.hiding = true
        ConcealButton(btn)
        return
    end
    btn.hiding = true
    ActionBar.SeatButton(btn)
    WatchSeat(btn)
    ConcealButton(btn)
    ConsoleMenu:AnimatedScaleDown(btn, 0, nil, function(frame)
        frame.hiding = nil
        StopButtonFade(frame)
        frame:SetAlpha(0)
        frame:Hide()
        if frame.ReturnHome then
            frame:ReturnHome()
        end
        SettleHiddenFace(frame)
        if ActionBar.AfterButtonHidden then
            ActionBar.AfterButtonHidden()
        end
    end)
end

-- Задаёт размер кружка соседям светящейся кнопки. Сама светящаяся иконка растёт отдельно.
function ActionBar.SetButtonPictureSize(btn, size)
    if not btn or not size or size < 1 then
        return
    end
    if btn.flipBusy or btn.glowReady then
        return
    end
    if ActionBar.slot12Slots and ActionBar.slot12Slots[btn.slotID] then
        return
    end
    local ability = btn.Ability
    if ability then
        ability:SetSize(size, size)
    end
    if btn.IconFrame then
        btn.IconFrame:SetSize(size, size)
    end
    if ability then
        return
    end
    if btn.texture then
        btn.texture:ClearAllPoints()
        btn.texture:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btn.texture:SetSize(size, size)
    end
end

-- Собирает вращающееся свечение и вспышку искр.
local function CreateGlow(btn)
    local glow = CreateFrame("Frame", nil, btn)
    local glowSize = ActionBar.buttonSize * ActionBar.glowScale - 2
    glow:SetSize(glowSize, glowSize)
    glow:SetPoint("CENTER", btn.Ability, "CENTER", 0, 0)
    glow:SetFrameStrata(btn:GetFrameStrata())
    glow:Hide()
    glow.button = btn
    ConsoleMenu:InitScaleAnimations(glow, ActionBar.glowMotionDuration or 0.2)

    local spin = CreateFrame("Frame", nil, glow)
    spin:SetAllPoints(glow)
    ConsoleMenu:InitFadeAnimations(spin, ActionBar.animationDuration)
    spin.Ring = spin:CreateTexture(nil, "ARTWORK", nil, -1)
    StartGlowSheet(spin.Ring, ActionBar.glowRingTexture, "ADD", ActionBar.glowBodyColor, ActionBar.glowRingDuration)
    spin.Body = spin:CreateTexture(nil, "ARTWORK")
    StartGlowSheet(spin.Body, ActionBar.glowBodyTexture, "BLEND", ActionBar.glowBodyColor)
    spin.Core = spin:CreateTexture(nil, "OVERLAY")
    StartGlowSheet(spin.Core, ActionBar.glowCoreTexture, "ADD", ActionBar.glowCoreColor)
    spin:Hide()
    spin.PlayLoop = PlaySpin
    spin.StopLoop = StopSpin

    local burst = CreateFrame("Frame", nil, glow)
    burst:SetSize(ActionBar.glowBurstSize, ActionBar.glowBurstSize)
    burst:SetPoint("CENTER", glow, "CENTER", 0, 0)
    ConsoleMenu:InitFadeAnimations(burst, ActionBar.animationDuration)
    burst.Texture = burst:CreateTexture(nil, "OVERLAY")
    StartGlowBurst(burst.Texture)
    burst:Hide()
    burst.PlayOnce = PlayBurst
    burst.StopOnce = StopBurst

    glow.Spin = spin
    glow.BurstFrame = burst
    glow.Ring = spin.Ring
    glow.Body = spin.Body
    glow.Core = spin.Core
    glow.Burst = burst.Texture
    glow.ShowGlow = ShowGlowFrame
    glow.HideGlow = HideGlowFrame
    glow.Grow = GrowGlow
    glow.Restore = RestoreGlow
    btn.Glow = glow
end

-- Собирает тень под кнопкой.
local function CreateShadow(btn)
    local shadow = CreateFrame("Frame", nil, btn)
    shadow:SetFrameStrata(btn:GetFrameStrata())
    shadow:EnableMouse(false)
    shadow:SetSize(ActionBar.glowShadowSize, ActionBar.glowShadowSize)
    shadow:SetPoint("CENTER", btn.Ability, "CENTER", 0, 0)
    shadow:SetAlpha(0)
    shadow:Hide()
    local texture = shadow:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    texture:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png")
    ConsoleMenu:InitFadeAnimations(shadow, 0.2)
    shadow.fadeOut.alpha:SetDuration(0.1)
    shadow.fadeAlpha = ActionBar.glowShadowAlpha or 0.7
    shadow.glowButton = btn
    shadow.ShowShadow = function(self)
        ShowShadow(self.glowButton)
    end
    shadow.HideShadow = function(self)
        HideShadow(self.glowButton)
    end
    btn.Shadow = shadow
    btn.glowShadow = shadow
end

-- Собирает пиктограмму обозначения кнопки.
local function CreatePictogram(btn, buttonNumber, isSlot12)
    local icon = CreateFrame("Frame", "ConsoleMenuActionButtonIcon" .. buttonNumber, btn)
    icon:SetSize(ActionBar.iconSize, ActionBar.iconSize)
    icon:SetPoint("TOPRIGHT", btn.IconFrame, "TOPRIGHT", ActionBar.stackCountOffset, ActionBar.stackCountOffset)
    ConsoleMenu:InitFadeAnimations(icon, ActionBar.animationDuration)
    icon:Hide()
    icon.Texture = icon:CreateTexture(nil, "ARTWORK")
    icon.Texture:SetAllPoints()
    icon.Texture:SetAlpha(1)
    icon.Texture:SetTexture(ConsoleMenu.Backgrounds and ConsoleMenu.Backgrounds["PAD"])
    icon.Background = icon:CreateTexture(nil, "BACKGROUND")
    icon.Background:SetAllPoints()
    icon.Background:SetAlpha(0.75)
    icon.Background:SetTexture(ConsoleMenu.Backgrounds and ConsoleMenu.Backgrounds["STICK"])
    icon.Shadow = icon:CreateTexture(nil, "BACKGROUND")
    icon.Shadow:SetPoint("TOPLEFT", icon.Background, "TOPLEFT", -ActionBar.stackCountShadowOffset, ActionBar.stackCountShadowOffset)
    icon.Shadow:SetPoint("BOTTOMRIGHT", icon.Background, "BOTTOMRIGHT", ActionBar.stackCountShadowOffset, -ActionBar.stackCountShadowOffset)
    icon.Shadow:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png")
    icon.ShowPictogram = function(self)
        FadeIn(self)
    end
    icon.HidePictogram = function(self)
        FadeOut(self)
    end
    icon.UpdatePictogram = function()
        UpdatePictogram(btn)
    end
    if isSlot12 then
        ActionBar.ApplyKeyGlyphStyle(icon)
    end
    btn.Pictogram = icon
    btn.Icon = icon
end

-- Следующий порядковый номер фрейма кнопки. Имя не зависит от клавиши.
local nextButtonNumber = 0

-- Создание кнопки геймпада. Номера ячеек записываются позже, по привязкам клавиши.
function ActionBar.CreateButton(parent, mainKey)
    nextButtonNumber = nextButtonNumber + 1
    local buttonNumber = nextButtonNumber
    local buttonName = "ConsoleMenuActionButton" .. buttonNumber
    local buttonFrame = CreateFrame("Frame", buttonName, parent)
    parent[buttonName] = buttonFrame

    local isSlot12 = mainKey == ActionBar.padButtonKey or mainKey == "PADBACK"
    if isSlot12 then
        buttonFrame:SetSize(ActionBar.slot12ContainerWidth, ActionBar.slot12ContainerHeight)
    else
        buttonFrame:SetSize(ActionBar.buttonSize, ActionBar.buttonSize)
    end
    ConsoleMenu:InitFadeAnimations(buttonFrame, ActionBar.buttonFadeDuration or 0.2)
    ConsoleMenu:InitScaleAnimations(buttonFrame, ActionBar.glowMotionDuration or 0.2)
    buttonFrame.glowRestLevel = buttonFrame:GetFrameLevel()
    buttonFrame.mainKey = mainKey
    buttonFrame.modifierKey = nil

    if isSlot12 and ActionBar.BuildSlot12Plate then
        ActionBar.BuildSlot12Plate(buttonFrame)
    end

    local ability = CreateFrame("Frame", nil, buttonFrame)
    ability:SetSize(ActionBar.buttonSize, ActionBar.buttonSize)
    if isSlot12 then
        ability:SetPoint("LEFT", buttonFrame, "LEFT", (ActionBar.slot12IconPadding or 0) + 4, 0)
    else
        ability:SetPoint("CENTER", buttonFrame, "CENTER", 0, 0)
    end
    buttonFrame.Ability = ability
    ConsoleMenu:InitScaleAnimations(ability, ActionBar.glowMotionDuration or 0.2)

    local icon = CreateFrame("Frame", nil, ability)
    icon:SetSize(ActionBar.buttonSize, ActionBar.buttonSize)
    icon:SetPoint("CENTER", ability, "CENTER", 0, 0)
    ConsoleMenu:InitScaleAnimations(icon, ActionBar.glowMotionDuration or 0.2)
    icon.slots = {}
    icon.button = buttonFrame
    icon.SetSlot = SetIconSlot
    icon.ClearSlot = ClearIconSlot
    icon.UpdateSlot = UpdateIconSlot
    icon.ClearSlots = ClearIconSlots
    icon.EnableDesaturation = EnableIconDesaturation
    icon.DisableDesaturation = DisableIconDesaturation
    icon.Switch = SwitchIcon
    icon.Grow = GrowIcon
    icon.Restore = RestoreIcon
    local background = icon:CreateTexture(nil, "BACKGROUND")
    background:SetPoint("TOPLEFT", icon, "TOPLEFT", -4, 4)
    background:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 4, -4)
    background:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\pad-background.png")
    background:SetVertexColor(0, 0, 0, 1)
    icon.background = background
    buttonFrame.background = background
    buttonFrame.Front = CreateFace(icon)
    buttonFrame.Back = CreateFace(icon)
    buttonFrame.Back:Hide()
    buttonFrame.texture = buttonFrame.Front.texture
    buttonFrame.mask = buttonFrame.Front.mask
    buttonFrame.IconFrame = icon
    icon:ClearSlots()

    local cooldown = CreateFrame("Cooldown", nil, buttonFrame, "CooldownFrameTemplate")
    cooldown:SetSize(ActionBar.buttonSize, ActionBar.buttonSize)
    cooldown:SetPoint("CENTER", ability, "CENTER", 0, 0)
    cooldown:SetDrawBling(false)
    cooldown:SetDrawSwipe(false)
    cooldown:SetDrawEdge(false)
    cooldown:SetHideCountdownNumbers(false)
    cooldown:SetMinimumCountdownDuration(0)
    ConsoleMenu:InitFadeAnimations(cooldown, ActionBar.animationDuration)
    cooldown:Hide()
    cooldown:HookScript("OnHide", function(self)
        if self.Clear then
            self:Clear()
        end
    end)
    cooldown.ShowCooldown = function()
        ShowCooldown(buttonFrame)
    end
    cooldown.HideCooldown = function()
        HideCooldown(buttonFrame)
    end
    cooldown.RefreshCooldown = function(_, duration)
        RefreshCooldown(buttonFrame, duration)
    end
    buttonFrame.cooldown = cooldown

    local stack = CreateFrame("Frame", "ConsoleMenuActionButtonStackCount" .. buttonNumber, buttonFrame)
    stack:SetSize(ActionBar.stackCountSize, ActionBar.stackCountSize)
    stack:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", ActionBar.stackCountOffset, -ActionBar.stackCountOffset)
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
    stack.ShowCharges = function(_, count)
        ShowCharges(buttonFrame, count)
    end
    stack.HideCharges = function()
        HideCharges(buttonFrame)
    end
    stack.UpdateCharges = function(_, count)
        if count ~= nil then
            stack.Text:SetText(count)
        end
    end
    buttonFrame.Charges = stack
    buttonFrame.StackCount = stack

    CreateGlow(buttonFrame)
    CreateShadow(buttonFrame)
    CreatePictogram(buttonFrame, buttonNumber, isSlot12)

    if isSlot12 then
        local iconAnchor = CreateFrame("Frame", nil, buttonFrame)
        iconAnchor:SetSize(1, 1)
        iconAnchor:SetPoint("LEFT", buttonFrame, "LEFT", ActionBar.Slot12IconCenterOffset(), 0)
        buttonFrame.iconAnchor = iconAnchor
        buttonFrame.Label = buttonFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        buttonFrame.Label:SetPoint(
            "LEFT",
            iconAnchor,
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

    buttonFrame.Update = UpdateButtonState
    buttonFrame.ShowsSlot = ShowsSlot
    buttonFrame.ShowButton = ShowButton
    buttonFrame.HideButton = HideButton
    buttonFrame.ReturnHome = function(self)
        if ActionBar.ReturnButtonHome then
            ActionBar.ReturnButtonHome(self)
        end
    end
    buttonFrame.ShowGlow = ShowGlow
    buttonFrame.HideGlow = HideGlow
    buttonFrame.ShowShadow = ShowShadow
    buttonFrame.HideShadow = HideShadow
    buttonFrame.ShowCharges = ShowCharges
    buttonFrame.HideCharges = HideCharges
    buttonFrame.ShowCooldown = ShowCooldown
    buttonFrame.HideCooldown = HideCooldown
    buttonFrame.ForgetCharges = ForgetCharges
    buttonFrame.GrowIcon = function(self)
        GrowIcon(self.IconFrame)
    end
    buttonFrame.RestoreIcon = function(self)
        RestoreIcon(self.IconFrame)
    end

    buttonFrame:HookScript("OnHide", function(self)
        if self.HideShadow then
            self:HideShadow(true)
        end
    end)

    RaiseButtonContents(buttonFrame)
    if parent and parent.buttons and ActionBar.AttachGroupButton then
        ActionBar.AttachGroupButton(parent, buttonFrame)
    end
    return buttonFrame
end

-- Добавляет правый рычаг, если его нажатие привязано к ячейке, и убирает, если привязки больше нет.
-- Левый рычаг отдельного фрейма не имеет: его ячейка лежит на нижнем направлении крестовины.
function ActionBar.SyncStickButtons(frame)
    frame = frame or ActionBar.GetFrame()
    if not frame or not frame.actionButtons then
        return
    end
    local sticks = { ActionBar.rightStickKey }
    for index = 1, #sticks do
        local key = sticks[index]
        if key then
            local bound = ActionBar.StickHasSlot and ActionBar.StickHasSlot(key)
            local btn = frame.actionButtons[key]
            local group = frame.rightGroup
            frame.keptButtons = frame.keptButtons or {}
            if bound and not btn then
                btn = frame.keptButtons[key]
                if not btn then
                    btn = ActionBar.CreateButton(group or frame, key)
                    frame.keptButtons[key] = btn
                elseif group and ActionBar.AttachGroupButton then
                    ActionBar.AttachGroupButton(group, btn)
                end
                frame.actionButtons[key] = btn
            elseif btn and not bound then
                if btn.HideButton then
                    btn:HideButton()
                else
                    btn:Hide()
                end
                if group and ActionBar.DetachGroupButton then
                    ActionBar.DetachGroupButton(group, btn)
                end
                frame.keptButtons[key] = btn
                frame.actionButtons[key] = nil
            end
        end
    end
end

-- Ячейка годится для кнопки, если она задана и это не дополнительное действие.
local function AcceptSlot(slot)
    if not slot or (ActionBar.IsExtraActionSlot and ActionBar.IsExtraActionSlot(slot)) then
        return nil
    end
    return slot
end

-- Записывает в кнопку ячейку без модификатора и ячейки Shift, Ctrl и Alt.
-- Низ крестовины без модификатора берёт ячейку левого рычага, а с модификатором — свою.
local function WriteButtonSlots(btn, page)
    local icon = btn.IconFrame
    local key = btn.mainKey
    if not icon or not icon.ClearSlots or not key or not ActionBar.BindingSlot then
        return
    end
    icon:ClearSlots()
    btn.baseFromStick = false
    local base = nil
    if key == "PADDDOWN" and ActionBar.leftStickKey then
        base = AcceptSlot(ActionBar.BindingSlot(ActionBar.leftStickKey, nil, page))
        if base then
            btn.baseFromStick = true
        end
    end
    if not base then
        base = ActionBar.BindingSlot(key, nil, page)
    end
    if not base and key == ActionBar.padButtonKey then
        base = ActionBar.BindingSlot("PADBACK", nil, page)
    end
    icon:SetSlot(nil, base)
    btn.slotID = base
    local modifiers = { "SHIFT", "CTRL", "ALT" }
    for index = 1, #modifiers do
        local modifier = modifiers[index]
        local slot = ActionBar.BindingSlot(key, modifier, page)
        if not slot and key == ActionBar.padButtonKey then
            slot = ActionBar.BindingSlot("PADBACK", modifier, page)
        end
        if slot and not (ActionBar.IsExtraActionSlot and ActionBar.IsExtraActionSlot(slot)) then
            icon:SetSlot(modifier, slot)
            if ActionBar.EnableRangeCheck then
                ActionBar.EnableRangeCheck(slot, true)
            end
        end
    end
    if base and ActionBar.EnableRangeCheck then
        ActionBar.EnableRangeCheck(base, true)
    end
end

-- Раскладывает ячейки по кнопкам геймпада согласно текущим привязкам.
function ActionBar.FillButtonSlots()
    local frame = ActionBar.GetFrame()
    if not frame or not frame.actionButtons then
        return
    end
    if ActionBar.SyncStickButtons then
        ActionBar.SyncStickButtons(frame)
    end
    local page = ActionBar.SlotPage and ActionBar.SlotPage() or 1
    for _, btn in pairs(frame.actionButtons) do
        WriteButtonSlots(btn, page)
    end
end

-- Сообщает видимой кнопке зажатый модификатор.
function ActionBar.SetButtonModifier(btn, modifier, instant)
    if not btn or btn.modifierKey or not btn.Update then
        return
    end
    if btn.heldModifier == modifier and not btn.flipBusy then
        local want = ResolveShownSlot(btn)
        if modifier == btn.heldModifier and btn.shownSlot == want and not instant then
            return
        end
    end
    btn.heldModifier = modifier
    btn.swapInstant = instant and true or false
    btn:Update()
    btn.swapInstant = nil
end

-- Обновляет кнопку слота и те кнопки, которые сейчас показывают этот слот.
function ActionBar.UpdateButton(slotID, spellID, isUsable, isLackingResources)
    local frame = ActionBar.GetFrame()
    if not frame or not frame.actionButtons or not slotID then
        return
    end
    for _, btn in pairs(frame.actionButtons) do
        if btn.Update and not btn.modifierKey and btn.ShowsSlot and btn:ShowsSlot(slotID) then
            if btn.slotID == slotID or btn.shownSlot == slotID then
                btn.usableHint = isUsable
                btn.resourceHint = isLackingResources
            end
            btn.glowEventSlot = spellID and slotID or nil
            if btn.group and btn.group.UpdateGroup then
                btn.group:UpdateGroup(btn, spellID)
            else
                btn:Update(spellID)
            end
            btn.glowEventSlot = nil
        end
    end
end

-- Обновляет все видимые кнопки панели.
function ActionBar.UpdateAllButtons(spellID)
    local frame = ActionBar.GetFrame()
    if not frame or not frame.actionButtons then
        return
    end
    for _, btn in pairs(frame.actionButtons) do
        if btn.Update and not btn.modifierKey then
            btn:Update(spellID)
        end
    end
end

ActionBar.ShowButton = ShowButton
ActionBar.HideButton = HideButton
