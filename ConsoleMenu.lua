-- ConsoleMenu.lua

local addonName, ConsoleMenu = ...
ConsoleMenu = LibStub("AceAddon-3.0"):NewAddon("ConsoleMenu", "AceConsole-3.0", "AceEvent-3.0")
_G[addonName] = ConsoleMenu

function ConsoleMenu:OnInitialize()
    local LibSharedMedia = LibStub:GetLibrary ("LibSharedMedia-3.0")

    LibSharedMedia:Register ("statusbar", "EnemyHealthBar", [[Interface\AddOns\ConsoleMenu\Assets\EnemyHealthBar.png]])

    LibSharedMedia:Register ("statusbar", "HealthBar", [[Interface\AddOns\ConsoleMenu\Assets\HealthBar.png]])
    LibSharedMedia:Register ("statusbar", "BossHealthBar", [[Interface\AddOns\ConsoleMenu\Assets\BossHealthBar.png]])

    LibSharedMedia:Register ("statusbar", "FourBar", [[Interface\AddOns\ConsoleMenu\Assets\FourBar.png]])
    LibSharedMedia:Register ("statusbar", "FiveBar", [[Interface\AddOns\ConsoleMenu\Assets\FiveBar.png]])
    LibSharedMedia:Register ("statusbar", "SixBar", [[Interface\AddOns\ConsoleMenu\Assets\SixBar.png]])
    LibSharedMedia:Register ("statusbar", "SevenBar", [[Interface\AddOns\ConsoleMenu\Assets\SevenBar.png]])


    LibSharedMedia:Register ("statusbar", "GroupIcon2", [[Interface\AddOns\ConsoleMenu\Assets\GroupIcon2.png]])
    LibSharedMedia:Register ("statusbar", "GroupIcon3", [[Interface\AddOns\ConsoleMenu\Assets\GroupIcon3.png]])
    LibSharedMedia:Register ("statusbar", "GroupIcon3Line", [[Interface\AddOns\ConsoleMenu\Assets\GroupIcon3Line.png]])
    LibSharedMedia:Register ("statusbar", "DpsCounter", [[Interface\AddOns\ConsoleMenu\Assets\DpsCounter.png]])
    LibSharedMedia:Register ("statusbar", "Power_Item", [[Interface\AddOns\ConsoleMenu\Assets\Power_Item.png]])

    self:RegisterEvent("ACTIONBAR_SLOT_CHANGED", "UpdateActionInfo")
    self:RegisterEvent("UPDATE_BINDINGS", "UpdateActionInfo")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateActionInfo")
    self:RegisterEvent("GAME_PAD_ACTIVE_CHANGED", "UpdateActionInfo")
    self:RegisterEvent("ACTIONBAR_PAGE_CHANGED", "UpdateActionInfo")
    self:RegisterEvent("AUCTION_HOUSE_THROTTLED_SYSTEM_READY", "ConfirmPurchase")
    self:RegisterEvent("CRAFTINGORDERS_SHOW_CUSTOMER", "SetProfessionsCustomerOrdersFrame")

    self:SetCharacterFrame()
    self:SetPaperDollFrame()
    self:SetReputationFrame()
    self:SetTokenFrame()
    self:SetMailFrame()
    self:SetMerchantFrame()
    self:SetOpenMailFrame()
    self:SetQuestFrame()
    self:SetGossipFrame()
    --self:SetPVEFrame()
    --self:SetWorldMapFrame()
    
    self:SetCustomGossipFrame()
    self:SetFastTravelFrame()

    self:UpdateActionInfo()

end