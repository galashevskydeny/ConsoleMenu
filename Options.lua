-- Options.lua
-- Настройки аддона через Settings API без вспомогательной библиотеки

local ConsoleMenu = _G.ConsoleMenu

if not ConsoleMenuDB then
    ConsoleMenuDB = {}
end

local hudDropdownOptions = { "Не влиять", "Скрыть" }
local windowStyleOptions = { "Обновленное", "Стандартное" }
local cvarDropdownOptions = { "По умолчанию", "Включить", "Выключить", "Не влиять" }
local cvarHideDropdownOptions = { "По умолчанию", "Скрыть", "Не влиять" }
local toggleOptions = { "Включено", "Отклюнено" }
local interactButtonMap = { "PAD1", "PAD2", "PAD3", "PAD4" }

local mainCategorySettings = {
    { name = "Вырез экрана MacBook Pro", variable = "enableMacBook", default = 1, tooltip = "Смещает элементы интерфейса вниз для MacBook Pro с вырезом экрана.", options = toggleOptions }
}

-- Основные элементы
local hudSettingsMainElements = {
    { name = "Отслеживание цели", variable = "hideObjectiveTracker", default = 1, tooltip = "Управляет отображением трекера заданий (ObjectiveTracker).", options = hudDropdownOptions },
    { name = "Оповещения о целях", variable = "hideObjectiveTrackerTopBannerFrame", default = 1, tooltip = "Управляет отображением баннера трекера заданий (ObjectiveTrackerTopBannerFrame).", options = hudDropdownOptions },
    { name = "Миникарта", variable = "hideMinimap", default = 2, tooltip = "Управляет отображением миникарты (Minimap).", options = hudDropdownOptions },
    { name = "Главное меню", variable = "hideMicroMenu", default = 2, tooltip = "Управляет отображением главного меню (MicroMenu).", options = hudDropdownOptions },
    { name = "Поиск группы", variable = "hideGroupFinderFrame", default = 2, tooltip = "Управляет отображением фрейма поиска группы (GroupFinderFrame).", options = hudDropdownOptions },
    { name = "Панель сумок", variable = "hideBagsBarsBar", default = 2, tooltip = "Управляет отображением панели сумок (BagsBarsBar).", options = hudDropdownOptions },
}

-- Рамки интерфейса
local hudSettingsFrames = {
    { name = "Игрок", variable = "hidePlayerFrame", default = 2, tooltip = "Управляет отображением фрейма игрока (PlayerFrame).", options = hudDropdownOptions },
    { name = "Цель и выделенная цель", variable = "hideTargetFrame", default = 2, tooltip = "Управляет отображением фрейма цели (TargetFrame).", options = hudDropdownOptions },
    { name = "Интерфейс группы", variable = "hideCompactPartyFrame", default = 2, tooltip = "Управляет отображением фрейма группы (CompactPartyFrame).", options = hudDropdownOptions },
    { name = "Интерфейс рейда", variable = "hideCompactRaidFrame", default = 2, tooltip = "Управляет отображением фрейма рейда (CompactRaidFrame).", options = hudDropdownOptions },
    { name = "Рамки боссов", variable = "hideBossTargetFrameContainer", default = 2, tooltip = "Управляет отображением контейнера фреймов боссов (BossTargetFrameContainer).", options = hudDropdownOptions },
}

-- Бой
local hudSettingsCombat = {
    { name = "Панель команд", variable = "hideActionBar", default = 2, tooltip = "Управляет отображением основной панели действий (ActionBar).", options = hudDropdownOptions },
    { name = "Панель питомца", variable = "hidePetActionBar", default = 2, tooltip = "Управляет отображением панели действий питомца (PetActionBar).", options = hudDropdownOptions },
    { name = "Индикатор заклинаний", variable = "hidePlayerCastingBarFrame", default = 2, tooltip = "Управляет отображением полосы заклинаний игрока (PlayerCastingBarFrame).", options = hudDropdownOptions },
    { name = "Индикатор стойки", variable = "hideStanceBar", default = 2, tooltip = "Управляет отображением панели стоек (StanceBar).", options = hudDropdownOptions },
    { name = "Положительные эффекты и ауры", variable = "hideBuffFrame", default = 2, tooltip = "Управляет отображением фрейма баффов (BuffFrame).", options = hudDropdownOptions },
    { name = "Негативные эффекты и ауры", variable = "hideDebuffFrame", default = 2, tooltip = "Управляет отображением фрейма дебаффов (DebuffFrame).", options = hudDropdownOptions },
    { name = "Доп. способности", variable = "hideZoneAbilityFrame", default = 2, tooltip = "Управляет отображением фрейма способностей зоны (ZoneAbilityFrame).", options = hudDropdownOptions },
    { name = "Усиление заклинаний", variable = "hideSpellActivationOverlay", default = 2, tooltip = "Управляет отображением эффектов усиления заклинаний (SpellActivationOverlay) персонажа.", options = hudDropdownOptions },
}

