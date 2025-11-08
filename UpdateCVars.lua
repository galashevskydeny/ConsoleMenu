local ConsoleMenu = _G.ConsoleMenu

-- Скрывает текст боя (всплывающих цифр)
local function HideFloatingText()
    SetCVar("threatShowNumeric", 0)
    SetCVar("enableFloatingCombatText", 0)
    SetCVar("floatingCombatTextCombatDamage", 0)
end

-- Отображение текста боя (всплывающих цифр) к значениям по умолчанию
local function ShowFloatingText()
    SetCVar("threatShowNumeric", 1)
    SetCVar("enableFloatingCombatText", 1)
    SetCVar("floatingCombatTextCombatDamage", 1)
end

-- Возврат текста боя (всплывающих цифр) к значениям по умолчанию
local function DefaultFloatingText()
    SetCVar("threatShowNumeric", GetCVarDefault("threatShowNumeric"))
    SetCVar("enableFloatingCombatText", GetCVarDefault("enableFloatingCombatText"))
    SetCVar("floatingCombatTextCombatDamage", GetCVarDefault("floatingCombatTextCombatDamage"))
end

-- Скрывает облака с субтитрами над головой персонажей и игроков
local function HideChatBubble()
    SetCVar("chatBubbles", 0)
    SetCVar("chatBubblesParty", 0)
end

-- Возвращает облака с субтитрами над головой персонажей и игроков к значениям по умолчанию
local function ResetChatBubble()
    SetCVar("chatBubbles", GetCVarDefault("chatBubbles"))
    SetCVar("chatBubblesParty", GetCVarDefault("chatBubblesParty"))
end

-- Отображение облака с субтитрами над головой персонажей и игроков
local function ShowChatBubble()
    SetCVar("chatBubbles", 1)
    SetCVar("chatBubblesParty", 1)
end

-- Скрывает выделение под квестодателем
local function HideQuestCircle()
    SetCVar("ShowQuestUnitCircles", "0")
    SetCVar("ObjectSelectionCircle", "0")
end

-- Возвращает выделение под квестодателем к значениям по умолчанию
local function ResetQuestCircle()
    SetCVar("ShowQuestUnitCircles", GetCVarDefault("ShowQuestUnitCircles"))
    SetCVar("ObjectSelectionCircle", GetCVarDefault("ObjectSelectionCircle"))
end

-- Отображение выделения под квестодателем
local function ShowQuestCircle()
    SetCVar("ShowQuestUnitCircles", 1)
    SetCVar("ObjectSelectionCircle", 1)
end

-- Устанавливает базовые для необходимого пользовательского опыта значения soft target
local function SetBaseSoftTargetSettings()
    SetCVar("SoftTargetFriend", 1)
    SetCVar("SoftTargetNameplateEnemy", 1)
    SetCVar("SoftTargetIconInteract", 0)
    
    SetCVar("SoftTargetForce", 0)

    if ConsoleMenuDB.softTargetFlightSwitching == 1 then
        -- Фокусировка на врагах только если персонаж не верхом
        if IsMounted() then
            SetCVar("SoftTargetEnemy", 0)
        else
            SetCVar("SoftTargetEnemy", 1)
        end
    end
end

-- Возвращает настройки soft target к значениям по умолчанию
local function ResetBaseSoftTargetSettings()
    SetCVar("SoftTargetFriend", GetCVarDefault("SoftTargetFriend"))
    SetCVar("SoftTargetNameplateEnemy", GetCVarDefault("SoftTargetNameplateEnemy"))
    SetCVar("SoftTargetIconInteract", GetCVarDefault("SoftTargetIconInteract"))
    SetCVar("SoftTargetForce", GetCVarDefault("SoftTargetForce"))
    SetCVar("SoftTargetEnemy", GetCVarDefault("SoftTargetEnemy"))
end

-- Устанавливает значения настроек soft target для боя
local function SetCombatSoftTargetSettings()
    SetCVar("SoftTargetEnemy", 1)
    SetCVar("SoftTargetForce", 0)
end

