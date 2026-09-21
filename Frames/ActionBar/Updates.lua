-- Показ значков панели: текстура, клавиша, пригодность, свечение, восстановление и счётчик.

local ConsoleMenu = _G.ConsoleMenu
local ActionBar = ConsoleMenu.ActionBar

-- Проверка, является ли кулдаун глобальным кулдауном (GCD)
-- ВАЖНО: isOnGCD помечено как NeverSecret = true, поэтому безопасно для чтения
local function IsGlobalCooldown(slotID)
    if not slotID or not C_ActionBar or not C_ActionBar.GetActionCooldown then
        return false;
    end
    
    local cooldownInfo = C_ActionBar.GetActionCooldown(slotID);
    if cooldownInfo and cooldownInfo.isOnGCD then
        return true;
    end
    
    return false;
end

-- Последняя известная недосягаемость ячейки по событию клиента.
local actionOutOfRange = {}

-- Значение скрыто, по нему нельзя принимать решение.
local function IsSecretValue(value)
    return value ~= nil and issecretvalue and issecretvalue(value)
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

-- Предмет экипировки с той же текстурой, что у ячейки.
local function GetEquippedItemIDForAction(slotID)
    local actionTexture = CallSlotApi(C_ActionBar.GetActionTexture, slotID)
    if not actionTexture or (issecretvalue and issecretvalue(actionTexture)) then
        return nil
    end

    for inventorySlot = 1, 30 do
        local itemID = GetInventoryItemID("player", inventorySlot)
        local itemTexture = GetInventoryItemTexture("player", inventorySlot)
        if itemID and itemTexture == actionTexture then
            return itemID
        end
    end
    return nil
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

-- Есть ли у ячейки действие применения. Для заклинаний всегда да.
function ActionBar.SlotHasUseAction(slotID)
    if not slotID or not C_ActionBar or not C_ActionBar.HasAction then
        return true
    end
    if not C_ActionBar.HasAction(slotID) then
        return true
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

-- Обновление текстуры умения на кнопке.
local function UpdateActionButtonTexture(slotID)
    local btn = ActionBar.GetButton(slotID)
    if not btn or not btn.texture then return end

    local textureFileID = nil

    -- Однокнопочный помощник (Assisted Combat): иконка должна соответствовать заклинанию, которое будет применено
    if C_ActionBar and C_ActionBar.IsAssistedCombatAction and C_ActionBar.IsAssistedCombatAction(slotID) then
        if C_AssistedCombat and C_Spell then
            -- В бою — следующее заклинание в ротации; вне боя — текущее заклинание помощника
            local spellID = C_AssistedCombat.GetNextCastSpell and C_AssistedCombat.GetNextCastSpell(true)

            if spellID then
                textureFileID = C_Spell.GetSpellTexture(spellID)
            end
        end
    end

    if not textureFileID then
        textureFileID = C_ActionBar.GetActionTexture(slotID)
    end

    if issecretvalue(textureFileID) then
        -- Во время боя API может вернуть secret-значение.
        -- В этом случае не трогаем текущее состояние кнопки, чтобы не терять иконки.
        return
    end

    if textureFileID then
        btn.texture:SetTexture(textureFileID)
        btn.background:Show()
        -- Кнопка будет показана/скрыта в UpdateButtonPositions на основе биндинга
    else
        -- В бою API иногда временно возвращает nil даже для заполненного слота.
        -- В этом случае сохраняем текущую иконку, чтобы она не исчезала визуально.
        if InCombatLockdown and InCombatLockdown() and C_ActionBar.HasAction(slotID) then
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

-- Обновление обесцвечивания значка по пригодности, восстановлению и блокировке.
local function UpdateActionButtonTextureDesaturation(btn, slotID, isUsable, isLackingResources)
    if not btn or not btn.texture then
        return
    end

    -- Предмет без применения всегда обесцвечен.
    if not ActionBar.SlotHasUseAction(slotID) then
        btn.texture:SetDesaturated(true)
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

    local cooldownShown = btn.cooldown and btn.cooldown:IsShown()
    if isUsable and not IsActionOutOfRange(slotID) and (not cooldownShown or cooldownShown and IsGlobalCooldown(slotID)) then
        btn.texture:SetDesaturated(false)
    elseif isLackingResources then
        btn.texture:SetDesaturated(true)
    elseif cooldownShown and not IsGlobalCooldown(slotID) then
        btn.texture:SetDesaturated(true)
    else
        btn.texture:SetDesaturated(true)
    end

    -- Проверка блокировки по уровню
    local isLevelLinkLocked = false
    if C_LevelLink and C_LevelLink.IsActionLocked then
        isLevelLinkLocked = C_LevelLink.IsActionLocked(slotID)
    end

    -- Десатурация и иконка блокировки
    if not btn.texture:IsDesaturated() then
        btn.texture:SetDesaturated(isLevelLinkLocked)
    end
end

-- Обновление пригодности кнопки к применению.
local function UpdateActionButtonUsable(slotID, isUsable, isLackingResources)
    local btn = ActionBar.GetButton(slotID)
    if not btn or not btn.texture then return end
    
    UpdateActionButtonTextureDesaturation(btn, slotID, isUsable, isLackingResources)
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

    if ActionBar.UpdateBoosts then
        ActionBar.UpdateBoosts()
    end
end

