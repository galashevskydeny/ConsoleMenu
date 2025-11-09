local ConsoleMenu = _G.ConsoleMenu
-- Функция для очистки всех биндов на кнопках PlayStation5 (131-154)
function ConsoleMenu:ClearControllerBindings()
    local keys = {
        "PADDUP",
        "PADDRIGHT",
        "PADDDOWN",
        "PADDLEFT",
        "PAD1",
        "PAD2",
        "PAD3",
        "PAD4",
        "PAD5",
        "PADLSTICK",
        "PADRSTICK",
        "PADLSHOULDER",
        "PADRSHOULDER",
        "PADLTRIGGER",
        "PADRTRIGGER",
        "PADFORWARD",
        "PADBACK",
        "PAD6",
        "PADSYSTEM",
        "PADSOCIAL",
        "PADPADDLE1",
        "PADPADDLE2",
        "PADPADDLE3",
        "PADPADDLE4",
    }

    -- Очищаем бинды в каждом модификаторе и без модификатора
    for _, key in ipairs(keys) do
        SetBinding(key)
        SetBinding("SHIFT-"..key)
        SetBinding("CTRL-"..key)
        SetBinding("ALT-"..key)
        SetBinding("CTRL-SHIFT-"..key)
        SetBinding("CTRL-ALT-"..key)
        SetBinding("SHIFT-ALT-"..key)
        SetBinding("CTRL-SHIFT-ALT-"..key)
    end

    SaveBindings(GetCurrentBindingSet())
end


function ConsoleMenu:SetBaseKeyBindings()
    -- Выполняем только если выбрана кастомная схема привязки
    if not ConsoleMenuDB or ConsoleMenuDB.keyBindingScheme ~= 1 then
        return
    end
    
    local baseBindings = {
        PAD1 = "JUMP",
        PAD2 = "ACTIONBUTTON3",
        PAD3 = "ACTIONBUTTON1",
        PAD4 = "ACTIONBUTTON2",
        PADDUP = "ACTIONBUTTON6",
        PADDDOWN = "ACTIONBUTTON8",
        PADDLEFT = "ACTIONBUTTON9",
        PADDRIGHT = "ACTIONBUTTON7",
        PADLTRIGGER = "TARGETNEARESTENEMY",
        PADLSTICK = "ACTIONBUTTON5",
        PADRSTICK = "ACTIONBUTTON4",
        PADFORWARD = "",

        -- Тачпад DualSense
        PADBACK = "TOGGLEWORLDMAP",
        PAD6 = "TOGGLEWORLDMAP"
    }
    
    local shiftBindings = {
        PAD1 = "INTERACTTARGET",
        PAD2 = "MULTIACTIONBAR1BUTTON3",
        PAD3 = "MULTIACTIONBAR1BUTTON1",
        PAD4 = "MULTIACTIONBAR1BUTTON2",
        PADDUP = "MULTIACTIONBAR1BUTTON6",
        PADDDOWN = "MULTIACTIONBAR1BUTTON8",
        PADDLEFT = "MULTIACTIONBAR1BUTTON9",
        PADDRIGHT = "MULTIACTIONBAR1BUTTON7",
        PADLSTICK = "MULTIACTIONBAR1BUTTON5",
        PADRSTICK = "MULTIACTIONBAR1BUTTON4",
        PADFORWARD = "CAMERAZOOMOUT",

        -- Тачпад DualSense
        PADBACK = "TOGGLEWORLDMAP",
        PAD6 = "TOGGLEWORLDMAP"
    }
    
    local ctrlBindings = {
        PAD1 = "INTERACTTARGET",
        PAD2 = "MULTIACTIONBAR2BUTTON3",
        PAD3 = "MULTIACTIONBAR2BUTTON1",
        PAD4 = "MULTIACTIONBAR2BUTTON2",
        PADDUP = "MULTIACTIONBAR2BUTTON6",
        PADDDOWN = "MULTIACTIONBAR2BUTTON8",
        PADDLEFT = "MULTIACTIONBAR2BUTTON9",
        PADDRIGHT = "MULTIACTIONBAR2BUTTON7",
        PADLSTICK = "MULTIACTIONBAR2BUTTON5",
        PADRSTICK = "MULTIACTIONBAR2BUTTON4",
        PADFORWARD = "CAMERAZOOMIN",

        -- Тачпад DualSense
        PADBACK = "TOGGLEWORLDMAP",
        PAD6 = "TOGGLEWORLDMAP"
    }

    local function SetBindingsForSet(bindings, modifier)
        for key, action in pairs(bindings) do
            local bindingKey = modifier and (modifier .. "-" .. key) or key
            SetBinding(bindingKey, action)
        end
    end

    -- Очистим старые биндинги
    for key, _ in pairs(baseBindings) do
        SetBinding(key)
        SetBinding("SHIFT-" .. key)
        SetBinding("CTRL-" .. key)
    end
    
    -- Установим основные биндинги
    SetBindingsForSet(baseBindings)
    
    -- Установим SHIFT биндинги
    SetBindingsForSet(shiftBindings, "SHIFT")
    
    -- Установим CTRL биндинги
    SetBindingsForSet(ctrlBindings, "CTRL")
    
    -- Сохраним
    SaveBindings(GetCurrentBindingSet())
