-- Раскладка кнопок: положения по клавишам, видимость страницы и тени групп.

local ConsoleMenu = _G.ConsoleMenu
local ActionBar = ConsoleMenu.ActionBar

-- Ячейка относится к текущей странице основной панели.
local function IsSlotOnActiveActionBarPage(slotID)
    return ActionBar.IsSlotOnActivePage(slotID)
end

-- Нужно ли показывать кнопку при текущей дополнительной клавише.
local function IsActionButtonVisible(slotID, btn, activeModifier)
    if ActionBar.IsBoostSlot(slotID) then
        return false
    end

    if ActionBar.IsExtraActionSlot(slotID) then
        return false
    end

    -- Вне боя без удержания клавиш обычные кнопки скрыты.
    if ConsoleMenu.GetPlayerContext and ConsoleMenu:GetPlayerContext() == "exploring" and not activeModifier then
        return false
    end

    if ActionBar.ignoredSlot[slotID] or not ActionBar.buttonPositions[btn.mainKey] then
        return false
    end

    -- Подсказка тачпада (слот 12): только при наличии действия и названия
    if ActionBar.slot12Slots[slotID] then
        if not C_ActionBar.HasAction(slotID) then
            return false
        end
        local actionType, id, subType = GetActionInfo(slotID)
        if not ConsoleMenu:GetSlotTitle(actionType, id, subType, slotID) then
            return false
        end
    end

    -- Кнопки основной панели остаются на экране: переворот и серый цвет делает сама кнопка.
    -- Вне боя при зажатой клавише берём боевую страницу, третья страница этих кнопок не содержит.
    if slotID >= 1 and slotID <= 24 then
        if btn.modifierKey then
            return false
        end
        if activeModifier and ConsoleMenu.GetPlayerContext and ConsoleMenu:GetPlayerContext() == "exploring" then
            return ActionBar.IsSlotOnCombatPage(slotID)
        end
        return IsSlotOnActiveActionBarPage(slotID)
    end

    -- Умение дополнительной панели рисует перевёрнутая кнопка, вторая копия не нужна.
    return false
end

-- Текущая удерживаемая дополнительная клавиша.
-- Ctrl важнее Shift: вместе они оставляют переворот панели, а не облако усилений.
local function GetActiveModifier()
    if not IsModifierKeyDown() then
        return nil
    end
    if IsControlKeyDown() then
        return "CTRL"
    end
    if IsShiftKeyDown() then
        return "SHIFT"
    end
    if IsAltKeyDown() then
        return "ALT"
    end
    return nil
end

-- Кнопка сейчас занимает место на панели. Скрытая страница и чужой модификатор в сдвиг не входят.
-- Островок тачпада в сдвиге не участвует, поэтому его название здесь не спрашиваем.
function ActionBar.IsShiftButtonVisible(btn)
    if not btn or not btn.slotID then
        return false
    end
    if ActionBar.slot12Slots and ActionBar.slot12Slots[btn.slotID] then
        return false
    end
    local activeModifier = GetActiveModifier()
    if IsActionButtonVisible(btn.slotID, btn, activeModifier) then
        return true
    end
    -- В исследовании обычные кнопки скрыты, но переворачивающаяся кнопка крестовины остаётся.
    return ActionBar.IsActiveBoostHostSlot and ActionBar.IsActiveBoostHostSlot(btn.slotID)
end

-- Проявление тени задаётся ниже: при росте панели она уже нужна здесь.
local FadeRevealShadow

-- Обычный размер ареола. После исчезновения панели его нужно вернуть, иначе тень остаётся точкой.
local function RestoreGroupShadowSize(shadow)
    if not shadow then
        return
    end
    local home = ActionBar.shadowSize
    if not home or home < 1 then
        return
    end
    if shadow.lastSize == home then
        return
    end
    shadow:SetSize(home, home)
    shadow.lastSize = home
end

-- Включает ареол группы один раз: повторный вызов не перезапускает проявление.
local function SetGroupShadowShown(shadow, shown)
    if not shadow then
        return
    end
    local frame = ActionBar.GetFrame()
    local reveal = frame and frame.spellReveal
    if reveal and reveal.owns then
        local scale = frame.spellRevealScale or 0
        FadeRevealShadow(shadow, scale)
        shadow.groupShown = scale > 0.001
        return
    end
    if shadow.groupShown == shown then
        return
    end
    shadow.groupShown = shown
    if shown then
        RestoreGroupShadowSize(shadow)
        ConsoleMenu:AnimatedShow(shadow)
    else
        ConsoleMenu:AnimatedHide(shadow)
    end
end

