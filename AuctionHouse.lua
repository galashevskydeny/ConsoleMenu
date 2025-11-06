-- AuctionHouse.lua
local ConsoleMenu = _G.ConsoleMenu

-- Текущая покупка
local currentPurchase = {}

-- Функция запуска покупки
function ConsoleMenu:StartPurchase(itemID, quantity)
    C_AuctionHouse.StartCommoditiesPurchase(itemID, quantity)
    currentPurchase.itemID = itemID
    currentPurchase.quantity = quantity
end

function ConsoleMenu:ConfirmPurchase()
    if currentPurchase.itemID and currentPurchase.quantity then
        C_AuctionHouse.ConfirmCommoditiesPurchase(currentPurchase.itemID, currentPurchase.quantity)
        print("Покупка подтверждена:", currentPurchase.itemID, "x", currentPurchase.quantity)
        -- Обнуляем текущую покупку
        currentPurchase = {}
    end
end

-- -- Создаем кнопку
-- local buyButton = CreateFrame("Button", "ConsoleMenuBuyButton", UIParent, "UIPanelButtonTemplate")
-- buyButton:SetSize(120, 30)
-- buyButton:SetText("Купить первый")
-- buyButton:SetPoint("CENTER")

-- -- Обработчик нажатия
-- buyButton:SetScript("OnClick", function()
--     local firstItem = ConsoleMenu.CartItems[2]
--     print(firstItem)
--     if firstItem then
--         ConsoleMenu:StartPurchase(firstItem.itemID, firstItem.quantity)
--     else
--         print("Корзина пуста.")
--     end
-- end)