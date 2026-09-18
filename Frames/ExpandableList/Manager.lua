-- Создание раскрывающегося списка на родителе: прокрутка, пустое состояние и фон.

local ConsoleMenu = _G.ConsoleMenu
local ExpandableList = ConsoleMenu.ExpandableList

-- Привязать фон к списку или к пустому блоку.
local function ReanchorBackground(list, hasItems)
    local parent = list.parent
    if not parent or not parent.Background or not parent.AdditionalShadow then
        return
    end

    local anchorFrame = parent
    if hasItems then
        anchorFrame = list.items or parent
    else
        anchorFrame = list.emptyList or parent
    end

    local horizontal = ExpandableList.backgroundHOffset
    local vertical = ExpandableList.backgroundVOffset

    parent.Background:ClearAllPoints()
    parent.Background:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", -horizontal * 1.5, vertical)
    parent.Background:SetPoint("TOPRIGHT", anchorFrame, "TOPRIGHT", horizontal, vertical)
    parent.Background:SetPoint("BOTTOMLEFT", anchorFrame, "BOTTOMLEFT", -horizontal * 1.5, -vertical)
    parent.Background:SetPoint("BOTTOMRIGHT", anchorFrame, "BOTTOMRIGHT", horizontal, -vertical)

    parent.AdditionalShadow:ClearAllPoints()
    parent.AdditionalShadow:SetPoint("TOP", anchorFrame, "TOP", 0, vertical * 1.2)
    parent.AdditionalShadow:SetPoint("BOTTOM", anchorFrame, "BOTTOM", 0, -vertical * 1.2)
    parent.AdditionalShadow:SetPoint("RIGHT", anchorFrame, "CENTER", horizontal / 2, 0)
end

-- Обновить видимость полосы прокрутки.
local function RefreshScrollLayout(list)
    local scrollBox = list.scrollBox
    if not scrollBox then
        return
    end

    if scrollBox.FullUpdate then
        if ScrollBoxConstants and ScrollBoxConstants.UpdateImmediately then
            scrollBox:FullUpdate(ScrollBoxConstants.UpdateImmediately)
        else
            scrollBox:FullUpdate()
        end
    elseif scrollBox.Update then
        scrollBox:Update()
    end
end

-- Создать блок пустого списка.
local function CreateEmptyList(parent, namePrefix, list)
    local emptyList = CreateFrame("Frame", namePrefix and (namePrefix .. "EmptyList") or nil, parent)
    emptyList:SetPoint("TOPLEFT", parent, "TOPLEFT", list.contentPadding, 0)
    emptyList:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 128, 0)
    emptyList:SetHeight(160)

    local title = emptyList:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    emptyList.Text = title
    title:SetPoint("TOPLEFT", emptyList, "TOPLEFT", 0, 0)
    title:SetWidth(list.frameWidth)
    title:SetJustifyH("LEFT")
    title:SetNonSpaceWrap(true)
    title:SetFont(ExpandableList.emptyTitleFontName, ExpandableList.emptyListFontSize, "OUTLINE")
    title:SetTextColor(
        ExpandableList.titleColorR,
        ExpandableList.titleColorG,
        ExpandableList.titleColorB,
        1
    )
    title:SetText("")

    local description = emptyList:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    emptyList.Description = description
    description:SetPoint("TOPLEFT", emptyList.Text, "BOTTOMLEFT", 0, -24)
    description:SetWidth(list.frameWidth)
    description:SetJustifyH("LEFT")
    description:SetNonSpaceWrap(true)
    description:SetFont(ExpandableList.fontName, ExpandableList.emptyListDescriptionFontSize, "OUTLINE")
    description:SetTextColor(
        ExpandableList.separatorColorR,
        ExpandableList.separatorColorG,
        ExpandableList.separatorColorB,
        ExpandableList.separatorColorA
    )
    description:SetText("")

    return emptyList
end

-- Создать прокручиваемую область списка.
local function CreateScrollArea(parent, namePrefix, list)
    local items = CreateFrame("Frame", namePrefix and (namePrefix .. "Items") or nil, parent)
    items:SetAllPoints(parent)

    local scrollBox = CreateFrame("Frame", namePrefix and (namePrefix .. "ScrollBox") or nil, items, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", items, "TOPLEFT", list.contentPadding, 0)
    scrollBox:SetPoint("BOTTOMRIGHT", items, "BOTTOMRIGHT", 0, ExpandableList.sectionHeight)

    local scrollBar = CreateFrame("EventFrame", namePrefix and (namePrefix .. "ScrollBar") or nil, items, "MinimalScrollBar")
    scrollBar:SetAlpha(0.4)
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPLEFT", -list.contentPadding, -24)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMLEFT", 0, 24)
    scrollBar.Forward:Hide()
    scrollBar.Back:Hide()

    local scrollView = CreateScrollBoxListLinearView()
    local dataProvider = CreateDataProvider()

    if scrollView.SetElementExtentCalculator then
        scrollView:SetElementExtentCalculator(function(index, elementData)
            local data = elementData
            if type(data) ~= "table" and type(index) == "table" then
                data = index
            end
            if ExpandableList.IsFocusedElement(list, data) then
                return math.max(ExpandableList.sectionHeight, list.focusedExtent or ExpandableList.sectionHeight)
            end
            return ExpandableList.sectionHeight
        end)
    else
        scrollView:SetElementExtent(ExpandableList.sectionHeight)
    end

    scrollView:SetElementInitializer("Button", function(frame, data)
        ExpandableList.InitializeRow(frame, data, list)
    end)

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)
    scrollBox:SetDataProvider(dataProvider)

    return items, scrollBox, scrollBar, scrollView, dataProvider
