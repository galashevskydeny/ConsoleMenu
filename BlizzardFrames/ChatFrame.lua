-- ChatFrame.lua

local ConsoleMenu = _G.ConsoleMenu

-- Функция для проверки, активен ли режим редактирования интерфейса
local function IsEditModeActive()
    -- Проверяем через API если доступен
    if C_EditMode and C_EditMode.IsEditModeActive then
        return C_EditMode.IsEditModeActive()
    end
    -- Проверяем через фрейм
    if EditModeManagerFrame then
        return EditModeManagerFrame:IsShown()
    end
    return false
end

-- Скрытие ненужных фреймов, регионов и текстур
local function HideFramesAndRegions()
    QuickJoinToastButton:Hide()

    for i = 1, 10 do
        local chatFrame = _G["ChatFrame" .. i]
        local chatFrameTab = _G["ChatFrame" .. i .. "Tab"]
        local chatFrameEditBox = _G["ChatFrame" .. i .. "EditBox"]

        -- Все текстуры и фоновые элементы
        local textures = {
            _G["ChatFrame" .. i .. "Background"],
            _G["ChatFrame" .. i .. "RightTexture"],
            _G["ChatFrame" .. i .. "LeftTexture"],
            _G["ChatFrame" .. i .. "TopTexture"],
            _G["ChatFrame" .. i .. "TopRightTexture"],
            _G["ChatFrame" .. i .. "TopLeftTexture"],
            _G["ChatFrame" .. i .. "BottomTexture"],
            _G["ChatFrame" .. i .. "BottomRightTexture"],
            _G["ChatFrame" .. i .. "BottomLeftTexture"],
            _G["ChatFrame" .. i .. "ButtonFrameBackground"],
            _G["ChatFrame" .. i .. "ButtonFrameRightTexture"],
            _G["ChatFrame" .. i .. "ButtonFrameLeftTexture"],
            _G["ChatFrame" .. i .. "ButtonFrameTopTexture"],
            _G["ChatFrame" .. i .. "ButtonFrameTopRightTexture"],
            _G["ChatFrame" .. i .. "ButtonFrameTopLeftTexture"],
            _G["ChatFrame" .. i .. "ButtonFrameBottomTexture"],
            _G["ChatFrame" .. i .. "ButtonFrameBottomRightTexture"],
            _G["ChatFrame" .. i .. "ButtonFrameBottomLeftTexture"]
        }

        -- Скрываем все текстуры
        for _, texture in ipairs(textures) do
            if texture then
                texture:Hide()
            end
        end

        local editBox = _G["ChatFrame" .. i .. "EditBox"]
        local editBoxHeader = _G["ChatFrame" .. i .. "EditBoxHeader"]

        if editBox then
            -- Проходим по всем регионам (в том числе текстуры) и скрываем их
            for j = 1, select("#", editBox:GetRegions()) do
                local region = select(j, editBox:GetRegions())
                if region and region:IsObjectType("Texture") then
                    region:SetTexture(nil)
                    region:Hide() -- Дополнительно скрываем текстуру
                end
            end

            -- Не изменяем позицию в режиме редактирования
            if not IsEditModeActive() then
                pcall(function()
                    editBox:ClearAllPoints()
                    editBox:SetPoint("BOTTOMLEFT", _G["ChatFrame" .. i], "TOPLEFT", -10, 40)
                    editBox:SetPoint("BOTTOMRIGHT", _G["ChatFrame" .. i], "TOPRIGHT", 10, 0)
                end)
            end
            editBox:SetFont("Fonts\\FRIZQT___CYR.TTF", 14, "")
            editBoxHeader:SetFont("Fonts\\FRIZQT___CYR.TTF", 14, "")

        end
         
    end
end

local function HideChatCommand()
    -- Не выполняем операции с фреймами в режиме редактирования
    if IsEditModeActive() then
        return
    end

    ConsoleMenu:RemoveWindow("chat")
    local context = ConsoleMenu:GetPlayerContext()
    ConsoleMenu:ApplyContextUIChanges(context)
    if WeakAuras then
        WeakAuras.ScanEvents("CHANGE_CONTEXT", context)
        WeakAuras.ScanEvents("SHOW_CHAT_FRAME", false)
    end

    pcall(function()
        ChatFrame1:SetHeight(1)
        ChatFrame1:ClearAllPoints() -- Очищаем все текущие точки привязки
        ChatFrame1:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, -4) -- Устанавливаем новую точку привязки
        ChatFrame1:SetParent(UIParent)
        ChatFrame1:SetUserPlaced(true)
    end)

    pcall(function()
        ChatFrame1:Hide()
        if ChatFrame1ButtonFrame then
            ChatFrame1ButtonFrame:Hide()
        end
    end)

    for i = 1, 10 do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            pcall(function()
                chatFrame:SetClampedToScreen(false)
                chatFrame:SetClampRectInsets(0, 0, 0, 0)
                chatFrame:SetUserPlaced(true)
            end)
        end
    end

    -- Обновляем текст кнопки
    if _G.ToggleChatButton and _G.ToggleChatButton.text then
        _G.ToggleChatButton.text:SetText("Показать чат")
    end
