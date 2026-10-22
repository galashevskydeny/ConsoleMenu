-- Общие сведения панели команд: размеры, положения кнопок и скрытые ячейки.

local ConsoleMenu = _G.ConsoleMenu

ConsoleMenu.ActionBar = ConsoleMenu.ActionBar or {}

local ActionBar = ConsoleMenu.ActionBar

ActionBar.frameWidth = 688
ActionBar.frameHeight = 196

ActionBar.buttonSize = 52
-- На сколько пикселей вырастает кнопка, пока на ней горит свечение готовности.
ActionBar.glowGrowSize = 4
-- На сколько пикселей уменьшаются остальные кнопки, пока чужое свечение горит.
ActionBar.glowShrinkSize = 4
-- На сколько пикселей тёмные кнопки подъезжают к тёмной противоположной.
ActionBar.glowShiftSize = 8
-- Сколько секунд длятся увеличение из-за своего свечения, уменьшение и сдвиг к тёмной противоположной.
ActionBar.glowMotionDuration = 0.2
-- Сколько секунд длится проявление и погасание полупрозрачности кнопки.
ActionBar.buttonFadeDuration = 0.12
-- Сколько секунд длятся увеличение до штатного размера и сдвиг на штатное место.
ActionBar.glowHomeDuration = 0.15
-- Сторона тени у иконки со свечением: больше круга, чтобы выходить за край и немного накрывать соседние иконки.
ActionBar.glowShadowSize = 240
-- Непрозрачность этой тени: 1 — полностью видима, 0 — невидима.
ActionBar.glowShadowAlpha = 0.7

-- Крутящийся контур готовности: лист из тридцати кадров, пять в ширину и шесть в высоту.
ActionBar.glowScale = 1.5
ActionBar.glowRows = 6
ActionBar.glowColumns = 5
ActionBar.glowFrames = 30
ActionBar.glowDuration = 1
-- Мягкое золото и более светлое ядро, чтобы свечение не стало белым.
ActionBar.glowBodyColor = { 1, 0.78, 0.22 }
ActionBar.glowCoreColor = { 1, 0.93, 0.55 }
ActionBar.glowBodyTexture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Glow\\orbit-glow-pinswirl-loop-round-full.tga"
ActionBar.glowCoreTexture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Glow\\orbit-glow-pinswirl-loop-round-full-core.tga"
-- Светящееся кольцо под контуром. Тот же лист кадров, дыхание медленнее вращения.
ActionBar.glowRingTexture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Glow\\orbit-glow-halobreathe-loop-round-full-core.tga"
ActionBar.glowRingDuration = 1.6
-- Вспышка из одного цикла записи: все кадры ролика, восемь в ширину и семь в высоту.
-- Кадр целиком, крупнее иконки: свечение в записи занимает середину, и на размере иконки его не разглядеть.
ActionBar.glowBurstTexture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Glow\\impact-burst.tga"
ActionBar.glowBurstSize = ActionBar.buttonSize * 6
ActionBar.glowBurstRows = 7
ActionBar.glowBurstColumns = 8
ActionBar.glowBurstFrames = 56
ActionBar.glowBurstDuration = 1

ActionBar.iconSize = 28
ActionBar.stackCountSize = 24
ActionBar.stackCountOffset = 8
ActionBar.stackCountShadowOffset = 12
ActionBar.fontSize = 14

ActionBar.paddingPAD = ActionBar.buttonSize * 1.5
ActionBar.paddingPADD = ActionBar.buttonSize * 1.5

ActionBar.buttonVerticalPadding = ActionBar.buttonSize * 0.6
ActionBar.buttonHorizontalPadding = ActionBar.buttonSize * 0.6

ActionBar.slot12ContainerWidth = 190
ActionBar.slot12ContainerHeight = 70
ActionBar.slot12LabelFontSize = 16
-- Отступ иконки от края фона = вертикальный зазор (фон круга 60 при высоте 70)
ActionBar.slot12IconPadding = (ActionBar.slot12ContainerHeight - (ActionBar.buttonSize + 8)) / 2
ActionBar.slot12LabelGap = ActionBar.slot12IconPadding + 6
ActionBar.slot12LabelEdgePadding = ActionBar.slot12IconPadding
ActionBar.slot12LabelRightPadding = ActionBar.slot12IconPadding + 12
-- Плашка островка. Картинка вдвое крупнее показа: торцы круглые, при расширении тянется только середина.
ActionBar.slot12PlateTexture = "Interface\\AddOns\\ConsoleMenu\\Assets\\GroupIcon3.png"
ActionBar.slot12PlateTexWidth = 380
ActionBar.slot12PlateTexHeight = 140
-- Зазор до верхних кнопок соседних групп, чтобы расширенный островок их не касался.
ActionBar.slot12SideGap = 16
-- Высота верхнего ряда значков с учётом внутреннего отступа панельки тачпада.
ActionBar.topRowOffsetY = ActionBar.buttonVerticalPadding + ActionBar.buttonSize / 2 + ActionBar.slot12IconPadding

