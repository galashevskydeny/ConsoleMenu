-- Выполнение выбранного пункта меню диалога.

local ConsoleMenu = _G.ConsoleMenu
local Gossip = ConsoleMenu.Gossip

-- Выполнение выбранного пункта по его данным.
function Gossip.SelectOption(data)
    if not data then
        return
    end

    if data.type == "gossip" then
        if data.gossipOptionID ~= nil then
            C_GossipInfo.SelectOption(data.gossipOptionID)
        elseif data.orderIndex ~= nil then
            C_GossipInfo.SelectOptionByIndex(data.orderIndex)
        end
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
