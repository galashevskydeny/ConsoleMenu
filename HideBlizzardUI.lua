local ConsoleMenu = LibStub("AceAddon-3.0"):GetAddon("ConsoleMenu")

-- Скрывает основную панель действий (MainMenuBar)
local function HideActionBar()
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

-- Скрывает панель действий питомца (PetActionBar)
local function HidePetActionBar()
    PetActionBar:SetAlpha(0)
    RegisterStateDriver(PetActionBar, "visibility", "hide")

    for i = 1, 10 do
        if not _G['PetActionBarButtonContainer' .. i] then return end
        _G['PetActionBarButtonContainer' .. i]:Hide()
        _G['PetActionBarButtonContainer' .. i]:UnregisterAllEvents()
        _G['PetActionBarButtonContainer' .. i]:SetAttribute('statehidden', true)
    end

    RegisterStateDriver(MainStatusTrackingBarContainer, "visibility", "hide")

end

-- Скрывает трекер заданий (ObjectiveTrackerFrame)
local function HideObjectiveTrackerFrame()
    ObjectiveTrackerFrame:Hide()
    ObjectiveTrackerFrame:SetAlpha(0)
end

-- Скрывает фрейм цели (TargetFrame)
local function HideTargetFrame()
    TargetFrame:Hide()
    TargetFrame:SetAlpha(0.0)
    RegisterStateDriver(TargetFrame, "visibility", "hide")
end

-- Скрывает фрейм игрока (PlayerFrame)
local function HidePlayerFrame()
    PlayerFrame:Hide()
    PlayerFrame:UnregisterAllEvents()
    RegisterStateDriver(PlayerFrame, "visibility", "hide")
end

-- Скрывает полосу заклинаний игрока (PlayerCastingBarFrame)
local function HidePlayerCastingBarFrame()
    PlayerCastingBarFrame:Hide()
    RegisterStateDriver(PlayerCastingBarFrame, "visibility", "hide")
    PlayerCastingBarFrame:UnregisterAllEvents()
end

-- Скрывает миникарту и связанные элементы (Minimap, GameTimeFrame, BuffFrame, DebuffFrame и т.д.)
local function HideMinimap()
    Minimap:SetAlpha(0.0)
    Minimap:SetScale(0.01)

    UIWidgetBelowMinimapContainerFrame:Hide()
    RegisterStateDriver(UIWidgetBelowMinimapContainerFrame, "visibility", "hide")

    MinimapCluster.IndicatorFrame.MailFrame:Hide()
    RegisterStateDriver(MinimapCluster.IndicatorFrame.MailFrame, "visibility", "hide")

    MinimapCluster.Tracking:Hide()
    RegisterStateDriver(MinimapCluster.Tracking, "visibility", "hide")

    MinimapCluster.InstanceDifficulty:Hide()
    RegisterStateDriver(MinimapCluster.InstanceDifficulty, "visibility", "hide")

    GameTimeFrame:Hide()
    RegisterStateDriver(GameTimeFrame, "visibility", "hide")

    MinimapCluster.ZoneTextButton:Hide()
    RegisterStateDriver(MinimapCluster.ZoneTextButton, "visibility", "hide")

    MinimapCluster.IndicatorFrame.MailFrame:Hide()
    RegisterStateDriver(MinimapCluster.IndicatorFrame.MailFrame, "visibility", "hide")

    MinimapCluster.BorderTop:Hide()
    RegisterStateDriver(MinimapCluster.BorderTop, "visibility", "hide")

    BuffFrame:Hide()
    RegisterStateDriver(BuffFrame, "visibility", "hide")

    DebuffFrame:Hide()
    RegisterStateDriver(DebuffFrame, "visibility", "hide")
end

-- Скрывает кнопку часов (TimeManagerClockButton)
function ConsoleMenu:HideTimeManagerClockButton()
    if TimeManagerClockButton then
        TimeManagerClockButton:Hide()
    end
end

-- Скрывает меню (MicroMenu)
local function HideMicroMenu()
    MicroMenu:Hide()
    RegisterStateDriver(MicroMenu, "visibility", "hide")
end

-- Скрывает панель сумок (BagsBar)
local function HideBagsBagsBar()
    BagsBar:Hide()
    RegisterStateDriver(BagsBar, "visibility", "hide")
end

