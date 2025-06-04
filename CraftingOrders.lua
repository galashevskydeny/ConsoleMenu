-- CraftingOrders.lua
local ConsoleMenu = LibStub("AceAddon-3.0"):GetAddon("ConsoleMenu")

ConsoleMenu.CartItems = {}
ConsoleMenu.ChoiseTasks = {}

-- Функция из предыдущего ответа
function CountUniqueStrings(strings)
  local seen, count = {}, 0
  for _, str in ipairs(strings) do
    if not seen[str] then
      seen[str] = true
      count = count + 1
    end
  end
  return count
end

-- Функция добавления товара в корзину
function AddToCart(itemID, quantity)
    if not itemID or not quantity then
        return
    end

    if ConsoleMenu.CartItems[itemID] == nil then
        ConsoleMenu.CartItems[itemID] = quantity
    else
        ConsoleMenu.CartItems[itemID] = ConsoleMenu.CartItems[itemID] + quantity
    end
end

-- Функция удаления товара из корзины
function RemoveFromCart(itemID, quantity)
    if not itemID or not quantity or ConsoleMenu.CartItems[itemID] then
        return
    end

    if ConsoleMenu.CartItems[itemID] - quantity > 0 then
        ConsoleMenu.CartItems[itemID] = ConsoleMenu.CartItems[itemID] - quantity
    else
         ConsoleMenu.CartItems[itemID] = 0
    end
end

-- Функция получения
function ConsoleMenu:AddCraftingOrderItemsToCart()
    if not ProfessionsCustomerOrdersFrame or not ProfessionsCustomerOrdersFrame.Form.order then
        return
    end

    local spellID = ProfessionsCustomerOrdersFrame.Form.order.spellID
    local quality = ProfessionsCustomerOrdersFrame.Form.order.minQuality
    local isRecraft = ProfessionsCustomerOrdersFrame.Form.order.isRecraft

    local schematic = C_TradeSkillUI.GetRecipeSchematic(spellID, isRecraft, quality)
    local bestQualityCheckbox = ProfessionsCustomerOrdersFrame.Form.AllocateBestQualityCheckbox:GetChecked()

    if schematic and schematic.reagentSlotSchematics then
        for _, reagentSlot in ipairs(schematic.reagentSlotSchematics) do

            local reagents = {}
            local names = {}

            for _, reagent in ipairs(reagentSlot.reagents) do
                -- Создаём объект Item
                local itemObj = Item:CreateFromItemID(reagent.itemID)
                -- Запрашиваем загрузку данных
                itemObj:ContinueOnItemLoad(function()
                    local quality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(reagent.itemID)
                    local itemName, _, _, _, _, _, _, _, _, _ = C_Item.GetItemInfo(reagent.itemID)

                    table.insert(
                        reagents,
                        {
                            quality = quality,
                            itemID = reagent.itemID
                        }
                    )

                    table.insert(names, itemName)

                end)
            end

            if reagentSlot.slotInfo then
                -- Добавляем название слота
                table.insert(names, reagentSlot.slotInfo.slotText)
            end
                
            if reagentSlot.reagentType == 1 or reagentSlot.reagentType == 0 then
                if #reagentSlot.reagents ==  1 then
                    AddToCart(reagentSlot.reagents[1].itemID, reagentSlot.quantityRequired)
                elseif CountUniqueStrings(names) == 1 then
                    for _, reagent in ipairs(reagents) do
                        if bestQualityCheckbox and reagent.quality == 3 then
                            AddToCart(reagent.itemID, reagentSlot.quantityRequired)
                        elseif not bestQualityCheckbox and reagent.quality == 1 then
                            AddToCart(reagent.itemID, reagentSlot.quantityRequired)
                        end
                    end
                else
                    table.insert(
                        ConsoleMenu.ChoiseTasks,
                        {
                            quantity = reagentSlot.quantityRequired,
                            items = reagentSlot.reagents,
                            title = reagentSlot.slotInfo.slotText
                        }
                    )
                end
            end
        end
    end
end

