-- GossipFrame.lua

local ConsoleMenu = _G.ConsoleMenu
local parentFrame

local frameWidth = 688

local viewedItemCount = 3
local sectionHeight = 52
local sectionPadding = 8
local iconSize = sectionHeight - sectionPadding * 2
local itemFontSize = 20

local animationDuration = 0.1

local focusedIndex = 1 -- Индекс текущего элемента в фокусе

local previousGossip = false
local softTargetEnemy

local gamePadActive = false

-- Провкрка элемента на вхождение в массив
local function isElementInTable(element, table)
    for _, value in ipairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- Посчитать количество квестов с QuestLineID
local function CountByQuestLineID(quests, targetQuestLineID)
    local count = 0
    for _, quest in ipairs(quests) do
        if quest.questLineID == targetQuestLineID then
            count = count + 1
        end
    end
    return count
end

-- Получение данных квестов при открытии Gossip
local function GetGossipQuests()
    -- Загружаем данные квестов
    local activeQuests = C_GossipInfo.GetActiveQuests()
    local availableQuests = C_GossipInfo.GetAvailableQuests()
    local result = {}

    -- Объединяем таблицы
    for _, quest in ipairs(activeQuests) do
        quest.inProgress = true
        table.insert(result, quest)
    end
    for _, quest in ipairs(availableQuests) do
        quest.inProgress = false
        table.insert(result, quest)
    end

    return result
end

-- Получение данных квестов при открытии Greeting
local function GetGreetingQuests()

    local result = {}

    -- Загружаем данные квестов
    local numActiveQuests = GetNumActiveQuests()
    local numAvailableQuests = GetNumAvailableQuests()

    if numActiveQuests == 0 and numAvailableQuests == 0 then
        return result
    end

    if numActiveQuests > 0 then
        -- Работа с активными квестами
        for i = 1, numActiveQuests do
            local title, isComplete = GetActiveTitle(i);
            local questID = GetActiveQuestID(i)
            local quest = {
                title = title,
                inProgress = true,
                isComplete = isComplete,
                index = i,
                questID = questID,
            }
            table.insert(result, quest)
        end
    end

    if numAvailableQuests > 0 then
        -- Работа с доступными квестами
        for i = 1, numAvailableQuests do
            local _, _, _, _, questID, _ = GetAvailableQuestInfo(i)
            local title = GetAvailableTitle(i)
            local quest = {
                title = title,
                inProgress = false,
                isComplete = false,
                index = i,
                questID = questID,
            }

            table.insert(result, quest)
        end
    end

    return result
end

