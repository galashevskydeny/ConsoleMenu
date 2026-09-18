-- Выбор строки раскрывающегося списка через открытые методы поставщика.

local ConsoleMenu = _G.ConsoleMenu
local ExpandableList = ConsoleMenu.ExpandableList

-- Выравнивание прокрутки к ближайшему краю видимой области.
local function GetAlignNearest()
    if ScrollBoxConstants and ScrollBoxConstants.AlignNearest then
        return ScrollBoxConstants.AlignNearest
    end
    return -1
end

-- Выравнивание прокрутки к верхнему краю видимой области.
local function GetAlignBegin()
    if ScrollBoxConstants and ScrollBoxConstants.AlignBegin then
        return ScrollBoxConstants.AlignBegin
    end
    return 0
end

-- Прокрутка без плавного смещения, чтобы рамка строки появилась сразу.
local function GetNoInterpolation()
    if ScrollBoxConstants and ScrollBoxConstants.NoScrollInterpolation then
        return ScrollBoxConstants.NoScrollInterpolation
    end
    return true
end

-- Сбросить номер и высоту выбора, пока строка не назначена.
function ExpandableList.ResetFocusState(list)
    if not list then
        return
    end
    list.focusedIndex = nil
    list.focusedExtent = ExpandableList.sectionHeight
    list.focusFrameRetryQueued = nil
end

-- Строка по номеру через открытый метод поставщика.
function ExpandableList.GetElement(list, index)
    if not list or not list.dataProvider or not index then
        return nil
    end
    return list.dataProvider:Find(index)
end

-- Число строк через открытый метод поставщика.
function ExpandableList.GetSize(list)
    if not list or not list.dataProvider then
        return 0
    end
    return list.dataProvider:GetSize()
end

-- Номер строки в поставщике с учётом сравнения потребителя.
function ExpandableList.FindElementIndex(list, element)
    if not list or not element then
        return nil
    end

    if list.areElementsEqual then
        local size = ExpandableList.GetSize(list)
        for index = 1, size do
            local candidate = ExpandableList.GetElement(list, index)
            if candidate and list.areElementsEqual(candidate, element) then
                return index, candidate
            end
        end
        return nil
    end

    if list.dataProvider and list.dataProvider.FindIndex then
        local index, found = list.dataProvider:FindIndex(element)
        return index, found or element
    end

    return nil
end

-- Текущая выбранная строка.
function ExpandableList.GetFocusedElement(list)
    if not list then
        return nil
    end
    return ExpandableList.GetElement(list, list.focusedIndex)
end

-- Совпадает ли строка с текущим выбором.
function ExpandableList.IsFocusedElement(list, element)
    if not list or not ExpandableList.CanSelect(list, element) then
        return false
    end
    local focused = ExpandableList.GetFocusedElement(list)
    if not focused then
        return false
    end
    return ExpandableList.AreEqual(list, focused, element)
end

-- Найти первую строку, для которой сравнение истинно.
function ExpandableList.FindElement(list, predicate)
    if not list or not predicate then
        return nil
    end

    if list.dataProvider and list.dataProvider.FindByPredicate then
        local index, element = list.dataProvider:FindByPredicate(predicate)
        if element then
            return element, index
        end
        return nil
    end

    local size = ExpandableList.GetSize(list)
    for index = 1, size do
        local element = ExpandableList.GetElement(list, index)
        if element and predicate(element) then
            return element, index
        end
    end
    return nil
end

-- Соседи выбранной строки, минуя разделители.
function ExpandableList.GetNeighbors(list, element)
    local neighbors = {}
    local size = ExpandableList.GetSize(list)
    if size <= 0 or not element then
        return neighbors
    end

    local index = ExpandableList.FindElementIndex(list, element)
    if not index then
        return neighbors
    end

    for previousIndex = index - 1, 1, -1 do
        local previous = ExpandableList.GetElement(list, previousIndex)
        if ExpandableList.CanSelect(list, previous) then
            table.insert(neighbors, previous)
            break
        end
    end

    for nextIndex = index + 1, size do
        local nextElement = ExpandableList.GetElement(list, nextIndex)
        if ExpandableList.CanSelect(list, nextElement) then
            table.insert(neighbors, nextElement)
            break
        end
    end

    return neighbors
