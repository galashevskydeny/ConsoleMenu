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
    --updateTextures()

end
