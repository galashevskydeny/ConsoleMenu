-- Показ значков панели: текстура, клавиша, пригодность, свечение, восстановление и счётчик.

local ConsoleMenu = _G.ConsoleMenu
local ActionBar = ConsoleMenu.ActionBar

-- Последняя известная недосягаемость ячейки по событию клиента.
local actionOutOfRange = {}

-- Значение скрыто, по нему нельзя принимать решение.
local function IsSecretValue(value)
    return ActionBar.IsSecretValue(value)
end

-- Запоминает досягаемость только если клиент действительно проверил дальность.
function ActionBar.SetRangeFromEvent(slotID, isInRange, checksRange)
    if not slotID then
        return
    end
    if IsSecretValue(checksRange) or IsSecretValue(isInRange) then
        return
    end

    -- Без проверки (нет цели и т.п.) действие нельзя считать далёким.
    actionOutOfRange[slotID] = checksRange == true and isInRange == false
end

-- Сбрасывает запомненную дальность, чтобы заново опросить клиент.
function ActionBar.ClearRangeState()
    wipe(actionOutOfRange)
end

-- Просит клиент сообщать о смене дальности для ячейки.
function ActionBar.EnableRangeCheck(slotID, enable)
    if not slotID or not C_ActionBar or not C_ActionBar.EnableActionRangeCheck then
        return
    end
    pcall(C_ActionBar.EnableActionRangeCheck, slotID, enable ~= false)
end

-- Включает уведомления о дальности для всех ячеек панели.
function ActionBar.EnableAllRangeChecks()
    local frame = ActionBar.GetFrame()
    if not frame then
        return
    end
    for slotID in pairs(frame.actionButtons) do
        ActionBar.EnableRangeCheck(slotID, true)
    end
end

-- Действие вне зоны досягаемости текущей цели.
local function IsActionOutOfRange(slotID)
    if not slotID then
        return false
    end

    local known = actionOutOfRange[slotID]
    if known ~= nil then
        return known
    end

    if not C_ActionBar or not C_ActionBar.IsActionInRange then
        return false
    end

    local ok, isInRange = pcall(C_ActionBar.IsActionInRange, slotID)
    if not ok or IsSecretValue(isInRange) then
        return false
    end

    -- Пустой ответ значит, что дальность сейчас нельзя определить.
    return isInRange == false
end

-- Безопасный вызов API ячейки.
local function CallSlotApi(fn, ...)
    if not fn then
        return nil
    end
    local ok, result, extra = pcall(fn, ...)
    if not ok then
        return nil
    end
    return result, extra
end

-- Настоящий идентификатор заклинания, а не пустое или скрытое значение.
local function IsValidSpellID(spellID)
    if not spellID or spellID == 0 then
        return false
    end
    if issecretvalue and issecretvalue(spellID) then
        return false
    end
    return true
end

-- Пассивное заклинание нельзя применить с панели.
local function IsPassiveSpellID(spellID)
    if not IsValidSpellID(spellID) or not C_Spell or not C_Spell.IsSpellPassive then
        return false
    end
    return CallSlotApi(C_Spell.IsSpellPassive, spellID) == true
end

-- Идентификатор предмета по названию, если клиент его знает.
local function GetItemIDByName(name)
    if not name or name == "" or not C_Item or not C_Item.GetItemInfoInstant then
        return nil
    end
    local itemID = CallSlotApi(C_Item.GetItemInfoInstant, name)
    if itemID and not (issecretvalue and issecretvalue(itemID)) then
        return itemID
    end
    return nil
end

-- Рисунок надетого предмета и его идентификатор. Сбрасывается при смене экипировки.
local equippedItemByTexture = nil

-- Забывает соответствие рисунка и надетого предмета.
function ActionBar.InvalidateEquippedItemCache()
    equippedItemByTexture = nil
end

-- Собирает рисунки надетых предметов один раз, пока набор не сменится.
-- Если клиент ещё не отдал рисунок, набор не запоминаем и спросим снова.
local function EnsureEquippedItemCache()
    if equippedItemByTexture then
        return equippedItemByTexture
    end

    local cache = {}
    local pending = false
    for inventorySlot = 1, 30 do
        local itemID = GetInventoryItemID("player", inventorySlot)
        local itemTexture = GetInventoryItemTexture("player", inventorySlot)
        if itemID and (not itemTexture or IsSecretValue(itemID) or IsSecretValue(itemTexture)) then
            pending = true
        elseif itemID and itemTexture and not cache[itemTexture] then
            cache[itemTexture] = itemID
        end
    end

    if not pending then
        equippedItemByTexture = cache
    end
    return cache
end

-- Предмет экипировки с той же текстурой, что у ячейки.
local function GetEquippedItemIDForAction(slotID)
    local actionTexture = CallSlotApi(C_ActionBar.GetActionTexture, slotID)
    if not actionTexture or IsSecretValue(actionTexture) then
        return nil
    end

    local cache = EnsureEquippedItemCache()
    return cache and cache[actionTexture]
end

-- Имя предмета внутри макроса ячейки.
local function GetMacroItemNameForSlot(slotID, actionType)
    if actionType ~= "macro" then
        return nil
    end

    local macroName = CallSlotApi(GetActionText, slotID)
    if not macroName or macroName == "" then
        macroName = CallSlotApi(C_ActionBar.GetActionText, slotID)
    end
    if not macroName or macroName == "" then
        return nil
    end

    local itemName = CallSlotApi(GetMacroItem, macroName)
    if itemName == "" then
        return nil
    end
    return itemName
end

-- Заклинание «Использование» предмета или макроса на предмет.
local function GetUseSpellForAction(slotID, actionType, actionID, subType)
    local _, spellID = CallSlotApi(C_Item.GetItemSpell, actionID)
    if IsValidSpellID(spellID) then
        return spellID, actionID
    end

    local title = ConsoleMenu.GetSlotTitle and ConsoleMenu:GetSlotTitle(actionType, actionID, subType, slotID)
    local macroItemName = GetMacroItemNameForSlot(slotID, actionType)
    local resolvedItemID = GetItemIDByName(macroItemName)
        or GetItemIDByName(title)
        or GetEquippedItemIDForAction(slotID)

    if resolvedItemID then
        _, spellID = CallSlotApi(C_Item.GetItemSpell, resolvedItemID)
        return spellID, resolvedItemID
    end

    if macroItemName then
        _, spellID = CallSlotApi(C_Item.GetItemSpell, macroItemName)
        return spellID, nil
    end

    return nil, nil
end

-- Есть ли у ячейки действие применения. Пустая ячейка и заклинание без предмета отвечают по-разному.
-- Пустая ячейка — нет. Заклинание — да. Вызывающий сам решает, красить ли пустую кнопку.
function ActionBar.SlotHasUseAction(slotID)
    if not slotID or not C_ActionBar or not C_ActionBar.HasAction then
        return false
    end
    local hasAction = C_ActionBar.HasAction(slotID)
    if IsSecretValue(hasAction) then
        return true
    end
    if not hasAction then
        return false
    end

    local infoOk, actionType, actionID, subType = pcall(GetActionInfo, slotID)
    if not infoOk then
        return true
    end

    local isItem = actionType == "item" or (actionType == "macro" and subType == "item")
    if not isItem and C_ActionBar.IsItemAction then
        isItem = C_ActionBar.IsItemAction(slotID) == true
    end
    if not isItem then
        return true
    end

    local itemSpellID, resolvedItemID = GetUseSpellForAction(slotID, actionType, actionID, subType)
    if IsValidSpellID(itemSpellID) and not IsPassiveSpellID(itemSpellID) then
        return true
    end
    if resolvedItemID then
        return false
    end

    local spellID = CallSlotApi(C_ActionBar.GetSpell, slotID)
    if not IsValidSpellID(spellID) then
        return false
    end

    local onEquipSpellID = CallSlotApi(C_ActionBar.GetItemActionOnEquipSpellID, slotID)
    if IsValidSpellID(onEquipSpellID) and spellID == onEquipSpellID then
        return false
    end
    if IsPassiveSpellID(spellID) then
        return false
    end
    return true