-- Ширина островка без полосы названия: кружок и отступы вокруг него.
function ActionBar.Slot12ChromeWidth()
    return ActionBar.slot12IconPadding
        + ActionBar.buttonSize + 8
        + ActionBar.slot12LabelGap
        + ActionBar.slot12LabelRightPadding
end

-- Расстояние от левого края островка до центра кружка.
function ActionBar.Slot12IconCenterOffset()
    return ActionBar.slot12IconPadding + (ActionBar.buttonSize + 8) / 2
end

-- Наибольшая ширина островка: он остаётся по центру и не доходит до верхних кнопок групп.
function ActionBar.Slot12MaxWidth()
    local halfButton = ActionBar.buttonSize / 2 + (ActionBar.glowGrowSize or 0) / 2
    local gap = ActionBar.slot12SideGap or 0
    local center = ActionBar.frameWidth / 2
    local leftInner = ActionBar.paddingPADD + halfButton + gap
    local rightInner = ActionBar.frameWidth - ActionBar.paddingPAD - halfButton - gap
    local leftRoom = (center - leftInner) * 2
    local rightRoom = (rightInner - center) * 2
    local span = leftRoom
    if rightRoom < span then
        span = rightRoom
    end
    if span < ActionBar.slot12ContainerWidth then
        return ActionBar.slot12ContainerWidth
    end
    return span
end

-- Ставит кружок умения на левый край островка и снимает наклон после подброса.
function ActionBar.PlaceSlot12Icon(btn)
    if not btn then
        return
    end

    if btn.Ability then
        btn.Ability:ClearAllPoints()
        btn.Ability:SetPoint("LEFT", btn, "LEFT", (ActionBar.slot12IconPadding or 0) + 4, 0)
        btn.Ability:SetSize(ActionBar.buttonSize, ActionBar.buttonSize)
        if btn.IconFrame then
            btn.IconFrame:ClearAllPoints()
            btn.IconFrame:SetAllPoints(btn.Ability)
        end
        return
    end

    local background = btn.background
    if background then
        background:ClearAllPoints()
        background:SetPoint("LEFT", btn, "LEFT", ActionBar.slot12IconPadding, 0)
        background:SetSize(ActionBar.buttonSize + 8, ActionBar.buttonSize + 8)
        if background.SetRotation then
            background:SetRotation(0)
        end
    end

    local texture = btn.texture
    if texture then
        texture:ClearAllPoints()
        texture:SetSize(ActionBar.buttonSize, ActionBar.buttonSize)
        if background then
            texture:SetPoint("CENTER", background, "CENTER", 0, 0)
        end
        texture:SetVertexColor(1, 1, 1)
        if texture.SetRotation then
            texture:SetRotation(0)
        end
    end

    if btn.mask and btn.mask.SetRotation then
        btn.mask:SetRotation(0)
    end
end

ActionBar.shadowSize = 320

ActionBar.animationDuration = 0.05

-- Клиент умножает отступ точки на размер кнопки. Делим заранее, чтобы место на джойстике не съезжало к центру группы.
function ActionBar.StableOffset(value, scale)
    local offset = value or 0
    scale = scale or 1
    if scale >= 0.999 then
        return offset
    end
    if scale < 0.001 then
        scale = 0.001
    end
    return offset / scale
end

-- Центр кнопки стоит на своём месте джойстика относительно центра группы.
-- Второй элемент — ключ якоря: right — правая группа, left — левая, bar — сама панель.
local reachX = ActionBar.buttonHorizontalPadding + ActionBar.buttonSize / 2
local reachY = ActionBar.buttonVerticalPadding + ActionBar.buttonSize / 2
ActionBar.buttonPositions = {
    PADRSTICK = { "CENTER", "right", "CENTER", 0, -reachY },

    PAD2 = { "CENTER", "right", "CENTER", reachX, 0 },
    PAD3 = { "CENTER", "right", "CENTER", -reachX, 0 },
    PAD4 = { "CENTER", "right", "CENTER", 0, reachY },

    PADDUP = { "CENTER", "left", "CENTER", 0, reachY },
    PADDRIGHT = { "CENTER", "left", "CENTER", reachX, 0 },
    PADDLEFT = { "CENTER", "left", "CENTER", -reachX, 0 },
    -- Низ левой крестовины. Без модификатора здесь способность левого рычага.
    PADDDOWN = { "CENTER", "left", "CENTER", 0, -reachY },

    -- Сенсорная панель DualSense: по центру, на высоте верхнего ряда крестовины и лицевых кнопок
    PAD6 = { "CENTER", "bar", "CENTER", 0, ActionBar.topRowOffsetY },
    PADBACK = { "CENTER", "bar", "CENTER", 0, ActionBar.topRowOffsetY },
}

