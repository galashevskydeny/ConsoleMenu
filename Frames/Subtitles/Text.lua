-- Разбиение текста реплик на строки показа и расчёт длительности.

local ConsoleMenu = _G.ConsoleMenu
local Subtitle = ConsoleMenu.Subtitle

-- Слово перед точкой — инициал или цепочка сокращения вроде «т.д.».
local function IsAbbreviationWord(word)
    if not word then
        return false
    end

    local lettersOnly = word:gsub("%.", "")
    if lettersOnly == "" then
        return false
    end

    if Subtitle.GetTextLength(lettersOnly) <= 1 then
        return true
    end

    return word:find("%.", 1, true) ~= nil
end

-- Точка относится к сокращению или инициалу, а не к концу предложения.
local function IsAbbreviationPeriod(str, periodIndex)
    local before = str:sub(1, periodIndex - 1)
    return IsAbbreviationWord(before:match("([^%s]+)$"))
end

-- Убирает лишнюю точку в конце, не трогая многоточие и сокращения.
local function TrimTrailingPeriod(line)
    line = line:gsub("%s+$", "")
    if line:match("%.%.+%s*>$") or line:match("…%s*>$") then
        return line
    end
    line = line:gsub("%.%s*>$", ">")
    if line:match("%.%.+$") or line:match("…$") then
        return line
    end

    local lastWord = line:match("([^%s]+)$")
    if IsAbbreviationWord(lastWord) then
        return line
    end

    return line:gsub("%.$", "")
end

-- Короткая помета в скобках задаёт тон следующей реплики, а не отдельную строку.
local function IsShortStageDirection(tag)
    local inner = tag:match("^<%s*(.-)%s*>$")
    if not inner or inner == "" then
        return false
    end

    if inner:find("[%s.!?]") then
        return false
    end

    return Subtitle.GetTextLength(inner) <= 24
end

-- Текст внутри полных угловых скобок.
local function GetTagInner(tag)
    return tag:match("^<%s*(.-)%s*>$") or tag
end

