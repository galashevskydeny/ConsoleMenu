local ConsoleMenu = _G.ConsoleMenu

-- Скрывает текст боя (всплывающих цифр)
local function HideFloatingText()
    SetCVar("threatShowNumeric", 0)
    SetCVar("enableFloatingCombatText", 0)
    SetCVar("floatingCombatTextCombatDamage", 0)
end
-- Делаем функцию доступной глобально
_G.HideFloatingText = HideFloatingText

-- Возвращает текст боя (всплывающих цифр) к значениям по умолчанию
local function ShowFloatingText()
    SetCVar("threatShowNumeric", GetCVarDefault("threatShowNumeric"))
    SetCVar("enableFloatingCombatText", GetCVarDefault("enableFloatingCombatText"))
    SetCVar("floatingCombatTextCombatDamage", GetCVarDefault("floatingCombatTextCombatDamage"))
end
-- Делаем функцию доступной глобально
_G.ShowFloatingText = ShowFloatingText

-- Скрывает уведомления о входе/выходе членов гильдии из онлайна
local function HideGuildMemberNotification()
    SetCVar("guildMemberNotify", 0)
end
-- Делаем функцию доступной глобально
_G.HideGuildMemberNotification = HideGuildMemberNotification

-- Возвращает уведомления о входе/выходе членов гильдии из онлайна к значениям по умолчанию
local function ShowGuildMemberNotification()
    SetCVar("guildMemberNotify", GetCVarDefault("guildMemberNotify"))
end
-- Делаем функцию доступной глобально
_G.ShowGuildMemberNotification = ShowGuildMemberNotification

-- Скрывает облака с субтитрами над головой персонажей и игроков
local function HideChatBubble()
    SetCVar("chatBubbles", 0)
    SetCVar("chatBubblesParty", 0)
end
-- Делаем функцию доступной глобально
_G.HideChatBubble = HideChatBubble

-- Возвращает облака с субтитрами над головой персонажей и игроков к значениям по умолчанию
local function ShowChatBubble()
    SetCVar("chatBubbles", GetCVarDefault("chatBubbles"))
    SetCVar("chatBubblesParty", GetCVarDefault("chatBubblesParty"))
end
-- Делаем функцию доступной глобально
_G.ShowChatBubble = ShowChatBubble

-- Скрывает выделение под квестодателем
local function HideQuestCircle()
    SetCVar("ShowQuestUnitCircles", "0")
    SetCVar("ObjectSelectionCircle", "0")
end
-- Делаем функцию доступной глобально
_G.HideQuestCircle = HideQuestCircle

-- Возвращает выделение под квестодателем к значениям по умолчанию
local function ShowQuestCircle()
    SetCVar("ShowQuestUnitCircles", GetCVarDefault("ShowQuestUnitCircles"))
    SetCVar("ObjectSelectionCircle", GetCVarDefault("ObjectSelectionCircle"))
end
-- Делаем функцию доступной глобально
_G.ShowQuestCircle = ShowQuestCircle

-- Устанавливает базовые для необходимого пользовательского опыта значения soft target
local function SetBaseSoftTargetSettings()
    SetCVar("SoftTargetFriend", 1)
    SetCVar("SoftTargetFriend", 1)
    SetCVar("SoftTargetNameplateEnemy", 1)
    SetCVar("SoftTargetIconInteract", 0)
    SetCVar("SoftTargetFriendRange", 5)
    SetCVar("SoftTargetForce", 0)

    -- Фокусировка на врагах только если персонаж не верхом
    if IsMounted() then
        SetCVar("SoftTargetEnemy", 0)
    else
        SetCVar("SoftTargetEnemy", 1)
    end
end
-- Делаем функцию доступной глобально
_G.SetBaseSoftTargetSettings = SetBaseSoftTargetSettings

-- Возвращает настройки soft target к значениям по умолчанию
local function ResetSoftTargetSettings()
    SetCVar("SoftTargetFriend", GetCVarDefault("SoftTargetFriend"))
    SetCVar("SoftTargetNameplateEnemy", GetCVarDefault("SoftTargetNameplateEnemy"))
    SetCVar("SoftTargetIconInteract", GetCVarDefault("SoftTargetIconInteract"))
    SetCVar("SoftTargetFriendRange", GetCVarDefault("SoftTargetFriendRange"))
    SetCVar("SoftTargetForce", GetCVarDefault("SoftTargetForce"))
    SetCVar("SoftTargetEnemy", GetCVarDefault("SoftTargetEnemy"))
end
-- Делаем функцию доступной глобально
_G.ResetSoftTargetSettings = ResetSoftTargetSettings

