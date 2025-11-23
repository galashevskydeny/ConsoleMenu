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

local function SetBindingsForSet(bindings, modifier)
    for key, action in pairs(bindings) do
        local bindingKey = modifier and (modifier .. "-" .. key) or key
        SetBinding(bindingKey, action)
    end
end

local function SetOverrideBindingsForSet(bindings, modifier, frame)
    if not bindings then
        return
    end
    
    for key, action in pairs(bindings) do
        local bindingKey = modifier and (modifier .. "-" .. key) or key
        SetOverrideBinding(frame, false, bindingKey, action)
    end
end

-- Авторская схема привязок
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

-- Жилье
local function SetHousingButtonBinding(...)
    local currentEditMode = C_HouseEditor.GetActiveHouseEditorMode()

    local baseBindings = {}

    baseBindings["PAD4"] = "HOUSING_REMOVEDECOR"
    
    -- Тачпад DualSense
    baseBindings["PADBACK"] = "HOUSING_TOGGLEEDITOR"
    baseBindings["PAD6"] = "HOUSING_TOGGLEEDITOR"

    SetCVar("GamePadStickAxisButtons", "0")
    SetCVar("GamePadCameraPitchSpeed", "1")
    SetCVar("GamePadCameraYawSpeed", "1")

    if currentEditMode == Enum.HouseEditorMode.BasicDecor then
        baseBindings["PADLTRIGGER"] = "HOUSING_TOGGLELAYOUTMODE"
        baseBindings["PADRTRIGGER"] = "HOUSING_TOGGLEEXPERTDECORMODE"

        baseBindings["PADDLEFT"] = "HOUSING_BASICDECOR_ROTATELEFT"
        baseBindings["PADDRIGHT"] = "HOUSING_BASICDECOR_ROTATERIGHT"  


        if not C_Housing.IsInsideHouse() then
            baseBindings["PADLTRIGGER"] = "HOUSING_TOGGLEEXTERIORCUSTOMIZEMODE"
        end
    elseif currentEditMode == Enum.HouseEditorMode.ExpertDecor then
        baseBindings["PADLTRIGGER"] = "HOUSING_TOGGLEBASICDECORMODE"
        baseBindings["PADRTRIGGER"] = "HOUSING_TOGGLECUSTOMIZEMODE"

        local submode = C_HousingExpertMode.GetPrecisionSubmode()

        if submode == Enum.HousingPrecisionSubmode.Translate then
            baseBindings["PADDUP"] = "HOUSING_EXPERTDECORINCREMENT_BACK"
            baseBindings["PADDDOWN"] = "HOUSING_EXPERTDECORINCREMENT_FORWARD"
            baseBindings["PADDLEFT"] = "HOUSING_EXPERTDECORINCREMENT_RIGHT"
            baseBindings["PADDRIGHT"] = "HOUSING_EXPERTDECORINCREMENT_LEFT"  

            if C_HousingExpertMode.GetSelectedDecorInfo() then
                SetCVar("GamePadStickAxisButtons", "1")
                SetCVar("GamePadCameraPitchSpeed", "0")
                SetCVar("GamePadCameraYawSpeed", "0")
            end

            baseBindings["PADRSTICKUP"] = "HOUSING_EXPERTDECORINCREMENT_UP"
            baseBindings["PADRSTICKDOWN"] = "HOUSING_EXPERTDECORINCREMENT_DOWN"
    
            baseBindings["PADRSHOULDER"] = "HOUSING_EXPERTDECORROTATESUBMODE"
            baseBindings["PADLSHOULDER"] = "HOUSING_EXPERTDECORSCALESUBMODE"
        elseif submode == Enum.HousingPrecisionSubmode.Rotate then
            baseBindings["PADDLEFT"] = "HOUSING_EXPERTDECORINCREMENT_ROTATELEFT"
            baseBindings["PADDRIGHT"] = "HOUSING_EXPERTDECORINCREMENT_ROTATERIGHT" 
    
            baseBindings["PADDUP"] = "HOUSING_EXPERTDECORROTATION_NEXTAXIS"
            baseBindings["PADDDOWN"] = "HOUSING_EXPERTDECORROTATION_NEXTAXIS"
    
            baseBindings["PADRSHOULDER"] = "HOUSING_EXPERTDECORSCALESUBMODE"
            baseBindings["PADLSHOULDER"] = "HOUSING_EXPERTDECORTRANSLATESUBMODE"
    
        elseif submode == Enum.HousingPrecisionSubmode.Scale then
            baseBindings["PADDLEFT"] = "HOUSING_EXPERTDECORINCREMENT_SCALEDOWN"
            baseBindings["PADDRIGHT"] = "HOUSING_EXPERTDECORINCREMENT_SCALEUP" 
    
            baseBindings["PADRSHOULDER"] = "HOUSING_EXPERTDECORTRANSLATESUBMODE"
            baseBindings["PADLSHOULDER"] = "HOUSING_EXPERTDECORROTATESUBMODE"
        end

    elseif currentEditMode == Enum.HouseEditorMode.Customize then
        baseBindings["PADLTRIGGER"] = "HOUSING_TOGGLEEXPERTDECORMODE"
        baseBindings["PADRTRIGGER"] = "HOUSING_TOGGLECLEANUPMODE"
    elseif currentEditMode == Enum.HouseEditorMode.Cleanup then
        baseBindings["PADLTRIGGER"] = "HOUSING_TOGGLECUSTOMIZEMODE"
        baseBindings["PADRTRIGGER"] = "HOUSING_TOGGLELAYOUTMODE"

        if not C_Housing.IsInsideHouse() then
            baseBindings["PADRTRIGGER"] = "HOUSING_TOGGLEEXTERIORCUSTOMIZEMODE"
        end
    elseif currentEditMode == Enum.HouseEditorMode.Layout then
        baseBindings["PADLTRIGGER"] = "HOUSING_TOGGLECLEANUPMODE"
        baseBindings["PADRTRIGGER"] = "HOUSING_TOGGLEBASICDECORMODE"
    elseif currentEditMode == Enum.HouseEditorMode.ExteriorCustomization then
        baseBindings["PADLTRIGGER"] = "HOUSING_TOGGLECLEANUPMODE"
        baseBindings["PADRTRIGGER"] = "HOUSING_TOGGLEBASICDECORMODE"
    end

    -- Установим основные биндинги
    SetOverrideBindingsForSet(baseBindings, nil, ConsoleMenu.HousingBindingFrame)
