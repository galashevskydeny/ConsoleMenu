-- Значки пунктов списка диалога.

local ConsoleMenu = _G.ConsoleMenu
local Gossip = ConsoleMenu.Gossip

-- Рисунки значка задания: можно взять или можно сдать.
-- Смещения держат щит и обёртку внутри ячейки.
local QUEST_ICON_STYLES = {
    campaign = {
        offer = "Crosshair_campaignquest_128",
        turnIn = "Crosshair_campaignquestturnin_128",
        left = -6,
        right = -6,
        top = 0,
        bottom = 0,
    },
    legendary = {
        offer = "Crosshair_legendaryquest_128",
        turnIn = "Crosshair_legendaryquestturnin_128",
    },
    important = {
        offer = "Crosshair_important_128",
        turnIn = "Crosshair_importantturnin_128",
        left = -2,
        right = -2,
        top = 2,
        bottom = 2,
    },
    meta = {
        offer = "Crosshair_Wrapper_128",
        turnIn = "Crosshair_Wrapperturnin_128",
        left = -1,
        right = -1,
        top = 2,
        bottom = 2,
    },
    recurring = {
        offer = "Crosshair_Recurring_128",
        turnIn = "Crosshair_Recurringturnin_128",
    },
    normal = {
        offer = "Crosshair_Quest_128",
        turnIn = "Crosshair_Questturnin_128",
    },
}

-- Число, если клиент его не скрывает.
local function ReadableNumber(value)
    value = Gossip.Readable(value)
    if type(value) == "number" then
        return value
    end
end

-- Ежедневное, еженедельное или задание со своим расписанием.
local function IsRecurringFrequency(frequency)
    local frequencies = Enum.QuestFrequency
    if not frequencies or frequency == nil then
        return false
    end
    return frequency == frequencies.Daily
        or frequency == frequencies.Weekly
        or frequency == frequencies.ResetByScheduler
end

-- Частота из пункта диалога или из журнала, если пункт её не принёс.
local function QuestFrequency(data)
    local frequency = ReadableNumber(data.frequency)
    if frequency ~= nil then
        return frequency
    end
    if not (QuestCache and data.questID) then
        return nil
    end
    local quest = QuestCache:Get(data.questID)
    if not quest then
        return nil
    end
    return ReadableNumber(quest.frequency)
end

-- Класс значка. Порядок совпадает с окном разговора клиента.
-- Поручение кампании рисуется щитом кампании: отдельного значка для него нет.
local function QuestIconStyle(data)
    local styles = QUEST_ICON_STYLES
    local classes = Enum.QuestClassification
    local classification
    if C_QuestInfoSystem and C_QuestInfoSystem.GetQuestClassification and data.questID then
        local questInfoID = ReadableNumber(data.questInfoID)
        if questInfoID == 0 then
            questInfoID = nil
        end
        classification = ReadableNumber(C_QuestInfoSystem.GetQuestClassification(data.questID, questInfoID))
    end

    if not classes or classification == nil then
        if IsRecurringFrequency(QuestFrequency(data)) then
            return styles.recurring
        end
        return styles.normal
    end

    if classification == classes.Campaign or classification == classes.Calling then
        return styles.campaign
    elseif classification == classes.Legendary then
        return styles.legendary
    elseif classification == classes.Important then
        return styles.important
    elseif classification == classes.Meta then
        return styles.meta
    elseif classification == classes.Recurring or IsRecurringFrequency(QuestFrequency(data)) then
        return styles.recurring
    end
    return styles.normal
end

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
    -- Значок задания: можно взять или можно сдать.
    local function ApplyQuestIcon(state)
        local style = QuestIconStyle(data)
        local texture = frame.icon.texture
        if style.left then
            texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", style.left, style.top or 0)
            texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", style.right, style.bottom or 0)
        else
            texture:SetAllPoints()
        end
        texture:SetAtlas(style[state] or style.offer)
        texture:Show()
    end

    -- Значок задания, которое ещё выполняется.
    local function SetQuestInProgressIcon()
        local texture = frame.icon.texture
        texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -4, 4)
        texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", 4, -4)
        texture:SetAtlas("Quest-In-Progress-Icon-yellow")
        texture:Show()
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
            ApplyQuestIcon("turnIn")
        elseif data.inProgress then
            SetQuestInProgressIcon()
        else
            ApplyQuestIcon("offer")
        end
    elseif data.type == "acceptQuest" then
        if Gossip.previousGossip then
            SetSpeakIcon()
        else
            ApplyQuestIcon("offer")
        end
    elseif data.type == "progressQuest" then
        SetSpeakIcon()
    elseif data.type == "completeQuest" then
        ApplyQuestIcon("turnIn")
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
