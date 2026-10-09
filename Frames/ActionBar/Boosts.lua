-- Облако усилений на месте правого рычага: плавание в покое, на крестовине взлёт и переворот без переноса.

local ConsoleMenu = _G.ConsoleMenu
local ActionBar = ConsoleMenu.ActionBar

local pi2 = math.pi * 2

-- Смягчение с перелётом: значок вспухает чуть сильнее цели и садится обратно.
local function EaseOutBack(t)
    if t <= 0 then
        return 0
    end
    if t >= 1 then
        return 1
    end
    local overshoot = 2.2
    local cubic = overshoot + 1
    t = t - 1
    return 1 + cubic * t * t * t + overshoot * t * t
end

local function Lerp(a, b, t)
    return a + (b - a) * t
end

-- Смягчение к концу отрезка, чтобы значок сел на место без рывка.
local function EaseOutCubic(t)
    if t <= 0 then
        return 0
    end
    if t >= 1 then
        return 1
    end
    local rest = 1 - t
    return 1 - rest * rest * rest
end

-- Снимает привязку к пиксельной сетке, иначе медленное плавание прыгает по кадрам.
local function DisablePixelSnap(region)
    if not region then
        return
    end
    if region.SetSnapToPixelGrid then
        region:SetSnapToPixelGrid(false)
    end
    if region.SetTexelSnappingBias then
        region:SetTexelSnappingBias(0)
    end
end

-- Текстура ячейки облака по тем же правилам, что у обычных кнопок.
local function GetBoostTexture(slotID)
    local textureFileID = nil

    if C_ActionBar and C_ActionBar.IsAssistedCombatAction and C_ActionBar.IsAssistedCombatAction(slotID) then
        if C_AssistedCombat and C_Spell then
            local spellID = C_AssistedCombat.GetNextCastSpell and C_AssistedCombat.GetNextCastSpell(true)
            if spellID then
                textureFileID = C_Spell.GetSpellTexture(spellID)
            end
        end
    end

    if not textureFileID and C_ActionBar and C_ActionBar.GetActionTexture then
        local ok, result = pcall(C_ActionBar.GetActionTexture, slotID)
        if ok then
            textureFileID = result
        end
    end

    if textureFileID and issecretvalue and issecretvalue(textureFileID) then
        return nil, true
    end

    return textureFileID, false
end

-- Состояние облака, если рамка уже создана.
local function GetBoosts()
    local frame = ActionBar.GetFrame()
    if not frame then
        return nil
    end
    return frame.boosts
end

-- Сборка одного круглого значка облака.
local function CreateBoostIcon(parent, index, spec)
    local icon = CreateFrame("Frame", "ConsoleMenuActionBarBoost" .. spec.slotID, parent)
    icon.slotID = spec.slotID
    icon.isExtra = spec.isExtra == true
    icon.index = index
    icon.filled = false

    if icon.isExtra then
        icon.wanted = false
        icon.restX = ActionBar.boostExtraRestX
        icon.restY = ActionBar.boostExtraRestY
        icon.restSize = 0.01
        icon.expandX = ActionBar.boostExtraExpandX
        icon.expandY = ActionBar.boostExtraExpandY
        icon.phase = ActionBar.boostExtraFloatPhase
        icon.speed = ActionBar.boostExtraFloatSpeed
        icon.flightRate = ActionBar.boostExtraFlightRate or 1
        icon:SetAlpha(0)
        icon:Hide()
    else
        icon.restX = ActionBar.boostCloudOffsets[index].x
        icon.restY = ActionBar.boostCloudOffsets[index].y
        icon.restSize = ActionBar.boostCloudSizes[index]
        icon.expandX = ActionBar.boostExpandPositions[index].x
        icon.expandY = ActionBar.boostExpandPositions[index].y
        icon.phase = ActionBar.boostFloatPhases[index]
        icon.speed = ActionBar.boostFloatSpeeds[index]
        icon.flightRate = ActionBar.boostFlightRates[index] or 1
    end

    icon.expandSize = ActionBar.buttonSize

    icon:SetSize(icon.restSize, icon.restSize)
    icon:SetPoint("CENTER", parent, "CENTER", icon.restX, icon.restY)
    if icon.isExtra then
        icon:SetFrameLevel(parent:GetFrameLevel() + 10)
    else
        icon:SetFrameLevel(parent:GetFrameLevel() + index + 1)
    end
    DisablePixelSnap(icon)

    local background = icon:CreateTexture(nil, "BACKGROUND")
    background:SetSize(icon.restSize + 8, icon.restSize + 8)
    background:SetPoint("CENTER", icon, "CENTER", 0, 0)
    background:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\pad-background.png")
    background:SetVertexColor(0, 0, 0, 1)
    DisablePixelSnap(background)
    icon.background = background

    local texture = icon:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints(icon)
    local edge = 3 / math.max(icon.restSize, 1)
    texture:SetTexCoord(edge, 1 - edge, edge, 1 - edge)
    DisablePixelSnap(texture)
    icon.texture = texture

    local mask = icon:CreateMaskTexture()
    mask:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\MaskCircle.png")
    mask:SetAllPoints(texture)
    texture:AddMaskTexture(mask)
    DisablePixelSnap(mask)
    icon.mask = mask

    local cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    cooldown:SetAllPoints(texture)
    cooldown:SetDrawBling(false)
    cooldown:SetDrawSwipe(false)
    cooldown:SetDrawEdge(false)
    cooldown:SetHideCountdownNumbers(true)
    cooldown:SetAlpha(0)
    DisablePixelSnap(cooldown)
    icon.cooldown = cooldown
    icon.timerShown = false

    -- Счётчик зарядов в углу значка, как у обычных кнопок.
    local stackCount = CreateFrame("Frame", icon:GetName() .. "StackCount", icon)
    stackCount:SetSize(ActionBar.stackCountSize, ActionBar.stackCountSize)
    stackCount:SetPoint("BOTTOMRIGHT", texture, "BOTTOMRIGHT", ActionBar.stackCountOffset, -ActionBar.stackCountOffset)
    stackCount:SetFrameLevel(icon:GetFrameLevel() + 8)
    ConsoleMenu:InitFadeAnimations(stackCount, ActionBar.animationDuration)
    stackCount:Hide()
    DisablePixelSnap(stackCount)

    local countShadow = stackCount:CreateTexture(nil, "BACKGROUND")
    countShadow:SetPoint("TOPLEFT", stackCount, "TOPLEFT", -ActionBar.stackCountShadowOffsef, ActionBar.stackCountShadowOffsef)
    countShadow:SetPoint("BOTTOMRIGHT", stackCount, "BOTTOMRIGHT", ActionBar.stackCountShadowOffsef, -ActionBar.stackCountShadowOffsef)
    countShadow:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png")
    DisablePixelSnap(countShadow)
    stackCount.Shadow = countShadow

    local countText = stackCount:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    countText:SetAllPoints()
    countText:SetJustifyH("CENTER")
    countText:SetTextColor(1.0, 0.960784, 0.772549, 1)
    countText:SetFont("Fonts\\FRIZQT___CYR.TTF", ActionBar.fontSize, "")
    countText:SetText("")
    stackCount.Text = countText

    icon.StackCount = stackCount
    icon.hasCount = false
    icon.countShown = false

    -- Подпись и буква L только у дополнительного действия, после посадки.
    if icon.isExtra then
        local caption = CreateFrame("Frame", icon:GetName() .. "Caption", icon)
        caption:SetSize(
            ActionBar.slot12ContainerWidth - ActionBar.buttonSize - ActionBar.slot12IconPadding * 2,
            ActionBar.slot12ContainerHeight - ActionBar.slot12LabelEdgePadding * 2
        )
        caption:SetPoint("LEFT", icon, "RIGHT", ActionBar.slot12LabelGap, 0)
        caption:SetFrameLevel(icon:GetFrameLevel() + 4)
        ConsoleMenu:InitFadeAnimations(caption, ActionBar.animationDuration)
        caption:Hide()
        caption:SetAlpha(0)
        DisablePixelSnap(caption)

        local label = caption:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetAllPoints()
        label:SetJustifyH("LEFT")
        label:SetJustifyV("MIDDLE")
        label:SetWordWrap(true)
        label:SetNonSpaceWrap(true)
        label:SetMaxLines(2)
        label:SetTextColor(1.0, 0.960784, 0.772549, 1)
        label:SetFont("Fonts\\FRIZQT___CYR.TTF", ActionBar.slot12LabelFontSize, "")
        label:SetText("")
        icon.Caption = caption
        icon.Label = label

        local keyIcon = CreateFrame("Frame", icon:GetName() .. "KeyIcon", icon)
        keyIcon:SetSize(ActionBar.stackCountSize, ActionBar.stackCountSize)
        keyIcon:SetPoint("TOPRIGHT", texture, "TOPRIGHT", ActionBar.boostExtraKeyOffsetX, ActionBar.boostExtraKeyOffsetY)
        keyIcon:SetFrameLevel(icon:GetFrameLevel() + 6)
        ConsoleMenu:InitFadeAnimations(keyIcon, ActionBar.animationDuration)
        keyIcon:Hide()
        keyIcon:SetAlpha(0)
        DisablePixelSnap(keyIcon)

        keyIcon.Shadow = keyIcon:CreateTexture(nil, "BACKGROUND")
        keyIcon.Shadow:SetPoint("TOPLEFT", keyIcon, "TOPLEFT", -ActionBar.stackCountShadowOffsef, ActionBar.stackCountShadowOffsef)
        keyIcon.Shadow:SetPoint("BOTTOMRIGHT", keyIcon, "BOTTOMRIGHT", ActionBar.stackCountShadowOffsef, -ActionBar.stackCountShadowOffsef)
        keyIcon.Shadow:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png")
        DisablePixelSnap(keyIcon.Shadow)

        keyIcon.Texture = keyIcon:CreateTexture(nil, "ARTWORK")
        keyIcon.Texture:SetAllPoints()
        keyIcon.Texture:SetAlpha(1)
        local letterInfo = ConsoleMenu.Textures and ConsoleMenu.Textures.L
        local letterTexture = letterInfo and letterInfo.texture
        if letterTexture and letterTexture ~= "" then
            keyIcon.Texture:SetTexture(letterTexture)
        else
            keyIcon.Texture:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\L.png")
        end
        ActionBar.ApplyKeyGlyphStyle(keyIcon)
        icon.KeyIcon = keyIcon
        icon.captionsShown = false
    end

    icon:Hide()
    return icon
