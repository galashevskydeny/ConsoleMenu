-- SubtitleFrame.lua

local ConsoleMenu = _G.ConsoleMenu
local parentFrame

local frameWidth = 688
local frameHeight = 96
local backgroundOverlapVertical = 200
local backgroundOverlapHorizontal = 160

local maxLineLength = 160
local subtitleUpdateTimer = nil

local animationDuration = 0.1

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

    if issecretvalue(text) then
        return {}
    end

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
        
        -- Разбиваем текст по запятым и двоеточиям, исключая сами разделители
        local lastPos = 1
        for commaPos in text:gmatch("()[,:]") do
            local part = text:sub(lastPos, commaPos - 1)
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

    if event and (event:find("QUEST") or event == "GOSSIP_SHOW") then
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

    -- Проходим по всем субтитрам от конца к началу и ищем активные
    for i = #ConsoleMenu.Subtitles, 1, -1 do
        local subtitle = ConsoleMenu.Subtitles[i]
        if subtitle and now >= (subtitle.startTime - 0.1) and now <= subtitle.stopTime then
            if not minPriority or subtitle.priority < minPriority then
                minPriority = subtitle.priority
                currentSubtitle = subtitle
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
    -- Безопасное удаление: итерация в обратном порядке
    for i = #ConsoleMenu.Subtitles, 1, -1 do
        local subtitle = ConsoleMenu.Subtitles[i]
        if subtitle and subtitle.stopTime <= now then
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

    local priority = SubtitleEventPriority[event] or 3

    if issecretvalue(message) then
        local currentTime = GetTime()
        local duration = 5
        local startTime = currentTime
        local stopTime = startTime + duration

        local emotion = (event == "CHAT_MSG_MONSTER_EMOTE" or event == "CHAT_MSG_TEXT_EMOTE")

        local displaySender = sender
        if event:find("CHAT_MSG") and not event:find("_MONSTER_") and not issecretvalue(sender) then
            displaySender = sender:match("^([^-]+)") or sender
        end

        table.insert(ConsoleMenu.Subtitles, {
            text = message,
            sender = displaySender,
            priority = priority,
            event = event,
            duration = duration,
            startTime = startTime,
            stopTime = stopTime,
            emotion = emotion,
            lastLine = true,
        })
        return
    end

    local lines = SplitTextIntoLines(message)
    local currentTime = GetTime()
    local startTime = currentTime

    local emotion = false

    if event == "CHAT_MSG_MONSTER_EMOTE" or event == "CHAT_MSG_TEXT_EMOTE" then
        emotion = true
    end

    for i, line in ipairs(lines) do
        local duration = CalculateSpeechDuration(line, event)
        if priority == 1 and i == #lines then
            duration = duration + 24 * 60 * 60
        end
        
        local stopTime = startTime + duration

        if event == "CHAT_MSG_MONSTER_EMOTE" then
            line = string.gsub(line, "%%s", sender or "")
        end

        if line:find("<") then
            -- Строка содержит символ <
            emotion = true
        end

        -- Убираем название игрового мира из отправителя игрока
        -- Если event содержит CHAT_MSG и не содержит _MONSTER_, обрезаем у sender все после дефиса
        if event:find("CHAT_MSG") and not event:find("_MONSTER_") and not issecretvalue(sender) then
            sender = sender:match("^([^-]+)") or sender
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

    -- Безопасно получаем текущий фрейм и субтитр
    local frame = ConsoleMenuFrame and ConsoleMenuFrame.SubtitleFrame
    local currentSubtitle = frame and frame.CurrentSubtitle

    if not currentSubtitle or not ConsoleMenu or not ConsoleMenu.Subtitles then
        return
    end

    -- Сначала удаляем старые субтитры (чтобы не сломать индексы позже)
    RemoveOldSubtitles()

    -- щем текущий субтитр по ссылке
    local currentIndex = nil
    for i, subtitle in ipairs(ConsoleMenu.Subtitles) do
        if subtitle == currentSubtitle then
            currentIndex = i
            break -- важно остановиться сразу
        end
    end

    -- Если не нашли — выходим (защита от рассинхрона)
    if not currentIndex then
        return
    end

    -- Завершаем текущий субтитр (если это не последняя строка)
    if not currentSubtitle.lastLine then
        currentSubtitle.stopTime = GetTime()
    end

    -- 🔹 Перестраиваем только следующие субтитры того же события
    local startTime = GetTime()
    local nextSubtitle = nil

    for i = currentIndex + 1, #ConsoleMenu.Subtitles do
        local subtitle = ConsoleMenu.Subtitles[i]

        -- Работаем только с той же "цепочкой" (тем же событием)
        if subtitle.event == currentSubtitle.event then

            -- Пересчитываем тайминги последовательно
            subtitle.startTime = startTime
            subtitle.stopTime = startTime + subtitle.duration

            -- Первый подходящий — это следующий субтитр
            if not nextSubtitle then
                nextSubtitle = subtitle
            end

            -- Сдвигаем время дальше по цепочке
            startTime = subtitle.stopTime
        end
    end

    -- Если есть следующий субтитр — сразу показываем его
    if nextSubtitle then
        ConsoleMenu:SubtitleFrameUpdate(nextSubtitle)
    end
