-- Общие сведения окна торговца: вкладки, отложенное обновление и ссылка на список.

local ConsoleMenu = _G.ConsoleMenu

ConsoleMenu.Merchant = ConsoleMenu.Merchant or {}

local Merchant = ConsoleMenu.Merchant

Merchant.frameLeftOffset = 34
Merchant.tabFontSize = 22
Merchant.maxItemCost = 3
Merchant.maxTooltipDescriptionLines = 20
Merchant.merchantTabSlotCount = 3
Merchant.animationDuration = 0.1

Merchant.currenciesWidth = 304
Merchant.currenciesSectionHeight = 32
Merchant.currenciesMaxItems = 3
Merchant.currenciesIconInnerPadding = 8
Merchant.currenciesFontSize = 16

Merchant.focusedTabIndex = 1
Merchant.tabs = {}
Merchant.tabFocus = {}
Merchant.list = nil
Merchant.frame = nil
Merchant.currenciesData = {}

Merchant.merchantRefreshQueued = false
Merchant.merchantRefreshRebuildTabs = false
Merchant.tooltipRefreshQueued = false
Merchant.pendingOverrideBindings = false
Merchant.pendingClearOverrideBindings = false
Merchant.moneyEventsRegistered = false
Merchant.tooltipEventsRegistered = false
Merchant.pendingSellItemIDs = {}

-- Обычная строка товара, выкупа или предмета из сумки.
function Merchant.IsListItem(element)
    if not element then
        return false
    end
    return element.type == "merchantItem"
        or element.type == "buybackItem"
        or element.type == "bagItem"
end

-- Можно ли выбрать и раскрыть строку торговца.
function Merchant.IsSelectable(element)
    return Merchant.IsListItem(element) and element.slot ~= nil
end

-- Совпадают ли две строки по типу, ячейке и сумке.
function Merchant.AreElementsEqual(left, right)
    if not left or not right then
        return false
    end
    if left.type ~= right.type then
        return false
    end
    if left.type == "bagItem" then
        return left.slot == right.slot and left.bag == right.bag
    end
    return left.slot == right.slot
end

-- Совпадает ли строка с сохранённым выбором, включая сумку.
function Merchant.MatchesFocus(element, slot, itemType, bag)
    if not Merchant.IsListItem(element) or not slot then
        return false
    end
    if itemType and element.type ~= itemType then
        return false
    end
    if element.type == "bagItem" then
        return element.slot == slot and element.bag == bag
    end
    return element.slot == slot
end

-- Возвращает окно торговца, если оно уже создано.
function Merchant.GetFrame()
    return Merchant.frame or (ConsoleMenuFrame and ConsoleMenuFrame.ItemListFrame)
end

-- Возвращает раскрывающийся список торговца.
function Merchant.GetList()
    return Merchant.list
end
