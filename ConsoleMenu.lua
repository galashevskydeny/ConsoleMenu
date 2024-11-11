-- ConsoleMenu.lua

local addonName, ConsoleMenu = ...

ConsoleMenu = LibStub("AceAddon-3.0"):NewAddon("ConsoleMenu", "AceConsole-3.0")
_G[addonName] = ConsoleMenu -- Делаем аддон доступным глобально

function ConsoleMenu:OnInitialize()
    local LibSharedMedia = LibStub:GetLibrary ("LibSharedMedia-3.0")
    LibSharedMedia:Register ("statusbar", "healthbar", [[Interface\AddOns\ConsoleMenu\Assets\manabar.tga]])
    LibSharedMedia:Register ("statusbar", "healthbar2", [[Interface\AddOns\ConsoleMenu\Assets\healthPlate.tga]])

    self:SetCharacterFrame()
    self:SetPaperDollFrame()
end