-- Показ и скрытие теней левой и правой групп кнопок.
local function UpdateActionButtonShadows()
    local frame = ActionBar.GetFrame()
    if not frame then
        return
    end

    local activeModifier = GetActiveModifier()

    local PADcount = 0
    local PADDcount = 0

    for slotID, btn in pairs(frame.actionButtons) do
        local position = ActionBar.buttonPositions[btn.mainKey]
        local shownSlot = slotID
        if btn.boostShowingAlt and btn.boostFlipSlot then
            shownSlot = btn.boostFlipSlot
        end
        if position and C_ActionBar.HasAction(shownSlot) and IsActionButtonVisible(slotID, btn, activeModifier) then
            if position[2] == "right" then
                PADcount = PADcount + 1
            elseif position[2] == "left" then
                PADDcount = PADDcount + 1
            end
        end
    end

    local cloudVisible = ActionBar.HasVisibleBoosts and ActionBar.HasVisibleBoosts()
    SetGroupShadowShown(frame.PADshadow, PADcount > 0 or cloudVisible)
    SetGroupShadowShown(frame.PADDshadow, PADDcount > 0)
    frame.shadowCloudVisible = cloudVisible and true or false
    ActionBar.shadowsDirty = nil
end

-- Пересчитывает тени, только если сменилась видимость облака или сторона монеты.
local function UpdateActionButtonShadowsIfNeeded()
    local frame = ActionBar.GetFrame()
    if not frame then
        return
    end

    local cloudVisible = ActionBar.HasVisibleBoosts and ActionBar.HasVisibleBoosts() or false
    if not ActionBar.shadowsDirty and frame.shadowCloudVisible == cloudVisible then
        return
    end

    UpdateActionButtonShadows()
end

-- Ставит кнопку на место раскладки и оставляет уже набранный сдвиг к тёмной противоположной.
-- Пока кнопка уменьшена, клиент сжимает и отступ от середины группы, поэтому отступ делится на размер.
local function PlaceButton(btn, position, anchor)
    local shiftX, shiftY = 0, 0
    if ActionBar.ButtonGlowShift then
        shiftX, shiftY = ActionBar.ButtonGlowShift(btn)
    end
    local x = position[4] + shiftX
    local y = position[5] + shiftY
    local scale = btn:GetScale() or 1
    if scale < 0.999 then
        if scale < 0.001 then
            scale = 0.001
        end
        x = x / scale
        y = y / scale
    end
    btn:ClearAllPoints()
    btn:SetPoint(position[1], anchor, position[3], x, y)
end

-- Привязка кнопок к положениям по назначению клавиш.
local function UpdateButtonPositions(slotID)
    local frame = ActionBar.GetFrame()
    if not frame then
        return
    end

    -- Обновление позиции конкретной кнопки (если передан slotID)
    if slotID then
        local btn = frame.actionButtons[slotID]
        if not btn then return end
        
        local command = ConsoleMenu:GetBindingCommandBySlotID(slotID)
        -- Раскладка панели всегда по клавишам контроллера, даже без подключённого геймпада.
        local binding = ConsoleMenu:GetCommandBinding(command, true)
        btn.binding = binding

        local mainKey, modifierKey = ConsoleMenu:ParseBindingKey(binding)
        btn.mainKey = mainKey
        btn.modifierKey = modifierKey

        local position = ActionBar.buttonPositions[btn.mainKey]

        local anchor = position and ActionBar.ResolveAnchor(frame, position[2])
        if anchor and not (ActionBar.ignoredSlot[slotID] == true) then
            PlaceButton(btn, position, anchor)
        end

        ActionBar.UpdateIcon(slotID)

        return
    end

    -- Обновление всех кнопок (если не передан slotID)
    for slotID, btn in pairs(frame.actionButtons) do
        local command = ConsoleMenu:GetBindingCommandBySlotID(slotID)
        -- Раскладка панели всегда по клавишам контроллера, даже без подключённого геймпада.
        local binding = ConsoleMenu:GetCommandBinding(command, true)
        btn.binding = binding

        local mainKey, modifierKey = ConsoleMenu:ParseBindingKey(binding)
        btn.mainKey = mainKey
        btn.modifierKey = modifierKey

        local position = ActionBar.buttonPositions[btn.mainKey]
        local anchor = position and ActionBar.ResolveAnchor(frame, position[2])
        if anchor and not (ActionBar.ignoredSlot[slotID] == true) then
            PlaceButton(btn, position, anchor)
        end

        ActionBar.UpdateIcon(slotID)
    end
end

-- Смягчение с перелётом, как у значков облака.
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

-- Доля размера: ноль прячет, единица — обычный размер, между ними лёгкий перелёт.
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