-- Скрывает отображения имен
local function HideUnitNameSettings()
    SetCVar("UnitNameEnemyGuardianName", 0)
    SetCVar("UnitNameEnemyMinionName", 0)
    SetCVar("UnitNameEnemyPetName", 0)
    SetCVar("UnitNameEnemyPlayerName", 0)
    SetCVar("UnitNameEnemyTotemName", 0)

    SetCVar("UnitNameFriendlyGuardianName", 0)
    SetCVar("UnitNameFriendlyMinionName", 0)
    SetCVar("UnitNameFriendlyPetName", 0)
    SetCVar("UnitNameFriendlyPlayerName", 0)
    SetCVar("UnitNameFriendlySpecialNPCName", 0)
    SetCVar("UnitNameFriendlyTotemName", 0)
    SetCVar("UnitNameGuildTitle", 0)
    SetCVar("UnitNameHostleNPC", 0)
    SetCVar("UnitNameInteractiveNPC", 0)
end

-- Отображение имен
local function ShowUnitNameSettings()
    SetCVar("UnitNameEnemyGuardianName", 1)
    SetCVar("UnitNameEnemyMinionName", 1)
    SetCVar("UnitNameEnemyPetName", 1)
    SetCVar("UnitNameEnemyPlayerName", 1)
    SetCVar("UnitNameEnemyTotemName", 1)

    SetCVar("UnitNameFriendlyGuardianName", 1)
    SetCVar("UnitNameFriendlyMinionName", 1)
    SetCVar("UnitNameFriendlyPetName", 1)
    SetCVar("UnitNameFriendlyPlayerName", 1)
    SetCVar("UnitNameFriendlySpecialNPCName", 1)
    SetCVar("UnitNameFriendlyTotemName", 1)
    SetCVar("UnitNameGuildTitle", 1)
    SetCVar("UnitNameHostleNPC", 1)
    SetCVar("UnitNameInteractiveNPC", 1)
end

-- Возвращает настройки отображения имен к значениям по умолчанию
local function ResetUnitNameSettings()
    SetCVar("UnitNameEnemyGuardianName", GetCVarDefault("UnitNameEnemyGuardianName"))
    SetCVar("UnitNameEnemyMinionName", GetCVarDefault("UnitNameEnemyMinionName"))
    SetCVar("UnitNameEnemyPetName", GetCVarDefault("UnitNameEnemyPetName"))
    SetCVar("UnitNameEnemyPlayerName", GetCVarDefault("UnitNameEnemyPlayerName"))
    SetCVar("UnitNameEnemyTotemName", GetCVarDefault("UnitNameEnemyTotemName"))

    SetCVar("UnitNameFriendlyGuardianName", GetCVarDefault("UnitNameFriendlyGuardianName"))
    SetCVar("UnitNameFriendlyMinionName", GetCVarDefault("UnitNameFriendlyMinionName"))
    SetCVar("UnitNameFriendlyPetName", GetCVarDefault("UnitNameFriendlyPetName"))
    SetCVar("UnitNameFriendlyPlayerName", GetCVarDefault("UnitNameFriendlyPlayerName"))
    SetCVar("UnitNameFriendlySpecialNPCName", GetCVarDefault("UnitNameFriendlySpecialNPCName"))
    SetCVar("UnitNameFriendlyTotemName", GetCVarDefault("UnitNameFriendlyTotemName"))
    SetCVar("UnitNameGuildTitle", GetCVarDefault("UnitNameGuildTitle"))
    SetCVar("UnitNameHostleNPC", GetCVarDefault("UnitNameHostleNPC"))
    SetCVar("UnitNameInteractiveNPC", GetCVarDefault("UnitNameInteractiveNPC"))
end

-- Отключает режим контуров графики
local function SetGraphicsOutlineMode()
    SetCVar("graphicsOutlineMode", 0)
end

-- Возвращает режим контуров графики к значению по умолчанию
local function ResetGraphicsOutlineMode()
    SetCVar("graphicsOutlineMode", GetCVarDefault("graphicsOutlineMode"))
end

-- Устанавливает базовые для необходимого пользовательского опыта значения настроек графики
local function SetMacBookSettings()

    -- Устанавливаем настройки для MacBook Pro с вырезом экрана
    UIWidgetTopCenterContainerFrame:ClearAllPoints()
    UIWidgetTopCenterContainerFrame:SetPoint("TOP", UIParent, "TOP", 0, -60)
    SetCVar("NotchedDisplayMode", 0)

