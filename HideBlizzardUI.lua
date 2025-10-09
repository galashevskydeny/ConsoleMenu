local ConsoleMenu = LibStub("AceAddon-3.0"):GetAddon("ConsoleMenu")

local function hideActionBar()
    MainMenuBar:SetAlpha(0)
    RegisterStateDriver(MainMenuBar, "visibility", "hide")

    for i = 1, 12 do
        if not _G['ActionButton' .. i] then return end
        _G['ActionButton' .. i]:Hide()
        _G['ActionButton' .. i]:UnregisterAllEvents()
        _G['ActionButton' .. i]:SetAttribute('statehidden', true)
    end

    RegisterStateDriver(MainStatusTrackingBarContainer, "visibility", "hide")

end

local function hideObjectiveTrackerFrame()
    ObjectiveTrackerFrame:Hide()
    ObjectiveTrackerFrame:SetAlpha(0)
end

function ConsoleMenu:HideBlizzardUI()
    hideActionBar()
    hideObjectiveTrackerFrame()
end