end

-- Обновление значка клавиши на заполненной ячейке.
local function UpdateActionButtonIcon(slotID)
    local btn = ActionBar.GetButton(slotID)
    if not btn or not btn.Icon or not btn.Icon.Texture or not btn.mainKey then return end

    -- Пока кнопка переворачивается в умение усиления, значок рычага не должен оставаться на фоне.
    if btn.boostFlipLock then
        btn.Icon:Hide()
        return
    end
    local mainKey = btn.mainKey

    -- Для пустых слотов иконку бинда не показываем.
    if not C_ActionBar.HasAction(slotID) then
        ConsoleMenu:AnimatedHide(btn.Icon)
        return
    end

    local shouldShowIcon = (
        mainKey == "PADRSTICK" or
        mainKey == "PADLSTICK" or
        mainKey == "4" or
        mainKey == "5"
    )

    if not shouldShowIcon then
        ConsoleMenu:AnimatedHide(btn.Icon)
        return
    end

    -- Обновление иконки
    local textureInfo = ConsoleMenu.Textures and ConsoleMenu.Textures[mainKey]
    local texture = textureInfo and textureInfo.texture
    if not texture or texture == "" then
        -- Во время боя биндинг/текстура могут обновляться неатомарно.
        -- Не трогаем текущую иконку, чтобы не получать неверное мигание.
        if InCombatLockdown and InCombatLockdown() then
            return
        end
        ConsoleMenu:AnimatedHide(btn.Icon)
        return
    end

    btn.Icon.Texture:SetTexture(texture)
    if mainKey == "PADLSTICK" then
        ActionBar.ApplyKeyGlyphStyle(btn.Icon)
    elseif btn.Icon.Background then
        btn.Icon:SetSize(ActionBar.iconSize, ActionBar.iconSize)
        btn.Icon.Background:Show()
    end
    ConsoleMenu:AnimatedShow(btn.Icon)
end

-- Название действия для слота 12 (PAD6/PADBACK)
local function UpdateSlot12Label(slotID)
    if not ActionBar.slot12Slots[slotID] then
        return
    end

    local btn = ActionBar.GetButton(slotID)
    if not btn or not btn.Label then
        return
    end

    if not C_ActionBar.HasAction(slotID) then
        btn.Label:SetText("")
        return
    end

    local actionType, id, subType = GetActionInfo(slotID)
    local title = ConsoleMenu:GetSlotTitle(actionType, id, subType, slotID)
    btn.Label:SetText(title or "")
end

-- Пока кнопка показывает чужое умение, его свежий рисунок переносится на неё.
local function MirrorFlipFace(slotID, textureFileID)
    if not textureFileID or (issecretvalue and issecretvalue(textureFileID)) then
        return
    end

    local frame = ActionBar.GetFrame()
    if not frame or not frame.actionButtons then
        return
    end

    for _, host in pairs(frame.actionButtons) do
        if host.boostShowingAlt and host.boostFlipSlot == slotID and host.slotID ~= slotID and host.texture then
            host.texture:SetTexture(textureFileID)
            if host.background then
                host.background:Show()
            end
        end
    end
end

-- Обновление текстуры умения на кнопке.
local function UpdateActionButtonTexture(slotID)
    local btn = ActionBar.GetButton(slotID)
    if not btn or not btn.texture then return end
    -- Во время подброса лицо кнопки задаёт переворот, обычное обновление его не затирает.
    if btn.boostFlipLock then
        return
    end

    local textureFileID, textureHidden = ActionBar.GetSlotTexture(slotID)
    if textureHidden then
        -- Во время боя API может вернуть скрытое значение.
        -- В этом случае не трогаем текущее состояние кнопки, чтобы не терять иконки.
        return
    end

    if textureFileID then
        btn.texture:SetTexture(textureFileID)
        btn.background:Show()
        MirrorFlipFace(slotID, textureFileID)
        -- Кнопка будет показана/скрыта в UpdateButtonPositions на основе биндинга
    else
        -- В бою пустой рисунок не значит, что умение исчезло. Иконку и счётчик не трогаем.
        if ActionBar.IsInCombat() then
            return
        end

        btn.texture:SetTexture(nil)
        btn.background:Hide()
        if btn.StackCount then
            ConsoleMenu:AnimatedHide(btn.StackCount)
        end
        if btn.Icon then
            ConsoleMenu:AnimatedHide(btn.Icon)
        end
        if btn.Label then
            btn.Label:SetText("")
        end
    end

    UpdateSlot12Label(slotID)

end

-- Красит одну картинку: серый рисунок у недоступного умения и обычный цвет у готового.
-- Пока монета в воздухе, оттенок ребра не меняем: серый включается отдельно, сразу на новом рисунке.
local function SetIconGray(texture, gray, keepShade)
    if not texture then
        return
    end
    local wasGray = texture.iconGray and true or false
    gray = gray and true or false
    texture.iconGray = gray
    if texture.SetDesaturated then
        texture:SetDesaturated(gray)
    end
    if texture.SetDesaturation then
        texture:SetDesaturation(gray and 1 or 0)
    end
    if keepShade then
        return
    end
    texture:SetVertexColor(1, 1, 1)
    if gray or not wasGray then
        return
    end
    -- Серый иногда остаётся на самом рисунке. Повторная установка картинки снимает его с этой кнопки.
    local file = texture.GetTexture and texture:GetTexture()
    if not file or (issecretvalue and issecretvalue(file)) then
        return
    end
    local c1, c2, c3, c4, c5, c6, c7, c8 = texture:GetTexCoord()
    texture:SetTexture(file)
    if c5 ~= nil then
        texture:SetTexCoord(c1, c2, c3, c4, c5, c6, c7, c8)
    else
        texture:SetTexCoord(c1, c2, c3, c4)
    end
    if texture.SetDesaturated then
        texture:SetDesaturated(false)
    end
    if texture.SetDesaturation then
        texture:SetDesaturation(0)
    end
    texture:SetVertexColor(1, 1, 1)
end