-- Правая сторона: квадрат, треугольник и круг. Правый рычаг добавляется, только если нажат как ячейка.
ActionBar.rightButtonKeys = { "PAD3", "PAD4", "PAD2" }
ActionBar.rightStickKey = "PADRSTICK"
-- Левая сторона: крестовина. Нажатие левого рычага показывается на нижнем направлении.
ActionBar.leftButtonKeys = { "PADDUP", "PADDRIGHT", "PADDDOWN", "PADDLEFT" }
ActionBar.leftStickKey = "PADLSTICK"
-- Сенсорная панель остаётся отдельной кнопкой.
ActionBar.padButtonKey = "PAD6"

-- Слоты ACTIONBUTTON12 / MULTIACTIONBAR*BUTTON12
ActionBar.slot12Slots = {
    [12] = true,
    [24] = true,
    [60] = true,
    [72] = true,
}

ActionBar.ignoredSlot = {
    [53] = true,
}

-- Ячейки второй панели на крестовине: вверх, вправо, вниз, влево.
ActionBar.boostSlots = {
    { slotID = 66, key = "UP" },
    { slotID = 67, key = "RIGHT" },
    { slotID = 68, key = "DOWN" },
    { slotID = 69, key = "LEFT" },
}

ActionBar.boostSlotLookup = {
    [66] = true,
    [67] = true,
    [68] = true,
    [69] = true,
}

