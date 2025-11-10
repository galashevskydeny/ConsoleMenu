-- SettingsHelper.lua
-- Библиотека для работы с Settings API

local SettingsHelper = {}

-- Инициализация базы данных, если она не существует
-- ВАЖНО: Не перезаписываем ConsoleMenuDB, если он уже существует (загружен из SavedVariables)
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

-- Регистрирует пикер клавиши/кнопки бинда
-- settingInfo: { name, variable, defaultKey, tooltip }
-- onValueChanged: функция, вызываемая при изменении значения (опционально)
function SettingsHelper.registerKeyBindingPicker(category, layout, settingInfo, onValueChanged)
    if not ConsoleMenuDB then
        ConsoleMenuDB = {}
    end

    local variable = settingInfo.variable
    local defaultKey = settingInfo.defaultKey or "ENTER"
    
    if ConsoleMenuDB[variable] == nil or ConsoleMenuDB[variable] == "" then
        ConsoleMenuDB[variable] = defaultKey
    end

    -- Создание и добавление кнопки выбора клавиши
    local keyPickerInitializer = CreateSettingsButtonInitializer(
        settingInfo.name,
        ConsoleMenuDB[variable] or defaultKey,

        function(button)
            
            -- Ожидание ввода клавиши
            if button._waitingForKey then
                return
            end
            button._waitingForKey = true

            -- Переиспользуем существующий фрейм или создаем новый
            local captureFrame = button._captureFrame
            if not captureFrame then
                -- Создаем полноэкранный фрейм для захвата ввода
                captureFrame = CreateFrame("Frame", nil, UIParent)
                captureFrame:SetFrameStrata("DIALOG")
                captureFrame:SetAllPoints(UIParent)
                captureFrame:EnableKeyboard(true)
                captureFrame:EnableGamePadButton(true)
                captureFrame:SetPropagateKeyboardInput(false)
                
                -- Создаем затемняющий фон
                local backdrop = captureFrame:CreateTexture(nil, "BACKGROUND")
                backdrop:SetAllPoints(captureFrame)
                backdrop:SetColorTexture(0, 0, 0, 0.7)
                
                -- Создаем текст подсказки
                local textFrame = CreateFrame("Frame", nil, captureFrame)
                textFrame:SetSize(400, 100)
                textFrame:SetPoint("CENTER", captureFrame, "CENTER", 0, 0)
                
                local text = textFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                text:SetPoint("CENTER", textFrame, "CENTER", 0, 0)
                text:SetText("Нажмите клавишу на клавиатуре или кнопку на контроллере...\n(ESC для отмены)")
                text:SetTextColor(1, 1, 1, 1)
                
                -- Сохраняем ссылку на фрейм в кнопке
                button._captureFrame = captureFrame
            end
            
            local waitingForInput = true
            local capturedKey = nil
            
            -- Обработка нажатий клавиатуры
            captureFrame:SetScript("OnKeyDown", function(self, key)
                if waitingForInput and key then
                    if key == "ESCAPE" then
                        -- Отмена
                        waitingForInput = false
                        self:Hide()
                    else
                        -- Сохраняем выбор
                        capturedKey = key
                        waitingForInput = false
                        self:Hide()
                    end
                end
            end)
            
            -- Обработка нажатий геймпада
            captureFrame:SetScript("OnGamePadButtonDown", function(self, gamepadButton)
                if waitingForInput and gamepadButton then
                    -- Сохраняем выбор кнопки геймпада
                    capturedKey = gamepadButton
                    waitingForInput = false
                    self:Hide()
                end
            end)
            
            -- Очистка при скрытии
            captureFrame:SetScript("OnHide", function(self)
                if capturedKey then
                    -- Сначала обновляем значение в базе данных
                    ConsoleMenuDB[variable] = capturedKey
                    
                    -- Вызываем callback (он может также изменять значение в ConsoleMenuDB)
                    if onValueChanged then
                        onValueChanged(capturedKey)
                    end
                    
                    button:SetText(capturedKey)
                    
                end
                button._waitingForKey = false
                -- Очищаем скрипты
                self:SetScript("OnKeyDown", nil)
                self:SetScript("OnGamePadButtonDown", nil)
                self:SetScript("OnHide", nil)
            end)
            
            captureFrame:Show()
        end,
        settingInfo.tooltip or "Нажмите, чтобы выбрать клавишу или кнопку",
        true -- выделенная кнопка
    )
    
    layout:AddInitializer(keyPickerInitializer)
end

-- Экспорт библиотеки
_G.SettingsHelper = SettingsHelper