-- Устанавливает значения настроек soft target для боя
local function SetCombatSoftTargetSettings()
    SetCVar("SoftTargetEnemy", 1)
    SetCVar("SoftTargetForce", 0)
end

-- Устанавливает значения настроект soft target в зонах святилищах
local function SetSanctuarySoftTargetSettings()
    local pvpType, _, _ = C_PvP.GetZonePVPInfo()

    if pvpType == "sanctuary" then
        SetCVar("SoftTargetEnemy", 0)
    end
end

-- Устанавливает настройки soft target для лекаря (фокусировка на союзниках)
local function SetHealerSoftTargetSettings()
    SetCVar("SoftTargetFriend", 1)
    SetCVar("SoftTargetNameplateEnemy", 0)
    SetCVar("SoftTargetIconInteract", 0)
    SetCVar("SoftTargetFriendRange", 5)
    SetCVar("SoftTargetForce", 0)
    SetCVar("SoftTargetEnemy", 0)
end
-- Делаем функцию доступной глобально
_G.SetHealerSoftTargetSettings = SetHealerSoftTargetSettings

-- Устанавливает базовые для необходимого пользовательского опыта значения настроек отображения имен
local function SetBaseUnitNameSettings()
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
-- Делаем функцию доступной глобально
_G.SetBaseUnitNameSettings = SetBaseUnitNameSettings

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
-- Делаем функцию доступной глобально
_G.ResetUnitNameSettings = ResetUnitNameSettings

-- Устанаваливает базовые для необходимого пользовательского опыта значения различных игровых настроек 
local function SetBaseSettings()
    -- Автоматический сбор добычи
    SetCVar("autoLootDefault", 1)
    -- Автоматическое отслеживание квестов
    SetCVar("autoQuestWatch", 0)

    SetCVar("Sound_ZoneMusicNoDelay", 1)

    -- Скрытие отображения уроков в интерфейсе
    SetCVar("showTutorials", 0)

    SetCVar("nameplateShowSelf", 0)

end
-- Делаем функцию доступной глобально
_G.SetBaseSettings = SetBaseSettings

-- Возвращает различные игровые настройки к значениям по умолчанию
local function ResetBaseSettings()
    -- Автоматический сбор добычи
    SetCVar("autoLootDefault", GetCVarDefault("autoLootDefault"))
    -- Автоматическое отслеживание квестов
    SetCVar("autoQuestWatch", GetCVarDefault("autoQuestWatch"))

    SetCVar("Sound_ZoneMusicNoDelay", GetCVarDefault("Sound_ZoneMusicNoDelay"))

    -- Отображение уроков в интерфейсе
    SetCVar("showTutorials", GetCVarDefault("showTutorials"))

    SetCVar("nameplateShowSelf", GetCVarDefault("nameplateShowSelf"))

end
-- Делаем функцию доступной глобально
_G.ResetBaseSettings = ResetBaseSettings

-- Устанавливает базовые для необходимого пользовательского опыта значения настроек графики
local function SetBaseGraphicsSettings()
    SetCVar("NotchedDisplayMode", 0)
    SetCVar("graphicsOutlineMode", 0)
    SetCVar("useMaxFPS", 0)
    SetCVar("useMaxFPSBk", 0)
    SetCVar("useTargetFPS", 0)
    SetCVar("Gamma", 0.9)
    SetCVar("Contrast", 80)
    SetCVar("Brightness", 65)
end
-- Делаем функцию доступной глобально
_G.SetBaseGraphicsSettings = SetBaseGraphicsSettings

-- Возвращает настройки графики к значениям по умолчанию
local function ResetGraphicsSettings()
    SetCVar("NotchedDisplayMode", GetCVarDefault("NotchedDisplayMode"))
    SetCVar("graphicsOutlineMode", GetCVarDefault("graphicsOutlineMode"))
    SetCVar("useMaxFPS", GetCVarDefault("useMaxFPS"))
    SetCVar("useMaxFPSBk", GetCVarDefault("useMaxFPSBk"))
    SetCVar("useTargetFPS", GetCVarDefault("useTargetFPS"))
    SetCVar("Gamma", GetCVarDefault("Gamma"))
    SetCVar("Contrast", GetCVarDefault("Contrast"))
    SetCVar("Brightness", GetCVarDefault("Brightness"))
end
-- Делаем функцию доступной глобально
_G.ResetGraphicsSettings = ResetGraphicsSettings


