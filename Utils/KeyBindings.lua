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

    if InCombatLockdown() then return end

    ClearOverrideBindings(frame)
    
    for key, action in pairs(bindings) do
        local bindingKey = modifier and (modifier .. "-" .. key) or key
        SetOverrideBinding(frame, false, bindingKey, action)
    end
end

-- Модуль для системы жилищ
-- Вспомогательная функция для получения списка категорий из StoragePanel
local function GetStorageCategories()
    local storagePanel = HouseEditorFrame and HouseEditorFrame.StoragePanel
    if not storagePanel or not storagePanel.Categories then
        return {}
    end
    
    local categories = storagePanel.Categories.categories

    local categoriesToShow = {};
    
	for categoryID, category in pairs(categories) do
        if storagePanel.Categories:DoesCategoryPassFilters(categoryID) then
			table.insert(categoriesToShow, category);
		end
	end

    table.sort(categoriesToShow, function (c1, c2) return c1.categoryInfo.orderIndex < c2.categoryInfo.orderIndex; end )

    local categoryIDs = {}
    for i, category in ipairs(categoriesToShow) do
        table.insert(categoryIDs, category.categoryInfo.ID)
    end

    return categoryIDs
end

-- Вспомогательная функция для получения списка подкатегорий из StoragePanel
local function GetStorageSubcategories(categoryID)
    local storagePanel = HouseEditorFrame and HouseEditorFrame.StoragePanel
    if not storagePanel or not storagePanel.Categories then
        return {}
    end

    local categories = storagePanel.Categories.categories

    local subcategoriesToShow = {}
	for subcategoryID, subcategoryInfo in pairs(categories[categoryID].subcategoryInfos) do
        if storagePanel.Categories:DoesSubcategoryPassFilters(subcategoryID) then
			table.insert(subcategoriesToShow, subcategoryInfo);
		end
	end

	if #subcategoriesToShow <= 1 then
		return nil
	end

	table.sort(subcategoriesToShow, function (s1, s2) return s1.orderIndex < s2.orderIndex; end );

    local categoryIDs = {}
    for i, category in ipairs(subcategoriesToShow) do
        table.insert(categoryIDs, category.ID)
    end

    return categoryIDs
end

-- Вспомогательная функция для поиска индекса категории
local function FindCategoryIndex(categoryIDs, categoryID)
    if not categoryIDs then
        return nil
    end
    for idx, catID in ipairs(categoryIDs) do
        if catID == categoryID then
            return idx
        end
    end
    return nil
end

