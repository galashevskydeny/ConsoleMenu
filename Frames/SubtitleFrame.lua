-- SubtitleFrame.lua

local ConsoleMenu = _G.ConsoleMenu
local parentFrame
local maxLineLength = 100
local subtitleUpdateTimer = nil

local SubtitleEventPriority = {
    CHAT_MSG_MONSTER_SAY = 3,
    CHAT_MSG_MONSTER_YELL = 3,
    CHAT_MSG_MONSTER_WHISPER = 3,
    GOSSIP_SHOW = 1,
    QUEST_DETAIL = 1,
    QUEST_PROGRESS = 1,
    QUEST_COMPLETE = 1,
    QUEST_GREETING = 1
}

-- Локальная функция для разбиения текста на строки с учетом максимальной длины
local function splitTextIntoLines(text)
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
        
        -- Разбиваем текст на предложения (оптимизированное регулярное выражение)
        for sentence in text:gmatch("([^%.%!%?]+[%.,%!%?]?)") do
            sentence = sentence:match("^%s*(.-)%s*$") -- убираем пробелы одним вызовом
            if sentence ~= "" then
                sentences[#sentences + 1] = sentence
            end
        end
        
        if #sentences == 0 then
            return {text}
        end
        
        -- Группируем предложения по длине
        for i = 1, #sentences do
            local sentence = sentences[i]
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
        
        if current ~= "" then
            result[#result + 1] = current
        end
        
        return result
    end
    
    -- Разбиваем текст на строки, убираем лишние переносы и пустые строки
    for line in text:gmatch("[^\r\n]+") do
        local trimmedLine = line:match("^%s*(.-)%s*$")
        if trimmedLine ~= "" then
            if #trimmedLine < maxLen then
                lines[#lines + 1] = trimmedLine
            else
                local grouped = split_and_group_text(trimmedLine, maxLen)
                for i = 1, #grouped do
                    lines[#lines + 1] = grouped[i]
                end
            end
        end
    end
    
    return lines
end

-- Функция для расчета длительности произнесения строки
local function calculateSpeechDuration(line)

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

-- Функция для добавления субтитров
local function AddSubtitles(event, message, sender)
    if not ConsoleMenu or not ConsoleMenu.Subtitles then
        return
    end

    local priority = SubtitleEventPriority[event] or 1

    local lines = splitTextIntoLines(message)

    local currentTime = GetTime()
    local startTime = currentTime
    for i, line in ipairs(lines) do
        local duration = calculateSpeechDuration(line)
        local stopTime = startTime + duration
        
        -- Вычисляем диапазон секунд для этого субтитра
        local startSec = math.floor(startTime)
        local stopSec = math.ceil(stopTime)
        
        -- Создаем таблицу субтитра
        local subtitleData = {
            text = line,
            sender = sender,
            priority = priority,
            event = event,
            duration = duration
        }
        
        -- Добавляем субтитр в хэш-таблицу по секундам
        for t = startSec, stopSec do
            if not ConsoleMenu.Subtitles[t] then
                ConsoleMenu.Subtitles[t] = {}
            end
            table.insert(ConsoleMenu.Subtitles[t], subtitleData)
        end

        startTime = stopTime -- последовательно, строки идут друг за другом
    end
end

-- Функция для удаления старых субтитров
local function RemoveOldSubtitles()
    if not ConsoleMenu or not ConsoleMenu.Subtitles then
        return
    end

    local nowSec = math.floor(GetTime())

    -- Быстро найдём минимальный и максимальный ключи
    local minKey, maxKey
    for t in pairs(ConsoleMenu.Subtitles) do
        if not minKey or t < minKey then minKey = t end
        if not maxKey or t > maxKey then maxKey = t end
    end

    if not minKey or minKey >= nowSec then
        return
    end

    -- Удаляем только ключи меньше nowSec, двигаясь подряд по диапазону
    for t = minKey, nowSec - 1 do
        if ConsoleMenu.Subtitles[t] then
            ConsoleMenu.Subtitles[t] = nil
        end
    end
end

-- Функция возвращает строку субтитров с максимальным приоритетом, если её интервал отображения совпадает с текущим моментом
local function GetCurrentSubtitleWithMaxPriority()
    if not ConsoleMenu or not ConsoleMenu.Subtitles then
        return nil
    end

    local now = GetTime()
    local nowSec = math.floor(now)
    local subs = ConsoleMenu.Subtitles[nowSec]
    if not subs then return nil end

    local currentSubtitle = nil
    local minPriority = nil

    for _, subtitle in ipairs(subs) do
        if (not minPriority) or (subtitle.priority < minPriority) then
            minPriority = subtitle.priority
            currentSubtitle = subtitle
        end
    end

    return currentSubtitle
end

local function SubtitleFrameUpdate()
    if not ConsoleMenu or not ConsoleMenu.SubtitleFrame then
        return
    end

    local frame = ConsoleMenu.SubtitleFrame
    local current = GetCurrentSubtitleWithMaxPriority()

    if current then
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

        -- Узнать, сколько осталось времени показа этого субтитра
        local now = GetTime()
        local durationLeft = (current.stopTime or now) - now

        if durationLeft < 0.05 then durationLeft = 0.05 end

        -- Устанавливаем периодический таймер
        if subtitleUpdateTimer then
            subtitleUpdateTimer:Cancel()
        end

        subtitleUpdateTimer = C_Timer.NewTimer(durationLeft, SubtitleFrameUpdate)
    else
        -- Нет подходящего субтитра, скрываем оба текста
        frame.Speaker:SetText("")
        frame.Speaker:Hide()
        frame.Subtitle:SetText("")
        frame.Subtitle:Hide()

        if subtitleUpdateTimer then
            subtitleUpdateTimer:Cancel()
            subtitleUpdateTimer = nil
        end

        -- Проверяем каждую секундочку снова
        subtitleUpdateTimer = C_Timer.NewTimer(1, SubtitleFrameUpdate)
    end
end

ConsoleMenu.SubtitleFrameUpdate = SubtitleFrameUpdate



-- Функция инициализации SubtitleFrame
function ConsoleMenu:SetSubtitleFrame()
    if ConsoleMenuDB.dialogQuestWindowStyle == 2 then
        return
    end

    if not ConsoleMenu.Subtitles then
        ConsoleMenu.Subtitles = {}
    end

    if not self.SubtitleFrame then
        self.SubtitleFrame = CreateFrame("Frame")
    end

    -- Внутри SubtitleFrame создаём два FontString для имени говорящего и субтитра

    -- Фрейм для текста субтитра и имени говорящего
    local frame = self.SubtitleFrame
    frame:SetSize(688, 120)
    frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 310)

    -- Текст для имени говорящего
    if not frame.Speaker then
        frame.Speaker = frame:CreateFontString(nil, "OVERLAY", nil)
        frame.Speaker:SetPoint("TOP", frame, "TOP", 0, -10)
        frame.Speaker:SetFont("Fonts\\FRIZQT___CYR.TTF", 12, "SLUG")
        frame.Speaker:SetTextColor(1.0, 0.960784, 0.772549, 0.5)
        frame.Speaker:SetJustifyH("CENTER")
        frame.Speaker:SetWidth(688)
        frame.Speaker:SetText("") -- Пустой по умолчанию
        frame.Speaker:Hide()
    end

    -- Текст для самого субтитра
    if not frame.Subtitle then
        frame.Subtitle = frame:CreateFontString(nil, "OVERLAY", nil)
        frame.Subtitle:SetPoint("TOP", frame.Speaker, "BOTTOM", 0, -8)
        frame.Subtitle:SetFont("Fonts\\FRIZQT___CYR.TTF", 16, "SLUG")
        frame.Subtitle:SetTextColor(1.0, 0.960784, 0.772549, 1.0)
        frame.Subtitle:SetJustifyH("CENTER")
        frame.Subtitle:SetWidth(688)
        frame.Subtitle:SetText("") -- Пустой по умолчанию
        frame.Subtitle:Hide()
    end

    self.ContextsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    -- Необходимо добавлять субтитры
    self.ContextsFrame:RegisterEvent("CHAT_MSG_MONSTER_SAY")
    self.ContextsFrame:RegisterEvent("CHAT_MSG_MONSTER_YELL")
    self.ContextsFrame:RegisterEvent("CHAT_MSG_MONSTER_WHISPER")

    self.ContextsFrame:RegisterEvent("GOSSIP_SHOW")
    self.ContextsFrame:RegisterEvent("QUEST_DETAIL")
    self.ContextsFrame:RegisterEvent("QUEST_PROGRESS")
    self.ContextsFrame:RegisterEvent("QUEST_COMPLETE")
    self.ContextsFrame:RegisterEvent("QUEST_GREETING")

    -- Необходимо удалять субтитры
    self.ContextsFrame:RegisterEvent("GOSSIP_CLOSED")
    self.ContextsFrame:RegisterEvent("QUEST_FINISHED")
    
    -- Добавляем обработчики для событий субтитров
    local function OnSubtitleEvent(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            SubtitleFrameUpdate()
        end
        if event == "CHAT_MSG_MONSTER_SAY" or
           event == "CHAT_MSG_MONSTER_YELL" or
           event == "CHAT_MSG_MONSTER_WHISPER" or
           event == "GOSSIP_SHOW" or
           event == "QUEST_DETAIL" or
           event == "QUEST_PROGRESS" or
           event == "QUEST_COMPLETE" or
           event == "QUEST_GREETING" then
            AddSubtitles(event, ...)
            SubtitleFrameUpdate()
        end

        RemoveOldSubtitles()
    end

    self.ContextsFrame:SetScript("OnEvent", OnSubtitleEvent)

end

