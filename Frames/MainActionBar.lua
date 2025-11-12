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

    for slot = 1, numButtons do
        local button = self:CreateActionButton(mainBar, slot)
        if not button then
            return
        end
        button:SetParent(mainBar)
        button:SetSize(buttonSize, buttonSize)
        button:ClearAllPoints()
        if slot == 1 then
            button:SetPoint("LEFT", mainBar, "LEFT", 0, 0)
        else
            button:SetPoint("LEFT", mainBar.buttons[slot - 1], "RIGHT", buttonSpacing, 0)
        end
        mainBar.buttons[slot] = button
    end

    -- Центрируем фрейм под панелью
    mainBar:SetWidth(totalWidth)
    mainBar:SetHeight(buttonSize)
end

