-- QuestUseItem.lua
-- Кладёт в ячейку исследования предмет, которым нужно воспользоваться для задания.

local ConsoleMenu = _G.ConsoleMenu

-- Первая ячейка страницы исследования: сюда кладётся предмет задания.
local QUEST_USE_ITEM_SLOT = 25

-- Достаёт номер предмета из ссылки.
local function ItemIDFromLink(link)
    if type(link) ~= "string" then
        return nil
    end

    if C_Item and C_Item.GetItemInfoInstant then
        local itemID = C_Item.GetItemInfoInstant(link)
        if type(itemID) == "number" then
            return itemID
        end
    end

    return tonumber(link:match("item:(%d+)"))
end

-- Предмет, которым нужно воспользоваться, чтобы продвинуть задание.
local function QuestUseItemID(questID)
    if type(questID) ~= "number" or questID <= 0 then
        return nil
    end

    local logIndex = C_QuestLog.GetLogIndexForQuestID(questID)
    if type(logIndex) ~= "number" or logIndex <= 0 or type(GetQuestLogSpecialItemInfo) ~= "function" then
        return nil
    end

    local link, icon = GetQuestLogSpecialItemInfo(logIndex)
    local itemID = ItemIDFromLink(link)

    -- Если номер не удалось прочитать из ссылки, он берётся из подсказки.
    if not itemID and icon and C_TooltipInfo and C_TooltipInfo.GetQuestLogSpecialItem then
        local data = C_TooltipInfo.GetQuestLogSpecialItem(logIndex)
        if type(data) == "table" and type(data.id) == "number" then
            itemID = data.id
        end
    end

    if not itemID then
        return nil
    end

    -- Выполненное задание и задание, готовое к сдаче, больше не держат предмет в ячейке.
    if C_QuestLog.IsComplete(questID) or C_QuestLog.ReadyForTurnIn(questID) then
        return nil
    end

    return itemID
end

-- Ищет предмет в переданном списке слежения и возвращает первый подходящий.
local function FirstWatchedQuestUseItemID(count, questIDAtIndex)
    if type(count) ~= "number" or count <= 0 or type(questIDAtIndex) ~= "function" then
        return nil
    end

    for index = 1, count do
        local itemID = QuestUseItemID(questIDAtIndex(index))
        if itemID then
            return itemID
        end
    end
end

-- Сначала задание в фокусе, затем обычные и мировые задания из списка слежения.
local function FindQuestUseItemID()
    local focusedItemID = QuestUseItemID(C_SuperTrack.GetSuperTrackedQuestID())
    if focusedItemID then
        return focusedItemID
    end

    local watchedItemID = FirstWatchedQuestUseItemID(
        C_QuestLog.GetNumQuestWatches(),
        C_QuestLog.GetQuestIDForQuestWatchIndex
    )
    if watchedItemID then
        return watchedItemID
    end

    if C_QuestLog.GetNumWorldQuestWatches and C_QuestLog.GetQuestIDForWorldQuestWatchIndex then
        return FirstWatchedQuestUseItemID(
            C_QuestLog.GetNumWorldQuestWatches(),
            C_QuestLog.GetQuestIDForWorldQuestWatchIndex
        )
    end
end

-- Убирает действие из ячейки исследования.
local function ClearQuestUseItemSlot()
    PickupAction(QUEST_USE_ITEM_SLOT)
    ClearCursor()
end

-- Кладёт предмет в ячейку исследования или очищает её, если применять больше нечего.
function ConsoleMenu:UpdateQuestUseItemSlot()
    if not ConsoleMenuDB or ConsoleMenuDB.actionBarPageExploring ~= 1 then
        return
    end

    -- В бою и с занятым курсором ячейку не трогаем: общий фрейм вызовет обновление снова.
    if InCombatLockdown() or GetCursorInfo() then
        return
    end

    local itemID = FindQuestUseItemID()
    local actionType, actionID = GetActionInfo(QUEST_USE_ITEM_SLOT)

    if itemID then
        if actionType == "item" and actionID == itemID then
            return
        end

        C_Item.PickupItem(itemID)
        local cursorType, cursorID = GetCursorInfo()
        if cursorType == "item" and cursorID == itemID then
            PlaceAction(QUEST_USE_ITEM_SLOT)
        end
        if GetCursorInfo() then
            ClearCursor()
        end
        return
    end

    if actionType then
        ClearQuestUseItemSlot()
    end
end
