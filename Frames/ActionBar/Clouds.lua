-- Облака умений у рычагов. Значки покачиваются на месте, каждый надувается сам и не перелетает на кнопки.

local ConsoleMenu = _G.ConsoleMenu
local ActionBar = ConsoleMenu.ActionBar

local modifierCVars = {
    SHIFT = "GamePadEmulateShift",
    CTRL = "GamePadEmulateCtrl",
    ALT = "GamePadEmulateAlt",
}

-- Смягчение с перелётом, как у роста значка.
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

-- Смягчение к концу отрезка, чтобы значки сели на новое место без рывка.
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

local function Lerp(from, to, amount)
    return from + (to - from) * amount
end

-- Размер значка: растёт с лёгким перелётом и так же сдувается.
local function BubbleScale(life)
    if life <= 0 then
        return 0
    end
    if life >= 1 then
        return 1
    end
    local scale = EaseOutBack(life)
    if scale < 0 then
        return 0
    end
    return scale
end

-- Снимает привязку к пиксельной сетке, иначе медленное покачивание прыгает.
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

local pi2 = math.pi * 2

-- Физическая кнопка, назначенная этой дополнительной клавише.
local function PhysicalKey(modifier)
    local cvarName = modifier and modifierCVars[modifier]
    if not cvarName or not GetCVar then
        return nil
    end
    local value = GetCVar(cvarName)
    if type(value) ~= "string" or value == "" or string.upper(value) == "NONE" then
        return nil
    end
    return string.upper(value)
end

-- Какая дополнительная клавиша сейчас зажата.
local function HeldModifier()
    if not IsModifierKeyDown or not IsModifierKeyDown() then
        return nil
    end
    if IsControlKeyDown and IsControlKeyDown() then
        return "CTRL"
    end
    if IsShiftKeyDown and IsShiftKeyDown() then
        return "SHIFT"
    end
    if IsAltKeyDown and IsAltKeyDown() then
        return "ALT"
    end
    return nil
end

-- Кнопка основной панели без дополнительной клавиши. При двух страницах берётся боевая.
local function FindMainPageButton(mainKey)
    local frame = ActionBar.GetFrame()
    if not frame or not frame.actionButtons or not mainKey then
        return nil
    end
    local fallback
    for _, btn in pairs(frame.actionButtons) do
        if btn.mainKey == mainKey and not btn.modifierKey and btn.slotID and btn.slotID >= 1 and btn.slotID <= 24 then
            if ActionBar.IsSlotOnCombatPage and ActionBar.IsSlotOnCombatPage(btn.slotID) then
                return btn
            end
            if not fallback then
                fallback = btn
            end
        end
    end
    return fallback
end

-- Кнопка панели с этой клавишей и этим модификатором.
local function FindSpellButton(mainKey, modifier)
    local frame = ActionBar.GetFrame()
    if not frame or not frame.actionButtons or not mainKey then
        return nil
    end
    for _, btn in pairs(frame.actionButtons) do
        if btn.mainKey == mainKey and btn.modifierKey == modifier then
            return btn
        end
    end
    return nil
end

-- Правый рычаг привязан к ячейке основной панели, а не занят модификатором.
local function RightStickIsAction()
    if PhysicalKey("SHIFT") == "PADRSTICK" or PhysicalKey("CTRL") == "PADRSTICK" or PhysicalKey("ALT") == "PADRSTICK" then
        return false
    end
    return FindMainPageButton("PADRSTICK") ~= nil
end

