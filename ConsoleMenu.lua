-- ConsoleMenu.lua

local addonName, ConsoleMenu = ...
ConsoleMenu = ConsoleMenu or {}
_G[addonName] = ConsoleMenu

-- Инициализация таблицы аддона для InterfaceSettingsLib
if not ConsoleMenuAddon then
    ConsoleMenuAddon = {}
    ConsoleMenuAddon.AddonName = "ConsoleMenu"
    ConsoleMenuAddon.AddonFileName = "ConsoleMenu"
end

-- Создаём фрейм для обработки событий
local eventFrame = CreateFrame("Frame")

-- Регистрация событий
function ConsoleMenu:RegisterEvent(event, handler)
    if type(handler) == "string" then
        handler = self[handler]
    end
    eventFrame:RegisterEvent(event)
    if not eventFrame.registeredEvents then
        eventFrame.registeredEvents = {}
    end
    eventFrame.registeredEvents[event] = handler
end

function ConsoleMenu:UnregisterEvent(event)
    eventFrame:UnregisterEvent(event)
    if eventFrame.registeredEvents then
        eventFrame.registeredEvents[event] = nil
    end
end

-- Инициализация аддона
local function Initialize()

    ConsoleMenu:SetCommonFrame()

    -- Инициализация модулей
    ConsoleMenu:RegisterAssets()
    
    -- Инициализируем контексты раньше, чтобы они были доступны для других модулей
    ConsoleMenu:InitializeContexts()

    ConsoleMenu:SetCharacterFrame()
    ConsoleMenu:SetChatFrame()
    ConsoleMenu:SetPaperDollFrame()
    ConsoleMenu:SetReputationFrame()
    ConsoleMenu:SetTokenFrame()
    ConsoleMenu:SetMailFrame()
    ConsoleMenu:SetMerchantFrame()
    ConsoleMenu:SetOpenMailFrame()
    ConsoleMenu:SetQuestFrame()
    ConsoleMenu:SetStatusTrackingFrame()
    ConsoleMenu:SetObjectiveTrackerFrame()
    ConsoleMenu:SetGameDialog()
    ConsoleMenu:SetPlayerChoice()
    
    ConsoleMenu:SetSubtitleFrame()
    ConsoleMenu:SetCustomGossipFrame()
    ConsoleMenu:SetGossipFrame()
    ConsoleMenu:SetNotificationFrame()
    ConsoleMenu:SetQueueStatusToastFrame()
    ConsoleMenu:SetLootList()
    ConsoleMenu:InitializeMainActionBar()
    ConsoleMenu:SetMerchantFrame()

    ConsoleMenu:SetKeysFrame()
    
    ConsoleMenu:HideBlizzardUI()
    ConsoleMenu:UpdateCVars()
    
    -- Установим бинды после полной инициализации игрока
    ConsoleMenu:RegisterEvent("PLAYER_LOGIN", function()
        -- Применяем настройки GamePad при загрузке игрока
        if _G.ApplyGamePadCVars then
            _G.ApplyGamePadCVars()
        end
        ConsoleMenu:SetBaseKeyBindings()

        if ConsoleMenuDB.hideMinimap == 2 or ConsoleMenuDB.hideMinimapCluster == 2 then
            ConsoleMenu:DisableTimeManagerClockButton()
        end

        ConsoleMenu:SetFastTravelFrame()
        ConsoleMenu:SetPanelFrame()

        _G.ApplyMacroSettings()
        
    end)

    -- Вибрация при отображении проков (overlay glow)
    ConsoleMenu:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", function()
        ConsoleMenu:SetVibrationSpellGlow()
    end)
    
    ConsoleMenu:InitHousingBindingFrame()
    ConsoleMenu:InitInteractBindingFrame()
    ConsoleMenu:InitZoneAbilityBindingFrame()
    ConsoleMenu:InitStopCastingBindingFrame()
    
    ConsoleMenu.InitializeOptions()
    ConsoleMenu:InitializeSuperTrackManager()
    ConsoleMenu:InitializeNameplate()
    
end

-- Обработчик всех событий
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddonName = ...
        if loadedAddonName == addonName then
            Initialize()
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif self.registeredEvents and self.registeredEvents[event] then
        local handler = self.registeredEvents[event]
        if type(handler) == "function" then
            handler(ConsoleMenu, event, ...)
        end
    end
end)

-- Запуск инициализации после загрузки
eventFrame:RegisterEvent("ADDON_LOADED")