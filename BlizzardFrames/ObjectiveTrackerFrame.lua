-- GossipFrame.lua

local ConsoleMenu = _G.ConsoleMenu
local parentFrame = ObjectiveTrackerFrame

-- Перемещение и изменение тточек привязки фреймов
local function moveFrames()
    return
end

local function hideAndLockElement(element)
    if not element then
        return
    end

    element:Hide()
    element:SetAlpha(0)

    if element.consoleMenuHideLocked then
        return
    end

    hooksecurefunc(element, "Show", function(frame)
        frame:Hide()
        frame:SetAlpha(0)
    end)

    hooksecurefunc(element, "SetShown", function(frame, shown)
        if shown then
            frame:Hide()
            frame:SetAlpha(0)
        end
    end)

    element:HookScript("OnShow", function(frame)
        frame:Hide()
        frame:SetAlpha(0)
    end)

    element.consoleMenuHideLocked = true
end

local function hideModuleMinimizeButton(module)
    if module and module.Header and module.Header.MinimizeButton then
        hideAndLockElement(module.Header.MinimizeButton)
    end
end

local function cleanObjectiveText(text)
    if type(text) ~= "string" then
        return text
    end

    text = text:gsub("^%s*0/1%s+", "")
    text = text:gsub("%s+0/1%s*$", "")
    text = text:gsub("^%s*0/1%s*$", "")
    text = text:gsub("^%s*1/1%s+", "")
    text = text:gsub("%s+1/1%s*$", "")
    text = text:gsub("^%s*1/1%s*$", "")
    text = text:gsub("^%s*%-%s*", "")
    text = text:gsub(":%s*0/1%s*", "")
    text = text:gsub(":%s*1/1%s*$", "")
    text = text:gsub(":%s*1/1%s+", " ")
    text = text:gsub("%s+$", "")
    text = text:gsub(":%s*$", "")
    text = text:gsub("%s+:", ":")

    return text
end

local function hookLineTextSetter(line)
    if not line or not line.Text or line.Text.consoleMenuTextHooked then
        return
    end

    hooksecurefunc(line.Text, "SetText", function(fontString, text)
        if fontString.consoleMenuSanitizingText then
            return
        end

        local newText = cleanObjectiveText(text)
        if newText ~= text then
            fontString.consoleMenuSanitizingText = true
            fontString:SetText(newText)
            fontString.consoleMenuSanitizingText = nil
        end
    end)

    line.Text.consoleMenuTextHooked = true
end

local function cleanLine(line)
    if not line or not line.Text then
        return
    end

    hookLineTextSetter(line)

    local oldText = line.Text:GetText()
    local newText = cleanObjectiveText(oldText)
    if newText ~= oldText then
        line.Text:SetText(newText)
    end
end

local function cleanBlockUsedLines(block)
    if not block then
        return
    end

    if block.ForEachUsedLine then
        block:ForEachUsedLine(function(line)
            cleanLine(line)
        end)
        return
    end

    if block.usedLines then
        for _, line in pairs(block.usedLines) do
            cleanLine(line)
        end
    end
end

local function cleanAllTrackerLines()
    if not parentFrame or not parentFrame.ForEachModule then
        return
    end

    parentFrame:ForEachModule(function(module)
        if not module then
            return
        end

        -- Прямой проход по фактической структуре: module -> ContentsFrame -> child block -> usedLines.
        if module.ContentsFrame and module.ContentsFrame.GetChildren then
            for _, block in ipairs({ module.ContentsFrame:GetChildren() }) do
                cleanBlockUsedLines(block)
            end
        end

        -- Fallback для модулей с нестандартным перечислением блоков.
        if module.EnumerateActiveBlocks then
            module:EnumerateActiveBlocks(function(block)
                cleanBlockUsedLines(block)
            end)
        end
    end)
end

local function requestTrackerLinesCleanup()
    cleanAllTrackerLines()

    if C_Timer and C_Timer.After then
        -- Первый отложенный проход: после ближайшего layout кадра.
        C_Timer.After(0, cleanAllTrackerLines)
    end
end

local function setupQuestEventsCleanup()
    if parentFrame and parentFrame.consoleMenuQuestEventsCleanupSetup then
        return
    end

    if parentFrame then
        parentFrame.consoleMenuQuestEventsCleanupSetup = true
    end

    local eventFrame = CreateFrame("Frame")
    local events = {
        "QUEST_ACCEPTED",
        "QUEST_LOG_UPDATE",
        "QUEST_WATCH_UPDATE",
        "QUEST_TURNED_IN",
        "QUEST_REMOVED",
        "UNIT_QUEST_LOG_CHANGED",
        "TASK_PROGRESS_UPDATE",
    }

    for _, eventName in ipairs(events) do
        eventFrame:RegisterEvent(eventName)
    end

    eventFrame:SetScript("OnEvent", function()
        requestTrackerLinesCleanup()
    end)

    requestTrackerLinesCleanup()
end

-- Скрытие ненужных фреймов, регионов и текстур
local function hideFramesAndRegions()
    local elementsToHide = {
        parentFrame.Header,
    }

    if parentFrame.modules then
        for _, module in pairs(parentFrame.modules) do
            hideModuleMinimizeButton(module)
        end
    end

    if not parentFrame.consoleMenuAddModuleHooked then
        hooksecurefunc(parentFrame, "AddModule", function(_, module)
            hideModuleMinimizeButton(module)
        end)
        parentFrame.consoleMenuAddModuleHooked = true
    end

    -- Скрываем все элементы из списка
    for _, element in ipairs(elementsToHide) do
        hideAndLockElement(element)
    end

end

-- Обновление текстур фрейсов и регионов
local function updateTextures()
    return
end

function ConsoleMenu:SetObjectiveTrackerFrame()

    --moveFrames()
    hideFramesAndRegions()
    setupQuestEventsCleanup()
    --updateTextures()

end
