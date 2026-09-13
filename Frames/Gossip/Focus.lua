-- Фокус и навигация по списку пунктов диалога.

local ConsoleMenu = _G.ConsoleMenu
local Gossip = ConsoleMenu.Gossip

-- Элемент списка по индексу через открытый метод поставщика.
function Gossip.GetListElement(index)
    local parentFrame = Gossip.parentFrame
    if not parentFrame or not parentFrame.ScrollBox then
        return nil
    end
    local dataProvider = parentFrame.ScrollBox:GetDataProvider()
    if not dataProvider then
        return nil
    end
    return dataProvider:Find(index)
end

-- Размер списка через открытый метод поставщика.
function Gossip.GetListSize()
    local parentFrame = Gossip.parentFrame
    if not parentFrame or not parentFrame.ScrollBox then
        return 0
    end
    local dataProvider = parentFrame.ScrollBox:GetDataProvider()
    if not dataProvider then
        return 0
    end
    return dataProvider:GetSize()
end

-- Обновление фокуса.
function Gossip.UpdateFocus(element, changeFocus)
    if not element then
        return
    end
    local parentFrame = Gossip.parentFrame
    if not parentFrame or not parentFrame.ScrollBox then
        return
    end

    local frames = parentFrame.ScrollBox:GetFrames()
    for _, frame in ipairs(frames) do
        if frame.SetFocused then
            frame:SetFocused(false)
        end
    end

    Gossip.focusedIndex = parentFrame.ScrollBox:FindElementDataIndex(element)
    if not Gossip.focusedIndex then
        return
    end

    -- Сначала прокручиваем к элементу: его строка может быть ещё не создана.
    if changeFocus then
        parentFrame.ScrollBox:ScrollToElementDataIndex(Gossip.focusedIndex)
    end

    local frame = parentFrame.ScrollBox:FindFrameByPredicate(function(frame, elementData)
        return elementData == element
    end)

    if frame and changeFocus then
        frame:SetFocused(true)
    end
end

-- Переключение фокуса на соседний пункт.
function Gossip.MoveFocus(delta)
    local dataProviderSize = Gossip.GetListSize()
    if dataProviderSize <= 0 then
        return
    end
    local newIndex = math.max(1, math.min(Gossip.focusedIndex + delta, dataProviderSize))
    local element = Gossip.GetListElement(newIndex)
    if element then
        Gossip.UpdateFocus(element, true)
    end
end

-- Установка фокуса на первый пункт списка.
function Gossip.FocusFirstElement()
    local element = Gossip.GetListElement(1)
    if element then
        Gossip.UpdateFocus(element, true)
    end
end
