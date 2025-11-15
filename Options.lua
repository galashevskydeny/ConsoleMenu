-- Options.lua
-- Настройки аддона через Settings API без вспомогательной библиотеки

local ConsoleMenu = _G.ConsoleMenu

if not ConsoleMenuDB then
    ConsoleMenuDB = {}
end

local hudDropdownOptions = { "Не влиять", "Скрыть" }
local hudUpdateDropdownOptions = { "Обновленный", "Стандартный", "Стандартный (скрываемый)" }
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
    { name = "Миникарта", variable = "hideMinimap", default = 1, tooltip = "Управляет отображением миникарты (Minimap).", options = hudDropdownOptions },
    { name = "Главное меню", variable = "hideMicroMenu", default = 1, tooltip = "Управляет отображением главного меню (MicroMenu).", options = hudDropdownOptions },
    { name = "Поиск группы", variable = "hideGroupFinderFrame", default = 1, tooltip = "Управляет отображением фрейма поиска группы (GroupFinderFrame).", options = hudDropdownOptions },
    { name = "Панель сумок", variable = "hideBagsBarsBar", default = 1, tooltip = "Управляет отображением панели сумок (BagsBarsBar).", options = hudDropdownOptions },
}

-- Рамки интерфейса
local hudSettingsFrames = {
    { name = "Игрок", variable = "hidePlayerFrame", default = 1, tooltip = "Управляет отображением фрейма игрока (PlayerFrame).", options = hudUpdateDropdownOptions },
    { name = "Цель и выделенная цель", variable = "hideTargetFrame", default = 1, tooltip = "Управляет отображением фрейма цели (TargetFrame).", options = hudDropdownOptions },
    { name = "Интерфейс группы", variable = "hideCompactPartyFrame", default = 1, tooltip = "Управляет отображением фрейма группы (CompactPartyFrame).", options = hudDropdownOptions },
    { name = "Интерфейс рейда", variable = "hideCompactRaidFrame", default = 1, tooltip = "Управляет отображением фрейма рейда (CompactRaidFrame).", options = hudDropdownOptions },
    { name = "Рамки боссов", variable = "hideBossTargetFrameContainer", default = 1, tooltip = "Управляет отображением контейнера фреймов боссов (BossTargetFrameContainer).", options = hudDropdownOptions },
}

-- Бой
local hudSettingsCombat = {
    { name = "Вид индикатора здоровья", variable = "enemyNameplateStyle", default = 2, tooltip = "Управляет видом полосы здоровья противников (Nameplate).", options = windowStyleOptions },
    { name = "Вид панели команд", variable = "actionBarStyle", default = 1, tooltip = "Управляет отображением основной панели действий (ActionBar).", options = hudUpdateDropdownOptions },
    { name = "Панель питомца", variable = "hidePetActionBar", default = 1, tooltip = "Управляет отображением панели действий питомца (PetActionBar).", options = hudDropdownOptions },
    { name = "Индикатор заклинаний", variable = "hidePlayerCastingBarFrame", default = 1, tooltip = "Управляет отображением полосы заклинаний игрока (PlayerCastingBarFrame).", options = hudDropdownOptions },
    { name = "Индикатор стойки", variable = "hideStanceBar", default = 1, tooltip = "Управляет отображением панели стоек (StanceBar).", options = hudDropdownOptions },
    { name = "Положительные эффекты и ауры", variable = "hideBuffFrame", default = 1, tooltip = "Управляет отображением фрейма баффов (BuffFrame).", options = hudDropdownOptions },
    { name = "Негативные эффекты и ауры", variable = "hideDebuffFrame", default = 1, tooltip = "Управляет отображением фрейма дебаффов (DebuffFrame).", options = hudDropdownOptions },
    { name = "Доп. способности", variable = "hideZoneAbilityFrame", default = 1, tooltip = "Управляет отображением фрейма способностей зоны (ZoneAbilityFrame).", options = hudDropdownOptions },
    { name = "Усиление заклинаний", variable = "hideSpellActivationOverlay", default = 1, tooltip = "Управляет отображением эффектов усиления заклинаний (SpellActivationOverlay) персонажа.", options = hudDropdownOptions },
}

