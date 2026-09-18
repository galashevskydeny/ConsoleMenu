-- Покупка, продажа, ремонт и подписи кнопок окна торговца.

local ConsoleMenu = _G.ConsoleMenu
local Merchant = ConsoleMenu.Merchant

-- Нужно ли чинить снаряжение у этого торговца.
function Merchant.NeedsEquipmentRepair()
    if not CanMerchantRepair() then
        return false
    end

    local repairCost, canRepair = GetRepairAllCost()
    if canRepair then
        return true
    end

    return repairCost and repairCost > 0
end

-- Можно ли продать весь хлам у этого торговца.
function Merchant.CanSellAllJunk()
    if not C_MerchantFrame.IsSellAllJunkEnabled or not C_MerchantFrame.GetNumJunkItems then
        return false
    end
    if not C_MerchantFrame.IsSellAllJunkEnabled() then
        return false
    end
    local numJunkItems = C_MerchantFrame.GetNumJunkItems()
    return numJunkItems and numJunkItems > 0
end

-- Подсказки кнопок для выбранной строки и текущей вкладки.
function Merchant.UpdateActionKeys(element)
    local tab = Merchant.tabs[Merchant.focusedTabIndex]
    local canRepair = tab and tab.code == "trade" and Merchant.NeedsEquipmentRepair()
    local canSellAllJunk = tab and tab.code == "sell" and Merchant.CanSellAllJunk()

    -- Снимаем действия прошлой вкладки, иначе у одной кнопки остаются две подписи.
    ConsoleMenu:DeleteKeysFrameItem("PAD1")
    ConsoleMenu:DeleteKeysFrameItem("PAD3")
    ConsoleMenu:DeleteKeysFrameItem("PAD4")

    if element and element.type == "merchantItem" and not element.isUnavailable then
        ConsoleMenu:AddKeysFrameItem("PAD1", "Купить предмет")
        if canRepair then
            ConsoleMenu:AddKeysFrameItem("PAD3", "Отремонтировать снаряжение")
        end
        if Merchant.GetListItemStackSize(element) > 1 then
            ConsoleMenu:AddKeysFrameItem("PAD4", "Купить пачку предметов")
        end
    elseif element and element.type == "buybackItem" then
        ConsoleMenu:AddKeysFrameItem("PAD1", "Выкупить предмет")
    elseif element and element.type == "bagItem" then
        ConsoleMenu:AddKeysFrameItem("PAD1", "Продать предмет")
        if canSellAllJunk then
            ConsoleMenu:AddKeysFrameItem("PAD4", "Продать весь хлам")
        end
    else
        if canRepair then
            ConsoleMenu:AddKeysFrameItem("PAD3", "Отремонтировать снаряжение")
        end
        if canSellAllJunk then
            ConsoleMenu:AddKeysFrameItem("PAD4", "Продать весь хлам")
        end
    end
end

-- Обновить подписи кнопок из текущего выбора списка.
function Merchant.UpdateKeysFrame()
    local list = Merchant.GetList()
    Merchant.UpdateActionKeys(list and list:GetFocusedElement())
end

-- Купить товар, выкупить предмет или продать содержимое ячейки сумки.
function Merchant.PrimaryAction()
    local list = Merchant.GetList()
    local focusedElement = list and list:GetFocusedElement()
    if not focusedElement or not focusedElement.slot then
        return
    end

    if focusedElement.type == "merchantItem" then
        if focusedElement.isUnavailable then
            return
        end
        BuyMerchantItem(focusedElement.slot)
    elseif focusedElement.type == "buybackItem" then
        BuybackItem(focusedElement.slot)
    elseif focusedElement.type == "bagItem" and focusedElement.bag ~= nil then
        C_Container.UseContainerItem(focusedElement.bag, focusedElement.slot)
    end
end

-- Купить пачку товаров или продать весь хлам.
function Merchant.SecondaryAction()
    local tab = Merchant.tabs[Merchant.focusedTabIndex]
    if tab and tab.code == "sell" then
        if Merchant.CanSellAllJunk() then
            C_MerchantFrame.SellAllJunkItems()
        end
        return
    end

    if not tab or tab.code ~= "trade" then
        return
    end

    local list = Merchant.GetList()
    local focusedElement = list and list:GetFocusedElement()
    if not focusedElement or not focusedElement.slot then
        return
    end
    if focusedElement.type ~= "merchantItem" or focusedElement.isUnavailable then
        return
    end

    local quantity = Merchant.GetListItemStackSize(focusedElement)
    if quantity <= 1 then
        return
    end

    BuyMerchantItem(focusedElement.slot, quantity)
end

-- Отремонтировать всё снаряжение.
function Merchant.TertiaryAction()
    local tab = Merchant.tabs[Merchant.focusedTabIndex]
    if not tab or tab.code ~= "trade" then
        return
    end
    if Merchant.NeedsEquipmentRepair() then
        RepairAllItems()
    end
end