end

local function ShowChatCommand()
    -- Не выполняем операции с фреймами в режиме редактирования
    if IsEditModeActive() then
        return
    end

    ConsoleMenu:AddWindow("chat")
    local context = ConsoleMenu:GetPlayerContext()
    ConsoleMenu:ApplyContextUIChanges(context)

    if WeakAuras then
        WeakAuras.ScanEvents("CHANGE_CONTEXT", context)
        WeakAuras.ScanEvents("SHOW_CHAT_FRAME", true)
    end

    pcall(function()
        ChatFrame1:SetHeight(160)
        ChatFrame1:ClearAllPoints() -- Очищаем все текущие точки привязки
        ChatFrame1:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 32) -- Устанавливаем новую точку привязки
        ChatFrame1:SetParent(UIParent)
        ChatFrame1:SetUserPlaced(true)
    end)

    pcall(function()
        ChatFrame1:Show()
        if ChatFrame1ButtonFrame then
            ChatFrame1ButtonFrame:Show()
        end
    end)

    for i = 1, 10 do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            pcall(function()
                chatFrame:SetClampedToScreen(true)
                chatFrame:SetClampRectInsets(0, 0, 0, 0)
                chatFrame:SetUserPlaced(true)
            end)
        end
    end

    -- Обновляем текст кнопки
    if _G.ToggleChatButton and _G.ToggleChatButton.text then
        _G.ToggleChatButton.text:SetText("Скрыть чат")
    end
end

local function CreateToggleChatButton()
    -- Ищем фрейм GeneralDockManagerScrollFrame
    local parentFrame = _G["GeneralDockManagerScrollFrame"]
    if not parentFrame then
        print("GeneralDockManagerScrollFrame не найден!")
        return nil
    end

    -- Создаём фрейм для хранения override биндингов (глобально доступный)
    if not ConsoleMenu.ChatBindingFrame then
        ConsoleMenu.ChatBindingFrame = CreateFrame("Frame", "ToggleChatButtonBindingFrame", UIParent)
    end
    
    -- Создаём кнопку без шаблона (без фона)
    local btn = CreateFrame("Button", "ToggleChatButton", parentFrame)
    btn:SetSize(100, 20)
    btn:SetAlpha(0.5)

    -- Функция для установки биндинга (доступна глобально для обновления)
    local function SetupChatKeyBinding()
        if InCombatLockdown() then
            return
        end
        
        if not ConsoleMenu.ChatBindingFrame then
            return
        end
        
        -- Очищаем предыдущие override биндинги
        ClearOverrideBindings(ConsoleMenu.ChatBindingFrame)
        
        -- Устанавливаем новый override биндинг
        local key = ConsoleMenuDB and ConsoleMenuDB.selectedChatButtonKey
        if key and key ~= "" then
            SetOverrideBindingClick(ConsoleMenu.ChatBindingFrame, true, key, "ToggleChatButton", "LeftButton")
        end
    end

    -- Делаем функцию доступной глобально
    _G.SetupChatKeyBinding = SetupChatKeyBinding

    -- Устанавливаем биндинг при создании
    SetupChatKeyBinding()
    
    -- Создаём текстовую строку для кнопки
    local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btnText:SetPoint("CENTER", btn, "CENTER", 0, 0)
    btnText:SetJustifyH("CENTER")
    btnText:SetJustifyV("MIDDLE")
    btn.text = btnText
    
    -- Функция для обновления текста кнопки в зависимости от состояния чата
    local function UpdateButtonText()
        if ChatFrame1 and ChatFrame1:GetHeight() <= 2 then
            btnText:SetText("Показать чат")
        else
            btnText:SetText("Скрыть чат")
        end
    end
    
    -- Устанавливаем начальный текст
    UpdateButtonText()
    
    -- Привязываем правый край кнопки к правому краю GeneralDockManagerScrollFrame
    -- Не изменяем позицию в режиме редактирования
    if not IsEditModeActive() then
        pcall(function()
            btn:ClearAllPoints()
            btn:SetPoint("RIGHT", parentFrame, "RIGHT", -2, 0) -- -2: небольшой отступ от края, можно 0
        end)
    end

    btn:SetScript("OnClick", function()
        ToggleChatCommand()
        UpdateButtonText()
    end)
    
    -- Добавляем эффект при наведении (опционально)
    btn:SetScript("OnEnter", function(self)
        btn:SetAlpha(1)
    end)
    
    btn:SetScript("OnLeave", function(self)
        btn:SetAlpha(0.5)
    end)

    return btn