-- Обновление обесцвечивания значка по пригодности, восстановлению и блокировке.
local function UpdateActionButtonTextureDesaturation(btn, slotID, isUsable, isLackingResources)
    if not btn or not btn.texture then
        return
    end

    -- В полёте остаётся блик ребра, но серый рисунок уже соответствует видимой стороне.
    local keepShade = btn.coinInAir or (btn.ctrlFlipOwned and not btn.ctrlFaceSettled)

    -- Предмет без применения всегда обесцвечен. Пустую ячейку этим правилом не красим.
    local hasAction = C_ActionBar and C_ActionBar.HasAction and C_ActionBar.HasAction(slotID)
    if hasAction and not IsSecretValue(hasAction) and not ActionBar.SlotHasUseAction(slotID) then
        SetIconGray(btn.texture, true, keepShade)
        return
    end

    -- Получаем значения пригодности и недостатка маны если не заданы
    if isUsable == nil or isLackingResources == nil then
        if C_ActionBar and C_ActionBar.IsUsableAction then
            isUsable, isLackingResources = C_ActionBar.IsUsableAction(slotID)
        else
            isUsable, isLackingResources = true, false -- fallback
        end
    end

    -- Серым умение делает только своё восстановление. Общее восстановление и застывший кадр таймера цвет не держат.
    local onCooldown = false
    if C_ActionBar and C_ActionBar.GetActionCooldown then
        local info = C_ActionBar.GetActionCooldown(slotID)
        if info and info.isActive and not info.isOnGCD then
            onCooldown = true
        end
    end

    local gray = not (isUsable and not IsActionOutOfRange(slotID) and not onCooldown)

    if not gray and C_LevelLink and C_LevelLink.IsActionLocked then
        gray = C_LevelLink.IsActionLocked(slotID) and true or false
    end

    -- Правый рычаг раскрывает облако на крестовине: квадрат, треугольник и круг основной панели остаются серыми.
    -- Пока основная иконка сама переворачивается в умение усиления, её не обесцвечиваем.
    if not gray and not btn.boostFlipLock and btn.mainKey and ActionBar.IsMainFaceButtonKey(btn.mainKey) and not btn.modifierKey and ActionBar.ShouldGrayFaceButtons() then
        gray = true
    end

    SetIconGray(btn.texture, gray, keepShade)
end

-- Обновление пригодности кнопки к применению.
local function UpdateActionButtonUsable(slotID, isUsable, isLackingResources)
    local btn = ActionBar.GetButton(slotID)
    if not btn or not btn.texture then return end

    if btn.boostShowingAlt and btn.boostFlipSlot then
        UpdateActionButtonTextureDesaturation(btn, btn.boostFlipSlot)
        return
    end

    UpdateActionButtonTextureDesaturation(btn, slotID, isUsable, isLackingResources)

    local frame = ActionBar.GetFrame()
    if not frame or not frame.actionButtons then
        return
    end

    for _, host in pairs(frame.actionButtons) do
        if host ~= btn and host.boostShowingAlt and host.boostFlipSlot == slotID then
            UpdateActionButtonTextureDesaturation(host, slotID)
        end
    end
end

-- Заново красит все кнопки панели, чтобы серый цвет одной не остался на соседней.
local function RepaintButtonColors()
    local frame = ActionBar.GetFrame()
    if not frame or not frame.actionButtons then
        return
    end
    for slotID in pairs(frame.actionButtons) do
        UpdateActionButtonUsable(slotID)
    end
end

-- Заново красит или обесцвечивает квадрат, треугольник и круг после нажатия и отпускания правого рычага.
function ActionBar.RefreshFaceButtonDesaturation()
    local frame = ActionBar.GetFrame()
    if not frame then
        return
    end

    for slotID, btn in pairs(frame.actionButtons) do
        if ActionBar.IsMainFaceButtonKey(btn.mainKey) and not btn.modifierKey then
            UpdateActionButtonUsable(slotID)
        end
    end
end

-- Обновление пригодности всех ячеек панели и значков облака.
function ActionBar.UpdateAllUsable()
    local frame = ActionBar.GetFrame()
    if not frame then
        return
    end

    for slotID in pairs(frame.actionButtons) do
        UpdateActionButtonUsable(slotID)
    end
end

-- Готовит слой свечения: рисунок, золотой цвет и круговое проигрывание кадров.
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

-- Готовит одноразовую вспышку из записанного цикла поверх контура.
local function StartGlowBurst(texture)
    texture:SetTexture(ActionBar.glowBurstTexture)
    texture:SetBlendMode("ADD")
    texture:SetVertexColor(1, 1, 1, 1)
    texture:SetSize(ActionBar.glowBurstSize, ActionBar.glowBurstSize)
    texture:SetPoint("CENTER")
    texture:SetAlpha(0)

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

-- Останавливает вспышку на экране. Повторный показ кнопки её не запускает заново.
local function StopGlowBurst(glow)
    if not glow then
        return
    end
    local burst = glow.Burst
    if not burst or not burst.sheet then
        return
    end
    burst.sheet:Stop()
    burst:SetAlpha(0)
end

-- Запускает вспышку только в момент загорания свечения и только на видимой кнопке.
local function PlayGlowBurst(glow)
    local burst = glow and glow.Burst
    if not burst or glow.burstPlayed or not glow:IsVisible() then
        return
    end
    glow.burstPlayed = true
    burst:SetAlpha(1)
    burst.sheet:Stop()
    burst.sheet:Play()
end

-- Продолжает проигрывание, если кадр был скрыт и анимация остановилась.
local function KeepGlowSheetsPlaying(glow)
    if glow.Ring and glow.Ring.sheet and not glow.Ring.sheet:IsPlaying() then
        glow.Ring.sheet:Play()
    end
    if glow.Body and glow.Body.sheet and not glow.Body.sheet:IsPlaying() then
        glow.Body.sheet:Play()
    end
    if glow.Core and glow.Core.sheet and not glow.Core.sheet:IsPlaying() then
        glow.Core.sheet:Play()
    end
end

-- Держит свечение над рисунком умения, а счётчик и значок клавиши — над свечением.
local function PlaceActionButtonGlow(btn)
    local glow = btn.Glow
    if not glow then
        return
    end

    local level = btn:GetFrameLevel()
    glow:SetFrameLevel(level + 1)
    if btn.StackCount then
        btn.StackCount:SetFrameLevel(level + 2)
    end
    if btn.Icon then
        btn.Icon:SetFrameLevel(level + 3)
    end
end

-- Смягчение с перелётом, как у значка в облаке усилений.
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

-- Уменьшение ускоряется и садится ровно в цель, без проскока ниже неё.
local function EaseIn(t)
    if t <= 0 then
        return 0
    end
    if t >= 1 then
        return 1
    end
    return t * t
end

-- Сдвиг начинается быстро и замедляется ровно к цели, без проскока за неё.
local function EaseOut(t)
    if t <= 0 then
        return 0
    end
    if t >= 1 then
        return 1
    end
    local remain = 1 - t
    return 1 - remain * remain
end

-- Размер на пути. Перелёт только когда иконка растёт из-за своего свечения.
-- Возврат к обычному размеру и уменьшение идут с ускорением, без проскока.
local function BubbleSize(origin, target, life)
    local glowSize = ActionBar.buttonSize + (ActionBar.glowGrowSize or 6)
    if target <= origin or math.abs(target - glowSize) > 0.5 then
        return origin + (target - origin) * EaseIn(life)
    end
    local scale = EaseOutBack(life)
    if scale < 0 then
        scale = 0
    end
    local pop = scale - 1
    if pop < 0 then
        pop = 0
    end
    local puff = ActionBar.buttonSize * pop
    return origin + (target - origin) * scale + puff
end

-- Кнопка ещё кувыркается: её картинку в этот момент меняет переворот.
local function ButtonSizeLocked(btn)
    return btn.coinInAir or (btn.ctrlFlipOwned and not btn.ctrlFaceSettled)
end

-- Обычный размер кольца свечения вокруг картинки.
local function BaseGlowSize()
    return ActionBar.buttonSize * ActionBar.glowScale - 2
end

-- Правая группа, левая группа или центр панели. Чужое свечение размер не меняет.
local function ButtonGlowGroup(btn)
    local position = btn.mainKey and ActionBar.buttonPositions[btn.mainKey]
    return position and position[2] or nil
end