-- Показывает кадр сразу, без затухания.
local function ShowNow(frame)
    if not frame then
        return
    end
    if frame.fadeOut then
        frame.fadeOut:Stop()
        frame.fadeOut:SetScript("OnFinished", nil)
    end
    if frame.fadeIn then
        frame.fadeIn:Stop()
    end
    frame:Show()
    frame:SetAlpha(1)
end

-- Прячет кадр сразу и возвращает полную непрозрачность.
local function HideNow(frame)
    if not frame then
        return
    end
    if frame.fadeOut then
        frame.fadeOut:Stop()
        frame.fadeOut:SetScript("OnFinished", nil)
    end
    if frame.fadeIn then
        frame.fadeIn:Stop()
    end
    frame:Hide()
    frame:SetAlpha(1)
end

-- Проявляет тень обычного размера: меняется только прозрачность.
function FadeRevealShadow(shadow, scale)
    if not shadow then
        return
    end
    RestoreGroupShadowSize(shadow)
    local alpha = scale or 0
    if alpha < 0 then
        alpha = 0
    elseif alpha > 1 then
        alpha = 1
    end
    if shadow.fadeOut then
        shadow.fadeOut:Stop()
        shadow.fadeOut:SetScript("OnFinished", nil)
    end
    if shadow.fadeIn then
        shadow.fadeIn:Stop()
    end
    if alpha <= 0.001 then
        shadow:SetAlpha(0)
        shadow:Hide()
        return
    end
    shadow:Show()
    shadow:SetAlpha(alpha)
end

-- Тень готового значка гаснет вместе с панелью, а не обрывается в конце.
local function FadeGlowShadows(frame, scale)
    if not frame.actionButtons then
        return
    end
    local alpha = scale or 0
    if alpha < 0 then
        alpha = 0
    elseif alpha > 1 then
        alpha = 1
    end
    local ceiling = ActionBar.glowShadowAlpha or 1
    if ceiling > 1 then
        ceiling = 1
    elseif ceiling < 0 then
        ceiling = 0
    end
    alpha = alpha * ceiling
    for _, btn in pairs(frame.actionButtons) do
        local shadow = btn.glowShadow
        if shadow and btn.glowReady then
            if shadow.fadeOut then
                shadow.fadeOut:Stop()
                shadow.fadeOut:SetScript("OnFinished", nil)
            end
            if shadow.fadeIn then
                shadow.fadeIn:Stop()
            end
            if alpha <= 0.001 then
                shadow:SetAlpha(0)
                shadow:Hide()
            else
                shadow:Show()
                shadow:SetAlpha(alpha)
            end
        end
    end
end

-- Растит кнопки. Сам кадр не трогаем: облако — его дочерний элемент и должно остаться видимым.
local function ApplySpellRevealScale(frame, scale)
    if scale < 0 then
        scale = 0
    end
    frame.spellRevealScale = scale
    local drawn = scale > 0 and scale or 0.001
    if frame:GetScale() ~= 1 then
        frame:SetScale(1)
    end
    if frame.actionButtons then
        for _, btn in pairs(frame.actionButtons) do
            btn:SetScale(drawn)
            local position = btn.mainKey and ActionBar.buttonPositions[btn.mainKey]
            local anchor = position and ActionBar.ResolveAnchor(frame, position[2])
            if anchor and ActionBar.ignoredSlot[btn.slotID] ~= true then
                PlaceButton(btn, position, anchor)
            end
        end
    end
    FadeRevealShadow(frame.PADshadow, scale)
    FadeRevealShadow(frame.PADDshadow, scale)
    FadeGlowShadows(frame, scale)
end

-- Возвращает кнопки и тени к обычному размеру.
local function ResetSpellRevealScale(frame)
    frame.spellRevealScale = 1
    frame:SetScale(1)
    if frame.actionButtons then
        for _, btn in pairs(frame.actionButtons) do
            btn:SetScale(1)
            local position = btn.mainKey and ActionBar.buttonPositions[btn.mainKey]
            local anchor = position and ActionBar.ResolveAnchor(frame, position[2])
            if anchor and ActionBar.ignoredSlot[btn.slotID] ~= true then
                PlaceButton(btn, position, anchor)
            end
        end
    end
    RestoreGroupShadowSize(frame.PADshadow)
    RestoreGroupShadowSize(frame.PADDshadow)
    if frame.PADshadow then
        frame.PADshadow.groupShown = false
        frame.PADshadow:Hide()
        frame.PADshadow:SetAlpha(1)
    end
    if frame.PADDshadow then
        frame.PADDshadow.groupShown = false
        frame.PADDshadow:Hide()
        frame.PADDshadow:SetAlpha(1)
    end