-- Список клавиш облака для рычага.
local function CloudKeys(stick, modifier)
    local keys = {}
    local source = stick == "PADRSTICK" and ActionBar.rightCloudKeys or ActionBar.leftCloudKeys
    if source then
        for index = 1, #source do
            keys[#keys + 1] = source[index]
        end
    end
    if stick == "PADLSTICK" and RightStickIsAction() then
        keys[#keys + 1] = "PADRSTICK"
    end
    return keys, modifier
end

-- Облака, которые сейчас положены рычагам-модификаторам.
local function CloudSpecs()
    local specs = {}
    local modifiers = { "SHIFT", "CTRL", "ALT" }
    for index = 1, #modifiers do
        local modifier = modifiers[index]
        local stick = PhysicalKey(modifier)
        if stick == "PADRSTICK" or stick == "PADLSTICK" then
            local keys = CloudKeys(stick, modifier)
            specs[#specs + 1] = {
                stick = stick,
                modifier = modifier,
                keys = keys,
            }
        end
    end
    return specs
end

-- Кнопка умения облака. Правый рычаг берётся с основной панели.
local function CloudSpellButton(key, modifier)
    if key == "PADRSTICK" then
        return FindMainPageButton(key)
    end
    return FindSpellButton(key, modifier)
end

-- Снимает привязку к сетке у значка и его рисунка, иначе покачивание дёргается.
local function ReleaseIconSnap(icon)
    if not icon then
        return
    end
    DisablePixelSnap(icon)
    DisablePixelSnap(icon.texture)
    DisablePixelSnap(icon.background)
    DisablePixelSnap(icon.mask)
    DisablePixelSnap(icon.cooldown)
    DisablePixelSnap(icon.StackCount)
end

-- Скорость, сдвиг по времени и рост значка умения. Места покоя общие для обоих рычагов.
local function PrepareSpellIcon(icon, index)
    local phases = ActionBar.boostFloatPhases or {}
    local speeds = ActionBar.boostFloatSpeeds or {}
    local rates = ActionBar.boostFlightRates or {}
    icon.cloudIndex = index
    icon.isCenter = false
    icon.bubble = 0
    icon.bubbleTarget = 0
    icon.floatPhase = phases[index] or (index * 0.7)
    icon.floatSpeed = speeds[index] or 0.3
    icon.floatRate = rates[index] or 1
    icon:SetScale(1)
    icon:SetAlpha(0)
    ReleaseIconSnap(icon)
end

-- Крупный значок в середине облака качается отдельно. Второй получает сдвиг, чтобы не повторять первый.
local function PrepareCenterIcon(icon, index)
    local phase = ActionBar.boostExtraFloatPhase or 2.55
    if index == 2 then
        phase = phase + math.pi
    end
    icon.cloudIndex = index
    icon.isCenter = true
    icon.bubble = 0
    icon.bubbleTarget = 0
    icon.centerSide = 0
    icon.centerDrop = 0
    icon.floatPhase = phase
    icon.floatSpeed = ActionBar.boostExtraFloatSpeed or 0.33
    icon.floatRate = ActionBar.boostExtraFlightRate or 0.96
    icon:SetScale(1)
    icon:SetAlpha(0)
    ReleaseIconSnap(icon)
end

-- Маленький значок умения в облаке. Та же круглая заготовка, что у кнопки панели.
local function CreateCloudIcon(parent)
    local icon = ActionBar.CreateRoundIcon(parent)
    icon:SetScale(1)
    icon:SetAlpha(0)
    icon:Hide()
    if icon.cooldown then
        if icon.cooldown.SetHideCountdownNumbers then
            icon.cooldown:SetHideCountdownNumbers(true)
        end
        icon.cooldown:Hide()
    end
    return icon
end

-- Готовит два облака на кадре панели. Места покоя уже содержат сдвиг вниз, поэтому якорь стоит в центре рычага.
local function EnsureClouds(frame)
    if frame.spellClouds then
        return frame.spellClouds
    end
    local clouds = {
        bubbleShow = false,
        time = 0,
        driver = CreateFrame("Frame", nil, frame),
    }
    clouds.driver:Hide()

    local function MakeCluster(anchor)
        local cluster = CreateFrame("Frame", nil, frame)
        cluster:SetSize(ActionBar.boostClusterSize or 200, ActionBar.boostClusterSize or 200)
        cluster:SetPoint("CENTER", anchor, "CENTER", 0, 0)
        cluster:SetFrameLevel((frame:GetFrameLevel() or 0) + 12)
        if cluster.SetClipsChildren then
            cluster:SetClipsChildren(false)
        end
        cluster.layoutMix = 0
        cluster.layoutTarget = 0
        cluster.icons = {}
        cluster.centers = {}
        for index = 1, 4 do
            cluster.icons[index] = CreateCloudIcon(cluster)
            PrepareSpellIcon(cluster.icons[index], index)
        end
        for index = 1, 2 do
            cluster.centers[index] = CreateCloudIcon(cluster)
            PrepareCenterIcon(cluster.centers[index], index)
        end
        cluster:Hide()
        return cluster
    end

    clouds.right = MakeCluster(frame.PADCenter or frame)
    clouds.left = MakeCluster(frame.PADDCenter or frame)
    clouds.loneIcons = {
        CreateCloudIcon(frame),
        CreateCloudIcon(frame),
    }
    PrepareCenterIcon(clouds.loneIcons[1], 1)
    PrepareCenterIcon(clouds.loneIcons[2], 2)
    frame.spellClouds = clouds

    clouds.driver:SetScript("OnUpdate", function(_, elapsed)
        ActionBar.StepClouds(elapsed)
    end)
    return clouds
end

-- Рисунок ячейки, если он уже известен.
local function SlotTexture(slotID)
    if not slotID or not C_ActionBar or not C_ActionBar.GetActionTexture then
        return nil
    end
    local texture = C_ActionBar.GetActionTexture(slotID)
    if ActionBar.IsSecretValue and ActionBar.IsSecretValue(texture) then
        return nil
    end
    return texture
end

-- Рисунок способности области, если её показал бы и стандартный интерфейс.
local function ZoneAbilityTexture()
    if not ConsoleMenu.GetDisplayedZoneAbility then
        return nil
    end
    local ability = ConsoleMenu:GetDisplayedZoneAbility()
    local spellID = ability and ability.spellID
    if not spellID or not C_Spell or not C_Spell.GetSpellTexture then
        return nil
    end
    return C_Spell.GetSpellTexture(spellID)
end

-- Запоминает рисунок значка. Размер и место задаёт покачивание, чтобы рост не спорил с раскладкой.
local function AssignIcon(icon, texture, slotID)
    if not icon then
        return
    end
    if not texture then
        icon.painted = nil
        icon.paintSlot = nil
        if icon.cooldown then
            icon.cooldown:Clear()
        end
        if icon.StackCount then
            icon.StackCount:Hide()
        end
        return
    end
    if icon.texture then
        icon.texture:SetTexture(texture)
    end
    icon.paintSlot = slotID
    icon.painted = true
end

-- Значок облака без отсчёта перезарядки и без числа зарядов.
local function PaintCloudSlot(icon)
    if not icon or not icon.painted or not icon.paintSlot then
        return
    end
    if icon.cooldown then
        icon.cooldown:Clear()
        icon.cooldown:Hide()
    end
    if icon.StackCount then
        icon.StackCount:Hide()
    end
    if icon.paintSlot and ActionBar.UpdateTextureDesaturation then
        ActionBar.UpdateTextureDesaturation(icon, icon.paintSlot)
    end
    -- Чужое облако и крупные значки в середине серые, пока открыта панель модификатора.
    if icon.cloudMuted and icon.texture and ActionBar.SetIconGray then
        ActionBar.SetIconGray(icon.texture, true)
    end
end

-- Серый цвет для значка без ячейки: способность области не проходит обычную покраску.
local function ApplyMutedGray(icon)
    if not icon or not icon.painted or not icon.texture or not ActionBar.SetIconGray then
        return
    end
    if icon.cloudMuted then
        ActionBar.SetIconGray(icon.texture, true)
        return
    end
    if icon.isCenter and not icon.paintSlot then
        ActionBar.SetIconGray(icon.texture, false)
    end
end

-- Обходит значки облака и обновляет восстановление.
local function PaintCloudSlots(clouds)
    local function PaintCluster(cluster)
        if not cluster then
            return
        end
        for index = 1, #cluster.icons do
            PaintCloudSlot(cluster.icons[index])
            ApplyMutedGray(cluster.icons[index])
        end
        for index = 1, #cluster.centers do
            PaintCloudSlot(cluster.centers[index])
            ApplyMutedGray(cluster.centers[index])
        end
    end
    PaintCluster(clouds.right)
    PaintCluster(clouds.left)
    if clouds.loneIcons then
        for index = 1, #clouds.loneIcons do
            PaintCloudSlot(clouds.loneIcons[index])
            ApplyMutedGray(clouds.loneIcons[index])
        end
    end
end

-- Повторный вызов в ту же сторону не сбрасывает переезд на тесные места.
local function BeginLayout(cluster, target)
    if not cluster or cluster.layoutTarget == target then
        return
    end
    cluster.layoutTarget = target
    cluster.layoutStartMix = cluster.layoutMix or 0
    cluster.layoutElapsed = 0
    local span = math.abs(target - cluster.layoutStartMix)
    if span < 0.001 then
        cluster.layoutMix = target
        cluster.layoutDuration = 0
        return
    end
    cluster.layoutDuration = (ActionBar.boostLayoutDuration or 0.4) * span
end

-- Доводит переезд соседей к местам вокруг крупного значка.
local function AdvanceLayout(cluster, elapsed)
    if not cluster then
        return
    end
    if not cluster.layoutDuration or cluster.layoutDuration <= 0 or cluster.layoutMix == cluster.layoutTarget then
        cluster.layoutMix = cluster.layoutTarget or cluster.layoutMix or 0
        return
    end
    cluster.layoutElapsed = (cluster.layoutElapsed or 0) + (elapsed or 0)
    local amount = cluster.layoutElapsed / cluster.layoutDuration
    if amount >= 1 then
        cluster.layoutMix = cluster.layoutTarget
        cluster.layoutDuration = 0
        return
    end
    local eased = EaseOutCubic(amount)
    cluster.layoutMix = cluster.layoutStartMix + (cluster.layoutTarget - cluster.layoutStartMix) * eased
end

-- Место и размер покоя умения: без крупного значка и с ним.
local function SpellRest(icon, mix)
    local index = icon.cloudIndex or 1
    local from = ActionBar.boostCloudOffsets and ActionBar.boostCloudOffsets[index]
    local toOffsets = ActionBar.boostCloudOffsetsWithExtra and ActionBar.boostCloudOffsetsWithExtra[index]
    local sizeFrom = (ActionBar.boostCloudSizes and ActionBar.boostCloudSizes[index]) or 32
    local sizeTo = (ActionBar.boostCloudSizesWithExtra and ActionBar.boostCloudSizesWithExtra[index]) or sizeFrom
    if not from then
        return 0, 0, sizeFrom
    end
    if not toOffsets or not mix or mix <= 0 then
        return from.x, from.y, sizeFrom
    end
    if mix >= 1 then
        return toOffsets.x, toOffsets.y, sizeTo
    end
    return Lerp(from.x, toOffsets.x, mix), Lerp(from.y, toOffsets.y, mix), Lerp(sizeFrom, sizeTo, mix)
end

-- Доводит рост или спад одного значка. Повтор в ту же сторону не обнуляет уже прошедший ход.
local function AdvanceBubble(icon, elapsed, show)
    if not icon then
        return
    end
    local target = (show and icon.painted) and 1 or 0
    icon.bubbleTarget = target
    if icon.bubble == nil then
        icon.bubble = 0
    end
    if icon.bubble == target or not elapsed or elapsed <= 0 then
        return
    end
    local duration = ActionBar.boostBubbleDuration or 0.16
    local rate = icon.floatRate or 1
    if rate < 0.05 then
        rate = 1
    end
    duration = duration / rate
    local step = elapsed / duration
    if target > icon.bubble then
        icon.bubble = math.min(target, icon.bubble + step)
    else
        icon.bubble = math.max(target, icon.bubble - step)
    end
end

-- Прячет сдутый значок один раз, чтобы следующий кадр не повторял ту же работу.
local function HidePosedIcon(icon)
    if icon.posedShown ~= false then
        icon:SetAlpha(0)
        icon:Hide()
        icon.posedShown = false
    end
    icon.posedParent = nil
    icon.posedSize = nil
    icon.posedLevel = nil
end

-- Ставит значок на место покоя и покачивает его. Размер и уровень меняются только вместе с ростом.
local function PoseIcon(icon, parent, time, mix)
    if not icon or not parent then
        return
    end
    local life = icon.bubble or 0
    if life <= 0.001 and not icon.painted then
        HidePosedIcon(icon)
        return
    end

    local restX, restY, restSize
    if icon.isCenter then
        restX = icon.centerSide or 0
        restY = icon.centerDrop or 0
        restSize = ActionBar.boostExtraCloudSize or 40
    else
        restX, restY, restSize = SpellRest(icon, mix or 0)
    end

    local scale = BubbleScale(life)
    local size = restSize * scale
    if size < 0.01 then
        size = 0.01
    end

    local floatX, floatY = 0, 0
    if life > 0.001 then
        local speed = icon.floatSpeed or 0.3
        local phase = icon.floatPhase or 0
        local radius = ActionBar.boostFloatRadius or 1.78
        floatX = math.sin(time * speed * pi2 + phase) * radius
        floatY = math.cos(time * speed * 0.85 * pi2 + phase) * radius
    end

    if icon:GetScale() ~= 1 then
        icon:SetScale(1)
    end

    local x = restX + floatX
    local y = restY + floatY
    local moved = icon.posedParent ~= parent
        or math.abs((icon.posedX or 0) - x) > 0.2
        or math.abs((icon.posedY or 0) - y) > 0.2
    if moved then
        icon:ClearAllPoints()
        icon:SetPoint("CENTER", parent, "CENTER", x, y)
        icon.posedParent = parent
        icon.posedX = x
        icon.posedY = y
    end

    if not icon.posedSize or math.abs(icon.posedSize - size) > 0.2 then
        icon:SetSize(size, size)
        if icon.texture then
            icon.texture:SetSize(size, size)
            local crop = 0
            if size > 8 then
                crop = 3 / size
            end
            icon.texture:SetTexCoord(crop, 1 - crop, crop, 1 - crop)
            icon.lastSize = size
        end
        if icon.background then
            icon.background:SetSize(size + 8 * scale, size + 8 * scale)
        end
        icon.posedSize = size
    end

    local shown = life > 0.001
    if icon.posedShown ~= shown then
        if shown then
            icon:SetAlpha(1)
            icon:Show()
        else
            icon:SetAlpha(0)
            icon:Hide()
        end
        icon.posedShown = shown
    end

    local base = parent:GetFrameLevel()
    local level
    if icon.isCenter then
        level = base + 10
    elseif icon.texture and icon.texture.iconGray then
        level = base + 1
    else
        level = base + (icon.cloudIndex or 1) + 1
    end
    if icon.posedLevel ~= level then
        icon:SetFrameLevel(level)
        icon.posedLevel = level
        if icon.StackCount then
            icon.StackCount:SetFrameLevel(level + 2)
        end
    end
end

-- Кадр ещё нужен: значок виден, доигрывает рост или соседи ещё переезжают.
local function ListBusy(list)
    if not list then
        return false
    end
    for index = 1, #list do
        local icon = list[index]
        local life = icon.bubble or 0
        local target = icon.bubbleTarget or 0
        if icon.painted and life > 0.001 then
            return true
        end
        if math.abs(life - target) > 0.001 then
            return true
        end
    end
    return false
end

local function LayoutBusy(cluster)
    if not cluster then
        return false
    end
    if (cluster.layoutDuration or 0) > 0 then
        return true
    end
    return math.abs((cluster.layoutMix or 0) - (cluster.layoutTarget or 0)) > 0.001
end

local function CloudsNeedDriver(clouds)
    if not clouds then
        return false
    end
    if LayoutBusy(clouds.right) or LayoutBusy(clouds.left) then
        return true
    end
    if clouds.right and (ListBusy(clouds.right.icons) or ListBusy(clouds.right.centers)) then
        return true
    end
    if clouds.left and (ListBusy(clouds.left.icons) or ListBusy(clouds.left.centers)) then
        return true
    end
    return ListBusy(clouds.loneIcons)
end

-- Раскладывает умения по первым местам покоя и сажает крупные значки в середину.
local function LayoutCluster(cluster, spec, centerMarks)
    if not cluster then
        return
    end
    centerMarks = centerMarks or {}
    local shownCenters = 0
    for index = 1, #cluster.centers do
        local mark = centerMarks[index]
        if mark and mark.texture then
            shownCenters = shownCenters + 1
        end
    end
    local placed = 0
    local any = shownCenters > 0
    for index = 1, #cluster.centers do
        local mark = centerMarks[index]
        local icon = cluster.centers[index]
        -- Та же высота, что у кольца умений: покой уже опущен от лицевых кнопок до рычага.
        icon.centerDrop = ActionBar.boostExtraRestY or 0
        if mark and mark.texture then
            placed = placed + 1
            if shownCenters >= 2 then
                icon.centerSide = placed == 1 and -24 or 24
            else
                icon.centerSide = 0
            end
            AssignIcon(icon, mark.texture, mark.slotID)
        else
            icon.centerSide = 0
            AssignIcon(icon, nil)
        end
    end
    for index = 1, #cluster.icons do
        local icon = cluster.icons[index]
        local key = spec and spec.keys[index]
        local btn = key and CloudSpellButton(key, spec.modifier)
        local slotID = btn and btn.slotID
        local texture = slotID and SlotTexture(slotID)
        AssignIcon(icon, texture, slotID)
        if icon.painted then
            any = true
        end
    end
    cluster.hasIcons = any
    cluster.cloudModifier = spec and spec.modifier or nil
    BeginLayout(cluster, shownCenters > 0 and 1 or 0)
end

-- Гасит все значки сразу, без вспышки, когда панель растёт из ничего.
local function SnapBubbles(clouds)
    local function SnapList(list)
        if not list then
            return
        end
        for index = 1, #list do
            local icon = list[index]
            icon.bubble = 0
            icon.bubbleTarget = 0
            HidePosedIcon(icon)
        end
    end
    if clouds.right then
        SnapList(clouds.right.icons)
        SnapList(clouds.right.centers)
        clouds.right:Hide()
    end
    if clouds.left then
        SnapList(clouds.left.icons)
        SnapList(clouds.left.centers)
        clouds.left:Hide()
    end
    SnapList(clouds.loneIcons)
    clouds.bubbleShow = false
    if clouds.shadowVisible then
        clouds.shadowVisible = false
        if ActionBar.UpdateActionButtonShadowsIfNeeded then
            ActionBar.UpdateActionButtonShadowsIfNeeded()
        end
    end
    clouds.shadowVisible = false
    if clouds.driver then
        clouds.driver:Hide()
    end
end

-- Покачивание, рост каждого значка и переезд соседей. Кадр жив, пока значок ещё виден.
function ActionBar.StepClouds(elapsed)
    local frame = ActionBar.GetFrame()
    local clouds = frame and frame.spellClouds
    if not clouds then
        return
    end
    elapsed = elapsed or 0
    clouds.time = (clouds.time or 0) + elapsed

    -- Облако видно вместе с панелью, а не вместо неё.
    local function ClusterStays()
        return true
    end

    local shadowVisible = false
    local function StepList(list, parent, mix, show)
        if not list or not parent then
            return false
        end
        local alive = false
        for index = 1, #list do
            local icon = list[index]
            AdvanceBubble(icon, elapsed, show)
            PoseIcon(icon, parent, clouds.time, mix)
            local life = icon.bubble or 0
            if icon.painted and life > 0.05 then
                shadowVisible = true
            end
            if life > 0.001 or math.abs(life - (icon.bubbleTarget or 0)) > 0.001 then
                alive = true
            end
        end
        return alive
    end

    AdvanceLayout(clouds.right, elapsed)
    AdvanceLayout(clouds.left, elapsed)

    local function StepCluster(cluster)
        if not cluster then
            return
        end
        local mix = cluster.layoutMix or 0
        local show = ClusterStays(cluster) and true or false
        local alive = StepList(cluster.icons, cluster, mix, show)
        if StepList(cluster.centers, cluster, mix, show) then
            alive = true
        end
        if alive then
            cluster:Show()
        else
            cluster:Hide()
        end
    end

    StepCluster(clouds.right)
    StepCluster(clouds.left)
    StepList(clouds.loneIcons, frame, 0, clouds.bubbleShow and true or false)

    if clouds.driver and not CloudsNeedDriver(clouds) then
        clouds.driver:Hide()
    end
    if clouds.shadowVisible ~= shadowVisible then
        clouds.shadowVisible = shadowVisible
        if ActionBar.UpdateActionButtonShadowsIfNeeded then
            ActionBar.UpdateActionButtonShadowsIfNeeded()
        end
    end
end

-- Собирает центр: дополнительная кнопка и способность области.
local function CenterMarks()
    local marks = {}
    if ActionBar.GetExtraActionSlotID then
        local slotID = ActionBar.GetExtraActionSlotID()
        local extra = SlotTexture(slotID)
        if extra then
            marks[#marks + 1] = { texture = extra, slotID = slotID }
        end
    end
    local zone = ZoneAbilityTexture()
    if zone then
        marks[#marks + 1] = { texture = zone }
    end
    return marks
end

-- Два крупных значка рядом, один — в середине панели. Покачивание то же, что у центра облака.
local function LayoutLone(clouds, marks)
    local icons = clouds.loneIcons or {}
    local shown = #marks
    for index = 1, #icons do
        local icon = icons[index]
        local mark = marks[index]
        icon.centerDrop = 0
        if mark and mark.texture then
            if shown >= 2 then
                icon.centerSide = index == 1 and -28 or 28
            else
                icon.centerSide = 0
            end
            AssignIcon(icon, mark.texture, mark.slotID)
        else
            icon.centerSide = 0
            AssignIcon(icon, nil)
        end
    end
end

-- Обновляет состав облаков и их надувание.
function ActionBar.UpdateClouds()
    local frame = ActionBar.GetFrame()
    if not frame or not frame.PADCenter then
        return
    end
    local clouds = EnsureClouds(frame)
    local specs = CloudSpecs()
    local centers = CenterMarks()
    local rightSpec, leftSpec
    for index = 1, #specs do
        if specs[index].stick == "PADRSTICK" then
            rightSpec = specs[index]
        elseif specs[index].stick == "PADLSTICK" then
            leftSpec = specs[index]
        end
    end

    local hostCenters = centers
    if not rightSpec and not leftSpec then
        LayoutCluster(clouds.right, nil, {})
        LayoutCluster(clouds.left, nil, {})
        LayoutLone(clouds, centers)
    else
        if clouds.loneIcons then
            for index = 1, #clouds.loneIcons do
                AssignIcon(clouds.loneIcons[index], nil)
            end
        end
        if rightSpec then
            LayoutCluster(clouds.right, rightSpec, hostCenters)
            LayoutCluster(clouds.left, leftSpec, {})
        else
            LayoutCluster(clouds.right, nil, {})
            LayoutCluster(clouds.left, leftSpec, hostCenters)
        end
    end

    local held = HeldModifier()
    clouds.revealOwns = false
    clouds.heldModifier = held
    clouds.bubbleShow = true

    -- Сразу полный размер: иначе значок ждёт следующий кадр и при появлении панели остаётся пустым.
    local function OpenPainted(list)
        if not list then
            return
        end
        for index = 1, #list do
            local icon = list[index]
            if icon.painted then
                icon.bubble = 1
                icon.bubbleTarget = 1
            end
        end
    end
    if clouds.right then
        OpenPainted(clouds.right.icons)
        OpenPainted(clouds.right.centers)
    end
    if clouds.left then
        OpenPainted(clouds.left.icons)
        OpenPainted(clouds.left.centers)
    end
    OpenPainted(clouds.loneIcons)

    local function MarkForeignCloud(cluster)
        if not cluster then
            return
        end
        local muted = held and cluster.cloudModifier and cluster.cloudModifier ~= held
        local muteCenters = held and true or false
        for index = 1, #cluster.icons do
            cluster.icons[index].cloudMuted = muted and true or false
        end
        for index = 1, #cluster.centers do
            cluster.centers[index].cloudMuted = muteCenters and true or false
        end
    end
    MarkForeignCloud(clouds.right)
    MarkForeignCloud(clouds.left)
    if clouds.loneIcons then
        local muteLone = held and true or false
        for index = 1, #clouds.loneIcons do
            clouds.loneIcons[index].cloudMuted = muteLone and true or false
        end
    end

    PaintCloudSlots(clouds)
    if clouds.driver then
        clouds.driver:Show()
    end
    ActionBar.StepClouds(0)
end

-- Облако ещё видно и может держать тень правой группы.
function ActionBar.HasVisibleClouds()
    local frame = ActionBar.GetFrame()
    local clouds = frame and frame.spellClouds
    if not clouds then
        return false
    end
    local function IconVisible(icon)
        return icon and icon.painted and icon:IsShown() and (icon.bubble or 0) > 0.05
    end
    local function ListVisible(list)
        if not list then
            return false
        end
        for index = 1, #list do
            if IconVisible(list[index]) then
                return true
            end
        end
        return false
    end
    if clouds.right and (ListVisible(clouds.right.icons) or ListVisible(clouds.right.centers)) then
        return true
    end
    if clouds.left and (ListVisible(clouds.left.icons) or ListVisible(clouds.left.centers)) then
        return true
    end
    return ListVisible(clouds.loneIcons)
end

-- Обновляет рисунок уже стоящего значка, не трогая его место.
local function RefreshCloudIconTexture(icon)
    if not icon or not icon.painted or not icon.paintSlot or not icon.texture then
        return
    end
    local texture = SlotTexture(icon.paintSlot)
    if not texture or (ActionBar.IsSecretValue and ActionBar.IsSecretValue(texture)) then
        return
    end
    local current = icon.texture:GetTexture()
    if ActionBar.IsSecretValue and ActionBar.IsSecretValue(current) then
        return
    end
    if current ~= texture then
        icon.texture:SetTexture(texture)
        icon.posedSize = nil
    end
end

-- Перекрашивает уже показанные значки. Состав облака и места при этом не собираются заново.
function ActionBar.RecolorClouds()
    local frame = ActionBar.GetFrame()
    local clouds = frame and frame.spellClouds
    if not clouds then
        return
    end
    local function RecolorList(list)
        if not list then
            return
        end
        for index = 1, #list do
            local icon = list[index]
            RefreshCloudIconTexture(icon)
            PaintCloudSlot(icon)
            ApplyMutedGray(icon)
        end
    end
    if clouds.right then
        RecolorList(clouds.right.icons)
        RecolorList(clouds.right.centers)
    end
    if clouds.left then
        RecolorList(clouds.left.icons)
        RecolorList(clouds.left.centers)
    end
    RecolorList(clouds.loneIcons)
end

-- Старые вызовы облака усилений идут в новый показ.
ActionBar.UpdateBoosts = ActionBar.UpdateClouds
ActionBar.HasVisibleBoosts = ActionBar.HasVisibleClouds
ActionBar.CreateBoosts = function(parent)
    if parent then
        EnsureClouds(parent)
    end
end
ActionBar.SetBoostsExpanded = function()
    ActionBar.UpdateClouds()
end

-- Запускает покачивание уже после того, как панель показана. Показ до этого кадр не будит.
function ActionBar.WakeClouds()
    local frame = ActionBar.GetFrame()
    local clouds = frame and frame.spellClouds
    if not clouds or not clouds.driver or not frame:IsShown() then
        return
    end
    clouds.driver:Hide()
    clouds.driver:Show()
end
ActionBar.QuietCollapseBoosts = function()
    local frame = ActionBar.GetFrame()
    local clouds = frame and frame.spellClouds
    if not clouds then
        return
    end
    SnapBubbles(clouds)
end

-- Модификатор сидит на правом рычаге: лицевые кнопки не переворачиваются.
function ActionBar.ModifierSitsOnRightStick(modifier)
    return PhysicalKey(modifier) == "PADRSTICK"
end