end

-- Значок нажатия правого рычага поверх облака, как L на кнопке левого рычага.
local function CreateBoostStickHint(parent)
    local hint = CreateFrame("Frame", "ConsoleMenuActionBarBoostStickHint", parent)
    hint:SetSize(ActionBar.iconSize, ActionBar.iconSize)
    hint:SetPoint(
        "TOPRIGHT",
        parent,
        "CENTER",
        ActionBar.buttonSize / 2 + ActionBar.stackCountOffset,
        -ActionBar.boostExpandOffset + ActionBar.buttonSize / 2 + ActionBar.stackCountOffset
    )
    hint:SetFrameLevel(parent:GetFrameLevel() + 12)
    DisablePixelSnap(hint)

    hint.Shadow = hint:CreateTexture(nil, "BACKGROUND")
    hint.Shadow:SetPoint("TOPLEFT", hint, "TOPLEFT", -ActionBar.stackCountShadowOffsef, ActionBar.stackCountShadowOffsef)
    hint.Shadow:SetPoint("BOTTOMRIGHT", hint, "BOTTOMRIGHT", ActionBar.stackCountShadowOffsef, -ActionBar.stackCountShadowOffsef)
    hint.Shadow:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png")
    DisablePixelSnap(hint.Shadow)

    hint.Texture = hint:CreateTexture(nil, "ARTWORK")
    hint.Texture:SetAllPoints()
    hint.Texture:SetAlpha(1)
    DisablePixelSnap(hint.Texture)
    local stickInfo = ConsoleMenu.Textures and ConsoleMenu.Textures.PADRSTICK
    local stickTexture = stickInfo and stickInfo.texture
    if stickTexture and stickTexture ~= "" then
        hint.Texture:SetTexture(stickTexture)
    else
        hint.Texture:SetTexture(ConsoleMenu.Backgrounds and ConsoleMenu.Backgrounds.PAD)
    end

    ActionBar.ApplyKeyGlyphStyle(hint, ActionBar.iconSize)
    return hint
end

-- Насколько свёрнутое облако занято дополнительным действием: от нуля до единицы.
local function GetExtraRestMix(boosts)
    local rest = 1 - (boosts.progress or 0)
    if rest < 0 then
        rest = 0
    elseif rest > 1 then
        rest = 1
    end
    local mix = (boosts.layoutMix or 0) * rest
    if mix < 0 then
        return 0
    end
    if mix > 1 then
        return 1
    end
    return mix
end

-- Ареол правой группы растёт вместе со свёрнутым облаком, если в нём дополнительное действие.
local function ApplyCloudHalo(boosts)
    local parent = boosts.frame and boosts.frame:GetParent()
    local shadow = parent and parent.PADshadow
    if not shadow then
        return
    end

    local size = Lerp(ActionBar.shadowSize, ActionBar.shadowSizeWithExtra, GetExtraRestMix(boosts))
    if shadow.lastSize ~= size then
        shadow:SetSize(size, size)
        shadow.lastSize = size
    end
end

-- Значок рычага гаснет в начале разлёта и появляется лишь к концу сбора.
-- Подсказка всегда сидит на облаке и плавно сдвигается вместе с раскладкой, без скачка на значок дополнительного действия.
-- Прячет подсказку правого рычага.
local function HideBoostStickHint(boosts)
    local hint = boosts and boosts.stickHint
    if not hint then
        return
    end
    hint:SetAlpha(0)
    if hint:IsShown() then
        hint:Hide()
    end
end