-- Разное
local hudSettingsMisc = {
    { name = "Название области", variable = "hideZoneTextFrame", default = 1, tooltip = "Управляет отображением фрейма текста зоны (ZoneTextFrame).", options = hudDropdownOptions },
    { name = "Предупреждения", variable = "hideAlertFrame", default = 1, tooltip = "Управляет отображением фрейма предупреждений (AlertFrame).", options = hudDropdownOptions },
    { name = "Ошибки", variable = "hideUIErrorsFrame", default = 1, tooltip = "Управляет отображением фрейма ошибок интерфейса (UIErrorsFrame).", options = hudDropdownOptions },
    { name = "Говорящая голова", variable = "hideTalkingHeadFrame", default = 1, tooltip = "Управляет отображением фрейма говорящей головы (TalkingHeadFrame).", options = hudDropdownOptions },
    { name = "Высший пилотаж", variable = "hideUIWidgetPowerBarContainerFrame", default = 1, tooltip = "Управляет отображением фрейма полета на драконе (UIWidgetPowerBarContainerFrame).", options = hudDropdownOptions },
    { name = "Окно добычи", variable = "hideLootFrame", default = 1, tooltip = "Управляет отображением фрейма лута (LootFrame).", options = hudDropdownOptions },
}

-- Геймплей
local hudSettingsGameplay = {
    { name = "Плавающие цифры", variable = "floatingText", default = 3, tooltip = "Плавающие цифры урона, лечения и других эффектов (threatShowNumeric, enableFloatingCombatText, floatingCombatTextCombatDamage).", options = cvarHideDropdownOptions },
    { name = "Имена персонажей и игроков", variable = "unitNames", default = 3, tooltip = "Отключает отображение имен персонажей, игроков, питомцев и других юнитов (UnitNameEnemyGuardianName и другие).", options = cvarHideDropdownOptions },
    { name = "Реплики персонажей над головой", variable = "chatBubble", default = 4, tooltip = "Отключает облака с субтитрами над головой персонажей и игроков (chatBubbles, chatBubblesParty).", options = cvarDropdownOptions },
    { name = "Подсветка квестодателя", variable = "qestCircle", default = 4, tooltip = "Выделение квестодателя при взаимодействии в геймплее (ShowQuestUnitCircles, ObjectSelectionCircle).", options = cvarDropdownOptions },
    { name = "Выделение персонажей и игроков", variable = "hideGraphicsOutlineMode", default = 3, tooltip = "Отключает режим контуров графики (graphicsOutlineMode).", options = cvarHideDropdownOptions },
}

local standardUISettings = {
    { name = "Окно персонажа", variable = "characterWindowStyle", default = 2, tooltip = "Выберите стиль окна персонажа: обновленную версию или стандартную.", options = windowStyleOptions },
    { name = "Окно почты", variable = "mailWindowStyle", default = 2, tooltip = "Выберите стиль окна почты: обновленную версию или стандартную.", options = windowStyleOptions },
    { name = "Окно торговца", variable = "merchantWindowStyle", default = 2, tooltip = "Выберите стиль окна торговца: обновленную версию или стандартную.", options = windowStyleOptions },
    { name = "Окна диалогов и квестов", variable = "dialogQuestWindowStyle", default = 2, tooltip = "Выберите стиль окна диалогов и квестов: обновленную (более имерсивную) версию или стандартную.", options = windowStyleOptions },
    { name = "Окно чата", variable = "chatWindowStyle", default = 2, tooltip = "Выберите стиль окна чата: обновленную версию (скрытую по умолчанию в центре экрана) или стандартную.", options = windowStyleOptions },
}

