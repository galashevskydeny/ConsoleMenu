-- Выбор строки раскрывающегося списка через открытые методы поставщика.

local ConsoleMenu = _G.ConsoleMenu
local ExpandableList = ConsoleMenu.ExpandableList

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

-- Текущая выбранная строка.
function ExpandableList.GetFocusedElement(list)
    if not list then
        return nil
    end
    return ExpandableList.GetElement(list, list.focusedIndex)
end

-- Совпадает ли строка с текущим выбором.
function ExpandableList.IsFocusedElement(list, element)
    if not list or not element or not ExpandableList.IsSelectable(element) then
        return false
    end
    if list.isSelectable and not list.isSelectable(element) then
        return false
    end
    local focused = ExpandableList.GetFocusedElement(list)
    if not focused then
        return false
    end
    if list.areElementsEqual then
        return list.areElementsEqual(focused, element)
    end
    return focused == element
end

-- Найти первую строку, для которой сравнение истинно.
function ExpandableList.FindElement(list, predicate)
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

    local index = list.scrollBox and list.scrollBox:FindElementDataIndex(element) or nil
    if not index then
        for candidateIndex = 1, size do
            if ExpandableList.GetElement(list, candidateIndex) == element then
                index = candidateIndex
                break
            end
        end
    end
    if not index then
        return neighbors
    end

    local function IsNeighbor(candidate)
        if not candidate then
            return false
        end
        if list.isSelectable then
            return list.isSelectable(candidate)
        end
        return ExpandableList.IsSelectable(candidate)
    end

    for previousIndex = index - 1, 1, -1 do
        local previous = ExpandableList.GetElement(list, previousIndex)
        if IsNeighbor(previous) then
            table.insert(neighbors, previous)
            break
        end
    end

    for nextIndex = index + 1, size do
        local nextElement = ExpandableList.GetElement(list, nextIndex)
        if IsNeighbor(nextElement) then
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

    local function IsNeighbor(candidate)
        if not candidate then
            return false
        end
        if list.isSelectable then
            return list.isSelectable(candidate)
        end
        return ExpandableList.IsSelectable(candidate)
    end

    for index = fromIndex, size do
        local element = ExpandableList.GetElement(list, index)
        if IsNeighbor(element) then
            return element
        end
    end

    for index = fromIndex - 1, 1, -1 do
        local element = ExpandableList.GetElement(list, index)
        if IsNeighbor(element) then
            return element
        end
    end

    return nil
end

-- Обновить выбор и при необходимости прокрутить к строке.
function ExpandableList.UpdateFocus(list, element, changeFocus)
    if not list or not element or not list.scrollBox then
        return
    end

    local previousExtent = list.focusedExtent
    local previousElement = ExpandableList.GetFocusedElement(list)
    local layoutChanged = false

    local focusedIndex = list.scrollBox:FindElementDataIndex(element)
    if not focusedIndex then
        return
    end

    local sameElement = previousElement == element
    if list.areElementsEqual and previousElement then
        sameElement = list.areElementsEqual(previousElement, element)
    end
    if not sameElement then
        list.focusedExtent = ExpandableList.sectionHeight
    end

    list.focusedIndex = focusedIndex

    if changeFocus then
        list.scrollBox:ScrollToElementDataIndex(list.focusedIndex)
    end

    for _, rowFrame in ipairs(list.scrollBox:GetFrames()) do
        if rowFrame.SetFocused then
            layoutChanged = rowFrame:SetFocused(false) or layoutChanged
        end
    end

    local focusedFrame = list.scrollBox:FindFrameByPredicate(function(_, elementData)
        return elementData == element
    end)

    if focusedFrame and focusedFrame.SetFocused then
        layoutChanged = focusedFrame:SetFocused(true) or layoutChanged
    end

    if (layoutChanged or list.focusedExtent ~= previousExtent) and list.UpdateScrollBar then
        list:UpdateScrollBar()
    end

    if list.onFocusChanged then
        list.onFocusChanged(element)
    end
end

-- Сместить выбор на соседнюю обычную строку, замыкая список в кольцо.
function ExpandableList.MoveFocus(list, delta)
    local size = ExpandableList.GetSize(list)
    if size <= 0 then
        return
    end

    local newIndex = list.focusedIndex or 1
    for _ = 1, size do
        newIndex = newIndex + delta
        if newIndex < 1 then
            newIndex = size
        elseif newIndex > size then
            newIndex = 1
        end

        local candidate = ExpandableList.GetElement(list, newIndex)
        local selectable = candidate and ExpandableList.IsSelectable(candidate)
        if list.isSelectable then
            selectable = candidate and list.isSelectable(candidate)
        end
        if selectable then
            ExpandableList.UpdateFocus(list, candidate, true)
            return candidate
        end
    end

    return nil
end

-- Поставить выбор на первую обычную строку.
function ExpandableList.FocusFirst(list)
    local first = ExpandableList.FindNearestSelectable(list, 1)
    if first then
        ExpandableList.UpdateFocus(list, first, true)
        return first
    end

    list.focusedIndex = 1
    list.focusedExtent = ExpandableList.sectionHeight
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
        ExpandableList.UpdateFocus(list, restored, true)
        return restored
    end
    return ExpandableList.FocusFirst(list)
end

-- Перерисовать выбранную строку без смены номера.
function ExpandableList.RefreshFocused(list)
    local element = ExpandableList.GetFocusedElement(list)
    if not element then
        return
    end
    ExpandableList.UpdateFocus(list, element, false)
end
