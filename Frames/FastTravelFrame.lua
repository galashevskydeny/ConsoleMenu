-- FastTravelFrame.lua

local ConsoleMenu = _G.ConsoleMenu
local parentFrame
local updateFocus
local setItemList
local frames = {}
local focusedIndex = 1
local PAD1_COMMON_BINDING
local softTargetEnemy

local mageTeleports = {
    -- War Within
    446540,

    -- Dragonflight
    395277, -- Teleport: Valdrakken

    -- Shadowlands
    344587, -- Teleport: Oribos

    -- Battle for Azeroth
    281403, -- Teleport: Boralus (Alliance)
    281404, -- Teleport: Dazar'alor (Horde)

    -- Legion
    224869, -- Teleport: Dalaran (Broken Isles)
    193759, -- Телепортация: Оплот Хранителя

    -- Warlords of Draenor
    176248, -- Teleport: Stormshield (Alliance)
    176242, -- Teleport: Warspear (Horde)

    -- Mists of Pandaria
    132621, -- Teleport: Vale of Eternal Blossoms (Alliance, Shrine of Seven Stars)
    132627, -- Teleport: Vale of Eternal Blossoms (Horde, Shrine of Two Moons)

    -- Классические города
    3561,   -- Teleport: Stormwind
    3567,   -- Teleport: Orgrimmar
    3562,   -- Teleport: Ironforge
    3563,   -- Teleport: Undercity
    3565,   -- Teleport: Darnassus
    3566,   -- Teleport: Thunder Bluff
    
    -- Прочие старые телепорты
    49359,  -- Teleport: Stonard (Horde)
    49358,  -- Teleport: Theramore (Alliance)
    33690,  -- Teleport: Silvermoon
    35715,  -- Teleport: Shattrath (Outland)
    53140,  -- Teleport: Dalaran (Northrend)
    88342,  -- Teleport: Tol Barad (Alliance)
    88344,  -- Teleport: Tol Barad (Horde)
}

-- Установка иконки пункту списка
local function setIcon(frame, data)
    if not frame.icon then
        frame.icon = CreateFrame("Frame", nil, frame)
        frame.icon:SetSize(32, 32)
        frame.icon:SetPoint("LEFT", 10, 0)
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
    else
        frame.icon.border:Hide()
    end

    if data.type == "item" or data.type == "spell" then
        frame.icon.texture:SetAllPoints()
        frame.icon.texture:SetTexture(data.texture)
        ApplyMaskToTexture(frame.icon.texture)
        frame.icon.border:Show()
        frame.icon.texture:Show()
    else
        frame.icon.texture:Hide()
    end
end

