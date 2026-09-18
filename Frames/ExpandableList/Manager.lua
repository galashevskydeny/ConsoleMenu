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

-- Назначить расчёт высоты, создание строки и сброс повторно используемой рамки.
local function BindScrollView(list)
    local scrollView = list.scrollView
    if not scrollView then
        return
    end

    if scrollView.SetElementExtentCalculator then
        scrollView:SetElementExtentCalculator(function(_, elementData)
            if ExpandableList.IsFocusedElement(list, elementData) then
                return math.max(ExpandableList.sectionHeight, list.focusedExtent or ExpandableList.sectionHeight)
            end
            return ExpandableList.sectionHeight
        end)
    elseif scrollView.SetElementExtent then
        scrollView:SetElementExtent(ExpandableList.sectionHeight)
    end

    scrollView:SetElementInitializer("Frame", function(frame, data)
        ExpandableList.InitializeRow(frame, data, list)
    end)

    if scrollView.SetElementResetter then
        scrollView:SetElementResetter(function(frame)
            ExpandableList.ResetReleasedRow(frame)
        end)
    end

    if scrollView.SetPanExtent then
        scrollView:SetPanExtent(ExpandableList.sectionHeight)
    elseif list.scrollBox and list.scrollBox.SetPanExtent then
        list.scrollBox:SetPanExtent(ExpandableList.sectionHeight)
    end
end

-- Создать блок пустого списка.
local function CreateEmptyList(parent, namePrefix, list)
    local emptyList = CreateFrame("Frame", namePrefix and (namePrefix .. "EmptyList") or nil, parent)
    emptyList:SetPoint("TOPLEFT", parent, "TOPLEFT", list.contentPadding, 0)
    emptyList:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -list.contentPadding, 0)
    emptyList:SetHeight(160)
    emptyList:Hide()

    local title = emptyList:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    emptyList.Text = title
    title:SetPoint("TOPLEFT", emptyList, "TOPLEFT", 0, 0)
    title:SetPoint("TOPRIGHT", emptyList, "TOPRIGHT", 0, 0)
    title:SetJustifyH("LEFT")
    title:SetNonSpaceWrap(true)
    title:SetWordWrap(true)
    ExpandableList.ApplyTitleFont(title, ExpandableList.emptyListFontSize, "OUTLINE")
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
    description:SetPoint("TOPRIGHT", emptyList.Text, "BOTTOMRIGHT", 0, -24)
    description:SetJustifyH("LEFT")
    description:SetNonSpaceWrap(true)
    description:SetWordWrap(true)
    ExpandableList.ApplyBodyFont(description, ExpandableList.emptyListDescriptionFontSize, "OUTLINE")
    description:SetTextColor(
        ExpandableList.separatorColorR,
        ExpandableList.separatorColorG,
        ExpandableList.separatorColorB,
        ExpandableList.separatorColorA
    )
    description:SetText("")

    return emptyList
end

-- Скрыть встроенные тени шаблона области прокрутки.
local function HideScrollBoxShadows(scrollBox)
    if not scrollBox then
        return
    end
    if scrollBox.Shadows then
        scrollBox.Shadows:Hide()
        return
    end
    if scrollBox.SetShadowsShown then
        scrollBox:SetShadowsShown(false, false)
    end
end

-- Перепривязать дорожку полосы, потому что стрелки скрыты.
local function RelayoutScrollBarTrack(scrollBar)
    if not scrollBar then
        return
    end
    if scrollBar.Forward then
        scrollBar.Forward:Hide()
    end
    if scrollBar.Back then
        scrollBar.Back:Hide()
    end
    if scrollBar.Track then
        scrollBar.Track:ClearAllPoints()
        scrollBar.Track:SetPoint("TOPLEFT")
        scrollBar.Track:SetPoint("BOTTOMRIGHT")
    end
end

-- Привязать область прокрутки и полосу к текущим отступам списка.
local function ApplyScrollAreaLayout(list)
    local items = list.items
    local scrollBox = list.scrollBox
    if not items or not scrollBox then
        return
    end

    scrollBox:ClearAllPoints()
    scrollBox:SetPoint("TOPLEFT", items, "TOPLEFT", list.contentPadding, 0)
    scrollBox:SetPoint("BOTTOMRIGHT", items, "BOTTOMRIGHT", 0, list.bottomPadding)
    HideScrollBoxShadows(scrollBox)

    local scrollBar = list.scrollBar
    if not scrollBar then
        return
    end
    scrollBar:ClearAllPoints()
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPLEFT", -list.contentPadding, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMLEFT", 0, 0)
    RelayoutScrollBarTrack(scrollBar)
end

-- Создать прокручиваемую область списка.
local function CreateScrollArea(parent, namePrefix, list)
    local items = CreateFrame("Frame", namePrefix and (namePrefix .. "Items") or nil, parent)
    items:SetAllPoints(parent)

    local scrollBox = CreateFrame("Frame", namePrefix and (namePrefix .. "ScrollBox") or nil, items, "WowScrollBoxList")
    local scrollBar = CreateFrame("EventFrame", namePrefix and (namePrefix .. "ScrollBar") or nil, items, "MinimalScrollBar")
    scrollBar:SetAlpha(0.4)

    local scrollView = CreateScrollBoxListLinearView()
    local dataProvider = CreateDataProvider()

    list.items = items
    list.scrollBox = scrollBox
    list.scrollBar = scrollBar
    list.scrollView = scrollView
    list.dataProvider = dataProvider

    ApplyScrollAreaLayout(list)
    BindScrollView(list)
    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)
    scrollBox:SetDataProvider(dataProvider)

    if scrollView.SetPanExtent then
        scrollView:SetPanExtent(ExpandableList.sectionHeight)
    elseif scrollBox.SetPanExtent then
        scrollBox:SetPanExtent(ExpandableList.sectionHeight)
    end

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
        bottomPadding = options.bottomPadding or 0,
        focusedIndex = nil,
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
        list.dataProvider = list.scrollBox.GetDataProvider and list.scrollBox:GetDataProvider() or nil
        ApplyScrollAreaLayout(list)
        BindScrollView(list)
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
        ExpandableList.ResetFocusState(self)
        if not self.scrollBox or not self.scrollBox.SetDataProvider then
            return
        end
        local dataProvider = CreateDataProvider(elements)
        self.dataProvider = dataProvider
        self.scrollBox:SetDataProvider(dataProvider)
        self:UpdateScrollBarShown()
    end

    -- Очистить список.
    function list:Clear()
        self:SetElements(nil)
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
            if self.items then
                self.items:Hide()
            end
        else
            emptyList:Hide()
            if self.items then
                self.items:Show()
            end
        end
        ReanchorBackground(self, not isShown)
        self:UpdateScrollBarShown()
    end

    -- Показать или скрыть полосу по диапазону прокрутки.
    function list:UpdateScrollBarShown()
        if not self.scrollBar then
            return
        end
        local scrollRange = self.scrollBox and self.scrollBox:GetDerivedScrollRange() or 0
        if scrollRange > 0 and (not self.items or self.items:IsShown()) then
            self.scrollBar:Show()
        else
            self.scrollBar:Hide()
        end
    end

    -- Пересчитать полосу прокрутки.
    function list:UpdateScrollBar()
        RefreshScrollLayout(self)
        self:UpdateScrollBarShown()
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

    ReanchorBackground(list, true)
    return list
end