-- Значок рычага гаснет в начале разлёта и появляется лишь к концу сбора.
-- Подсказка всегда сидит на облаке и плавно сдвигается вместе с раскладкой, без скачка на значок дополнительного действия.
local function ApplyBoostStickHint(boosts)
    local hint = boosts.stickHint
    if not hint then
        return
    end

    -- В исследовании при исчезновении облака букву R не показываем.
    if boosts.exploringHidePending then
        HideBoostStickHint(boosts)
        return
    end

    local extraRest = GetExtraRestMix(boosts)
    local hintX = ActionBar.buttonSize / 2 + ActionBar.stackCountOffset + ActionBar.boostHintExtraOffsetX * extraRest
    local hintY = -ActionBar.boostExpandOffset + ActionBar.buttonSize / 2 + ActionBar.stackCountOffset + ActionBar.boostHintExtraOffsetY * extraRest
    hint:ClearAllPoints()
    hint:SetPoint("TOPRIGHT", boosts.frame, "CENTER", hintX, hintY)

    local extra = boosts.extraIcon
    if extra and extra:IsShown() then
        hint:SetFrameLevel(extra:GetFrameLevel() + 8)
    else
        hint:SetFrameLevel(boosts.frame:GetFrameLevel() + 12)
    end

    local fadeSpan = ActionBar.boostHintFadeProgress
    if fadeSpan <= 0 then
        fadeSpan = 0.35
    end
    local alpha = 1 - boosts.progress / fadeSpan
    if alpha < 0 then
        alpha = 0
    elseif alpha > 1 then
        alpha = 1
    end
    if alpha <= 0.001 then
        hint:SetAlpha(0)
        if hint:IsShown() then
            hint:Hide()
        end
        return
    end

    if not hint:IsShown() then
        hint:Show()
    end
    hint:SetAlpha(alpha)
    if hint.Texture and hint.Texture.SetDesaturated then
        hint.Texture:SetDesaturated(IsControlKeyDown())
    end
end

-- Запуск плавной смены раскладки облака при появлении или исчезновении дополнительного действия.
local function BeginLayoutMotion(boosts, target)
    if not boosts then
        return
    end
    -- Повторный вызов в ту же сторону не сбрасывает ход, иначе значок не успевает уйти из облака.
    if boosts.layoutTarget == target then
        return
    end

    boosts.layoutTarget = target
    boosts.layoutStartMix = boosts.layoutMix or 0
    boosts.layoutElapsed = 0
    local span = math.abs(target - boosts.layoutStartMix)
    if span < 0.001 then
        boosts.layoutMix = target
        boosts.layoutDuration = 0
        return
    end
    local duration = ActionBar.boostLayoutDuration or 0.4
    boosts.layoutDuration = duration * span
end

-- Доля текущего хода раскладки от нуля до единицы, без смягчения.
local function GetLayoutAmount(boosts)
    if not boosts.layoutDuration or boosts.layoutDuration <= 0 then
        return 1
    end
    local amount = (boosts.layoutElapsed or 0) / boosts.layoutDuration
    if amount < 0 then
        return 0
    end
    if amount > 1 then
        return 1
    end
    return amount
end

-- Ход раскладки облака: значки разъезжаются, новый всплывает.
local function AdvanceLayoutMix(boosts, elapsed)
    if not boosts.layoutDuration or boosts.layoutDuration <= 0 or boosts.layoutMix == boosts.layoutTarget then
        boosts.layoutMix = boosts.layoutTarget or boosts.layoutMix or 0
        return
    end

    boosts.layoutElapsed = (boosts.layoutElapsed or 0) + elapsed
    local amount = GetLayoutAmount(boosts)
    if amount >= 1 then
        boosts.layoutMix = boosts.layoutTarget
        boosts.layoutDuration = 0
        return
    end

    local eased = EaseOutCubic(amount)
    boosts.layoutMix = boosts.layoutStartMix + (boosts.layoutTarget - boosts.layoutStartMix) * eased
end

-- Текущий покой значка с учётом раскладки вокруг дополнительного действия.
local function SyncIconRestFromLayout(boosts, icon)
    local mix = boosts.layoutMix or 0
    if mix < 0 then
        mix = 0
    elseif mix > 1 then
        mix = 1
    end

    local appearing = (boosts.layoutTarget or 0) >= 1
    local amount = GetLayoutAmount(boosts)

    if icon.isExtra then
        local extraScale = mix
        if appearing and (boosts.layoutStartMix or 0) < 0.05 then
            extraScale = EaseOutBack(amount)
        end
        if extraScale < 0 then
            extraScale = 0
        end
        icon.restX = ActionBar.boostExtraRestX
        icon.restY = ActionBar.boostExtraRestY
        icon.restSize = ActionBar.boostExtraCloudSize * extraScale
        icon.expandX = ActionBar.boostExtraExpandX
        icon.expandY = ActionBar.boostExtraExpandY
        icon:SetAlpha(mix)
        return
    end

    local index = icon.index
    local from = ActionBar.boostCloudOffsets[index]
    local to = ActionBar.boostCloudOffsetsWithExtra[index]
    local sizeFrom = ActionBar.boostCloudSizes[index]
    local sizeTo = ActionBar.boostCloudSizesWithExtra[index]
    icon.restX = Lerp(from.x, to.x, mix)
    icon.restY = Lerp(from.y, to.y, mix)
    icon.restSize = Lerp(sizeFrom, sizeTo, mix)
end

-- В исследовании без Shift облако живёт только вместе с дополнительным действием.
local function IsExploringWithoutShift()
    if not ConsoleMenu.GetPlayerContext or ConsoleMenu:GetPlayerContext() ~= "exploring" then
        return false
    end
    return not IsShiftKeyDown()
end

-- В исследовании без дополнительного действия прячем всю панель, иначе облако остаётся висеть.
local function HideExploringBarIfIdle()
    if not IsExploringWithoutShift() then
        return
    end
    if IsControlKeyDown() or IsAltKeyDown() then
        return
    end
    if ActionBar.HasVisibleExtraAction() then
        return
    end
    local frame = ActionBar.GetFrame()
    if frame then
        ConsoleMenu:AnimatedHide(frame)
    end
end

local HideFrameThen

-- Длительность гашения в исследовании: пока значки летят обратно, панель гаснет вместе с ними.
local function GetExploringHideDuration(boosts)
    if boosts and (boosts.target or 0) == 0 and (boosts.duration or 0) > 0 then
        local remaining = boosts.duration - (boosts.elapsed or 0)
        if remaining > 0.16 then
            return remaining
        end
    end
    return 0.16
end

-- Возвращает длительность затухания панели к обычной.
local function RestoreActionBarFadeDuration()
    local frame = ActionBar.GetFrame()
    if frame and frame.fadeOut and frame.fadeOut.alpha then
        frame.fadeOut.alpha:SetDuration(ActionBar.animationDuration or 0.05)
    end
    local boosts = GetBoosts()
    if boosts and boosts.frame and boosts.frame.fadeOut and boosts.frame.fadeOut.alpha then
        boosts.frame.fadeOut.alpha:SetDuration(0.16)
    end
end

-- Останавливает затухание рамки, чтобы отменённое гашение не довело её до скрытия.
local function StopFade(frame)
    if not frame or not frame.fadeOut then
        return
    end
    frame.fadeOut:Stop()
    frame.fadeOut:SetScript("OnFinished", nil)
end

-- Прерывает гашение облака, если действие вернулось или режим уже не исследование.
local function CancelExploringCloudHide(boosts)
    if not boosts or not boosts.exploringHidePending then
        return false
    end
    boosts.exploringHidePending = nil
    boosts.exploringHideToken = (boosts.exploringHideToken or 0) + 1
    RestoreActionBarFadeDuration()
    local barFrame = ActionBar.GetFrame()
    StopFade(barFrame)
    StopFade(boosts.frame)
    if barFrame then
        ConsoleMenu:AnimatedShow(barFrame)
    end
    return true
end

