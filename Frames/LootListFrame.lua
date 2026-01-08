local ConsoleMenu = _G.ConsoleMenu

local maxItemsCount = 5

local frameWidth = 304

local iconSize = 56
local titleFontSize = 24
local fontSize = 20
local padding = 16

local frameHeight = titleFontSize + padding + iconSize * maxItemsCount + padding * (maxItemsCount - 1) + padding + fontSize

local duration = 8
local animationDuration = 0.3

-- Функция для инициализации LootList
function ConsoleMenu:SetLootList()
    if not ConsoleMenu.Items then
        ConsoleMenu.Items = {}
    end

    if not ConsoleMenuFrame.LootListFrame then
        local frame = CreateFrame("Frame", "LootListFrame", ConsoleMenuFrame)
        ConsoleMenuFrame.LootListFrame = frame
    end

    local frame = ConsoleMenuFrame.LootListFrame
    frame:SetSize(frameWidth, frameHeight)
    frame:SetPoint("TOPLEFT", ConsoleMenuFrame.NotificationFrame, "BOTTOMLEFT", 0, -48)
    frame:Show()
    ConsoleMenu:InitFadeAnimations(frame, animationDuration)

    -- Заголовок
    if not frame.Title then
        frame.Title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.Title:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        frame.Title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        frame.Title:SetFont("Fonts\\FRIZQT___CYR.TTF", titleFontSize, "")
        frame.Title:SetTextColor(1.0, 0.960784, 0.772549, 1)
        frame.Title:SetJustifyH("LEFT")

        local text = COLLECTED .. " " .. ITEMS
        local title = string.sub(text, 1, 2) .. string.lower(string.sub(text, 2))
        
        frame.Title:SetText(title)
        frame.Title:SetNonSpaceWrap(true)
        frame.Title:Show()
        frame.Title:SetWordWrap(true)
    end

    -- Счетчик дополнительных предметов
    if not frame.AdditionalItemsCount then
        frame.AdditionalItemsCount = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.AdditionalItemsCount:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
        frame.AdditionalItemsCount:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        frame.AdditionalItemsCount:SetFont("Fonts\\FRIZQT___CYR.TTF", fontSize, "")
        frame.AdditionalItemsCount:SetTextColor(1.0, 0.960784, 0.772549, 1)
        frame.AdditionalItemsCount:SetJustifyH("LEFT")
        frame.AdditionalItemsCount:SetText("и еще N предметов в инвентаре")
        frame.AdditionalItemsCount:Show()
    end

    frame:RegisterEvent("LOOT_OPENED")

    local function OnLootListEvent(self, event, ...)

    end

    frame:SetScript("OnEvent", OnLootListEvent)
end