end

-- Размеры строк с секретным текстом возвращают secret number — их нельзя использовать в арифметике аддона.
local function setSubtitleBackgroundSizeFromContent(frame, contentWidth, contentHeight)
    local width = contentWidth
    if issecretvalue(contentWidth) or issecretvalue(contentHeight) then
        frame.Background:SetSize(
            frameWidth + backgroundOverlapHorizontal,
            frameHeight + backgroundOverlapVertical
        )
    else
        if contentWidth > 160 then
            width = contentWidth + backgroundOverlapHorizontal
        else
            width = frameWidth + backgroundOverlapHorizontal / 4
        end
        frame.Background:SetSize(
            width,
            contentHeight + backgroundOverlapVertical
        )
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
        -- Сбрасываем текст субтитров
        frame.Speaker:SetText("")
        frame.Subtitle:SetText("")
        frame.Emotion:SetText("")

        if current.emotion then
            -- Обновить текст субтитра
            frame.Emotion:SetText(current.text or "")
            frame.Emotion:Show()

            local width = frame.Emotion:GetStringWidth()
            local height = frame.Emotion:GetStringHeight()
            setSubtitleBackgroundSizeFromContent(frame, width, height)

            frame.Background:ClearAllPoints()
            frame.Background:SetPoint("CENTER", frame.Emotion, "CENTER", 0, 0)

            frame.Speaker:Hide()
            frame.Subtitle:Hide()
        else
            -- Обновить имя говорящего
            local speaker = current.sender or ""

            frame.Speaker:SetText(speaker)
            frame.Speaker:Show()

            local speakerH = frame.Speaker:GetStringHeight()

            -- Обновить текст субтитра
            frame.Subtitle:SetText(current.text or "")
            frame.Subtitle:Show()

            local subW = frame.Subtitle:GetStringWidth()
            local subH = frame.Subtitle:GetStringHeight()
            if issecretvalue(speakerH) or issecretvalue(subW) or issecretvalue(subH) then
                setSubtitleBackgroundSizeFromContent(frame, frameWidth, frameHeight)
            else
                setSubtitleBackgroundSizeFromContent(frame, subW, speakerH + subH)
            end

            frame.Background:ClearAllPoints()
            frame.Background:SetPoint("CENTER", frame.Subtitle, "CENTER", 0, 10)

            frame.Emotion:Hide()
        end

        if current.event == "GOSSIP_SHOW" or current.event == "QUEST_GREETING" or current.event == "QUEST_PROGRESS" or current.event == "QUEST_COMPLETE" or current.event == "QUEST_ACCEPTED" or current.event == "QUEST_TURNED_IN" or current.event == "QUEST_DETAIL" then
            
            if not current.lastLine or current.lastLine == false then
                ConsoleMenu:AddKeysFrameItem("PAD4", "Пропустить")
                ConsoleMenu:UpdateKeysFrame()
            else
                ConsoleMenu:DeleteKeysFrameItem("PAD4")
                ConsoleMenu:UpdateKeysFrame()
            end
        
        elseif current.event == "GOSSIP_CLOSED" or current.event == "QUEST_FINISHED" or current.event == "GOSSIP_CONFIRM" then
            ConsoleMenu:DeleteKeysFrameItem("PAD4")
            ConsoleMenu:UpdateKeysFrame()
        end

        if not frame:IsShown() then
            ConsoleMenu:AnimatedShow(frame)
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
        -- Нет подходящего субтитра, скрываем субтитр
        ConsoleMenu:AnimatedHide(frame)

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
    frame:SetPoint("BOTTOM", ConsoleMenuFrame, "BOTTOM", 0, 280)
    frame:Hide()
    ConsoleMenu:InitFadeAnimations(frame, animationDuration)

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

    if not frame.Background then
        frame.Background = frame:CreateTexture(nil, "BACKGROUND")
        frame.Background:SetPoint("CENTER", frame, "CENTER", 0, 0)
        frame.Background:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png")
        frame.Background:SetSize(frameWidth, frameHeight)
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

    frame:RegisterEvent("CHAT_MSG_SAY")

    frame:RegisterEvent("GOSSIP_SHOW")
    frame:RegisterEvent("QUEST_DETAIL")
    frame:RegisterEvent("QUEST_PROGRESS")
    frame:RegisterEvent("QUEST_COMPLETE")
    frame:RegisterEvent("QUEST_GREETING")
    -- Необходимо удалять субтитры
    frame:RegisterEvent("GOSSIP_CLOSED")
    frame:RegisterEvent("QUEST_FINISHED")
    frame:RegisterEvent("GOSSIP_CONFIRM")
    
    local subtitleCloseToken = 0

    local function HasDialogueContext()
        local questID = GetQuestID()
        if questID and questID ~= 0 then
            return true
        end

        local gossipActive = C_GossipInfo.GetActiveQuests()
        if gossipActive and #gossipActive > 0 then
            return true
        end

        local gossipAvailable = C_GossipInfo.GetAvailableQuests()
        if gossipAvailable and #gossipAvailable > 0 then
            return true
        end

        local gossipOptions = C_GossipInfo.GetOptions()
        if gossipOptions and #gossipOptions > 0 then
            return true
        end

        local greetingActive = GetNumActiveQuests and GetNumActiveQuests() or 0
        local greetingAvailable = GetNumAvailableQuests and GetNumAvailableQuests() or 0
        if greetingActive > 0 or greetingAvailable > 0 then
            return true
        end

        return false
    end

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
           event == "CHAT_MSG_TEXT_EMOTE" or
           event == "CHAT_MSG_SAY"
        then
            ConsoleMenu:AddSubtitles(event, ...)
        elseif event == "GOSSIP_SHOW" then
            subtitleCloseToken = subtitleCloseToken + 1
            local message = C_GossipInfo.GetText()
            local sender = UnitName("npc")
            ConsoleMenu:AddSubtitles(event, message, sender)
        elseif event == "QUEST_DETAIL" then
            subtitleCloseToken = subtitleCloseToken + 1
            local message = GetQuestText()
            local sender = UnitName("npc")
            ConsoleMenu:AddSubtitles(event, message, sender)
        elseif event == "QUEST_COMPLETE" then
            subtitleCloseToken = subtitleCloseToken + 1
            local message = GetRewardText()
            local sender = UnitName("npc")
            ConsoleMenu:AddSubtitles(event, message, sender)
        elseif event == "QUEST_PROGRESS" then
            subtitleCloseToken = subtitleCloseToken + 1
            local message = GetProgressText()
            local sender = UnitName("npc")
            ConsoleMenu:AddSubtitles(event, message, sender)
        elseif event == "QUEST_GREETING" then
            subtitleCloseToken = subtitleCloseToken + 1
            local message = GetGreetingText()
            local sender = UnitName("npc")
            ConsoleMenu:AddSubtitles(event, message, sender)
        elseif event == "QUEST_FINISHED" then
            subtitleCloseToken = subtitleCloseToken + 1
            local currentToken = subtitleCloseToken
            local questFinishedDelay = animationDuration + 0.2

            C_Timer.After(questFinishedDelay, function()
                if currentToken ~= subtitleCloseToken then
                    return
                end

                if HasDialogueContext() then
                    return
                end

                RemoveSubtitlesByPriority(1)
                ConsoleMenu:SubtitleFrameUpdate()
            end)
            return
        elseif event == "GOSSIP_CLOSED" or event == "GOSSIP_CONFIRM" then
            subtitleCloseToken = subtitleCloseToken + 1
            local currentToken = subtitleCloseToken

            C_Timer.After(animationDuration + 0.1, function()
                if currentToken ~= subtitleCloseToken then
                    return
                end

                if HasDialogueContext() then
                    return
                end

                RemoveSubtitlesByPriority(1)
                ConsoleMenu:SubtitleFrameUpdate()
            end)
            return
        end

        ConsoleMenu:SubtitleFrameUpdate()
    end

    frame:SetScript("OnEvent", OnSubtitleEvent)

end

