local ConsoleMenu = LibStub("AceAddon-3.0"):GetAddon("ConsoleMenu")
local parentFrame
local frames = {} -- Хранение всех созданных элементов
local focusedIndex = 1 -- Индекс текущего элемента в фокусе
local questsInQuestLine = {}
local questsWithoutQuestline = {}
local previousGossip = false

-- Провкрка элемента на вхождение в массив
local function isElementInTable(element, table)
    for _, value in ipairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- DEPRECATED: Получение Questline по множеству квестов
local function GetUniqueQuestLineInfoArray(quests)
    local result = {}
    local seenQuestLineIDs = {}

    for _, quest in ipairs(quests) do
        if not seenQuestLineIDs[quest.questLineID] then
            table.insert(result, {
                questLineID = quest.questLineID,
                questLineName = quest.questLineName
            })
            seenQuestLineIDs[quest.questLineID] = true
        end
    end

    return result
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

-- DEPRECATED: Получение статуса цепочки
local function GetQuestLineStatus(questLineID)
    local quests = C_QuestLine.GetQuestLineQuests(questLineID)
    local firstComplete = C_QuestLog.IsQuestFlaggedCompleted(quests[1]) or C_QuestLog.IsOnQuest(quests[1])
    local lastComplete = C_QuestLog.IsQuestFlaggedCompleted(quests[#quests]) or C_QuestLog.IsOnQuest(quests[#quests])

    if not firstComplete then
        return "start"
    elseif firstComplete and lastComplete then
        return "complete"
    else
        return "progress"
    end
end

-- Установка иконки пункту списка
local function setIcon(frame, data)

    -- Вспомогательные функции для определенных иконок
    ---- Иконка квеста в зависимости от его класса
    local function SetQuestIcon()
        local classification = C_QuestInfoSystem.GetQuestClassification(data.questID)
        if classification == 1 then
        elseif classification == 2 then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -6, 0)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -6, 0)
            frame.icon.texture:SetAtlas("Crosshair_campaignquest_128")
        elseif classification == 4 then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -1, 2)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -1, 2)
            frame.icon.texture:SetAtlas("Crosshair_Wrapper_128")
        elseif classification == 7 then
            frame.icon.texture:SetAllPoints()
            frame.icon.texture:SetAtlas("Crosshair_Quest_128")
        end

        frame.icon.texture:Show()
    end

    ---- Иконка завершения квеста в зависимости от его класса
    local function SetQuestTurnInIcon()
        
        local classification = C_QuestInfoSystem.GetQuestClassification(data.questID)
        if classification == 1 then
        elseif classification == 2 then
            
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -6, 0)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -6, 0)
            frame.icon.texture:SetAtlas("Crosshair_campaignquestturnin_128")
        elseif classification == 4 then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -1, 2)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -1, 2)
            frame.icon.texture:SetAtlas("Crosshair_Wrapperturnin_128")
        elseif classification == 7 then
            frame.icon.texture:SetAllPoints()
            frame.icon.texture:SetAtlas("Crosshair_Questturnin_128")
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

    -- Смена текстур и их видимости

    if not frame.icon.texture then
        frame.icon.texture = frame.icon:CreateTexture(nil, "ARTWORK")
        frame.icon.texture:Hide()
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
    elseif data.type == "completeQuest" then
        SetQestTurnInIcon()
    elseif data.type == "goodbye" then
        SetSpeakIcon()
    else
        frame.icon.texture:Hide()
    end
end

