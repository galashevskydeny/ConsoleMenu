-- SuperTrackManager.lua

local ConsoleMenu = _G.ConsoleMenu

-- Инициализация сохраненных значений в ConsoleMenuDB
local function InitializeSuperTrackData()
    ConsoleMenuDB.superTrackPreviousQuestId = nil
    ConsoleMenuDB.superTrackPreviousQuestLineID = nil
end

-- Проверка, все ли цели квеста выполнены
local function IsQuestAllObjectivesComplete(questID)
    if not questID or questID == 0 then
        return false
    end
    
    local objectives = C_QuestLog.GetQuestObjectives(questID) or {}
    for _, objInfo in ipairs(objectives) do
        if not objInfo.finished then
            return false
        end
    end
    return true
end

-- Установка фокуса на первом незавершенном квесте в журнале
local function SetFirstIncompleteQuest()
    local totalEntries, _ = C_QuestLog.GetNumQuestLogEntries()
    
    for i = 1, totalEntries do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and not info.isHidden and info.questID > 0 then
            C_SuperTrack.SetSuperTrackedQuestID(info.questID)
            return
        end
    end
end

-- Обработчик событий SuperTrackManager
local function OnEvent(self, event, ...)

    if ConsoleMenuDB.questSuperTrackEnable == 2 then return end

    if event == "QUEST_REMOVED" then
        local questID = ...
        if not questID then return end

        -- Очистка трекинга, если удаленный квест был отслеживаемым
        if C_SuperTrack.GetHighestPrioritySuperTrackingType() == 0 and questID == C_SuperTrack.GetSuperTrackedQuestID() then
            C_SuperTrack.ClearAllSuperTracked()
        end

        -- Возврат фокуса после выхода из локального задания
        if ConsoleMenuDB.questFocusLocalQuests and C_QuestLog.IsWorldQuest(questID) and ConsoleMenuDB.superTrackPreviousQuestId then
            C_SuperTrack.SetSuperTrackedQuestID(ConsoleMenuDB.superTrackPreviousQuestId)
            return
        end

        -- Запись идентификатора цепочки на будущее
        local questLineInfo = C_QuestLine.GetQuestLineInfo(questID)
        
        if questLineInfo and questLineInfo.questLineID then
            ConsoleMenuDB.superTrackPreviousQuestLineID = questLineInfo.questLineID
        else
            ConsoleMenuDB.superTrackPreviousQuestLineID = nil
        end

        -- Установка фокуса на первом квесте в журнале
        if ConsoleMenuDB.questAutoSelectFirstIncomplete then
            SetFirstIncompleteQuest()
        end

    elseif event == "QUEST_LOG_UPDATE" and C_SuperTrack.GetHighestPrioritySuperTrackingType() == 0 then
        local questID = ...
        if not questID then return end
        -- Установка фокуса на незавершенном квесте из этой же цепочки, чтобы не оставлять фокус на фактически выполненном квесте
        local trackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
        
        if not trackedQuestID or trackedQuestID == 0 then return end

        -- Проверяем, все ли цели текущего квеста выполнены
        if not IsQuestAllObjectivesComplete(trackedQuestID) then return end

        -- Ищем следующий незавершенный квест из той же цепочки
        local lineInfo = C_QuestLine.GetQuestLineInfo(trackedQuestID)
        local currentLineID = lineInfo and lineInfo.questLineID
        
        if not currentLineID then return end
        
        local totalEntries, _ = C_QuestLog.GetNumQuestLogEntries()
        for i = 1, totalEntries do
            local info = C_QuestLog.GetInfo(i)
            if info and not info.isHeader and not info.isHidden and info.questID ~= trackedQuestID then
                local otherLine = C_QuestLine.GetQuestLineInfo(info.questID)
                if otherLine ~= nil and currentLineID ~= nil and otherLine.questLineID == currentLineID then
                    if not IsQuestAllObjectivesComplete(info.questID) then
                        C_SuperTrack.SetSuperTrackedQuestID(info.questID)
                        return
                    end
                end
            end
        end

    elseif event == "QUEST_ACCEPTED" and C_SuperTrack.GetHighestPrioritySuperTrackingType() == 0 then
        local questID = ...
        if not questID then return end

        -- Установка фокуса на локальном задании
        if ConsoleMenuDB.questFocusLocalQuests and C_QuestLog.IsWorldQuest(questID) then
            ConsoleMenuDB.superTrackPreviousQuestId = C_SuperTrack.GetSuperTrackedQuestID()
            C_SuperTrack.SetSuperTrackedQuestID(questID)
            return
        end

        -- Установка фокуса на новом взятом квесте текущей цепочки
        local questLineInfo = C_QuestLine.GetQuestLineInfo(questID)
        
        if ConsoleMenuDB.superTrackPreviousQuestLineID and questLineInfo and questLineInfo.questLineID then
            if ConsoleMenuDB.superTrackPreviousQuestLineID == questLineInfo.questLineID then
                C_SuperTrack.ClearAllSuperTracked()
                C_SuperTrack.SetSuperTrackedQuestID(questID)
                return
            end
        else
            -- Если нет предыдущей цепочки, устанавливаем фокус на первый незавершенный квест в журнале
            SetFirstIncompleteQuest()
        end
    end
end

-- Функция инициализации SuperTrackManager
function ConsoleMenu:InitializeSuperTrackManager()
    -- Инициализируем сохраненные данные
    InitializeSuperTrackData()
    
    if not self.SuperTrackManager then
        self.SuperTrackManager = CreateFrame("Frame")
    end

    self.SuperTrackManager:RegisterEvent("QUEST_LOG_UPDATE")
    self.SuperTrackManager:RegisterEvent("QUEST_ACCEPTED")
    self.SuperTrackManager:RegisterEvent("QUEST_REMOVED")
    
    self.SuperTrackManager:SetScript("OnEvent", OnEvent)
end