end

-- Ближайшая обычная строка начиная с сохранённого номера.
function ExpandableList.FindNearestSelectable(list, startIndex)
    local size = ExpandableList.GetSize(list)
    if size <= 0 then
        return nil
    end

    local fromIndex = startIndex or 1
    if fromIndex < 1 then
        fromIndex = 1
    elseif fromIndex > size then
        fromIndex = size
    end

    for index = fromIndex, size do
        local element = ExpandableList.GetElement(list, index)
        if ExpandableList.CanSelect(list, element) then
            return element, index
        end
    end

    for index = fromIndex - 1, 1, -1 do
        local element = ExpandableList.GetElement(list, index)
        if ExpandableList.CanSelect(list, element) then
            return element, index
        end
    end

    return nil
end

-- Прокрутить к номеру строки без плавного смещения.
-- Если над выбранной строкой есть подпись группы, сначала показываем её.
local function ScrollToIndex(list, index)
    if not list or not list.scrollBox or not index then
        return
    end

    local noInterpolation = GetNoInterpolation()
    local previous = ExpandableList.GetElement(list, index - 1)
    if ExpandableList.IsSeparator(previous) then
        list.scrollBox:ScrollToElementDataIndex(index - 1, GetAlignBegin(), 0, noInterpolation)
        list.scrollBox:ScrollToElementDataIndex(index, GetAlignNearest(), 0, noInterpolation)
        return
    end

    list.scrollBox:ScrollToElementDataIndex(index, GetAlignNearest(), 0, noInterpolation)
end

-- Вернуть выбранную строку и подпись группы в видимую область после смены высоты.
function ExpandableList.ScrollFocusedIntoView(list)
    if not list or not list.focusedIndex then
        return
    end
    ScrollToIndex(list, list.focusedIndex)
end

-- Найти видимую рамку строки с учётом сравнения потребителя.
local function FindVisibleFrame(list, element)
    if not list or not list.scrollBox or not element then
        return nil
    end
    return list.scrollBox:FindFrameByPredicate(function(_, elementData)
        return ExpandableList.AreEqual(list, elementData, element)
    end)
end

-- Свернуть остальные обычные строки и раскрыть выбранную, не трогая разделители.
local function ApplyFocusToVisibleFrames(list, element)
    local layoutChanged = false
    if not list.scrollBox then
        return layoutChanged, nil
    end

    local frames = list.scrollBox.GetFrames and list.scrollBox:GetFrames() or {}
    local focusedFrame = nil
    for _, rowFrame in ipairs(frames) do
        local data = rowFrame.listData
        if not data and rowFrame.GetElementData then
            data = rowFrame:GetElementData()
        end
        if data and ExpandableList.AreEqual(list, data, element) then
            focusedFrame = rowFrame
        elseif rowFrame.SetFocused and data and ExpandableList.CanSelect(list, data) then
            layoutChanged = rowFrame:SetFocused(false) or layoutChanged
        end
    end

    if focusedFrame then
        if not focusedFrame.SetFocused then
            ExpandableList.InitializeRow(focusedFrame, element, list)
            layoutChanged = true
        else
            layoutChanged = focusedFrame:SetFocused(true) or layoutChanged
        end
    end

    return layoutChanged, focusedFrame
end

-- Пересчитать протяжённость списка после смены высоты выбранной строки.
local function RefreshVisibleLayout(list, changeFocus, focusedIndex)
    if list.UpdateScrollBar then
        list:UpdateScrollBar()
    end
    if changeFocus then
        ScrollToIndex(list, focusedIndex)
    end
end

-- Сообщить потребителю о смене выбора.
local function NotifyFocusChanged(list, element, skipNotify)
    if skipNotify or not list.onFocusChanged then
        return
    end
    list.onFocusChanged(element)
end

