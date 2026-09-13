-- Выполнение выбранного пункта меню диалога.

local ConsoleMenu = _G.ConsoleMenu
local Gossip = ConsoleMenu.Gossip

-- Выполняет пункт разговора по идентификатору или по порядковому номеру.
local function SelectGossipChoice(optionID, orderIndex)
    optionID = Gossip.Readable(optionID)
    orderIndex = Gossip.Readable(orderIndex)
    if optionID then
        C_GossipInfo.SelectOption(optionID)
        return
    end
    if orderIndex ~= nil then
        C_GossipInfo.SelectOptionByIndex(orderIndex)
    end
end

-- Выполнение выбранного пункта по его данным.
function Gossip.SelectOption(data)
    if not data then
        return
    end

    if data.type == "gossip" then
        SelectGossipChoice(data.gossipOptionID, data.orderIndex)
    elseif data.type == "gossipQuest" and not data.inProgress then
        C_GossipInfo.SelectAvailableQuest(data.questID)
    elseif data.type == "gossipQuest" and data.inProgress then
        C_GossipInfo.SelectActiveQuest(data.questID)
    elseif data.type == "greetingQuest" and not data.inProgress then
        SelectAvailableQuest(data.index)
    elseif data.type == "greetingQuest" and data.inProgress then
        SelectActiveQuest(data.index)
    elseif data.type == "goodbye" then
        C_GossipInfo.CloseGossip()
        CloseQuest()
        if Gossip.HideWindowNow then
            Gossip.HideWindowNow()
        end
    elseif data.type == "acceptQuest" then
        AcceptQuest()
    elseif data.type == "progressQuest" then
        CompleteQuest()
    elseif data.type == "completeQuest" or data.type == "completeQuestInStoryline" or data.type == "completeQuestWithReward" then
        if data.index then
            GetQuestReward(data.index)
        else
            GetQuestReward(1)
        end
    elseif data.type == "reputation" then
        Gossip.ShowReputation(data.reputationText, data.reputationName)
    elseif data.type == "reputationBack" then
        Gossip.BackToGossip(data.reputationName)
    elseif data.type == "completedAccountQuest" then
        CloseQuest()
    end
end

-- Выбор пункта полёта, если карта сама не открылась.
function Gossip.SelectTaxiIfNeeded()
    if Gossip.IsTaxiMapOpen() then
        return
    end

    local options = C_GossipInfo.GetOptions()
    if not options then
        return
    end

    for _, option in pairs(options) do
        if type(option) == "table" and Gossip.IsTaxiOption(option) then
            SelectGossipChoice(option.gossipOptionID, option.orderIndex)
            return
        end
    end
end