-- Облако чуть крупнее обычного умения.
-- После разворота значки садятся на крестовину: вверх, вправо, вниз и влево.
ActionBar.boostClusterSize = 200
ActionBar.boostCloudSizes = { 34, 39.95, 28.05, 32.3 }
ActionBar.boostExpandOffset = ActionBar.buttonVerticalPadding + ActionBar.buttonSize / 2
-- Смещение от центра лицевых кнопок до центра крестовины: туда садится разворот.
ActionBar.boostExpandOriginX = ActionBar.paddingPADD + ActionBar.paddingPAD - ActionBar.frameWidth + 1
ActionBar.boostExpandOriginY = 0
-- Покой у правого рычага. Крупные ближе к центру, мелкие дальше, чтобы силуэт читался кругом.
-- Стороны нарочно не совпадают с разворотом, чтобы значки перелетали крест-накрест.
ActionBar.boostCloudOffsets = {
    { x = -9.867, y = -5.6925 - ActionBar.boostExpandOffset },
    { x = -3.795, y = 6.578 - ActionBar.boostExpandOffset },
    { x = 13.156, y = 7.59 - ActionBar.boostExpandOffset },
    { x = 6.325, y = -11.0055 - ActionBar.boostExpandOffset },
}
-- Точки покоя четырёх значков, когда в центре облака дополнительное действие.
-- На 15% ближе к центру, чтобы облако было кучнее.
ActionBar.boostCloudOffsetsWithExtra = {
    { x = -20.968, y = -12.096 - ActionBar.boostExpandOffset },
    { x = -8.065, y = 13.978 - ActionBar.boostExpandOffset },
    { x = 21.25, y = 12.257 - ActionBar.boostExpandOffset },
    { x = 13.441, y = -23.387 - ActionBar.boostExpandOffset },
}
-- В присутствии дополнительного действия остальные значки чуть мельче, но ближе к его размеру.
ActionBar.boostCloudSizesWithExtra = { 27.88, 32.76, 23.0, 26.49 }
-- Сверху крестовина вверх, справа вправо, снизу вниз, слева влево.
ActionBar.boostExpandPositions = {
    { x = ActionBar.boostExpandOriginX, y = ActionBar.boostExpandOriginY + ActionBar.boostExpandOffset },
    { x = ActionBar.boostExpandOriginX + ActionBar.boostExpandOffset, y = ActionBar.boostExpandOriginY },
    { x = ActionBar.boostExpandOriginX, y = ActionBar.boostExpandOriginY - ActionBar.boostExpandOffset },
    { x = ActionBar.boostExpandOriginX - ActionBar.boostExpandOffset, y = ActionBar.boostExpandOriginY },
}
-- Квадрат, треугольник и круг основной панели: при правом рычаге остаются на экране серыми.
ActionBar.mainFaceButtonKeys = {
    PAD3 = true,
    PAD4 = true,
    PAD2 = true,
}
-- Умения облака правого рычага: вверх, вправо, вниз, влево его панели.
ActionBar.rightCloudKeys = { "PADDUP", "PADDRIGHT", "PADDDOWN", "PADDLEFT" }
-- Умения облака левого рычага: квадрат, треугольник и круг его панели.
ActionBar.leftCloudKeys = { "PAD3", "PAD4", "PAD2" }
-- Эти кнопки не переворачиваются, пока модификатор сидит на правом рычаге.
ActionBar.rightStickStillKeys = {
    PAD3 = true,
    PAD4 = true,
    PAD2 = true,
}
-- Дополнительная кнопка действия: самый крупный значок в центре облака.
ActionBar.boostExtraCloudSize = 40
-- Покой у правого рычага, посадка в центре панели — в координатах самой панели.
ActionBar.boostExtraRestX = ActionBar.frameWidth / 2 - ActionBar.paddingPAD
ActionBar.boostExtraRestY = -ActionBar.boostExpandOffset
ActionBar.boostExtraExpandX = 0
ActionBar.boostExtraExpandY = 0
ActionBar.boostExtraFloatSpeed = 0.33
ActionBar.boostExtraFloatPhase = 2.55
ActionBar.boostFloatRadius = 1.784592
ActionBar.boostFloatSpeeds = { 0.2992, 0.39168, 0.26112, 0.34272 }
-- Разброс скорости перелёта: быстрые садятся заметно раньше медленных.
ActionBar.boostFlightRates = { 0.72, 1.22, 0.86, 1.12 }
ActionBar.boostExtraFlightRate = 0.96
ActionBar.boostFloatPhases = { 0.2, 1.7, 3.4, 4.9 }
ActionBar.boostExpandDuration = 0.48
ActionBar.boostCollapseDuration = ActionBar.boostExpandDuration
ActionBar.boostLayoutDuration = 0.4
-- Рост и спад значка облака: появляется увеличением, исчезает уменьшением.
ActionBar.boostBubbleDuration = 0.16
-- К концу сбора пузырёк снова надувается, не раньше посадки монеты.
ActionBar.boostBubbleReturn = 0.12
ActionBar.boostCooldownProgress = 0.72
-- Переворот заканчивается к появлению цифр восстановления, чтобы лицо уже было ровным.
ActionBar.boostFlipSettle = ActionBar.boostCooldownProgress
-- С этой доли подброса уже видно число зарядов входящего умения. Ниже неё число снова прячется.
ActionBar.boostCountReveal = 0.12
-- Узкое ребро монеты в кувырке, доля полной ширины.
ActionBar.boostFlipEdge = 0.07
-- Высота подброса: короткий отрыв, без высокого прыжка.
ActionBar.boostFlipLift = 26
-- Боковой толчок щелчка, к посадке возвращается.
ActionBar.boostFlipNudge = 6
-- Сколько полуоборотов монета делает в воздухе. Нечётное число сажает её другой стороной.
ActionBar.boostCoinTurns = 1
-- Подпись и буква L у дополнительного действия появляются чуть раньше полной посадки.
ActionBar.boostExtraCaptionProgress = 0.78
ActionBar.boostHintFadeProgress = 0.35
-- Подсказка правого рычага на краю более широкого облака: чуть правее и выше, но не слишком далеко вправо.
ActionBar.boostHintExtraOffsetX = 6
ActionBar.boostHintExtraOffsetY = 8
-- Буква L на дополнительной кнопке действия: чуть дальше от центра, но ближе исходного угла.
ActionBar.boostExtraKeyOffsetX = 5
ActionBar.boostExtraKeyOffsetY = 5

ActionBar.stackCountChange = ActionBar.stackCountChange or {}

-- Ассоциативный массив панели: по ключу способности лежит true, если счётчик уже показывали.
-- Хранится в сохранённых данных и не пропадает после перезапуска игры.
function ActionBar.EnsureChargeShown()
    if not ConsoleMenuDB then
        ConsoleMenuDB = {}
    end
    if type(ConsoleMenuDB.actionBarChargeShown) ~= "table" then
        ConsoleMenuDB.actionBarChargeShown = {}
    end
    ActionBar.chargeShown = ConsoleMenuDB.actionBarChargeShown
    return ActionBar.chargeShown
end

