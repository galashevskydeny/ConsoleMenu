-- MainActionBar.lua

local ConsoleMenu = _G.ConsoleMenu

function ConsoleMenu:SetMainActionBar()
    -- Создаем главный фрейм панели действий
    if self.mainActionBar then
        self.mainActionBar:Hide()
        self.mainActionBar:SetParent(nil)
    end

    local mainBar = CreateFrame("Frame", "ConsoleMenuMainActionBar", UIParent)
    mainBar:SetSize(670, 64)
    mainBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 100)
    mainBar:SetFrameStrata("MEDIUM")
    self.mainActionBar = mainBar

    mainBar.buttons = {}

    local numButtons = 12
    local buttonSpacing = 6
    local buttonSize = 52
    local totalWidth = numButtons * buttonSize + (numButtons - 1) * buttonSpacing

    local lastButton = nil
    for slot = 1, numButtons do
        local button = self:CreateActionButton(mainBar, slot)
        if button then
            button:SetParent(mainBar)
            button:SetSize(buttonSize, buttonSize)
            button:ClearAllPoints()
            if lastButton then
                button:SetPoint("LEFT", lastButton, "RIGHT", buttonSpacing, 0)
            else
                button:SetPoint("LEFT", mainBar, "LEFT", 0, 0)
            end
            mainBar.buttons[slot] = button
            lastButton = button
        else
            -- Если кнопка не создана, сохраняем nil в массиве
            mainBar.buttons[slot] = nil
        end
    end

    -- Центрируем фрейм под панелью
    mainBar:SetWidth(totalWidth)
    mainBar:SetHeight(buttonSize)
end

