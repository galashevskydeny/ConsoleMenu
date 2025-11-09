-- SettingsHelper.lua
-- Библиотека для работы с Settings API

local SettingsHelper = {}

-- Инициализация базы данных, если она не существует
if not ConsoleMenuDB then
    ConsoleMenuDB = {}
end

-- Кеш зарегистрированных настроек для избежания повторной регистрации
-- Ключ: "CONSOLEMENU_" .. variable:upper(), значение: объект настройки
local registeredSettings = {}

-- Проверяет и устанавливает числовое значение в допустимом диапазоне
function SettingsHelper.ensureNumericChoice(variable, defaultValue, maxValue)
    if not ConsoleMenuDB then
        ConsoleMenuDB = {}
    end
    
    local value = ConsoleMenuDB[variable]

    if value == nil or type(value) ~= "number" or value < 1 or value > maxValue then
        ConsoleMenuDB[variable] = defaultValue
        value = defaultValue
    end

    return value
end

-- Проверяет и устанавливает значения по умолчанию для dropdown
function SettingsHelper.ensureDropdownDefaults(setting)
    return SettingsHelper.ensureNumericChoice(setting.variable, setting.default, #setting.options)
end

-- Регистрирует dropdown настройку
function SettingsHelper.registerDropdown(category, settingInfo, onValueChanged)
    SettingsHelper.ensureDropdownDefaults(settingInfo)

    local function getOptions()
        local container = Settings.CreateControlTextContainer()
        for index, optionName in ipairs(settingInfo.options) do
            container:Add(index, optionName)
        end
        return container:GetData()
    end

    local settingKey = "CONSOLEMENU_" .. settingInfo.variable:upper()
    local setting
    
    -- Проверяем, не была ли настройка уже зарегистрирована
    if registeredSettings[settingKey] then
        -- Используем уже зарегистрированную настройку
        setting = registeredSettings[settingKey]
    else
        -- Регистрируем новую настройку
        local success, result = pcall(function()
            return Settings.RegisterAddOnSetting(
                category,
                settingKey,
                settingInfo.variable,
                ConsoleMenuDB,
                Settings.VarType.Number,
                settingInfo.name,
                settingInfo.default
            )
        end)
        
        if success then
            setting = result
        else
            -- Если регистрация не удалась (настройка уже существует), 
            -- пытаемся получить существующую настройку через Settings API
            -- В WoW API нет прямого способа получить существующую настройку,
            -- поэтому создаем объект-заглушку, который будет работать с dropdown
            setting = {
                variable = settingInfo.variable,
                variableKey = settingInfo.variable,
                variableType = "number",
                name = settingInfo.name,
                defaultValue = settingInfo.default,
                data = {}
            }
        end
        
        -- Сохраняем в кеш
        registeredSettings[settingKey] = setting
    end

    -- Обновляем tooltip, если он указан
    if settingInfo.tooltip then
        if not setting.data then
            setting.data = {}
        end
        setting.data.tooltip = settingInfo.tooltip
    end

    -- Callback устанавливаем только при первой регистрации
    if onValueChanged and not registeredSettings[settingKey]._callbackSet then
        local callbackSuccess, callbackError = pcall(function()
            if setting.SetValueChangedCallback then
                setting:SetValueChangedCallback(function(_, newValue)
                    onValueChanged(newValue)
                end)
                registeredSettings[settingKey]._callbackSet = true
            end
        end)
        -- Если callback не поддерживается, игнорируем ошибку
    end

    -- Создаем dropdown для текущей категории (можно создавать несколько dropdown для одной настройки)
    Settings.CreateDropdown(category, setting, getOptions, settingInfo.tooltip)
end

-- Добавляет кнопку перезагрузки интерфейса
function SettingsHelper.addReloadButton(layout, name)
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

-- Экспорт библиотеки
_G.SettingsHelper = SettingsHelper