-- Ячейки, у которых заряды уже были видны. Скрытое боевое значение само по себе счётчик не включает.
ActionBar.chargeSlots = ActionBar.chargeSlots or {}
-- Последнее настоящее число. Пустой ответ после переворота не стирает его.
ActionBar.chargeText = ActionBar.chargeText or {}
-- Умение, которому принадлежало запомненное число. Чужое умение его не наследует.
ActionBar.chargeAction = ActionBar.chargeAction or {}
ActionBar.countReadRetries = ActionBar.countReadRetries or {}

-- Сколько кадров подряд перечитывать ячейку, пока число зарядов не пришло.
local countReadRetryLimit = 5
local countRetryQueued = {}
local countRetryPump = false

-- Число зарядов видно игроку: оно есть и это не ноль. Скрытое боевое значение сравнивать нельзя.
function ActionBar.HasVisibleChargeCount(count)
    if ActionBar.IsSecretValue(count) then
        return false
    end
    return count ~= nil and count ~= "" and count ~= "0" and count ~= 0
end

-- Идёт бой: пустой ответ нельзя принимать за исчезновение зарядов.
function ActionBar.IsInCombat()
    return InCombatLockdown and InCombatLockdown() and true or false
end

-- Вне боя пустая подпись прячет цифры. Ноль и пустой ответ числом не считаются, память о счётчике не стирают.
function ActionBar.ShouldForgetChargeCount(count)
    if ActionBar.IsSecretValue(count) or count == nil or ActionBar.IsInCombat() then
        return false
    end
    return not ActionBar.HasVisibleChargeCount(count)
end

-- Запоминает, что у ячейки есть счётчик зарядов, и само число.
function ActionBar.RememberChargeSlot(slotID, count)
    if not slotID then
        return
    end
    ActionBar.chargeSlots[slotID] = true
    if not ActionBar.IsSecretValue(count) and ActionBar.HasVisibleChargeCount(count) then
        ActionBar.chargeText[slotID] = count
    end
    local actionKey = ActionBar.ReadActionKey(slotID)
    if actionKey and actionKey ~= "" then
        ActionBar.chargeAction[slotID] = actionKey
    end
end

-- У ячейки уже бывал настоящий счётчик, не пустая подпись.
function ActionBar.SlotHasChargeCounter(slotID)
    return slotID ~= nil and ActionBar.chargeSlots[slotID] == true
end

-- Последнее видимое число этой ячейки.
function ActionBar.SavedChargeText(slotID)
    if not slotID then
        return nil
    end
    return ActionBar.chargeText[slotID]
end

-- Прячет цифры, но оставляет знание, что у ячейки бывает счётчик.
function ActionBar.ClearChargeText(slotID)
    if not slotID then
        return
    end
    ActionBar.chargeText[slotID] = nil
    ActionBar.stackCountChange[slotID] = nil
end

-- Смена действия: прежнее число относилось к другому умению.
function ActionBar.ForgetChargeCount(slotID)
    if not slotID then
        return
    end
    ActionBar.stackCountChange[slotID] = nil
    ActionBar.chargeSlots[slotID] = nil
    ActionBar.chargeText[slotID] = nil
    ActionBar.chargeAction[slotID] = nil
    ActionBar.countReadRetries[slotID] = nil
    local frame = ActionBar.GetFrame()
    if not frame or not frame.actionButtons then
        return
    end
    for _, btn in pairs(frame.actionButtons) do
        if btn.ForgetCharges and (btn.slotID == slotID or btn.shownSlot == slotID) then
            btn:ForgetCharges()
        end
    end
end

-- Какое умение сейчас лежит в ячейке. Скрытый ответ не считается сменой.
function ActionBar.ReadActionKey(slotID)
    if not slotID or not GetActionInfo then
        return nil
    end
    local ok, actionType, id, subType = pcall(GetActionInfo, slotID)
    if not ok then
        return nil
    end
    if ActionBar.IsSecretValue(actionType) or ActionBar.IsSecretValue(id) or ActionBar.IsSecretValue(subType) then
        return nil
    end
    if not actionType then
        return ""
    end
    return tostring(actionType) .. ":" .. tostring(id or "") .. ":" .. tostring(subType or "")
end

-- В ячейке уже другое умение, и это видно без скрытого ответа.
function ActionBar.ChargeActionChanged(slotID)
    local saved = slotID and ActionBar.chargeAction[slotID]
    if not saved then
        return false
    end
    local key = ActionBar.ReadActionKey(slotID)
    if not key then
        return false
    end
    return key ~= saved
end

-- Заряды самого умения, если подпись ячейки их не содержит.
local function ReadChargeCount(slotID)
    if not C_ActionBar.GetActionCharges then
        return nil, nil
    end

    local ok, info, maxCharges = pcall(C_ActionBar.GetActionCharges, slotID)
    if not ok then
        return nil, nil
    end
    if ActionBar.IsSecretValue(info) then
        return info, maxCharges
    end
    if info == nil then
        return nil, nil
    end

    local current = info
    if type(info) == "table" then
        current = info.currentCharges
        maxCharges = info.maxCharges
    end
    return current, maxCharges
