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

-- Признак открытой карты полётов.
function Gossip.IsTaxiMapOpen()
    if TaxiFrame and TaxiFrame:IsShown() then
        return true
    end
    if FlightMapFrame and FlightMapFrame:IsShown() then
        return true
    end
    local taxiType = Gossip.GetTaxiInteractionType()
    if taxiType and C_PlayerInteractionManager and C_PlayerInteractionManager.IsInteractingWithNpcOfType then
        return C_PlayerInteractionManager.IsInteractingWithNpcOfType(taxiType)
    end
    return false
end

-- Признак пункта полёта в разговоре.
function Gossip.IsTaxiOption(option)
    if not option then
        return false
    end

    local taxiIcon = Gossip.taxiGossipIcon
    local fileIcon = GetFileIDFromPath and GetFileIDFromPath("Interface/GossipFrame/TaxiGossipIcon")
    if option.icon == taxiIcon or option.overrideIconID == taxiIcon then
        return true
    end
    if fileIcon and (option.icon == fileIcon or option.overrideIconID == fileIcon) then
        return true
    end
    return false
end

-- Есть ли среди пунктов разговора полёт.
function Gossip.HasTaxiOption()
    local options = C_GossipInfo.GetOptions()
    if not options then
        return false
    end
    for _, option in pairs(options) do
        if type(option) == "table" and Gossip.IsTaxiOption(option) then
            return true
        end
    end
    return false
end

-- Разговор с распорядителем полётов: карту покажет клиент, своё меню не нужно.
function Gossip.ShouldSkipForTaxi()
    if Gossip.IsTaxiMapOpen() then
        return true
    end

    local numActive = C_GossipInfo.GetNumActiveQuests and C_GossipInfo.GetNumActiveQuests() or 0
    local numAvailable = C_GossipInfo.GetNumAvailableQuests and C_GossipInfo.GetNumAvailableQuests() or 0
    if numActive > 0 or numAvailable > 0 then
        return false
    end

    if Gossip.HasTaxiOption() then
        return true
    end

    return false
end

-- Клиент сам выбрал пункт и не открыл стандартное окно разговора.
function Gossip.DidClientSkipGossipFrame()
    return GossipFrame and not GossipFrame:IsShown()
end

-- Диалог сейчас не нужно показывать: полёт или клиент уже пропустил окно.
function Gossip.ShouldSuppressDialogue()
    if Gossip.ShouldSkipForTaxi() then
        return true
    end
    return Gossip.DidClientSkipGossipFrame()
end
