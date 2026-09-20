-- Названия действий ячеек панели для подписей и подсказок клавиш.

local ConsoleMenu = _G.ConsoleMenu

-- Название действия по типу ячейки: заклинание, предмет, макрос, скакун или наряд.
function ConsoleMenu:GetSlotTitle(actionType, id, subType, slotID)
    -- У макроса GetActionInfo кладёт в id spellID/itemID, если есть subType.
    -- Для item-макроса id часто невалиден — имя предмета берём через GetMacroItem.
    if actionType == "macro" then
        if subType == "spell" then
            actionType = "spell"
        elseif subType == "item" then
            local macroName = slotID and GetActionText(slotID)
            return (macroName and GetMacroItem(macroName)) or C_Item.GetItemNameByID(id) or macroName
        else
            return C_Macro.GetMacroName(id)
        end
    end

    if actionType == "spell" then
        local spellInfo = C_Spell.GetSpellInfo(id)
        if spellInfo and spellInfo.name then
            return spellInfo.name
        end
        return slotID and GetActionText(slotID)
    end

    if actionType == "item" then
        local name = C_Item.GetItemNameByID(id)
        return name
    end

    if actionType == "summonmount" then

        -- 268435455 - избранный маунт
        if id ~= 268435455 then
            local name = C_MountJournal.GetMountInfoByID(id)
            return name
        else
            return "Избранный маунт"
        end
    end

    if actionType == "outfit" then
        if not C_TransmogOutfitInfo or not C_TransmogOutfitInfo.GetOutfitInfo then
            return nil
        end
        local info = C_TransmogOutfitInfo.GetOutfitInfo(id)
        if info and info.name then
            return info.name
        end
        return nil
    end

end
