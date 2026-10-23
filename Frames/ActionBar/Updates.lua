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
    for _, btn in pairs(frame.actionButtons) do
        local slots = btn.IconFrame and btn.IconFrame.slots
        if slots then
            if slots.base then
                ActionBar.EnableRangeCheck(slots.base, true)
            end
            if slots.SHIFT then
                ActionBar.EnableRangeCheck(slots.SHIFT, true)
            end
            if slots.CTRL then
                ActionBar.EnableRangeCheck(slots.CTRL, true)
            end
            if slots.ALT then
                ActionBar.EnableRangeCheck(slots.ALT, true)
            end
        elseif btn.slotID then
            ActionBar.EnableRangeCheck(btn.slotID, true)
        end
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
local equippedCachePending = false
local equipCacheTries = 0
local equipCacheRetryQueued = false
local useActionBySlot = {}
local EQUIP_CACHE_RETRY_LIMIT = 3

-- Забывает соответствие рисунка и надетого предмета, а с ним и ответы о применении.
function ActionBar.InvalidateEquippedItemCache()
    equippedItemByTexture = nil
    equippedCachePending = false
    equipCacheTries = 0
    equipCacheRetryQueued = false
    wipe(useActionBySlot)
end

-- Забывает ответ о применении одной ячейки или всех, если ячейка не указана.
function ActionBar.ForgetUseAction(slotID)
    if slotID then
        useActionBySlot[slotID] = nil
    else
        wipe(useActionBySlot)
    end
end

-- Дописывает уже известные рисунки. Скрытый ответ не стирает то, что успели запомнить.
local function CollectEquippedItems()
    local cache = equippedItemByTexture
    if not cache then
        cache = {}
        equippedItemByTexture = cache
    end

    local pending = false
    for inventorySlot = 1, 30 do
        local itemID = GetInventoryItemID("player", inventorySlot)
        local itemTexture = GetInventoryItemTexture("player", inventorySlot)
        if itemID and (not itemTexture or IsSecretValue(itemID) or IsSecretValue(itemTexture)) then
            pending = true
        elseif itemID and itemTexture then
            cache[itemTexture] = itemID
        end
    end

    equippedCachePending = pending
    return cache
end

-- Ещё одна попытка дописать скрытые рисунки. Потолок попыток не даёт крутиться каждый кадр.
local function ScheduleEquipCacheRetry()
    if equipCacheRetryQueued or not equippedCachePending or equipCacheTries >= EQUIP_CACHE_RETRY_LIMIT then
        return
    end
    if not RunNextFrame then
        return
    end
    equipCacheRetryQueued = true
    equipCacheTries = equipCacheTries + 1
    RunNextFrame(function()
        equipCacheRetryQueued = false
        if not equippedCachePending then
            return
        end
        CollectEquippedItems()
        wipe(useActionBySlot)
        if equippedCachePending then
            ScheduleEquipCacheRetry()
        end
    end)
end

-- Возвращает уже собранное соответствие. Повторный обход всех вещей на каждой ячейке не нужен.
local function EnsureEquippedItemCache()
    if equippedItemByTexture then
        return equippedItemByTexture
    end
    local cache = CollectEquippedItems()
    if equippedCachePending then
        ScheduleEquipCacheRetry()
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
local function SlotHasUseActionUncached(slotID)
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
        -- Предмет ещё мог не загрузиться: такой ответ не запоминаем.
        return false, true
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

-- Ответ о применении помним, пока не сменится ячейка или надетые предметы.
function ActionBar.SlotHasUseAction(slotID)
    if not slotID or not C_ActionBar or not C_ActionBar.HasAction then
        return false
    end
    local known = useActionBySlot[slotID]
    if known ~= nil then
        return known
    end
    local result, uncertain = SlotHasUseActionUncached(slotID)
    result = result and true or false
    if not uncertain then
        useActionBySlot[slotID] = result
    end
    return result
end

