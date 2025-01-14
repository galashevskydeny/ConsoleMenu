local ConsoleMenu = LibStub("AceAddon-3.0"):GetAddon("ConsoleMenu")
local parentFrame
local frames = {} -- Хранение всех созданных элементов
local focusedIndex = 1 -- Индекс текущего элемента в фокусе
local questsInQuestLine = {}
local questsWithoutQuestline = {}

-- Провкрка элемента на вхождение в массив
local function isElementInTable(element, table)
    for _, value in ipairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- Получение данных квестов при открытии Gossip
local function GetGossipQuests()
    -- Загружаем данные квестов
    local activeQuests = C_GossipInfo.GetActiveQuests()
    local availableQuests = C_GossipInfo.GetAvailableQuests()

    -- Объединяем таблицы
    for _, quest in ipairs(activeQuests) do
        local info = C_QuestLine.GetQuestLineInfo(quest.questID)
        if info then
            info.isComplete = quest.isComplete
            table.insert(questsInQuestLine, info)
        else
            local quest = {
                questName = QuestUtils_GetQuestName(quest.questID),
                questID = quest.questID,
                inProgress = true,
                isQuestStart = false,
                isComplete = quest.isComplete
            }
            table.insert(questsWithoutQuestline, quest)
        end
    end
    for _, quest in ipairs(availableQuests) do
        local info = C_QuestLine.GetQuestLineInfo(quest.questID)
        if info then
            info.isComplete = quest.isComplete
            table.insert(questsInQuestLine, info)
        else
            local quest = {
                questName = QuestUtils_GetQuestName(quest.questID),
                questID = quest.questID,
                inProgress = false,
                isQuestStart = true,
                isComplete = quest.isComplete
            }
            table.insert(questsWithoutQuestline, quest)
        end
    end
end

-- Получение Questline по множеству увестов
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

-- Установка иконки пункту списка
local function setIcon(frame, data)
    if not frame.icon.texture then
        frame.icon.texture = frame.icon:CreateTexture(nil, "ARTWORK")
    end

    if data.type == "gossip" then
        print("file: " .. data.icon)
        if data.icon == 132053 then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -2, 4)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -2, 4)
            frame.icon.texture:SetAtlas("crosshair_speak_128")
        elseif data.icon == 136458 then
            frame.icon.texture:SetAllPoints()
            frame.icon.texture:SetAtlas("Crosshair_innkeeper_128")
        elseif data.icon == 132060 then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -2, 2)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -2, 0)
            frame.icon.texture:SetAtlas("Crosshair_pickup_128")
        elseif data.icon == 1673939 then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -2, 0)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -2, 0)
            frame.icon.texture:SetAtlas("Crosshair_Transmogrify_128")
        elseif data.icon == 132057 then
            frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", 0, 4)
            frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", 0, 4)
            frame.icon.texture:SetAtlas("Crosshair_Taxi_128")
        end
    elseif (data.type == "gossipQuest" and data.isQuestStart) or data.type == "acceptQuest" then
        print("quest classification: " .. C_QuestInfoSystem.GetQuestClassification(data.questID))

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

    elseif (data.type == "gossipQuest" and data.isComplete) or data.type == "completeQuest" then
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
    elseif (data.type == "gossipQuest" and not data.isComplete and data.inProgress) then
        frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -4, 4)
        frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", 4, -4)
        frame.icon.texture:SetAtlas("Quest-In-Progress-Icon-yellow")
    elseif data.type == "goodbye" then
        frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -2, 2)
        frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -2, 2)
        frame.icon.texture:SetAtlas("crosshair_speak_128")
    else
        print("Unknown data type:", data.type)
    end