-- Установка иконки пункту списка
local function setIcon(frame, data)

    -- Вспомогательные функции для определенных иконок
    ---- Иконка квеста в зависимости от его класса
    local function SetQuestIcon()
        local classification = C_QuestInfoSystem.GetQuestClassification(data.questID)
        if classification == 0 then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -2, 2)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -2, 2)
            frame.icon.texture:SetAtlas("Crosshair_important_128")
        elseif classification == 2 then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -6, 0)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -6, 0)
            frame.icon.texture:SetAtlas("Crosshair_campaignquest_128")
        elseif classification == 4 then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -1, 2)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -1, 2)
            frame.icon.texture:SetAtlas("Crosshair_Wrapper_128")
        elseif classification == 5 then
            frame.icon.texture:SetAllPoints()
            frame.icon.texture:SetAtlas("Crosshair_Recurring_128")
        elseif classification == 7 then
            frame.icon.texture:SetAllPoints()
            frame.icon.texture:SetAtlas("Crosshair_Quest_128")
        else
            print("classification" .. classification)
        end

        frame.icon.texture:Show()
    end

    ---- Иконка завершения квеста в зависимости от его класса
    local function SetQuestTurnInIcon()
        
        local classification = C_QuestInfoSystem.GetQuestClassification(data.questID)
        if classification == 0 then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -2, 2)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -2, 2)
            frame.icon.texture:SetAtlas("Crosshair_importantturnin_128")
        elseif classification == 2 then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -6, 0)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -6, 0)
            frame.icon.texture:SetAtlas("Crosshair_campaignquestturnin_128")
        elseif classification == 4 then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -1, 2)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -1, 2)
            frame.icon.texture:SetAtlas("Crosshair_Wrapperturnin_128")
        elseif classification == 5 then
            frame.icon.texture:SetAllPoints()
            frame.icon.texture:SetAtlas("Crosshair_Recurringturnin_128")
        elseif classification == 7 then
            frame.icon.texture:SetAllPoints()
            frame.icon.texture:SetAtlas("Crosshair_Questturnin_128")
        else
            print("classification" .. classification)
        end

        frame.icon.texture:Show()
    end

    ---- Иконка прогресса квеста
    local function SetQuestInProgressIcon()
        frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -4, 4)
        frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", 4, -4)
        frame.icon.texture:SetAtlas("Quest-In-Progress-Icon-yellow")

        frame.icon.texture:Show()
    end

    ---- Иконка облака общения
    local function SetSpeakIcon()
        frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -2, 2)
        frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -2, 2)
        frame.icon.texture:SetAtlas("crosshair_speak_128")

        frame.icon.texture:Show()
    end

    -- Иконка отношений с NPC
    local function SetInspectorIcon()
        frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", 0, 0)
        frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", 0, 0)
        frame.icon.texture:SetAtlas("Crosshair_Inspect_128")

        frame.icon.texture:Show()
    end

    -- Иконка отряда
    local function SetWarbandIcon()
        frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", 0, 6)
        frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", 0, -6)
        frame.icon.texture:SetAtlas("warbands-icon")

        frame.icon.texture:Show()
    end

    -- Смена текстур и их видимости

    if not frame.icon.texture then
        frame.icon.texture = frame.icon:CreateTexture(nil, "ARTWORK")
        frame.icon.texture:Hide()
    end

    if not frame.icon.border then
        frame.icon.border = frame.icon:CreateTexture(nil, "OVERLAY")

        frame.icon.border:SetPoint("TOPLEFT", frame.icon.texture, "TOPLEFT", -6,6)
        frame.icon.border:SetPoint("BOTTOMRIGHT", frame.icon.texture, "BOTTOMRIGHT", 6, -6)
        frame.icon.border:SetAtlas("plunderstorm-actionbar-slot-border")

        frame.icon.border:Hide()
    else
        frame.icon.border:Hide()
    end
    

    if data.type == "gossip" then
        if data.icon == 132053 then
            frame.icon.texture:Show()
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -2, 4)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -2, 4)
            frame.icon.texture:SetAtlas("crosshair_speak_128")
        elseif data.icon == 136458 then
            frame.icon.texture:Show()
            frame.icon.texture:SetAllPoints()
            frame.icon.texture:SetAtlas("Crosshair_innkeeper_128")
        elseif data.icon == 132060 then
            frame.icon.texture:Show()
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -2, 2)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -2, 0)
            frame.icon.texture:SetAtlas("Crosshair_pickup_128")
        elseif data.icon == 1673939 then
            frame.icon.texture:Show()
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -2, 0)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -2, 0)
            frame.icon.texture:SetAtlas("Crosshair_Transmogrify_128")
        elseif data.icon == 132057 then
            frame.icon.texture:Show()
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", 0, 4)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", 0, 4)
            frame.icon.texture:SetAtlas("Crosshair_Taxi_128")
        elseif data.icon == 132058 then
            frame.icon.texture:Show()
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", 0, 2)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", 0, 2)
            frame.icon.texture:SetAtlas("Crosshair_trainer_128")
        else
            print("file: " .. data.icon)
        end
    elseif (data.type == "gossipQuest" or data.type == "greetingQuest") then
        if data.isComplete then
            SetQuestTurnInIcon()
        elseif data.inProgress then
            SetQuestInProgressIcon()
        else
            SetQuestIcon()
        end

    elseif data.type == "acceptQuest" then
        if previousGossip then
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
        --print(data.texture)
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
        SetSpeakIcon()
    else
        frame.icon.texture:Hide()
    end
