-- GossipFrame.lua

local ConsoleMenu = _G.ConsoleMenu
local parentFrame = ObjectiveTrackerFrame

-- Перемещение и изменение тточек привязки фреймов
local function moveFrames()
    return
end

-- Скрытие ненужных фреймов, регионов и текстур
local function hideFramesAndRegions()
    local elementsToHide = {
        parentFrame.Header,
    }

    -- Добавляем все Header фреймы из parentFrame.modules в elementsToHide
    if parentFrame.modules then
        for _, module in pairs(parentFrame.modules) do
            if module and module.Header then
                table.insert(elementsToHide, module.Header.MinimizeButton)
            end
        end
    end

    -- Скрываем все элементы из списка
    for _, element in ipairs(elementsToHide) do
        if element then
            element:Hide()
            element:SetAlpha(0)
        end
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
