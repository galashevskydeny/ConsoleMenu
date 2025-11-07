-- ConsoleMenu.lua

local addonName, ConsoleMenu = ...
ConsoleMenu = ConsoleMenu or {}
_G[addonName] = ConsoleMenu

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
    -- Регистрация текстур в LibSharedMedia (если доступна)
    local LibSharedMedia = LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true)
    if LibSharedMedia then
        LibSharedMedia:Register("statusbar", "EnemyHealthBar", [[Interface\AddOns\ConsoleMenu\Assets\EnemyHealthBar.png]])
        LibSharedMedia:Register("statusbar", "HealthBar", [[Interface\AddOns\ConsoleMenu\Assets\HealthBar.png]])
        LibSharedMedia:Register("statusbar", "BossHealthBar", [[Interface\AddOns\ConsoleMenu\Assets\BossHealthBar.png]])
        LibSharedMedia:Register("statusbar", "FourBar", [[Interface\AddOns\ConsoleMenu\Assets\FourBar.png]])
        LibSharedMedia:Register("statusbar", "FiveBar", [[Interface\AddOns\ConsoleMenu\Assets\FiveBar.png]])
        LibSharedMedia:Register("statusbar", "SixBar", [[Interface\AddOns\ConsoleMenu\Assets\SixBar.png]])
        LibSharedMedia:Register("statusbar", "SevenBar", [[Interface\AddOns\ConsoleMenu\Assets\SevenBar.png]])
        LibSharedMedia:Register("statusbar", "GroupIcon2", [[Interface\AddOns\ConsoleMenu\Assets\GroupIcon2.png]])
        LibSharedMedia:Register("statusbar", "GroupIcon3", [[Interface\AddOns\ConsoleMenu\Assets\GroupIcon3.png]])
        LibSharedMedia:Register("statusbar", "GroupIcon3Line", [[Interface\AddOns\ConsoleMenu\Assets\GroupIcon3Line.png]])
        LibSharedMedia:Register("statusbar", "DpsCounter", [[Interface\AddOns\ConsoleMenu\Assets\DpsCounter.png]])
        LibSharedMedia:Register("statusbar", "Power_Item", [[Interface\AddOns\ConsoleMenu\Assets\Power_Item.png]])
    end    

    -- ConsoleMenu:RegisterEvent("AUCTION_HOUSE_THROTTLED_SYSTEM_READY", "ConfirmPurchase")
    -- ConsoleMenu:RegisterEvent("CRAFTINGORDERS_SHOW_CUSTOMER", "SetProfessionsCustomerOrdersFrame")
    
    -- Инициализация модулей
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
    end)

    -- Вибрация при отображении проков (overlay glow)
    ConsoleMenu:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", function()
        if ConsoleMenu.SetVibrationSpellGlow then ConsoleMenu:SetVibrationSpellGlow() end
    end)
    
    ConsoleMenu:InitInteractBindingFrame()
    ConsoleMenu:InitZoneAbilityBindingFrame()
    
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