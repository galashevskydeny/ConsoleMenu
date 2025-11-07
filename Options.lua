-- Options.lua
-- Настройки аддона через InterfaceSettingsLib

local ConsoleMenu = _G.ConsoleMenu

-- Инициализация базы данных настроек
if not ConsoleMenuDB then
    ConsoleMenuDB = {}
end

-- Определения настроек для раздела "Стандартный HUD" (1 = "Показать", 2 = "Скрыть")
local hudSettings = {
    { name = "Панель действий", variable = "hideActionBar", default = 2, tooltip = "Управляет отображением основной панели действий (ActionBar)." },
    { name = "Панель действий питомца", variable = "hidePetActionBar", default = 2, tooltip = "Управляет отображением панели действий питомца (PetActionBar)." },
    { name = "Трекер заданий", variable = "hideObjectiveTracker", default = 2, tooltip = "Управляет отображением трекера заданий (ObjectiveTracker)." },
    { name = "Баннер трекера заданий", variable = "hideObjectiveTrackerTopBannerFrame", default = 2, tooltip = "Управляет отображением баннера трекера заданий (ObjectiveTrackerTopBannerFrame)." },
    { name = "Фрейм цели", variable = "hideTargetFrame", default = 2, tooltip = "Управляет отображением фрейма цели (TargetFrame)." },
    { name = "Фрейм игрока", variable = "hidePlayerFrame", default = 2, tooltip = "Управляет отображением фрейма игрока (PlayerFrame)." },
    { name = "Полоса заклинаний", variable = "hidePlayerCastingBarFrame", default = 2, tooltip = "Управляет отображением полосы заклинаний игрока (PlayerCastingBarFrame)." },
    { name = "Миникарта", variable = "hideMinimap", default = 2, tooltip = "Управляет отображением миникарты (Minimap)." },
    { name = "Главное меню", variable = "hideMicroMenu", default = 2, tooltip = "Управляет отображением главного меню (MicroMenu)." },
    { name = "Поиск группы", variable = "hideGroupFinderFrame", default = 2, tooltip = "Управляет отображением фрейма поиска группы (GroupFinderFrame)." },
    { name = "Панель сумок", variable = "hideBagsBarsBar", default = 2, tooltip = "Управляет отображением панели сумок (BagsBarsBar)." },
    { name = "Текст зоны", variable = "hideZoneTextFrame", default = 2, tooltip = "Управляет отображением фрейма текста зоны (ZoneTextFrame)." },
    { name = "Панель стоек", variable = "hideStanceBar", default = 2, tooltip = "Управляет отображением панели стоек (StanceBar)." },
    { name = "Фрейм группы", variable = "hideCompactPartyFrame", default = 2, tooltip = "Управляет отображением фрейма группы (CompactPartyFrame)." },
    { name = "Фрейм рейда", variable = "hideCompactRaidFrame", default = 2, tooltip = "Управляет отображением фрейма рейда (CompactRaidFrame)." },
    { name = "Фрейм предупреждений", variable = "hideAlertFrame", default = 2, tooltip = "Управляет отображением фрейма предупреждений (AlertFrame)." },
    { name = "Фрейм ошибок", variable = "hideUIErrorsFrame", default = 2, tooltip = "Управляет отображением фрейма ошибок интерфейса (UIErrorsFrame)." },
    { name = "Говорящая голова", variable = "hideTalkingHeadFrame", default = 2, tooltip = "Управляет отображением фрейма говорящей головы (TalkingHeadFrame)." },
    { name = "Панель полета", variable = "hideUIWidgetPowerBarContainerFrame", default = 2, tooltip = "Управляет отображением фрейма полета на драконе (UIWidgetPowerBarContainerFrame)." },
    { name = "Окно добычи", variable = "hideLootFrame", default = 2, tooltip = "Управляет отображением фрейма лута (LootFrame)." },
    { name = "Фрейм баффов", variable = "hideBuffFrame", default = 2, tooltip = "Управляет отображением фрейма баффов (BuffFrame)." },
    { name = "Фрейм дебаффов", variable = "hideDebuffFrame", default = 2, tooltip = "Управляет отображением фрейма дебаффов (DebuffFrame)." },
    { name = "Фрейм способностей зоны", variable = "hideZoneAbilityFrame", default = 2, tooltip = "Управляет отображением фрейма способностей зоны (ZoneAbilityFrame)." },
    { name = "Контейнер фреймов боссов", variable = "hideBossTargetFrameContainer", default = 2, tooltip = "Управляет отображением контейнера фреймов боссов (BossTargetFrameContainer)." },
}

