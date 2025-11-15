-- SubtitleFrame.lua

local ConsoleMenu = _G.ConsoleMenu
local parentFrame
local maxLineLength = 100

-- Локальная функция для разбиения текста на строки с учетом максимальной длины
local function splitTextIntoLines(text)
    local lines = {}
    
    -- Вспомогательная функция для группировки предложений
    local function split_and_group_text(text, max_length)
        local sentences = {}
        local result = {}
        local current = ""
        
        -- Разбиваем текст на предложения
        for sentence in text:gmatch("([^%.%!%?%.%.%.]+[%.,%!%?%.%.%.]*)") do
            sentence = sentence:gsub("^%s+", ""):gsub("%s+$", "") -- убираем лишние пробелы
            if sentence ~= "" then
                table.insert(sentences, sentence)
            end
        end
        
        -- Группируем предложения по длине
        for i, sentence in ipairs(sentences) do
            if #current + #sentence + 1 <= max_length then
                if current == "" then
                    current = sentence
                else
                    current = current .. " " .. sentence
                end
            else
                if current ~= "" then
                    table.insert(result, current)
                end
                current = sentence
            end
        end
        
        if current ~= "" then
            table.insert(result, current)
        end
        
        return result
    end
    
    -- Разбиваем текст на строки, убираем лишние переносы и пустые строки
    for line in string.gmatch(text, "[^\r\n]+") do
        local trimmedLine = line:match("^%s*(.-)%s*$") -- Убираем пробелы в начале и конце строки
        if trimmedLine ~= "" then -- Исключаем пустые строки
            if #trimmedLine < maxLineLength then
                table.insert(lines, trimmedLine) -- Сохраняем строку без изменений
            else
                local result = split_and_group_text(trimmedLine, maxLineLength)
                for i, part in ipairs(result) do
                    table.insert(lines, part)
                end
            end
        end
    end
    
    return lines
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