end

-- Обновление фокуса
local function UpdateFocus(element, changeFocus)
    if not element then
        return
    end

    -- Сброс фокуса для всех элементов
    local frames = parentFrame.ScrollBox:GetFrames()
    for _, frame in ipairs(frames) do
        frame:SetFocused(false)
    end

    focusedIndex = parentFrame.ScrollBox:FindElementDataIndex(element)

    local frame = parentFrame.ScrollBox:FindFrameByPredicate(function(frame, elementData)
        return elementData == element
    end)
    
    if frame and changeFocus then
        frame:SetFocused(true)
    end

    -- Прокрутить ScrollBox до текущего элемента
    if gamePadActive then
        parentFrame.ScrollBox:ScrollToElementDataIndex(focusedIndex)
    end
end

-- Функция переключения фокуса
local function MoveFocus(delta)
    if not parentFrame or not parentFrame.ScrollBox then
        return
    end
    local dataProvider = parentFrame.ScrollBox:GetDataProvider()
    if not dataProvider then
        return
    end
    local dataProviderSize = #dataProvider.collection
    local newIndex = math.max(1, math.min(focusedIndex + delta, dataProviderSize))
    local element = dataProvider.collection[newIndex]
    if element and UpdateFocus then
        UpdateFocus(element, true)
    end
end