-- Создание ScrollBox
local function CreateFastTravelScrollBox()
    local FastTravelScrollBox = CreateFrame("Frame", "FastTravelScroll", UIParent)
    FastTravelScrollBox:SetSize(480, 48 * 4)
    FastTravelScrollBox:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 48, 48)

    -- Скрытие при начале боя или начале произнесения заклинания
    FastTravelScrollBox:RegisterEvent("PLAYER_REGEN_DISABLED") -- Начало боя
    FastTravelScrollBox:RegisterUnitEvent("UNIT_SPELLCAST_START", "player") -- Игрок начал каст

    FastTravelScrollBox:SetScript("OnEvent", function(_, event)
        if FastTravelScrollBox:IsShown() then
            FastTravelScrollBox:Hide()
        end
    end)

    local ScrollBox = CreateFrame("Frame", "FastTravelScrollBox", FastTravelScrollBox, "WowScrollBoxList")
    FastTravelScrollBox.ScrollBox = ScrollBox
    ScrollBox:SetPoint("TOPLEFT", FastTravelScrollBox, "TOPLEFT", 0, 0)
    ScrollBox:SetAllPoints()

    local ScrollBar = CreateFrame("EventFrame", "FastTravelScrollBar", FastTravelScrollBox, "MinimalScrollBar")
    FastTravelScrollBox.ScrollBox.ScrollBar = ScrollBar

    ScrollBar:SetPoint("TOPLEFT", ScrollBox, "TOPRIGHT")
    ScrollBar:SetPoint("BOTTOMLEFT", ScrollBox, "BOTTOMRIGHT")

    local DataProvider = CreateDataProvider()
    local ScrollView = CreateScrollBoxListLinearView()

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

            -- Прокрутить ScrollBox до текущего элемента
            parentFrame.ScrollBox:ScrollToElementDataIndex(newIndex)

            -- Устанавливаем бинд: при нажатии PAD1 будет использоваться предмет, 
            -- соответствующий текущему элементу (через SetOverrideBindingItem)
            local item = frames[focusedIndex]:GetData()

            if PAD1_COMMON_BINDING ~= nil then
                SetBinding("PAD1", nil) -- обязательно сначала удалить постоянную привязку!
            end

            if item.type == "item" then
                local bindString = "item:" .. item.id
                SetOverrideBindingItem(
                    parentFrame, -- владелец бинда
                    false, 
                    "PAD1", 
                    bindString
                )
            elseif item.type == "spell" then
                SetOverrideBindingSpell(
                    parentFrame, -- владелец бинда
                    false, 
                    "PAD1", 
                    item.name
                )
            end
        end
    end

    -- Обновление видимости скролл бара
    local function UpdateScrollBarVisibility()
        local totalHeight = ScrollView:GetExtent() - 1
        if totalHeight <= FastTravelScrollBox:GetHeight() then
            FastTravelScrollBar:Hide()
        else
            FastTravelScrollBar:Show()
        end
    end

    -- Инициализатор для элемента списка
    local function Initializer(frame, data)

        if not data then
            -- Если по какой-то причине data == nil, не вставляем во frames
            return
        end

        table.insert(frames, frame)

        local hearthstoneButton = CreateFrame("Button", nil, frame, "SecureActionButtonTemplate")
        frame.SecureActionButton = hearthstoneButton

        hearthstoneButton:SetAllPoints()
        hearthstoneButton:RegisterForClicks("AnyDown")

        -- Необходимо для клика мышкой
        --hearthstoneButton:SetAttribute("type1", data.type)
        --hearthstoneButton:SetAttribute("item1", data.name)

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
            frame.bg:SetAtlas("Garr_BuildingInfoShadow")
            frame.bg:Hide()
        end

        function frame:SetFocused(isFocused)
            if isFocused then
                frame.bg:Show()
            else
                frame.bg:Hide()
            end
        end

        -- Сохраняем данные, чтобы потом получить их через frame:GetData()
        frame.data = data
        function frame:GetData()
            return self.data
        end
    end

    -- Наполнение списка элементами
    local function SetItemList()
        DataProvider:Flush()
        frames = {}
    
        local itemInfo = 6948
        local itemName, _, _, _, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(itemInfo)
        DataProvider:Insert({
            id = itemInfo,
            type = "item",
            name = itemName,
            texture = itemTexture,
        })
    
        -- Проверяем, что игрок - маг
        local className, classFile = UnitClass("player")
        if classFile == "MAGE" then
    
            for _, spellID in ipairs(mageTeleports) do
                if IsSpellKnown(spellID) then
                    -- Получаем инфо о заклинании
                    local spellInfo = C_Spell.GetSpellInfo(spellID)
    
                    DataProvider:Insert({
                        id = spellInfo.spellID,
                        type = "spell",
                        name = spellInfo.name,
                        texture = spellInfo.iconID,
                    })
                end
            end
        end
    
        UpdateScrollBarVisibility()
    end

    ScrollView:SetElementExtent(48)
    ScrollView:SetElementInitializer("Button", Initializer, "SecureActionButtonTemplate")

    ScrollUtil.InitScrollBoxListWithScrollBar(ScrollBox, ScrollBar, ScrollView)
    ScrollBox:SetDataProvider(DataProvider)

    FastTravelScrollBox:Hide()

    return FastTravelScrollBox, UpdateFocus, SetItemList
end