-- После общего затухания в исследовании сбрасываем дополнительное действие.
local function ClearExtraAfterExploringHide(boosts, token)
    if not boosts then
        return
    end
    -- Старый обратный вызов не должен стереть облако, если гашение уже отменили.
    if token and boosts.exploringHideToken ~= token then
        return
    end
    if not boosts.exploringHidePending then
        return
    end
    boosts.exploringHidePending = nil
    boosts.layoutMix = 0
    boosts.layoutTarget = 0
    boosts.layoutDuration = 0
    boosts.layoutElapsed = 0
    boosts.progress = 0
    boosts.target = 0
    boosts.startProgress = 0
    boosts.elapsed = 0
    boosts.duration = 0
    boosts.captionHidePending = nil
    local extra = boosts.extraIcon
    if extra then
        extra.wanted = false
        extra.filled = false
        extra:SetAlpha(1)
        extra.lastSize = nil
        extra.texture:SetTexture(nil)
        extra:Hide()
    end
    if boosts.frame then
        boosts.frame:SetScript("OnUpdate", nil)
    end
end

-- В исследовании облако и дополнительная кнопка гаснут вместе с обратным перелётом.
local function BeginExploringCloudHide(boosts)
    if not boosts or boosts.exploringHidePending then
        return
    end
    boosts.exploringHidePending = true
    boosts.exploringHideToken = (boosts.exploringHideToken or 0) + 1
    local token = boosts.exploringHideToken
    HideBoostStickHint(boosts)
    -- Цикл не останавливаем: значки должны долететь, пока панель уже гаснет.

    local frame = ActionBar.GetFrame()
    local fadeDuration = GetExploringHideDuration(boosts)
    local function onDone()
        RestoreActionBarFadeDuration()
        ClearExtraAfterExploringHide(boosts, token)
    end

    if frame and frame:IsShown() then
        if frame.fadeOut and frame.fadeOut.alpha then
            frame.fadeOut.alpha:SetDuration(fadeDuration)
        end
        HideFrameThen(frame, onDone)
        return
    end
    if boosts.frame and boosts.frame:IsShown() then
        if boosts.frame.fadeOut and boosts.frame.fadeOut.alpha then
            boosts.frame.fadeOut.alpha:SetDuration(fadeDuration)
        end
        HideFrameThen(boosts.frame, onDone)
        return
    end
    onDone()
end

-- Если дополнительное действие уже ушло, прячем его после окончания раскладки.
local function FinishExtraLayoutExit(boosts)
    if (boosts.layoutMix or 0) > 0.001 or (boosts.layoutTarget or 0) ~= 0 then
        return
    end
    local extra = boosts.extraIcon
    if not extra or extra.wanted then
        return
    end
    extra.filled = false
    extra:SetAlpha(1)
    extra.lastSize = nil
    extra.texture:SetTexture(nil)
    extra:Hide()
end

-- Название дополнительного действия для подписи после посадки.
local function UpdateExtraActionCaption(icon)
    if not icon or not icon.Label then
        return
    end
    if not icon.filled then
        icon.Label:SetText("")
        return
    end
    local actionType, id, subType = GetActionInfo(icon.slotID)
    local title = ConsoleMenu:GetSlotTitle(actionType, id, subType, icon.slotID)
    icon.Label:SetText(title or "")
end

-- Подписи появляются ближе к концу полёта, не дожидаясь полной посадки.
local function ApplyExtraCaptions(boosts)
    local extra = boosts and boosts.extraIcon
    if not extra or not extra.Caption or not extra.KeyIcon then
        return
    end

    local captionProgress = ActionBar.boostExtraCaptionProgress or 0.78
    local flightProgress = extra.flightProgress
    if flightProgress == nil then
        flightProgress = boosts.progress
    end
    local show = extra.filled and extra:IsShown() and flightProgress >= captionProgress and boosts.target == 1 and not boosts.captionHidePending
    if extra.captionsShown == show then
        return
    end
    extra.captionsShown = show
    if show then
        ConsoleMenu:AnimatedShow(extra.Caption)
        ConsoleMenu:AnimatedShow(extra.KeyIcon)
    else
        ConsoleMenu:AnimatedHide(extra.Caption)
        ConsoleMenu:AnimatedHide(extra.KeyIcon)
    end
end

-- Ход одного значка: чуть быстрее или чуть медленнее общего перелёта.
local function IconFlightProgress(boosts, icon)
    local target = boosts.target or 0
    if not boosts.duration or boosts.duration <= 0 or boosts.progress == target then
        icon.flightProgress = target
        return target
    end

    local rate = icon.flightRate or 1
    local slowest = boosts.flightRateFloor or 1
    if slowest < 0.05 then
        slowest = 1
    end
    local amount = boosts.elapsed / boosts.duration
    if amount < 0 then
        amount = 0
    elseif amount > 1 then
        amount = 1
    end
    local travelled = amount * (rate / slowest)
    if travelled > 1 then
        travelled = 1
    end

    local startProgress = icon.flightStart
    if startProgress == nil then
        startProgress = boosts.startProgress or 0
    end
    local progress = startProgress + (target - startProgress) * EaseOutCubic(travelled)
    icon.flightProgress = progress
    return progress
end

-- Крестовина: на этих кнопках подбрасывается умение усиления.
-- Снизу слева стоит левый рычаг, а не отдельная нижняя кнопка креста.
local hostKeys = {
    UP = "PADDUP",
    RIGHT = "PADDRIGHT",
    DOWN = "PADLSTICK",
    LEFT = "PADDLEFT",
}

-- Наклон оси кувырка, у каждой кнопки свой, чтобы ребро не было вертикальной щелью.
local hostTilts = { 0.72, -0.86, 0.58, -1.05 }

-- Основная кнопка этой стороны креста, с текущей страницы панели.
local function FindHostButton(mainKey)
    local frame = ActionBar.GetFrame()
    if not frame or not frame.actionButtons or not mainKey then
        return nil
    end

    local page = 1
    if C_ActionBar and C_ActionBar.GetActionBarPage then
        page = C_ActionBar.GetActionBarPage() or 1
    end
    local pageStart = 12 * (page - 1) + 1
    local onCross
    for slotID, btn in pairs(frame.actionButtons) do
        if btn.mainKey == mainKey and not btn.modifierKey and not ActionBar.IsBoostSlot(slotID) and not ActionBar.ignoredSlot[slotID] then
            local position = ActionBar.buttonPositions[btn.mainKey]
            if position and (position[2] == "PADDCenter" or mainKey == "PADLSTICK") then
                if slotID >= pageStart and slotID < pageStart + 12 then
                    return btn
                end
                onCross = btn
            end
        end
    end
    return onCross
end

-- Скрывает остальные кнопки на том же месте, иначе под подбросом остаётся вторая иконка.
local function HideHostTwins(host)
    local frame = ActionBar.GetFrame()
    if not frame or not host then
        return
    end

    for _, btn in pairs(frame.actionButtons) do
        if btn ~= host and btn:IsShown() then
            local sameKey = btn.mainKey == host.mainKey
            local sameBottom = host.mainKey == "PADLSTICK" and btn.mainKey == "PADDDOWN"
            if sameKey or sameBottom then
                if btn.fadeIn then
                    btn.fadeIn:Stop()
                end
                if btn.fadeOut then
                    btn.fadeOut:Stop()
                    btn.fadeOut:SetScript("OnFinished", nil)
                end
                btn:SetAlpha(0)
                btn:Hide()
            end
        end
    end
end

-- Видимой остаётся только та кнопка, которая сама переворачивается.
function ActionBar.IsActiveBoostHostSlot(slotID)
    if not ActionBar.BoostFlipOwnsHosts or not ActionBar.BoostFlipOwnsHosts() then
        return false
    end
    local btn = ActionBar.GetButton(slotID)
    if not btn or btn.modifierKey or not ActionBar.IsBoostHostKey(btn.mainKey) then
        return false
    end
    return FindHostButton(btn.mainKey) == btn