-- Создание ScrollBox
local function CreateGossipScrollBox()
    -- Главный фрейм
    local GossipScrollBox = ConsoleMenuFrame.GossipFrame
    
    -- Создаем ScrollBox
    local ScrollBox = CreateFrame("Frame", "GossipScrollBox", GossipScrollBox, "WowScrollBoxList")
    GossipScrollBox.ScrollBox = ScrollBox
    ScrollBox:SetPoint("TOPLEFT", GossipScrollBox, "TOPLEFT", iconSize, 0)
    ScrollBox:SetPoint("BOTTOMRIGHT", GossipScrollBox, "BOTTOMRIGHT", -iconSize, 0)
    
    -- Создаем ScrollBar
    local ScrollBar = CreateFrame("EventFrame", "GossipScrollBar", GossipScrollBox, "MinimalScrollBar")
    GossipScrollBox.ScrollBox.ScrollBar = ScrollBar

    ScrollBar:SetPoint("TOPLEFT", ScrollBox, "TOPRIGHT")
    ScrollBar:SetPoint("BOTTOMLEFT", ScrollBox, "BOTTOMRIGHT")

    -- Создаем DataProvider и ScrollView
    local DataProvider = CreateDataProvider()
    local ScrollView = CreateScrollBoxListLinearView()

        -- Обновление отображения ScrollBar
    local function UpdateScrollBarVisibility()
        local totalHeight = ScrollView:GetExtent() - 1
        if totalHeight <= GossipScrollBox:GetHeight() then
            GossipScrollBar:Hide()
        else
            GossipScrollBar:Show()
        end
    end

    -- Получение Gossip меню
    local function GetGossip()
        -- Очищаем DataProvider
        DataProvider:Flush()

        -- Получаем данные квестов
        local quests = GetGossipQuests()
        
        -- Добавляем одиночные квесты
        for _, quest in ipairs(quests) do
            DataProvider:Insert({
                type = "gossipQuest",
                name = quest.title,
                inProgress = quest.inProgress,
                isComplete = quest.isComplete,
                questID = quest.questID
            })
        end

        -- Добавляем опции госсипа
        local options = C_GossipInfo.GetOptions()
        for _, option in ipairs(options) do
            DataProvider:Insert({
                type = "gossip",
                name = option.name,
                icon = option.icon,
                gossipOptionID = option.gossipOptionID,
            })
        end

        -- Добавить опцию просмотра отношений с NPC
        local reputationInfo = C_GossipInfo.GetFriendshipReputation(factionID or 0);
        if ( reputationInfo and reputationInfo.friendshipFactionID and  reputationInfo.friendshipFactionID > 0 ) then
            -- Добавить опцию выхода
            DataProvider:Insert({
                type = "reputation",
                name = "Отношения с " .. reputationInfo.name,
                reputationText = reputationInfo.text,
                reputationName = reputationInfo.name,
            })
        end

        -- Добавить опцию выхода
        DataProvider:Insert({
            type = "goodbye",
            name = GOODBYE,
        })

        UpdateScrollBarVisibility()
    end

    -- Получение Gossip меню
    local function GetGreeting()
        -- Очищаем DataProvider
        DataProvider:Flush()

        -- Получаем данные квестов
        local quests = GetGreetingQuests()
        
        -- Добавляем одиночные квесты
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
        

        -- Добавить опцию выхода
        DataProvider:Insert({
            type = "goodbye",
            name = GOODBYE,
        })

        UpdateScrollBarVisibility()
    end

    -- Обновить меню квеста
    local function UpdateQuestDetail()
        -- Очищаем DataProvider и добавляем новые данные
        DataProvider:Flush()

        local questID = GetQuestID()

        -- Добавить опцию принятия квеста
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

        -- Добавить опцию выхода
        DataProvider:Insert({
            type = "goodbye",
            name = GOODBYE,
        })
    end

    -- Показать отношения с NPC
    local function ShowReputation(reputationText, reputationName)
        -- Очищаем DataProvider и добавляем новые данные
        DataProvider:Flush()

        ConsoleMenu:AddSubtitles("GOSSIP_SHOW", reputationText, reputationName)
        ConsoleMenu:SubtitleFrameUpdate()

        -- Добавить опцию выхода
        DataProvider:Insert({
            type = "reputationBack",
            name = "Давай поговорим о чем-то другом.",
            reputationName = reputationName,
        })

        -- Добавить опцию выхода
        DataProvider:Insert({
            type = "goodbye",
            name = GOODBYE,
        })

        local element = parentFrame.ScrollBox:GetDataProvider().collection[1]
        if element then
            UpdateFocus(element, true)
        end
        UpdateScrollBarVisibility()
    end

    -- Вернуться к Gossip
    local function BackToGossip(reputationName)

        local gossipText = C_GossipInfo.GetText()
        ConsoleMenu:AddSubtitles("GOSSIP_SHOW", gossipText, reputationName)
        ConsoleMenu:SubtitleFrameUpdate()

        GetGossip()
        local element = parentFrame.ScrollBox:GetDataProvider().collection[1]
        if element then
            UpdateFocus(element, true)
        end
        UpdateScrollBarVisibility()
    end

    -- Кастомный инициализатор
    local function Initializer(frame, data)
        if not data then
            -- Если по какой-то причине data == nil, не обрабатываем
            return
        end

        -- Иконка
        if not frame.icon then
            frame.icon = CreateFrame("Frame", nil, frame)
            frame.icon:SetSize(iconSize, iconSize)
            frame.icon:SetPoint("LEFT", sectionPadding, 0)
        end

        setIcon(frame, data)

        -- Текст
        if not frame.text then
            frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            frame.text:SetPoint("LEFT", frame.icon, "RIGHT", sectionPadding, 0)
            frame.text:SetPoint("RIGHT", -sectionPadding, 0)
            frame.text:SetJustifyH("LEFT")
        end

        frame.text:SetFont("Fonts\\FRIZQT___CYR.TTF", itemFontSize, "OUTLINE")
        frame.text:SetText(data.name)
        frame.text:SetTextColor(1, 0.976, 0.855) -- Цвет текста FFF9DA

        -- Тень (фон)
        if not frame.bg then
            frame.bg = frame:CreateTexture(nil, "BACKGROUND")
            frame.bg:SetAllPoints()
            frame.bg:SetAtlas("Garr_BuildingInfoShadow") -- Прозрачный фон при наведении
            frame.bg:Hide() -- Скрываем фон по умолчанию
        end

        -- Обновление фокуса
        function frame:SetFocused(isFocused)
            if isFocused then
                frame.text:SetTextColor(1, 0.768, 0.071) -- Цвет текста FFC412
                frame.bg:Show() -- Показываем тень
            else
                frame.text:SetTextColor(1, 0.976, 0.855) -- Цвет текста FFF9DA
                frame.bg:Hide() -- Скрываем тень
            end
        end

        function frame:SelectOption()
            if data.type == "gossip" then
                C_GossipInfo.SelectOption(data.gossipOptionID)
            elseif ((data.type == "gossipQuest") and not data.inProgress)  then
                C_GossipInfo.SelectAvailableQuest(data.questID)
            elseif ((data.type == "gossipQuest") and data.inProgress) then
                C_GossipInfo.SelectActiveQuest(data.questID)
            elseif (data.type == "greetingQuest" and not data.inProgress) then
                SelectAvailableQuest(data.index)
            elseif (data.type == "greetingQuest" and data.inProgress) then
                SelectActiveQuest(data.index)
            elseif data.type == "gossipQuestLine" then
                GetLineQuestGossip(data.questLineID)
            elseif data.type == "backToGossip" then
                GetGossip()
            elseif data.type == "goodbye" then
                C_GossipInfo.CloseGossip()
                CloseQuest()
            elseif data.type == "acceptQuest" then
                AcceptQuest()
            elseif data.type == "progressQuest" then
                CompleteQuest()
            elseif data.type == "completeQuest" or data.type == "completeQuestInStoryline" or data.type == "completeQuestWithReward" then
                if data.index then
                    GetQuestReward(data.index)
                else
                    GetQuestReward(1)
                end
            elseif data.type == "reputation" then
                ShowReputation(data.reputationText, data.reputationName)
            elseif data.type == "reputationBack" then
                BackToGossip(data.reputationName)
            elseif data.type == "completedAccountQuest" then
                CloseQuest()
            else
                print("Unknown data type:", data.type)
            end
        end

        -- Фокус (изменение подложки при наведении)
        frame:SetScript("OnEnter", function()
            UpdateFocus(data, false)
            frame:SetFocused(true)
        end)
        frame:SetScript("OnLeave", function()
            -- При уходе мыши фокус остается на текущем элементе
        end)

        frame:SetScript("OnMouseDown", function()
            frame:SelectOption()
        end)

    end

    -- Устанавливаем кастомный элемент как шаблон
    ScrollView:SetElementExtent(sectionHeight)
    ScrollView:SetElementInitializer("Frame", Initializer)

    -- Инициализируем ScrollBox с ScrollBar
    ScrollUtil.InitScrollBoxListWithScrollBar(ScrollBox, ScrollBar, ScrollView)
    ScrollView:SetDataProvider(DataProvider)

    -- Обработка событий GOSSIP_SHOW и GOSSIP_CLOSED
    local EventFrame = CreateFrame("Frame", nil, GossipScrollBox)
    EventFrame:RegisterEvent("GOSSIP_SHOW")
    EventFrame:RegisterEvent("GOSSIP_CLOSED")
    EventFrame:RegisterEvent("QUEST_GREETING")
    EventFrame:RegisterEvent("QUEST_DETAIL")
    EventFrame:RegisterEvent("QUEST_PROGRESS")
    EventFrame:RegisterEvent("QUEST_COMPLETE")
    EventFrame:RegisterEvent("QUEST_FINISHED")
    EventFrame:RegisterEvent("QUEST_TURNED_IN")
    EventFrame:RegisterEvent("QUEST_ACCEPTED")
    EventFrame:RegisterEvent("QUESTLINE_UPDATE")
    EventFrame:RegisterEvent("GOSSIP_CONFIRM")


    EventFrame:SetScript("OnEvent", function(self, event)

        if event == "GOSSIP_SHOW" then
            
            GetGossip()

            previousGossip = false

            local element = parentFrame.ScrollBox:GetDataProvider().collection[1]
            if element then
                UpdateFocus(element, true) -- Устанавливаем фокус на первый элемент
            end

        elseif event == "QUEST_GREETING" then

            GetGreeting()

            previousGossip = false

            local element = parentFrame.ScrollBox:GetDataProvider().collection[1]
            if element then
                UpdateFocus(element, true)
            end
            
        elseif event == "QUEST_DETAIL" then
            local questID = GetQuestID()

            if questID ~= 0 then
                UpdateQuestDetail()
                local element = parentFrame.ScrollBox:GetDataProvider().collection[1]
                if element then
                    UpdateFocus(element, true) -- Устанавливаем фокус на первый элемент
                end
            end
            
        elseif event == "QUEST_PROGRESS" then
            -- Очищаем DataProvider и добавляем новые данные
            DataProvider:Flush()

            local questID = GetQuestID()
            local isComplete = C_QuestLog.IsComplete(questID)
            local numRequiredItems = GetNumQuestItems()

            if isComplete then
                if numRequiredItems == 0 then
                    -- Добавить опцию выхода
                    DataProvider:Insert({
                        type = "progressQuest",
                        name = "Что дальше?",
                    })
                elseif numRequiredItems == 1 then
                    local itemLink = GetQuestItemLink("required", 1)
                    local itemName, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ = C_Item.GetItemInfo(itemLink)

                    -- Добавить опцию выхода
                    DataProvider:Insert({
                        type = "progressQuest",
                        name = itemName .. " при мне.",
                    })
                else
                    -- Добавить опцию выхода
                    DataProvider:Insert({
                        type = "progressQuest",
                        name = "Готово!",
                    })
                end
            elseif numRequiredItems == 1 then
                local name, texture, count, quality, isUsable, itemID = GetQuestItemInfo("required", 1)
                local currentCount = C_Item.GetItemCount(itemID)

                if currentCount >= count then
                    -- Добавить опцию выхода
                    DataProvider:Insert({
                        type = "progressQuest",
                        name = name .. " при мне.",
                    })
                else
                    -- Добавить опцию выхода
                    DataProvider:Insert({
                        type = "goodbye",
                        name = "Мне нужно больше времени",
                    })
                end
            elseif numRequiredItems > 1 then

                local currentItems = 0
                
                for i = 1, numRequiredItems do
                    local name, texture, count, quality, isUsable, itemID = GetQuestItemInfo("required", i)
                    local currentCount = C_Item.GetItemCount(itemID)
                    if currentCount >= count then
                        currentItems = currentItems + 1
                    end
                end

                if currentItems == numRequiredItems then
                    -- Добавить опцию выхода
                    DataProvider:Insert({
                        type = "progressQuest",
                        name = "Все необходимое при мне",
                    })
                else
                    -- Добавить опцию выхода
                    DataProvider:Insert({
                        type = "goodbye",
                        name = "Мне нужно больше времени",
                    })
                end
            else
                -- Добавить опцию выхода
                DataProvider:Insert({
                    type = "goodbye",
                    name = "Мне нужно больше времени",
                })
            end

            -- Добавить опцию выхода
            DataProvider:Insert({
                type = "goodbye",
                name = GOODBYE,
            })

            local element = parentFrame.ScrollBox:GetDataProvider().collection[1]
            if element then
                UpdateFocus(element, true) -- Устанавливаем фокус на первый элемент
            end

        elseif event == "QUEST_COMPLETE" then
            -- Очищаем DataProvider и добавляем новые данные
            DataProvider:Flush()

            local questID = GetQuestID()
            local questLineInfo = C_QuestLine.GetQuestLineInfo(questID)
            local questIDs
            local numChoices = GetNumQuestChoices()

            if questLineInfo then
                questIDs = C_QuestLine.GetQuestLineQuests(questLineInfo.questLineID)
            end

            if questLineInfo and not (questIDs[#questIDs] == questID) and (numChoices <= 1) then
                -- Добавить опцию продолжения Storyline
                DataProvider:Insert({
                    type = "completeQuestInStoryline",
                    name = "Что дальше?",
                    numChoices = numChoices,
                    questID = questID,
                    isComplete = true,
                    inProgress = false,
                })
            elseif numChoices > 1 then
                -- Выбор награды
                for i = 1, numChoices do
                    local lootType = GetQuestItemInfoLootType("choice", i)
                    if lootType == 0 then
                        local itemLink = GetQuestItemLink("choice", i)
                        if itemLink then
                            local item = Item:CreateFromItemLink(itemLink)
                            item:ContinueOnItemLoad(function()
                                local name = item:GetItemName()
                                local texture = item:GetItemIcon()
                                DataProvider:Insert({
                                    type = "completeQuestWithReward",
                                    name = name,
                                    numChoices = numChoices,
                                    index = i,
                                    questID = questID,
                                    isComplete = true,
                                    inProgress = false,
                                    texture = texture,
                                })
                                UpdateScrollBarVisibility()
                            end)
                        end
                
                    elseif lootType == 1 then
                        local currencyInfo = C_QuestLog.GetQuestRewardCurrencyInfo(questID, i, true) or C_QuestOffer.GetQuestRewardCurrencyInfo("choice", i);
                        if currencyInfo then
                            -- Преобразуем данные, если это контейнер валюты
                            local name, texture, amount, quality = CurrencyContainerUtil.GetCurrencyContainerInfo(
                                currencyInfo.currencyID,
                                currencyInfo.totalRewardAmount,
                                currencyInfo.name,
                                currencyInfo.texture,
                                currencyInfo.quality
                            )
                    
                            -- Добавляем в DataProvider
                            DataProvider:Insert({
                                type = "completeQuestWithReward",
                                name = name,
                                numChoices = numChoices,
                                index = i,
                                questID = questID,
                                isComplete = true,
                                inProgress = false,
                                texture = texture,
                            })
                        end
                    end
                    
                end
                
            else
                -- Добавить опцию завершения квеста
                DataProvider:Insert({
                    type = "completeQuest",
                    name = COMPLETE_QUEST,
                    numChoices = numChoices,
                    index = 1,
                    questID = questID,
                    isComplete = true,
                    inProgress = false,
                })
            end

            -- Добавить опцию выхода
            DataProvider:Insert({
                type = "goodbye",
                name = GOODBYE,
            })

            local element = parentFrame.ScrollBox:GetDataProvider().collection[1]
            if element then
                UpdateFocus(element, true) -- Устанавливаем фокус на первый элемент
            end

        elseif event == "GOSSIP_CLOSED" then
            previousGossip = true
        elseif event == "QUEST_FINISHED" or event == "GOSSIP_CONFIRM" then
        elseif event == "QUEST_ACCEPTED" or event == "QUEST_TURNED_IN" then
            previousGossip = false
        end

        UpdateScrollBarVisibility()

    end)

    return GossipScrollBox, UpdateFocus
end

-- Подключение контроллера
local function toggleController(updateFocus)

    -- Создаем фрейм для обработки событий геймпада
    local controllerHandler = CreateFrame("Frame", "ControllerHandlerFrame", parentFrame)

    parentFrame:HookScript("OnShow", function()
        controllerHandler:EnableGamePadButton(true)
        controllerHandler:SetScript("OnGamePadButtonDown", function(_, button)
            if button == "PADDUP" then
                MoveFocus(-1)
            elseif button == "PADDDOWN" then
                MoveFocus(1)
            elseif button == "PAD1" then
                local element = parentFrame.ScrollBox:GetDataProvider().collection[focusedIndex]
                if element then
                    local frame = parentFrame.ScrollBox:FindFrameByPredicate(function(frame, elementData)
                        return elementData == element
                    end)
                    if frame and frame.SelectOption then
                        frame:SelectOption()
                    end
                end
            elseif button == "PAD2" then
                C_GossipInfo.CloseGossip()
                CloseQuest()
            elseif button == "PAD4" then
                ConsoleMenu:SkipCurrentSubtitle()
            end
        end)
    end)

    parentFrame:HookScript("OnHide", function()
        controllerHandler:EnableGamePadButton(false)
        controllerHandler:SetScript("OnGamePadButtonDown", nil)
    end)
end

-- Создание фрейма
function ConsoleMenu:SetCustomGossipFrame()
    if ConsoleMenuDB.dialogQuestWindowStyle == 2 then
        return
    end

    local frame = CreateFrame("Frame", "GossipFrame", ConsoleMenuFrame)
    ConsoleMenuFrame.GossipFrame = frame
    

    frame:SetSize(frameWidth, sectionHeight * viewedItemCount)
    frame:SetPoint("TOP", SubtitleFrame, "BOTTOM", 0, -16)
    frame:Hide()
    ConsoleMenu:InitFadeAnimations(frame, animationDuration)

    frame:HookScript("OnShow", function()
        softTargetEnemy = GetCVar("SoftTargetEnemy")
        SetCVar("SoftTargetEnemy", 0)

        UpdateFocus(parentFrame.ScrollBox:GetDataProvider().collection[1], true)

        if WeakAuras then
            WeakAuras.ScanEvents("CHANGE_CONTEXT", "window")
            WeakAuras.ScanEvents("SHOW_GOSSIP_FRAME", true)
        end

    end)

    frame:HookScript("OnHide", function()
        if softTargetEnemy then
            SetCVar("SoftTargetEnemy", softTargetEnemy)
        end

        if WeakAuras then
            WAGlobal = WAGlobal or {}  -- Создаем таблицу, если её ещё нет
            local previousContext = WAGlobal.previousContext or "exploring"
            WeakAuras.ScanEvents("CHANGE_CONTEXT", previousContext)
            WeakAuras.ScanEvents("SHOW_GOSSIP_FRAME", false)
        end

    end)

    -- Регистрация события изменения режима геймпада
    frame:RegisterEvent("GAME_PAD_ACTIVE_CHANGED")

    frame:RegisterEvent("GOSSIP_SHOW")
    frame:RegisterEvent("QUEST_GREETING")
    frame:RegisterEvent("QUEST_DETAIL")
    frame:RegisterEvent("QUEST_PROGRESS")
    frame:RegisterEvent("QUEST_COMPLETE")
    frame:RegisterEvent("QUEST_TURNED_IN")
    frame:RegisterEvent("QUEST_ACCEPTED")
    frame:RegisterEvent("QUESTLINE_UPDATE")


    frame:RegisterEvent("QUEST_FINISHED")
    frame:RegisterEvent("GOSSIP_CLOSED")
    frame:RegisterEvent("GOSSIP_CONFIRM")

    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "GAME_PAD_ACTIVE_CHANGED" then
            gamePadActive = ...
        elseif event == "GOSSIP_SHOW" or event == "QUEST_GREETING" or event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" then
            ConsoleMenu:AnimatedShow(frame)
        elseif event == "QUEST_DETAIL" then
            local questID = GetQuestID()

            if questID ~= 0 then
                ConsoleMenu:AnimatedShow(frame)
            end
        elseif event == "GOSSIP_CLOSED" or event == "GOSSIP_CONFIRM" or event == "QUEST_FINISHED" then

            local previousCollection = parentFrame.ScrollBox:GetDataProvider().collection

            C_Timer.After(animationDuration + 0.1, function()
                local collection = parentFrame.ScrollBox:GetDataProvider().collection
                if collection == previousCollection then
                    ConsoleMenu:AnimatedHide(frame)
                end
            end)
        end
    end)
    
    -- Создаем основной фрейм
    parentFrame, UpdateFocus = CreateGossipScrollBox()

    -- Добавляем обработку геймпада
    toggleController(updateFocus)

end
