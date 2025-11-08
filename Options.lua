-- Options.lua
-- Настройки аддона через Settings API без вспомогательной библиотеки

local ConsoleMenu = _G.ConsoleMenu

if not ConsoleMenuDB then
    ConsoleMenuDB = {}
end

local hudDropdownOptions = { "Показать", "Скрыть" }
local cvarDropdownOptions = { "По умолчанию", "Отключить", "Вручную" }
local macBookGraphicsDropdownOptions = { "По умолчанию", "Кастомные", "Вручную" }
local softTargetDropdownOptions = { "По умолчанию", "Для бойца", "Для танка", "Для лекаря", "Вручную" }

local hudSettings = {
    { name = "Панель действий", variable = "hideActionBar", default = 2, tooltip = "Управляет отображением основной панели действий (ActionBar).", options = hudDropdownOptions },
    { name = "Панель действий питомца", variable = "hidePetActionBar", default = 2, tooltip = "Управляет отображением панели действий питомца (PetActionBar).", options = hudDropdownOptions },
    { name = "Трекер заданий", variable = "hideObjectiveTracker", default = 1, tooltip = "Управляет отображением трекера заданий (ObjectiveTracker).", options = hudDropdownOptions },
    { name = "Баннер трекера заданий", variable = "hideObjectiveTrackerTopBannerFrame", default = 1, tooltip = "Управляет отображением баннера трекера заданий (ObjectiveTrackerTopBannerFrame).", options = hudDropdownOptions },
    { name = "Фрейм цели", variable = "hideTargetFrame", default = 2, tooltip = "Управляет отображением фрейма цели (TargetFrame).", options = hudDropdownOptions },
    { name = "Фрейм игрока", variable = "hidePlayerFrame", default = 2, tooltip = "Управляет отображением фрейма игрока (PlayerFrame).", options = hudDropdownOptions },
    { name = "Полоса заклинаний", variable = "hidePlayerCastingBarFrame", default = 2, tooltip = "Управляет отображением полосы заклинаний игрока (PlayerCastingBarFrame).", options = hudDropdownOptions },
    { name = "Миникарта", variable = "hideMinimap", default = 2, tooltip = "Управляет отображением миникарты (Minimap).", options = hudDropdownOptions },
    { name = "Главное меню", variable = "hideMicroMenu", default = 2, tooltip = "Управляет отображением главного меню (MicroMenu).", options = hudDropdownOptions },
    { name = "Поиск группы", variable = "hideGroupFinderFrame", default = 2, tooltip = "Управляет отображением фрейма поиска группы (GroupFinderFrame).", options = hudDropdownOptions },
    { name = "Панель сумок", variable = "hideBagsBarsBar", default = 2, tooltip = "Управляет отображением панели сумок (BagsBarsBar).", options = hudDropdownOptions },
    { name = "Текст зоны", variable = "hideZoneTextFrame", default = 2, tooltip = "Управляет отображением фрейма текста зоны (ZoneTextFrame).", options = hudDropdownOptions },
    { name = "Панель стоек", variable = "hideStanceBar", default = 2, tooltip = "Управляет отображением панели стоек (StanceBar).", options = hudDropdownOptions },
    { name = "Фрейм группы", variable = "hideCompactPartyFrame", default = 2, tooltip = "Управляет отображением фрейма группы (CompactPartyFrame).", options = hudDropdownOptions },
    { name = "Фрейм рейда", variable = "hideCompactRaidFrame", default = 2, tooltip = "Управляет отображением фрейма рейда (CompactRaidFrame).", options = hudDropdownOptions },
    { name = "Фрейм предупреждений", variable = "hideAlertFrame", default = 2, tooltip = "Управляет отображением фрейма предупреждений (AlertFrame).", options = hudDropdownOptions },
    { name = "Фрейм ошибок", variable = "hideUIErrorsFrame", default = 2, tooltip = "Управляет отображением фрейма ошибок интерфейса (UIErrorsFrame).", options = hudDropdownOptions },
    { name = "Говорящая голова", variable = "hideTalkingHeadFrame", default = 2, tooltip = "Управляет отображением фрейма говорящей головы (TalkingHeadFrame).", options = hudDropdownOptions },
    { name = "Панель полета", variable = "hideUIWidgetPowerBarContainerFrame", default = 2, tooltip = "Управляет отображением фрейма полета на драконе (UIWidgetPowerBarContainerFrame).", options = hudDropdownOptions },
    { name = "Окно добычи", variable = "hideLootFrame", default = 2, tooltip = "Управляет отображением фрейма лута (LootFrame).", options = hudDropdownOptions },
    { name = "Фрейм баффов", variable = "hideBuffFrame", default = 2, tooltip = "Управляет отображением фрейма баффов (BuffFrame).", options = hudDropdownOptions },
    { name = "Фрейм дебаффов", variable = "hideDebuffFrame", default = 2, tooltip = "Управляет отображением фрейма дебаффов (DebuffFrame).", options = hudDropdownOptions },
    { name = "Фрейм способностей зоны", variable = "hideZoneAbilityFrame", default = 2, tooltip = "Управляет отображением фрейма способностей зоны (ZoneAbilityFrame).", options = hudDropdownOptions },
    { name = "Контейнер фреймов боссов", variable = "hideBossTargetFrameContainer", default = 2, tooltip = "Управляет отображением контейнера фреймов боссов (BossTargetFrameContainer).", options = hudDropdownOptions },
}