end

-- Эти клавиши крестовины принимают умение из облака усилений.
function ActionBar.IsBoostHostKey(mainKey)
    return mainKey == "PADDUP" or mainKey == "PADDRIGHT" or mainKey == "PADDLEFT" or mainKey == "PADLSTICK"
end

-- Пока меню усилений раскрыто или ещё складывается, кнопки крестовины остаются на экране.
function ActionBar.BoostFlipOwnsHosts()
    local boosts = GetBoosts()
    if not boosts then
        return false
    end
    return (boosts.target or 0) == 1 or (boosts.progress or 0) > 0.001
end

-- Ход подброса: от нуля до единицы, пока монета в воздухе.
local function CoinTossAmount(progress)
    local settle = ActionBar.boostFlipSettle or ActionBar.boostCooldownProgress or 0.72
    if settle < 0.05 then
        settle = 0.72
    end
    if progress <= 0 then
        return 0
    end
    if progress >= settle then
        return 1
    end
    return progress / settle
end

-- Крутит текстуру, если клиент это умеет.
local function SetPieceRotation(piece, angle)
    if piece and piece.SetRotation then
        piece:SetRotation(angle or 0)
    end
end

-- Возвращает рисунок и подложку кнопки на место после подброса.
local function ResetHostCoin(btn)
    if not btn or not btn.coinActive then
        return
    end

    btn.coinActive = nil
    btn.boostFlipLock = nil
    btn.boostShowingAlt = nil
    btn.boostFlipSlot = nil
    btn.boostHostSaved = nil
    if btn.coinBaseLevel then
        btn:SetFrameLevel(btn.coinBaseLevel)
        btn.coinBaseLevel = nil
    end

    local texture = btn.texture
    if texture then
        texture:ClearAllPoints()
        texture:SetAllPoints(btn)
        texture:SetVertexColor(1, 1, 1)
        SetPieceRotation(texture, 0)
    end
    SetPieceRotation(btn.mask, 0)
    if btn.background then
        btn.background:ClearAllPoints()
        btn.background:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btn.background:SetSize(ActionBar.buttonSize + 8, ActionBar.buttonSize + 8)
        SetPieceRotation(btn.background, 0)
    end

    if btn.slotID and ActionBar.UpdateTexture then
        ActionBar.UpdateTexture(btn.slotID)
    end
    if btn.slotID and ActionBar.UpdateIcon then
        ActionBar.UpdateIcon(btn.slotID)
    end
    if btn.slotID and ActionBar.UpdateUsable then
        ActionBar.UpdateUsable(btn.slotID)
    end
end

-- Подбрасывает кружок как монету: быстрый взлёт, несколько кувырков и мягкая посадка.
local function ApplyCoinToss(texture, background, mask, parent, size, amount, tilt)
    local turns = ActionBar.boostCoinTurns or 3
    if turns < 1 then
        turns = 1
    end

    local edge = ActionBar.boostFlipEdge or 0.07
    if edge < 0.02 then
        edge = 0.02
    elseif edge > 0.4 then
        edge = 0.4
    end

    local thin = 1
    local axis = 0
    local slide = 0
    local lift = 0
    local shade = 1
    local scale = 1
    local showAlt = amount >= 1

    if amount > 0 and amount < 1 then
        -- Взлёт быстрее падения: пик раньше середины, как после щелчка пальцем.
        local rise = amount ^ 0.62
        local hop = math.sin(rise * math.pi)
        local bounce = 0
        if amount > 0.88 then
            local settle = (amount - 0.88) / 0.12
            if settle > 1 then
                settle = 1
            end
            bounce = math.sin(settle * math.pi) * 0.16
        end

        -- В середине кувырки чаще, у старта и посадки монета спокойнее.
        local spun = amount * amount * (3 - 2 * amount)
        local spin = spun * turns * math.pi
        thin = math.abs(math.cos(spin))
        if thin < edge then
            thin = edge
        end
        -- Отрицательный косинус — оборотная сторона. На ребре смена почти не видна.
        showAlt = math.cos(spin) < 0

        local tiltAmount = tilt or 0.7
        local direction = tiltAmount >= 0 and 1 or -1
        -- Ось качается на каждом обороте и гаснет к посадке.
        axis = tiltAmount * hop * 0.85 + math.sin(spin) * 0.7 * hop
        slide = math.sin(amount * math.pi) * direction * (ActionBar.boostFlipNudge or 6) + math.sin(spin) * 2 * hop
        lift = (hop * 0.92 + bounce) * (ActionBar.boostFlipLift or 58)
        scale = 1 + hop * 0.36
        shade = 0.16 + 0.84 * thin + hop * 0.14 * thin
        if shade > 1 then
            shade = 1
        end
    end

    local height = size * scale
    if height < 0.01 then
        height = 0.01
    end
    local width = height * thin
    if width < 0.01 then
        width = 0.01
    end
    local pad = 8 * scale

    if texture then
        texture:ClearAllPoints()
        texture:SetPoint("CENTER", parent, "CENTER", slide, lift)
        texture:SetSize(width, height)
        texture:SetVertexColor(shade, shade, shade)
        SetPieceRotation(texture, axis)
    end
    SetPieceRotation(mask, axis)
    if background then
        background:ClearAllPoints()
        background:SetPoint("CENTER", parent, "CENTER", slide, lift)
        background:SetSize(math.max(width + pad * thin, 0.01), height + pad)
        SetPieceRotation(background, axis)
    end

    return showAlt
end

-- Запоминает обычное лицо кнопки и в середине подброса показывает умение усиления.
local function ApplyHostFace(btn, boostSlot, showAlt)
    if not btn or not btn.texture then
        return
    end
    if not btn.boostHostSaved then
        btn.boostHostSaved = true
        local ok, current = pcall(function()
            return btn.texture:GetTexture()
        end)
        if ok then
            btn.boostHostTexture = current
        end
    end
    if btn.boostShowingAlt == showAlt then
        return
    end
    btn.boostShowingAlt = showAlt
    if showAlt then
        local textureFileID = GetBoostTexture(boostSlot)
        if textureFileID then
            btn.texture:SetTexture(textureFileID)
        end
        return
    end
    if btn.boostHostTexture then
        btn.texture:SetTexture(btn.boostHostTexture)
    end
end