end

-- Число зарядов с ячейки. Пустая подпись и скрытое боевое значение сами счётчик не создают.
function ActionBar.ReadDisplayCount(slotID)
    if not slotID or not C_ActionBar or not C_ActionBar.GetActionDisplayCount then
        return nil
    end

    local count = C_ActionBar.GetActionDisplayCount(slotID)
    if not ActionBar.IsSecretValue(count) and ActionBar.HasVisibleChargeCount(count) then
        ActionBar.RememberChargeSlot(slotID, count)
        return count
    end

    local current, maxCharges = ReadChargeCount(slotID)
    local severalCharges = not ActionBar.IsSecretValue(maxCharges) and type(maxCharges) == "number" and maxCharges > 1
    if severalCharges then
        ActionBar.RememberChargeSlot(slotID, current)
        if not ActionBar.IsSecretValue(current) and current ~= nil then
            return current
        end
    end

    -- Скрытое число рисует клиент только там, где счётчик уже известен.
    if ActionBar.SlotHasChargeCounter(slotID) then
        if ActionBar.IsSecretValue(count) then
            return count
        end
        if ActionBar.IsSecretValue(current) then
            return current
        end
    end

    if not ActionBar.IsSecretValue(count) and (count == 0 or count == "0" or count == "") then
        return count
    end
    return nil
end

-- Ещё одно чтение на следующем кадре. Число попыток ограничено, чтобы пустая ячейка не крутилась вечно.
function ActionBar.ScheduleCountRetry(slotID)
    if not slotID or not RunNextFrame then
        return
    end
    if countRetryQueued[slotID] then
        return
    end

    local tries = ActionBar.countReadRetries[slotID] or 0
    if tries >= countReadRetryLimit then
        return
    end
    ActionBar.countReadRetries[slotID] = tries + 1
    countRetryQueued[slotID] = true
    if countRetryPump then
        return
    end

    countRetryPump = true
    RunNextFrame(function()
        countRetryPump = false
        local slots = countRetryQueued
        countRetryQueued = {}
        for id in pairs(slots) do
            if ActionBar.UpdateCount then
                ActionBar.UpdateCount(id)
            end
        end
    end)
end

-- Ясный ответ сбрасывает попытки. Неизвестное число у занятой ячейки читаем ещё раз.
function ActionBar.FinishCountRead(slotID, unknown)
    if not slotID then
        return
    end
    if not unknown or ActionBar.SlotHasAction(slotID) == false then
        ActionBar.countReadRetries[slotID] = nil
        return
    end
    ActionBar.ScheduleCountRetry(slotID)
end

-- Пиктограмма клавиши поверх умения: тень как у счётчика зарядов, без подложки стика.
function ActionBar.ApplyKeyGlyphStyle(iconFrame, size)
    if not iconFrame then
        return
    end

    local glyphSize = size or ActionBar.stackCountSize
    iconFrame:SetSize(glyphSize, glyphSize)
    if iconFrame.Background then
        iconFrame.Background:Hide()
    end
    if iconFrame.Shadow then
        iconFrame.Shadow:ClearAllPoints()
        iconFrame.Shadow:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", -ActionBar.stackCountShadowOffset, ActionBar.stackCountShadowOffset)
        iconFrame.Shadow:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", ActionBar.stackCountShadowOffset, -ActionBar.stackCountShadowOffset)
        iconFrame.Shadow:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png")
        iconFrame.Shadow:Show()
    end
end

-- Квадрат, треугольник или круг основной панели.
function ActionBar.IsMainFaceButtonKey(mainKey)
    return ActionBar.mainFaceButtonKeys[mainKey] == true
end

-- Правый рычаг удерживает Shift: квадрат, треугольник и круг основной панели остаются серыми.
function ActionBar.ShouldGrayFaceButtons()
    return IsShiftKeyDown() and not IsControlKeyDown() and not IsAltKeyDown()
end

-- Ячейка живёт в облаке усилений, а не на левой крестовине.
function ActionBar.IsBoostSlot(slotID)
    return ActionBar.boostSlotLookup[slotID] == true
end

-- Запасные номера дополнительной кнопки, если кадр ещё не сообщил свой.
-- 217 — обычная ячейка, 139 — прежняя ячейка той же кнопки.
ActionBar.extraActionFallbackSlots = { 217, 139 }

