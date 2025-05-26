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
                    table.insert(
                        ConsoleMenu.CartItems,
                        {
                            quantity = reagentSlot.quantityRequired,
                            itemID = reagentSlot.reagents[1].itemID
                        }
                    )
                elseif CountUniqueStrings(names) == 1 then
                    for _, reagent in ipairs(reagents) do
                        if bestQualityCheckbox and reagent.quality == 3 then
                            table.insert(
                                ConsoleMenu.CartItems,
                                {
                                    quantity = reagentSlot.quantityRequired,
                                    itemID = reagent.itemID
                                }
                            )
                        elseif not bestQualityCheckbox and reagent.quality == 1 then
                            table.insert(
                                ConsoleMenu.CartItems,
                                {
                                    quantity = reagentSlot.quantityRequired,
                                    itemID = reagent.itemID
                                }
                            )
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

function ConsoleMenu:AddCartButton()
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