-- В покое значок лежит в облаке. Кнопка крестовины подбрасывается на месте, как монета.
local ApplyBoostIconLayer
local function ApplyBoostIconPose(boosts, icon, progress, elapsedTime)
    SyncIconRestFromLayout(boosts, icon)
    progress = IconFlightProgress(boosts, icon)

    local host
    local tilt = hostTilts[icon.index] or 0.7
    if not icon.isExtra then
        local spec = ActionBar.boostSlots[icon.index]
        local hostKey = spec and hostKeys[spec.key]
        host = FindHostButton(hostKey)
    end

    if host then
        if progress <= 0 then
            ResetHostCoin(host)
            icon:SetAlpha(1)
        else
            local amount = CoinTossAmount(progress)
            icon:SetAlpha(0)
            host.coinActive = true
            host.boostFlipLock = true
            host.boostFlipSlot = icon.slotID
            if not host.coinBaseLevel then
                host.coinBaseLevel = host:GetFrameLevel()
            end
            host:SetFrameLevel(host.coinBaseLevel + 20)
            if host.fadeOut then
                host.fadeOut:Stop()
                host.fadeOut:SetScript("OnFinished", nil)
            end
            if host.fadeIn then
                host.fadeIn:Stop()
            end
            if not host:IsShown() then
                host:Show()
            end
            host:SetAlpha(1)
            if host.Icon then
                host.Icon:Hide()
            end
            HideHostTwins(host)
            local showAlt = ApplyCoinToss(host.texture, host.background, host.mask, host, ActionBar.buttonSize, amount, tilt)
            ApplyHostFace(host, icon.slotID, showAlt)
            if amount >= 1 and ActionBar.UpdateTextureDesaturation then
                ActionBar.UpdateTextureDesaturation(host, icon.slotID)
            end
        end
    end

    local x, y, size
    local floatX, floatY = 0, 0
    local tossingOwnFace = (not host) and progress > 0
    if tossingOwnFace then
        local amount = CoinTossAmount(progress)
        x = icon.restX
        y = icon.restY
        size = icon.restSize
        icon.coinSpinning = true
        ApplyCoinToss(icon.texture, icon.background, icon.mask, icon, math.max(size, 0.01), amount, tilt)
    else
        x = icon.restX
        y = icon.restY
        size = icon.restSize
        if progress <= 0 then
            floatX = math.sin(elapsedTime * icon.speed * pi2 + icon.phase) * ActionBar.boostFloatRadius
            floatY = math.cos(elapsedTime * icon.speed * 0.85 * pi2 + icon.phase) * ActionBar.boostFloatRadius
        end
        if icon.coinSpinning then
            SetPieceRotation(icon.texture, 0)
            SetPieceRotation(icon.mask, 0)
            SetPieceRotation(icon.background, 0)
            if icon.texture then
                icon.texture:SetVertexColor(1, 1, 1)
                icon.texture:ClearAllPoints()
                icon.texture:SetAllPoints(icon)
            end
            if icon.background then
                icon.background:ClearAllPoints()
                icon.background:SetPoint("CENTER", icon, "CENTER", 0, 0)
            end
            icon.coinSpinning = nil
            icon.lastWidth = nil
            icon.lastHeight = nil
        end
    end
    if size < 0.01 then
        size = 0.01
    end

    local poseX = x + floatX
    local poseY = y + floatY
    local poseParent = boosts.frame
    if icon.isExtra then
        poseParent = boosts.frame:GetParent() or boosts.frame
    end
    icon:SetPoint("CENTER", poseParent, "CENTER", poseX, poseY)

    if not tossingOwnFace and (icon.lastWidth ~= size or icon.lastHeight ~= size) then
        icon:SetSize(size, size)
        if icon.background and not icon.coinSpinning then
            icon.background:SetSize(size + 8, size + 8)
        end
        icon.lastWidth = size
        icon.lastHeight = size
    end
    if icon.lastSize ~= size then
        local crop = 3 / math.max(size, 1)
        icon.texture:SetTexCoord(crop, 1 - crop, crop, 1 - crop)
        icon.lastSize = size
    end

    -- Цифры восстановления только в развороте, без кольца отката.
    local showTimer = progress >= ActionBar.boostCooldownProgress
    if icon.timerShown ~= showTimer then
        icon.timerShown = showTimer
        icon.cooldown:SetHideCountdownNumbers(not showTimer)
        icon.cooldown:SetAlpha(showTimer and 1 or 0)
    end

    -- Счётчик зарядов появляется вместе с цифрами восстановления.
    local showCount = icon.hasCount and showTimer
    if icon.countShown ~= showCount then
        icon.countShown = showCount
        if showCount then
            ConsoleMenu:AnimatedShow(icon.StackCount)
        else
            ConsoleMenu:AnimatedHide(icon.StackCount)
        end
    end

    ApplyBoostIconLayer(icon, progress)
    if icon.isExtra then
        ApplyExtraCaptions(boosts)
    end
end

-- Ход разлёта или сбора без скачка при смене направления.
local function AdvanceBoostProgress(boosts, elapsed)
    if boosts.duration <= 0 or boosts.progress == boosts.target then
        boosts.progress = boosts.target
        return
    end

    boosts.elapsed = boosts.elapsed + elapsed
    local amount = boosts.elapsed / boosts.duration
    if amount >= 1 then
        boosts.progress = boosts.target
        boosts.duration = 0
        return
    end

    local eased = EaseOutCubic(amount)
    boosts.progress = boosts.startProgress + (boosts.target - boosts.startProgress) * eased
end

-- Цикл облака: плавание в покое, подброс кнопок крестовины как монет.
function ActionBar.OnBoostsUpdate(elapsed)
    local boosts = GetBoosts()
    if not boosts then
        return
    end

    boosts.time = boosts.time + elapsed
    AdvanceBoostProgress(boosts, elapsed)
    AdvanceLayoutMix(boosts, elapsed)

    for index = 1, #boosts.icons do
        local icon = boosts.icons[index]
        if icon:IsShown() or (boosts.progress or 0) <= 0 then
            ApplyBoostIconPose(boosts, icon, boosts.progress, boosts.time)
        end
    end

    local extra = boosts.extraIcon
    if extra and extra:IsShown() then
        ApplyBoostIconPose(boosts, extra, boosts.progress, boosts.time)
    else
        ApplyExtraCaptions(boosts)
    end

    FinishExtraLayoutExit(boosts)
    ApplyBoostStickHint(boosts)
    ApplyCloudHalo(boosts)
    if ActionBar.UpdateActionButtonShadows then
        ActionBar.UpdateActionButtonShadows()
    end

    if boosts.exploringHidePending then
        return
    end

    -- В исследовании гасим панель сразу, пока значки ещё летят обратно.
    local extraWanted = extra and extra.wanted
    if IsExploringWithoutShift() and not extraWanted then
        BeginExploringCloudHide(boosts)
        return
    end

    if not ActionBar.HasVisibleBoosts() then
        boosts.frame:SetScript("OnUpdate", nil)
        ConsoleMenu:AnimatedHide(boosts.frame)
        ApplyCloudHalo(boosts)
        HideExploringBarIfIdle()
    end
end

-- Запуск или остановка цикла, пока облако на экране.
local function SetBoostsUpdating(boosts, enabled)
    if enabled then
        boosts.frame:SetScript("OnUpdate", function(_, elapsed)
            ActionBar.OnBoostsUpdate(elapsed)
        end)
    else
        boosts.frame:SetScript("OnUpdate", nil)
    end
end

-- Значки ещё летят или ждут гашения подписей перед сбором.
function ActionBar.IsBoostMotionActive()
    local boosts = GetBoosts()
    if not boosts then
        return false
    end
    if boosts.captionHidePending then
        return true
    end
    if (boosts.duration or 0) > 0 then
        return true
    end
    if (boosts.target or 0) == 1 then
        return true
    end
    if (boosts.progress or 0) > 0.001 then
        return true
    end
    return false
end

-- Текущий ход разворота: ноль у рычага, единица на крестовине.
function ActionBar.GetBoostProgress()
    local boosts = GetBoosts()
    return boosts and boosts.progress or 0
end

