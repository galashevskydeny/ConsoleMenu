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

    text = text:gsub(":%s*0/1", "")
    text = text:gsub(":%s*1/1%s*$", "")
    text = text:gsub(":%s*1/1%s+", " ")
    text = text:gsub("%s+$", "")
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

local function setupTextCleanupHook()
    if not parentFrame or parentFrame.consoleMenuTextCleanupHooked then
        return
    end

    hooksecurefunc(parentFrame, "Update", cleanAllTrackerLines)
    parentFrame.consoleMenuTextCleanupHooked = true

    if C_Timer and C_Timer.After then
        C_Timer.After(0, cleanAllTrackerLines)
    else
        cleanAllTrackerLines()
    end
end

local function installBlockStringSanitizer()
    if not ObjectiveTrackerBlockMixin or ObjectiveTrackerBlockMixin.consoleMenuStringSanitizerInstalled then
        return
    end

    local originalSetStringText = ObjectiveTrackerBlockMixin.SetStringText
    local originalGetLine = ObjectiveTrackerBlockMixin.GetLine
    local originalAddObjective = ObjectiveTrackerBlockMixin.AddObjective

    ObjectiveTrackerBlockMixin.SetStringText = function(self, fontString, text, useFullHeight, colorStyle, useHighlight)
        if fontString and fontString ~= self.HeaderText then
            text = cleanObjectiveText(text)
        end

        return originalSetStringText(self, fontString, text, useFullHeight, colorStyle, useHighlight)
    end

    ObjectiveTrackerBlockMixin.GetLine = function(self, objectiveKey, optTemplate)
        local line = originalGetLine(self, objectiveKey, optTemplate)
        cleanLine(line)
        return line
    end

    ObjectiveTrackerBlockMixin.AddObjective = function(self, objectiveKey, text, template, useFullHeight, dashStyle, colorStyle, adjustForNoText, overrideHeight)
        text = cleanObjectiveText(text)
        return originalAddObjective(self, objectiveKey, text, template, useFullHeight, dashStyle, colorStyle, adjustForNoText, overrideHeight)
    end

    ObjectiveTrackerBlockMixin.consoleMenuStringSanitizerInstalled = true
end

local function setupDeferredTrackerHooks()
    if parentFrame and parentFrame.consoleMenuDeferredHooksSetup then
        return
    end

    if parentFrame then
        parentFrame.consoleMenuDeferredHooksSetup = true
    end

    local waitFrame = CreateFrame("Frame")
    waitFrame:RegisterEvent("ADDON_LOADED")
    waitFrame:SetScript("OnEvent", function(_, _, addonName)
        if addonName ~= "Blizzard_ObjectiveTracker" then
            return
        end

        installBlockStringSanitizer()
        setupTextCleanupHook()
        cleanAllTrackerLines()
        waitFrame:UnregisterEvent("ADDON_LOADED")
    end)
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
    installBlockStringSanitizer()
    setupTextCleanupHook()
    setupDeferredTrackerHooks()
    --updateTextures()

end
