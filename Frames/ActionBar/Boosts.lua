-- Облако усилений на месте правого рычага: плавание, разлёт по дугам и сбор.

local ConsoleMenu = _G.ConsoleMenu
local ActionBar = ConsoleMenu.ActionBar

local pi2 = math.pi * 2

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

-- Точка на квадратичной дуге от облака к кресту.
local function BezierPoint(startX, startY, controlX, controlY, endX, endY, t)
    local rest = 1 - t
    local restSquare = rest * rest
    local tSquare = t * t
    local mix = 2 * rest * t
    local x = restSquare * startX + mix * controlX + tSquare * endX
    local y = restSquare * startY + mix * controlY + tSquare * endY
    return x, y
end

-- Контрольная точка дуги: середина пути со сдвигом по часовой стрелке.
local function ArcControl(startX, startY, endX, endY, bulge)
    local midX = (startX + endX) / 2
    local midY = (startY + endY) / 2
    local dx = endX - startX
    local dy = endY - startY
    local length = math.sqrt(dx * dx + dy * dy)
    if length < 1 then
        return midX, midY
    end
    local scaledBulge = math.min(bulge, length * 0.42)
    return midX + (dy / length) * scaledBulge, midY + (-dx / length) * scaledBulge
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

    if not textureFileID then
        textureFileID = C_ActionBar.GetActionTexture(slotID)
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
    icon.restX = ActionBar.boostCloudOffsets[index].x
    icon.restY = ActionBar.boostCloudOffsets[index].y
    icon.restSize = ActionBar.boostCloudSizes[index]
    icon.expandX = ActionBar.boostExpandPositions[index].x
    icon.expandY = ActionBar.boostExpandPositions[index].y
    icon.expandSize = ActionBar.buttonSize
    icon.phase = ActionBar.boostFloatPhases[index]
    icon.speed = ActionBar.boostFloatSpeeds[index]
    icon.controlX, icon.controlY = ArcControl(
        icon.restX,
        icon.restY,
        icon.expandX,
        icon.expandY,
        ActionBar.boostArcBulge
    )
    icon.filled = false
    icon.index = index

    icon:SetSize(icon.restSize, icon.restSize)
    icon:SetPoint("CENTER", parent, "CENTER", icon.restX, icon.restY)
    icon:SetFrameLevel(parent:GetFrameLevel() + index + 1)
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
    local edge = 3 / icon.restSize
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

    -- local countBackground = stackCount:CreateTexture(nil, "ARTWORK")
    -- countBackground:SetAllPoints()
    -- countBackground:SetAlpha(0.5)
    -- countBackground:SetTexture(ConsoleMenu.Backgrounds and ConsoleMenu.Backgrounds.PAD)
    -- DisablePixelSnap(countBackground)
    -- stackCount.Background = countBackground

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

    hint.Background = hint:CreateTexture(nil, "BACKGROUND")
    hint.Background:SetAllPoints()
    hint.Background:SetAlpha(0.75)
    DisablePixelSnap(hint.Background)
    local stickBackground = ConsoleMenu.Backgrounds and ConsoleMenu.Backgrounds.STICK
    if stickBackground then
        hint.Background:SetTexture(stickBackground)
    end

    hint.Shadow = hint:CreateTexture(nil, "BACKGROUND")
    hint.Shadow:SetPoint("TOPLEFT", hint.Background, "TOPLEFT", -ActionBar.stackCountShadowOffsef, ActionBar.stackCountShadowOffsef)
    hint.Shadow:SetPoint("BOTTOMRIGHT", hint.Background, "BOTTOMRIGHT", ActionBar.stackCountShadowOffsef, -ActionBar.stackCountShadowOffsef)
    hint.Shadow:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png")
    DisablePixelSnap(hint.Shadow)

    return hint
end

-- Значок рычага гаснет в начале разлёта и появляется лишь к концу сбора.
local function ApplyBoostStickHint(boosts)
    local hint = boosts.stickHint
    if not hint then
        return
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