-- Есть ли в облаке хотя бы один заполненный значок.
function ActionBar.HasVisibleBoosts()
    local boosts = GetBoosts()
    if not boosts then
        return false
    end
    -- Пока облако гаснет в исследовании, его считаем скрытым. В бою это уже не должно его прятать.
    if boosts.exploringHidePending and IsExploringWithoutShift() then
        return false
    end
    if boosts.extraIcon and (boosts.extraIcon.filled or boosts.extraIcon.wanted or (boosts.layoutMix or 0) > 0.001) then
        return true
    end
    if ActionBar.IsBoostMotionActive() then
        return true
    end
    if IsExploringWithoutShift() then
        return false
    end
    for index = 1, #boosts.icons do
        if boosts.icons[index].filled then
            return true
        end
    end
    return false
end

-- В облаке сейчас есть заполненная дополнительная кнопка действия.
function ActionBar.HasVisibleExtraAction()
    local boosts = GetBoosts()
    if not boosts or not boosts.extraIcon then
        return false
    end
    if boosts.exploringHidePending and IsExploringWithoutShift() then
        return false
    end
    return boosts.extraIcon.wanted == true or boosts.extraIcon.filled == true or (boosts.layoutMix or 0) > 0.001
end

-- Панель в исследовании уже гаснет вместе с облаком.
function ActionBar.IsExploringCloudHiding()
    local boosts = GetBoosts()
    return boosts and boosts.exploringHidePending == true
end

-- Слой значка: в покое обесцвеченные уходят вниз, готовые остаются сверху.
function ApplyBoostIconLayer(icon, progress)
    if not icon.filled then
        return
    end

    local clusterLevel = icon:GetParent():GetFrameLevel()
    if icon.isExtra then
        icon:SetFrameLevel(clusterLevel + 10)
    else
        local atRest = progress < ActionBar.boostCooldownProgress
        if atRest and icon.texture and icon.texture:IsDesaturated() then
            icon:SetFrameLevel(clusterLevel + 1)
        else
            icon:SetFrameLevel(clusterLevel + icon.index + 1)
        end
    end

    if icon.StackCount then
        icon.StackCount:SetFrameLevel(icon:GetFrameLevel() + 2)
    end
    if icon.Caption then
        icon.Caption:SetFrameLevel(icon:GetFrameLevel() + 4)
    end
    if icon.KeyIcon then
        icon.KeyIcon:SetFrameLevel(icon:GetFrameLevel() + 6)
    end
end

-- Обесцвечивание значка облака: при CTRL все значки серые, иначе по пригодности.
local function UpdateBoostIconUsable(icon)
    if not icon.filled or not icon.texture then
        return
    end
    if IsControlKeyDown() then
        icon.texture:SetDesaturated(true)
        return
    end
    ActionBar.UpdateTextureDesaturation(icon, icon.slotID)
end

-- Число зарядов на значке облака.
local function UpdateBoostIconCount(icon)
    local stackCount = icon.StackCount
    if not stackCount or not stackCount.Text then
        return
    end

    if not icon.filled then
        icon.hasCount = false
        stackCount.Text:SetText("")
        if icon.countShown then
            icon.countShown = false
            ConsoleMenu:AnimatedHide(stackCount)
        end
        return
    end

    local count = C_ActionBar.GetActionDisplayCount(icon.slotID)
    if count and issecretvalue and issecretvalue(count) then
        stackCount.Text:SetText(count)
        return
    end

    if (count and count ~= "" and count ~= "0" and count ~= 0) or ActionBar.stackCountChange[icon.slotID] then
        stackCount.Text:SetText(count)
        ActionBar.stackCountChange[icon.slotID] = true
        icon.hasCount = true
    else
        stackCount.Text:SetText("")
        icon.hasCount = false
        if icon.countShown then
            icon.countShown = false
            ConsoleMenu:AnimatedHide(stackCount)
        end
    end
end

-- Время восстановления значка. Кольцо отката не рисуем.
local function UpdateBoostIconCooldown(icon)
    if not icon.cooldown then
        return
    end

    local info = C_ActionBar.GetActionCooldown(icon.slotID)
    if info and info.isActive then
        local duration = C_ActionBar.GetActionCooldownDuration(icon.slotID)
        icon.cooldown:SetCooldownFromDurationObject(duration)
        icon.cooldown:Show()
    else
        icon.cooldown:Clear()
    end
end

-- Значение скрыто, по нему нельзя решать, пуста ли ячейка.
local function IsSecretValue(value)
    return value ~= nil and issecretvalue and issecretvalue(value)
end

-- Есть ли действие в ячейке облака. Пустой ответ оставляем без изменений.
local function SlotHasAction(slotID)
    if not slotID or not C_ActionBar or not C_ActionBar.HasAction then
        return false
    end
    local ok, hasAction = pcall(C_ActionBar.HasAction, slotID)
    if not ok then
        return nil
    end
    if IsSecretValue(hasAction) then
        return true
    end
    return hasAction == true
end

-- Текстура, видимость и пригодность одного значка облака.
local function UpdateBoostIcon(icon)
    local slotID = icon.slotID
    local hasAction
    if icon.isExtra then
        hasAction = ActionBar.HasExtraAction()
    else
        hasAction = SlotHasAction(slotID)
        if hasAction == nil then
            return
        end
    end
    local textureFileID, isSecret = GetBoostTexture(slotID)

    -- Скрытая текстура не должна оставлять в облаке уже исчезнувшую дополнительную кнопку.
    if isSecret and hasAction ~= false then
        return
    end

    if not hasAction or not textureFileID then
        -- Ячейка заполнена, а значок ещё не готов: оставляем прошлую картинку, иначе облако мигает.
        if hasAction then
            if icon.isExtra then
                icon.wanted = true
            end
            return
        end
        if icon.isExtra then
            icon.wanted = false
            local boosts = GetBoosts()
            if boosts and IsExploringWithoutShift() then
                return
            end
            if boosts and ((boosts.layoutMix or 0) > 0.001 or (boosts.layoutTarget or 0) == 1) then
                return
            end
            FinishExtraLayoutExit(boosts)
            return
        end
        icon.filled = false
        icon.texture:SetTexture(nil)
        UpdateBoostIconCount(icon)
        icon:Hide()
        return
    end

    if icon.isExtra then
        icon.wanted = true
        if not icon:IsShown() then
            icon:SetAlpha(0)
        end
    end
    icon.filled = true
    icon.texture:SetTexture(textureFileID)
    icon:Show()
    UpdateBoostIconCooldown(icon)
    UpdateBoostIconUsable(icon)
    UpdateBoostIconCount(icon)
    if icon.isExtra then
        UpdateExtraActionCaption(icon)
    end

    local boosts = GetBoosts()
    local progress = boosts and boosts.progress or 0
    ApplyBoostIconLayer(icon, progress)
end

