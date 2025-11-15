-- SubtitleFrame.lua

local ConsoleMenu = _G.ConsoleMenu
local parentFrame
local maxLineLength = 100

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


-- Функция инициализации SubtitleFrame
function ConsoleMenu:SetSubtitleFrame()
    if ConsoleMenuDB.dialogQuestWindowStyle == 2 then
        return
    end

    if not self.SubtitleFrame then
        self.SubtitleFrame = CreateFrame("Frame")
    end

    self.ContextsFrame:RegisterEvent("CHAT_MSG_MONSTER_SAY")
    self.ContextsFrame:RegisterEvent("CHAT_MSG_MONSTER_YELL")
    self.ContextsFrame:RegisterEvent("CHAT_MSG_MONSTER_WHISPER")
    

end