-- Положение и размер значка на текущем ходе дуги и при плавании.
local ApplyBoostIconLayer
local function ApplyBoostIconPose(boosts, icon, progress, elapsedTime)
    local x, y = BezierPoint(
        icon.restX,
        icon.restY,
        icon.controlX,
        icon.controlY,
        icon.expandX,
        icon.expandY,
        progress
    )
    local size = icon.restSize + (icon.expandSize - icon.restSize) * progress
    local floatStrength = 1 - progress
    local floatX = math.sin(elapsedTime * icon.speed * pi2 + icon.phase) * ActionBar.boostFloatRadius * floatStrength
    local floatY = math.cos(elapsedTime * icon.speed * 0.85 * pi2 + icon.phase) * ActionBar.boostFloatRadius * floatStrength

    local poseX = x + floatX
    local poseY = y + floatY
    icon:SetPoint("CENTER", boosts.frame, "CENTER", poseX, poseY)

    if icon.lastSize ~= size then
        icon:SetSize(size, size)
        icon.background:SetSize(size + 8, size + 8)
        local edge = 3 / math.max(size, 1)
        icon.texture:SetTexCoord(edge, 1 - edge, edge, 1 - edge)
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

-- Цикл облака: плавание в покое и полёт по дуге.
function ActionBar.OnBoostsUpdate(elapsed)
    local boosts = GetBoosts()
    if not boosts then
        return
    end

    boosts.time = boosts.time + elapsed
    AdvanceBoostProgress(boosts, elapsed)

    for index = 1, #boosts.icons do
        local icon = boosts.icons[index]
        if icon:IsShown() then
            ApplyBoostIconPose(boosts, icon, boosts.progress, boosts.time)
        end
    end

    ApplyBoostStickHint(boosts)
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

-- Есть ли в облаке хотя бы один заполненный значок.
function ActionBar.HasVisibleBoosts()
    local boosts = GetBoosts()
    if not boosts then
        return false
    end
    for index = 1, #boosts.icons do
        if boosts.icons[index].filled then
            return true
        end
    end
    return false
end

-- Слой значка: в покое обесцвеченные уходят вниз, готовые остаются сверху.
function ApplyBoostIconLayer(icon, progress)
    if not icon.filled then
        return
    end

    local clusterLevel = icon:GetParent():GetFrameLevel()
    local atRest = progress < ActionBar.boostCooldownProgress
    if atRest and icon.texture and icon.texture:IsDesaturated() then
        icon:SetFrameLevel(clusterLevel + 1)
    else
        icon:SetFrameLevel(clusterLevel + icon.index + 1)
    end

    if icon.StackCount then
        icon.StackCount:SetFrameLevel(icon:GetFrameLevel() + 2)
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

-- Текстура, видимость и пригодность одного значка облака.
local function UpdateBoostIcon(icon)
    local slotID = icon.slotID
    local hasAction = C_ActionBar.HasAction(slotID)
    local textureFileID, isSecret = GetBoostTexture(slotID)

    if isSecret then
        return
    end

    if not hasAction or not textureFileID then
        if InCombatLockdown and InCombatLockdown() and hasAction then
            return
        end
        icon.filled = false
        icon.texture:SetTexture(nil)
        UpdateBoostIconCount(icon)
        icon:Hide()
        return
    end

    icon.filled = true
    icon.texture:SetTexture(textureFileID)
    icon:Show()
    UpdateBoostIconCooldown(icon)
    UpdateBoostIconUsable(icon)
    UpdateBoostIconCount(icon)

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

    for index = 1, #boosts.icons do
        UpdateBoostIcon(boosts.icons[index])
    end

    if ActionBar.HasVisibleBoosts() then
        ConsoleMenu:AnimatedShow(boosts.frame)
        SetBoostsUpdating(boosts, true)
        ActionBar.OnBoostsUpdate(0)
    else
        SetBoostsUpdating(boosts, false)
        ConsoleMenu:AnimatedHide(boosts.frame)
    end
end

-- Разворот в крест или сбор обратно в облако с текущей точки.
function ActionBar.SetBoostsExpanded(expanded)
    local boosts = GetBoosts()
    if not boosts then
        return
    end

    local target = expanded and 1 or 0
    if boosts.target == target and boosts.progress == target then
        return
    end

    local span = math.abs(target - boosts.progress)
    if span < 0.001 then
        boosts.progress = target
        boosts.target = target
        boosts.duration = 0
        ActionBar.OnBoostsUpdate(0)
        return
    end

    local fullDuration = expanded and ActionBar.boostExpandDuration or ActionBar.boostCollapseDuration
    boosts.target = target
    boosts.startProgress = boosts.progress
    boosts.elapsed = 0
    boosts.duration = fullDuration * span
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

    parent.boosts = boosts
    ActionBar.UpdateBoosts()
    return boosts
end