-- Кнопка занимает место на панели, а не просто ещё не успела погаснуть.
local function ShiftButtonVisible(btn)
    if not btn then
        return false
    end
    if ActionBar.IsShiftButtonVisible then
        return ActionBar.IsShiftButtonVisible(btn)
    end
    return btn:IsShown()
end

-- В каких группах сейчас горит хотя бы одно свечение на видимой кнопке.
local function GlowingGroups(buttons)
    local groups = {}
    for _, btn in pairs(buttons) do
        if btn.glowReady and ShiftButtonVisible(btn) then
            local group = ButtonGlowGroup(btn)
            if group then
                groups[group] = true
            end
        end
    end
    return groups
end

-- К какому размеру картинки стремится кнопка.
local function IconTargetSize(btn, glowingGroups)
    if not ShiftButtonVisible(btn) then
        return ActionBar.buttonSize
    end
    if btn.glowReady then
        return ActionBar.buttonSize + (ActionBar.glowGrowSize or 6)
    end
    local group = ButtonGlowGroup(btn)
    if group and glowingGroups[group] then
        return ActionBar.buttonSize - (ActionBar.glowShrinkSize or 6)
    end
    return ActionBar.buttonSize
end

-- Оси двух крестов. Сверху напротив снизу, справа напротив слева.
-- Низ левой крестовины — левый рычаг, а не отдельная нижняя кнопка.
local shiftAxes = {
    { group = "right", axis = "y", positive = "PAD4", negative = "PADRSTICK" },
    { group = "right", axis = "x", positive = "PAD2", negative = "PAD3" },
    { group = "left", axis = "y", positive = "PADDUP", negative = "PADLSTICK" },
    { group = "left", axis = "x", positive = "PADDRIGHT", negative = "PADDLEFT" },
}

-- Кнопки, которые входят в крест и могут сдвинуться.
local shiftMembers = {
    PAD4 = true,
    PADRSTICK = true,
    PAD2 = true,
    PAD3 = true,
    PADDUP = true,
    PADLSTICK = true,
    PADDRIGHT = true,
    PADDLEFT = true,
    PADDDOWN = true,
}

-- Левый рычаг сейчас на панели: он и есть низ крестовины.
local function StickIsShown(buttons)
    for _, btn in pairs(buttons) do
        if btn.mainKey == "PADLSTICK" and ShiftButtonVisible(btn) and not ActionBar.IsBoostSlot(btn.slotID) then
            return true
        end
    end
    return false
end

-- Кнопка занимает низ крестовины: левый рычаг, а если его нет — нижняя кнопка.
local function IsBottomOccupant(btn, buttons)
    if not btn or ActionBar.IsBoostSlot(btn.slotID) then
        return false
    end
    if btn.mainKey == "PADLSTICK" then
        return true
    end
    return btn.mainKey == "PADDDOWN" and not StickIsShown(buttons)
end

-- Кнопка принадлежит кресту лицевых кнопок или крестовины.
local function IsShiftMember(btn, buttons)
    if not btn or not btn.mainKey or ActionBar.IsBoostSlot(btn.slotID) then
        return false
    end
    if btn.mainKey == "PADDDOWN" then
        return IsBottomOccupant(btn, buttons)
    end
    return shiftMembers[btn.mainKey] == true
end

-- Эта сторона оси сейчас горит на видимой кнопке.
local function PoleGlows(buttons, key)
    local stickShown = key == "PADLSTICK" and StickIsShown(buttons)
    for _, btn in pairs(buttons) do
        if btn.glowReady and ShiftButtonVisible(btn) and not ActionBar.IsBoostSlot(btn.slotID) then
            if key == "PADLSTICK" then
                if stickShown and btn.mainKey == "PADLSTICK" then
                    return true
                end
                if not stickShown and btn.mainKey == "PADDDOWN" then
                    return true
                end
            elseif btn.mainKey == key then
                return true
            end
        end
    end
    return false
end

-- Место кнопки на кресте: верх и право считаются положительными.
local function ButtonCrossSign(btn)
    local key = btn.mainKey
    if key == "PAD4" or key == "PADDUP" then
        return 0, 1
    end
    if key == "PADRSTICK" or key == "PADLSTICK" or key == "PADDDOWN" then
        return 0, -1
    end
    if key == "PAD2" or key == "PADDRIGHT" then
        return 1, 0
    end
    if key == "PAD3" or key == "PADDLEFT" then
        return -1, 0
    end
    return 0, 0
end

-- Шаг к противоположной стороне сразу по вертикали и по горизонтали.
local function AddShiftToward(shiftX, shiftY, btn, oppositeX, oppositeY, distance)
    local buttonX, buttonY = ButtonCrossSign(btn)
    if oppositeX ~= buttonX then
        shiftX = shiftX + (oppositeX > buttonX and distance or -distance)
    end
    if oppositeY ~= buttonY then
        shiftY = shiftY + (oppositeY > buttonY and distance or -distance)
    end
    return shiftX, shiftY
end

-- Кнопка стоит на указанной стороне оси.
local function IsPoleButton(btn, key, buttons)
    if key == "PADLSTICK" then
        return IsBottomOccupant(btn, buttons)
    end
    return btn.mainKey == key
end

-- Облако уже село на крестовину и занимает её место целиком.
local function CloudStandsOnCross()
    if not ActionBar.BoostFlipOwnsHosts or not ActionBar.BoostFlipOwnsHosts() then
        return false
    end
    local frame = ActionBar.GetFrame()
    local boosts = frame and frame.boosts
    if not boosts then
        return false
    end
    local settle = ActionBar.boostFlipSettle or 0.72
    return (boosts.progress or 0) >= settle
end

-- Облако считается светящимся, если готов хотя бы один его значок.
local function CloudGlows(buttons)
    for _, btn in pairs(buttons) do
        if btn.glowReady then
            if btn.slotID and (ActionBar.IsBoostSlot(btn.slotID) or ActionBar.IsExtraActionSlot(btn.slotID)) then
                return true
            end
            if btn.boostShowingAlt and ActionBar.IsBoostHostKey and ActionBar.IsBoostHostKey(btn.mainKey) then
                return true
            end
        end
    end
    return false
end

-- На крестовине горит хотя бы одна её собственная кнопка.
local function CrossHasGlow(buttons, group)
    for _, btn in pairs(buttons) do
        if btn.glowReady and ShiftButtonVisible(btn) and ButtonGlowGroup(btn) == group and IsShiftMember(btn, buttons) then
            return true
        end
    end
    return false
end

-- Сдвиг к центру крестовины, когда напротив стоит всё облако.
local function ShiftTowardCloud(btn, distance)
    if btn.mainKey == "PADDUP" then
        return 0, -distance
    end
    if btn.mainKey == "PADLSTICK" or btn.mainKey == "PADDDOWN" then
        return 0, distance
    end
    if btn.mainKey == "PADDRIGHT" then
        return -distance, 0
    end
    if btn.mainKey == "PADDLEFT" then
        return distance, 0
    end
    return 0, 0
end

-- Видимый левый рычаг. Нижняя кнопка креста делит с ним одно место.
local function FindShownStick(buttons)
    for _, btn in pairs(buttons) do
        if btn.mainKey == "PADLSTICK" and ShiftButtonVisible(btn) and not ActionBar.IsBoostSlot(btn.slotID) then
            return btn
        end
    end
    return nil
end

