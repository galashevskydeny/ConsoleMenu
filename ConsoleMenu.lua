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
    
    -- Инициализация модулей
    ConsoleMenu:RegisterAssets()

    ConsoleMenu:SetCharacterFrame()
    ConsoleMenu:SetPaperDollFrame()
    ConsoleMenu:SetReputationFrame()
    ConsoleMenu:SetTokenFrame()
    ConsoleMenu:SetMailFrame()
    ConsoleMenu:SetMerchantFrame()
    ConsoleMenu:SetOpenMailFrame()
    ConsoleMenu:SetQuestFrame()
    ConsoleMenu:SetGossipFrame()
    
    ConsoleMenu:SetCustomGossipFrame()
    ConsoleMenu:SetFastTravelFrame()

    ConsoleMenu:InitActionInfoFrame()

    ConsoleMenu:HideBlizzardUI()
    ConsoleMenu:UpdateCVars()
    
    -- Установим бинды после полной инициализации игрока
    ConsoleMenu:RegisterEvent("PLAYER_LOGIN", function()
        if ConsoleMenu.SetBaseKeyBindings then ConsoleMenu:SetBaseKeyBindings() end
        if ConsoleMenu.HideTimeManagerClockButton then ConsoleMenu:HideTimeManagerClockButton() end

        -- Интеграция с ConsolePort
        if ConsolePortUtilityToggle then
            ConsolePortUtilityToggle:HookScript("OnShow", function()
                if WeakAuras then
                    WeakAuras.ScanEvents("CHANGE_CONTEXT", "ring")
                end
            end)
            
            ConsolePortUtilityToggle:HookScript("OnHide", function()                
                if WeakAuras then
                    WeakAuras.ScanEvents("CHANGE_CONTEXT", ConsoleMenu.PlayerContext.lastContext)
                end
            end)
        end
    end)

    -- Вибрация при отображении проков (overlay glow)
    ConsoleMenu:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", function()
        ConsoleMenu:SetVibrationSpellGlow()
    end)
    
    ConsoleMenu:InitInteractBindingFrame()
    ConsoleMenu:InitZoneAbilityBindingFrame()
    
    ConsoleMenu.InitializeOptions()
    ConsoleMenu:InitializeContexts()
    ConsoleMenu:InitializeSuperTrackManager()
    
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