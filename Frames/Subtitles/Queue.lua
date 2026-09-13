-- Очередь реплик: добавление, удаление и пересчёт времени показа.

local ConsoleMenu = _G.ConsoleMenu
local Subtitle = ConsoleMenu.Subtitle

-- Сколько реплик в текущей цепочке разговора.
function Subtitle.CountDialogueChainLines(subtitle)
    if not subtitle or not Subtitle.queue then
        return 0
    end

    local count = 0
    for _, item in ipairs(Subtitle.queue) do
        if item.event == subtitle.event and item.priority == subtitle.priority then
            count = count + 1
        end
    end
    return count
end

-- Первая ли это реплика текущей цепочки разговора.
function Subtitle.IsFirstDialogueChainLine(subtitle)
    if not subtitle or not Subtitle.queue then
        return true
    end

    for _, item in ipairs(Subtitle.queue) do
        if item.event == subtitle.event and item.priority == subtitle.priority then
            return item == subtitle
        end
    end

    return true
end

-- Возвращает активную реплику с наибольшей важностью.
function Subtitle.GetCurrent()
    if not Subtitle.queue then
        return nil
    end

    local now = GetTime()
    local currentSubtitle = nil
    local minPriority = nil

    for i = #Subtitle.queue, 1, -1 do
        local subtitle = Subtitle.queue[i]
        if subtitle and now >= (subtitle.startTime - 0.1) and now < subtitle.stopTime then
            if not minPriority or subtitle.priority < minPriority then
                minPriority = subtitle.priority
                currentSubtitle = subtitle
            end
        end
    end

    return currentSubtitle
end

-- Удаляет реплики, время показа которых уже истекло.
function Subtitle.RemoveOld()
    if not Subtitle.queue then
        return
    end

    local now = GetTime()

    for i = #Subtitle.queue, 1, -1 do
        local subtitle = Subtitle.queue[i]
        -- Реплики разговора храним до закрытия окна, чтобы их можно было повторить.
        if subtitle and subtitle.priority ~= 1 and subtitle.stopTime <= now then
            table.remove(Subtitle.queue, i)
        end
    end
end

-- Удаляет реплики указанной важности.
function Subtitle.RemoveByPriority(priorityToRemove)
    if not Subtitle.queue then
        return
    end
    for i = #Subtitle.queue, 1, -1 do
        local subtitle = Subtitle.queue[i]
        if subtitle and subtitle.priority == priorityToRemove then
            table.remove(Subtitle.queue, i)
        end
    end
end

-- Назначает время начала цепочки реплик от текущего момента.
function Subtitle.RebuildTimings(fromIndex, eventName, startTime)
    local nextSubtitle = nil
    local queue = Subtitle.queue

    for i = fromIndex, #queue do
        local subtitle = queue[i]
        if subtitle.event == eventName then
            subtitle.startTime = startTime
            subtitle.stopTime = startTime + subtitle.duration
            if not nextSubtitle then
                nextSubtitle = subtitle
            end
            startTime = subtitle.stopTime
        end
    end

    return nextSubtitle
end

-- Добавляет реплики в очередь показа.
function ConsoleMenu:AddSubtitles(event, message, sender)
    if not Subtitle.queue then
        Subtitle.queue = {}
    end

    local priority = Subtitle.eventPriority[event] or 3

    if priority == 1 then
        Subtitle.RemoveByPriority(1)
    end

    local displaySender = Subtitle.GetDisplaySender(event, sender)
    local emotionFromEvent = (event == "CHAT_MSG_MONSTER_EMOTE" or event == "CHAT_MSG_TEXT_EMOTE")

    if Subtitle.IsSecret(message) then
        local duration = 5
        if priority == 1 then
            duration = duration + Subtitle.dialogueHoldDuration
        end

        table.insert(Subtitle.queue, {
            text = message,
            sender = displaySender,
            priority = priority,
            event = event,
            duration = duration,
            startTime = GetTime(),
            stopTime = GetTime() + duration,
            emotion = emotionFromEvent,
            lastLine = true,
        })
        return
    end

    local lines = Subtitle.SplitTextIntoLines(message)
    local startTime = GetTime()
    local firstInsertedIndex = #Subtitle.queue + 1

    for i = 1, #lines do
        local lineData = lines[i]
        local line = lineData.text

        if event == "CHAT_MSG_MONSTER_EMOTE" and not Subtitle.IsSecret(sender) then
            line = string.gsub(line, "%%s", sender or "")
        end

        line = line:gsub("[<>]", "")
        if line ~= "" then
            local duration = Subtitle.CalculateSpeechDuration(line, event)
            local subtitleData = {
                text = line,
                sender = displaySender,
                priority = priority,
                event = event,
                duration = duration,
                startTime = startTime,
                stopTime = startTime + duration,
                emotion = emotionFromEvent or lineData.emotion,
                lastLine = false,
            }

            table.insert(Subtitle.queue, subtitleData)
            startTime = subtitleData.stopTime
        end
    end

    local lastInsertedIndex = #Subtitle.queue
    if lastInsertedIndex >= firstInsertedIndex then
        local lastSubtitle = Subtitle.queue[lastInsertedIndex]
        lastSubtitle.lastLine = true
        if priority == 1 then
            lastSubtitle.duration = lastSubtitle.duration + Subtitle.dialogueHoldDuration
            lastSubtitle.stopTime = lastSubtitle.startTime + lastSubtitle.duration
        end
    end
end