end

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

    -- Получение Gossip меню
    local function GetGossip()
        -- Очищаем DataProvider и хранимые данные
        DataProvider:Flush()
        frames = {}
        questsWithoutQuestline = {}
        questsInQuestLine = {}

        -- Получаем данные квестов
        GetGossipQuests()
        
        -- Добавляем одиночные квесты
        for _, quest in ipairs(questsWithoutQuestline) do
            DataProvider:Insert({
                type = "gossipQuest",
                name = quest.questName,
                isQuestStart = quest.isQuestStart,
                inProgress = quest.inProgress,
                isComplete = quest.isComplete,
                questID = quest.questID
            })
        end

        -- Добавляем цепочки квестов
        local lines = GetUniqueQuestLineInfoArray(questsInQuestLine)
        for _, line in ipairs(lines) do
            if CountByQuestLineID(questsInQuestLine, line.questLineID) > 1 then
                -- Цепочки с несколькими квестами в Gossip
                DataProvider:Insert({
                    type = "gossipQuestLine",
                    name = line.questLineName,
                    questLineID = line.questLineID,
                })
            else
                -- Цепочка с одним квестом в Gossip
                for _, quest in ipairs(questsInQuestLine) do
                    if quest.questLineID == line.questLineID then
                        DataProvider:Insert({
                            type = "gossipQuest",
                            name = quest.questLineName,
                            isQuestStart = quest.isQuestStart,
                            inProgress = quest.inProgress,
                            isComplete = quest.isComplete,
                            questID = quest.questID
                        })
                    end
                end
            end
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

    -- Отобразить меню цепочки цвестов
    local function GetLineQuestGossip(questLineID)
        -- Очищаем DataProvider и хранимые данные
        DataProvider:Flush()
        frames = {}

        for _, quest in ipairs(questsInQuestLine) do
            if quest.questLineID == questLineID then
                DataProvider:Insert({
                    type = "gossipQuest",
                    name = quest.questName,
                    isQuestStart = quest.isQuestStart,
                    inProgress = quest.inProgress,
                    isComplete = quest.isComplete,
                    questID = quest.questID
                })
            end
        end

        -- Добавить опцию возврата к Gossip
        DataProvider:Insert({
            type = "backToGossip",
            name = BACK,
        })

        UpdateFocus(1) -- Устанавливаем фокус на первый элемент
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
            elseif (data.type == "gossipQuest" and data.isQuestStart)  then
                C_GossipInfo.SelectAvailableQuest(data.questID)
            elseif (data.type == "gossipQuest" and not data.isQuestStart) then
                C_GossipInfo.SelectActiveQuest(data.questID)
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
    EventFrame:RegisterEvent("QUEST_DETAIL")
    EventFrame:RegisterEvent("QUEST_PROGRESS")
    EventFrame:RegisterEvent("QUEST_COMPLETE")
    EventFrame:RegisterEvent("QUEST_FINISHED")
    EventFrame:RegisterEvent("QUEST_TURNED_IN")

    EventFrame:SetScript("OnEvent", function(self, event)
        if event == "GOSSIP_SHOW" or event == "QUEST_TURNED_IN" then

            GetGossip()

            if event == "GOSSIP_SHOW" then
                GossipScrollBox:Show()
            end

            UpdateFocus(1) -- Устанавливаем фокус на первый элемент
            
        elseif event == "QUEST_DETAIL" then
            -- Очищаем DataProvider и добавляем новые данные
            DataProvider:Flush()
            frames = {} -- Сбрасываем список фреймов

            local questID = GetQuestID()
            local questLineInfo = C_QuestLine.GetQuestLineInfo(questID)

            if questLineInfo then
                local questIDs = C_QuestLine.GetQuestLineQuests(questLineInfo.questLineID)
                if questIDs[1] == questID then
                    -- Добавить опцию начала Storyline
                    DataProvider:Insert({
                        type = "acceptQuest",
                        name = VOICEMACRO_2_Hu_0,
                        questID = questID,
                    })
                    
                else
                    -- Добавить опцию продолжения Storyline
                    DataProvider:Insert({
                        type = "acceptQuestInStoryline",
                        name = "Я этим займусь.",
                        questID = questID,
                    })
                end
            else
                -- Добавить опцию принятия квеста
                DataProvider:Insert({
                    type = "acceptQuest",
                    name = "Я этим займусь.",
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
            
        elseif event == "QUEST_PROGRESS" then
        elseif event == "QUEST_COMPLETE" then
            -- Очищаем DataProvider и добавляем новые данные
            DataProvider:Flush()
            frames = {} -- Сбрасываем список фреймов

            local questID = GetQuestID()
            local questLineInfo = C_QuestLine.GetQuestLineInfo(questID)

            if questLineInfo then
                local questIDs = C_QuestLine.GetQuestLineQuests(questLineInfo.questLineID)
                if questIDs[#questIDs] == questID then
                    -- Добавить опцию завершения Storyline
                    DataProvider:Insert({
                        type = "completeQuest",
                        name = COMPLETE_QUEST .. " " .. questLineInfo.questLineName,
                        numChoices = GetNumQuestChoices(),
                        questID = questID,
                    })
                    
                else
                    -- Добавить опцию продолжения Storyline
                    DataProvider:Insert({
                        type = "completeQuestInStoryline",
                        name = "Что дальше?",
                        numChoices = GetNumQuestChoices(),
                        questID = questID,
                    })
                end
            else
                -- Добавить опцию завершения квеста
                DataProvider:Insert({
                    type = "completeQuest",
                    name = COMPLETE_QUEST .. " " .. C_QuestLog.GetTitleForQuestID(questID),
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

        elseif event == "GOSSIP_CLOSED" or event == "QUEST_FINISHED" then
            GossipScrollBox:Hide()
        end

        local totalHeight = ScrollView:GetElementExtent() * DataProvider:GetSize()
        if totalHeight <= GossipScroll:GetHeight() then
            GossipScrollBar:Hide()
        else
            GossipScrollBar:Show()
        end

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