-- Обновление значка клавиши на заполненной ячейке.
local function UpdateActionButtonIcon(slotID)
    if ActionBar.UpdateButton then
        ActionBar.UpdateButton(slotID)
        return
    end
    local btn = ActionBar.GetButton(slotID)
    if not btn or not btn.Icon or not btn.Icon.Texture or not btn.mainKey then return end

    -- Пока кнопка переворачивается в умение усиления, значок рычага не должен оставаться на фоне.
    if btn.boostFlipLock then
        btn.Icon:Hide()
        return
    end
    -- Для пустых слотов иконку бинда не показываем.
    if not C_ActionBar.HasAction(slotID) then
        ConsoleMenu:AnimatedHide(btn.Icon)
        return
    end

    local glyphKey = nil
    if btn.mainKey == ActionBar.rightStickKey then
        glyphKey = ActionBar.rightStickKey
    elseif btn.baseFromStick and not btn.heldModifier then
        glyphKey = ActionBar.leftStickKey
    end

    if not glyphKey then
        ConsoleMenu:AnimatedHide(btn.Icon)
        return
    end

    -- Обновление иконки
    local textureInfo = ConsoleMenu.Textures and ConsoleMenu.Textures[glyphKey]
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
    if glyphKey == ActionBar.leftStickKey then
        ActionBar.ApplyKeyGlyphStyle(btn.Icon)
    elseif btn.Icon.Background then
        btn.Icon:SetSize(ActionBar.iconSize, ActionBar.iconSize)
        btn.Icon.Background:Show()
    end
    ConsoleMenu:AnimatedShow(btn.Icon)
end

local slot12MeasureLabel
local slot12MeasureTries = {}
local UpdateSlot12Label

-- Отдельная строка для замера: у видимой подписи ширина уже ограничена островком.
local function Slot12MeasureLabel()
    if slot12MeasureLabel then
        return slot12MeasureLabel
    end

    local holder = CreateFrame("Frame", nil, UIParent)
    holder:SetSize(4, 4)
    holder:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", -200, -200)
    holder:SetAlpha(0)
    holder:Show()

    slot12MeasureLabel = holder:CreateFontString(nil, "OVERLAY")
    slot12MeasureLabel:SetFont("Fonts\\FRIZQT___CYR.TTF", ActionBar.slot12LabelFontSize, "")
    slot12MeasureLabel:SetWordWrap(false)
    slot12MeasureLabel:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
    slot12MeasureLabel:Show()
    return slot12MeasureLabel
end

-- Ширина строки без переноса, в пикселях шрифта подписи островка.
local function LabelTextWidth(text)
    local measure = Slot12MeasureLabel()
    measure:SetText(text or "")
    local width = 0
    if measure.GetUnboundedStringWidth then
        width = measure:GetUnboundedStringWidth() or 0
    end
    if width <= 0 and measure.GetStringWidth then
        width = measure:GetStringWidth() or 0
    end
    if width < 0 then
        width = 0
    end
    return width
end