-- Подтянуть все значки облака и скрыть рамку, если ячеек нет.
function ActionBar.UpdateBoosts()
    local boosts = GetBoosts()
    if not boosts then
        return
    end

    local extra = boosts.extraIcon
    if extra then
        local slotID = ActionBar.GetExtraActionSlotID()
        if extra.slotID ~= slotID then
            extra.slotID = slotID
            ActionBar.EnableRangeCheck(slotID, true)
        end
        UpdateBoostIcon(extra)
        if extra.wanted then
            CancelExploringCloudHide(boosts)
            BeginLayoutMotion(boosts, 1)
            -- Показываем панель только если её ещё нет на экране, иначе сбивается затухание.
            if IsExploringWithoutShift() then
                local barFrame = ActionBar.GetFrame()
                if barFrame and not barFrame:IsShown() then
                    ConsoleMenu:AnimatedShow(barFrame)
                end
            end
        elseif IsExploringWithoutShift() then
            BeginExploringCloudHide(boosts)
        else
            CancelExploringCloudHide(boosts)
            BeginLayoutMotion(boosts, 0)
        end
    end

    for index = 1, #boosts.icons do
        UpdateBoostIcon(boosts.icons[index])
    end

    ApplyExtraCaptions(boosts)

    local layoutBusy = (boosts.layoutDuration or 0) > 0
        or math.abs((boosts.layoutMix or 0) - (boosts.layoutTarget or 0)) > 0.001
    if boosts.exploringHidePending and IsExploringWithoutShift() then
        -- Гашение уже идёт: значки продолжают лететь, пока панель затухает.
        SetBoostsUpdating(boosts, true)
        return
    end
    if boosts.exploringHidePending then
        CancelExploringCloudHide(boosts)
    end
    if ActionBar.HasVisibleBoosts() or layoutBusy then
        ConsoleMenu:AnimatedShow(boosts.frame)
        SetBoostsUpdating(boosts, true)
        ActionBar.OnBoostsUpdate(0)
    else
        SetBoostsUpdating(boosts, false)
        ConsoleMenu:AnimatedHide(boosts.frame)
        ApplyCloudHalo(boosts)
        HideExploringBarIfIdle()
    end
end

-- Запоминает, откуда каждый значок продолжает полёт при смене направления.
local function CaptureFlightStarts(boosts)
    local function capture(icon)
        if not icon then
            return
        end
        if icon.flightProgress == nil then
            icon.flightStart = boosts.progress or 0
        else
            icon.flightStart = icon.flightProgress
        end
    end

    for index = 1, #boosts.icons do
        capture(boosts.icons[index])
    end
    capture(boosts.extraIcon)
end

-- Самая маленькая скорость: по ней длится общий перелёт, чтобы медленный значок успел сесть.
local function SlowestFlightRate(boosts)
    local slowest = 1
    local function consider(icon)
        if not icon then
            return
        end
        local rate = icon.flightRate or 1
        if rate < slowest then
            slowest = rate
        end
    end

    for index = 1, #boosts.icons do
        consider(boosts.icons[index])
    end
    consider(boosts.extraIcon)
    if slowest < 0.05 then
        return 1
    end
    return slowest
end

-- Разворот в крест или сбор обратно в облако с текущей точки.
local function BeginBoostMotion(boosts, target)
    if boosts.target == target and boosts.progress == target then
        return
    end

    local span = math.abs(target - boosts.progress)
    if span < 0.001 then
        boosts.progress = target
        boosts.target = target
        boosts.duration = 0
        CaptureFlightStarts(boosts)
        ActionBar.OnBoostsUpdate(0)
        return
    end

    CaptureFlightStarts(boosts)
    boosts.flightRateFloor = SlowestFlightRate(boosts)
    local fullDuration = target == 1 and ActionBar.boostExpandDuration or ActionBar.boostCollapseDuration
    boosts.target = target
    boosts.startProgress = boosts.progress
    boosts.elapsed = 0
    boosts.duration = fullDuration * span / boosts.flightRateFloor
end

-- Прячет рамку и вызывает продолжение после затухания.
HideFrameThen = function(frame, callback)
    if not frame or not frame.fadeOut then
        if callback then
            callback()
        end
        return
    end
    if not frame:IsShown() then
        if callback then
            callback()
        end
        return
    end

    ConsoleMenu:AnimatedHide(frame)
    if not frame:IsShown() then
        if callback then
            callback()
        end
        return
    end

    frame.fadeOut:SetScript("OnFinished", function()
        frame:Hide()
        frame.fadeOut:SetScript("OnFinished", nil)
        frame.fadeOut.alpha:SetFromAlpha(1)
        frame.fadeOut.alpha:SetToAlpha(0)
        if callback then
            callback()
        end
    end)
end

-- Сначала гасит подписи дополнительного действия, затем продолжает сбор облака.
local function HideExtraCaptionsThen(boosts, onDone)
    local extra = boosts.extraIcon
    if not extra or not extra.captionsShown then
        onDone()
        return
    end

    extra.captionsShown = false
    local captionShown = extra.Caption and extra.Caption:IsShown()
    local keyShown = extra.KeyIcon and extra.KeyIcon:IsShown()
    local remaining = (captionShown and 1 or 0) + (keyShown and 1 or 0)
    if remaining == 0 then
        onDone()
        return
    end

    local function finished()
        remaining = remaining - 1
        if remaining <= 0 then
            onDone()
        end
    end

    if captionShown then
        HideFrameThen(extra.Caption, finished)
    end
    if keyShown then
        HideFrameThen(extra.KeyIcon, finished)
    end
end

function ActionBar.SetBoostsExpanded(expanded)
    local boosts = GetBoosts()
    if not boosts then
        return
    end

    local target = expanded and 1 or 0

    if expanded then
        boosts.captionHidePending = nil
        BeginBoostMotion(boosts, 1)
        ApplyExtraCaptions(boosts)
        return
    end

    if boosts.captionHidePending then
        return
    end

    if boosts.target == 0 and boosts.progress == 0 then
        return
    end

    local extra = boosts.extraIcon
    if extra and extra.captionsShown then
        boosts.captionHidePending = true
        HideExtraCaptionsThen(boosts, function()
            if not boosts.captionHidePending then
                return
            end
            boosts.captionHidePending = nil
            BeginBoostMotion(boosts, 0)
            ActionBar.OnBoostsUpdate(0)
        end)
        return
    end

    BeginBoostMotion(boosts, 0)
end

-- Создание облака под правой группой кнопок.
function ActionBar.CreateBoosts(parent)
    if parent.boosts then
        return parent.boosts
    end

    local cluster = CreateFrame("Frame", "ConsoleMenuActionBarBoosts", parent)
    cluster:SetSize(ActionBar.boostClusterSize, ActionBar.boostClusterSize)
    cluster:SetPoint("CENTER", parent.PADCenter, "CENTER", 0, 0)
    cluster:SetFrameLevel(parent:GetFrameLevel() + 6)
    DisablePixelSnap(cluster)
    ConsoleMenu:InitFadeAnimations(cluster, 0.16)
    if cluster.SetClipsChildren then
        cluster:SetClipsChildren(false)
    end
    cluster:Hide()

    local boosts = {
        frame = cluster,
        icons = {},
        progress = 0,
        target = 0,
        startProgress = 0,
        elapsed = 0,
        duration = 0,
        time = 0,
        layoutMix = 0,
        layoutTarget = 0,
        layoutStartMix = 0,
        layoutElapsed = 0,
        layoutDuration = 0,
        stickHint = CreateBoostStickHint(cluster),
    }

    for index = 1, #ActionBar.boostSlots do
        boosts.icons[index] = CreateBoostIcon(cluster, index, ActionBar.boostSlots[index])
        local button = parent.actionButtons and parent.actionButtons[ActionBar.boostSlots[index].slotID]
        if button then
            button:Hide()
            button:SetAlpha(0)
        end
    end

    boosts.extraIcon = CreateBoostIcon(cluster, 5, {
        slotID = ActionBar.GetExtraActionSlotID(),
        isExtra = true,
    })
    ActionBar.EnableRangeCheck(boosts.extraIcon.slotID, true)

    parent.boosts = boosts
    ActionBar.UpdateBoosts()
    return boosts
end