local keyBindingSettings = {
    { name = "Переопределять кнопку при наличии объекта взаимодействия", variable = "overrideInteractKey", default = 1, tooltip = "Если включено, основная кнопка автоматически использует действие взаимодействия при наличии объекта.", options = toggleOptions },
    { name = "Переопределять кнопку при наличии способности области", variable = "overrideZoneAbilityKey", default = 2, tooltip = "Если включено, выбранная кнопка автоматически использует способность области, если она доступна.", options = toggleOptions },
    { name = "Схема привязки контроллера", variable = "keyBindingScheme", default = 2, tooltip = "Выберите схему привязки игровых клавиш контроллера к действиям в игре.", options = { "Авторская", "Вручную" } },
    { name = "Вибрация контроллера", variable = "controllerVibration", default = 2, tooltip = "Управляет вибрацией контроллера при использовании способностей.", options = { "Нет", "При усилении активной способности" } },
    { name = "Макросы панели исследования", variable = "actionBarPageExploring", default = 2, tooltip = "Устанавливает фиксированный набор преднастроенных макросов для панели исследования открытого мира.", options = toggleOptions },  
    { name = "Макросы панели общения с игроком", variable = "actionBarPagePlayerInteraction", default = 2, tooltip = "Устанавливает фиксированный набор преднастроенных макросов для панели общения с игроком.", options = toggleOptions },
    { name = "Макросы панели верховой езды", variable = "actionBarPageMount", default = 2, tooltip = "Устанавливает фиксированный набор преднастроенных макросов для панели верховой езды.", options = toggleOptions },
    { name = "Способности и макросы панели полета на драконе", variable = "actionBarPageDragonriding", default = 2, tooltip = "Устанавливает фиксированный набор преднастроенных способностей и макросов для панели полета на драконе.", options = toggleOptions }, 
}

local contextsSettings = {
    { name = "Переключение страниц панели команд", variable = "actionBarPageSwitching", default = 2, tooltip = "Управляет переключением страниц панели команд автоматически в зависимости от контекста игрока (в бою, на транспорте, при рассмотрении дружественного игрока и другие).", options = toggleOptions },
    { name = "Игнорировать противников при верховой езде", variable = "softTargetFlightSwitching", default = 2, tooltip = "Отключение Soft Target на противниках при верховой езде.", options = toggleOptions},
    { name = "Игнорировать противников в зонах святилищ", variable = "softTargetSanctuarySwitching", default = 2, tooltip = "Отключение Soft Target на противниках в святилищах.", options = toggleOptions},
    { name = "Малая дистанция обнаружения союзников", variable = "softTargetFriendSanctuaryRange", default = 2, tooltip = "Радиус фокусировки союзников в святилищах 5 метров (SoftTargetFriendRange).", options = toggleOptions},
}

local questSettings = {
    { name = "Автом. переключение активного задания (Super Track)", variable = "questSuperTrackEnable", default = 2, tooltip = "Автоматическое переключение активного задания (Super Track).", options = toggleOptions },
    { name = "Первый незавершенный квест", variable = "questAutoSelectFirstIncomplete", default = 2, tooltip = "Выбрать первый незавершенный квест из журнала заданий, если не было выбрано задание из цепочки предыдущего задания.", options = toggleOptions },
    { name = "Фокус на локальных заданиях", variable = "questFocusLocalQuests", default = 2, tooltip = "Автоматически выбирать локальные задания при вхождении в область их выполнения с последующим возвратом предыдущего задания (если оно было выбрано).", options = toggleOptions },
}

-- Используем библиотеку SettingsHelper
local ensureNumericChoice = SettingsHelper.ensureNumericChoice
local ensureDropdownDefaults = SettingsHelper.ensureDropdownDefaults
local registerDropdown = SettingsHelper.registerDropdown
local addReloadButton = SettingsHelper.addReloadButton
local registerKeyBindingPicker = SettingsHelper.registerKeyBindingPicker

local function registerMainOptions(category, layout)
    registerDropdown(category, mainCategorySettings[1], function(value)
        ConsoleMenuDB.enableMacBook = value
        if _G.ApplyCVarSettings then
            _G.ApplyCVarSettings()
        end
    end)

    addReloadButton(layout, "Применить изменения")