-- Обновить выбор и при необходимости прокрутить к строке.
function ExpandableList.UpdateFocus(list, element, changeFocus, skipNotify, isRetry)
    if not list or not element or not list.scrollBox then
        return nil
    end

    local focusedIndex, currentElement = ExpandableList.FindElementIndex(list, element)
    if not focusedIndex then
        return nil
    end
    element = currentElement or element

    local previousExtent = list.focusedExtent
    local previousElement = ExpandableList.GetFocusedElement(list)
    if not ExpandableList.AreEqual(list, previousElement, element) then
        list.focusedExtent = ExpandableList.sectionHeight
    end

    list.focusedIndex = focusedIndex

    local focusedFrame = FindVisibleFrame(list, element)
    if changeFocus or not focusedFrame then
        ScrollToIndex(list, focusedIndex)
    end

    local layoutChanged
    layoutChanged, focusedFrame = ApplyFocusToVisibleFrames(list, element)
    if not focusedFrame then
        ScrollToIndex(list, focusedIndex)
        if list.UpdateScrollBar then
            list:UpdateScrollBar()
        end
        layoutChanged, focusedFrame = ApplyFocusToVisibleFrames(list, element)
    end
    if not focusedFrame then
        if not isRetry and not list.focusFrameRetryQueued then
            list.focusFrameRetryQueued = true
            C_Timer.After(0, function()
                list.focusFrameRetryQueued = nil
                local current = ExpandableList.GetFocusedElement(list)
                if not current or not ExpandableList.AreEqual(list, current, element) then
                    return
                end
                local restored = ExpandableList.UpdateFocus(list, current, true, skipNotify, true)
                if not restored then
                    NotifyFocusChanged(list, element, skipNotify)
                end
            end)
        elseif isRetry then
            NotifyFocusChanged(list, element, skipNotify)
        end
        return nil
    end

    if layoutChanged or list.focusedExtent ~= previousExtent then
        RefreshVisibleLayout(list, changeFocus, focusedIndex)
    end

    NotifyFocusChanged(list, element, skipNotify)
    return element
end

-- Сместить выбор на соседнюю обычную строку, замыкая список в кольцо.
function ExpandableList.MoveFocus(list, delta)
    local size = ExpandableList.GetSize(list)
    if size <= 0 then
        return nil
    end

    if not list.focusedIndex then
        if delta < 0 then
            local last = ExpandableList.FindNearestSelectable(list, size)
            if last then
                return ExpandableList.UpdateFocus(list, last, true)
            end
            return nil
        end
        return ExpandableList.FocusFirst(list)
    end

    local newIndex = list.focusedIndex
    for _ = 1, size do
        newIndex = newIndex + delta
        if newIndex < 1 then
            newIndex = size
        elseif newIndex > size then
            newIndex = 1
        end

        local candidate = ExpandableList.GetElement(list, newIndex)
        if ExpandableList.CanSelect(list, candidate) then
            return ExpandableList.UpdateFocus(list, candidate, true)
        end
    end

    return nil
end

-- Поставить выбор на первую обычную строку.
function ExpandableList.FocusFirst(list)
    local first = ExpandableList.FindNearestSelectable(list, 1)
    if first then
        return ExpandableList.UpdateFocus(list, first, true)
    end

    ExpandableList.ResetFocusState(list)
    if list.onFocusChanged then
        list.onFocusChanged(nil)
    end
    if list.UpdateScrollBar then
        list:UpdateScrollBar()
    end
    return nil
end

-- Восстановить выбор по сравнению или взять ближайшую обычную строку.
function ExpandableList.RestoreFocus(list, predicate, startIndex)
    local restored = nil
    if predicate then
        restored = ExpandableList.FindElement(list, predicate)
    end
    if not restored then
        restored = ExpandableList.FindNearestSelectable(list, startIndex or list.focusedIndex)
    end
    if restored then
        return ExpandableList.UpdateFocus(list, restored, true)
    end
    return ExpandableList.FocusFirst(list)
end

-- Перерисовать выбранную строку на месте, без принудительной прокрутки.
function ExpandableList.RefreshFocused(list)
    local element = ExpandableList.GetFocusedElement(list)
    if not element then
        return
    end
    return ExpandableList.UpdateFocus(list, element, false, true)
end