end

-- Готовит состояние роста и отдельный цикл, пока панель ещё скрыта.
local function EnsureSpellReveal(frame)
    local reveal = frame.spellReveal
    if reveal then
        return reveal
    end
    local driver = CreateFrame("Frame", nil, frame)
    driver:Hide()
    reveal = {
        life = 1,
        start = 1,
        target = 1,
        elapsed = 0,
        duration = 0,
        owns = false,
        driver = driver,
    }
    frame.spellReveal = reveal
    driver:SetScript("OnUpdate", function(_, elapsed)
        ActionBar.StepSpellReveal(elapsed)
    end)
    return reveal
end

-- Возвращает значки основной панели, когда сама панель уже скрыта.
local function RestoreHostFaces()
    local frame = ActionBar.GetFrame()
    if not frame or not frame.actionButtons or not ActionBar.SetButtonModifier then
        return
    end
    for _, btn in pairs(frame.actionButtons) do
        if not btn.modifierKey then
            ActionBar.SetButtonModifier(btn, nil, true)
        end
    end
    if ActionBar.SyncGlowButtonSizes then
        ActionBar.SyncGlowButtonSizes()
    end
end

-- Шаг роста или спада иконок и теней.
function ActionBar.StepSpellReveal(elapsed)
    local frame = ActionBar.GetFrame()
    local reveal = frame and frame.spellReveal
    if not reveal or not reveal.owns then
        return
    end

    local scale = frame.spellRevealScale or 0
    if reveal.duration and reveal.duration > 0 then
        reveal.elapsed = (reveal.elapsed or 0) + (elapsed or 0)
        local amount = reveal.elapsed / reveal.duration
        if amount >= 1 then
            amount = 1
            reveal.life = reveal.target
            reveal.duration = 0
        end
        local blend = EaseOutBack(amount)
        scale = (reveal.scaleStart or 0) + ((reveal.scaleTarget or 0) - (reveal.scaleStart or 0)) * blend
        if scale < 0 then
            scale = 0
        end
    end

    ApplySpellRevealScale(frame, scale)

    if (reveal.duration or 0) > 0 then
        return
    end
    if reveal.driver then
        reveal.driver:Hide()
    end
    if reveal.target ~= 0 or scale > 0.001 then
        -- Панель уже выросла: облако, погашенное в начале, нужно показать.
        if reveal.target ~= 0 and reveal.fromHidden then
            reveal.fromHidden = false
            if ActionBar.UpdateClouds then
                ActionBar.UpdateClouds()
            end
        end
        return
    end

    HideNow(frame)
    reveal.owns = false
    reveal.life = 0
    reveal.shownModifier = nil
    frame.spellRevealSuppressed = false
    ResetSpellRevealScale(frame)
    RestoreHostFaces()
    if ActionBar.QuietCollapseBoosts then
        ActionBar.QuietCollapseBoosts()
    end
end

-- Запускает рост или спад. Повтор в ту же сторону не сбрасывает уже идущий ход.
local function BeginSpellReveal(frame, target)
    local reveal = EnsureSpellReveal(frame)
    if reveal.target == target and (reveal.duration or 0) > 0 then
        return
    end
    local drawn = frame.spellRevealScale
    if drawn == nil then
        drawn = BubbleScale(reveal.life or 0)
    end
    if math.abs(drawn - target) < 0.001 and (reveal.duration or 0) <= 0 then
        reveal.life = target
        reveal.target = target
        reveal.scaleStart = target
        reveal.scaleTarget = target
        ApplySpellRevealScale(frame, target)
        return
    end

    reveal.scaleStart = drawn
    reveal.scaleTarget = target
    reveal.target = target
    reveal.life = drawn
    reveal.elapsed = 0
    local span = math.abs(target - drawn)
    local full = target == 1 and ActionBar.spellRevealShowDuration or ActionBar.spellRevealHideDuration
    if not full or full < 0.01 then
        full = 0.2
    end
    reveal.duration = full * span
    if reveal.driver then
        reveal.driver:Show()
    end
    ActionBar.StepSpellReveal(0)
end

