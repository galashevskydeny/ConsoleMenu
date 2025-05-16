-- ConsoleMenu.lua

local addonName, ConsoleMenu = ...
ConsoleMenu = LibStub("AceAddon-3.0"):NewAddon("ConsoleMenu", "AceConsole-3.0", "AceEvent-3.0")
_G[addonName] = ConsoleMenu

function ConsoleMenu:OnInitialize()
    local LibSharedMedia = LibStub:GetLibrary ("LibSharedMedia-3.0")


    LibSharedMedia:Register ("statusbar", "healthbar", [[Interface\AddOns\ConsoleMenu\Assets\manabar.tga]])
    LibSharedMedia:Register ("statusbar", "healthbar2", [[Interface\AddOns\ConsoleMenu\Assets\healthPlate.tga]])

    LibSharedMedia:Register ("statusbar", "HealthBar", [[Interface\AddOns\ConsoleMenu\Assets\HealthBar.png]])
    LibSharedMedia:Register ("statusbar", "ManaBar_Mage_Arcane", [[Interface\AddOns\ConsoleMenu\Assets\ManaBar_Mage_Arcane.png]])

    LibSharedMedia:Register ("statusbar", "GroupIcon2", [[Interface\AddOns\ConsoleMenu\Assets\GroupIcon2.png]])
    LibSharedMedia:Register ("statusbar", "GroupIcon3", [[Interface\AddOns\ConsoleMenu\Assets\GroupIcon3.png]])
    LibSharedMedia:Register ("statusbar", "DpsCounter", [[Interface\AddOns\ConsoleMenu\Assets\DpsCounter.png]])
    LibSharedMedia:Register ("statusbar", "Power_Item", [[Interface\AddOns\ConsoleMenu\Assets\Power_Item.png]])

    self:RegisterEvent("ACTIONBAR_SLOT_CHANGED", "UpdateActionInfo")
    self:RegisterEvent("UPDATE_BINDINGS", "UpdateActionInfo")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateActionInfo")

    self:SetCharacterFrame()
    self:SetPaperDollFrame()
    self:SetReputationFrame()
    self:SetTokenFrame()
    self:SetMailFrame()
    self:SetMerchantFrame()
    self:SetOpenMailFrame()
    self:SetQuestFrame()
    self:SetGossipFrame()
    self:SetPVEFrame()
    --self:SetWorldMapFrame()
    
    self:SetCustomGossipFrame()
    self:SetFastTravelFrame()

    self:UpdateActionInfo()

end