--
function ConsoleMenu:AddCraftingOrderCartButton()
    -- Создаем кнопку
    local addButton = CreateFrame("Button", "ConsoleMenuAddItemsButton", ProfessionsCustomerOrdersFrame.Form, "SharedButtonTemplate")
    addButton:SetSize(190, 32)
    addButton:SetText("Добавить реагенты в корзину")
    addButton:SetPoint("BOTTOMRIGHT", ProfessionsCustomerOrdersFrame.Form, "TOPRIGHT", 0, 2)

    -- Обработчик нажатия
    addButton:SetScript("OnClick", function()
        ConsoleMenu:AddCraftingOrderItemsToCart()
    end)
end

--
function ConsoleMenu:AddCraftingOrderReagentSlotsCartButton()
    if not ProfessionsCustomerOrdersFrame.Form or not ProfessionsCustomerOrdersFrame.Form.ReagentContainer.Reagents then
        return
    end

    for _, child in ipairs({ProfessionsCustomerOrdersFrame.Form.ReagentContainer.Reagents:GetChildren()}) do
        
        local reagents = {}
        local names = {}

        for _, reagent in ipairs(child.reagentSlotSchematic.reagents) do
            -- Создаём объект Item
            local itemObj = Item:CreateFromItemID(reagent.itemID)
            -- Запрашиваем загрузку данных
            itemObj:ContinueOnItemLoad(function()
                local quality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(reagent.itemID)
                local itemName, _, _, _, _, _, _, _, _, _, _, _, _, bindType = C_Item.GetItemInfo(reagent.itemID)

                table.insert(
                        reagents,
                        {
                            quality = quality,
                            itemID = reagent.itemID
                        }
                    )

                table.insert(names, itemName)

            end)
        end

        if child.reagentSlotSchematic.slotInfo then
            -- Добавляем название слота
            table.insert(names, child.reagentSlotSchematic.slotInfo.slotText)
        end

        if CountUniqueStrings(names) == 1 and not child.AddToCartButton then
            local addButton = CreateFrame("Button", nil, child, "SharedButtonTemplate")

            addButton:SetSize(96, 36)
            addButton:SetText("В корзину")
            addButton:SetPoint("LEFT", child, "RIGHT", 8, 0)
            
            -- Обработчик нажатия
            addButton:SetScript("OnClick", function()
                local bestQualityCheckbox = ProfessionsCustomerOrdersFrame.Form.AllocateBestQualityCheckbox:GetChecked()

                if child.reagentSlotSchematic.reagentType == 1 or child.reagentSlotSchematic.reagentType == 0 then
                    if #child.reagentSlotSchematic.reagents ==  1 then
                        AddToCart(child.reagentSlotSchematic.reagents[1].itemID, child.reagentSlotSchematic.quantityRequired)
                    elseif CountUniqueStrings(names) == 1 then
                        for _, reagent in ipairs(reagents) do
                            if bestQualityCheckbox and reagent.quality == 3 then
                                AddToCart(reagent.itemID, child.reagentSlotSchematic.quantityRequired)
                            elseif not bestQualityCheckbox and reagent.quality == 1 then
                                AddToCart(reagent.itemID, child.reagentSlotSchematic.quantityRequired)
                            end
                        end
                    end
                end
            end)

            child.AddToCartButton = addButton

        elseif CountUniqueStrings(names) > 1 and child.AddToCartButton then
            child.AddToCartButton:Hide()
            child.AddToCartButton:SetParent(nil)
            child.AddToCartButton = nil
        end
    end

    for _, child in ipairs({ProfessionsCustomerOrdersFrame.Form.ReagentContainer.OptionalReagents:GetChildren()}) do
        if child.AddToCartButton then
            child.AddToCartButton:Hide()
            child.AddToCartButton:SetParent(nil)
            child.AddToCartButton = nil
        end
    end
end

function ConsoleMenu:SetProfessionsCustomerOrdersFrame()
    ProfessionsCustomerOrdersFrame.Form:HookScript("OnShow", function()
        --ConsoleMenu:AddCraftingOrderCartButton()
    end)

    ProfessionsCustomerOrdersFrame.Form:HookScript("OnShow", function()
        ConsoleMenu:AddCraftingOrderReagentSlotsCartButton()
    end)

    ProfessionsCustomerOrdersFrame.Form:HookScript("OnUpdate", function()
        ConsoleMenu:AddCraftingOrderReagentSlotsCartButton()
    end)
end
