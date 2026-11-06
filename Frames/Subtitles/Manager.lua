-- Создание окна субтитров и подписка на события речи и диалога.

local ConsoleMenu = _G.ConsoleMenu
local Subtitle = ConsoleMenu.Subtitle

-- Окно задания ещё видно. Номер задания после принятия остаётся прежним и сам по себе не значит, что окно открыто.
local function IsQuestFrameOpen()
    return QuestFrame and QuestFrame.IsShown and QuestFrame:IsShown()
end

-- Снимает реплики разговора, если отложенное закрытие ещё актуально.
local function FinishDialogueClose(reason, token)
    local matched = token == Subtitle.closeToken
    local questFrameOpen = IsQuestFrameOpen() and 1 or 0
    -- #region agent log
    Subtitle.DebugLog("H1", "Manager.lua:FinishDialogueClose", "delayed close", {
        reason = reason,
        matched = matched and 1 or 0,
        questId = GetQuestID and GetQuestID() or 0,
        questFrame = questFrameOpen,
        queue = Subtitle.queue and #Subtitle.queue or 0,
        t = GetTime(),
    })
    -- #endregion
    if not matched then
        return
    end

    -- Задание ещё на экране: это закрытие предыдущего окна, реплику задания не снимаем.
    if questFrameOpen == 1 then
        -- #region agent log
        Subtitle.DebugLog("H1", "Manager.lua:FinishDialogueClose", "skip close quest open", {
            reason = reason,
            questId = GetQuestID and GetQuestID() or 0,
            questFrame = questFrameOpen,
            t = GetTime(),
        })
        -- #endregion
        return
    end

    local frame = Subtitle.GetFrame()
    local current = frame and frame.CurrentSubtitle
    -- Разговор закрылся в начале первой реплики: даём цепочке договорить.
    -- Текст задания после принятия не оставляем, даже если первая строка ещё не доиграла.
    if current and current.event == "GOSSIP_SHOW" and Subtitle.FirstLineStillPlaying() then
        Subtitle.ReleaseDialogueHold()
        -- #region agent log
        Subtitle.DebugLog("H1", "Manager.lua:FinishDialogueClose", "play out", {
            reason = reason,
            left = current and ((current.stopTime or GetTime()) - GetTime()) or -1,
            t = GetTime(),
        })
        -- #endregion
        Subtitle.ScheduleNextUpdate(current)
        return
    end

    Subtitle.RemoveByPriority(1)
    ConsoleMenu:SubtitleFrameUpdate()
end

-- Длина текста события диалога для отладочной записи.
local function PeekDialogueTextLen(event)
    local text
    if event == "QUEST_DETAIL" then
        text = GetQuestText()
    elseif event == "QUEST_PROGRESS" then
        text = GetProgressText()
    elseif event == "QUEST_COMPLETE" then
        text = GetRewardText()
    elseif event == "QUEST_GREETING" then
        text = GetGreetingText()
    elseif event == "GOSSIP_SHOW" then
        text = C_GossipInfo.GetText()
    end
    if not text or Subtitle.IsSecret(text) then
        return -1
    end
    return #text
end

-- Обрабатывает речь, текст диалога и закрытие окна разговора.
local function OnSubtitleEvent(_, event, ...)
    Subtitle.RemoveOld()

    -- #region agent log
    if event == "GOSSIP_SHOW" or event == "GOSSIP_CLOSED" or event == "GOSSIP_CONFIRM"
        or event == "QUEST_DETAIL" or event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE"
        or event == "QUEST_GREETING" or event == "QUEST_FINISHED" or event == "TAXIMAP_OPENED"
    then
        Subtitle.DebugLog("H1", "Manager.lua:OnSubtitleEvent", "dialogue event", {
            event = event,
            closeToken = Subtitle.closeToken or 0,
            questId = GetQuestID and GetQuestID() or 0,
            textLen = PeekDialogueTextLen(event),
            t = GetTime(),
        })
    end
    -- #endregion

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
            FinishDialogueClose("QUEST_FINISHED", currentToken)
        end)
        return
    elseif event == "GOSSIP_CLOSED" or event == "GOSSIP_CONFIRM" then
        Subtitle.closeToken = Subtitle.closeToken + 1
        local currentToken = Subtitle.closeToken

        C_Timer.After(Subtitle.animationDuration, function()
            FinishDialogueClose(event, currentToken)
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

    -- #region agent log
    if ConsoleMenuDB.subtitleDebugRun ~= "post-fix2" then
        ConsoleMenuDB.subtitleDebugLog = {}
        ConsoleMenuDB.subtitleDebugRun = "post-fix2"
    end
    Subtitle.DebugLog("H1", "Manager.lua:SetSubtitleFrame", "session start", { t = GetTime() })
    -- #endregion

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
