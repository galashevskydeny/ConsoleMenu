-- Общие сведения и вспомогательные функции модуля субтитров.

local ConsoleMenu = _G.ConsoleMenu

ConsoleMenu.Subtitle = ConsoleMenu.Subtitle or {}

local Subtitle = ConsoleMenu.Subtitle

Subtitle.frameWidth = 640
Subtitle.frameHeight = 96
Subtitle.backgroundOverlapVertical = 200
Subtitle.backgroundOverlapHorizontal = 176
Subtitle.maxLineLength = 120
Subtitle.animationDuration = 0.1
Subtitle.speakerFontSize = 22
Subtitle.subtitleFontSize = 26
Subtitle.frameBottomOffset = 280
Subtitle.fontName = "Fonts\\FRIZQT___CYR.TTF"
Subtitle.backgroundTexture = "Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png"

-- Удержание последней реплики диалога до закрытия окна.
Subtitle.dialogueHoldDuration = 24 * 60 * 60

Subtitle.textColorR = 1.0
Subtitle.textColorG = 0.960784
Subtitle.textColorB = 0.772549

-- Важность событий: меньшее число важнее.
Subtitle.eventPriority = {
    CHAT_MSG_MONSTER_EMOTE = 4,
    CHAT_MSG_TEXT_EMOTE = 4,
    CHAT_MSG_MONSTER_SAY = 3,
    CHAT_MSG_MONSTER_YELL = 3,
    CHAT_MSG_MONSTER_WHISPER = 3,
    CHAT_MSG_PARTY_LEADER = 2,
    CHAT_MSG_PARTY = 2,
    CHAT_MSG_INSTANCE_CHAT = 2,
    CHAT_MSG_INSTANCE_CHAT_LEADER = 2,
    CHAT_MSG_RAID = 2,
    CHAT_MSG_RAID_LEADER = 2,
    GOSSIP_SHOW = 1,
    QUEST_DETAIL = 1,
    QUEST_PROGRESS = 1,
    QUEST_COMPLETE = 1,
    QUEST_GREETING = 1
}

-- Очередь реплик для показа.
Subtitle.queue = Subtitle.queue or {}

-- Соответствие строчных русских букв заглавным.
local cyrillicUpperMap = {
    ["а"] = "А", ["б"] = "Б", ["в"] = "В", ["г"] = "Г", ["д"] = "Д",
    ["е"] = "Е", ["ё"] = "Ё", ["ж"] = "Ж", ["з"] = "З", ["и"] = "И",
    ["й"] = "Й", ["к"] = "К", ["л"] = "Л", ["м"] = "М", ["н"] = "Н",
    ["о"] = "О", ["п"] = "П", ["р"] = "Р", ["с"] = "С", ["т"] = "Т",
    ["у"] = "У", ["ф"] = "Ф", ["х"] = "Х", ["ц"] = "Ц", ["ч"] = "Ч",
    ["ш"] = "Ш", ["щ"] = "Щ", ["ъ"] = "Ъ", ["ы"] = "Ы", ["ь"] = "Ь",
    ["э"] = "Э", ["ю"] = "Ю", ["я"] = "Я",
}

-- Проверяет, что значение скрыто клиентом.
function Subtitle.IsSecret(value)
    return value ~= nil and issecretvalue(value)
end

-- Возвращает длину строки в символах, а не в байтах.
function Subtitle.GetTextLength(str)
    if not str or Subtitle.IsSecret(str) then
        return 0
    end
    return strlenutf8(str)
end

-- События разговора с персонажем и текста задания.
function Subtitle.IsNpcDialogueEvent(event)
    return event == "GOSSIP_SHOW"
        or event == "QUEST_DETAIL"
        or event == "QUEST_PROGRESS"
        or event == "QUEST_COMPLETE"
        or event == "QUEST_GREETING"
end

-- Возвращает текст, который можно передать в элемент интерфейса.
function Subtitle.GetSafeDisplayText(value)
    if Subtitle.IsSecret(value) then
        return value
    end
    return value or ""
end

-- Обрезает название игрового мира у имени отправителя, если значение доступно аддону.
function Subtitle.GetDisplaySender(event, sender)
    if Subtitle.IsSecret(sender) or not sender then
        return sender
    end

    if event:find("CHAT_MSG") and not event:find("_MONSTER_") then
        return sender:match("^([^-]+)") or sender
    end

    return sender
end

-- Возвращает окно субтитров, если оно уже создано.
function Subtitle.GetFrame()
    return ConsoleMenuFrame and ConsoleMenuFrame.SubtitleFrame
end

-- Возвращает следующий символ UTF-8 и его длину в байтах.
function Subtitle.GetUtf8Char(str, index)
    local byte = str:byte(index)
    if not byte then
        return "", 0
    end

    local charLen = 1
    if byte >= 0xC0 then
        if byte < 0xE0 then
            charLen = 2
        elseif byte < 0xF0 then
            charLen = 3
        else
            charLen = 4
        end
    end

    return str:sub(index, index + charLen - 1), charLen
end

-- Делает первую букву заглавной, в том числе для кириллицы.
function Subtitle.CapitalizeFirstLetter(line)
    local i = 1
    local len = #line
    local prefix = ""

    while i <= len do
        if line:sub(i, i) == "<" then
            local tagEnd = line:find(">", i, true)
            if not tagEnd then
                break
            end
            prefix = prefix .. line:sub(i, tagEnd)
            i = tagEnd + 1
        elseif line:sub(i, i):match("%s") then
            prefix = prefix .. line:sub(i, i)
            i = i + 1
        else
            break
        end
    end

    if i > len then
        return line
    end

    local char, charLen = Subtitle.GetUtf8Char(line, i)
    local upperChar = cyrillicUpperMap[char] or char:upper()
    return prefix .. upperChar .. line:sub(i + charLen)
end