-- Куда подъехать тёмной кнопке. Светящаяся и тёмная противоположная остаются на месте.
local function ButtonShiftTarget(btn, buttons)
    -- Скрытая страница не хранит чужой сдвиг: иначе он всплывёт при смене страницы.
    if not ShiftButtonVisible(btn) then
        return 0, 0
    end
    -- Нижняя кнопка не отдельная сторона. Своё свечение её удерживает, иначе она едет с рычагом.
    if btn.mainKey == "PADDDOWN" and StickIsShown(buttons) then
        if btn.glowReady then
            return 0, 0
        end
        local stick = FindShownStick(buttons)
        if not stick or stick.glowReady then
            return 0, 0
        end
        btn = stick
    end
    if not IsShiftMember(btn, buttons) or btn.glowReady then
        return 0, 0
    end
    local group = ButtonGlowGroup(btn)
    if group ~= "left" and group ~= "right" then
        return 0, 0
    end

    local distance = ActionBar.glowShiftSize or 6
    if distance < 0 then
        distance = 0
    end

    -- На месте крестовины облако: оно одно напротив, и светится целиком.
    if group == "left" and CloudStandsOnCross() then
        if CloudGlows(buttons) or not CrossHasGlow(buttons, group) then
            return 0, 0
        end
        return ShiftTowardCloud(btn, distance)
    end

    local shiftX, shiftY = 0, 0
    for index = 1, #shiftAxes do
        local axis = shiftAxes[index]
        if axis.group == group then
            local positiveGlows = PoleGlows(buttons, axis.positive)
            local negativeGlows = PoleGlows(buttons, axis.negative)
            local towardNegative = positiveGlows and not negativeGlows
            local towardPositive = negativeGlows and not positiveGlows
            local blocked = false
            local oppositeX, oppositeY = 0, 0
            if towardNegative then
                blocked = IsPoleButton(btn, axis.negative, buttons)
                if axis.axis == "y" then
                    oppositeY = -1
                else
                    oppositeX = -1
                end
            elseif towardPositive then
                blocked = IsPoleButton(btn, axis.positive, buttons)
                if axis.axis == "y" then
                    oppositeY = 1
                else
                    oppositeX = 1
                end
            end
            if (towardNegative or towardPositive) and not blocked then
                shiftX, shiftY = AddShiftToward(shiftX, shiftY, btn, oppositeX, oppositeY, distance)
            end
        end
    end
    return shiftX, shiftY
end

-- Ставит кнопку на место раскладки и добавляет только временный сдвиг.
local function ApplyButtonShift(btn, shiftX, shiftY)
    btn.glowShiftX = shiftX
    btn.glowShiftY = shiftY
    if ButtonSizeLocked(btn) then
        return
    end
    local position = btn.mainKey and ActionBar.buttonPositions[btn.mainKey]
    if not position then
        return
    end
    local frame = ActionBar.GetFrame()
    local anchor = frame and ActionBar.ResolveAnchor(frame, position[2])
    if not anchor then
        return
    end
    btn:ClearAllPoints()
    btn:SetPoint(position[1], anchor, position[3], position[4] + shiftX, position[5] + shiftY)
end

-- Текущий сдвиг поверх раскладки, чтобы обновление мест его не стирало.
function ActionBar.ButtonGlowShift(btn)
    if not btn then
        return 0, 0
    end
    return btn.glowShiftX or 0, btn.glowShiftY or 0
end

-- Смещение начинается быстро и замедляется ровно к цели.
local function ShiftOffset(origin, target, life)
    return (origin or 0) + ((target or 0) - (origin or 0)) * EaseOut(life or 0)
end

-- Ставит размер картинки, подложки и кольца. Значок клавиши и счётчик не меняются.
local function ApplyGlowButtonSize(btn, size)
    local texture = btn.texture
    if not texture or size < 1 then
        return
    end

    local wide = ActionBar.slot12Slots and ActionBar.slot12Slots[btn.slotID]
    if not wide then
        texture:ClearAllPoints()
        texture:SetPoint("CENTER", btn, "CENTER", 0, 0)
        if btn.background then
            btn.background:SetSize(size + 8, size + 8)
        end
    end
    texture:SetSize(size, size)

    if btn.Glow then
        local glowSize = BaseGlowSize() + (size - ActionBar.buttonSize)
        if glowSize < 1 then
            glowSize = 1
        end
        btn.Glow:SetSize(glowSize, glowSize)
    end
end

local glowSizeDriver

-- Доводит размеры кнопок до цели и засыпает, когда все уже сели.
local function StepGlowButtonSizes(_, elapsed)
    local frame = ActionBar.GetFrame()
    local buttons = frame and frame.actionButtons
    if not buttons then
        glowSizeDriver:Hide()
        return
    end

    local glowingGroups = GlowingGroups(buttons)
    local duration = ActionBar.glowMotionDuration or 0.11
    if duration < 0.01 then
        duration = 0.11
    end
    local busy = false

    for _, btn in pairs(buttons) do
        if ButtonSizeLocked(btn) then
            btn.glowSizeRestart = true
            btn.glowShiftRestart = true
            busy = true
        else
            if btn.texture then
                local target = IconTargetSize(btn, glowingGroups)
                local life = btn.glowBubbleLife
                local arrived = btn.glowBubbleTarget == target and (life or 0) >= 1
                if btn.glowSizeRestart or not arrived then
                    if btn.glowSizeRestart or btn.glowBubbleTarget ~= target then
                        btn.glowSizeRestart = nil
                        btn.glowBubbleOrigin = btn.texture:GetWidth()
                        btn.glowBubbleTarget = target
                        if math.abs(btn.glowBubbleOrigin - target) < 0.05 then
                            btn.glowBubbleLife = 1
                            ApplyGlowButtonSize(btn, target)
                        else
                            btn.glowBubbleLife = 0
                            busy = true
                        end
                    else
                        btn.glowBubbleLife = math.min(1, (life or 0) + (elapsed or 0) / duration)
                        ApplyGlowButtonSize(btn, BubbleSize(btn.glowBubbleOrigin, btn.glowBubbleTarget, btn.glowBubbleLife))
                        if btn.glowBubbleLife < 1 then
                            busy = true
                        end
                    end
                end
            end

            local shiftX, shiftY = ButtonShiftTarget(btn, buttons)
            local shiftLife = btn.glowShiftLife
            local shiftArrived = btn.glowShiftTargetX == shiftX and btn.glowShiftTargetY == shiftY and (shiftLife or 0) >= 1
            if btn.glowShiftRestart or not shiftArrived then
                if btn.glowShiftRestart or btn.glowShiftTargetX ~= shiftX or btn.glowShiftTargetY ~= shiftY then
                    btn.glowShiftRestart = nil
                    btn.glowShiftOriginX = btn.glowShiftX or 0
                    btn.glowShiftOriginY = btn.glowShiftY or 0
                    btn.glowShiftTargetX = shiftX
                    btn.glowShiftTargetY = shiftY
                    if math.abs(btn.glowShiftOriginX - shiftX) < 0.05 and math.abs(btn.glowShiftOriginY - shiftY) < 0.05 then
                        btn.glowShiftLife = 1
                        ApplyButtonShift(btn, shiftX, shiftY)
                    else
                        btn.glowShiftLife = 0
                        busy = true
                    end
                else
                    btn.glowShiftLife = math.min(1, (shiftLife or 0) + (elapsed or 0) / duration)
                    ApplyButtonShift(
                        btn,
                        ShiftOffset(btn.glowShiftOriginX, shiftX, btn.glowShiftLife),
                        ShiftOffset(btn.glowShiftOriginY, shiftY, btn.glowShiftLife)
                    )
                    if btn.glowShiftLife < 1 then
                        busy = true
                    end
                end
            end
        end
    end

    if not busy then
        glowSizeDriver:Hide()
    end