end

-- Модуль для отслеживания взаимодействия
function ConsoleMenu:InitInteractBindingFrame()
    if not self.InteractBindingFrame then
        self.InteractBindingFrame = CreateFrame("Frame")
    end
    
    self.InteractBindingFrame:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
    self.InteractBindingFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.InteractBindingFrame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")

    self.InteractBindingFrame:SetScript("OnEvent", function(frame, event, ...)
        if not ConsoleMenu or not ConsoleMenu.SetInteractBinding then
            return
        end
        
        if event == "PLAYER_SOFT_INTERACT_CHANGED" then
            local oldTarget, newTarget = ...
            ConsoleMenu:SetInteractBinding(newTarget)
        elseif event == "PLAYER_ENTERING_WORLD" then
            local oldTarget, newTarget
            ConsoleMenu:SetInteractBinding(newTarget)
        elseif event == "PLAYER_SOFT_ENEMY_CHANGED" then
            -- Отменяем override бинды при появлении враждебной soft-target цели
            ClearOverrideBindings(frame)
        end
    end)
end

-- Устанавливает биндинг на взаимодействие
function ConsoleMenu:SetInteractBinding(newTarget)

    if ConsoleMenuDB and ConsoleMenuDB.overrideInteractKey == 2 then
        return
    end

    if InCombatLockdown and InCombatLockdown() then
        return
    end

    if newTarget then
        local interactButton = (ConsoleMenuDB and ConsoleMenuDB["interactButtonString"]) or "PAD1"
        SetOverrideBinding(self.InteractBindingFrame, true, interactButton, "INTERACTTARGET")

    else
        ClearOverrideBindings(self.InteractBindingFrame)
    end
end

-- Модуль для отслеживания способности зоны PAD6 и PADBACK
function ConsoleMenu:InitZoneAbilityBindingFrame()
    if not self.ZoneAbilityBindingFrame then
        self.ZoneAbilityBindingFrame = CreateFrame("Frame")
    end
    
    self.ZoneAbilityBindingFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.ZoneAbilityBindingFrame:RegisterEvent("PLAYER_LOSES_VEHICLE_DATA")
    self.ZoneAbilityBindingFrame:RegisterEvent("PLAYER_GAINS_VEHICLE_DATA")
    self.ZoneAbilityBindingFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self.ZoneAbilityBindingFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")

    self.ZoneAbilityBindingFrame:SetScript("OnEvent", function(self, event, ...)
        if not ConsoleMenu or not ConsoleMenu.SetBindingsZoneAbility then
            return
        end
        
        ConsoleMenu:SetBindingsZoneAbility()
    end)
end

-- Устанавливает биндинг на первую способность зоны
function ConsoleMenu:SetBindingsZoneAbility()
    if ConsoleMenuDB.overrideZoneAbilityKey == 2 then
        ClearOverrideBindings(self.ZoneAbilityBindingFrame)
        return
    end
    
    if InCombatLockdown() then return end

    -- Получаем активные зоновые способности
    local zoneAbilities = C_ZoneAbility.GetActiveAbilities()
    
    if zoneAbilities and #zoneAbilities > 0 then
        local firstAbility = zoneAbilities[1]
        if firstAbility and firstAbility.spellID then
            local spellID = firstAbility.spellID
            local spellInfo = spellID and C_Spell.GetSpellInfo(spellID)
            if spellInfo and spellInfo.name then
                ClearOverrideBindings(self.ZoneAbilityBindingFrame)
                SetOverrideBindingSpell(self.ZoneAbilityBindingFrame, true, "PAD6", spellInfo.name)
                SetOverrideBindingSpell(self.ZoneAbilityBindingFrame, true, "PADBACK", spellInfo.name)
            else
                ClearOverrideBindings(self.ZoneAbilityBindingFrame)
            end
        else
            ClearOverrideBindings(self.ZoneAbilityBindingFrame)
        end
    else
        ClearOverrideBindings(self.ZoneAbilityBindingFrame)
    end
end
