-- Общие сведения панели команд: размеры, положения кнопок и скрытые ячейки.

local ConsoleMenu = _G.ConsoleMenu

ConsoleMenu.ActionBar = ConsoleMenu.ActionBar or {}

local ActionBar = ConsoleMenu.ActionBar

ActionBar.frameWidth = 688
ActionBar.frameHeight = 196

ActionBar.buttonSize = 52
ActionBar.modelSize = 160
ActionBar.modelOffset = 0.039
ActionBar.modelScale = 0.017
-- Изначальный отступ модели подбирался на экране MacBook Pro (примерно 16:10).
ActionBar.modelReferenceAspect = 16 / 10

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
-- Высота верхнего ряда значков с учётом внутреннего отступа панельки тачпада.
ActionBar.topRowOffsetY = ActionBar.buttonVerticalPadding + ActionBar.buttonSize / 2 + ActionBar.slot12IconPadding

ActionBar.shadowSize = 320
-- Ареол правой группы чуть крупнее, пока в свёрнутом облаке есть дополнительное действие.
ActionBar.shadowSizeWithExtra = 384

ActionBar.animationDuration = 0.05

-- Второй элемент — ключ якоря: right — правая группа, left — левая, bar — сама панель.
ActionBar.buttonPositions = {
    PADRSTICK = { "TOP", "right", "BOTTOM", 0, -ActionBar.buttonVerticalPadding },
    PADLSTICK = { "TOP", "left", "BOTTOM", 0, -ActionBar.buttonVerticalPadding },

    PAD2 = { "LEFT", "right", "RIGHT", ActionBar.buttonHorizontalPadding, 0 },
    PAD3 = { "RIGHT", "right", "LEFT", -ActionBar.buttonHorizontalPadding, 0 },
    PAD4 = { "BOTTOM", "right", "TOP", 0, ActionBar.buttonVerticalPadding },

    PADDUP = { "BOTTOM", "left", "TOP", 0, ActionBar.buttonVerticalPadding },
    PADDRIGHT = { "LEFT", "left", "RIGHT", ActionBar.buttonHorizontalPadding, 0 },
    PADDLEFT = { "RIGHT", "left", "LEFT", -ActionBar.buttonHorizontalPadding, 0 },
    PADDDOWN = { "TOP", "left", "BOTTOM", 0, -ActionBar.buttonVerticalPadding },

    -- Сенсорная панель DualSense: по центру, на высоте верхнего ряда крестовины и лицевых кнопок
    PAD6 = { "CENTER", "bar", "CENTER", 0, ActionBar.topRowOffsetY },
    PADBACK = { "CENTER", "bar", "CENTER", 0, ActionBar.topRowOffsetY },
}

-- Слоты ACTIONBUTTON12 / MULTIACTIONBAR*BUTTON12
ActionBar.slot12Slots = {
    [12] = true,
    [24] = true,
    [60] = true,
    [72] = true,
}

ActionBar.ignoredSlot = {
    [8] = true,
    [20] = true,
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
-- Дополнительная кнопка действия: самый крупный значок в центре облака.
ActionBar.boostExtraCloudSize = 46
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
        if ActionBar.UpdateBoosts then
            ActionBar.UpdateBoosts()
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

-- Кнопка ячейки, если окно панели и сама кнопка существуют.
function ActionBar.GetButton(slotID)
    local frame = ActionBar.GetFrame()
    if not frame or not slotID then
        return nil
    end
    return frame.actionButtons[slotID]
end

-- Смещение и масштаб свечения за один замер экрана, чтобы модель оставалась по центру кнопки.
function ActionBar.GetGlowTransform()
    local offset = ActionBar.modelOffset
    local scale = ActionBar.modelScale
    local width, height = GetPhysicalScreenSize()
    if not width or not height or height == 0 then
        return offset, scale
    end

    local currentAspect = width / height
    if currentAspect <= 0 then
        return offset, scale
    end

    local ratio = ActionBar.modelReferenceAspect / currentAspect
    return offset * ratio, scale * ratio
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

-- Кадр, к которому привязана кнопка: правая группа, левая группа или сама панель.
function ActionBar.ResolveAnchor(frame, anchorKey)
    if not frame then
        return nil
    end
    if anchorKey == "right" then
        return frame.PADCenter
    end
    if anchorKey == "left" then
        return frame.PADDCenter
    end
    if anchorKey == "bar" then
        return frame
    end
    return nil
end

-- Рисунок ячейки. У однокнопочного помощника берётся заклинание, которое будет применено.
-- Второй результат истинен, если клиент скрыл рисунок и трогать кнопку нельзя.
function ActionBar.GetSlotTexture(slotID)
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