-- Разное
local hudSettingsMisc = {
    { name = "Название области", variable = "hideZoneTextFrame", default = 2, tooltip = "Управляет отображением фрейма текста зоны (ZoneTextFrame).", options = hudDropdownOptions },
    { name = "Предупреждения", variable = "hideAlertFrame", default = 2, tooltip = "Управляет отображением фрейма предупреждений (AlertFrame).", options = hudDropdownOptions },
    { name = "Ошибки", variable = "hideUIErrorsFrame", default = 2, tooltip = "Управляет отображением фрейма ошибок интерфейса (UIErrorsFrame).", options = hudDropdownOptions },
    { name = "Говорящая голова", variable = "hideTalkingHeadFrame", default = 2, tooltip = "Управляет отображением фрейма говорящей головы (TalkingHeadFrame).", options = hudDropdownOptions },
    { name = "Высший пилотаж", variable = "hideUIWidgetPowerBarContainerFrame", default = 2, tooltip = "Управляет отображением фрейма полета на драконе (UIWidgetPowerBarContainerFrame).", options = hudDropdownOptions },
    { name = "Окно добычи", variable = "hideLootFrame", default = 2, tooltip = "Управляет отображением фрейма лута (LootFrame).", options = hudDropdownOptions },
}

-- Геймплей
local hudSettingsGameplay = {
    { name = "Плавающие цифры", variable = "floatingText", default = 3, tooltip = "Плавающие цифры урона, лечения и других эффектов (threatShowNumeric, enableFloatingCombatText, floatingCombatTextCombatDamage).", options = cvarHideDropdownOptions },
    { name = "Имена персонажей и игроков", variable = "unitNames", default = 3, tooltip = "Отключает отображение имен персонажей, игроков, питомцев и других юнитов (UnitNameEnemyGuardianName и другие).", options = cvarDropdownOptions },
    { name = "Реплики персонажей над головой", variable = "chatBubble", default = 3, tooltip = "Отключает облака с субтитрами над головой персонажей и игроков (chatBubbles, chatBubblesParty).", options = cvarDropdownOptions },
    { name = "Подсветка квестодателя", variable = "qestCircle", default = 3, tooltip = "Отключает выделение под квестодателем (ShowQuestUnitCircles, ObjectSelectionCircle).", options = cvarDropdownOptions },
    { name = "Выделение персонажей и игроков", variable = "hideGraphicsOutlineMode", default = 2, tooltip = "Отключает режим контуров графики (graphicsOutlineMode).", options = cvarHideDropdownOptions },
}

local standardUISettings = {
    { name = "Окно персонажа", variable = "characterWindowStyle", default = 1, tooltip = "Выберите стиль окна персонажа: обновленную версию или стандартную.", options = windowStyleOptions },
    { name = "Окно почты", variable = "mailWindowStyle", default = 2, tooltip = "Выберите стиль окна почты: обновленную версию или стандартную.", options = windowStyleOptions },
    { name = "Окно торговца", variable = "merchantWindowStyle", default = 2, tooltip = "Выберите стиль окна торговца: обновленную версию или стандартную.", options = windowStyleOptions },
    { name = "Окна диалогов и квестов", variable = "dialogQuestWindowStyle", default = 1, tooltip = "Выберите стиль окна диалогов и квестов: обновленную (более имерсивную) версию или стандартную.", options = windowStyleOptions },
}

local keyBindingSettings = {
    { name = "Переопределять кнопку при наличии объекта взаимодействия", variable = "overrideInteractKey", default = 1, tooltip = "Если включено, основная кнопка автоматически использует действие взаимодействия при наличии объекта.", options = toggleOptions },
    { name = "Переопределять кнопку при наличии способности области", variable = "overrideZoneAbilityKey", default = 2, tooltip = "Если включено, выбранная кнопка автоматически использует способность области, если она доступна.", options = toggleOptions },
    { name = "Схема привязки контроллера", variable = "keyBindingScheme", default = 1, tooltip = "Выберите схему привязки игровых клавиш контроллера к действиям в игре.", options = { "Авторская", "Вручную" } },
    { name = "Вибрация контроллера", variable = "controllerVibration", default = 2, tooltip = "Управляет вибрацией контроллера при использовании способностей.", options = { "Нет", "При усилении активной способности" } },
}