end

-- Запускает вспухание размеров, если кнопки ещё не пришли к нужному размеру.
function ActionBar.SyncGlowButtonSizes()
    if not glowSizeDriver then
        glowSizeDriver = CreateFrame("Frame")
        glowSizeDriver:Hide()
        glowSizeDriver:SetScript("OnUpdate", StepGlowButtonSizes)
    end
    local frame = ActionBar.GetFrame()
    local buttons = frame and frame.actionButtons
    if buttons then
        local glowingGroups = GlowingGroups(buttons)
        for _, btn in pairs(buttons) do
            local target = IconTargetSize(btn, glowingGroups)
            local width = btn.texture and btn.texture:GetWidth() or target
            local arrived = btn.glowBubbleTarget == target and (btn.glowBubbleLife or 0) >= 1
            if ButtonSizeLocked(btn) or btn.glowBubbleTarget ~= target or (arrived and math.abs(width - target) >= 0.05) then
                btn.glowSizeRestart = true
            end

            local shiftX, shiftY = ButtonShiftTarget(btn, buttons)
            local sameShift = btn.glowShiftTargetX == shiftX and btn.glowShiftTargetY == shiftY
            local shiftArrived = sameShift and (btn.glowShiftLife or 0) >= 1
            local currentX = btn.glowShiftX or 0
            local currentY = btn.glowShiftY or 0
            local shiftDrifted = math.abs(currentX - shiftX) >= 0.05 or math.abs(currentY - shiftY) >= 0.05
            if ButtonSizeLocked(btn) or not sameShift or (shiftArrived and shiftDrifted) then
                btn.glowShiftRestart = true
            end
        end
    end
    glowSizeDriver:Show()
end

-- Облако село на крестовину или ушло с неё: сдвиг нужно пересчитать, даже если свечение не менялось.
local cloudOnCrossKnown = false
local cloudWasOnCross = false

function ActionBar.NoteCloudOnCross()
    local standing = CloudStandsOnCross()
    if cloudOnCrossKnown and cloudWasOnCross == standing then
        return
    end
    -- Первый замер в покое кнопки не трогает. Посадка и уход облака заново считают сдвиг.
    local changed = cloudOnCrossKnown or standing
    cloudWasOnCross = standing
    cloudOnCrossKnown = true
    if changed then
        ActionBar.SyncGlowButtonSizes()
    end
end

-- Запоминает, горит ли свечение, и просит остальные кнопки подстроить размер.
-- Вспышка забывается только когда готовность правда погасла, а не когда кадр спрятали.
local function NoteGlowReady(btn, ready)
    btn.glowReady = ready and true or false
    if not btn.glowReady and btn.Glow then
        btn.Glow.burstPlayed = nil
    end
    ActionBar.SyncGlowButtonSizes()
end

-- Тень выше обычных кнопок, а горящая кнопка — выше своей тени, чтобы тёмный центр её не закрыл.
local GLOW_SHADOW_LEVEL = 4
local GLOW_BUTTON_LEVEL = 10

-- Мягкая тень вокруг готовой иконки. Рисуется отдельно, чтобы лечь на соседние кнопки.
local function EnsureGlowShadow(btn)
    if btn.glowShadow then
        return btn.glowShadow
    end

    local shadow = CreateFrame("Frame", nil, btn:GetParent())
    shadow:SetFrameStrata(btn:GetFrameStrata())
    shadow:EnableMouse(false)
    shadow:SetAlpha(0)
    shadow:Hide()

    local texture = shadow:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    texture:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png")

    ConsoleMenu:InitFadeAnimations(shadow, 0.2)
    -- После свечения тень уходит быстрее, чем появляется.
    shadow.fadeOut.alpha:SetDuration(0.1)
    shadow.glowButton = btn
    btn.glowShadow = shadow
    return shadow
end

-- Подброс сам держит уровень кнопки: свечение в этот момент его не меняет.
local function CoinOwnsLevel(btn)
    return btn.coinBaseLevel ~= nil
end

-- Опускает кнопку, когда тень уже не должна лежать поверх её иконки.
local function ReleaseGlowButtonLevel(btn)
    if not btn or not btn.glowLevelRaised or CoinOwnsLevel(btn) or ButtonSizeLocked(btn) then
        return
    end
    local rest = btn.glowRestLevel
    if not rest then
        return
    end
    btn:SetFrameLevel(rest)
    btn.glowLevelRaised = nil
    PlaceActionButtonGlow(btn)
end

-- Исходный уровень для подброса: не тот, на который кнопку подняло свечение.
function ActionBar.ButtonRestFrameLevel(btn)
    if btn and btn.glowLevelRaised and btn.glowRestLevel then
        return btn.glowRestLevel
    end
    return btn and btn:GetFrameLevel() or 0
end

-- Гасит тень сразу и снимает незаконченное проявление.
local function HideGlowShadowNow(shadow)
    if shadow.fadeIn then
        shadow.fadeIn:Stop()
    end
    if shadow.fadeOut then
        shadow.fadeOut:Stop()
        shadow.fadeOut:SetScript("OnFinished", nil)
    end
    shadow:SetAlpha(0)
    shadow:Hide()
end

-- Показывает или убирает тень. Пока кнопка кувыркается, её уровень не трогаем.
local function SetGlowShadow(btn, shown, instant)
    if shown and not btn:IsShown() then
        shown = false
        instant = true
    end
    if not shown and instant and btn.glowShadow and not btn.glowShadow:IsShown() then
        ReleaseGlowButtonLevel(btn)
        return
    end
    if not shown and not btn.glowShadow then
        ReleaseGlowButtonLevel(btn)
        return
    end

    local shadow = EnsureGlowShadow(btn)
    local rest = btn.glowRestLevel or btn:GetFrameLevel()
    local anchor = btn.texture or btn
    shadow:ClearAllPoints()
    shadow:SetPoint("CENTER", anchor, "CENTER", 0, 0)
    shadow:SetSize(ActionBar.glowShadowSize, ActionBar.glowShadowSize)
    shadow:SetFrameLevel(rest + GLOW_SHADOW_LEVEL)
    local shadowAlpha = ActionBar.glowShadowAlpha
    if not shadowAlpha or shadowAlpha > 1 then
        shadowAlpha = 1
    elseif shadowAlpha < 0 then
        shadowAlpha = 0
    end
    shadow.fadeAlpha = shadowAlpha

    local levelLocked = ButtonSizeLocked(btn) or CoinOwnsLevel(btn)
    if shown then
        if not levelLocked then
            btn:SetFrameLevel(rest + GLOW_BUTTON_LEVEL)
            btn.glowLevelRaised = true
        end
        ConsoleMenu:AnimatedShow(shadow)
    elseif instant then
        HideGlowShadowNow(shadow)
        ReleaseGlowButtonLevel(btn)
    else
        -- Кнопка остаётся выше тени, пока та гаснет, иначе тёмный центр накроет иконку.
        ConsoleMenu:AnimatedHide(shadow)
        if shadow.fadeOut and shadow.fadeOut:IsPlaying() then
            shadow.fadeOut:SetScript("OnFinished", function()
                shadow:Hide()
                shadow.fadeOut:SetScript("OnFinished", nil)
                shadow.fadeOut.alpha:SetFromAlpha(shadow.fadeAlpha or 1)
                shadow.fadeOut.alpha:SetToAlpha(0)
                ReleaseGlowButtonLevel(shadow.glowButton)
            end)
        else
            ReleaseGlowButtonLevel(btn)
        end
    end

    if not levelLocked then
        PlaceActionButtonGlow(btn)
    end