-- Скрывает фрейм текста зоны (ZoneTextFrame и SubZoneTextFrame)
local function HideZoneTextFrame()
    ZoneTextFrame:Hide()
    ZoneTextFrame:SetAlpha(0.0)
    ZoneTextFrame:UnregisterAllEvents()
    RegisterStateDriver(ZoneTextFrame, "visibility", "hide")
    SubZoneTextFrame:Hide()
    SubZoneTextFrame:SetAlpha(0.0)
    RegisterStateDriver(SubZoneTextFrame, "visibility", "hide")
    SubZoneTextFrame:UnregisterAllEvents()
end

-- Скрывает панель стоек (StanceBar)
local function HideStanceBar()
    StanceBar:Hide()
    RegisterStateDriver(StanceBar, "visibility", "hide")
end

-- Скрывает фрейм группы (CompactPartyFrame)
local function HideCompactPartyFrame()
    CompactPartyFrame:Hide()
    CompactPartyFrame:SetAlpha(0.0)
    RegisterStateDriver(CompactPartyFrame, "visibility", "hide")
end

-- Скрывает фрейм рейда (CompactRaidFrameContainer)
local function HideCompactRaidFrame()
    CompactRaidFrameContainer:Hide()
    CompactRaidFrameContainer:SetAlpha(0.0)
    RegisterStateDriver(CompactRaidFrameContainer, "visibility", "hide")
end

-- Скрывает фрейм предупреждений (AlertFrame)
local function HideAlertFrame()
    AlertFrame:Hide()
    RegisterStateDriver(AlertFrame, "visibility", "hide")
    AlertFrame:UnregisterAllEvents()
end

-- Скрывает фрейм ошибок UI (UIErrorsFrame)
local function HideUIErrorsFrame()
    UIErrorsFrame:Hide()
    RegisterStateDriver(UIErrorsFrame, "visibility", "hide")
    UIErrorsFrame:UnregisterAllEvents()
end

-- Скрывает баннер трекера заданий (ObjectiveTrackerTopBannerFrame)
local function HideObjectiveTrackerTopBannerFrame()
    ObjectiveTrackerTopBannerFrame:Hide()
    ObjectiveTrackerTopBannerFrame:SetAlpha(0.0)
    RegisterStateDriver(ObjectiveTrackerTopBannerFrame, "visibility", "hide")
    ObjectiveTrackerTopBannerFrame:UnregisterAllEvents()
end

-- Скрывает фрейм аддонов (AddonCompartmentFrame)
local function HideAddonCompartmentFrame()
    AddonCompartmentFrame:Hide()
    RegisterStateDriver(AddonCompartmentFrame, "visibility", "hide")
    AddonCompartmentFrame:UnregisterAllEvents()
end

-- Скрывает фрейм говорящей головы (TalkingHeadFrame)
local function HideTalkingHeadFrame()
    TalkingHeadFrame:Hide()
    RegisterStateDriver(TalkingHeadFrame, "visibility", "hide")
end

-- Скрывает фрейм полета на драконе (UIWidgetPowerBarContainerFrame)
local function HideUIWidgetPowerBarContainerFrame()
    UIWidgetPowerBarContainerFrame:Hide()
    RegisterStateDriver(UIWidgetPowerBarContainerFrame, "visibility", "hide")
    UIWidgetPowerBarContainerFrame:UnregisterAllEvents()
end

-- Скрывает фрейм лута (LootFrame)
local function HideLootFrame()
    LootFrame:Hide()
    LootFrame:UnregisterAllEvents()
end

-- Основная функция, которая скрывает все элементы UI Blizzard
function ConsoleMenu:HideBlizzardUI()
    HideLootFrame()
    HideUIWidgetPowerBarContainerFrame()
    HideTalkingHeadFrame()
    HideAddonCompartmentFrame()
    HideObjectiveTrackerTopBannerFrame()
    HideUIErrorsFrame()
    HideAlertFrame()
    HideCompactPartyFrame()
    HideCompactRaidFrame()
    HideStanceBar()
    HideZoneTextFrame()
    HideBagsBagsBar()
    HideMicroMenu()
    HideMinimap()
    HidePlayerCastingBarFrame()
    HidePlayerFrame()
    HideTargetFrame()
    HidePetActionBar()
    HideActionBar()
    HideObjectiveTrackerFrame()
end