end


function ToggleChatCommand()
    -- Не выполняем переключение в режиме редактирования
    if IsEditModeActive() then
        return
    end

    if ChatFrame1:GetHeight() <= 2 then
        ShowChatCommand()
    else
        HideChatCommand()
    end
end

-- Функция для восстановления позиции чата после выхода из режима редактирования
local function RestoreChatPosition()
    -- Не восстанавливаем позицию в режиме редактирования
    if IsEditModeActive() then
        return
    end

    pcall(function()
        if ChatFrame1:GetHeight() <= 2 then
            -- Если чат скрыт, восстанавливаем позицию скрытого состояния
            ChatFrame1:ClearAllPoints()
            ChatFrame1:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, -4)
            ChatFrame1:SetUserPlaced(true)
        else
            -- Если чат показан, восстанавливаем позицию показанного состояния
            ChatFrame1:ClearAllPoints()
            ChatFrame1:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 32)
            ChatFrame1:SetUserPlaced(true)
        end
    end)
end

-- Защита позиции чата от изменения при редактировании UI
local function SetupChatPositionProtection()
    if not ChatFrame1 then
        return
    end
    
    -- Защищаем от изменения позиции через SetUserPlaced (только если не в режиме редактирования)
    if not IsEditModeActive() then
        pcall(function() ChatFrame1:SetUserPlaced(true) end)
    end
    
    -- Хук события EDIT_MODE_LAYOUTS_UPDATED
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
    eventFrame:SetScript("OnEvent", function()
        -- Восстанавливаем позицию только после выхода из режима редактирования
        if not IsEditModeActive() then
            C_Timer.After(0.1, RestoreChatPosition)
        end
    end)
    
    -- Дополнительная защита через OnUpdate (проверяем позицию периодически)
    -- Проверяем только когда не в режиме редактирования
    local positionGuard = CreateFrame("Frame")
    local lastCheck = 0
    
    -- Отслеживаем режим редактирования для восстановления позиции после выхода
    if EditModeManagerFrame then
        EditModeManagerFrame:HookScript("OnShow", function()
            -- Не делаем ничего в режиме редактирования
        end)
        EditModeManagerFrame:HookScript("OnHide", function()
            -- Восстанавливаем позицию сразу после выхода из режима редактирования
            C_Timer.After(0.2, RestoreChatPosition)
        end)
    end
    
    positionGuard:SetScript("OnUpdate", function(self, elapsed)
        -- Не проверяем позицию в режиме редактирования
        if IsEditModeActive() then
            return
        end
        
        lastCheck = lastCheck + elapsed
        if lastCheck >= 1.0 then -- Проверяем каждую секунду (реже для оптимизации)
            lastCheck = 0
            pcall(function()
                if ChatFrame1:IsShown() and ChatFrame1:GetHeight() > 2 then
                    local point, relativeTo, relativePoint, xOfs, yOfs = ChatFrame1:GetPoint()
                    if relativeTo == UIParent and yOfs ~= 32 then
                        RestoreChatPosition()
                    end
                elseif ChatFrame1:GetHeight() <= 2 then
                    local point, relativeTo, relativePoint, xOfs, yOfs = ChatFrame1:GetPoint()
                    if relativeTo == UIParent and yOfs ~= -4 then
                        RestoreChatPosition()
                    end
                end
            end)
        end
    end)
end

function ConsoleMenu:SetChatFrame()

    if ConsoleMenuDB.chatWindowStyle == 2 then
        return
    end

    HideFramesAndRegions()
    SetupChatPositionProtection()
    CreateToggleChatButton()
    
    -- Устанавливаем начальную позицию
    C_Timer.After(0.1, function() 
        HideChatCommand() 
    end)
end