-- Обновление свечения готовности на кнопке.
local function UpdateActionButtonGlow(slotID, spellID, event)
    local btn = ActionBar.GetButton(slotID)
    if not btn then return end

    -- Фрейм для отображения M2 модели
    if not btn.Glow then
        btn.Glow = CreateFrame("PlayerModel", nil, btn)
        btn.Glow:SetSize(ActionBar.modelSize, ActionBar.modelSize)
        if btn.texture then
            btn.Glow:SetPoint("CENTER", btn.texture, "CENTER", 0, 0)
        else
            btn.Glow:SetPoint("CENTER", btn, "CENTER", 0, 0)
        end
        btn.Glow:SetFrameStrata(btn:GetFrameStrata())
        btn.Glow:SetFrameLevel(btn:GetFrameLevel() - 1)
        btn.Glow:SetModel(5201375)
        btn.Glow:SetParent(btn)
        btn.Glow:SetKeepModelOnHide(true)
        btn.Glow:SetAnimation(1)

        btn.Glow:SetAlpha(1.0)
        btn.Glow:Show()

        ConsoleMenu:InitFadeAnimations(btn.Glow, ActionBar.animationDuration)
    elseif btn.texture then
        btn.Glow:ClearAllPoints()
        btn.Glow:SetPoint("CENTER", btn.texture, "CENTER", 0, 0)
    end

    -- Переустанавливаем transform на каждом обновлении:
    -- это удерживает визуальный центр при разном соотношении сторон и смене разрешения.
    local transformOffset = ActionBar.GetGlowTransformOffset()
    btn.Glow:SetTransform(
        CreateVector3D(transformOffset, transformOffset, 0),
        CreateVector3D(0, 0, 0),
        ActionBar.GetGlowTransformScale()
    )

    -- Если spellID не передан, пытаемся получить его из слота
    if not spellID then
        local actionType, id, _ = GetActionInfo(slotID)
        
        -- Если это не заклинание и не макрос, скрываем glow
        if actionType ~= "spell" and actionType ~= "macro" then
            ConsoleMenu:AnimatedHide(btn.Glow)
            return
        end

        spellID = id
    end

    -- Если spellID найден, проверяем актуальное состояние overlay
    if spellID then
        local isSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed(spellID)
        if isSpellOverlayed then
            -- Иконка слота часто меняется вместе с проком.
            UpdateActionButtonTexture(slotID)
            ConsoleMenu:AnimatedShow(btn.Glow)
        else
            ConsoleMenu:AnimatedHide(btn.Glow)
            -- После исчезновения свечения клиент ещё может отдавать иконку прока.
            RunNextFrame(function()
                UpdateActionButtonTexture(slotID)
            end)
        end
    else
        ConsoleMenu:AnimatedHide(btn.Glow)
        RunNextFrame(function()
            UpdateActionButtonTexture(slotID)
        end)
    end
end

-- Обновление восстановления и пригодности всех кнопок.
local function UpdateActionButtonCooldowns()
    local frame = ActionBar.GetFrame()
    if not frame then
        return
    end

    for slotID, btn in pairs(frame.actionButtons) do
        if btn.cooldown then
            local info = C_ActionBar.GetActionCooldown(slotID)

            if info and info.isActive then
                local duration = C_ActionBar.GetActionCooldownDuration(slotID)

                btn.cooldown:SetCooldownFromDurationObject(duration)
                btn.cooldown:Show()
            else
                btn.cooldown:Clear()
            end

            RunNextFrame(function()
                UpdateActionButtonTextureDesaturation(btn, slotID)
            end)
        end
    end
end

-- Обновление счётчика зарядов на кнопке.
local function UpdateActionButtonCount(slotID)
    local btn = ActionBar.GetButton(slotID)
    if not btn or not btn.StackCount or not btn.StackCount.Text then return end

    local count = C_ActionBar.GetActionDisplayCount(slotID)

    if count and issecretvalue(count) then
        -- Во время боя count может быть secret-значением.
        -- Обновляем только текст, но не меняем видимость фрейма,
        -- чтобы не возвращать баг с "вечным" фоном стаков.
        btn.StackCount.Text:SetText(count)
        return
    end

    if (count and count ~= "" and count ~= "0" and count ~= 0) or ActionBar.stackCountChange[slotID] then
        btn.StackCount.Text:SetText(count)
        ActionBar.stackCountChange[slotID] = true
        ConsoleMenu:AnimatedShow(btn.StackCount)
    else
        btn.StackCount.Text:SetText("")
        ConsoleMenu:AnimatedHide(btn.StackCount)
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
    ActionBar.UpdateBoosts()
    ActionBar.UpdateAllUsable()
end

ActionBar.UpdateIcon = UpdateActionButtonIcon
ActionBar.UpdateSlot12Label = UpdateSlot12Label
ActionBar.UpdateTexture = UpdateActionButtonTexture
ActionBar.UpdateTextureDesaturation = UpdateActionButtonTextureDesaturation
ActionBar.UpdateUsable = UpdateActionButtonUsable
ActionBar.UpdateGlow = UpdateActionButtonGlow
ActionBar.UpdateCooldowns = UpdateActionButtonCooldowns
ActionBar.UpdateCount = UpdateActionButtonCount
ActionBar.UpdatePageVisibility = UpdateActionBarPageVisibility
