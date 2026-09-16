-- Создание окна субтитров и подписка на события речи и диалога.

local ConsoleMenu = _G.ConsoleMenu
local Subtitle = ConsoleMenu.Subtitle

-- Обрабатывает речь, текст диалога и закрытие окна разговора.
local function OnSubtitleEvent(_, event, ...)
    Subtitle.RemoveOld()

    if event == "CHAT_MSG_MONSTER_SAY" or
       event == "CHAT_MSG_MONSTER_YELL" or
       event == "CHAT_MSG_MONSTER_WHISPER" or
       event == "CHAT_MSG_MONSTER_EMOTE" or
       event == "CHAT_MSG_PARTY_LEADER" or
       event == "CHAT_MSG_PARTY" or
       event == "CHAT_MSG_INSTANCE_CHAT" or
       event == "CHAT_MSG_INSTANCE_CHAT_LEADER" or
       event == "CHAT_MSG_RAID" or
       event == "CHAT_MSG_RAID_LEADER" or
       event == "CHAT_MSG_TEXT_EMOTE"
    then
        -- В бою текст и имя могут быть скрыты клиентом; их всё равно нужно показать в субтитрах.
        local message, sender = ...
        ConsoleMenu:AddSubtitles(event, message, sender)
    elseif event == "GOSSIP_SHOW" then
        if ConsoleMenu.Gossip and ConsoleMenu.Gossip.ShouldSkipForTaxi and ConsoleMenu.Gossip.ShouldSkipForTaxi() then
            return
        end
        Subtitle.closeToken = Subtitle.closeToken + 1
        local message = C_GossipInfo.GetText()
        local sender = UnitName("npc")
        ConsoleMenu:AddSubtitles(event, message, sender)
    elseif event == "TAXIMAP_OPENED" then
        -- Отменяет отложенное скрытие; окно диалога снимет реплику само, без второго исчезновения.
        Subtitle.closeToken = Subtitle.closeToken + 1
        return
    elseif event == "QUEST_DETAIL" then
        Subtitle.closeToken = Subtitle.closeToken + 1
        local message = GetQuestText()
        local sender = UnitName("npc")
        ConsoleMenu:AddSubtitles(event, message, sender)
    elseif event == "QUEST_COMPLETE" then
        Subtitle.closeToken = Subtitle.closeToken + 1
        local message = GetRewardText()
        local sender = UnitName("npc")
        ConsoleMenu:AddSubtitles(event, message, sender)
    elseif event == "QUEST_PROGRESS" then
        Subtitle.closeToken = Subtitle.closeToken + 1
        local message = GetProgressText()
        local sender = UnitName("npc")
        ConsoleMenu:AddSubtitles(event, message, sender)
    elseif event == "QUEST_GREETING" then
        Subtitle.closeToken = Subtitle.closeToken + 1
        local message = GetGreetingText()
        local sender = UnitName("npc")
        ConsoleMenu:AddSubtitles(event, message, sender)
    elseif event == "QUEST_FINISHED" then
        Subtitle.closeToken = Subtitle.closeToken + 1
        local currentToken = Subtitle.closeToken

        C_Timer.After(Subtitle.animationDuration + 0.25, function()
            if currentToken ~= Subtitle.closeToken then
                return
            end

            Subtitle.RemoveByPriority(1)
            ConsoleMenu:SubtitleFrameUpdate()
        end)
        return
    elseif event == "GOSSIP_CLOSED" or event == "GOSSIP_CONFIRM" then
        Subtitle.closeToken = Subtitle.closeToken + 1
        local currentToken = Subtitle.closeToken

        C_Timer.After(Subtitle.animationDuration, function()
            if currentToken ~= Subtitle.closeToken then
                return
            end

            Subtitle.RemoveByPriority(1)
            ConsoleMenu:SubtitleFrameUpdate()
        end)
        return
    end

    ConsoleMenu:SubtitleFrameUpdate()
end

-- Создаёт окно субтитров и подписывается на события речи и диалога.
function ConsoleMenu:SetSubtitleFrame()
    if ConsoleMenuDB.dialogQuestWindowStyle == 2 then
        return
    end

    if not Subtitle.queue then
        Subtitle.queue = {}
    end

    Subtitle.closeToken = Subtitle.closeToken or 0

    if not ConsoleMenuFrame.SubtitleFrame then
        local frame = CreateFrame("Frame", "SubtitleFrame", ConsoleMenuFrame)
        ConsoleMenuFrame.SubtitleFrame = frame
    end

    Subtitle.CreateDisplay(ConsoleMenuFrame.SubtitleFrame)

    local frame = ConsoleMenuFrame.SubtitleFrame
    frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
    frame:UnregisterEvent("CHAT_MSG_SAY")

    frame:RegisterEvent("CHAT_MSG_MONSTER_SAY")
    frame:RegisterEvent("CHAT_MSG_MONSTER_YELL")
    frame:RegisterEvent("CHAT_MSG_MONSTER_WHISPER")
    frame:RegisterEvent("CHAT_MSG_MONSTER_EMOTE")
    frame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
    frame:RegisterEvent("CHAT_MSG_PARTY")
    frame:RegisterEvent("CHAT_MSG_INSTANCE_CHAT")
    frame:RegisterEvent("CHAT_MSG_INSTANCE_CHAT_LEADER")
    frame:RegisterEvent("CHAT_MSG_RAID")
    frame:RegisterEvent("CHAT_MSG_RAID_LEADER")
    frame:RegisterEvent("CHAT_MSG_TEXT_EMOTE")

    frame:RegisterEvent("GOSSIP_SHOW")
    frame:RegisterEvent("QUEST_DETAIL")
    frame:RegisterEvent("QUEST_PROGRESS")
    frame:RegisterEvent("QUEST_COMPLETE")
    frame:RegisterEvent("QUEST_GREETING")
    frame:RegisterEvent("GOSSIP_CLOSED")
    frame:RegisterEvent("QUEST_FINISHED")
    frame:RegisterEvent("GOSSIP_CONFIRM")
    frame:RegisterEvent("TAXIMAP_OPENED")

    frame:SetScript("OnEvent", OnSubtitleEvent)
end
