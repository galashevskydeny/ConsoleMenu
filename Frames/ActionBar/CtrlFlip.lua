-- Переворот кнопок при удержании Ctrl: та же кнопка садится умением другой панели.

local ConsoleMenu = _G.ConsoleMenu
local ActionBar = ConsoleMenu.ActionBar

-- Переворот панели Ctrl: та же кнопка подбрасывается монетой и садится умением другой панели.
-- Наклон у каждой свой, чтобы ребро не вставало одинаковой щелью.
local ctrlSpinTilts = {
    PAD3 = 0.74,
    PAD4 = -0.62,
    PAD2 = 0.9,
    PADDUP = 0.72,
    PADDRIGHT = -0.86,
    PADDLEFT = -1.05,
    PADLSTICK = 0.58,
    PADDDOWN = -0.58,
}

-- Разброс скорости, как у облака: часть значков садится раньше остальных.
local ctrlSpinRates = {
    PAD3 = 0.72,
    PAD4 = 1.22,
    PAD2 = 0.86,
    PADDUP = 1.12,
    PADDRIGHT = 0.78,
    PADDLEFT = 0.96,
    PADLSTICK = 1.08,
    PADDDOWN = 0.9,
}

-- Место кнопки на панели. Соседи с одной точкой, например рычаг и низ креста, совпадают.
local function PositionToken(mainKey)
    local position = mainKey and ActionBar.buttonPositions[mainKey]
    if not position then
        return nil
    end
    return position[1]
        .. ":" .. position[2]
        .. ":" .. position[3]
        .. ":" .. tostring(position[4])
        .. ":" .. tostring(position[5])
end

-- Снизу виден левый рычаг, отдельная нижняя кнопка креста ему уступает.
local function HostRank(mainKey)
    if mainKey == "PADLSTICK" then
        return 2
    end
    if mainKey == "PADDDOWN" then
        return 0
    end
    return 1
end

-- Рисунок, который сейчас виден на кнопке.
local function ReadButtonTexture(texture)
    if not texture or not texture.GetTexture then
        return nil
    end

    local ok, current = pcall(texture.GetTexture, texture)
    if not ok or not current or ActionBar.IsSecretValue(current) then
        return nil
    end
    return current
end

-- Умение Ctrl на том же месте, что и кнопка. Своя клавиша важнее соседней.
local function PickCtrlButton(list, hostKey)
    local fallback
    for index = 1, #list do
        local candidate = list[index]
        if candidate.mainKey == hostKey then
            return candidate
        end
        if not fallback then
            fallback = candidate
        end
    end
    return fallback
end

