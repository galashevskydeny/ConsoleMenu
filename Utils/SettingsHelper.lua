-- SettingsHelper.lua
-- Библиотека для работы с Settings API

local SettingsHelper = {}

-- Инициализация базы данных, если она не существует
if not ConsoleMenuDB then
    ConsoleMenuDB = {}
end

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

