local ConsoleMenu = _G.ConsoleMenu

local maxItemsCount = 8

local frameWidth = 304

local sectionHeight = 32
local sectionPadding = 0
local iconSize = sectionHeight - sectionPadding * 2

local padding = 12

local frameHeight = sectionHeight * maxItemsCount + padding * (maxItemsCount - 1)

local fontSize = 16

-- Функция для инициализации LootList
function ConsoleMenu:SetKeysFrame()

    if not ConsoleMenuFrame.KeysFrame then
        local frame = CreateFrame("Frame", "KeysFrame", ConsoleMenuFrame)
        ConsoleMenuFrame.KeysFrame = frame
    end

    local frame = ConsoleMenuFrame.KeysFrame
    frame:SetSize(frameWidth, frameHeight)
    frame:SetPoint("BOTTOMRIGHT", ConsoleMenuFrame, "BOTTOMRIGHT", -48, 48)

end