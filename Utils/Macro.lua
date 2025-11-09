-- Macro.lua
-- Модуль для работы с макросами

local ConsoleMenu = _G.ConsoleMenu

-- Функция установки действия для слота
local function SetActionForSlot(slot, actionType, actionId)

    if InCombatLockdown() then return end

    if actionType == "spell" then
        C_Spell.PickupSpell(actionId)
        PlaceAction(slot)
    elseif actionType == "macro" then
        PickupMacro(actionId)
        PlaceAction(slot)
    elseif actionType == "item" then
        PickupItem(actionId)
        PlaceAction(slot)
    elseif actionType == "companion" then
        PickupCompanion("MOUNT", -1)
        PlaceAction(slot)
    elseif actionType == "empty" then
        PickupAction(slot)
        ClearCursor()
    end
end

-- Глобальная функция применения настроек макросов
local function ApplyMacroSettings()
    if ConsoleMenuDB.actionBarPageExploring == 1 then
        SetActionForSlot(13, "empty", nil)
        SetActionForSlot(14, "empty", nil)
        SetActionForSlot(15, "macro", "Спешиться")
        SetActionForSlot(16, "empty", nil)
        SetActionForSlot(17, "empty", nil)
        SetActionForSlot(18, "macro", "Избранный маунт")
        SetActionForSlot(19, "empty", nil)
        SetActionForSlot(20, "macro", "БыстроеПеремещ.")
        SetActionForSlot(21, "empty", nil)
        SetActionForSlot(22, "empty", nil)
        SetActionForSlot(23, "empty", nil)
        SetActionForSlot(24, "empty", nil)
    end

    if ConsoleMenuDB.actionBarPagePlayerInteraction == 1 then
        SetActionForSlot(25, "empty", nil)
        SetActionForSlot(26, "macro", "Осмотреть")
        SetActionForSlot(27, "macro", "Спешиться")
        SetActionForSlot(28, "empty", nil)
        SetActionForSlot(29, "empty", nil)
        SetActionForSlot(30, "macro", "Избранный маунт")
        SetActionForSlot(31, "macro", "Предложить обмен")
        SetActionForSlot(32, "macro", "БыстроеПеремещ.")
        SetActionForSlot(33, "macro", "Создать группу")
        SetActionForSlot(34, "empty", nil)
        SetActionForSlot(35, "empty", nil)
        SetActionForSlot(36, "empty", nil)
    end

    if ConsoleMenuDB.actionBarPageMount == 1 then
        SetActionForSlot(37, "empty", nil)
        SetActionForSlot(38, "empty", nil)
        SetActionForSlot(39, "macro", "Спешиться")
        SetActionForSlot(40, "empty", nil)
        SetActionForSlot(41, "empty", nil)
        SetActionForSlot(42, "macro", "Трюк")
        SetActionForSlot(43, "empty", nil)
        SetActionForSlot(44, "empty", nil)
        SetActionForSlot(45, "empty", nil)
        SetActionForSlot(46, "empty", nil)
        SetActionForSlot(47, "empty", nil)
        SetActionForSlot(48, "empty", nil)
    end

    if ConsoleMenuDB.actionBarPageDragonriding == 1 then
        SetActionForSlot(121, "spell", 372608)
        SetActionForSlot(122, "spell", 425782)
        SetActionForSlot(123, "macro", "Спешиться")
        SetActionForSlot(124, "spell", 361584)
        SetActionForSlot(125, "spell", 403092)
        SetActionForSlot(126, "macro", "Трюк")
        SetActionForSlot(127, "spell", 372610)
        SetActionForSlot(128, "spell", 374990)
        SetActionForSlot(129, "empty", nil)
        SetActionForSlot(130, "empty", nil)
        SetActionForSlot(131, "empty", nil)
        SetActionForSlot(132, "empty", nil)
    end
end

-- Делаем функцию доступной глобально
_G.ApplyMacroSettings = ApplyMacroSettings