end


-- Модуль для отслеживания системы жилищ
function ConsoleMenu:InitHousingBindingFrame()
    if not self.HousingBindingFrame then
        self.HousingBindingFrame = CreateFrame("Frame")
    end
    
    self.HousingBindingFrame:RegisterEvent("HOUSE_EDITOR_MODE_CHANGED")
    self.HousingBindingFrame:RegisterEvent("HOUSING_DECOR_PRECISION_SUBMODE_CHANGED")
    self.HousingBindingFrame:RegisterEvent("HOUSING_EXPERT_MODE_SELECTED_TARGET_CHANGED")
    self.HousingBindingFrame:RegisterEvent("HOUSE_EDITOR_AVAILABILITY_CHANGED")
    self.HousingBindingFrame:RegisterEvent("HOUSE_INFO_UPDATED")
    self.HousingBindingFrame:RegisterEvent("CURRENT_HOUSE_INFO_RECIEVED")
    self.HousingBindingFrame:RegisterEvent("HOUSE_PLOT_ENTERED")
    self.HousingBindingFrame:RegisterEvent("HOUSE_PLOT_EXITED")

    self.HousingBindingFrame:SetScript("OnEvent", function(frame, event, ...)

        if not C_Housing.IsInsideHouseOrPlot() then
            ClearOverrideBindings(ConsoleMenu.HousingBindingFrame)
            return
        end

        SetHousingButtonBinding(...)
    end)
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
            if not InCombatLockdown() then
                ClearOverrideBindings(frame)
            else

            end
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

    -- Проверяем, есть ли враг, перед установкой override бинда
    local hasEnemy = false
    if UnitExists("softenemy") and UnitCanAttack("player", "softenemy") then
        hasEnemy = true
    elseif UnitExists("target") and UnitCanAttack("player", "target") then
        hasEnemy = true
    end

    if newTarget and not hasEnemy then
        SetOverrideBinding(self.InteractBindingFrame, true, ConsoleMenuDB.interactButton, "INTERACTTARGET")
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