-- Опции для dropdown HUD (1 = "Показать", 2 = "Скрыть")
local hudDropdownOptions = {"Показать", "Скрыть"}

-- Опции для dropdown CVars (1 = "По умолчанию", 2 = "Отключить", 3 = "Вручную")
local cvarDropdownOptions = {"По умолчанию", "Отключить", "Вручную"}

-- Опции для dropdown MacBook Graphics (1 = "По умолчанию", 2 = "Кастомные", 3 = "Вручную")
local macBookGraphicsDropdownOptions = {"По умолчанию", "Кастомные", "Вручную"}

-- Опции для dropdown SoftTarget (1 = "По умолчанию", 2 = "Для бойца", 3 = "Для танка", 4 = "Для лекаря", 5 = "Вручную")
local softTargetDropdownOptions = {"По умолчанию", "Для бойца", "Для танка", "Для лекаря", "Вручную"}

-- Определения настроек для раздела "Изменение CVars"
local cvarSettings = {
    { name = "Плавающие цифры", variable = "hideFloatingText", default = 2, tooltip = "Отключает плавающие цифры урона и лечения (threatShowNumeric, enableFloatingCombatText, floatingCombatTextCombatDamage)." },
    { name = "Уведомления об онлайне в гильдии", variable = "hideGuildMemberNotification", default = 2, tooltip = "Отключает уведомления о входе/выходе членов гильдии из онлайна (guildMemberNotify)." },
    { name = "Реплики персонажей над головой", variable = "hideChatBubble", default = 2, tooltip = "Отключает облака с субтитрами над головой персонажей и игроков (chatBubbles, chatBubblesParty)." },
    { name = "Выделение квестодателя", variable = "hideQuestCircle", default = 2, tooltip = "Отключает выделение под квестодателем (ShowQuestUnitCircles, ObjectSelectionCircle)." },
    { name = "Отображение имен персонажей и игроков", variable = "hideUnitNames", default = 2, tooltip = "Отключает отображение имен персонажей, игроков, питомцев и других юнитов (UnitNameEnemyGuardianName, UnitNameEnemyMinionName, UnitNameEnemyPetName, UnitNameEnemyPlayerName, UnitNameEnemyTotemName, UnitNameFriendlyGuardianName, UnitNameFriendlyMinionName, UnitNameFriendlyPetName, UnitNameFriendlyPlayerName, UnitNameFriendlySpecialNPCName, UnitNameFriendlyTotemName, UnitNameGuildTitle, UnitNameHostleNPC, UnitNameInteractiveNPC)." },
    { name = "Дополнительные параметры", variable = "enableBaseSettings", default = 2, tooltip = "Применяет дополнительные игровые настройки (autoLootDefault, autoQuestWatch, Sound_ZoneMusicNoDelay, showTutorials, nameplateShowSelf)." },
    { name = "Настройки для MacBook Pro", variable = "enableMacBookGraphics", default = 2, tooltip = "Применяет настройки для MacBook Pro (NotchedDisplayMode, graphicsOutlineMode, useMaxFPS, useMaxFPSBk, useTargetFPS, Gamma, Contrast, Brightness)." },
    { name = "Настройки SoftTarget", variable = "enableSoftTargetSettings", default = 2, tooltip = "Включает настройки мягкого выделения для бойца (SoftTargetFriend, SoftTargetNameplateEnemy, SoftTargetIconInteract, SoftTargetFriendRange, SoftTargetForce, SoftTargetEnemy)." },
}