local standardUISettings = {
    { name = "Окно персонажа", variable = "characterWindowStyle", default = 1, tooltip = "Выберите стиль окна персонажа: Современное или Стандартное.", options = { "Обновленное", "Стандартное" } },
    { name = "Окно почты", variable = "mailWindowStyle", default = 2, tooltip = "Выберите стиль окна почты: Обновленное или Стандартное.", options = { "Обновленное", "Стандартное" } },
    { name = "Окно торговца", variable = "merchantWindowStyle", default = 2, tooltip = "Выберите стиль окна торговца: Обновленное или Стандартное.", options = { "Обновленное", "Стандартное" } },
    { name = "Окна диалогов и квестов", variable = "dialogQuestWindowVisibility", default = 1, tooltip = "Показать или скрыть все стандартные окна диалогов и квестов.", options = { "Скрыть", "Показать" } },
}

local cvarSettings = {
    { name = "Плавающие цифры", variable = "hideFloatingText", default = 2, tooltip = "Отключает плавающие цифры урона и лечения (threatShowNumeric, enableFloatingCombatText, floatingCombatTextCombatDamage).", options = cvarDropdownOptions },
    { name = "Уведомления об онлайне в гильдии", variable = "hideGuildMemberNotification", default = 2, tooltip = "Отключает уведомления о входе/выходе членов гильдии из онлайна (guildMemberNotify).", options = cvarDropdownOptions },
    { name = "Реплики персонажей над головой", variable = "hideChatBubble", default = 2, tooltip = "Отключает облака с субтитрами над головой персонажей и игроков (chatBubbles, chatBubblesParty).", options = cvarDropdownOptions },
    { name = "Выделение квестодателя", variable = "hideQuestCircle", default = 2, tooltip = "Отключает выделение под квестодателем (ShowQuestUnitCircles, ObjectSelectionCircle).", options = cvarDropdownOptions },
    { name = "Отображение имен персонажей и игроков", variable = "hideUnitNames", default = 2, tooltip = "Отключает отображение имен персонажей, игроков, питомцев и других юнитов (UnitNameEnemyGuardianName и другие).", options = cvarDropdownOptions },
    { name = "Дополнительные параметры", variable = "enableBaseSettings", default = 2, tooltip = "Применяет дополнительные игровые настройки (autoLootDefault, autoQuestWatch, Sound_ZoneMusicNoDelay, showTutorials, nameplateShowSelf).", options = macBookGraphicsDropdownOptions },
    { name = "Настройки для MacBook Pro", variable = "enableMacBookGraphics", default = 3, tooltip = "Применяет настройки для MacBook Pro (NotchedDisplayMode, graphicsOutlineMode, useMaxFPS, useMaxFPSBk, useTargetFPS, Gamma, Contrast, Brightness).", options = macBookGraphicsDropdownOptions },
    { name = "Настройки SoftTarget", variable = "enableSoftTargetSettings", default = 2, tooltip = "Включает настройки мягкого выделения (SoftTargetFriend, SoftTargetIconInteract, SoftTargetFriendRange, SoftTargetForce, SoftTargetEnemy).", options = softTargetDropdownOptions },
}

