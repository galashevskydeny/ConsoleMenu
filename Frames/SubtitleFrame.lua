-- SubtitleFrame.lua

local ConsoleMenu = _G.ConsoleMenu
local parentFrame

local frameWidth = 688
local frameHeight = 96

local maxLineLength = 160
local subtitleUpdateTimer = nil

local SubtitleEventPriority = {
    CHAT_MSG_MONSTER_EMOTE = 4,
    CHAT_MSG_MONSTER_SAY = 3,
    CHAT_MSG_MONSTER_YELL = 3,
    CHAT_MSG_MONSTER_WHISPER = 3,
    CHAT_MSG_PARTY_LEADER = 2,
    CHAT_MSG_PARTY = 2,
    CHAT_MSG_INSTANCE_CHAT = 2,
    CHAT_MSG_INSTANCE_CHAT_LEADER = 2,
    CHAT_MSG_RAID = 2,
    CHAT_MSG_RAID_LEADER = 2,
    CHAT_MSG_TEXT_EMOTE = 3,
    GOSSIP_SHOW = 1,
    QUEST_DETAIL = 1,
    QUEST_PROGRESS = 1,
    QUEST_COMPLETE = 1,
    QUEST_GREETING = 1
}

-- Локальная функция для разбиения текста на строки с учетом максимальной длины
local function SplitTextIntoLines(text)
    if not text or text == "" then
        return {}
    end
    
    local lines = {}
    local maxLen = maxLineLength
    
    -- Вспомогательная функция для группировки предложений
    local function split_and_group_text(text, max_length)
        local sentences = {}
        local result = {}
        local current = ""
        
        -- Разбиваем текст на части: теги <...> и обычный текст
        local function addSentences(str, isTag)
            if isTag then
                sentences[#sentences + 1] = str
            else
                for s in str:gmatch("([^%.%!%?%.%.%.]+[%.,%!%?%.%.%.]*)") do
                    s = s:gsub("^%s+", ""):gsub("%s+$", "")
                    if s ~= "" then sentences[#sentences + 1] = s end
                end
            end
        end
        
        -- Обрабатываем все части: теги и текст между ними
        local pos = 1
        for tagStart, tagEnd in text:gmatch("()<[^>]*>()") do
            if pos < tagStart then
                addSentences(text:sub(pos, tagStart - 1), false)
            end
            addSentences(text:sub(tagStart, tagEnd), true)
            pos = tagEnd + 1
        end
        addSentences(text:sub(pos), false)
        
        if #sentences == 0 then
            return {text}
        end
        
        -- Группируем предложения по длине
        for i = 1, #sentences do
            local sentence = sentences[i]
            local hasTag = sentence:find("[<>]")
            
            -- Предложения с тегами не группируются
            if hasTag then
                if current ~= "" then
                    result[#result + 1] = current
                    current = ""
                end
                result[#result + 1] = sentence
            else
                local needSpace = current ~= "" and 1 or 0
                local newLength = #current + needSpace + #sentence
                
                if newLength <= max_length then
                    current = current ~= "" and (current .. " " .. sentence) or sentence
                else
                    if current ~= "" then
                        result[#result + 1] = current
                    end
                    current = sentence
                end
            end
        end
        
        if current ~= "" then
            result[#result + 1] = current
        end
        
        return result
    end
    
    -- Вспомогательная функция для разбиения текста по запятым, двоеточиям и тире
    local function split_by_commas(text, max_length)
        local parts = {}
        local result = {}
        local current = ""
        
        -- Разбиваем текст по запятым, двоеточиям и тире, сохраняя разделители и их форматирование
        local lastPos = 1
        for commaPos in text:gmatch("()[,:]") do
            local part = text:sub(lastPos, commaPos)
            parts[#parts + 1] = part
            lastPos = commaPos + 1
        end
        -- Добавляем оставшуюся часть после последнего разделителя
        if lastPos <= #text then
            parts[#parts + 1] = text:sub(lastPos)
        end
        
        if #parts == 0 then
            return {text}
        end
        
        -- Группируем части по длине, сохраняя оригинальные разделители
        for i = 1, #parts do
            local part = parts[i]
            local newLength = #current + #part
            
            if newLength <= max_length then
                current = current .. part
            else
                if current ~= "" then
                    result[#result + 1] = current
                end
                current = part
            end
        end
        
        if current ~= "" then
            result[#result + 1] = current
        end
        
        return result
    end
    
    -- Разбиваем текст на строки, убираем лишние переносы и пустые строки
    for line in text:gmatch("[^\r\n]+") do
        local trimmedLine = line:match("^%s*(.-)%s*$")
        if trimmedLine ~= "" then
            local grouped = split_and_group_text(trimmedLine, maxLen)
            for i = 1, #grouped do
                local groupedLine = grouped[i]
                if #groupedLine < maxLen then
                    lines[#lines + 1] = groupedLine
                else
                    -- Если строка все еще длиннее maxLen, разбиваем по запятым
                    local commaSplit = split_by_commas(groupedLine, maxLen)
                    for j = 1, #commaSplit do
                        lines[#lines + 1] = commaSplit[j]
                    end
                end
            end
        end
    end
    
    return lines
end

-- Функция для расчета длительности произнесения строки
local function CalculateSpeechDuration(line, event)

    -- Подсчет количества слов в строке
    local function countWords(str)
        local _, count = string.gsub(str, "%S+", "")
        return count
    end

    local wordCount = countWords(line)

    -- Средняя скорость речи (слов в минуту)
    local wordsPerMinute = 150

    -- Дополнительная длительность в секундах
    local additionalDuration = 1.5

    if event and not event:find("CHAT") then
        additionalDuration = 0.5
        wordsPerMinute = 240
    end

    -- Минимальная длительность в секундах
    local minDuration = 3

    -- Расчет длительности
    local duration = 60 * wordCount / wordsPerMinute + additionalDuration

    -- Минимальная длительность, если задана
    if config and minDuration and minDuration > duration then
        duration = minDuration
    end

    return duration
end

-- Функция возвращает строку субтитров с максимальным приоритетом, если её интервал отображения совпадает с текущим моментом
local function GetCurrentSubtitleWithMaxPriority()
    if not ConsoleMenu or not ConsoleMenu.Subtitles then
        return nil
    end

    local now = GetTime()
    local currentSubtitle = nil
    local minPriority = nil


    local displayedSpeaker = ""
    if ConsoleMenu.SubtitleFrame and ConsoleMenu.SubtitleFrame.Speaker and ConsoleMenu.SubtitleFrame.Speaker:IsShown() then
        displayedSpeaker = ConsoleMenu.SubtitleFrame.Speaker:GetText() or ""
    end

    -- Проходим по всем субтитрам от конца к началу и ищем активные
    for i = #ConsoleMenu.Subtitles, 1, -1 do
        local subtitle = ConsoleMenu.Subtitles[i]
        if subtitle and subtitle.startTime and subtitle.stopTime then
            if subtitle.startTime <= now and now <= subtitle.stopTime then
                if not minPriority or subtitle.priority < minPriority then
                    minPriority = subtitle.priority
                    currentSubtitle = subtitle
                elseif subtitle.priority == minPriority then
                    -- При равных приоритетах выбираем субтитр с более поздним startTime
                    if not currentSubtitle or (subtitle.startTime and currentSubtitle.startTime and subtitle.startTime > currentSubtitle.startTime) then
                        currentSubtitle = subtitle
                    end
                end
            end
        end
    end

    return currentSubtitle
end

-- Функция для удаления старых субтитров
local function RemoveOldSubtitles()
    if not ConsoleMenu or not ConsoleMenu.Subtitles then
        return
    end

    local now = GetTime()
    
    -- Удаляем все субтитры, у которых stopTime уже прошло
    for i = #ConsoleMenu.Subtitles, 1, -1 do
        local subtitle = ConsoleMenu.Subtitles[i]
        if subtitle and subtitle.stopTime and subtitle.stopTime <= now then
            table.remove(ConsoleMenu.Subtitles, i)
        end
    end
end

-- Функция для удаления субтитров по приоритету
local function RemoveSubtitlesByPriority(priorityToRemove)
    if not ConsoleMenu or not ConsoleMenu.Subtitles then
        return
    end
    for i = #ConsoleMenu.Subtitles, 1, -1 do
        local subtitle = ConsoleMenu.Subtitles[i]
        if subtitle and subtitle.priority == priorityToRemove then
            table.remove(ConsoleMenu.Subtitles, i)
        end
    end
end

-- Функция для добавления субтитров
function ConsoleMenu:AddSubtitles(event, message, sender)
    if not ConsoleMenu or not ConsoleMenu.Subtitles then
        return
    end

    local priority = SubtitleEventPriority[event] or 1

    local lines = SplitTextIntoLines(message)
    local currentTime = GetTime()
    local startTime = currentTime

    local emotion = false

    if event == "CHAT_MSG_MONSTER_EMOTE" or event == "CHAT_MSG_TEXT_EMOTE" then
        emotion = true
    end

    for i, line in ipairs(lines) do
        print(line)
        local duration = CalculateSpeechDuration(line, event)
        local stopTime = startTime + duration

        if event == "CHAT_MSG_MONSTER_EMOTE" then
            line = string.gsub(line, "%%s", sender or "")
        end

        if line:find("<") then
            -- Строка содержит символ <
            emotion = true
        end

        if line:gsub("[<>]", "") ~= "" then
            -- Создаем таблицу субтитра
            local subtitleData = {
                text = line:gsub("[<>]", ""),
                sender = sender,
                priority = priority,
                event = event,
                duration = duration,
                startTime = startTime,
                stopTime = stopTime,
                emotion = emotion,
                lastLine = (i == #lines),
            }
            
            table.insert(ConsoleMenu.Subtitles, subtitleData)

            startTime = stopTime -- последовательно, строки идут друг за другом
        end

        if line:find(">") then
            -- Строка содержит символ >
            emotion = false
        end
    end
end

-- Функция для пропуска субтитра
function ConsoleMenu:SkipCurrentSubtitle()
    
    local startTime = GetTime()
    local nextSubtitle = nil
    local currentSubtitle = ConsoleMenuFrame.SubtitleFrame.CurrentSubtitle

    for i, subtitle in ipairs(ConsoleMenu.Subtitles) do
        if subtitle.text == currentSubtitle.text then
            ConsoleMenu.Subtitles[i].stopTime = startTime
            break
        end
    end

    RemoveOldSubtitles()

    for i, subtitle in ipairs(ConsoleMenu.Subtitles) do
        if subtitle.event == currentSubtitle.event then
            
            subtitle.startTime = startTime
            subtitle.stopTime = startTime + subtitle.duration
            startTime = subtitle.stopTime
            
            if not nextSubtitle then
                nextSubtitle = subtitle
            end
        end
    end
    
    if nextSubtitle then
        ConsoleMenu:SubtitleFrameUpdate(nextSubtitle)
    end
end

-- Функция для обновления субтитра
function ConsoleMenu:SubtitleFrameUpdate(subtitle)
    if not ConsoleMenuFrame or not ConsoleMenuFrame.SubtitleFrame then
        return
    end

    local frame = ConsoleMenuFrame.SubtitleFrame
    local current

    if subtitle then
        current = subtitle
    else
        current = GetCurrentSubtitleWithMaxPriority()
    end

    ConsoleMenuFrame.SubtitleFrame.CurrentSubtitle = current

    if current then
        if current.emotion then
            -- Обновить текст субтитра
            frame.Emotion:SetText(current.text or "")
            frame.Emotion:Show()

            frame.Speaker:Hide()
            frame.Subtitle:Hide()
        else
            -- Обновить имя говорящего
            local speaker = current.sender or ""

            if speaker ~= "" then
                frame.Speaker:SetText(speaker)
                frame.Speaker:Show()
            else
                frame.Speaker:SetText("")
                frame.Speaker:Hide()
            end

            -- Обновить текст субтитра
            frame.Subtitle:SetText(current.text or "")
            frame.Subtitle:Show()

            frame.Emotion:Hide()
        end

        -- Узнать, сколько осталось времени показа этого субтитра
        local now = GetTime()
        local durationLeft = (current.stopTime or now) - now

        if durationLeft < 0.05 then durationLeft = 0.05 end

        -- Устанавливаем периодический таймер
        if subtitleUpdateTimer then
            subtitleUpdateTimer:Cancel()
        end

        if current.priority ~= 1 or (current.priority == 1 and not current.lastLine) then
            subtitleUpdateTimer = C_Timer.NewTimer(durationLeft, function()
                ConsoleMenu:SubtitleFrameUpdate()
            end)
        end

    else
        -- Нет подходящего субтитра, скрываем оба текста
        frame.Speaker:SetText("")
        frame.Speaker:Hide()
        frame.Subtitle:SetText("")
        frame.Subtitle:Hide()
        frame.Emotion:SetText("")
        frame.Emotion:Hide()

        if subtitleUpdateTimer then
            subtitleUpdateTimer:Cancel()
            subtitleUpdateTimer = nil
        end

        subtitleUpdateTimer = C_Timer.NewTimer(1, function()
            ConsoleMenu:SubtitleFrameUpdate()
        end)
    end
end

-- Функция инициализации SubtitleFrame
function ConsoleMenu:SetSubtitleFrame()
    if ConsoleMenuDB.dialogQuestWindowStyle == 2 then
        return
    end

    if not ConsoleMenu.Subtitles then
        ConsoleMenu.Subtitles = {}
    end

    if not ConsoleMenuFrame.SubtitleFrame then
        local frame = CreateFrame("Frame", "SubtitleFrame", ConsoleMenuFrame)
        ConsoleMenuFrame.SubtitleFrame = frame
    end

    -- Внутри SubtitleFrame создаём два FontString для имени говорящего и субтитра

    -- Фрейм для текста субтитра и имени говорящего
    local frame = ConsoleMenuFrame.SubtitleFrame
    frame:SetSize(frameWidth, frameHeight)
    frame:SetPoint("BOTTOM", ConsoleMenuFrame, "BOTTOM", 0, 260)

    -- Текст для имени говорящего
    if not frame.Speaker then
        frame.Speaker = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.Speaker:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        frame.Speaker:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        frame.Speaker:SetFont("Fonts\\FRIZQT___CYR.TTF", 22, "OUTLINE")
        -- frame.Speaker:SetShadowOffset(1.5, -1)
        frame.Speaker:SetTextColor(1.0, 0.960784, 0.772549, 0.6)
        frame.Speaker:SetJustifyH("CENTER")
        frame.Speaker:SetText("") -- Пустой по умолчанию
        frame.Speaker:SetNonSpaceWrap(true)
        frame.Speaker:SetWordWrap(true)
        frame.Speaker:Hide()
    end

    -- Текст для самого субтитра
    if not frame.Subtitle then
        frame.Subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.Subtitle:SetPoint("TOPLEFT", frame.Speaker, "BOTTOMLEFT", 0, -6)
        frame.Subtitle:SetPoint("TOPRIGHT", frame.Speaker, "BOTTOMRIGHT", 0, -6)
        frame.Subtitle:SetFont("Fonts\\FRIZQT___CYR.TTF", 26, "OUTLINE")
        -- frame.Subtitle:SetShadowOffset(1.5, -1)
        frame.Subtitle:SetTextColor(1.0, 0.960784, 0.772549, 1.0)
        frame.Subtitle:SetJustifyH("CENTER")
        frame.Subtitle:SetText("") -- Пустой по умолчанию
        frame.Subtitle:SetNonSpaceWrap(true)
        frame.Subtitle:SetWordWrap(true)
        frame.Subtitle:Hide()
    end

    -- Текст для самого субтитра
    if not frame.Emotion then
        frame.Emotion = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.Emotion:SetPoint("LEFT", frame, "LEFT", 0, 0)
        frame.Emotion:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
        frame.Emotion:SetFont("Fonts\\FRIZQT___CYR.TTF", 26, "OUTLINE")
        frame.Emotion:SetTextColor(1.0, 0.960784, 0.772549, 0.6)
        frame.Emotion:SetJustifyH("CENTER")
        frame.Emotion:SetText("") -- Пустой по умолчанию
        frame.Emotion:SetNonSpaceWrap(true)
        frame.Emotion:SetWordWrap(true)
        frame.Emotion:Hide()
    end

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    -- Необходимо добавлять субтитры
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
    -- Необходимо удалять субтитры
    frame:RegisterEvent("GOSSIP_CLOSED")
    frame:RegisterEvent("QUEST_FINISHED")
    frame:RegisterEvent("GOSSIP_CONFIRM")
    
    -- Добавляем обработчики для событий субтитров
    local function OnSubtitleEvent(self, event, ...)
        RemoveOldSubtitles()

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
            ConsoleMenu:AddSubtitles(event, ...)
        elseif event == "GOSSIP_SHOW" then
            local message = C_GossipInfo.GetText()
            local sender = UnitName("npc")
            ConsoleMenu:AddSubtitles(event, message, sender)
        elseif event == "QUEST_DETAIL" then
            local message = GetQuestText()
            local sender = UnitName("npc")
            ConsoleMenu:AddSubtitles(event, message, sender)
        elseif event == "QUEST_COMPLETE" then
            local message = GetRewardText()
            local sender = UnitName("npc")
            ConsoleMenu:AddSubtitles(event, message, sender)
        elseif event == "QUEST_PROGRESS" then
            local message = GetProgressText()
            local sender = UnitName("npc")
            ConsoleMenu:AddSubtitles(event, message, sender)
        elseif event == "QUEST_GREETING" then
            local message = GetGreetingText()
            local sender = UnitName("npc")
            ConsoleMenu:AddSubtitles(event, message, sender)
        elseif event == "GOSSIP_CLOSED" or event == "QUEST_FINISHED" or event == "GOSSIP_CONFIRM" then
            RemoveSubtitlesByPriority(1)
        end

        ConsoleMenu:SubtitleFrameUpdate()
    end

    frame:SetScript("OnEvent", OnSubtitleEvent)

end