-- Создание ScrollBox
local function CreateGossipScrollBox()
    -- Главный фрейм
    local GossipScrollBox = CreateFrame("Frame", "GossipScroll", UIParent)
    GossipScrollBox:SetSize(640, 48*3)
    GossipScrollBox:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 96)
    
    -- Создаем ScrollBox
    local ScrollBox = CreateFrame("Frame", "GossipScrollBox", GossipScrollBox, "WowScrollBoxList")
    GossipScrollBox.ScrollBox = ScrollBox
    ScrollBox:SetPoint("TOPLEFT", GossipScrollBox, "TOPLEFT", 0, 0)
    ScrollBox:SetAllPoints()

    -- Создаем ScrollBar
    local ScrollBar = CreateFrame("EventFrame", "GossipScrollBar", GossipScrollBox, "MinimalScrollBar")
    GossipScrollBox.ScrollBox.ScrollBar = ScrollBar

    ScrollBar:SetPoint("TOPLEFT", ScrollBox, "TOPRIGHT")
    ScrollBar:SetPoint("BOTTOMLEFT", ScrollBox, "BOTTOMRIGHT")

    -- Создаем DataProvider и ScrollView
    local DataProvider = CreateDataProvider()
    local ScrollView = CreateScrollBoxListLinearView()
    ScrollView:SetDataProvider(DataProvider)

    -- Инициализируем ScrollBox с ScrollBar
    ScrollUtil.InitScrollBoxListWithScrollBar(ScrollBox, ScrollBar, ScrollView)

    -- Обновление отображения ScrollBar
    local function UpdateScrollBarVisibility()
        local totalHeight = ScrollView:GetElementExtent() * DataProvider:GetSize()
        if totalHeight <= GossipScroll:GetHeight() then
            GossipScrollBar:Hide()
        else
            GossipScrollBar:Show()
        end
    end

    -- Получение Gossip меню
    local function GetGossip()
        -- Очищаем DataProvider и хранимые данные
        DataProvider:Flush()
        frames = {}

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

        -- Добавить опцию выхода
        DataProvider:Insert({
            type = "goodbye",
            name = GOODBYE,
        })

        UpdateScrollBarVisibility()
    end

    -- Получение Gossip меню
    local function GetGreeting()
        -- Очищаем DataProvider и хранимые данные
        DataProvider:Flush()
        frames = {}

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

    -- Обновление фокуса
    local function UpdateFocus(newIndex)
        -- Сброс фокуса для всех элементов
        for _, frame in ipairs(frames) do
            if frame and frame.SetFocused then
                frame:SetFocused(false)
            end
        end

        focusedIndex = newIndex
        
        if frames[focusedIndex] then
            frames[focusedIndex]:SetFocused(true)

            -- Смещаем скролл до текущего элемента
            parentFrame.ScrollBox:ScrollToElementDataIndex(newIndex)
        end
    end

    -- DEPRECATED: Отобразить меню цепочки цвестов
    local function GetLineQuestGossip(questLineID)
        -- Очищаем DataProvider и хранимые данные
        DataProvider:Flush()
        frames = {}

        for _, quest in ipairs(questsInQuestLine) do
            if quest.questLineID == questLineID then
                DataProvider:Insert({
                    type = "gossipQuestInQuestLine",
                    name = quest.questName,
                    isQuestStart = quest.isQuestStart,
                    inProgress = quest.inProgress,
                    isComplete = quest.isComplete,
                    questID = quest.questID,
                    questLineStatus = GetQuestLineStatus(questLineID),
                })
            end
        end

        -- Добавить опцию возврата к Gossip
        DataProvider:Insert({
            type = "backToGossip",
            name = BACK,
        })

        UpdateFocus(1) -- Устанавливаем фокус на первый элемент

        UpdateScrollBarVisibility()
    end

    -- Обновить меню квеста
    local function UpdateQuestDetail()
        -- Очищаем DataProvider и добавляем новые данные
        DataProvider:Flush()
        frames = {} -- Сбрасываем список фреймов

        local questID = GetQuestID()
        local questLineInfo = C_QuestLine.GetQuestLineInfo(questID)

        -- Добавить опцию принятия квеста
        DataProvider:Insert({
            type = "acceptQuest",
            name = "Я этим займусь.",
            questID = questID,
        })

        -- Добавить опцию выхода
        DataProvider:Insert({
            type = "goodbye",
            name = GOODBYE,
        })
    end

    -- Кастомный инициализатор
    local function Initializer(frame, data)
        table.insert(frames, frame) -- Добавляем элемент в массив

        -- Иконка
        if not frame.icon then
            frame.icon = CreateFrame("Frame", nil, frame)
            frame.icon:SetSize(32, 32)
            frame.icon:SetPoint("LEFT", 10, 0)
        end

        setIcon(frame, data)

        -- Текст
        if not frame.text then
            frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            frame.text:SetPoint("LEFT", frame.icon, "RIGHT", 10, 0)
            frame.text:SetPoint("RIGHT", -10, 0)
            frame.text:SetJustifyH("LEFT")
        end

        frame.text:SetFont("Fonts\\FRIZQT___CYR.TTF", 20, "OUTLINE")
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
            elseif data.type == "completeQuest" then
                if data.numChoices < 2 then
                    GetQuestReward(1)
                end
            else
                print("Unknown data type:", data.type)
            end
        end

        -- -- Фокус (изменение подложки при наведении)
        -- frame:SetScript("OnEnter", function()
        --     frame:SetFocused(true)
        -- end)
        -- frame:SetScript("OnLeave", function()
        --     frame:SetFocused(false)
        -- end)

        frame:SetScript("OnMouseDown", function()
            frame:SelectOption()
        end)

    end

    -- Устанавливаем кастомный элемент как шаблон
    ScrollView:SetElementExtent(48)
    ScrollView:SetElementInitializer("Frame", Initializer)

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


        EventFrame:SetScript("OnEvent", function(self, event)
            
            if event == "GOSSIP_SHOW" then
                
                GetGossip()

                GossipScrollBox:Show()
                previousGossip = false

                UpdateFocus(1) -- Устанавливаем фокус на первый элемент

            elseif event == "QUEST_GREETING" then

                GetGreeting()

                GossipScrollBox:Show()
                previousGossip = false

                UpdateFocus(1)
                
            elseif event == "QUEST_DETAIL" then

                UpdateQuestDetail()

                GossipScrollBox:Show()
                UpdateFocus(1) -- Устанавливаем фокус на первый элемент
                
            elseif event == "QUEST_PROGRESS" then
                -- Очищаем DataProvider и добавляем новые данные
                DataProvider:Flush()
                frames = {} -- Сбрасываем список фреймов

                -- Добавить опцию выхода
                DataProvider:Insert({
                    type = "goodbye",
                    name = GOODBYE,
                })

                GossipScrollBox:Show()
                UpdateFocus(1) -- Устанавливаем фокус на первый элемент

            elseif event == "QUEST_COMPLETE" then
                -- Очищаем DataProvider и добавляем новые данные
                DataProvider:Flush()
                frames = {} -- Сбрасываем список фреймов

                local questID = GetQuestID()
                local questLineInfo = C_QuestLine.GetQuestLineInfo(questID)
                local questIDs = C_QuestLine.GetQuestLineQuests(questLineInfo.questLineID)

                if questLineInfo and not (questIDs[#questIDs] == questID) then
                    -- Добавить опцию продолжения Storyline
                    DataProvider:Insert({
                        type = "completeQuestInStoryline",
                        name = "Что дальше?",
                        numChoices = GetNumQuestChoices(),
                        questID = questID,
                        questLineStatus = GetQuestLineStatus(questLineInfo.questLineID),
                    })
                else
                    -- Добавить опцию завершения квеста
                    DataProvider:Insert({
                        type = "completeQuest",
                        name = COMPLETE_QUEST,
                        numChoices = GetNumQuestChoices(),
                        questID = questID,
                    })
                end

                -- Добавить опцию выхода
                DataProvider:Insert({
                    type = "goodbye",
                    name = GOODBYE,
                })

                GossipScrollBox:Show()
                UpdateFocus(1) -- Устанавливаем фокус на первый элемент

            elseif event == "GOSSIP_CLOSED" then
                previousGossip = true
                GossipScrollBox:Hide()
            elseif event == "QUEST_FINISHED" then
                GossipScrollBox:Hide()
            elseif event == "QUEST_ACCEPTED" or "QUEST_TURNED_IN" then
                previousGossip = false
            end

            UpdateScrollBarVisibility()

        end)

    -- Изначально скрываем GossipScrollBox
    GossipScrollBox:Hide()

    return GossipScrollBox, UpdateFocus
end

local function MoveFocus(delta)
    local newIndex = math.max(1, math.min(focusedIndex + delta, #frames))
    updateFocus(newIndex)
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
                if frames[focusedIndex] then
                    frames[focusedIndex]:SelectOption()
                end
            elseif button == "PAD2" then
                C_GossipInfo.CloseGossip()
            end
        end)
    end)

    parentFrame:HookScript("OnHide", function()
        controllerHandler:EnableGamePadButton(false)
        controllerHandler:SetScript("OnGamePadButtonDown", nil)
    end)
end

function ConsoleMenu:SetCustomGossipFrame()
    -- Создаем основной фрейм
    parentFrame, updateFocus = CreateGossipScrollBox()

    -- Добавляем обработку геймпада
    toggleController(updateFocus)
end