local contextsSettings = {
    { name = "Переключение страниц панели команд", variable = "actionBarPageSwitching", default = 1, tooltip = "Управляет переключением страниц панели команд автоматически в зависимости от контекста игрока (в бою, на транспорте, при рассмотрении дружественного игрока и другие).", options = toggleOptions },
    { name = "Игнорировать противников при верховой езде", variable = "softTargetFlightSwitching", default = 1, tooltip = "Отключение Soft Target на противниках при верховой езде.", options = toggleOptions},
    { name = "Игнорировать противников в зонах святилищ", variable = "softTargetSanctuarySwitching", default = 1, tooltip = "Отключение Soft Target на противниках в святилищах.", options = toggleOptions},
    { name = "Малая дистанция обнаружения союзников", variable = "softTargetFriendSanctuaryRange", default = 1, tooltip = "Радиус фокусировки союзников в святилищах (SoftTargetFriendRange) 5 метров.", options = toggleOptions},
}

-- Используем библиотеку SettingsHelper
local ensureNumericChoice = SettingsHelper.ensureNumericChoice
local ensureDropdownDefaults = SettingsHelper.ensureDropdownDefaults
local registerDropdown = SettingsHelper.registerDropdown
local addReloadButton = SettingsHelper.addReloadButton

local function registerHUDOptions(category, layout)
    -- Основные элементы
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Основные элементы"))
    for _, setting in ipairs(hudSettingsMainElements) do
        registerDropdown(category, setting, function(value)
            ConsoleMenuDB[setting.variable] = value
        end)
    end

    -- Рамки интерфейса
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Рамки интерфейса"))
    for _, setting in ipairs(hudSettingsFrames) do
        registerDropdown(category, setting, function(value)
            ConsoleMenuDB[setting.variable] = value
        end)
    end

    -- Бой
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Бой"))
    for _, setting in ipairs(hudSettingsCombat) do
        registerDropdown(category, setting, function(value)
            ConsoleMenuDB[setting.variable] = value
        end)
    end

    -- Разное
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Разное"))
    for _, setting in ipairs(hudSettingsMisc) do
        registerDropdown(category, setting, function(value)
            ConsoleMenuDB[setting.variable] = value
        end)
    end

    -- Геймплей
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Геймплей"))
    for _, setting in ipairs(hudSettingsGameplay) do
        registerDropdown(category, setting, function(value)
            ConsoleMenuDB[setting.variable] = value
            if _G.ApplyCVarSettings then
                _G.ApplyCVarSettings()
            end
        end)
    end
end

local function registerStandardUIOptions(category, layout)
    for _, setting in ipairs(standardUISettings) do
        registerDropdown(category, setting, function(value)
            ConsoleMenuDB[setting.variable] = value
        end)
    end
end

local function registerContextsOptions(category, layout)
    registerDropdown(category, contextsSettings[1], function(value)
        ConsoleMenuDB[contextsSettings[1].variable] = value
    end)

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Исследование святилищ"))

    registerDropdown(category, contextsSettings[3], function(value)
        ConsoleMenuDB[contextsSettings[3].variable] = value
    end)

    registerDropdown(category, contextsSettings[4], function(value)
        ConsoleMenuDB[contextsSettings[4].variable] = value
    end)
    
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Верховая езда"))
    
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

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Способность области"))

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

local function registerMainOptions(category, layout)
    registerDropdown(category, mainCategorySettings[1], function(value)
        ConsoleMenuDB[mainCategorySettings[1].variable] = value
        if _G.ApplyCVarSettings then
            _G.ApplyCVarSettings()
        end
    end)

    addReloadButton(layout, "Применить изменения")
end

local function RegisterOptions()
    if not Settings then
        return false
    end

    local mainCategory, mainLayout = Settings.RegisterVerticalLayoutCategory("ConsoleMenu")
    registerMainOptions(mainCategory, mainLayout)

    local hudCategory, hudLayout = Settings.RegisterVerticalLayoutSubcategory(mainCategory, "Интерфейс")
    registerHUDOptions(hudCategory, hudLayout)

    local standardUICategory, standardUILayout = Settings.RegisterVerticalLayoutSubcategory(mainCategory, "Игровые окна")
    registerStandardUIOptions(standardUICategory, standardUILayout)

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
