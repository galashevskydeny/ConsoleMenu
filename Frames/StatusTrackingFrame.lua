local ConsoleMenu = _G.ConsoleMenu

local frameHeight = 18
local macbookNotchOffset = 16
local padding = 12

local fontSize = 20


local frameWidth = (308 / 16) * frameHeight

local animationDuration = 0.3

function ConsoleMenu:SetStatusTrackingFrame()

    if ConsoleMenuDB.statusTrackingBarManagerStyle == 1 then return end

    if not ConsoleMenuFrame.StatusTrackingFrame then
        local frame = CreateFrame("Frame", "StatusTrackingFrame", ConsoleMenuFrame)
        
        -- Простой StatusBar (все методы уже есть в WoW API)
        local statusBar = CreateFrame("StatusBar", nil, frame)
        statusBar:SetAllPoints(frame)
        statusBar:SetStatusBarTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\healthBar.png")
        statusBar:SetStatusBarColor(1.0, 0.960784, 0.772549, 1)
        statusBar:SetMinMaxValues(0, 100)
        statusBar:SetValue(20)
        
        frame.StatusBar = statusBar
        ConsoleMenuFrame.StatusTrackingFrame = frame
    end

    local frame = ConsoleMenuFrame.StatusTrackingFrame
    frame:SetSize(frameWidth, frameHeight)
    frame:SetPoint("TOP", ConsoleMenuFrame, "TOP", 0, -(48 + macbookNotchOffset))
    ConsoleMenu:InitFadeAnimations(frame, animationDuration)

    if not frame.Background then
        frame.Background = frame:CreateTexture(nil, "BACKGROUND")
        frame.Background:SetAllPoints()
        frame.Background:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\healthBar.png")
        frame.Background:SetVertexColor(0, 0, 0, 0.4)
    end

    -- Текст "from" слева
    if not frame.FromText then
        frame.FromText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        frame.FromText:SetPoint("RIGHT", frame, "LEFT", -padding, 0)
        frame.FromText:SetText("80")
        frame.FromText:SetJustifyH("LEFT")
        frame.FromText:SetTextColor(1.0, 0.960784, 0.772549, 1)
        frame.FromText:SetFont("Fonts\\FRIZQT___CYR.TTF", fontSize, "")

    end

    -- Текст "to" справа
    if not frame.ToText then
        frame.ToText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        frame.ToText:SetPoint("LEFT", frame, "RIGHT", padding, 0)
        frame.ToText:SetText("81")
        frame.ToText:SetJustifyH("RIGHT")
        frame.ToText:SetTextColor(1.0, 0.960784, 0.772549, 1)
        frame.ToText:SetFont("Fonts\\FRIZQT___CYR.TTF", fontSize, "")
    end

    -- Текст "Title" снизу
    if not frame.Title then
        frame.Title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        frame.Title:SetPoint("TOP", frame, "BOTTOM", 0, -padding)
        frame.Title:SetText("Название")
        frame.Title:SetJustifyH("RIGHT")
        frame.Title:SetTextColor(1.0, 0.960784, 0.772549, 1)
        frame.Title:SetFont("Fonts\\FRIZQT___CYR.TTF", fontSize, "")
    end
end