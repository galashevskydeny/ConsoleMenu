-- Создание окна диалогов и заданий и управление его показом.

local ConsoleMenu = _G.ConsoleMenu
local Gossip = ConsoleMenu.Gossip

-- Создание окна диалогов и заданий.
function ConsoleMenu:SetCustomGossipFrame()
    if ConsoleMenuDB.dialogQuestWindowStyle == 2 then
        return
    end

    local frame = CreateFrame("Frame", "ConsoleMenuGossipFrame", ConsoleMenuFrame)
    ConsoleMenuFrame.GossipFrame = frame

    frame:SetSize(Gossip.frameWidth, Gossip.sectionHeight * Gossip.viewedItemCount)
    frame:SetPoint("TOP", SubtitleFrame, "BOTTOM", 0, -32)
    frame:Hide()
    ConsoleMenu:InitFadeAnimations(frame, Gossip.animationDuration)

    frame.Background = frame:CreateTexture(nil, "BACKGROUND")
    frame.Background:SetWidth(1300)
    frame.Background:SetHeight(400)
    frame.Background:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
    frame.Background:SetAtlas("LevelUp-Shadow-Upper")
    frame.Background:SetAlpha(0.9)

    frame:HookScript("OnShow", function()
        Gossip.gamePadActive = Gossip.IsControllerActive()
        Gossip.StoreAndDisableSoftTarget()
        Gossip.FocusFirstElement()
    end)

    frame:HookScript("OnHide", function()
        Gossip.RestoreSoftTarget()
    end)

    frame:RegisterEvent("GAME_PAD_ACTIVE_CHANGED")
    frame:RegisterEvent("GOSSIP_SHOW")
    frame:RegisterEvent("QUEST_GREETING")
    frame:RegisterEvent("QUEST_DETAIL")
    frame:RegisterEvent("QUEST_PROGRESS")
    frame:RegisterEvent("QUEST_COMPLETE")
    frame:RegisterEvent("QUEST_FINISHED")
    frame:RegisterEvent("GOSSIP_CLOSED")
    frame:RegisterEvent("TAXIMAP_OPENED")
    frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")

    local hideRequestToken = 0

    -- Показ окна и отмена отложенного скрытия.
    local function ShowGossipWindow(interactionType)
        hideRequestToken = hideRequestToken + 1
        ConsoleMenu:AnimatedShow(frame)
        ConsoleMenu:AddWindow(interactionType or Enum.PlayerInteractionType.Gossip)
        ConsoleMenu:ApplyContextUIChanges()
    end

    -- Скрытие окна и снятие контекста диалога.
    local function HideGossipWindow()
        ConsoleMenu:AnimatedHide(frame)
        ConsoleMenu:RemoveWindow(Enum.PlayerInteractionType.Gossip)
        ConsoleMenu:RemoveWindow(Enum.PlayerInteractionType.QuestGiver)
        ConsoleMenu:ApplyContextUIChanges()
    end

    -- Скрытие окна без анимации, чтобы карта полётов не вспыхивала меню.
    local function HideGossipWindowNow()
        hideRequestToken = hideRequestToken + 1
        if frame.fadeIn then
            frame.fadeIn:Stop()
        end
        if frame.fadeOut then
            frame.fadeOut:Stop()
            frame.fadeOut:SetScript("OnFinished", nil)
        end
        frame:Hide()
        frame:SetAlpha(1)
        ConsoleMenu:RemoveWindow(Enum.PlayerInteractionType.Gossip)
        ConsoleMenu:RemoveWindow(Enum.PlayerInteractionType.QuestGiver)
        ConsoleMenu:ApplyContextUIChanges()
    end

    Gossip.HideWindowNow = HideGossipWindowNow
    Gossip.HideWindow = HideGossipWindow

    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "GAME_PAD_ACTIVE_CHANGED" then
            Gossip.gamePadActive = ...
            if ConsoleMenu.SetGamePadActive then
                ConsoleMenu:SetGamePadActive(...)
            end
        elseif event == "GOSSIP_SHOW" then
            if Gossip.ShouldSkipForTaxi() then
                Gossip.SelectTaxiIfNeeded()
                return
            end
            ShowGossipWindow(Enum.PlayerInteractionType.Gossip)
        elseif event == "TAXIMAP_OPENED" then
            HideGossipWindowNow()
        elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
            local interactionType = ...
            local types = Enum and Enum.PlayerInteractionType
            if types and interactionType and interactionType ~= types.Gossip and interactionType ~= types.QuestGiver then
                HideGossipWindowNow()
            end
        elseif event == "QUEST_GREETING" then
            ShowGossipWindow(Enum.PlayerInteractionType.QuestGiver)
        elseif event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" or event == "QUEST_DETAIL" then
            local questID = GetQuestID()
            if questID == 0 then
                return
            end
            ShowGossipWindow(Enum.PlayerInteractionType.QuestGiver)
        elseif event == "PLAYER_REGEN_DISABLED" then
            hideRequestToken = hideRequestToken + 1
            HideGossipWindow()
        elseif event == "PLAYER_REGEN_ENABLED" then
            if not frame:IsShown() then
                Gossip.RestoreSoftTarget()
            end
        elseif event == "GOSSIP_CLOSED" or event == "QUEST_FINISHED" then
            hideRequestToken = hideRequestToken + 1
            local currentToken = hideRequestToken
            local hideDelay = Gossip.animationDuration
            if event == "QUEST_FINISHED" then
                hideDelay = Gossip.questFinishedHideDelay
            end

            -- При смене разговора на торговца, полёт или задание окно нужно закрыть;
            -- новый показ разговора отменит это скрытие.
            C_Timer.After(hideDelay, function()
                if currentToken ~= hideRequestToken then
                    return
                end
                if not frame:IsShown() then
                    return
                end
                if GetQuestID() ~= 0 then
                    return
                end
                HideGossipWindow()
            end)
        end
    end)

    Gossip.parentFrame = Gossip.CreateScrollBox()
    Gossip.EnableController()
end
