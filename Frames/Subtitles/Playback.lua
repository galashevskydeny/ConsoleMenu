-- Пропуск и повтор реплик разговора, подсказки кнопок контроллера.

local ConsoleMenu = _G.ConsoleMenu
local Subtitle = ConsoleMenu.Subtitle

-- Пропускает текущую реплику и сразу показывает следующую той же цепочки.
function ConsoleMenu:SkipCurrentSubtitle()
    local frame = Subtitle.GetFrame()
    local currentSubtitle = frame and frame.CurrentSubtitle

    if not currentSubtitle or not Subtitle.queue then
        return
    end

    if not Subtitle.IsNpcDialogueEvent(currentSubtitle.event) then
        return
    end

    Subtitle.RemoveOld()

    local currentIndex = nil
    for i, subtitle in ipairs(Subtitle.queue) do
        if subtitle == currentSubtitle then
            currentIndex = i
            break
        end
    end

    if not currentIndex then
        return
    end

    if currentSubtitle.lastLine then
        return
    end

    currentSubtitle.stopTime = GetTime()
    local nextSubtitle = Subtitle.RebuildTimings(
        currentIndex + 1,
        currentSubtitle.event,
        GetTime()
    )

    ConsoleMenu:SubtitleFrameUpdate(nextSubtitle)
end

-- Начинает текущие реплики персонажа с первой строки.
function ConsoleMenu:RepeatCurrentSubtitles()
    local frame = Subtitle.GetFrame()
    local currentSubtitle = frame and frame.CurrentSubtitle

    if not currentSubtitle or currentSubtitle.priority ~= 1 then
        return
    end

    if Subtitle.CountDialogueChainLines(currentSubtitle) <= 1 or Subtitle.IsFirstDialogueChainLine(currentSubtitle) then
        return
    end

    if not Subtitle.queue then
        return
    end

    local firstIndex = nil
    for i, subtitle in ipairs(Subtitle.queue) do
        if subtitle.event == currentSubtitle.event and subtitle.priority == 1 then
            firstIndex = i
            break
        end
    end

    if not firstIndex then
        return
    end

    local firstSubtitle = Subtitle.RebuildTimings(
        firstIndex,
        currentSubtitle.event,
        GetTime()
    )

    ConsoleMenu:SubtitleFrameUpdate(firstSubtitle)
end

-- Есть ли в цепочке больше одной реплики, и текущая уже не первая.
function ConsoleMenu:CanRepeatCurrentSubtitles()
    local frame = Subtitle.GetFrame()
    local current = frame and frame.CurrentSubtitle
    if not current or not Subtitle.IsNpcDialogueEvent(current.event) then
        return false
    end
    return Subtitle.CountDialogueChainLines(current) > 1 and not Subtitle.IsFirstDialogueChainLine(current)
end

-- Можно ли пропустить текущую реплику разговора с персонажем.
function ConsoleMenu:CanSkipCurrentSubtitle()
    local frame = Subtitle.GetFrame()
    local current = frame and frame.CurrentSubtitle
    if not current or not Subtitle.IsNpcDialogueEvent(current.event) then
        return false
    end
    return not current.lastLine
end

-- Обновляет подсказки пропуска и повтора для разговора с персонажем.
function Subtitle.UpdateDialogueKeyHints(current)
    if current and Subtitle.IsNpcDialogueEvent(current.event) then
        if ConsoleMenu:CanRepeatCurrentSubtitles() then
            ConsoleMenu:AddKeysFrameItem("PAD3", "Повторить")
        else
            ConsoleMenu:DeleteKeysFrameItem("PAD3", "Повторить")
        end
        if ConsoleMenu:CanSkipCurrentSubtitle() then
            ConsoleMenu:AddKeysFrameItem("PAD4", "Пропустить")
        else
            ConsoleMenu:DeleteKeysFrameItem("PAD4", "Пропустить")
        end
        ConsoleMenu:UpdateKeysFrame()
        return
    end

    if not current then
        ConsoleMenu:DeleteKeysFrameItem("PAD3", "Повторить")
        ConsoleMenu:DeleteKeysFrameItem("PAD4", "Пропустить")
        ConsoleMenu:UpdateKeysFrame()
    end
end
