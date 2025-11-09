-- Macro.lua
-- Модуль для работы с макросами

local ConsoleMenu = _G.ConsoleMenu

-- Таблица определений всех возможных макросов: имя -> {тело, иконка}
local macroDefinitions = {
    ["Спешиться"] = {"/dismount [mounted, noflying]", "Ability_DragonRiding_LegStretches01"},
    ["Избранный маунт"] = {"/run C_MountJournal.SummonByID(0)", "ACHIEVEMENT_GUILDPERK_MOUNTUP"},
    ["БыстроеПеремещ."] = {"/fasttravel", "INV_HearthstonePet"},
    ["Осмотреть"] = {"/targetfriend\n/inspect", "ACHIEVEMENT_GUILDPERK_LADYLUCK"},
    ["Предложить обмен"] = {"/targetfriend\n/trade", "ACHIEVEMENT_GUILDPERK_CASHFLOW_RANK2"},
    ["Трюк"] = {"/mountspecial", "INV_TreasureCrabPet_Purple"},
}

-- Функция проверки и создания всех необходимых макросов
local function EnsureAllMacros()
    if InCombatLockdown() then return end

    -- Таблица необходимых макросов: заполняется в зависимости от настроек
    local requiredMacros = {}
    
    -- Заполняем таблицу в зависимости от включенных страниц панели действий
    if ConsoleMenuDB.actionBarPageExploring == 1 then
        requiredMacros["Избранный маунт"] = macroDefinitions["Избранный маунт"]
        requiredMacros["БыстроеПеремещ."] = macroDefinitions["БыстроеПеремещ."]
    end
    
    if ConsoleMenuDB.actionBarPagePlayerInteraction == 1 then
        requiredMacros["Осмотреть"] = macroDefinitions["Осмотреть"]
        requiredMacros["Избранный маунт"] = macroDefinitions["Избранный маунт"]
        requiredMacros["Предложить обмен"] = macroDefinitions["Предложить обмен"]
        requiredMacros["БыстроеПеремещ."] = macroDefinitions["БыстроеПеремещ."]
    end
    
    if ConsoleMenuDB.actionBarPageMount == 1 then
        requiredMacros["Спешиться"] = macroDefinitions["Спешиться"]
        requiredMacros["Трюк"] = macroDefinitions["Трюк"]
    end
    
    if ConsoleMenuDB.actionBarPageDragonriding == 1 then
        requiredMacros["Спешиться"] = macroDefinitions["Спешиться"]
        requiredMacros["Трюк"] = macroDefinitions["Трюк"]
    end
    
    -- Создаем таблицу существующих макросов за один проход
    local existingMacros = {}
    local totalMacros = GetNumMacros()
    for i = 1, totalMacros do
        local name = GetMacroInfo(i)
        if name then
            existingMacros[name] = i
        end
    end
    
    -- Проверяем и создаем/обновляем необходимые макросы
    for macroName, macroData in pairs(requiredMacros) do
        local macroBody = macroData[1]
        local macroIcon = macroData[2]
        
        if not existingMacros[macroName] then
            CreateMacro(macroName, macroIcon, macroBody, nil)
        end
    end
end

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
    -- Сначала проверяем и создаем все необходимые макросы
    EnsureAllMacros()
    
    if ConsoleMenuDB.actionBarPageExploring == 1 then
        SetActionForSlot(13, "empty", nil)
        SetActionForSlot(14, "empty", nil)
        SetActionForSlot(15, "empty", nil)
        SetActionForSlot(16, "empty", nil)
        -- Слот под L3 для классовой способности перемещения
        --SetActionForSlot(17, "empty", nil)
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
        SetActionForSlot(27, "empty", nil)
        SetActionForSlot(28, "empty", nil)
        -- Слот под L3 для классовой способности перемещения
        --SetActionForSlot(29, "empty", nil)
        SetActionForSlot(30, "macro", "Избранный маунт")
        SetActionForSlot(31, "empty", nil)
        SetActionForSlot(32, "macro", "БыстроеПеремещ.")
        SetActionForSlot(33, "macro", "Предложить обмен")
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
        SetActionForSlot(127, "empty", nil)
        SetActionForSlot(128, "spell", 374990)
        SetActionForSlot(129, "empty", nil)
        SetActionForSlot(130, "empty", nil)
        SetActionForSlot(131, "empty", nil)
        SetActionForSlot(132, "spell", 372610)
    end
end

-- Делаем функцию доступной глобально
_G.ApplyMacroSettings = ApplyMacroSettings