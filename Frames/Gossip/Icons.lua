-- Значки пунктов списка диалога.

local ConsoleMenu = _G.ConsoleMenu
local Gossip = ConsoleMenu.Gossip

-- Сброс привязки и видимости значка перед новой установкой.
local function ResetIconTexture(frame)
    if frame.icon.texture then
        frame.icon.texture:ClearAllPoints()
        frame.icon.texture:Hide()
    end
    if frame.icon.border then
        frame.icon.border:Hide()
    end
end

-- Установка значка пункту списка.
function Gossip.SetIcon(frame, data)
    -- Значок задания в зависимости от его класса.
    local function SetQuestIcon()
        local classification = C_QuestInfoSystem.GetQuestClassification(data.questID)
        local classEnum = Enum.QuestClassification

        if classification == classEnum.Important then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -2, 2)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -2, 2)
            frame.icon.texture:SetAtlas("Crosshair_important_128")
        elseif classification == classEnum.Campaign then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -6, 0)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -6, 0)
            frame.icon.texture:SetAtlas("Crosshair_campaignquest_128")
        elseif classification == classEnum.Meta then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -1, 2)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -1, 2)
            frame.icon.texture:SetAtlas("Crosshair_Wrapper_128")
        elseif classification == classEnum.Recurring then
            frame.icon.texture:SetAllPoints()
            frame.icon.texture:SetAtlas("Crosshair_Recurring_128")
        else
            frame.icon.texture:SetAllPoints()
            frame.icon.texture:SetAtlas("Crosshair_Quest_128")
        end

        frame.icon.texture:Show()
    end

    -- Значок завершения задания в зависимости от его класса.
    local function SetQuestTurnInIcon()
        local classification = C_QuestInfoSystem.GetQuestClassification(data.questID)
        local classEnum = Enum.QuestClassification

        if classification == classEnum.Important then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -2, 2)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -2, 2)
            frame.icon.texture:SetAtlas("Crosshair_importantturnin_128")
        elseif classification == classEnum.Campaign then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -6, 0)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -6, 0)
            frame.icon.texture:SetAtlas("Crosshair_campaignquestturnin_128")
        elseif classification == classEnum.Meta then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -1, 2)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -1, 2)
            frame.icon.texture:SetAtlas("Crosshair_Wrapperturnin_128")
        elseif classification == classEnum.Recurring then
            frame.icon.texture:SetAllPoints()
            frame.icon.texture:SetAtlas("Crosshair_Recurringturnin_128")
        else
            frame.icon.texture:SetAllPoints()
            frame.icon.texture:SetAtlas("Crosshair_Questturnin_128")
        end

        frame.icon.texture:Show()
    end

    -- Значок прогресса задания.
    local function SetQuestInProgressIcon()
        frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -4, 4)
        frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", 4, -4)
        frame.icon.texture:SetAtlas("Quest-In-Progress-Icon-yellow")
        frame.icon.texture:Show()
    end

    -- Значок облака общения.
    local function SetSpeakIcon()
        frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -2, 2)
        frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -2, 2)
        frame.icon.texture:SetAtlas("crosshair_speak_128")
        frame.icon.texture:Show()
    end

    -- Значок отношений с собеседником.
    local function SetInspectorIcon()
        frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", 0, 0)
        frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", 0, 0)
        frame.icon.texture:SetAtlas("Crosshair_Inspect_128")
        frame.icon.texture:Show()
    end

    -- Значок отряда.
    local function SetWarbandIcon()
        frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", 0, 6)
        frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", 0, -6)
        frame.icon.texture:SetAtlas("warbands-icon")
        frame.icon.texture:Show()
    end

    if not frame.icon.texture then
        frame.icon.texture = frame.icon:CreateTexture(nil, "ARTWORK")
        frame.icon.texture:Hide()
    end

    if not frame.icon.border then
        frame.icon.border = frame.icon:CreateTexture(nil, "OVERLAY")
        frame.icon.border:SetPoint("TOPLEFT", frame.icon.texture, "TOPLEFT", -6, 6)
        frame.icon.border:SetPoint("BOTTOMRIGHT", frame.icon.texture, "BOTTOMRIGHT", 6, -6)
        frame.icon.border:SetAtlas("plunderstorm-actionbar-slot-border")
        frame.icon.border:Hide()
    end

    ResetIconTexture(frame)

    if data.type == "gossip" then
        local icon = data.icon
        if icon == 132053 then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -2, 4)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -2, 4)
            frame.icon.texture:SetAtlas("crosshair_speak_128")
        elseif icon == 136458 then
            frame.icon.texture:SetAllPoints()
            frame.icon.texture:SetAtlas("Crosshair_innkeeper_128")
        elseif icon == 132060 then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -2, 2)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -2, 0)
            frame.icon.texture:SetAtlas("Crosshair_pickup_128")
        elseif icon == 1673939 then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -2, 0)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -2, 0)
            frame.icon.texture:SetAtlas("Crosshair_Transmogrify_128")
        elseif icon == 132057 then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", 0, 4)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", 0, 4)
            frame.icon.texture:SetAtlas("Crosshair_Taxi_128")
        elseif icon == 132058 then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", 0, 2)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", 0, 2)
            frame.icon.texture:SetAtlas("Crosshair_trainer_128")
        else
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -2, 2)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -2, 2)
            frame.icon.texture:SetAtlas("crosshair_speak_128")
        end
        frame.icon.texture:Show()
    elseif data.type == "gossipQuest" or data.type == "greetingQuest" then
        if data.isComplete then
            SetQuestTurnInIcon()
        elseif data.inProgress then
            SetQuestInProgressIcon()
        else
            SetQuestIcon()
        end
    elseif data.type == "acceptQuest" then
        if Gossip.previousGossip then
            SetSpeakIcon()
        else
            SetQuestIcon()
        end
    elseif data.type == "progressQuest" then
        SetSpeakIcon()
    elseif data.type == "completeQuest" then
        SetQuestTurnInIcon()
    elseif data.type == "completeQuestInStoryline" then
        SetQuestInProgressIcon()
    elseif data.type == "completeQuestWithReward" then
        frame.icon.texture:SetAllPoints()
        frame.icon.texture:SetTexture(data.texture)
        ApplyMaskToTexture(frame.icon.texture)
        frame.icon.border:Show()
        frame.icon.texture:Show()
    elseif data.type == "goodbye" then
        SetSpeakIcon()
    elseif data.type == "reputation" then
        SetInspectorIcon()
    elseif data.type == "reputationBack" then
        SetSpeakIcon()
    elseif data.type == "completedAccountQuest" then
        SetWarbandIcon()
    end
end