-- Функция переключения фокуса
local function MoveFocus(delta)
    local newIndex = math.max(1, math.min(focusedIndex + delta, #frames))
    updateFocus(newIndex)
end

function ConsoleMenu:SetFastTravelFrame()
    -- Предзагрузка данных
    local itemsToPreload = {
        6948,    -- Hearthstone
    }

    for _, itemID in ipairs(itemsToPreload) do
        -- Создаём объект Item
        local itemObj = Item:CreateFromItemID(itemID)
        -- Запрашиваем загрузку данных
        itemObj:ContinueOnItemLoad(function()
           
        end)
    end

    for _, spellID in ipairs(mageTeleports) do
        C_Spell.RequestLoadSpellData(spellID)
    end

    parentFrame, updateFocus, setItemList = CreateFastTravelScrollBox()

    -- Создаём «невидимые» кнопки для перемещения фокуса и скрытия окна:
    local focusUpButton = CreateFrame("Button", "FocusUpButton", parentFrame)
    focusUpButton:SetSize(1,1)  -- крошечная, невидимая
    focusUpButton:SetPoint("TOPLEFT", parentFrame, "TOPLEFT")
    focusUpButton:SetScript("OnClick", function()
        MoveFocus(-1)
    end)

    local focusDownButton = CreateFrame("Button", "FocusDownButton", parentFrame)
    focusDownButton:SetSize(1,1)
    focusDownButton:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 20)
    focusDownButton:SetScript("OnClick", function()
        MoveFocus(1)
    end)

    local hideButton = CreateFrame("Button", "FastTravelHideButton", parentFrame)
    hideButton:SetSize(1,1)
    hideButton:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 40)
    hideButton:SetScript("OnClick", function()
        if PAD1_COMMON_BINDING ~= nil then
            SetBinding("PAD1", PAD1_COMMON_BINDING)
            SaveBindings(GetCurrentBindingSet())
        end
        parentFrame:Hide()
    end)

    -- Вешаем бинды, когда окно показывается:
    parentFrame:HookScript("OnShow", function()
        softTargetEnemy = GetCVar("SoftTargetEnemy")
        SetCVar("SoftTargetEnemy", 0)
        PAD1_COMMON_BINDING = GetBindingAction("PAD1")
        
        -- Привязываем PADDUP к клику по FocusUpButton
        SetOverrideBindingClick(focusUpButton, true, "PADDUP", "FocusUpButton", "LeftButton")
        -- Привязываем PADDDOWN к клику по FocusDownButton
        SetOverrideBindingClick(focusDownButton, true, "PADDDOWN", "FocusDownButton", "LeftButton")
        -- Привязываем PAD2 к клику по FastTravelHideButton (чтобы закрывать окно)
        SetOverrideBindingClick(hideButton, true, "PAD2", "FastTravelHideButton", "LeftButton")

        -- Устанавливаем фокус на первый элемент (по желанию)
        if updateFocus then
            updateFocus(1)
        end

        if WeakAuras then
            WeakAuras.ScanEvents("CHANGE_CONTEXT", "window")
            WeakAuras.ScanEvents("SHOW_FAST_TRAVEL_FRAME", true)
        end

    end)

    -- Очищаем бинды, когда окно скрывается:
    parentFrame:HookScript("OnHide", function()
        if softTargetEnemy then
            SetCVar("SoftTargetEnemy", softTargetEnemy)
        end
        
        ClearOverrideBindings(parentFrame)
        ClearOverrideBindings(focusUpButton)
        ClearOverrideBindings(focusDownButton)
        ClearOverrideBindings(hideButton)
        if PAD1_COMMON_BINDING ~= nil then
            SetBinding("PAD1", PAD1_COMMON_BINDING)
            SaveBindings(GetCurrentBindingSet())
        end

        if WeakAuras then
            WAGlobal = WAGlobal or {}  -- Создаем таблицу, если её ещё нет
            local previousContext = WAGlobal.previousContext or "exploring"
            WeakAuras.ScanEvents("CHANGE_CONTEXT", previousContext)
            WeakAuras.ScanEvents("SHOW_FAST_TRAVEL_FRAME", false)
        end

    end)
    
end

-- Слеш-команда
SLASH_FASTTRAVEL1 = "/fasttravel"
SlashCmdList["FASTTRAVEL"] = function()
    if parentFrame and parentFrame:IsShown() then
        print("FastTravel уже открыт.")
        return
    end

    if not parentFrame or not updateFocus then
        ConsoleMenu:SetFastTravelFrame()
    end

    if parentFrame then
        setItemList()
        parentFrame:Show()
    end
end