end

-- Создать раскрывающийся список на родителе.
function ExpandableList.Create(parent, options)
    options = options or {}
    if not parent then
        return nil
    end

    local list = {
        parent = parent,
        frameWidth = options.frameWidth or ExpandableList.frameWidth,
        contentPadding = options.contentPadding or ExpandableList.contentPadding,
        focusedIndex = 1,
        focusedExtent = ExpandableList.sectionHeight,
        isSelectable = options.isSelectable,
        onExpand = options.onExpand,
        onDecorateIcon = options.onDecorateIcon,
        onFocusChanged = options.onFocusChanged,
        areElementsEqual = options.areElementsEqual,
    }

    local namePrefix = options.namePrefix
    list.emptyList = parent.EmptyList or CreateEmptyList(parent, namePrefix, list)
    parent.EmptyList = list.emptyList

    if parent.Items and parent.Items.ScrollBox then
        list.items = parent.Items
        list.scrollBox = parent.Items.ScrollBox
        list.scrollBar = parent.Items.ScrollBar
        list.scrollView = parent.Items.ScrollView
        list.dataProvider = list.scrollBox:GetDataProvider()
    else
        local items, scrollBox, scrollBar, scrollView, dataProvider = CreateScrollArea(parent, namePrefix, list)
        list.items = items
        list.scrollBox = scrollBox
        list.scrollBar = scrollBar
        list.scrollView = scrollView
        list.dataProvider = dataProvider
        parent.Items = items
        items.ScrollBox = scrollBox
        items.ScrollBar = scrollBar
        items.ScrollView = scrollView
    end

    -- Заменить содержимое списка новым набором строк.
    function list:SetElements(elements)
        if not self.dataProvider then
            return
        end
        self.dataProvider:Flush()
        if not elements then
            return
        end
        for index = 1, #elements do
            self.dataProvider:Insert(elements[index])
        end
    end

    -- Очистить список.
    function list:Clear()
        if self.dataProvider then
            self.dataProvider:Flush()
        end
        self.focusedIndex = 1
        self.focusedExtent = ExpandableList.sectionHeight
    end

    -- Показать или скрыть пустой блок с заголовком и подписью.
    function list:SetEmpty(title, description, isShown)
        local emptyList = self.emptyList
        if not emptyList then
            return
        end
        if emptyList.Text then
            emptyList.Text:SetText(title or "")
        end
        if emptyList.Description then
            emptyList.Description:SetText(description or "")
        end
        if isShown then
            emptyList:Show()
        else
            emptyList:Hide()
        end
        ReanchorBackground(self, not isShown)
    end

    -- Пересчитать полосу прокрутки.
    function list:UpdateScrollBar()
        RefreshScrollLayout(self)
        if not self.scrollBar then
            return
        end
        local scrollRange = self.scrollBox and self.scrollBox:GetDerivedScrollRange() or 0
        if scrollRange > 0 then
            self.scrollBar:Show()
        else
            self.scrollBar:Hide()
        end
    end

    -- Привязать фон к текущему содержимому.
    function list:ReanchorBackground(hasItems)
        ReanchorBackground(self, hasItems)
    end

    function list:GetElement(index)
        return ExpandableList.GetElement(self, index)
    end

    function list:GetSize()
        return ExpandableList.GetSize(self)
    end

    function list:GetFocusedElement()
        return ExpandableList.GetFocusedElement(self)
    end

    function list:IsFocusedElement(element)
        return ExpandableList.IsFocusedElement(self, element)
    end

    function list:FindElement(predicate)
        return ExpandableList.FindElement(self, predicate)
    end

    function list:GetNeighbors(element)
        return ExpandableList.GetNeighbors(self, element)
    end

    function list:UpdateFocus(element, changeFocus)
        return ExpandableList.UpdateFocus(self, element, changeFocus)
    end

    function list:MoveFocus(delta)
        return ExpandableList.MoveFocus(self, delta)
    end

    function list:FocusFirst()
        return ExpandableList.FocusFirst(self)
    end

    function list:RestoreFocus(predicate, startIndex)
        return ExpandableList.RestoreFocus(self, predicate, startIndex)
    end

    function list:RefreshFocused()
        return ExpandableList.RefreshFocused(self)
    end

    ReanchorBackground(list, false)
    return list
end