end

-- Возвращает настройки графики к значениям по умолчанию
local function ResetMacBookSettings()
    -- Устанавливаем настройки для MacBook Pro с вырезом экрана
    UIWidgetTopCenterContainerFrame:ClearAllPoints()
    UIWidgetTopCenterContainerFrame:SetPoint("TOP", UIParent, "TOP", 0, -15)
    SetCVar("NotchedDisplayMode", GetCVarDefault("NotchedDisplayMode"))
end

-- Применяет настройки CVars на основе значений в ConsoleMenuDB
local function ApplyCVarSettings()
    if not ConsoleMenuDB then
        return
    end
    
    -- Применяем функции в зависимости от значения настройки (1 = "По умолчанию", 2 = "Отключить", 3 = "Вручную" - не применяется)
    if ConsoleMenuDB.floatingText == 1 then
        DefaultFloatingText()
    elseif ConsoleMenuDB.floatingText == 2 then
        ShowFloatingText()
    elseif ConsoleMenuDB.floatingText == 3 then
        HideFloatingText()
    end
    
    if ConsoleMenuDB.chatBubble == 1 then
        ResetChatBubble()
    elseif ConsoleMenuDB.chatBubble == 2 then
        ShowChatBubble()
    elseif ConsoleMenuDB.chatBubble == 3 then
        HideChatBubble()
    end
    
    if ConsoleMenuDB.qestCircle == 1 then
        ResetQuestCircle()
    elseif ConsoleMenuDB.qestCircle == 2 then
        ShowQuestCircle()
    elseif ConsoleMenuDB.qestCircle == 3 then
        HideQuestCircle()
    end
    
    SetBaseSoftTargetSettings()
    
    if ConsoleMenuDB.unitNames == 1 then
        ResetUnitNameSettings()
    elseif ConsoleMenuDB.unitNames == 2 then
        ShowUnitNameSettings()
    elseif ConsoleMenuDB.unitNames == 3 then
        HideUnitNameSettings()
    end
    
    if ConsoleMenuDB.enableMacBook == 1 then
        SetMacBookSettings()
    elseif ConsoleMenuDB.enableMacBook == 2 then
        ResetMacBookSettings()
    end

    if ConsoleMenuDB.hideGraphicsOutlineMode == 1 then
        ResetGraphicsOutlineMode()
    elseif ConsoleMenuDB.hideGraphicsOutlineMode == 2 then
        SetGraphicsOutlineMode()
    end
    
end

-- Делаем функцию доступной глобально
_G.ApplyCVarSettings = ApplyCVarSettings

-- Устанавливает значения настроект soft target в зонах святилищах
local function UpdateSanctuarySoftTargetSettings()
    ConsoleMenuDB.softTargetFriendRange = GetCVarDefault("SoftTargetFriendRange")
    local pvpType, _, _ = C_PvP.GetZonePVPInfo()

    if ConsoleMenuDB.softTargetSanctuarySwitching == 1 and pvpType == "sanctuary" then
        SetCVar("SoftTargetEnemy", 0)
    end

    if pvpType ~= "sanctuary" and ConsoleMenuDB.softTargetFriendSanctuaryRange == 1 then
        SetCVar("SoftTargetFriendRange", ConsoleMenuDB.softTargetFriendRange)
    elseif pvpType == "sanctuary" and ConsoleMenuDB.softTargetFriendSanctuaryRange == 1 then
        SetCVar("SoftTargetFriendRange", 5)
    end

end

function ConsoleMenu:UpdateCVars()
    
    -- Регистрируем события для динамического изменения SoftTarget настроек
    ConsoleMenu:RegisterEvent("PLAYER_REGEN_DISABLED", function()
        SetCombatSoftTargetSettings()
    end)
    ConsoleMenu:RegisterEvent("PLAYER_REGEN_ENABLED", function()
        SetBaseSoftTargetSettings()
    end)
    ConsoleMenu:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED", function()
        SetBaseSoftTargetSettings()
    end)

    ConsoleMenu:RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
        UpdateSanctuarySoftTargetSettings()UpdateSanctuarySoftTargetSettings()
    end)

    ApplyCVarSettings()
end