-- Решает, нужен переворот или рост панели целиком.
local function SyncSpellRevealMode(frame, activeModifier)
    local reveal = EnsureSpellReveal(frame)
    local modifierHeld = activeModifier ~= nil
    local barShown = frame:IsShown() and (frame:GetAlpha() or 0) > 0.02

    if modifierHeld then
        reveal.shownModifier = activeModifier
        if reveal.owns or not barShown then
            if not reveal.owns then
                reveal.life = 0
                frame.spellRevealScale = 0
                reveal.fromHidden = true
            end
            reveal.owns = true
            frame.spellRevealSuppressed = true
            BeginSpellReveal(frame, 1)
        else
            reveal.fromHidden = false
            frame.spellRevealSuppressed = false
        end
        return
    end

    if reveal.owns then
        frame.spellRevealSuppressed = true
        BeginSpellReveal(frame, 0)
        return
    end

    frame.spellRevealSuppressed = false
end

-- Переворот не нужен: панель была скрыта и сейчас вырастает или сдувается целиком.
function ActionBar.SuppressSpellFlip()
    local frame = ActionBar.GetFrame()
    return frame and frame.spellRevealSuppressed == true
end

-- В исследовании панель видна, пока удерживается дополнительная клавиша.
local function UpdateExploringFrameVisibility(activeModifier)
    local contextData = ConsoleMenuFrame and ConsoleMenuFrame.PlayerContext
    if not contextData then
        return
    end
    if ConsoleMenu:GetPlayerContext() ~= "exploring" then
        return
    end

    local frame = ActionBar.GetFrame()
    if not frame then
        return
    end

    if frame.spellReveal and frame.spellReveal.owns then
        return
    end

    if frame.barDesired == false then
        ConsoleMenu:AnimatedHide(frame)
        return
    end

    if ActionBar.IsExploringCloudHiding and ActionBar.IsExploringCloudHiding() then
        return
    end

    if activeModifier then
        ConsoleMenu:AnimatedShow(frame)
    else
        ConsoleMenu:AnimatedHide(frame)
    end
end

-- Смена набора кнопок при удержании дополнительной клавиши.
local function UpdateModifierState()
    local frame = ActionBar.GetFrame()
    if not frame then
        return
    end

    if ActionBar.RememberCombatPage then
        ActionBar.RememberCombatPage()
    end

    local activeModifier = GetActiveModifier()
    if frame.barDesired == false then
        activeModifier = nil
    end
    SyncSpellRevealMode(frame, activeModifier)
    local reveal = frame.spellReveal
    local revealOwns = reveal and reveal.owns
    local instant = revealOwns and reveal.fromHidden

    local shrinking = revealOwns and reveal.target == 0
    local faceModifier = activeModifier
    if shrinking then
        faceModifier = reveal.shownModifier
    end
    for slotID, btn in pairs(frame.actionButtons) do
        local visible = IsActionButtonVisible(slotID, btn, activeModifier)
        if not btn.modifierKey and ActionBar.SetButtonModifier then
            local passModifier = visible and activeModifier or nil
            if shrinking then
                passModifier = faceModifier
            end
            ActionBar.SetButtonModifier(btn, passModifier, instant or shrinking)
        end
        if shrinking then
            if btn:IsShown() then
                ShowNow(btn)
            end
        elseif revealOwns then
            if visible then
                ShowNow(btn)
            else
                HideNow(btn)
                btn:SetScale(1)
            end
        elseif visible then
            ConsoleMenu:AnimatedShow(btn)
        else
            ConsoleMenu:AnimatedHide(btn)
        end
    end

    if ActionBar.UpdateClouds then
        ActionBar.UpdateClouds()
    end
    UpdateActionButtonShadows()
    UpdateExploringFrameVisibility(activeModifier)
    if ActionBar.RefreshFaceButtonDesaturation then
        ActionBar.RefreshFaceButtonDesaturation()
    end
    if frame.barDesired == false and not revealOwns then
        ConsoleMenu:AnimatedHide(frame)
    elseif frame.barDesired ~= false and ConsoleMenu.GetPlayerContext and ConsoleMenu:GetPlayerContext() ~= "exploring" and not revealOwns then
        ConsoleMenu:AnimatedShow(frame)
    end
    -- Набор кнопок сменился: старый сдвиг не должен остаться у новой страницы.
    if ActionBar.SyncGlowButtonSizes then
        ActionBar.SyncGlowButtonSizes()
    end
    if revealOwns and reveal.target ~= 0 then
        ShowNow(frame)
    end
    if revealOwns then
        ApplySpellRevealScale(frame, frame.spellRevealScale or 0)
    end
    if ActionBar.WakeClouds then
        ActionBar.WakeClouds()
    end
end

ActionBar.UpdateButtonPositions = UpdateButtonPositions
ActionBar.UpdateModifierState = UpdateModifierState
ActionBar.UpdateActionButtonShadows = UpdateActionButtonShadows
ActionBar.UpdateActionButtonShadowsIfNeeded = UpdateActionButtonShadowsIfNeeded
