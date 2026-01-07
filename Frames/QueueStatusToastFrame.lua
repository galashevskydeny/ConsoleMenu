local ConsoleMenu = _G.ConsoleMenu

local frameWidth = 304
local frameHeight = 56
local captionPadding = 4

local fontSize = 20
local captionFontSize = 16

local animationDuration = 0.3

-- Функция для инициализации NotificationFrame
function ConsoleMenu:SetQueueStatusToastFrame()

    if not ConsoleMenuFrame.QueueStatusToastFrame then
        local frame = CreateFrame("Frame", "QueueStatusToastFrame", ConsoleMenuFrame)
        ConsoleMenuFrame.QueueStatusToastFrame = frame
    end

    local frame = ConsoleMenuFrame.QueueStatusToastFrame
    frame:SetSize(frameWidth, frameHeight)
    frame:SetPoint("TOPLEFT", ConsoleMenuFrame, "TOPLEFT", 48, -48)
    ConsoleMenu:InitFadeAnimations(frame, animationDuration)
    frame:Hide()

    -- Текст уведомления
    if not frame.Text then
        frame.Text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.Text:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        frame.Text:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        frame.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", fontSize, "")
        frame.Text:SetTextColor(1.0, 0.960784, 0.772549, 1)
        frame.Text:SetJustifyH("LEFT")
        frame.Text:SetText("")
        frame.Text:SetNonSpaceWrap(true)
        frame.Text:Show()
        frame.Text:SetWordWrap(true)
    end

    -- Текст уведомления
    if not frame.Caption then
        frame.Caption = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.Caption:SetPoint("TOPLEFT", frame.Text, "BOTTOMLEFT", 0, -captionPadding)
        frame.Caption:SetPoint("TOPRIGHT", frame.Text, "BOTTOMRIGHT", 0, -captionPadding)
        frame.Caption:SetFont("Fonts\\FRIZQT___CYR.TTF", captionFontSize, "")
        frame.Caption:SetTextColor(1.0, 0.960784, 0.772549, 0.6)
        frame.Caption:SetJustifyH("LEFT")
        frame.Caption:SetText("")
        frame.Caption:SetNonSpaceWrap(true)
        frame.Caption:Hide()
        frame.Caption:SetWordWrap(true)
    end

    --For everything
	frame:RegisterEvent("PLAYER_ENTERING_WORLD");
	frame:RegisterEvent("GROUP_ROSTER_UPDATE");

	--For Plunderstorm 
	frame:RegisterEvent("LOBBY_MATCHMAKER_QUEUE_STATUS_UPDATE");
	frame:RegisterEvent("LOBBY_MATCHMAKER_QUEUE_ABANDONED");
	frame:RegisterEvent("LOBBY_MATCHMAKER_QUEUE_POPPED");
	frame:RegisterEvent("LOBBY_MATCHMAKER_QUEUE_EXPIRED");
	frame:RegisterEvent("LOBBY_MATCHMAKER_QUEUE_ERROR");

	--For LFG
	frame:RegisterEvent("LFG_UPDATE");
	frame:RegisterEvent("LFG_ROLE_CHECK_UPDATE");
	frame:RegisterEvent("LFG_READY_CHECK_UPDATE");
	frame:RegisterEvent("LFG_PROPOSAL_UPDATE");
	frame:RegisterEvent("LFG_PROPOSAL_FAILED");
	frame:RegisterEvent("LFG_PROPOSAL_SUCCEEDED");
	frame:RegisterEvent("LFG_PROPOSAL_SHOW");
	frame:RegisterEvent("LFG_QUEUE_STATUS_UPDATE");

	--For LFGList
	frame:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE");
	frame:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED");
	frame:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED");
	frame:RegisterEvent("LFG_LIST_APPLICANT_UPDATED");

	--For PvP
	frame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS");
	frame:RegisterEvent("PVP_BRAWL_INFO_UPDATED");

	--For World PvP stuff
	frame:RegisterEvent("ZONE_CHANGED_NEW_AREA");
	frame:RegisterEvent("ZONE_CHANGED");

	--For Pet Battles
	frame:RegisterEvent("PET_BATTLE_QUEUE_STATUS");

    local function OnQueueStatusToastEvent(self, event, ...)

    end

    frame:SetScript("OnEvent", OnQueueStatusToastEvent)
end