end

ActionBar.SetGlowShadow = SetGlowShadow

-- Обновление свечения готовности на кнопке.
local function UpdateActionButtonGlow(slotID, spellID, event)
    local btn = ActionBar.GetButton(slotID)
    if not btn then return end

    -- Пока монета в воздухе, кольцо и тень не показываем, но готовность для соседей обновляем.
    local inAir = btn.coinInAir or (btn.ctrlFlipOwned and not btn.ctrlFaceSettled)

    local paintSlot = slotID
    if btn.boostShowingAlt and btn.boostFlipSlot then
        paintSlot = btn.boostFlipSlot
    end

    -- Свечение чужого умения не должно загораться на перевёрнутой кнопке.
    if spellID and paintSlot ~= slotID then
        local actionType, actionID = GetActionInfo(paintSlot)
        local hidden = issecretvalue and (issecretvalue(spellID) or (actionID and issecretvalue(actionID)))
        if actionType == "spell" and not hidden and actionID ~= spellID then
            return
        end
    end

    if not btn.boostShowingAlt then
        local frame = ActionBar.GetFrame()
        if frame and frame.actionButtons then
            for _, host in pairs(frame.actionButtons) do
                if host ~= btn and host.ctrlFlipOwned and host.boostFlipSlot == slotID then
                    UpdateActionButtonGlow(host.slotID, spellID, event)
                end
            end
        end
    end

    -- Кольцо под двумя слоями крутящегося контура: мягкое золото и светлое ядро.
    if not btn.Glow then
        local glow = CreateFrame("Frame", nil, btn)
        -- На пару пикселей меньше расчётного размера, чтобы контур не казался крупным.
        local glowSize = ActionBar.buttonSize * ActionBar.glowScale - 2
        glow:SetSize(glowSize, glowSize)
        glow:SetFrameStrata(btn:GetFrameStrata())
        glow:SetAlpha(0)
        glow:Hide()

        glow.Ring = glow:CreateTexture(nil, "ARTWORK", nil, -1)
        StartGlowSheet(glow.Ring, ActionBar.glowRingTexture, "ADD", ActionBar.glowBodyColor, ActionBar.glowRingDuration)
        glow.Body = glow:CreateTexture(nil, "ARTWORK")
        StartGlowSheet(glow.Body, ActionBar.glowBodyTexture, "BLEND", ActionBar.glowBodyColor)
        glow.Core = glow:CreateTexture(nil, "OVERLAY")
        StartGlowSheet(glow.Core, ActionBar.glowCoreTexture, "ADD", ActionBar.glowCoreColor)
        glow.Burst = glow:CreateTexture(nil, "OVERLAY", nil, 1)
        StartGlowBurst(glow.Burst)
        glow:SetScript("OnHide", StopGlowBurst)

        ConsoleMenu:InitFadeAnimations(glow, ActionBar.animationDuration)
        btn.Glow = glow
    end

    local anchor = btn.texture or btn
    btn.Glow:ClearAllPoints()
    btn.Glow:SetPoint("CENTER", anchor, "CENTER", 0, 0)
    PlaceActionButtonGlow(btn)

    -- Если spellID не передан, пытаемся получить его из слота
    if not spellID then
        local actionType, id, _ = GetActionInfo(paintSlot)
        
        -- Если это не заклинание и не макрос, скрываем свечение.
        if actionType ~= "spell" and actionType ~= "macro" then
            NoteGlowReady(btn, false)
            if inAir then
                if btn.Glow then
                    btn.Glow:Hide()
                end
                SetGlowShadow(btn, false, true)
            else
                ConsoleMenu:AnimatedHide(btn.Glow)
                SetGlowShadow(btn, false)
            end
            return
        end

        spellID = id
    end

    -- Если spellID найден, проверяем актуальное состояние overlay
    if spellID then
        local isSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed(spellID)
        if isSpellOverlayed then
            NoteGlowReady(btn, true)
            if inAir then
                btn.Glow:Hide()
                SetGlowShadow(btn, false, true)
                return
            end
            -- Иконка слота часто меняется вместе с проком.
            UpdateActionButtonTexture(slotID)
            ConsoleMenu:AnimatedShow(btn.Glow)
            SetGlowShadow(btn, true)
            KeepGlowSheetsPlaying(btn.Glow)
            PlayGlowBurst(btn.Glow)
        else
            NoteGlowReady(btn, false)
            if inAir then
                btn.Glow:Hide()
                SetGlowShadow(btn, false, true)
                return
            end
            ConsoleMenu:AnimatedHide(btn.Glow)
            SetGlowShadow(btn, false)
            -- После исчезновения свечения клиент ещё может отдавать иконку прока.
            RunNextFrame(function()
                UpdateActionButtonTexture(slotID)
            end)
        end
    else
        NoteGlowReady(btn, false)
        if inAir then
            btn.Glow:Hide()
            SetGlowShadow(btn, false, true)
            return
        end
        ConsoleMenu:AnimatedHide(btn.Glow)
        SetGlowShadow(btn, false)
        RunNextFrame(function()
            UpdateActionButtonTexture(slotID)
        end)
    end
end

-- Ячейка, которую кнопка показывает сейчас: своя или оборотная после переворота.
local function VisibleCooldownSlot(btn, slotID)
    if btn and btn.boostShowingAlt and btn.boostFlipSlot then
        return btn.boostFlipSlot
    end
    return slotID
end

-- Ставит время восстановления на видимую сторону. На ребре цифры ещё скрыты, с новым рисунком они уже видны.
local function SyncButtonCooldown(btn, rebuild)
    if not btn or not btn.cooldown then
        return
    end

    -- Оборванный подброс не должен навсегда прятать цифры на панели.
    if not btn.coinActive then
        btn.coinInAir = nil
        if btn.ctrlFlipOwned and not btn.ctrlFaceSettled then
            btn.ctrlFlipOwned = nil
        end
    end

    local inFlight = btn.coinInAir or (btn.ctrlFlipOwned and not btn.ctrlFaceSettled)
    if inFlight and not btn.coinTimerReady then
        btn.cooldown:SetAlpha(0)
        if btn.cooldown:IsShown() then
            btn.cooldown:Hide()
        end
        return
    end

    local slotID = VisibleCooldownSlot(btn, btn.slotID)
    if inFlight then
        -- Цифры стоят на кнопке, а не на тонком ребре, и появляются вместе с серым рисунком.
        if btn.coinTimerAnchor ~= "button" then
            btn.cooldown:ClearAllPoints()
            btn.cooldown:SetPoint("CENTER", btn, "CENTER", 0, 0)
            btn.cooldown:SetSize(ActionBar.buttonSize, ActionBar.buttonSize)
            btn.coinTimerAnchor = "button"
            rebuild = true
        end
    elseif btn.texture and (rebuild or btn.coinTimerAnchor == "button") then
        btn.cooldown:ClearAllPoints()
        btn.cooldown:SetAllPoints(btn.texture)
        btn.cooldown:Show()
        btn.coinTimerAnchor = "texture"
        rebuild = true
    end

    local info = C_ActionBar and C_ActionBar.GetActionCooldown and C_ActionBar.GetActionCooldown(slotID)
    btn.coinTimerSlot = slotID

    if info and info.isActive then
        local duration = C_ActionBar.GetActionCooldownDuration(slotID)
        if duration then
            btn.cooldown:SetCooldownFromDurationObject(duration)
            btn.cooldown:Show()
        end
    else
        btn.cooldown:Clear()
    end
    btn.cooldown:SetAlpha(1)
    UpdateActionButtonTextureDesaturation(btn, slotID)