-- Регистрация настроек
local function RegisterOptions()
    if not InterfaceSettingsLib or not Settings then
        return false
    end

    local ISL = InterfaceSettingsLib

    -- Создаем основную категорию
    local MainCategory, MainLayout = ISL:CreateCategory("ConsoleMenu")

    -- Создаем подкатегорию "Отключение HUD"
    local HUDSubcategory, HUDLayout = ISL:CreateSubcategory(MainCategory, "Стандартный HUD")

    -- Регистрируем настройки HUD (dropdown)
    for _, setting in ipairs(hudSettings) do
        -- Убеждаемся, что значение в ConsoleMenuDB соответствует одному из индексов опций (1 или 2)
        local currentValue = ConsoleMenuDB[setting.variable]
        if currentValue == nil then
            ConsoleMenuDB[setting.variable] = setting.default
        elseif type(currentValue) ~= "number" or (currentValue ~= 1 and currentValue ~= 2) then
            -- Если значение невалидное, сбрасываем на дефолт
            ConsoleMenuDB[setting.variable] = setting.default
        end
        
        -- Убеждаемся, что значение точно установлено перед регистрацией
        currentValue = ConsoleMenuDB[setting.variable]
        if type(currentValue) ~= "number" or (currentValue ~= 1 and currentValue ~= 2) then
            ConsoleMenuDB[setting.variable] = setting.default
        end
        
        ISL:MakeDropdown(
            HUDSubcategory,
            setting.name,
            setting.variable,
            setting.default,
            setting.tooltip,
            hudDropdownOptions,
            ConsoleMenuDB,
            function(_, value)
                ConsoleMenuDB[setting.variable] = value
                -- Применяем изменения HUD на основе обновленных значений в ConsoleMenuDB
                if ConsoleMenu.HideBlizzardUI then
                    ConsoleMenu:HideBlizzardUI()
                end
            end
        )
    end

    -- Добавляем кнопку перезагрузки интерфейса в подкатегорию HUD
    ISL:CreateButton(
        HUDSubcategory,
        "Применить изменения",
        "Перезагрузить интерфейс",
        function()
            ReloadUI()
        end,
        "Перезагружает интерфейс игры (эквивалент команды /reload)",
        false
    )

    -- Создаем подкатегорию "Стандартный UI"
    local StandardUISubcategory, StandardUILayout = ISL:CreateSubcategory(MainCategory, "Стандартный UI")

    -- Добавляем dropdown для выбора окна персонажа: Современное или Стандартное
    -- Убедимся, что значение валидно (1 или 2)
    if ConsoleMenuDB.characterWindowStyle == nil or (ConsoleMenuDB.characterWindowStyle ~= 1 and ConsoleMenuDB.characterWindowStyle ~= 2) then
        ConsoleMenuDB.characterWindowStyle = 1 -- Современное по умолчанию
    end

    ISL:MakeDropdown(
        StandardUISubcategory,
        "Окно персонажа",
        "characterWindowStyle",
        1,
        "Выберите стиль окна персонажа: Современное или Стандартное.",
        { "Обновленное", "Стандартное" },
        ConsoleMenuDB,
        function(_, value)
            ConsoleMenuDB["characterWindowStyle"] = value
        end
    )


    -- Добавляем dropdown для выбора окна почты: Обновленное или Стандартное
    ISL:MakeDropdown(
        StandardUISubcategory,
        "Окно почты",
        "mailWindowStyle",
        1,
        "Выберите стиль окна почты: Обновленное или Стандартное.",
        { "Обновленное", "Стандартное" },
        ConsoleMenuDB,
        function(_, value)
            ConsoleMenuDB["mailWindowStyle"] = value
        end
    )

    -- Добавляем dropdown для выбора окна торговца: Обновленное или Стандартное
    ISL:MakeDropdown(
        StandardUISubcategory,
        "Окно торговца",
        "merchantWindowStyle",
        1,
        "Выберите стиль окна торговца: Обновленное или Стандартное.",
        { "Обновленное", "Стандартное" },
        ConsoleMenuDB,
        function(_, value)
            ConsoleMenuDB["merchantWindowStyle"] = value
        end
    )

    -- Добавляем dropdown для выбора отображения окон диалогов и квестов: скрыть или показать
    ISL:MakeDropdown(
        StandardUISubcategory,
        "Окна диалогов и квестов",
        "dialogQuestWindowVisibility",
        1,
        "Показать или скрыть все стандартные окна диалогов и квестов.",
        { "Скрыть", "Показать" },
        ConsoleMenuDB,
        function(_, value)
            ConsoleMenuDB["dialogQuestWindowVisibility"] = value
        end
    )


    -- Добавляем кнопку перезагрузки интерфейса на страницу "Стандартный UI"
    ISL:CreateButton(
        StandardUISubcategory,
        "Применить изменения",
        "Перезагрузить интерфейс",
        function()
            ReloadUI()
        end,
        "Перезагружает интерфейс игры (эквивалент команды /reload)",
        false
    )

    -- Создаем подкатегорию "Изменение CVars"
    local CVarsSubcategory, CVarsLayout = ISL:CreateSubcategory(MainCategory, "Изменение CVars")

    -- Регистрируем настройки CVars (dropdown)
    for _, setting in ipairs(cvarSettings) do
        -- Используем специальные опции для разных настроек
        local dropdownOptions
        if setting.variable == "enableSoftTargetSettings" then
            dropdownOptions = softTargetDropdownOptions
        elseif setting.variable == "enableMacBookGraphics" or setting.variable == "enableBaseSettings" then
            dropdownOptions = macBookGraphicsDropdownOptions
        else
            dropdownOptions = cvarDropdownOptions
        end
        
        -- Убеждаемся, что значение в ConsoleMenuDB соответствует одному из индексов опций
        -- Это должно быть сделано ДО регистрации настройки
        local currentValue = ConsoleMenuDB[setting.variable]
        local maxValue = (setting.variable == "enableSoftTargetSettings") and 5 or 3
        
        -- Проверяем тип значения: если это не число, сбрасываем на дефолт
        if currentValue == nil then
            ConsoleMenuDB[setting.variable] = setting.default
        elseif type(currentValue) ~= "number" then
            -- Если значение не число (например, старое boolean значение), сбрасываем на дефолт
            ConsoleMenuDB[setting.variable] = setting.default
        elseif currentValue < 1 or currentValue > maxValue then
            -- Если значение невалидное (вне диапазона), сбрасываем на дефолт
            ConsoleMenuDB[setting.variable] = setting.default
        end
        
        -- Убеждаемся, что значение точно установлено перед регистрацией
        currentValue = ConsoleMenuDB[setting.variable]
        if type(currentValue) ~= "number" or currentValue < 1 or currentValue > maxValue then
            ConsoleMenuDB[setting.variable] = setting.default
        end
        
        ISL:MakeDropdown(
            CVarsSubcategory,
            setting.name,
            setting.variable,
            setting.default,
            setting.tooltip,
            dropdownOptions,
            ConsoleMenuDB,
            function(_, value)
                ConsoleMenuDB[setting.variable] = value
                -- Применяем все CVar настройки на основе обновленных значений в ConsoleMenuDB
                if _G.ApplyCVarSettings then
                    _G.ApplyCVarSettings()
                end
            end
        )
    end

    -- Создаем подкатегорию "Настройка клавиш"
    local KeyBindingsSubcategory, KeyBindingsLayout = ISL:CreateSubcategory(MainCategory, "Настройка клавиш")
    -- Вставляем заголовок "Взаимодействие"
    local InteractHeader = CreateSettingsListSectionHeaderInitializer("Взаимодействие")
    KeyBindingsLayout:AddInitializer(InteractHeader)
    ISL:MakeDropdown(
        KeyBindingsSubcategory,
        "Переопределять кнопку при наличии объекта взаимодействия",
        "overrideInteractKey",
        1,
        "Если включено, основная кнопка будет автоматически использовать действие взаимодействия, если рядом есть соответствующий объект.",
        { "Включить", "Выключить" },
        ConsoleMenuDB,
        function(_, value)
            ConsoleMenuDB["overrideInteractKey"] = value
        end
    )
    -- Маппинг индексов на строки кнопок
    local interactButtonMap = { "PAD1", "PAD2", "PAD3", "PAD4" }
    
    -- Убеждаемся, что значение в ConsoleMenuDB валидное
    local currentInteractButton = ConsoleMenuDB.interactButton
    if currentInteractButton == nil then
        ConsoleMenuDB.interactButton = 1
    elseif type(currentInteractButton) == "string" then
        -- Если это строка, находим соответствующий индекс
        local found = false
        for i, button in ipairs(interactButtonMap) do
            if button == currentInteractButton then
                ConsoleMenuDB.interactButton = i
                found = true
                break
            end
        end
        if not found then
            ConsoleMenuDB.interactButton = 1
        end
    elseif type(currentInteractButton) ~= "number" or currentInteractButton < 1 or currentInteractButton > 4 then
        ConsoleMenuDB.interactButton = 1
    end
    
    ISL:MakeDropdown(
        KeyBindingsSubcategory,
        "Кнопка взаимодействия",
        "interactButton",
        1,
        "Выберите, какая кнопка будет использоваться для взаимодействия с объектами.",
        { "PAD1", "PAD2", "PAD3", "PAD4" },
        ConsoleMenuDB,
        function(_, value)
            ConsoleMenuDB["interactButton"] = value
            -- Сохраняем строковое значение для использования в коде
            ConsoleMenuDB["interactButtonString"] = interactButtonMap[value]
        end
    )

    local ZoneAbilityHeader = CreateSettingsListSectionHeaderInitializer("Способность зоны (области)")
    KeyBindingsLayout:AddInitializer(ZoneAbilityHeader)
    ISL:MakeDropdown(
        KeyBindingsSubcategory,
        "Переопределять кнопку при наличии способности области",
        "overrideZoneAbilityKey",
        1,
        "Если включено, выбранная кнопка будет автоматически использовать способность области, если она доступна.",
        { "Включить", "Выключить" },
        ConsoleMenuDB,
        function(_, value)
            ConsoleMenuDB["overrideZoneAbilityKey"] = value
            ConsoleMenu:SetBindingsZoneAbility()
        end
    )
    -- Назначение клавиш: заголовок и параметр "Схема привязки"

    local KeyBindingSchemeHeader = CreateSettingsListSectionHeaderInitializer("Назначение клавиш")
    KeyBindingsLayout:AddInitializer(KeyBindingSchemeHeader)

    ISL:MakeDropdown(
        KeyBindingsSubcategory,
        "Схема привязки контроллера",
        "keyBindingScheme",
        1,
        "Выберите схему привязки игровых клавиш контроллера к действиям в игре.",
        { "Кастомная", "Вручную" },
        ConsoleMenuDB,
        function(_, value)
            ConsoleMenuDB["keyBindingScheme"] = value
            ConsoleMenu:SetBaseKeyBindings()
        end
    )
    
    -- Добавляем кнопку для очистки привязок контроллера
    ISL:CreateButton(
        KeyBindingsSubcategory,
        "Очистить привязки",
        "Очистить все привязки контроллера",
        function()
            if ConsoleMenu.ClearControllerBindings then
                ConsoleMenu:ClearControllerBindings()
            end
        end,
        "Очищает все привязки клавиш контроллера (ClearControllerBindings).",
        false
    )
    
    return true
end

-- Инициализация настроек
local function InitializeOptions()
    if Settings then
        RegisterOptions()
    else
        local frame = CreateFrame("Frame")
        frame:RegisterEvent("ADDON_LOADED")
        frame:SetScript("OnEvent", function(self, event, addonName)
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