local keyBindingSettings = {
    { name = "Переопределять кнопку при наличии объекта взаимодействия", variable = "overrideInteractKey", default = 1, tooltip = "Если включено, основная кнопка автоматически использует действие взаимодействия при наличии объекта.", options = { "Включить", "Выключить" } },
    { name = "Переопределять кнопку при наличии способности области", variable = "overrideZoneAbilityKey", default = 2, tooltip = "Если включено, выбранная кнопка автоматически использует способность области, если она доступна.", options = { "Включить", "Выключить" } },
    { name = "Схема привязки контроллера", variable = "keyBindingScheme", default = 1, tooltip = "Выберите схему привязки игровых клавиш контроллера к действиям в игре.", options = { "Авторская", "Вручную" } },
    { name = "Вибрация контроллера", variable = "controllerVibration", default = 2, tooltip = "Управляет вибрацией контроллера при использовании способностей.", options = { "Нет", "При усилении активной способности" } },
}

local contextsSettings = {
    { name = "Переключение страниц панели команд", variable = "actionBarPageSwitching", default = 1, tooltip = "Управляет переключением страниц панели команд автоматически в зависимости от контекста игрока (в бою, на транспорте, при рассмотрении дружественного игрока и другие).", options = { "Включено", "Выключено" } },
    { name = "Игнорировать противников (soft target)", variable = "softTargetFlightSwitching", default = 1, tooltip = "Отключение soft target на противниках при верховой езде.", options = { "Включено", "Выключено" } },
}

local interactButtonMap = { "PAD1", "PAD2", "PAD3", "PAD4" }

local function ensureNumericChoice(variable, defaultValue, maxValue)
    local value = ConsoleMenuDB[variable]

    if type(value) ~= "number" or value < 1 or value > maxValue then
        ConsoleMenuDB[variable] = defaultValue
        value = defaultValue
    end

    return value
end