-- Номер ячейки стандартной дополнительной кнопки действия.
function ActionBar.GetExtraActionSlotID()
    local button = _G.ExtraActionButton1
    if button then
        if button.action and button.action ~= 0 then
            return button.action
        end
        if button.CalculateAction then
            local action = button:CalculateAction()
            if action and action ~= 0 then
                return action
            end
        end
    end
    return ActionBar.extraActionFallbackSlots[1]
end

-- Ячейка относится к дополнительной кнопке действия.
function ActionBar.IsExtraActionSlot(slotID)
    if not slotID then
        return false
    end
    if slotID == ActionBar.GetExtraActionSlotID() then
        return true
    end
    for index = 1, #ActionBar.extraActionFallbackSlots do
        if slotID == ActionBar.extraActionFallbackSlots[index] then
            return true
        end
    end
    return false
end

-- Показана ли стандартная рамка дополнительной кнопки.
local function IsExtraActionBarFrameShown()
    return ExtraActionBarFrame and ExtraActionBarFrame.IsShown and ExtraActionBarFrame:IsShown() or false
end

-- Дополнительная кнопка действия сейчас есть и должна быть в облаке.
function ActionBar.HasExtraAction()
    if not C_ActionBar or not C_ActionBar.HasExtraActionBar then
        return IsExtraActionBarFrameShown()
    end

    local ok, shown = pcall(C_ActionBar.HasExtraActionBar)
    if not ok then
        return IsExtraActionBarFrameShown()
    end

    -- В бою ответ бывает скрыт: тогда ориентируемся на саму рамку.
    if ActionBar.IsSecretValue(shown) then
        return IsExtraActionBarFrameShown()
    end

    -- Явный ответ важнее рамки и ячейки.
    -- После исчезновения кнопки рамка ещё гаснет, а в ячейке остаётся старая способность.
    return shown == true
end

-- Окно панели, если оно уже создано вместе с набором кнопок.
function ActionBar.GetFrame()
    local root = _G.ConsoleMenuFrame
    if not root then
        return nil
    end
    local frame = root.ActionBarFrame
    if not frame or not frame.actionButtons then
        return nil
    end
    return frame
end

-- Номер панели мультидействий в нумерации ячеек игры.
local multiBarIndex = {
    [1] = 6,
    [2] = 5,
    [3] = 3,
    [4] = 4,
    [5] = 13,
    [6] = 14,
    [7] = 15,
}

-- Ячейка команды панели: своя страница у основной панели и постоянное место у панели модификатора.
function ActionBar.CommandToSlot(command, page)
    if not command or command == "" then
        return nil
    end
    local buttonID = string.match(command, "^ACTIONBUTTON(%d+)$")
    if buttonID then
        buttonID = tonumber(buttonID)
        if not page or page < 1 then
            page = 1
        end
        return (page - 1) * 12 + buttonID
    end
    local bar, id = string.match(command, "^MULTIACTIONBAR(%d+)BUTTON(%d+)$")
    if bar then
        local barIndex = multiBarIndex[tonumber(bar)]
        if not barIndex then
            return nil
        end
        return (barIndex - 1) * 12 + tonumber(id)
    end
    if command == "EXTRAACTIONBUTTON1" and ActionBar.GetExtraActionSlotID then
        return ActionBar.GetExtraActionSlotID()
    end
    return nil
end

-- Ячейка, привязанная к клавише геймпада без модификатора или с ним.
function ActionBar.BindingSlot(key, modifier, page)
    if not key or not GetBindingAction then
        return nil
    end
    local binding = modifier and (modifier .. "-" .. key) or key
    local command = GetBindingAction(binding, true)
    return ActionBar.CommandToSlot(command, page)
end

-- Страница, с которой берётся способность без модификатора.
function ActionBar.SlotPage()
    if ConsoleMenu.GetPlayerContext and ConsoleMenu:GetPlayerContext() == "exploring" then
        local page = ActionBar.combatPage or 1
        if page ~= 1 and page ~= 2 then
            page = 1
        end
        return page
    end
    if C_ActionBar and C_ActionBar.GetActionBarPage then
        local page = C_ActionBar.GetActionBarPage() or 1
        if page < 1 then
            return 1
        end
        return page
    end
    return 1
end

-- Нажатие рычага привязано к ячейке панели, а не к пустому месту и не к дополнительному действию.
function ActionBar.StickHasSlot(key)
    local slot = ActionBar.BindingSlot(key, nil, ActionBar.SlotPage())
    if not slot or (ActionBar.IsExtraActionSlot and ActionBar.IsExtraActionSlot(slot)) then
        return false
    end
    return true
end

