local ConsoleMenu = _G.ConsoleMenu

function ConsoleMenu:SetBaseKeyBindings()
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

-- Модуль для отслеживания взаимодействия PAD1
function ConsoleMenu:InitKeybindFramePAD1()
    if not self.KeybindFramePAD1 then
        self.KeybindFramePAD1 = CreateFrame("Frame")
    end
    
    self.KeybindFramePAD1:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
    self.KeybindFramePAD1:RegisterEvent("PLAYER_ENTERING_WORLD")

    self.KeybindFramePAD1:SetScript("OnEvent", function(self, event, ...)
        if not ConsoleMenu or not ConsoleMenu.SetPAD1Interact then
            return
        end
        
        if event == "PLAYER_SOFT_INTERACT_CHANGED" then
            local oldTarget, newTarget = ...
            ConsoleMenu:SetPAD1Interact(newTarget)
        elseif event == "PLAYER_ENTERING_WORLD" then
            local oldTarget, newTarget
            ConsoleMenu:SetPAD1Interact(newTarget)
        end
    end)
end

-- Устанавливает биндинг PAD1 на взаимодействие
function ConsoleMenu:SetPAD1Interact(newTarget)
    if InCombatLockdown and InCombatLockdown() then
        return
    end

    if newTarget then
        SetOverrideBinding(self.KeybindFramePAD1, true, "PAD1", "INTERACTTARGET")
    else
        ClearOverrideBindings(self.KeybindFramePAD1)
    end
end

-- Модуль для отслеживания спешивания PAD2
function ConsoleMenu:InitKeybindFramePAD2()
    if not self.KeybindFramePAD2 then
        self.KeybindFramePAD2 = CreateFrame("Frame")
    end
    
    self.KeybindFramePAD2:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.KeybindFramePAD2:RegisterEvent("PLAYER_IS_GLIDING_CHANGED")
    self.KeybindFramePAD2:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")

    self.KeybindFramePAD2:RegisterEvent("UNIT_SPELLCAST_START")
    self.KeybindFramePAD2:RegisterEvent("UNIT_SPELLCAST_STOP")
    self.KeybindFramePAD2:RegisterEvent("UNIT_SPELLCAST_FAILED")
    self.KeybindFramePAD2:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")

    self.KeybindFramePAD2:SetScript("OnEvent", function(self, event, ...)
        if not ConsoleMenu or not ConsoleMenu.SetPAD2Dismount then
            return
        end
        
        if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_IS_GLIDING_CHANGED" or event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
            ConsoleMenu:SetPAD2Dismount()
        elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
            ConsoleMenu:SetPAD2StopCasting(event, ...)
        end
    end)
end

-- Устанавливает биндинг PAD2 на спуск с маунта
function ConsoleMenu:SetPAD2Dismount()
    if InCombatLockdown and InCombatLockdown() then
        return
    end

    if not IsFlying() and IsMounted() then
        SetOverrideBinding(self.KeybindFramePAD2, true, "PAD2", "DISMOUNT")
    else
        ClearOverrideBindings(self.KeybindFramePAD2)
    end
end

-- Устанавливает биндинг PAD2 на спуск с маунта
function ConsoleMenu:SetPAD2StopCasting(event, ...)
    if InCombatLockdown and InCombatLockdown() then
        return
    end

    if event == "UNIT_SPELLCAST_START" then
        local unitTarget, _ , _ = ...
        if unitTarget == "player" then
            SetOverrideBinding(self.KeybindFramePAD2, true, "PAD2", "STOPCASTING")
        end
    else
        ClearOverrideBindings(self.KeybindFramePAD2)
    end
end

-- Модуль для отслеживания способности зоны PAD6 и PADBACK
function ConsoleMenu:InitKeybindFramePAD6PADBACK()
    if not self.KeybindFramePAD6PADBACK then
        self.KeybindFramePAD6PADBACK = CreateFrame("Frame")
    end
    
    self.KeybindFramePAD6PADBACK:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.KeybindFramePAD6PADBACK:RegisterEvent("PLAYER_LOSES_VEHICLE_DATA")
    self.KeybindFramePAD6PADBACK:RegisterEvent("PLAYER_GAINS_VEHICLE_DATA")
    self.KeybindFramePAD6PADBACK:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self.KeybindFramePAD6PADBACK:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")

    self.KeybindFramePAD6PADBACK:SetScript("OnEvent", function(self, event, ...)
        if not ConsoleMenu or not ConsoleMenu.SetBindingsZoneAbility then
            return
        end
        
        ConsoleMenu:SetBindingsZoneAbility()
    end)
end

-- Устанавливает биндинг PAD6 и PADBACK на первую способность зоны
function ConsoleMenu:SetBindingsZoneAbility()
    if InCombatLockdown and InCombatLockdown() then
        return
    end

    -- Получаем активные зоновые способности
    local zoneAbilities = C_ZoneAbility.GetActiveAbilities()
    
    if zoneAbilities and #zoneAbilities > 0 then
        local firstAbility = zoneAbilities[1]
        if firstAbility and firstAbility.spellID then
            local spellID = firstAbility.spellID
            local spellInfo = spellID and C_Spell.GetSpellInfo(spellID)
            if spellInfo and spellInfo.name then
                ClearOverrideBindings(self.KeybindFramePAD6PADBACK)
                SetOverrideBindingSpell(self.KeybindFramePAD6PADBACK, true, "PAD6", spellInfo.name)
                SetOverrideBindingSpell(self.KeybindFramePAD6PADBACK, true, "PADBACK", spellInfo.name)
            else
                ClearOverrideBindings(self.KeybindFramePAD6PADBACK)
            end
        else
            ClearOverrideBindings(self.KeybindFramePAD6PADBACK)
        end
    else
        ClearOverrideBindings(self.KeybindFramePAD6PADBACK)
    end
end