-- Пары: кнопка текущей страницы и заполненное умение Ctrl на том же месте.
local function CollectCtrlPairs(frame)
    local ctrlByToken = {}
    local entries = {}
    local tokens = {}
    local rateFloor = 1
    if not frame or not frame.actionButtons then
        return entries, tokens, rateFloor
    end

    for slotID, btn in pairs(frame.actionButtons) do
        if btn.modifierKey == "CTRL"
            and not ActionBar.ignoredSlot[slotID]
            and not ActionBar.slot12Slots[slotID]
            and not ActionBar.IsBoostSlot(slotID)
            and ActionBar.SlotHasAction(slotID) == true
        then
            local token = PositionToken(btn.mainKey)
            if token then
                local list = ctrlByToken[token]
                if not list then
                    list = {}
                    ctrlByToken[token] = list
                end
                list[#list + 1] = btn
            end
        end
    end

    local bestHost = {}
    for slotID, btn in pairs(frame.actionButtons) do
        if not btn.modifierKey
            and ActionBar.IsSlotOnActivePage(slotID)
            and not ActionBar.ignoredSlot[slotID]
            and not ActionBar.slot12Slots[slotID]
            and not ActionBar.IsBoostSlot(slotID)
            and not ActionBar.IsExtraActionSlot(slotID)
        then
            local token = PositionToken(btn.mainKey)
            if token and ctrlByToken[token] then
                local current = bestHost[token]
                if not current or HostRank(btn.mainKey) > HostRank(current.mainKey) then
                    bestHost[token] = btn
                end
            end
        end
    end

    for token, host in pairs(bestHost) do
        local alt = PickCtrlButton(ctrlByToken[token], host.mainKey)
        if alt then
            local rate = ctrlSpinRates[host.mainKey] or 1
            if rate < rateFloor then
                rateFloor = rate
            end
            entries[#entries + 1] = {
                host = host,
                altSlot = alt.slotID,
                tilt = ctrlSpinTilts[host.mainKey] or 0.7,
                rate = rate,
            }
            tokens[token] = true
        end
    end

    if rateFloor < 0.05 then
        rateFloor = 1
    end
    return entries, tokens, rateFloor
end

-- Правый рычаг забирает крестовину обратно в облако усилений.
local function ShiftTakesHost(host)
    if not host or IsControlKeyDown() or not IsShiftKeyDown() then
        return false
    end
    return ActionBar.IsBoostHostKey and ActionBar.IsBoostHostKey(host.mainKey) or false
end

-- Лицевая сторона: своё умение, а если кнопка уже показывает усиление — оно и остаётся до оборота.
local function PrepareCtrlFront(host, target)
    if target == 0 then
        local textureFileID = ActionBar.GetSlotTexture(host.slotID)
        if textureFileID and not ActionBar.IsSecretValue(textureFileID) then
            host.boostHostSaved = true
            host.boostHostTexture = textureFileID
        end
        return
    end

    if host.boostShowingAlt and host.boostFlipSlot and ActionBar.IsBoostSlot(host.boostFlipSlot) then
        local current = ReadButtonTexture(host.texture)
        if current then
            host.boostHostSaved = true
            host.boostHostTexture = current
            return
        end
    end

    if host.boostHostSaved then
        return
    end

    host.boostHostSaved = true
    local textureFileID = ActionBar.GetSlotTexture(host.slotID)
    if textureFileID and not ActionBar.IsSecretValue(textureFileID) then
        host.boostHostTexture = textureFileID
        return
    end
    host.boostHostTexture = ReadButtonTexture(host.texture)
end

-- Запоминает лицевую сторону один раз на направление подброса.
-- Обратный ход начинается с уже показанного оборота, а не с общего, более раннего.
local function BindCtrlMotion(host, flip)
    if host.ctrlMotionTarget == flip.target and host.ctrlStartProgress ~= nil then
        return
    end
    PrepareCtrlFront(host, flip.target)
    host.ctrlMotionTarget = flip.target
    local from = host.ctrlShownProgress
    if from == nil then
        from = flip.progress or 0
    end
    host.ctrlStartProgress = from
    host.ctrlFaceSettled = nil
end

-- Ход одной монеты: быстрые доходят до оборота раньше общего конца.
local function CtrlEntryProgress(flip, entry)
    local target = flip.target or 0
    if not flip.duration or flip.duration <= 0 or flip.progress == target then
        return target
    end

    local rate = entry.rate or 1
    local slowest = flip.rateFloor or 1
    if slowest < 0.05 then
        slowest = 1
    end

    local amount = (flip.elapsed or 0) / flip.duration
    if amount < 0 then
        amount = 0
    elseif amount > 1 then
        amount = 1
    end

    local travelled = amount * (rate / slowest)
    if travelled > 1 then
        travelled = 1
    end

    local startProgress = entry.host.ctrlStartProgress
    if startProgress == nil then
        startProgress = flip.startProgress or 0
    end
    return startProgress + (target - startProgress) * ActionBar.Coin.EaseOutCubic(travelled)
end

-- Возвращает кнопку к своему умению после переворота.
local function ReleaseCtrlHost(host)
    if not host then
        return
    end

    local tossed = host.coinActive or host.boostFlipLock or host.ctrlFlipOwned
    host.ctrlFlipOwned = nil
    if host.cooldown then
        host.cooldown:SetAlpha(1)
    end
    if tossed then
        host.coinActive = true
        ActionBar.Coin.ResetHost(host)
    else
        host.ctrlFaceSettled = nil
        host.ctrlMotionTarget = nil
        host.ctrlStartProgress = nil
        host.ctrlShownProgress = nil
    end
    if host.Glow and ActionBar.UpdateGlow then
        ActionBar.UpdateGlow(host.slotID)
    end
end

-- Снимает переворот со всех кнопок, которые он держал.
local function CloseCtrlFlip(flip)
    local frame = ActionBar.GetFrame()
    if frame and frame.actionButtons then
        for _, btn in pairs(frame.actionButtons) do
            if btn.ctrlFlipOwned or btn.ctrlMotionTarget ~= nil then
                ReleaseCtrlHost(btn)
            end
        end
    end
    flip.entries = nil
    flip.hostSlots = nil
    flip.ownedTokens = nil
end

-- Один кадр подброса: кнопка остаётся на месте и меняет рисунок на ребре.
local function PoseCtrlHost(flip, entry)
    local host = entry.host
    if not host then
        return
    end

    -- Крестовину отдаём облаку один раз, иначе каждый кадр стирает её подброс.
    if flip.target == 0 and ShiftTakesHost(host) then
        if host.ctrlFlipOwned or host.ctrlMotionTarget ~= nil then
            ReleaseCtrlHost(host)
        end
        return false
    end

    BindCtrlMotion(host, flip)
    local shown = CtrlEntryProgress(flip, entry)
    host.ctrlShownProgress = shown
    local amount = ActionBar.Coin.TossAmount(shown)
    if amount < 1 then
        ActionBar.Coin.HoldCooldown(host)
    end
    host.ctrlFlipOwned = true
    host.coinActive = true
    host.boostFlipLock = true
    host.boostFlipSlot = entry.altSlot
    if not host.coinBaseLevel then
        host.coinBaseLevel = host:GetFrameLevel()
    end
    host:SetFrameLevel(host.coinBaseLevel + 20)
    ActionBar.Coin.RaiseLayers(host)
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
    if host.background then
        host.background:Show()
    end
    ActionBar.Coin.HideTwins(host)

    local showAlt = ActionBar.Coin.ApplyToss(host.texture, host.background, host.mask, host, ActionBar.buttonSize, amount, entry.tilt)
    if not showAlt and host.boostHostTexture then
        local current = ReadButtonTexture(host.texture)
        if current ~= host.boostHostTexture then
            host.boostShowingAlt = true
        end
    end
    ActionBar.Coin.ApplyFace(host, entry.altSlot, showAlt)
    if amount < 1 then
        host.ctrlFaceSettled = nil
    end
    if not host.ctrlFaceSettled and ActionBar.UpdateTextureDesaturation then
        ActionBar.UpdateTextureDesaturation(host, showAlt and entry.altSlot or host.slotID)
    end
    local timerFace = showAlt and true or false
    if (showAlt or amount >= 1) and (not host.coinTimerReady or host.coinTimerFace ~= timerFace) then
        host.coinTimerReady = true
        host.coinTimerFace = timerFace
        if amount < 1 and ActionBar.SyncButtonCooldown then
            ActionBar.SyncButtonCooldown(host, true)
        end
    end

    ActionBar.Coin.SyncCount(host, showAlt, amount)

    if amount < 1 then
        host.ctrlFaceSettled = nil
        if host.Glow then
            host.Glow:Hide()
        end
        return true
    end

    if not host.ctrlFaceSettled then
        host.coinInAir = nil
        host.ctrlFaceSettled = true
        ActionBar.Coin.ShowCount(host)
        if ActionBar.SyncButtonCooldown then
            ActionBar.SyncButtonCooldown(host, true)
        end
        if ActionBar.UpdateGlow then
            ActionBar.UpdateGlow(host.slotID)
        end
        if ActionBar.UpdateTextureDesaturation then
            ActionBar.UpdateTextureDesaturation(host, entry.altSlot)
        end
        if ActionBar.RepaintButtonColors then
            ActionBar.RepaintButtonColors()
        end
    end
    return true
end

-- Обновляет набор монет и рисует текущий кадр.
local function ApplyCtrlFaces(flip)
    local frame = ActionBar.GetFrame()
    local entries, tokens, rateFloor = CollectCtrlPairs(frame)
    local keep = {}
    for index = 1, #entries do
        keep[entries[index].host] = true
    end

    if flip.entries then
        for index = 1, #flip.entries do
            local previous = flip.entries[index].host
            if previous and not keep[previous] then
                ReleaseCtrlHost(previous)
            end
        end
    end

    flip.entries = entries
    flip.ownedTokens = tokens
    flip.rateFloor = rateFloor
    flip.hostSlots = {}
    for index = 1, #entries do
        local entry = entries[index]
        if PoseCtrlHost(flip, entry) then
            flip.hostSlots[entry.host.slotID] = true
        end
    end
end

-- Общий ход подброса без скачка при смене направления.
local function AdvanceCtrlProgress(flip, elapsed)
    if not flip.duration or flip.duration <= 0 or flip.progress == flip.target then
        flip.progress = flip.target
        return true
    end

    flip.elapsed = (flip.elapsed or 0) + (elapsed or 0)
    local amount = flip.elapsed / flip.duration
    if amount >= 1 then
        flip.progress = flip.target
        flip.duration = 0
        return true
    end

    flip.progress = flip.startProgress + (flip.target - flip.startProgress) * ActionBar.Coin.EaseOutCubic(amount)
    return false
end

-- Кадр переворота. Пока он скрыт, анимация стоит.
local function EnsureCtrlFlip(frame)
    if frame.ctrlFlip then
        return frame.ctrlFlip
    end

    local driver = CreateFrame("Frame", nil, frame)
    driver:Hide()
    local flip = {
        progress = 0,
        target = 0,
        startProgress = 0,
        elapsed = 0,
        duration = 0,
        driver = driver,
    }
    driver:SetScript("OnUpdate", function(_, elapsed)
        ActionBar.OnCtrlFlipUpdate(elapsed)
    end)
    frame.ctrlFlip = flip
    return flip
end

-- Шаг переворота всех кнопок панели Ctrl.
function ActionBar.OnCtrlFlipUpdate(elapsed)
    local frame = ActionBar.GetFrame()
    local flip = frame and frame.ctrlFlip
    if not flip or flip.ticking then
        return
    end

    flip.ticking = true
    local settled = AdvanceCtrlProgress(flip, elapsed or 0)
    ApplyCtrlFaces(flip)

    local empty = not flip.entries or #flip.entries == 0
    if empty then
        settled = true
        flip.progress = flip.target
        flip.duration = 0
    end

    if ActionBar.UpdateActionButtonShadowsIfNeeded then
        ActionBar.UpdateActionButtonShadowsIfNeeded()
    end

    if settled then
        flip.duration = 0
        if flip.driver then
            flip.driver:Hide()
        end
        if flip.target == 0 then
            CloseCtrlFlip(flip)
            flip.progress = 0
            flip.ticking = false
            if ActionBar.UpdateModifierState then
                ActionBar.UpdateModifierState()
            end
            return
        end
    end

    flip.ticking = false
end

-- Запускает подброс к цели. Короткий остаток не растягивается на полную длительность.
local function BeginCtrlMotion(flip, target)
    flip.startProgress = flip.progress or 0
    local span = math.abs(target - flip.startProgress)
    if flip.entries then
        for index = 1, #flip.entries do
            local host = flip.entries[index].host
            local shown = host and host.ctrlShownProgress
            if shown then
                local gap = math.abs(target - shown)
                if gap > span then
                    span = gap
                end
            end
        end
    end
    flip.target = target
    flip.elapsed = 0
    if span < 0.001 then
        flip.progress = target
        flip.duration = 0
        ActionBar.OnCtrlFlipUpdate(0)
        return
    end

    local _, _, rateFloor = CollectCtrlPairs(ActionBar.GetFrame())
    if not rateFloor or rateFloor < 0.05 then
        rateFloor = 1
    end
    flip.rateFloor = rateFloor
    local full = target == 1 and (ActionBar.boostExpandDuration or 0.48) or (ActionBar.boostCollapseDuration or 0.48)
    flip.duration = full * span / rateFloor
    flip.driver:Show()
    ActionBar.OnCtrlFlipUpdate(0)
end

-- В исследовании панель гаснет сразу, поэтому обратный подброс не показывается.
local function ExploringHidesCtrlFlip()
    if IsControlKeyDown() then
        return false
    end
    if not ConsoleMenu.GetPlayerContext or ConsoleMenu:GetPlayerContext() ~= "exploring" then
        return false
    end
    return true
end

-- Панель Ctrl ещё держит кнопки, пока монеты не вернулись.
function ActionBar.CtrlFlipOwnsHosts()
    local frame = ActionBar.GetFrame()
    local flip = frame and frame.ctrlFlip
    if not flip then
        return false
    end
    return (flip.target or 0) == 1 or (flip.progress or 0) > 0.001
end

-- Эта кнопка сама показывает умение Ctrl.
function ActionBar.IsActiveCtrlHostSlot(slotID)
    local frame = ActionBar.GetFrame()
    local flip = frame and frame.ctrlFlip
    if not flip or not flip.hostSlots or not ActionBar.CtrlFlipOwnsHosts() then
        return false
    end
    return flip.hostSlots[slotID] == true
end

-- Вторая копия на том же месте скрыта: рисунок уже на переворачиваемой кнопке.
function ActionBar.CtrlFlipHidesSlot(slotID)
    local frame = ActionBar.GetFrame()
    local flip = frame and frame.ctrlFlip
    local btn = ActionBar.GetButton(slotID)
    if not flip or not btn or btn.modifierKey ~= "CTRL" or not ActionBar.CtrlFlipOwnsHosts() then
        return false
    end
    if ActionBar.slot12Slots[slotID] then
        return false
    end
    local token = PositionToken(btn.mainKey)
    return token and flip.ownedTokens and flip.ownedTokens[token] == true or false
end

-- Включает переворот при удержании Ctrl и сажает монеты обратно, когда клавишу отпускают.
function ActionBar.SetCtrlFlip(active)
    local frame = ActionBar.GetFrame()
    if not frame then
        return
    end

    local flip = EnsureCtrlFlip(frame)
    if not active then
        if ExploringHidesCtrlFlip() then
            if (flip.progress or 0) > 0.001 or (flip.target or 0) ~= 0 or flip.hostSlots then
                flip.target = 0
                flip.progress = 0
                flip.duration = 0
                flip.elapsed = 0
                if flip.driver then
                    flip.driver:Hide()
                end
                CloseCtrlFlip(flip)
            end
            return
        end
        if (flip.target or 0) == 0 and (flip.progress or 0) <= 0.001 and (flip.duration or 0) <= 0 then
            return
        end
        -- Повторное отпускание не перезапускает уже идущий возврат.
        if (flip.target or 0) == 0 and (flip.duration or 0) > 0 then
            return
        end
        BeginCtrlMotion(flip, 0)
        return
    end

    if flip.target == 1 and (flip.duration or 0) <= 0 and (flip.progress or 0) >= 0.999 then
        ApplyCtrlFaces(flip)
        return
    end

    if flip.target == 1 and (flip.duration or 0) > 0 then
        return
    end

    BeginCtrlMotion(flip, 1)
end
