-- Сбор сведений о заданиях из разговора и приветствия.

local ConsoleMenu = _G.ConsoleMenu
local Gossip = ConsoleMenu.Gossip

-- Копия сведений о задании из разговора, без изменения таблиц клиента.
function Gossip.CopyGossipQuest(quest, inProgress)
    return {
        title = quest.title,
        inProgress = inProgress,
        isComplete = quest.isComplete,
        questID = quest.questID,
        questLineID = quest.questLineID,
    }
end

-- Получение данных квестов при открытии разговора.
function Gossip.GetGossipQuests()
    local activeQuests = C_GossipInfo.GetActiveQuests() or {}
    local availableQuests = C_GossipInfo.GetAvailableQuests() or {}
    local result = {}

    for _, quest in ipairs(activeQuests) do
        table.insert(result, Gossip.CopyGossipQuest(quest, true))
    end
    for _, quest in ipairs(availableQuests) do
        table.insert(result, Gossip.CopyGossipQuest(quest, false))
    end

    return result
end

-- Получение данных квестов при открытии приветствия.
function Gossip.GetGreetingQuests()
    local result = {}
    local numActiveQuests = GetNumActiveQuests()
    local numAvailableQuests = GetNumAvailableQuests()

    if numActiveQuests == 0 and numAvailableQuests == 0 then
        return result
    end

    if numActiveQuests > 0 then
        for i = 1, numActiveQuests do
            local title, isComplete = GetActiveTitle(i)
            local questID = GetActiveQuestID(i)
            table.insert(result, {
                title = title,
                inProgress = true,
                isComplete = isComplete,
                index = i,
                questID = questID,
            })
        end
    end

    if numAvailableQuests > 0 then
        for i = 1, numAvailableQuests do
            local _, _, _, _, questID = GetAvailableQuestInfo(i)
            local title = GetAvailableTitle(i)
            table.insert(result, {
                title = title,
                inProgress = false,
                isComplete = false,
                index = i,
                questID = questID,
            })
        end
    end

    return result
end

-- Сведения о сюжетной цепочке в том же виде, что у клиента.
function Gossip.GetQuestLineForComplete(questID)
    local questLineInfo = C_QuestLine.GetQuestLineInfo(questID, nil, true)
    if not questLineInfo or not questLineInfo.questLineID then
        questLineInfo = C_QuestLine.GetQuestLineInfo(questID)
    end
    if not questLineInfo or not questLineInfo.questLineID then
        return nil
    end
    local questIDs = C_QuestLine.GetQuestLineQuests(questLineInfo.questLineID)
    if not questIDs or #questIDs == 0 then
        return nil
    end
    return questLineInfo, questIDs
end

-- Разговор только про полёт: нет заданий и нет других пунктов.
function Gossip.IsTaxiConversation()
    local quests = Gossip.GetGossipQuests()
    if quests and #quests > 0 then
        return false
    end

    local options = C_GossipInfo.GetOptions() or {}
    if #options == 0 then
        return false
    end

    for _, option in ipairs(options) do
        local icon = option.overrideIconID or option.icon
        if icon ~= Gossip.taxiGossipIcon then
            return false
        end
    end

    return true
end
