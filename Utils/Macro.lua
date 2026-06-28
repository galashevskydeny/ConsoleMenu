-- Macro.lua
-- Модуль для работы с макросами

local ConsoleMenu = _G.ConsoleMenu

-- Таблица определений всех возможных макросов: имя -> {тело, иконка}
local macroDefinitions = {
    ["Спешиться"] = {"/dismount [mounted, noflying]", "Ability_DragonRiding_LegStretches01"},
    ["Порталы"] = {"/portals", "SPELL_ARCANE_TELEPORTHALLOFTHEGUARDIAN"},
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
        requiredMacros["Порталы"] = macroDefinitions["Порталы"]
    end
    
    if ConsoleMenuDB.actionBarPagePlayerInteraction == 1 then
        requiredMacros["Осмотреть"] = macroDefinitions["Осмотреть"]
        requiredMacros["Предложить обмен"] = macroDefinitions["Предложить обмен"]
        requiredMacros["Порталы"] = macroDefinitions["Порталы"]
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

-- mountID -> индекс журнала для C_MountJournal.Pickup (1..GetNumMounts; 0 = избранное)
local function GetMountDisplayIndexByMountID(mountID)
    if mountID == 0 then
        return 0
    end

    for displayIndex = 1, C_MountJournal.GetNumDisplayedMounts() do
        if C_MountJournal.GetDisplayedMountID(displayIndex) == mountID then
            return displayIndex
        end
    end

    return nil
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
    elseif actionType == "empty" then
        PickupAction(slot)
        ClearCursor()
    elseif actionType == "summonmount" then
        local displayIndex = GetMountDisplayIndexByMountID(actionId)
        if displayIndex then
            C_MountJournal.Pickup(displayIndex)
            PlaceAction(slot)
        end
    elseif actionType == "outfit" then
        C_TransmogOutfitInfo.PickupOutfit(actionId)
        PlaceAction(slot)
    end
end

-- Глобальная функция применения настроек макросов
local function ApplyMacroSettings()
    -- Сначала проверяем и создаем все необходимые макросы
    EnsureAllMacros()

    -- SetActionForSlot(8, "summonmount", 0)
    -- SetActionForSlot(157, "summonmount", 0)
    -- SetActionForSlot(158, "summonmount", 2237)
    -- SetActionForSlot(159, "summonmount", 2265)
    -- C_MountJournal.PickupDynamicFlightMode()
    -- PlaceAction(160)
    
    if ConsoleMenuDB.actionBarPageExploring == 1 then
        -- SetActionForSlot(13, "nil", nil)
        -- SetActionForSlot(14, "macro", "Полезности")
        -- SetActionForSlot(15, "empty", nil)
        -- SetActionForSlot(16, "empty", nil)
        -- Слот под L3 для классовой способности перемещения
        -- SetActionForSlot(17, "empty", nil)
        -- SetActionForSlot(18, "empty", "nil")
        -- SetActionForSlot(19, "empty", nil)
        -- SetActionForSlot(20, "summonmount", 0)
        -- SetActionForSlot(21, "empty", nil)
        -- SetActionForSlot(22, "empty", nil)
        -- SetActionForSlot(23, "empty", nil)
        -- SetActionForSlot(24, "empty", nil)
    end

    if ConsoleMenuDB.actionBarPagePlayerInteraction == 1 then
        SetActionForSlot(25, "nil", nil)
        SetActionForSlot(26, "macro", "Полезности")
        SetActionForSlot(27, "empty", nil)
        SetActionForSlot(28, "empty", nil)
        -- Слот под L3 для классовой способности перемещения
        -- SetActionForSlot(29, "empty", nil)
        SetActionForSlot(30, "macro", "Перемещение")
        SetActionForSlot(31, "empty", nil)
        SetActionForSlot(32, "summonmount", 0)
        SetActionForSlot(33, "empty", nil)
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
        SetActionForSlot(128, "empty", nil)
        SetActionForSlot(129, "empty", nil)
        SetActionForSlot(130, "empty", nil)
        SetActionForSlot(131, "empty", nil)
        SetActionForSlot(132, "empty", nil)
    end

    -- Получаем список нарядов и устанавливаем их с 145 по 156 ячейку (только 12 первых нарядов)
    local outfits = C_TransmogOutfitInfo.GetOutfitsInfo and C_TransmogOutfitInfo.GetOutfitsInfo() or {}
    for i = 1, math.min(12, #outfits) do
        local slot = 144 + i -- 145..156
        local outfit = outfits[i]
        -- id наряда нужен для макроса, если макрос ожидает строковое имя, можно подставить outfit.name
        SetActionForSlot(slot, "outfit", outfit.outfitID)
    end


end

-- Делаем функцию доступной глобально
_G.ApplyMacroSettings = ApplyMacroSettings