end

-- Обновление восстановления и пригодности всех кнопок.
local function UpdateActionButtonCooldowns()
    local frame = ActionBar.GetFrame()
    if not frame then
        return
    end

    for _, btn in pairs(frame.actionButtons) do
        SyncButtonCooldown(btn)
    end
end

-- Обновление счётчика зарядов на кнопке.
local function UpdateActionButtonCount(slotID)
    local btn = ActionBar.GetButton(slotID)
    if not btn or not btn.StackCount or not btn.StackCount.Text then return end

    if not btn.boostShowingAlt then
        local frame = ActionBar.GetFrame()
        if frame and frame.actionButtons then
            for _, host in pairs(frame.actionButtons) do
                if host ~= btn and host.boostShowingAlt and host.boostFlipSlot == slotID then
                    UpdateActionButtonCount(host.slotID)
                end
            end
        end
    end

    local countSlot = slotID
    if btn.boostShowingAlt and btn.boostFlipSlot then
        countSlot = btn.boostFlipSlot
    end
    if ActionBar.ChargeActionChanged(countSlot) then
        ActionBar.ForgetChargeCount(countSlot)
    end

    -- В самом начале подброса число ещё скрыто. В бою уже известный счётчик не гасим.
    local tossHidesCount = not btn.coinCountReady and (btn.coinInAir or (btn.ctrlFlipOwned and not btn.ctrlFaceSettled))
    local knownDuringToss = ActionBar.SlotHasChargeCounter(countSlot) or ActionBar.SavedChargeText(countSlot) ~= nil
    if tossHidesCount and not (ActionBar.IsInCombat() and knownDuringToss) then
        if btn.StackCount:IsShown() then
            if btn.StackCount.fadeOut then
                btn.StackCount.fadeOut:Stop()
                btn.StackCount.fadeOut:SetScript("OnFinished", nil)
            end
            btn.StackCount:Hide()
        end
        return
    end

    local count = ActionBar.ReadDisplayCount(countSlot)

    local function ShowStack()
        if not btn.coinCountReady then
            ConsoleMenu:AnimatedShow(btn.StackCount)
            return
        end
        if btn.StackCount.fadeIn then
            btn.StackCount.fadeIn:Stop()
        end
        if btn.StackCount.fadeOut then
            btn.StackCount.fadeOut:Stop()
            btn.StackCount.fadeOut:SetScript("OnFinished", nil)
        end
        btn.StackCount:SetAlpha(1)
        btn.StackCount:Show()
    end

    local flipping = btn.coinActive or btn.ctrlFlipOwned
    local known = ActionBar.SlotHasChargeCounter(countSlot) or ActionBar.SavedChargeText(countSlot) ~= nil

    local function HideStack(unknown)
        if ActionBar.IsInCombat() and known then
            local saved = ActionBar.SavedChargeText(countSlot)
            if saved ~= nil then
                btn.StackCount.Text:SetText(saved)
            end
            ActionBar.stackCountChange[countSlot] = true
            btn.stackCountSlot = countSlot
            ShowStack()
            ActionBar.FinishCountRead(countSlot)
            return
        end
        if btn.stackCountSlot == countSlot then
            btn.stackCountSlot = nil
        end
        btn.StackCount.Text:SetText("")
        ConsoleMenu:AnimatedHide(btn.StackCount)
        ActionBar.FinishCountRead(countSlot, unknown)
    end

    -- В бою и на возврате с переворота оставляем последнее число, не затирая память о счётчике.
    local function KeepKnownCount()
        if not known then
            return false
        end
        local saved = ActionBar.SavedChargeText(countSlot)
        if saved ~= nil then
            btn.StackCount.Text:SetText(saved)
        elseif not (btn.stackCountSlot == countSlot and btn.StackCount:IsShown()) then
            return false
        end
        ActionBar.stackCountChange[countSlot] = true
        btn.stackCountSlot = countSlot
        ShowStack()
        ActionBar.FinishCountRead(countSlot, count == nil)
        return true
    end

    if IsSecretValue(count) then
        -- Скрытое число клиент рисует сам, поэтому в бою цифры продолжают меняться.
        if not known then
            HideStack(false)
            return
        end
        btn.StackCount.Text:SetText(count)
        ActionBar.stackCountChange[countSlot] = true
        btn.stackCountSlot = countSlot
        ShowStack()
        ActionBar.FinishCountRead(countSlot)
        return
    end

    if ActionBar.HasVisibleChargeCount(count) then
        ActionBar.RememberChargeSlot(countSlot, count)
        btn.StackCount.Text:SetText(count)
        ActionBar.stackCountChange[countSlot] = true
        btn.stackCountSlot = countSlot
        ShowStack()
        ActionBar.FinishCountRead(countSlot)
    elseif btn.coinCountLatched and btn.stackCountSlot == countSlot and btn.StackCount:IsShown() then
        -- Пустой ответ посреди кувырка не гасит уже показанное число этого же умения.
    elseif flipping and KeepKnownCount() then
        -- Лицевая сторона после Ctrl снова показывает своё число.
    elseif ActionBar.IsInCombat() and KeepKnownCount() then
        -- В бою пустой или нулевой ответ не убирает уже видимый счётчик.
    elseif not flipping and not ActionBar.IsInCombat() and (count == 0 or count == "0" or ActionBar.ShouldForgetChargeCount(count)) then
        -- Цифры прячем, но ячейка по-прежнему умеет показывать заряды.
        ActionBar.ClearChargeText(countSlot)
        HideStack(false)
    elseif not known then
        HideStack(count == nil)
    elseif ActionBar.stackCountChange[countSlot] then
        ShowStack()
    elseif count == nil then
        HideStack(true)
    else
        HideStack(false)
    end
end

-- Обновление значков при смене страницы панели.
local function UpdateActionBarPageVisibility()
    if not ActionBar.GetFrame() then
        return
    end

    for slotID = 1, 24 do
        UpdateActionButtonTexture(slotID)
        UpdateActionButtonCount(slotID)
    end
    -- Эквиваленты слота 12 на панелях с модификаторами
    UpdateActionButtonTexture(60)
    UpdateActionButtonCount(60)
    UpdateActionButtonTexture(72)
    UpdateActionButtonCount(72)
    ActionBar.EnableAllRangeChecks()
    ActionBar.UpdateButtonPositions()
    ActionBar.UpdateModifierState()
    ActionBar.UpdateAllUsable()
end

ActionBar.UpdateIcon = UpdateActionButtonIcon
ActionBar.UpdateSlot12Label = UpdateSlot12Label
ActionBar.UpdateTexture = UpdateActionButtonTexture
ActionBar.SetIconGray = SetIconGray
ActionBar.RepaintButtonColors = RepaintButtonColors
ActionBar.UpdateTextureDesaturation = UpdateActionButtonTextureDesaturation
ActionBar.SyncButtonCooldown = SyncButtonCooldown
ActionBar.UpdateUsable = UpdateActionButtonUsable
ActionBar.UpdateGlow = UpdateActionButtonGlow
ActionBar.UpdateCooldowns = UpdateActionButtonCooldowns
ActionBar.UpdateCount = UpdateActionButtonCount
ActionBar.UpdatePageVisibility = UpdateActionBarPageVisibility