-- Применяет настройки CVars на основе значений в ConsoleMenuDB
local function ApplyCVarSettings()
    if not ConsoleMenuDB then
        return
    end
    
    -- Применяем функции в зависимости от значения настройки (1 = "По умолчанию", 2 = "Отключить", 3 = "Вручную" - не применяется)
    if ConsoleMenuDB.hideFloatingText == 1 then
        ShowFloatingText()
    elseif ConsoleMenuDB.hideFloatingText == 2 then
        HideFloatingText()
    -- При значении 3 ("Вручную") функции не вызываются
    end
    
    if ConsoleMenuDB.hideGuildMemberNotification == 1 then
        ShowGuildMemberNotification()
    elseif ConsoleMenuDB.hideGuildMemberNotification == 2 then
        HideGuildMemberNotification()
    -- При значении 3 ("Вручную") функции не вызываются
    end
    
    if ConsoleMenuDB.hideChatBubble == 1 then
        ShowChatBubble()
    elseif ConsoleMenuDB.hideChatBubble == 2 then
        HideChatBubble()
    -- При значении 3 ("Вручную") функции не вызываются
    end
    
    if ConsoleMenuDB.hideQuestCircle == 1 then
        ShowQuestCircle()
    elseif ConsoleMenuDB.hideQuestCircle == 2 then
        HideQuestCircle()
    -- При значении 3 ("Вручную") функции не вызываются
    end
    
    -- SoftTarget настройки (1 = "По умолчанию", 2 = "Для бойца", 3 = "Для танка", 4 = "Для лекаря", 5 = "Вручную")
    if ConsoleMenuDB.enableSoftTargetSettings == 1 then
        ResetSoftTargetSettings()
    elseif ConsoleMenuDB.enableSoftTargetSettings == 2 or ConsoleMenuDB.enableSoftTargetSettings == 3 then
        -- Боец и танк используют одинаковую логику
        SetBaseSoftTargetSettings()
    elseif ConsoleMenuDB.enableSoftTargetSettings == 4 then
        -- Лекарь использует специальную логику
        SetHealerSoftTargetSettings()
    -- При значении 5 ("Вручную") функции не вызываются
    end
    
    if ConsoleMenuDB.hideUnitNames == 1 then
        ResetUnitNameSettings()
    elseif ConsoleMenuDB.hideUnitNames == 2 then
        SetBaseUnitNameSettings()
    -- При значении 3 ("Вручную") функции не вызываются
    end
    
    if ConsoleMenuDB.enableMacBookGraphics == 1 then
        ResetGraphicsSettings()
    elseif ConsoleMenuDB.enableMacBookGraphics == 2 then
        SetBaseGraphicsSettings()
    -- При значении 3 ("Вручную") функции не вызываются
    end
    
    -- Дополнительные параметры (1 = "По умолчанию", 2 = "Кастомные", 3 = "Вручную")
    if ConsoleMenuDB.enableBaseSettings == 1 then
        ResetBaseSettings()
    elseif ConsoleMenuDB.enableBaseSettings == 2 then
        SetBaseSettings()
    -- При значении 3 ("Вручную") функции не вызываются
    end
end
-- Делаем функцию доступной глобально
_G.ApplyCVarSettings = ApplyCVarSettings

function ConsoleMenu:UpdateCVars()
    -- Инициализация базы данных настроек, если еще не инициализирована
    if not ConsoleMenuDB then
        ConsoleMenuDB = {}
    end
    
    -- Регистрируем события для динамического изменения SoftTarget настроек
    ConsoleMenu:RegisterEvent("PLAYER_REGEN_DISABLED", function()
        if ConsoleMenuDB then
            if ConsoleMenuDB.enableSoftTargetSettings == 2 or ConsoleMenuDB.enableSoftTargetSettings == 3 then
                -- Боец и танк: фокус на врагах в бою
                SetCombatSoftTargetSettings()
            elseif ConsoleMenuDB.enableSoftTargetSettings == 4 then
                -- Лекарь: фокус на союзниках в бою
                SetHealerSoftTargetSettings()
            end
        end
    end)
    ConsoleMenu:RegisterEvent("PLAYER_REGEN_ENABLED", function()
        if ConsoleMenuDB and (ConsoleMenuDB.enableSoftTargetSettings == 2 or ConsoleMenuDB.enableSoftTargetSettings == 3) then
            SetBaseSoftTargetSettings()
        end
    end)
    ConsoleMenu:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED", function()
        if ConsoleMenuDB and (ConsoleMenuDB.enableSoftTargetSettings == 2 or ConsoleMenuDB.enableSoftTargetSettings == 3) then
            SetBaseSoftTargetSettings()
        end
    end)
    ConsoleMenu:RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
        if ConsoleMenuDB and (ConsoleMenuDB.enableSoftTargetSettings == 2 or ConsoleMenuDB.enableSoftTargetSettings == 3) then
            SetSanctuarySoftTargetSettings()
        end
    end)
end