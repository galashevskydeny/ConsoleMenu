local ConsoleMenu = _G.ConsoleMenu

local frameWidth = 304
local frameHeight = 56
local captionPadding = 4

local fontSize = 20
local captionFontSize = 16

local animationDuration = 0.3

-- Функция для получения минимальной ожидания очереди
local function GetMinimumQueueWait()
    if not ConsoleMenu.Queues or #ConsoleMenu.Queues == 0 then
        return nil
    end
    local minWait = nil
    for _, queue in ipairs(ConsoleMenu.Queues) do
        if queue.wait and type(queue.wait) == "number" then
            if not minWait or queue.wait < minWait then
                minWait = queue.wait
            end
        end
    end
    return minWait
end

-- Функция для обновления списка очередей
local function UpdateQueue()
    local queues = {}
 
     -- Plunderstorm Queue
     local queuedForPlunderstorm = C_LobbyMatchmakerInfo.IsInQueue();
     if queuedForPlunderstorm then
         table.insert(queues, {
             type = "Plunderstorm",
             wait = nil,
         })
     end
 
     --Try each LFG type
     for i=1, NUM_LE_LFG_CATEGORYS do
         local hasData, _, _, _, _, _, _, _, _, _, _, averageWait, _, _, _, _, queuedTime, _ = GetLFGQueueStats(i)
 
         if hasData then
             local wait
 
             if averageWait and queuedTime then
                 wait = math.ceil((averageWait - (GetTime() - queuedTime)) / 60)
             end
 
             if wait < 0 or wait == -0 then
                 wait = nil
             end
 
             table.insert(queues, {
                 type = "LFG",
                 wait = wait,
             })
         end
     end
 
     --Try LFGList entries
     local isActive = C_LFGList.HasActiveEntryInfo()
     if ( isActive ) then
         table.insert(queues, {
             type = "LFGList",
             wait = nil,
         })
     end
 
     --Try all PvP queues
     for i=1, GetMaxBattlefieldID() do
         local status, _, _, _, _ = GetBattlefieldStatus(i)
         if ( status and status ~= "none" ) then

            local queuedTime = GetTime() - GetBattlefieldTimeWaited(i) / 1000;
			local averageWait = GetBattlefieldEstimatedWaitTime(i) / 1000;

            local wait
 
             if averageWait and queuedTime then
                 wait = math.ceil((averageWait - (GetTime() - queuedTime)) / 60)
             end
 
             if wait < 0 or wait == -0 then
                 wait = nil
             end

             table.insert(queues, {
                 type = "PvP",
                 wait = wait,
             })
         end
     end
 
     --Try all World PvP queues
     for i=1, MAX_WORLD_PVP_QUEUES do
         local status, _, averageWait, _, _, queuedTime, _ = GetWorldPVPQueueStatus(i)
         if ( status and status ~= "none" ) then
            local wait
 
             if averageWait and queuedTime then
                 wait = math.ceil((averageWait - (GetTime() - queuedTime)) / 60)
             end
 
             if wait < 0 or wait == -0 then
                 wait = nil
             end

             table.insert(queues, {
                 type = "WorldPvP",
                 wait = wait,
             })
         end
     end
 
     --Pet Battle PvP Queue
     local queueState, estimatedTime, _ = C_PetBattles.GetPVPMatchmakingInfo()
     if ( pbStatus ) then
         table.insert(queues, {
             type = "PetBattle",
             wait = nil
         })
     end
 
     ConsoleMenu.Queues = queues
 
end

-- Функция для обновления QueueStatusToastFrame
function ConsoleMenu:QueueStatusToastFrameUpdate()

    if ConsoleMenuFrame.NotificationFrame:IsShown() then
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.QueueStatusToastFrame)
        return
    end

    UpdateQueue()
    
    if not ConsoleMenu.Queues or #ConsoleMenu.Queues == 0 then
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.QueueStatusToastFrame)
        return
    end

    local minWait = GetMinimumQueueWait()

    if minWait and minWait > 0 then
        ConsoleMenuFrame.QueueStatusToastFrame.Caption:SetText("ещё примерно " .. minWait .. " мин.")
    elseif minWait and minWait <= 0 then
        ConsoleMenuFrame.QueueStatusToastFrame.Caption:SetText("призыв совсем скоро...")
    else
        local messages = {
            "рассылаем агентов...",
            "призываем рекрутов...",
            "договариваемся с наёмниками...",
            "опрашиваем гарнизон...",
        }

        local message = messages[math.random(1, #messages)]
        ConsoleMenuFrame.QueueStatusToastFrame.Caption:SetText(message)
    end

    ConsoleMenu:AnimatedShow(ConsoleMenuFrame.QueueStatusToastFrame)
end

-- Функция для инициализации NotificationFrame
function ConsoleMenu:SetQueueStatusToastFrame()

    if ConsoleMenuDB.groupFinderFrameStyle == 1 then return end

    if not ConsoleMenu.Queues then
        ConsoleMenu.Queues = {}
    end

    if not ConsoleMenuFrame.QueueStatusToastFrame then
        local frame = CreateFrame("Frame", "QueueStatusToastFrame", ConsoleMenuFrame)
        ConsoleMenuFrame.QueueStatusToastFrame = frame
    end

    local frame = ConsoleMenuFrame.QueueStatusToastFrame
    frame:SetSize(frameWidth, frameHeight)
    frame:SetPoint("TOPLEFT", ConsoleMenuFrame, "TOPLEFT", 48, -48)
    frame:Hide()
    ConsoleMenu:InitFadeAnimations(frame, animationDuration)

    -- Текст уведомления
    if not frame.Text then
        frame.Text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.Text:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        frame.Text:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        frame.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", fontSize, "")
        frame.Text:SetTextColor(1.0, 0.960784, 0.772549, 1)
        frame.Text:SetJustifyH("LEFT")
        frame.Text:SetText(LFG_TITLE)
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
        frame.Caption:Show()
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
        ConsoleMenu:QueueStatusToastFrameUpdate()
    end

    frame:SetScript("OnEvent", OnQueueStatusToastEvent)
end