-- Разбивает обычный текст на предложения, сохраняя знак в конце.
local function SplitPlainTextIntoSentences(str)
    local sentences = {}
    local len = #str
    local startPos = 1
    local i = 1

    local function emit(finish)
        -- Кладёт найденное предложение в список, отрезая пробелы по краям.
        local s = str:sub(startPos, finish):gsub("^%s+", ""):gsub("%s+$", "")
        if s ~= "" then
            sentences[#sentences + 1] = s
        end
    end

    while i <= len do
        local threeChars = str:sub(i, i + 2)
        if threeChars == "..." or threeChars == "…" then
            emit(i + 2)
            startPos = i + 3
            i = i + 3
        else
            local ch = str:sub(i, i)
            if ch == "." or ch == "!" or ch == "?" then
                if ch == "." and IsAbbreviationPeriod(str, i) then
                    i = i + 1
                else
                    emit(i)
                    startPos = i + 1
                    i = i + 1
                end
            else
                i = i + 1
            end
        end
    end

    if startPos <= len then
        emit(len)
    end

    return sentences
end

-- Разбивает слишком длинную строку по запятым и двоеточиям, сохраняя знаки.
local function SplitByCommas(text, maxLength)
    local parts = {}
    local lastPos = 1

    for commaPos in text:gmatch("()[,:]") do
        parts[#parts + 1] = text:sub(lastPos, commaPos)
        lastPos = commaPos + 1
    end

    if lastPos <= #text then
        parts[#parts + 1] = text:sub(lastPos)
    end

    if #parts == 0 then
        return { text }
    end

    local result = {}
    local current = ""

    for i = 1, #parts do
        local part = parts[i]
        local newLength = Subtitle.GetTextLength(current) + Subtitle.GetTextLength(part)

        if current ~= "" and newLength > maxLength then
            result[#result + 1] = current
            current = part
        else
            current = current .. part
        end
    end

    if current ~= "" then
        result[#result + 1] = current
    end

    return result
end

-- Группирует предложения и ремарки, не превышая ограничение длины.
local function SplitAndGroupText(text, maxLength)
    local units = {}
    local pos = 1

    for tagStart, tagEnd in text:gmatch("()<[^>]*>()") do
        if pos < tagStart then
            local sentences = SplitPlainTextIntoSentences(text:sub(pos, tagStart - 1))
            for i = 1, #sentences do
                units[#units + 1] = { kind = "text", value = sentences[i] }
            end
        end
        -- Индексы указывают на открывающую скобку и на символ сразу после закрывающей.
        units[#units + 1] = { kind = "tag", value = text:sub(tagStart, tagEnd - 1) }
        pos = tagEnd
    end

    local tail = SplitPlainTextIntoSentences(text:sub(pos))
    for i = 1, #tail do
        units[#units + 1] = { kind = "text", value = tail[i] }
    end

    if #units == 0 then
        return { { text = text, emotion = false } }
    end

    local result = {}
    local current = ""
    local groupEmotion = false
    local pendingEmotion = false

    local function flushCurrent()
        -- Сохраняет накопленную группу как отдельную реплику.
        if current == "" then
            return
        end
        result[#result + 1] = {
            text = current,
            emotion = groupEmotion,
        }
        current = ""
        groupEmotion = false
    end

    for i = 1, #units do
        local unit = units[i]
        if unit.kind == "tag" then
            flushCurrent()
            if IsShortStageDirection(unit.value) then
                pendingEmotion = true
            else
                local inner = GetTagInner(unit.value)
                if inner ~= "" then
                    result[#result + 1] = {
                        text = inner,
                        emotion = true,
                    }
                end
                pendingEmotion = false
            end
        else
            local sentence = unit.value
            local needSpace = current ~= "" and 1 or 0
            local newLength = Subtitle.GetTextLength(current) + needSpace + Subtitle.GetTextLength(sentence)

            if current ~= "" and newLength > maxLength then
                flushCurrent()
            end

            if current == "" then
                groupEmotion = pendingEmotion
                pendingEmotion = false
                current = sentence
            else
                current = current .. " " .. sentence
            end
        end
    end

    flushCurrent()
    return result
end

-- Разбивает текст на строки показа с учётом длины, ремарок и заглавной буквы.
function Subtitle.SplitTextIntoLines(text)
    if not text or text == "" or Subtitle.IsSecret(text) then
        return {}
    end

    local lines = {}

    for line in text:gmatch("[^\r\n]+") do
        local trimmedLine = line:match("^%s*(.-)%s*$")
        if trimmedLine ~= "" then
            local grouped = SplitAndGroupText(trimmedLine, Subtitle.maxLineLength)
            for i = 1, #grouped do
                local groupedLine = grouped[i]
                local pieces
                if Subtitle.GetTextLength(groupedLine.text) <= Subtitle.maxLineLength then
                    pieces = { groupedLine.text }
                else
                    pieces = SplitByCommas(groupedLine.text, Subtitle.maxLineLength)
                end

                for j = 1, #pieces do
                    local normalizedLine = TrimTrailingPeriod(pieces[j])
                    if normalizedLine ~= "" then
                        lines[#lines + 1] = {
                            text = Subtitle.CapitalizeFirstLetter(normalizedLine),
                            emotion = groupedLine.emotion,
                        }
                    end
                end
            end
        end
    end

    return lines
end

-- Рассчитывает длительность произнесения строки.
function Subtitle.CalculateSpeechDuration(line, event)
    -- Считает слова в строке.
    local function countWords(str)
        local _, count = string.gsub(str, "%S+", "")
        return count
    end

    local wordCount = countWords(line)
    local wordsPerMinute = 150
    local additionalDuration = 1.5

    if event and (event:find("QUEST") or event == "GOSSIP_SHOW") then
        additionalDuration = 0.5
        wordsPerMinute = 240
    end

    local minDuration = 3
    local duration = 60 * wordCount / wordsPerMinute + additionalDuration

    if duration < minDuration then
        duration = minDuration
    end

    return duration
end