end

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

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Исследование открытого мира"))

    registerDropdown(category, keyBindingSettings[5], function(value)
        ConsoleMenuDB[keyBindingSettings[5].variable] = value
        if _G.ApplyMacroSettings then
            _G.ApplyMacroSettings()
        end
    end)

    registerDropdown(category, keyBindingSettings[6], function(value)
        ConsoleMenuDB[keyBindingSettings[6].variable] = value
        if _G.ApplyMacroSettings then
            _G.ApplyMacroSettings()
        end
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

    registerDropdown(category, keyBindingSettings[7], function(value)
        ConsoleMenuDB[keyBindingSettings[7].variable] = value
        if _G.ApplyMacroSettings then
            _G.ApplyMacroSettings()
        end
    end)

    registerDropdown(category, keyBindingSettings[8], function(value)
        ConsoleMenuDB[keyBindingSettings[8].variable] = value
        if _G.ApplyMacroSettings then
            _G.ApplyMacroSettings()
        end
    end)

end

local function registerKeyBindingOptions(category, layout)
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Взаимодействие"))

    registerDropdown(category, keyBindingSettings[1], function(value)
        ConsoleMenuDB[keyBindingSettings[1].variable] = value
    end)

    registerKeyBindingPicker(
        category,
        layout,
        {
            name = "Клавиша для взаимодействия",
            variable = "interactButton",
            defaultKey = "PAD1",
            tooltip = "Выберите, какая кнопка будет использоваться для взаимодействия с объектами.",
        },
        function(newKey)
            ConsoleMenuDB.interactButton = newKey
        end
    )

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Способность области"))

    registerDropdown(category, keyBindingSettings[2], function(value)
        ConsoleMenuDB[keyBindingSettings[2].variable] = value
        if ConsoleMenu and ConsoleMenu.SetBindingsZoneAbility then
            ConsoleMenu:SetBindingsZoneAbility()
        end
    end)

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Игровой контроллер"))

    registerDropdown(category, keyBindingSettings[3], function(value)
        ConsoleMenuDB[keyBindingSettings[3].variable] = value
        if ConsoleMenu and ConsoleMenu.SetBaseKeyBindings then
            ConsoleMenu:SetBaseKeyBindings()
        end
    end)

    registerDropdown(category, keyBindingSettings[4], function(value)
        ConsoleMenuDB[keyBindingSettings[4].variable] = value
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

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Страницы и макросы"))

    registerDropdown(category, keyBindingSettings[5], function(value)
        ConsoleMenuDB[keyBindingSettings[5].variable] = value
        if _G.ApplyMacroSettings then
            _G.ApplyMacroSettings()
        end
    end)

    registerDropdown(category, keyBindingSettings[6], function(value)
        ConsoleMenuDB[keyBindingSettings[6].variable] = value
        if _G.ApplyMacroSettings then
            _G.ApplyMacroSettings()
        end
    end)

    registerDropdown(category, keyBindingSettings[7], function(value)
        ConsoleMenuDB[keyBindingSettings[7].variable] = value
        if _G.ApplyMacroSettings then
            _G.ApplyMacroSettings()
        end
    end)

    registerDropdown(category, keyBindingSettings[8], function(value)
        ConsoleMenuDB[keyBindingSettings[8].variable] = value
        if _G.ApplyMacroSettings then
            _G.ApplyMacroSettings()
        end
    end)

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Чат"))

    registerKeyBindingPicker(
        category,
        layout,
        {
            name = "Показать / скрыть чат",
            variable = "selectedChatButtonKey",
            defaultKey = "PAD5",
            tooltip = "Установить клавишу открытия чата. Нажмите кнопку и выберите клавишу.",
        },
        function(newKey)
            ConsoleMenuDB.selectedChatButtonKey = newKey
            -- Обновляем биндинг при изменении клавиши
            if ConsoleMenu and ConsoleMenu.SetupChatKeyBinding then
                ConsoleMenu:SetupChatKeyBinding()
            end
        end
    )
    
end

local function registerQuestOptions(category, layout)
    for _, setting in ipairs(questSettings) do
        registerDropdown(category, setting, function(value)
            ConsoleMenuDB[setting.variable] = value
        end)
    end
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

    local questCategory, questLayout = Settings.RegisterVerticalLayoutSubcategory(mainCategory, "Задания")
    registerQuestOptions(questCategory, questLayout)

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
