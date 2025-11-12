-- MainActionBar.lua

local ConsoleMenu = _G.ConsoleMenu

local function DrawActionBarSlots(parentFrame)
    local ICON_SIZE = 48
    local ICON_SPACING = 8
    local icons = {}

    for slot = 1, 12 do
        local actionType, actionID, subType = GetActionInfo(slot)
        local iconTexture = GetActionTexture(slot)
        local iconData = {
            id = "ActionBarSlot"..slot,
            width = ICON_SIZE,
            height = ICON_SIZE,
            displayIcon = iconTexture or "Interface\\Icons\\INV_Misc_QuestionMark",
            applyMask = true,
        }

        local icon = ConsoleMenu:CreateIcon(parentFrame, iconData)

        -- Выставляем позицию каждой иконки в ряд
        icon:SetPoint(
            "BOTTOMLEFT",
            parentFrame,
            "BOTTOMLEFT",
            (slot - 1) * (ICON_SIZE + ICON_SPACING),
            0
        )
        icons[slot] = icon
    end

    return icons
end



function ConsoleMenu:SetMainActionBar()
    -- Создаём кастомные слоты панели действий от ConsoleMenu
    if not self.MainActionBarFrame then
        self.MainActionBarFrame = CreateFrame("Frame", "ConsoleMenuMainActionBar", UIParent)
        self.MainActionBarFrame:SetSize(12 * 48 + 11 * 6, 48) -- 12 слотов, 11 промежутков
        self.MainActionBarFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 80)
    end

    if self.MainActionBarIcons then
        for _, icon in ipairs(self.MainActionBarIcons) do
            icon:Hide()
        end
    end

    self.MainActionBarIcons = DrawActionBarSlots(self.MainActionBarFrame)
end