-- Наименьшая ширина, при которой название умещается в две строки и слова не рвутся.
local function Slot12TextWidth(title)
    if not title or title == "" or ActionBar.IsSecretValue(title) then
        return 0
    end

    local spans = {}
    local startAt = 1
    while true do
        local fromIndex, toIndex = string.find(title, "%S+", startAt)
        if not fromIndex then
            break
        end
        spans[#spans + 1] = { fromIndex = fromIndex, toIndex = toIndex }
        startAt = toIndex + 1
    end

    local count = #spans
    if count == 0 then
        return 0
    end

    local function LineWidth(first, last)
        return LabelTextWidth(string.sub(title, spans[first].fromIndex, spans[last].toIndex))
    end

    if count == 1 then
        return LineWidth(1, 1)
    end

    local best = LineWidth(1, count)
    for split = 1, count - 1 do
        local left = LineWidth(1, split)
        local right = LineWidth(split + 1, count)
        local need = left
        if right > need then
            need = right
        end
        if need < best then
            best = need
        end
    end
    return best
end

-- Расширяет островок, если иначе слово не помещается в строку целиком.
local function ApplySlot12Width(btn, title)
    local label = btn and btn.Label
    if not label then
        return
    end

    if ActionBar.IsSecretValue(title) then
        label:SetText(title)
        return
    end

    local textWidth = Slot12TextWidth(title)
    local pending = textWidth <= 0 and title ~= "" and not ActionBar.IsSecretValue(title)
    if pending then
        local tries = slot12MeasureTries[btn] or 0
        if tries < 5 then
            slot12MeasureTries[btn] = tries + 1
            RunNextFrame(function()
                if btn.slotID then
                    UpdateSlot12Label(btn.slotID)
                end
            end)
        end
    else
        slot12MeasureTries[btn] = nil
    end

    -- Небольшой запас, чтобы последнее слово не перескочило из-за округления.
    if textWidth > 0 then
        textWidth = textWidth + 2
    end

    local width = ActionBar.Slot12ChromeWidth() + textWidth
    if width < ActionBar.slot12ContainerWidth then
        width = ActionBar.slot12ContainerWidth
    end
    local maxWidth = ActionBar.Slot12MaxWidth and ActionBar.Slot12MaxWidth() or width
    if width > maxWidth then
        width = maxWidth
    end
    width = math.floor(width + 0.5)

    if math.abs((btn:GetWidth() or 0) - width) > 0.5
        or math.abs((btn:GetHeight() or 0) - ActionBar.slot12ContainerHeight) > 0.5
    then
        btn:SetSize(width, ActionBar.slot12ContainerHeight)
    end
    label:SetText(title or "")
end

-- Название действия для островка тачпада. Берётся у той стороны, которая сейчас видна.
function UpdateSlot12Label(slotID)
    if not ActionBar.slot12Slots[slotID] then
        return
    end

    local btn = ActionBar.GetButton(slotID)
    if not btn or not btn.Label then
        return
    end

    local faceSlot = slotID
    if btn.boostShowingAlt and btn.boostFlipSlot then
        faceSlot = btn.boostFlipSlot
    end
    btn.slot12TitleSlot = faceSlot

    local title = ""
    if C_ActionBar.HasAction(faceSlot) then
        local actionType, id, subType = GetActionInfo(faceSlot)
        title = ConsoleMenu:GetSlotTitle(actionType, id, subType, faceSlot) or ""
    end
    ApplySlot12Width(btn, title)
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
            if host.Label then
                UpdateSlot12Label(host.slotID)
            end
        end
    end
end

-- Обновление текстуры умения на кнопке.
local function UpdateActionButtonTexture(slotID)
    if ActionBar.UpdateButton then
        ActionBar.UpdateButton(slotID)
        return
    end
    local btn = ActionBar.GetButton(slotID)
    if not btn or not btn.texture then return end
    -- Во время подброса лицо кнопки задаёт переворот, обычное обновление его не затирает.
    if btn.flipBusy or btn.boostShowingAlt or btn.boostFlipLock then
        return
    end

    local textureFileID, textureHidden = ActionBar.GetSlotTexture(slotID)
    if textureHidden then
        -- Во время боя API может вернуть скрытое значение.
        -- В этом случае не трогаем текущее состояние кнопки, чтобы не терять иконки.
        return
    end

    if textureFileID then
        btn.homeTexture = textureFileID
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

-- Нужно ли обесцветить видимую способность по пригодности, дальности и модификатору.
function ActionBar.IconNeedsDesaturation(btn, slotID, isUsable, isLackingResources)
    if not btn or not slotID then
        return false
    end

    -- Предмет без применения всегда обесцвечен. Пустую ячейку этим правилом не красим.
    local hasAction = C_ActionBar and C_ActionBar.HasAction and C_ActionBar.HasAction(slotID)
    if hasAction and not IsSecretValue(hasAction) and not ActionBar.SlotHasUseAction(slotID) then
        return true
    end

    if isUsable == nil or isLackingResources == nil then
        if C_ActionBar and C_ActionBar.IsUsableAction then
            isUsable, isLackingResources = C_ActionBar.IsUsableAction(slotID)
        else
            isUsable, isLackingResources = true, false
        end
    end

    -- Серым умение делает только своё восстановление. Общее восстановление цвет не держит.
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

    -- Пока кнопка переходит на способность модификатора, отсутствие сочетания её не обесцвечивает.
    if not gray and btn.heldGray then
        gray = true
    end

    if not gray and not btn.flipBusy and not btn.boostShowingAlt and btn.mainKey and ActionBar.IsMainFaceButtonKey and ActionBar.IsMainFaceButtonKey(btn.mainKey) and not btn.modifierKey and ActionBar.ShouldGrayFaceButtons and ActionBar.ShouldGrayFaceButtons() then
        gray = true
    end

    return gray
end

-- Обновление обесцвечивания значка облака. Кнопка панели красит себя сама.
local function UpdateActionButtonTextureDesaturation(btn, slotID, isUsable, isLackingResources)
    if not btn or not btn.texture then
        return
    end
    if btn.IconFrame and btn.IconFrame.EnableDesaturation then
        return
    end

    local keepShade = btn.flipBusy or btn.coinActive or btn.coinInAir or (btn.ctrlFlipOwned and not btn.ctrlFaceSettled)
    local gray = ActionBar.IconNeedsDesaturation(btn, slotID, isUsable, isLackingResources)
    SetIconGray(btn.texture, gray, keepShade)
end

-- Обновление пригодности кнопки к применению.
local function UpdateActionButtonUsable(slotID, isUsable, isLackingResources)
    if ActionBar.UpdateButton then
        ActionBar.UpdateButton(slotID, nil, isUsable, isLackingResources)
        return
    end
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
    for _, btn in pairs(frame.actionButtons) do
        if btn.slotID then
            UpdateActionButtonUsable(btn.slotID)
        end
    end
end

-- Заново красит или обесцвечивает квадрат, треугольник и круг после нажатия и отпускания правого рычага.
function ActionBar.RefreshFaceButtonDesaturation()
    local frame = ActionBar.GetFrame()
    if not frame then
        return
    end

    for _, btn in pairs(frame.actionButtons) do
        if btn.slotID and ActionBar.IsMainFaceButtonKey(btn.mainKey) and not btn.modifierKey then
            UpdateActionButtonUsable(btn.slotID)
        end
    end
end

-- Обновление пригодности всех ячеек панели и значков облака.
function ActionBar.UpdateAllUsable()
    local frame = ActionBar.GetFrame()
    if not frame then
        return
    end

    for _, btn in pairs(frame.actionButtons) do
        if btn.slotID then
            UpdateActionButtonUsable(btn.slotID)
        end
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

-- Держит свечение над рисунком умения, а счётчик с тенью и значок клавиши — над свечением.
local function PlaceActionButtonGlow(btn)
    local glow = btn.Glow
    if not glow then
        return
    end

    local level = btn:GetFrameLevel()
    glow:SetFrameLevel(level + 2)
    if glow.Spin then
        glow.Spin:SetFrameLevel(level + 2)
    end
    if glow.BurstFrame then
        glow.BurstFrame:SetFrameLevel(level + 2)
    end
    if btn.cooldown then
        btn.cooldown:SetFrameLevel(level + 3)
    end
    if btn.StackCount then
        btn.StackCount:SetFrameLevel(level + 5)
    end
    if btn.Icon then
        btn.Icon:SetFrameLevel(level + 6)
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

-- Размер на пути. Рост из-за свечения чуть перелетает цель и садится.
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
    return origin + (target - origin) * scale
end

-- Кнопка ещё кувыркается: её картинку в этот момент меняет переворот.
local function ButtonSizeLocked(btn)
    return btn.flipBusy or btn.coinActive or btn.coinInAir or (btn.ctrlFlipOwned and not btn.ctrlFaceSettled)
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
    if ActionBar.slot12Slots and ActionBar.slot12Slots[btn.slotID] then
        return ActionBar.buttonSize
    end
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

-- Ставит размер картинки, подложки и кольца. Значок клавиши и счётчик не меняются.
local function ApplyGlowButtonSize(btn, size)
    if ActionBar.SetButtonPictureSize then
        ActionBar.SetButtonPictureSize(btn, size)
        return
    end
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

-- Увеличение до штатного размера, а не рост из-за своего свечения и не уменьшение.
local function SizeReturnsHome(origin, target)
    local standard = ActionBar.buttonSize or 0
    return (target or 0) > (origin or 0) and math.abs((target or 0) - standard) <= 0.5
end

-- Возврат домой и движения при свечении длятся разное время.
local function GlowStepDuration(home)
    local duration = home and ActionBar.glowHomeDuration or ActionBar.glowMotionDuration
    if not duration or duration < 0.01 then
        duration = home and ActionBar.glowMotionDuration or 0.11
    end
    if not duration or duration < 0.01 then
        duration = 0.11
    end
    return duration
end

-- Доводит размеры кнопок до цели и засыпает, когда спокойным кнопкам больше некуда ехать.
local function StepGlowButtonSizes(_, elapsed)
    local frame = ActionBar.GetFrame()
    local buttons = frame and frame.actionButtons
    if not buttons then
        glowSizeDriver:Hide()
        return
    end

    local glowingGroups = GlowingGroups(buttons)
    local busy = false

    for _, btn in pairs(buttons) do
        if ButtonSizeLocked(btn) then
            -- Кувырок сам попросит размер, когда рисунок ляжет. Из-за него кадр не держим.
            btn.glowSizeRestart = true
        elseif btn.texture and not btn.glowReady then
            local target = IconTargetSize(btn, glowingGroups)
            local life = btn.glowBubbleLife
            local arrived = btn.glowBubbleTarget == target and (life or 0) >= 1
            if btn.glowSizeRestart or not arrived then
                local sameTarget = btn.glowBubbleTarget == target
                local lifeNow = life or 0
                -- Уже едет к этой цели или уже села: повтор не начинает вспухание сначала.
                if btn.glowSizeRestart and sameTarget and lifeNow > 0 then
                    btn.glowSizeRestart = nil
                    if lifeNow >= 1 then
                        ApplyGlowButtonSize(btn, target)
                    else
                        local duration = GlowStepDuration(SizeReturnsHome(btn.glowBubbleOrigin, target))
                        btn.glowBubbleLife = math.min(1, lifeNow + (elapsed or 0) / duration)
                        ApplyGlowButtonSize(btn, BubbleSize(btn.glowBubbleOrigin, btn.glowBubbleTarget, btn.glowBubbleLife))
                        if btn.glowBubbleLife < 1 then
                            busy = true
                        end
                    end
                elseif btn.glowSizeRestart or not sameTarget then
                    btn.glowSizeRestart = nil
                    btn.glowBubbleOrigin = btn.texture:GetWidth()
                    btn.glowBubbleTarget = target
                    -- Уже почти у цели: повторный запрос не проигрывает вспухание заново.
                    if math.abs(btn.glowBubbleOrigin - target) < 2 then
                        btn.glowBubbleLife = 1
                        ApplyGlowButtonSize(btn, target)
                    else
                        btn.glowBubbleLife = 0
                        busy = true
                    end
                else
                    local duration = GlowStepDuration(SizeReturnsHome(btn.glowBubbleOrigin, target))
                    btn.glowBubbleLife = math.min(1, (life or 0) + (elapsed or 0) / duration)
                    ApplyGlowButtonSize(btn, BubbleSize(btn.glowBubbleOrigin, btn.glowBubbleTarget, btn.glowBubbleLife))
                    if btn.glowBubbleLife < 1 then
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
            local sameTarget = btn.glowBubbleTarget == target
            local arrived = sameTarget and (btn.glowBubbleLife or 0) >= 1
            local knockedAway = math.abs(width - target) >= 2
            if not btn.glowReady and (ButtonSizeLocked(btn) or not sameTarget or (arrived and knockedAway)) then
                btn.glowSizeRestart = true
            end
        end
    end
    glowSizeDriver:Show()
end

-- Запоминает, горит ли свечение, и просит остальные кнопки подстроить размер.
-- Вспышка забывается только когда готовность правда погасла, а не когда кадр спрятали.
local function NoteGlowReady(btn, ready)
    ready = ready and true or false
    local changed = btn.glowReady ~= ready
    btn.glowReady = ready
    if not btn.glowReady and btn.Glow then
        btn.Glow.burstPlayed = nil
    end
    if changed then
        ActionBar.SyncGlowButtonSizes()
    end
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

-- Пока рисунок крутится, запоминает, должно ли гореть кольцо, и не показывает его.
local function RememberGlowWhileTossing(btn, shown)
    if (btn.flipBusy or btn.coinInAir) and ActionBar.SetButtonGlowShown then
        ActionBar.SetButtonGlowShown(btn, shown)
        return
    end
    if btn.Glow then
        btn.Glow:Hide()
    end
end

-- Обновление свечения готовности на кнопке.
local function UpdateActionButtonGlow(slotID, spellID, event)
    if ActionBar.UpdateButton then
        ActionBar.UpdateButton(slotID, spellID, nil, nil, event)
        return
    end
    local btn = ActionBar.GetButton(slotID)
    if not btn then return end

    -- Пока монета в воздухе, кольцо и тень не показываем, но готовность для соседей обновляем.
    local inAir = btn.flipBusy or btn.coinInAir or (btn.ctrlFlipOwned and not btn.ctrlFaceSettled)

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
                RememberGlowWhileTossing(btn, false)
                SetGlowShadow(btn, false, true)
            else
                ActionBar.SetButtonGlowShown(btn, false)
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
                RememberGlowWhileTossing(btn, true)
                SetGlowShadow(btn, false, true)
                return
            end
            -- Иконка слота часто меняется вместе с проком.
            UpdateActionButtonTexture(slotID)
            ActionBar.SetButtonGlowShown(btn, true)
            SetGlowShadow(btn, true)
            KeepGlowSheetsPlaying(btn.Glow)
            PlayGlowBurst(btn.Glow)
        else
            local wasReady = btn.glowReady and true or false
            NoteGlowReady(btn, false)
            if inAir then
                RememberGlowWhileTossing(btn, false)
                SetGlowShadow(btn, false, true)
                return
            end
            ActionBar.SetButtonGlowShown(btn, false)
            SetGlowShadow(btn, false)
            -- После исчезновения свечения клиент ещё может отдавать иконку прока.
            if wasReady then
                RunNextFrame(function()
                    UpdateActionButtonTexture(slotID)
                end)
            end
        end
    else
        local wasReady = btn.glowReady and true or false
        NoteGlowReady(btn, false)
        if inAir then
            RememberGlowWhileTossing(btn, false)
            SetGlowShadow(btn, false, true)
            return
        end
        ActionBar.SetButtonGlowShown(btn, false)
        SetGlowShadow(btn, false)
        if wasReady then
            RunNextFrame(function()
                UpdateActionButtonTexture(slotID)
            end)
        end
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
    if btn and btn.Update then
        btn:Update()
        return
    end
    if not btn or not btn.cooldown then
        return
    end

    -- Оборванный подброс не должен навсегда прятать цифры на панели.
    if not btn.coinActive and not btn.flipBusy then
        btn.coinInAir = nil
        if btn.ctrlFlipOwned and not btn.ctrlFaceSettled then
            btn.ctrlFlipOwned = nil
        end
    end

    local inFlight = btn.flipBusy or btn.coinActive or btn.coinInAir or (btn.ctrlFlipOwned and not btn.ctrlFaceSettled)
    if inFlight and not btn.coinTimerReady then
        if btn.cooldown:IsShown() then
            btn.cooldown:Clear()
            btn.cooldown:Hide()
        end
        btn.cooldown:SetAlpha(0)
        return
    end

    local slotID = VisibleCooldownSlot(btn, btn.slotID)
    if inFlight then
        -- Цифры стоят на месте значка, а не на тонком ребре, и появляются вместе с новой стороной.
        if btn.coinTimerAnchor ~= "button" then
            btn.cooldown:ClearAllPoints()
            local wide = ActionBar.slot12Slots and ActionBar.slot12Slots[btn.slotID]
            if wide and ActionBar.Slot12IconCenterOffset then
                btn.cooldown:SetPoint("CENTER", btn, "LEFT", ActionBar.Slot12IconCenterOffset(), 0)
            else
                btn.cooldown:SetPoint("CENTER", btn, "CENTER", 0, 0)
            end
            btn.cooldown:SetSize(ActionBar.buttonSize, ActionBar.buttonSize)
            btn.coinTimerAnchor = "button"
        end
    elseif btn.texture and btn.coinTimerAnchor ~= "texture" then
        btn.cooldown:ClearAllPoints()
        btn.cooldown:SetAllPoints(btn.texture)
        btn.coinTimerAnchor = "texture"
    end

    local info = C_ActionBar and C_ActionBar.GetActionCooldown and C_ActionBar.GetActionCooldown(slotID)
    btn.coinTimerSlot = slotID
    local ownCooldown = info and info.isActive and not info.isOnGCD
    if ownCooldown and C_ActionBar.GetActionCooldownDuration then
        local duration = C_ActionBar.GetActionCooldownDuration(slotID)
        if duration then
            btn.cooldown:SetCooldownFromDurationObject(duration)
            btn.cooldown:Show()
            btn.cooldown:SetAlpha(1)
        end
    else
        btn.cooldown:Clear()
        btn.cooldown:Hide()
        btn.cooldown:SetAlpha(0)
    end
    UpdateActionButtonTextureDesaturation(btn, slotID)
end

-- Обновление восстановления и пригодности всех кнопок.
local function UpdateActionButtonCooldowns()
    if ActionBar.UpdateAllButtons then
        ActionBar.UpdateAllButtons()
        return
    end
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
    if ActionBar.UpdateButton then
        ActionBar.UpdateButton(slotID)
        return
    end
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
    local tossHidesCount = not btn.coinCountReady and (btn.flipBusy or btn.coinActive or btn.coinInAir or (btn.ctrlFlipOwned and not btn.ctrlFaceSettled))
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
    ActionBar.ForgetUseAction()

    if ActionBar.UpdateAllButtons then
        ActionBar.UpdateAllButtons()
    end
    ActionBar.EnableAllRangeChecks()
    ActionBar.UpdateButtonPositions()
    ActionBar.UpdateModifierState()
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