local function ensureDropdownDefaults(setting)
    return ensureNumericChoice(setting.variable, setting.default, #setting.options)
end

local function registerDropdown(category, settingInfo, onValueChanged)
    ensureDropdownDefaults(settingInfo)

    local function getOptions()
        local container = Settings.CreateControlTextContainer()
        for index, optionName in ipairs(settingInfo.options) do
            container:Add(index, optionName)
        end
        return container:GetData()
    end

    local setting = Settings.RegisterAddOnSetting(
        category,
        "CONSOLEMENU_" .. settingInfo.variable:upper(),
        settingInfo.variable,
        ConsoleMenuDB,
        Settings.VarType.Number,
        settingInfo.name,
        settingInfo.default
    )

    if settingInfo.tooltip then
        setting.data = setting.data or {}
        setting.data.tooltip = settingInfo.tooltip
    end

    if onValueChanged then
        setting:SetValueChangedCallback(function(_, newValue)
            onValueChanged(newValue)
        end)
    end

    Settings.CreateDropdown(category, setting, getOptions, settingInfo.tooltip)
end

local function addReloadButton(layout, name)
    local initializer = CreateSettingsButtonInitializer(
        name,
        "Перезагрузить интерфейс",
        function()
            ReloadUI()
        end,
        "Перезагружает интерфейс игры (эквивалент команды /reload)",
        true
    )

    layout:AddInitializer(initializer)
end

local function registerHUDOptions(category, layout)
    for _, setting in ipairs(hudSettings) do
        registerDropdown(category, setting, function(value)
            ConsoleMenuDB[setting.variable] = value
        end)
    end

    addReloadButton(layout, "Применить изменения")
end

local function registerStandardUIOptions(category, layout)
    for _, setting in ipairs(standardUISettings) do
        registerDropdown(category, setting, function(value)
            ConsoleMenuDB[setting.variable] = value
        end)
    end

    addReloadButton(layout, "Применить изменения")
end

local function registerCVarOptions(category)
    for _, setting in ipairs(cvarSettings) do
        registerDropdown(category, setting, function(value)
            ConsoleMenuDB[setting.variable] = value
            if _G.ApplyCVarSettings then
                _G.ApplyCVarSettings()
            end
        end)
    end
end

local function registerContextsOptions(category, layout)
    -- Первая настройка
    registerDropdown(category, contextsSettings[1], function(value)
        ConsoleMenuDB[contextsSettings[1].variable] = value
    end)
    
    -- Заголовок "Верховая езда"
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Верховая езда"))
    
    -- Вторая настройка
    registerDropdown(category, contextsSettings[2], function(value)
        ConsoleMenuDB[contextsSettings[2].variable] = value
    end)
end

local function registerKeyBindingOptions(category, layout)
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Взаимодействие"))

    registerDropdown(category, keyBindingSettings[1], function(value)
        ConsoleMenuDB.overrideInteractKey = value
    end)

    local currentInteractButton = ConsoleMenuDB.interactButton
    if currentInteractButton == nil then
        ConsoleMenuDB.interactButton = 1
    elseif type(currentInteractButton) == "string" then
        local converted
        for index, label in ipairs(interactButtonMap) do
            if label == currentInteractButton then
                converted = index
                break
            end
        end
        ConsoleMenuDB.interactButton = converted or 1
    else
        ensureNumericChoice("interactButton", 1, #interactButtonMap)
    end

    ConsoleMenuDB.interactButtonString = interactButtonMap[ConsoleMenuDB.interactButton]

    registerDropdown(
        category,
        {
            name = "Кнопка взаимодействия",
            variable = "interactButton",
            default = ConsoleMenuDB.interactButton,
            tooltip = "Выберите, какая кнопка будет использоваться для взаимодействия с объектами.",
            options = interactButtonMap,
        },
        function(value)
            ConsoleMenuDB.interactButton = value
            ConsoleMenuDB.interactButtonString = interactButtonMap[value]
        end
    )

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Способность зоны (области)"))

    registerDropdown(category, keyBindingSettings[2], function(value)
        ConsoleMenuDB.overrideZoneAbilityKey = value
        if ConsoleMenu and ConsoleMenu.SetBindingsZoneAbility then
            ConsoleMenu:SetBindingsZoneAbility()
        end
    end)

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Игровой контроллер"))

    registerDropdown(category, keyBindingSettings[3], function(value)
        ConsoleMenuDB.keyBindingScheme = value
        if ConsoleMenu and ConsoleMenu.SetBaseKeyBindings then
            ConsoleMenu:SetBaseKeyBindings()
        end
    end)

    registerDropdown(category, keyBindingSettings[4], function(value)
        ConsoleMenuDB.controllerVibration = value
    end)

    local clearBindingsInitializer = CreateSettingsButtonInitializer(
        "Очистить привязки контроллера",
        "Очистить привязки",
        function()
            if ConsoleMenu and ConsoleMenu.ClearControllerBindings then
                ConsoleMenu:ClearControllerBindings()
            end
        end,
        "Очищает все привязки клавиш контроллера.",
        true
    )

    layout:AddInitializer(clearBindingsInitializer)
end

local function RegisterOptions()
    if not Settings then
        return false
    end

    local mainCategory, mainLayout = Settings.RegisterVerticalLayoutCategory("ConsoleMenu")

    local hudCategory, hudLayout = Settings.RegisterVerticalLayoutSubcategory(mainCategory, "Стандартный HUD")
    registerHUDOptions(hudCategory, hudLayout)

    local standardUICategory, standardUILayout = Settings.RegisterVerticalLayoutSubcategory(mainCategory, "Стандартный UI")
    registerStandardUIOptions(standardUICategory, standardUILayout)

    local cvarsCategory = Settings.RegisterVerticalLayoutSubcategory(mainCategory, "Изменение CVars")
    registerCVarOptions(cvarsCategory)

    local keyBindingsCategory, keyBindingsLayout = Settings.RegisterVerticalLayoutSubcategory(mainCategory, "Настройка клавиш")
    registerKeyBindingOptions(keyBindingsCategory, keyBindingsLayout)

    local contextsCategory, contextsLayout = Settings.RegisterVerticalLayoutSubcategory(mainCategory, "Контексты")
    registerContextsOptions(contextsCategory, contextsLayout)

    Settings.RegisterAddOnCategory(mainCategory)

    return true
end

local function InitializeOptions()
    if Settings then
        RegisterOptions()
    else
        local frame = CreateFrame("Frame")
        frame:RegisterEvent("ADDON_LOADED")
        frame:SetScript("OnEvent", function(self, _, addonName)
            if (addonName == "Blizzard_Options" or addonName == "Blizzard_ClientSavedVariables") and Settings then
                RegisterOptions()
                self:UnregisterEvent("ADDON_LOADED")
            end
        end)

        if C_Timer then
            C_Timer.After(1, function()
                if Settings then
                    RegisterOptions()
                end
            end)
        end
    end
end

ConsoleMenu.InitializeOptions = InitializeOptions