-- Общая функция для навигации по категориям (forward = true для следующей, false для предыдущей)
local function NavigateStorageCategory(currentCategoryID, currentSubcategoryID, forward)

    local resultCategoryID, resultSubcategoryID

    local categories = GetStorageCategories()
    local subcategories = GetStorageSubcategories(currentCategoryID) or {}

    local currentCatIndex = FindCategoryIndex(categories, currentCategoryID)
    local currentSubcatIndex = FindCategoryIndex(subcategories, currentSubcategoryID)

    if forward then

        if currentCatIndex and currentCatIndex == #categories then
            resultCategoryID = categories[1]
            resultSubcategoryID = nil
            subcategories = GetStorageSubcategories(resultCategoryID)
            if subcategories and #subcategories > 1 then
                resultSubcategoryID = subcategories[1]
            end

            return resultCategoryID, resultSubcategoryID
        end

        if #subcategories > 1 then
            if currentSubcatIndex and currentSubcatIndex == #subcategories then
                resultCategoryID = categories[currentCatIndex + 1]
                resultSubcategoryID = nil
                subcategories = GetStorageSubcategories(resultCategoryID)
                if subcategories and #subcategories > 1 then
                    resultSubcategoryID = subcategories[0]
                end
            elseif currentSubcatIndex then
                resultCategoryID = currentCategoryID
                resultSubcategoryID = subcategories[currentSubcatIndex + 1]
            else
                resultCategoryID = currentCategoryID
                resultSubcategoryID = subcategories[1]
            end
        else
            resultCategoryID = categories[currentCatIndex + 1]
            resultSubcategoryID = nil
            subcategories = GetStorageSubcategories(resultCategoryID)
            if subcategories and #subcategories > 1 then
                resultSubcategoryID = subcategories[0]
            end
        end
    else
        -- Движение назад
        if currentCatIndex and currentCatIndex == 1 then
            -- Если сейчас на первой категории, перейти к последней
            resultCategoryID = categories[#categories]
            resultSubcategoryID = nil
            subcategories = GetStorageSubcategories(resultCategoryID)
            if subcategories and #subcategories > 1 then
                resultSubcategoryID = subcategories[#subcategories]
            end

            return resultCategoryID, resultSubcategoryID
        end

        if #subcategories > 1 then
            if currentSubcatIndex and currentSubcatIndex == 0 then
                -- Если сейчас на первой подкатегории, перейти к предыдущей категории и к последней ее подкатегории
                resultCategoryID = categories[currentCatIndex - 1]
                resultSubcategoryID = nil
                subcategories = GetStorageSubcategories(resultCategoryID)
                if subcategories and #subcategories > 1 then
                    resultSubcategoryID = subcategories[#subcategories]
                end
            elseif currentSubcatIndex then
                -- Переместиться к предыдущей подкатегории в рамках текущей категории
                resultCategoryID = currentCategoryID
                resultSubcategoryID = subcategories[currentSubcatIndex - 1]
            else
                -- Нет активной подкатегории, выбрать последнюю
                resultCategoryID = categories[currentCatIndex - 1]
                resultSubcategoryID = nil
                subcategories = GetStorageSubcategories(resultCategoryID)
                if subcategories and #subcategories > 1 then
                    resultSubcategoryID = subcategories[#subcategories]
                end
            end
        else
            -- Нет подкатегорий, сдвинуться к предыдущей категории
            resultCategoryID = categories[currentCatIndex - 1]
            resultSubcategoryID = nil
            subcategories = GetStorageSubcategories(resultCategoryID)
            if subcategories and #subcategories > 1 then
                resultSubcategoryID = subcategories[#subcategories]
            end
        end
    end
    
    return resultCategoryID, resultSubcategoryID
end

-- Общая функция для установки следующей/предыдущей категории и подкатегории в StoragePanel
local function SetStorageCategory(forward)
    local storagePanel = HouseEditorFrame and HouseEditorFrame.StoragePanel
    if not storagePanel or not storagePanel.Categories then
        return
    end
    
    local currentCategoryID = storagePanel.Categories.focusedCategoryID
    local currentSubcategoryID = storagePanel.Categories.focusedSubcategoryID
    
    local categoryID, subcategoryID = NavigateStorageCategory(currentCategoryID, currentSubcategoryID, forward)
    if categoryID then
        storagePanel.Categories:SetFocus(categoryID, subcategoryID)
    end
end

-- Функция для установки следующей категории и подкатегории в StoragePanel
local function SetNextStorageCategory()
    SetStorageCategory(true)
end

-- Функция для установки предыдущей категории и подкатегории в StoragePanel
local function SetPreviousStorageCategory()
    SetStorageCategory(false)
end

local function SetHousingButtonBinding(...)
    local currentEditMode = C_HouseEditor.GetActiveHouseEditorMode()

    local baseBindings = {}
    
    -- Тачпад DualSense
    baseBindings["PADBACK"] = "HOUSING_TOGGLEEDITOR"
    baseBindings["PAD6"] = "HOUSING_TOGGLEEDITOR"

    if currentEditMode == Enum.HouseEditorMode.BasicDecor then

        baseBindings["PAD2"] = "HOUSING_REMOVEDECOR"
        baseBindings["PAD3"] = "HOUSING_TOGGLEDECORSNAPMODE"
        baseBindings["PAD4"] = "HOUSING_TOGGLEDECORNUDGEMODE"

        baseBindings["PADLTRIGGER"] = "HOUSING_TOGGLELAYOUTMODE"
        baseBindings["PADRTRIGGER"] = "HOUSING_TOGGLEEXPERTDECORMODE"

        if C_HousingBasicMode.IsDecorSelected() then
            baseBindings["PADDLEFT"] = "HOUSING_BASICDECOR_ROTATELEFT"
            baseBindings["PADDRIGHT"] = "HOUSING_BASICDECOR_ROTATERIGHT"
        else
            baseBindings["PADDLEFT"] = ""
            baseBindings["PADDRIGHT"] = ""
        end

        baseBindings["PADRSHOULDER"] = "CLICK ConsoleMenuHousingNextCategoryButton:LeftButton"
        baseBindings["PADLSHOULDER"] = "CLICK ConsoleMenuHousingPrevCategoryButton:LeftButton"

        if not C_Housing.IsInsideHouse() then
            baseBindings["PADLTRIGGER"] = "HOUSING_TOGGLEEXTERIORCUSTOMIZEMODE"
        end
    elseif currentEditMode == Enum.HouseEditorMode.ExpertDecor then
        baseBindings["PAD2"] = "HOUSING_REMOVEDECOR"
        baseBindings["PADLTRIGGER"] = "HOUSING_TOGGLEBASICDECORMODE"
        baseBindings["PADRTRIGGER"] = "HOUSING_TOGGLECUSTOMIZEMODE"

        local submode = C_HousingExpertMode.GetPrecisionSubmode()

        if submode == Enum.HousingPrecisionSubmode.Translate then
            baseBindings["PADDUP"] = "HOUSING_EXPERTDECORINCREMENT_FORWARD"
            baseBindings["PADDDOWN"] = "HOUSING_EXPERTDECORINCREMENT_BACK"
            baseBindings["PADDLEFT"] = "HOUSING_EXPERTDECORINCREMENT_LEFT"
            baseBindings["PADDRIGHT"] = "HOUSING_EXPERTDECORINCREMENT_RIGHT"  

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

function ConsoleMenu:InitHousingBindingFrame()
    if not C_Housing then
        return
    end

    if not self.HousingBindingFrame then
        self.HousingBindingFrame = CreateFrame("Frame")
        
        -- Создаем кнопку для переключения категории/подкатегории вперед
        local nextCategoryButton = CreateFrame("Button", "ConsoleMenuHousingNextCategoryButton", HouseEditorFrame)
        nextCategoryButton:SetSize(1, 1)
        nextCategoryButton:SetPoint("TOPLEFT", HouseEditorFrame, "TOPLEFT", 0, 0)
        nextCategoryButton:SetScript("OnClick", function(self, button)
            SetNextStorageCategory()
        end)
        
        -- Создаем кнопку для переключения категории/подкатегории назад
        local prevCategoryButton = CreateFrame("Button", "ConsoleMenuHousingPrevCategoryButton", HouseEditorFrame)
        prevCategoryButton:SetSize(1, 1)
        prevCategoryButton:SetPoint("TOPLEFT", HouseEditorFrame, "TOPLEFT", 0, 0)
        prevCategoryButton:SetScript("OnClick", function(self, button)
            SetPreviousStorageCategory()
        end)
        
    end
    
    self.HousingBindingFrame:RegisterEvent("HOUSE_EDITOR_MODE_CHANGED")
    self.HousingBindingFrame:RegisterEvent("HOUSING_BASIC_MODE_SELECTED_TARGET_CHANGED")
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
    self.InteractBindingFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

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
        elseif event == "PLAYER_REGEN_ENABLED" then
            if UnitIsInteractable("softenemy") then
                ConsoleMenu:SetInteractBinding("softenemy")
            elseif UnitIsInteractable("softinteract") then
                ConsoleMenu:SetInteractBinding("softinteract")
            end
        elseif event == "PLAYER_SOFT_ENEMY_CHANGED" then
            -- Отменяем override бинды при появлении враждебной soft-target цели
            if not InCombatLockdown() then
                ClearOverrideBindings(frame)
            else

            end
        end
    end)
end

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
        if InCombatLockdown() then return end
        SetOverrideBinding(self.InteractBindingFrame, true, ConsoleMenuDB.interactButton, "INTERACTTARGET")
        ConsoleMenu:AddKeysFrameItem("PAD1", "Взаимодействие")
        ConsoleMenu:UpdateKeysFrame()
    else
        if InCombatLockdown() then return end
        ClearOverrideBindings(self.InteractBindingFrame)
        ConsoleMenu:DeleteKeysFrameItem("PAD1", "Взаимодействие")
        ConsoleMenu:UpdateKeysFrame()
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

function ConsoleMenu:SetBindingsZoneAbility()
    
    if ConsoleMenuDB.overrideZoneAbilityKey == 2 then
        if InCombatLockdown() then return end
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

-- Модуль для отслеживания прерывания заклинания
function ConsoleMenu:SetStopCastingBinding()

    if InCombatLockdown() then
        return
    end

    if IsMounted() then
        return
    end

    if ConsoleMenuDB.overrideStopCastingKey == 2 then
        ClearOverrideBindings(self.StopCastingBindingFrame)
        return
    end

    SetOverrideBinding(self.StopCastingBindingFrame, true, ConsoleMenuDB.stopCastingButton, "STOPCASTING")
    ConsoleMenu:AddKeysFrameItem("PAD2", "Прервать")
    ConsoleMenu:UpdateKeysFrame()
end

function ConsoleMenu:InitStopCastingBindingFrame()
    if not self.StopCastingBindingFrame then
        self.StopCastingBindingFrame = CreateFrame("Frame")
    end
    
    self.StopCastingBindingFrame:RegisterEvent("UNIT_SPELLCAST_SENT")
    self.StopCastingBindingFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
    self.StopCastingBindingFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.StopCastingBindingFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.StopCastingBindingFrame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
    self.StopCastingBindingFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")


    self.StopCastingBindingFrame:SetScript("OnEvent", function(frame, event, ...)
        if event == "UNIT_SPELLCAST_SENT" then
            local unit, target, _, spellID = ...
            
            -- Если заклинание не относится к игроку
            if unit ~= "player" then
                return
            end

            -- После применения может начаться бой, во время которого нельзя откатить привязку
            if target ~= nil or UnitExists("target") or UnitExists("softenemy") then
                return
            end

            local spellInfo = C_Spell.GetSpellInfo(spellID)

            if spellInfo and spellInfo.castTime == 0 then
                return
            end

            ConsoleMenu:SetStopCastingBinding()
        
        elseif event == "UNIT_SPELLCAST_STOP" then
            local unit = ...
            
            -- Если заклинание не относится к игроку
            if unit ~= "player" then
                return
            end
            
            if InCombatLockdown() then return end
            ClearOverrideBindings(ConsoleMenu.StopCastingBindingFrame)
            ConsoleMenu:DeleteKeysFrameItem("PAD2", "Прервать")
            ConsoleMenu:UpdateKeysFrame()
        elseif event == "PLAYER_SOFT_ENEMY_CHANGED" then
            if InCombatLockdown() then return end
            -- При наличии врага может начаться бой, во время которого нельзя откатить привязку
            if UnitExists("softenemy") then
                ClearOverrideBindings(ConsoleMenu.StopCastingBindingFrame)
                ConsoleMenu:DeleteKeysFrameItem("PAD2", "Прервать")
                ConsoleMenu:UpdateKeysFrame()
            end
        elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
            if InCombatLockdown() then return end
            ClearOverrideBindings(ConsoleMenu.StopCastingBindingFrame)
            ConsoleMenu:DeleteKeysFrameItem("PAD2", "Прервать")
            ConsoleMenu:UpdateKeysFrame()
        end
    end)
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

-- Функция получения команды по идентификатору слота
function ConsoleMenu:GetBindingCommandBySlotID(slotID)
    local NUM_ACTIONBAR_BUTTONS = 12

    local abnormal = {
        [133] = "ACTIONBUTTON1",
        [134] = "ACTIONBUTTON2",
        [135] = "ACTIONBUTTON3",
        [136] = "ACTIONBUTTON4",
        [137] = "ACTIONBUTTON5",
        [138] = "ACTIONBUTTON6",
        [139] = "EXTRAACTIONBUTTON1", -- только если CPAPI.ExtraActionButtonID == 139
    }

    -- Приоритет: абнормальные ID
    if abnormal[slotID] then
        return abnormal[slotID]
    end

    local barID = math.ceil(slotID / NUM_ACTIONBAR_BUTTONS)
    local buttonID = (slotID - 1) % NUM_ACTIONBAR_BUTTONS + 1

    local barBindings = {
        [1] = "ACTIONBUTTON%d",
        [6] = "MULTIACTIONBAR1BUTTON%d",
        [5] = "MULTIACTIONBAR2BUTTON%d",
        [3] = "MULTIACTIONBAR3BUTTON%d",
        [4] = "MULTIACTIONBAR4BUTTON%d",
        [13] = "MULTIACTIONBAR5BUTTON%d",
        [14] = "MULTIACTIONBAR6BUTTON%d",
        [15] = "MULTIACTIONBAR7BUTTON%d",
    }

    -- Сопоставим barID по порядку:
    local bindingFormat
    if barBindings[barID] then
        bindingFormat = barBindings[barID]
    elseif barID >= 6 and barID <= 12 then
        -- Относятся к основной панели (pages 6–12 → ACTIONBUTTON)
        bindingFormat = "ACTIONBUTTON%d"
    else
        -- fallback на default
        bindingFormat = "ACTIONBUTTON%d"
    end

    local toggles = { GetActionBarToggles() }

    if not toggles[barID] and barID == GetActionBarPage() then
        bindingFormat = "ACTIONBUTTON%d"
    end

    return bindingFormat:format(buttonID)
end

--  Функция получения кнопки по идентификатору бинда
function ConsoleMenu:GetCommandBinding(bindingCommand)

    if not bindingCommand then return end

    local key1, key2 = GetBindingKey(bindingCommand)
    return key1
    
end