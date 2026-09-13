-- Список пунктов диалога и заполнение меню по событиям клиента.

local ConsoleMenu = _G.ConsoleMenu
local Gossip = ConsoleMenu.Gossip

-- Создание списка пунктов диалога.
function Gossip.CreateScrollBox()
    local gossipFrame = ConsoleMenuFrame.GossipFrame

    local ScrollBox = CreateFrame("Frame", "ConsoleMenuGossipScrollBox", gossipFrame, "WowScrollBoxList")
    gossipFrame.ScrollBox = ScrollBox
    ScrollBox:SetPoint("TOPLEFT", gossipFrame, "TOPLEFT", 0, 0)
    ScrollBox:SetPoint("BOTTOMRIGHT", gossipFrame, "BOTTOMRIGHT", Gossip.sectionPadding * 4, 0)

    local ScrollBar = CreateFrame("EventFrame", "ConsoleMenuGossipScrollBar", gossipFrame, "MinimalScrollBar")
    gossipFrame.ScrollBox.ScrollBar = ScrollBar

    ScrollBar:SetPoint("TOPLEFT", ScrollBox, "TOPRIGHT", 0, -Gossip.sectionPadding)
    ScrollBar:SetPoint("BOTTOMLEFT", ScrollBox, "BOTTOMRIGHT", 0, Gossip.sectionPadding)
    ScrollBar.Forward:Hide()
    ScrollBar.Back:Hide()
    ScrollBar:SetAlpha(0.7)

    local DataProvider = CreateDataProvider()
    local ScrollView = CreateScrollBoxListLinearView()
    local rewardLoadToken = 0

    -- Видимость полосы прокрутки по высоте содержимого.
    local function UpdateScrollBarVisibility()
        local totalHeight = ScrollView:GetExtent() - 1
        if totalHeight <= gossipFrame:GetHeight() then
            ScrollBar:Hide()
        else
            ScrollBar:Show()
        end
    end

    -- Сравнение пунктов разговора по порядку клиента.
    local function SortGossipOptions(left, right)
        return (left.orderIndex or 0) < (right.orderIndex or 0)
    end

    -- Заполнение меню разговора.
    local function GetGossip()
        rewardLoadToken = rewardLoadToken + 1
        DataProvider:Flush()

        local quests = Gossip.GetGossipQuests()
        for _, quest in ipairs(quests) do
            DataProvider:Insert({
                type = "gossipQuest",
                name = quest.title,
                inProgress = quest.inProgress,
                isComplete = quest.isComplete,
                questID = quest.questID
            })
        end

        local options = C_GossipInfo.GetOptions() or {}
        table.sort(options, SortGossipOptions)
        for _, option in ipairs(options) do
            DataProvider:Insert({
                type = "gossip",
                name = option.name,
                icon = option.overrideIconID or option.icon,
                gossipOptionID = option.gossipOptionID,
                orderIndex = option.orderIndex,
            })
        end

        local reputationInfo = C_GossipInfo.GetFriendshipReputation(0)
        if reputationInfo and reputationInfo.friendshipFactionID and reputationInfo.friendshipFactionID > 0 then
            DataProvider:Insert({
                type = "reputation",
                name = "Отношения с " .. reputationInfo.name,
                reputationText = reputationInfo.text,
                reputationName = reputationInfo.name,
            })
        end

        DataProvider:Insert({
            type = "goodbye",
            name = GOODBYE,
        })

        UpdateScrollBarVisibility()
    end

    -- Заполнение меню приветствия.
    local function GetGreeting()
        rewardLoadToken = rewardLoadToken + 1
        DataProvider:Flush()

        local quests = Gossip.GetGreetingQuests()
        for _, quest in ipairs(quests) do
            DataProvider:Insert({
                type = "greetingQuest",
                name = quest.title,
                inProgress = quest.inProgress,
                isComplete = quest.isComplete,
                questID = quest.questID,
                index = quest.index
            })
        end

        DataProvider:Insert({
            type = "goodbye",
            name = GOODBYE,
        })

        UpdateScrollBarVisibility()
    end

    -- Заполнение меню описания задания.
    local function UpdateQuestDetail()
        rewardLoadToken = rewardLoadToken + 1
        DataProvider:Flush()

        local questID = GetQuestID()

        DataProvider:Insert({
            type = "acceptQuest",
            name = "Я этим займусь.",
            questID = questID,
        })

        if C_QuestLog.IsQuestFlaggedCompletedOnAccount(questID) then
            DataProvider:Insert({
                type = "completedAccountQuest",
                name = "Кажется мой отряд уже выполнял это задание.",
            })
        end

        DataProvider:Insert({
            type = "goodbye",
            name = GOODBYE,
        })

        UpdateScrollBarVisibility()
    end

    -- Показать отношения с собеседником.
    function Gossip.ShowReputation(reputationText, reputationName)
        rewardLoadToken = rewardLoadToken + 1
        DataProvider:Flush()

        ConsoleMenu:AddSubtitles("GOSSIP_SHOW", reputationText, reputationName)
        ConsoleMenu:SubtitleFrameUpdate()

        DataProvider:Insert({
            type = "reputationBack",
            name = "Давай поговорим о чем-то другом.",
            reputationName = reputationName,
        })

        DataProvider:Insert({
            type = "goodbye",
            name = GOODBYE,
        })

        Gossip.FocusFirstElement()
        UpdateScrollBarVisibility()
    end

    -- Вернуться к меню разговора.
    function Gossip.BackToGossip(reputationName)
        local gossipText = C_GossipInfo.GetText()
        ConsoleMenu:AddSubtitles("GOSSIP_SHOW", gossipText, reputationName)
        ConsoleMenu:SubtitleFrameUpdate()

        GetGossip()
        Gossip.FocusFirstElement()
        UpdateScrollBarVisibility()
    end

    -- Заполнение меню завершения задания готовыми пунктами.
    local function InsertCompleteOptions(entries)
        DataProvider:Flush()
        for _, entry in ipairs(entries) do
            DataProvider:Insert(entry)
        end
        DataProvider:Insert({
            type = "goodbye",
            name = GOODBYE,
        })
        Gossip.FocusFirstElement()
        UpdateScrollBarVisibility()
    end

    -- Инициализация видимой строки списка.
    local function Initializer(frame, data)
        if not data then
            return
        end

        if not frame.icon then
            frame.icon = CreateFrame("Frame", nil, frame)
            frame.icon:SetSize(Gossip.iconSize, Gossip.iconSize)
            frame.icon:SetPoint("LEFT", Gossip.sectionPadding, 0)
        end

        Gossip.SetIcon(frame, data)

        if not frame.text then
            frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            frame.text:SetPoint("LEFT", frame.icon, "RIGHT", Gossip.sectionPadding, 0)
            frame.text:SetPoint("RIGHT", -Gossip.sectionPadding, 0)
            frame.text:SetJustifyH("LEFT")
        end

        frame.text:SetFont(Gossip.fontName, Gossip.itemFontSize, "OUTLINE")
        frame.text:SetText(data.name)
        frame.text:SetTextColor(1, 0.976, 0.855)

        if not frame.bg then
            frame.bg = frame:CreateTexture(nil, "BACKGROUND")
            frame.bg:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5)
            frame.bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, -4)
            frame.bg:SetAtlas("Garr_BuildingInfoShadow")
            frame.bg:Hide()
        end

        -- Подсветка выбранной строки.
        function frame:SetFocused(isFocused)
            if isFocused then
                frame.text:SetTextColor(1, 0.768, 0.071)
                frame.bg:Show()
            else
                frame.text:SetTextColor(1, 0.976, 0.855)
                frame.bg:Hide()
            end
        end

        frame:SetFocused(false)

        frame:SetScript("OnEnter", function()
            Gossip.UpdateFocus(data, false)
            frame:SetFocused(true)
        end)
        frame:SetScript("OnLeave", function()
        end)

        frame:SetScript("OnMouseDown", function()
            Gossip.SelectOption(data)
        end)
    end

    ScrollView:SetElementExtent(Gossip.sectionHeight)
    ScrollView:SetElementInitializer("Frame", Initializer)

    ScrollUtil.InitScrollBoxListWithScrollBar(ScrollBox, ScrollBar, ScrollView)
    ScrollView:SetDataProvider(DataProvider)

    local EventFrame = CreateFrame("Frame", nil, gossipFrame)
    EventFrame:RegisterEvent("GOSSIP_SHOW")
    EventFrame:RegisterEvent("GOSSIP_CLOSED")
    EventFrame:RegisterEvent("QUEST_GREETING")
    EventFrame:RegisterEvent("QUEST_DETAIL")
    EventFrame:RegisterEvent("QUEST_PROGRESS")
    EventFrame:RegisterEvent("QUEST_COMPLETE")
    EventFrame:RegisterEvent("QUEST_ACCEPTED")
    EventFrame:RegisterEvent("QUEST_TURNED_IN")

    EventFrame:SetScript("OnEvent", function(self, event)
        if event == "GOSSIP_SHOW" then
            GetGossip()
            Gossip.previousGossip = false
            Gossip.FocusFirstElement()
        elseif event == "QUEST_GREETING" then
            GetGreeting()
            Gossip.previousGossip = false
            Gossip.FocusFirstElement()
        elseif event == "QUEST_DETAIL" then
            local questID = GetQuestID()
            if questID ~= 0 then
                UpdateQuestDetail()
                Gossip.FocusFirstElement()
            end
        elseif event == "QUEST_PROGRESS" then
            rewardLoadToken = rewardLoadToken + 1
            DataProvider:Flush()
            Gossip.BuildQuestProgressOptions(DataProvider, GetQuestID())
            DataProvider:Insert({ type = "goodbye", name = GOODBYE })
            Gossip.FocusFirstElement()
        elseif event == "QUEST_COMPLETE" then
            rewardLoadToken = rewardLoadToken + 1
            local currentToken = rewardLoadToken
            local questID = GetQuestID()
            local numChoices = GetNumQuestChoices()
            local questLineInfo, questIDs = Gossip.GetQuestLineForComplete(questID)

            local isMidStoryline = questLineInfo
                and questIDs
                and #questIDs > 0
                and questIDs[#questIDs] ~= questID
                and numChoices <= 1

            if isMidStoryline then
                InsertCompleteOptions({
                    {
                        type = "completeQuestInStoryline",
                        name = "Что дальше?",
                        numChoices = numChoices,
                        questID = questID,
                        isComplete = true,
                        inProgress = false,
                    }
                })
            elseif numChoices > 1 then
                local pending = numChoices
                local rewards = {}

                -- Запись готовых наград одним заходом после загрузки.
                local function TryFinishRewards()
                    if currentToken ~= rewardLoadToken then
                        return
                    end
                    if pending > 0 then
                        return
                    end
                    table.sort(rewards, function(a, b)
                        return a.index < b.index
                    end)
                    InsertCompleteOptions(rewards)
                end

                -- Добавляет награду выбора в накопленный список.
                local function AddChoiceReward(index, name, texture)
                    table.insert(rewards, {
                        type = "completeQuestWithReward",
                        name = name,
                        numChoices = numChoices,
                        index = index,
                        questID = questID,
                        isComplete = true,
                        inProgress = false,
                        texture = texture,
                    })
                end

                for i = 1, numChoices do
                    local lootType = GetQuestItemInfoLootType("choice", i)
                    if lootType == 0 then
                        local name, texture = GetQuestItemInfo("choice", i)
                        if name and name ~= "" then
                            AddChoiceReward(i, name, texture)
                            pending = pending - 1
                        else
                            local itemLink = GetQuestItemLink("choice", i)
                            if itemLink then
                                local item = Item:CreateFromItemLink(itemLink)
                                item:ContinueOnItemLoad(function()
                                    pending = pending - 1
                                    if currentToken ~= rewardLoadToken then
                                        return
                                    end
                                    local loadedName = item:GetItemName()
                                    if not loadedName or loadedName == "" then
                                        loadedName = "награда"
                                    end
                                    AddChoiceReward(i, loadedName, item:GetItemIcon())
                                    TryFinishRewards()
                                end)
                            else
                                pending = pending - 1
                            end
                        end
                    elseif lootType == 1 then
                        local currencyInfo = C_QuestLog.GetQuestRewardCurrencyInfo(questID, i, true)
                            or C_QuestOffer.GetQuestRewardCurrencyInfo("choice", i)
                        if currencyInfo then
                            local name, texture = CurrencyContainerUtil.GetCurrencyContainerInfo(
                                currencyInfo.currencyID,
                                currencyInfo.totalRewardAmount,
                                currencyInfo.name,
                                currencyInfo.texture,
                                currencyInfo.quality
                            )
                            AddChoiceReward(i, name, texture)
                        end
                        pending = pending - 1
                    else
                        pending = pending - 1
                    end
                end

                TryFinishRewards()

                C_Timer.After(1, function()
                    if currentToken ~= rewardLoadToken then
                        return
                    end
                    if pending > 0 then
                        pending = 0
                        TryFinishRewards()
                    end
                end)
            else
                InsertCompleteOptions({
                    {
                        type = "completeQuest",
                        name = COMPLETE_QUEST,
                        numChoices = numChoices,
                        index = 1,
                        questID = questID,
                        isComplete = true,
                        inProgress = false,
                    }
                })
            end
        elseif event == "GOSSIP_CLOSED" then
            Gossip.previousGossip = true
        elseif event == "QUEST_ACCEPTED" or event == "QUEST_TURNED_IN" then
            Gossip.previousGossip = false
        end

        UpdateScrollBarVisibility()
    end)

    return gossipFrame
end