-- Кнопка, которая показывает эту ячейку: своя или одна из ячеек модификатора.
function ActionBar.GetButton(slotID)
    local frame = ActionBar.GetFrame()
    if not frame or not slotID or not frame.actionButtons then
        return nil
    end
    for _, btn in pairs(frame.actionButtons) do
        if btn.slotID == slotID or btn.shownSlot == slotID then
            return btn
        end
        local slots = btn.IconFrame and btn.IconFrame.slots
        if slots and (slots.base == slotID or slots.SHIFT == slotID or slots.CTRL == slotID or slots.ALT == slotID) then
            return btn
        end
    end
    return nil
end

-- Значение скрыто клиентом, по нему нельзя принимать решение.
function ActionBar.IsSecretValue(value)
    return value ~= nil and issecretvalue and issecretvalue(value)
end

-- Ячейка относится к текущей странице основной панели.
function ActionBar.IsSlotOnActivePage(slotID)
    if not slotID or slotID < 1 or slotID > 24 then
        return false
    end
    if not C_ActionBar or not C_ActionBar.GetActionBarPage then
        return true
    end

    local page = C_ActionBar.GetActionBarPage() or 1
    local startSlot = 12 * (page - 1) + 1
    return slotID >= startSlot and slotID < startSlot + 12
end

-- Страница, с которой в бою берутся квадрат, круг и треугольник. Вне боя третья страница её не затирает.
ActionBar.combatPage = ActionBar.combatPage or 1

-- Запоминает первую или вторую страницу, пока идёт бой или подготовка к нему.
function ActionBar.RememberCombatPage()
    if not ConsoleMenu.GetPlayerContext then
        return
    end
    local context = ConsoleMenu:GetPlayerContext()
    if context ~= "combat" and context ~= "precombat" then
        return
    end
    if not C_ActionBar or not C_ActionBar.GetActionBarPage then
        return
    end
    local page = C_ActionBar.GetActionBarPage() or 1
    if page == 1 or page == 2 then
        ActionBar.combatPage = page
    end
end

-- Ячейка лежит на запомненной боевой странице.
function ActionBar.IsSlotOnCombatPage(slotID)
    if not slotID or slotID < 1 or slotID > 24 then
        return false
    end
    local page = ActionBar.combatPage or 1
    if page ~= 1 and page ~= 2 then
        page = 1
    end
    local startSlot = 12 * (page - 1) + 1
    return slotID >= startSlot and slotID < startSlot + 12
end

-- Кадр, к которому привязана кнопка: правая группа, левая группа или сама панель.
function ActionBar.ResolveAnchor(frame, anchorKey)
    if not frame then
        return nil
    end
    if anchorKey == "right" then
        return frame.rightGroup
    end
    if anchorKey == "left" then
        return frame.leftGroup
    end
    if anchorKey == "bar" then
        return frame
    end
    return nil
end

-- Рисунок ячейки. У однокнопочного помощника берётся заклинание, которое будет применено.
-- Второй результат истинен, если клиент скрыл рисунок и трогать кнопку нельзя.
function ActionBar.GetSlotTexture(slotID)
    -- У кнопки без привязки номера нет, а клиент требует число.
    if not slotID then
        return nil, false
    end

    local textureFileID = nil

    if C_ActionBar and C_ActionBar.IsAssistedCombatAction and C_ActionBar.IsAssistedCombatAction(slotID) then
        if C_AssistedCombat and C_Spell and C_AssistedCombat.GetNextCastSpell then
            local spellID = C_AssistedCombat.GetNextCastSpell(true)
            -- Скрытый номер нельзя подменять обычным рисунком ячейки: оставляем то, что уже нарисовано.
            if ActionBar.IsSecretValue(spellID) then
                return nil, true
            end
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

    if ActionBar.IsSecretValue(textureFileID) then
        return nil, true
    end

    return textureFileID, false
end

-- Есть ли действие в ячейке. Пустой скрытый ответ не считается пустой ячейкой.
function ActionBar.SlotHasAction(slotID)
    if not slotID or not C_ActionBar or not C_ActionBar.HasAction then
        return false
    end

    local ok, hasAction = pcall(C_ActionBar.HasAction, slotID)
    if not ok then
        return nil
    end
    if ActionBar.IsSecretValue(hasAction) then
        return true
    end
    return hasAction == true
end

-- Признак скрытой ячейки, которую панель не показывает.
function ActionBar.IsSlotIgnored(slotID)
    return ActionBar.ignoredSlot[slotID] == true
end

-- Признак скрытой ячейки для остальных частей аддона.
function ConsoleMenu:IsSlotIgnored(slotID)
    return ActionBar.IsSlotIgnored(slotID)
end
