local ConsoleMenu = _G.ConsoleMenu

-- Отключает основную панель действий (MainMenuBar)
local function DisableActionBar()
    if MainActionBar then
        MainActionBar:SetAlpha(0)
    end

    if MainMenuBar then
        MainMenuBar:SetAlpha(0)
    end

    for i = 1, 12 do
        if not _G['ActionButton' .. i] then return end
        _G['ActionButton' .. i]:Hide()
        _G['ActionButton' .. i]:UnregisterAllEvents()
        _G['ActionButton' .. i]:SetAttribute('statehidden', true)
    end


end

-- Скрывает основную панель действий (MainMenuBar)
function ConsoleMenu:HideActionBar()
    if MainActionBar then
        MainActionBar:SetAlpha(0)
    end

    if MainMenuBar then
        MainMenuBar:SetAlpha(0)
      end

    for i = 1, 12 do
        if not _G['ActionButton' .. i] then return end
        _G['ActionButton' .. i]:SetAlpha(0)

    end

end

-- Восстанавливает отображение основной панели действий (MainMenuBar)
function ConsoleMenu:ShowActionBar()
    if MainActionBar then

        MainActionBar:SetAlpha(1)
    end

    if MainMenuBar then
        MainMenuBar:SetAlpha(1)
    end

    for i = 1, 12 do
        if not _G['ActionButton' .. i] then return end
        _G['ActionButton' .. i]:SetAlpha(1)
    end

end

-- Скрывает панель действий питомца (PetActionBar)
local function DisablePetActionBar()
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

-- Отключает фрейм игрока (PlayerFrame)
local function DisablePlayerFrame()
    PlayerFrame:Hide()
    PlayerFrame:SetAlpha(0.0)
    PlayerFrame:UnregisterAllEvents()
    RegisterStateDriver(PlayerFrame, "visibility", "hide")
end

-- Скрывает фрейм игрока (PlayerFrame)
function ConsoleMenu:HidePlayerFrame()
    PlayerFrame:SetAlpha(0.0)
end

-- Показывает фрейм игрока (PlayerFrame)
function ConsoleMenu:ShowPlayerFrame()
    PlayerFrame:SetAlpha(1.0)
end



-- Отключает полосу заклинаний игрока (PlayerCastingBarFrame)
local function DisablePlayerCastingBarFrame()
    PlayerCastingBarFrame:Hide()
    RegisterStateDriver(PlayerCastingBarFrame, "visibility", "hide")
    PlayerCastingBarFrame:UnregisterAllEvents()
end

-- Скрывает фрейм аддонов (AddonCompartmentFrame)
local function DisableAddonCompartmentFrame()
    AddonCompartmentFrame:Hide()
    RegisterStateDriver(AddonCompartmentFrame, "visibility", "hide")
    AddonCompartmentFrame:UnregisterAllEvents()
end

-- Скрывает миникарту и связанные элементы (Minimap, GameTimeFrame, BuffFrame, DebuffFrame и т.д.)
local function DisableMinimap()
    Minimap:SetAlpha(0.0)
    Minimap:SetScale(0.01)

    DisableAddonCompartmentFrame()

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
end

-- Скрывает фрейм баффов (BuffFrame)
local function HideBuffFrame()
    BuffFrame:Hide()
    RegisterStateDriver(BuffFrame, "visibility", "hide")
end

-- Скрывает фрейм дебаффов (DebuffFrame)
local function HideDebuffFrame()
    DebuffFrame:Hide()
    RegisterStateDriver(DebuffFrame, "visibility", "hide")
end

-- Скрывает кнопку часов (TimeManagerClockButton)
function ConsoleMenu:DisableTimeManagerClockButton()
    if TimeManagerClockButton then
        TimeManagerClockButton:Hide()
        RegisterStateDriver(TimeManagerClockButton, "visibility", "hide")
        TimeManagerClockButton:UnregisterAllEvents()
        TimeManagerClockButton:SetAlpha(0.0)
    end
end

-- Скрывает меню (MicroMenu)
local function DisableMicroMenu()
    MicroMenu:Hide()
    RegisterStateDriver(MicroMenu, "visibility", "hide")
    
    -- Скрываем QueueStatusButton если hideGroupFinderFrame == 2
    if ConsoleMenuDB and ConsoleMenuDB.hideGroupFinderFrame == 2 then
        if QueueStatusButton then
            QueueStatusButton:Hide()
            QueueStatusButton:SetAlpha(0.0)
            RegisterStateDriver(QueueStatusButton, "visibility", "hide")
            QueueStatusButton:UnregisterAllEvents()
        end
    end
end

-- Скрывает панель сумок (BagsBar)
local function HideBagsBagsBar()
    BagsBar:Hide()
    RegisterStateDriver(BagsBar, "visibility", "hide")
end

-- Скрывает фрейм текста зоны (ZoneTextFrame и SubZoneTextFrame)
local function DisableZoneTextFrame()
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
local function DisableAlertFrame()
    AlertFrame:Hide()
    RegisterStateDriver(AlertFrame, "visibility", "hide")
    AlertFrame:UnregisterAllEvents()
end

-- Скрывает фрейм ошибок UI (UIErrorsFrame)
local function DisableUIErrorsFrame()
    UIErrorsFrame:Hide()
    RegisterStateDriver(UIErrorsFrame, "visibility", "hide")
    UIErrorsFrame:UnregisterAllEvents()
end

-- Скрывает баннер трекера заданий (ObjectiveTrackerTopBannerFrame)
function ConsoleMenu:DisableObjectiveTrackerTopBannerFrame()
    ObjectiveTrackerTopBannerFrame:Hide()
    ObjectiveTrackerTopBannerFrame:SetAlpha(0.0)
    ObjectiveTrackerTopBannerFrame:UnregisterAllEvents()
end

-- Скрывает фрейм говорящей головы (TalkingHeadFrame)
function ConsoleMenu:HideTalkingHeadFrame()
    if TalkingHeadFrame then
        TalkingHeadFrame:Hide()
    end
end

-- Скрывает фрейм полета на драконе (UIWidgetPowerBarContainerFrame)
local function HideUIWidgetPowerBarContainerFrame()
    UIWidgetPowerBarContainerFrame:Hide()
    RegisterStateDriver(UIWidgetPowerBarContainerFrame, "visibility", "hide")
    UIWidgetPowerBarContainerFrame:UnregisterAllEvents()
end

-- Скрывает фрейм лута (LootFrame)
local function DisableLootFrame()
    SetCVar("autoLootDefault", 1)
    LootFrame:Hide()
    LootFrame:UnregisterAllEvents()
end

-- Скрывает фрейм способностей зоны (ZoneAbilityFrame)
local function DisableZoneAbilityFrame()
    if ZoneAbilityFrame then
        ZoneAbilityFrame:Hide()
        RegisterStateDriver(ZoneAbilityFrame, "visibility", "hide")
        ZoneAbilityFrame:UnregisterAllEvents()
    end
end

-- Скрывает контейнер фреймов боссов (BossTargetFrameContainer)
local function DisableBossTargetFrameContainer()
    if BossTargetFrameContainer then
        BossTargetFrameContainer:Hide()
        RegisterStateDriver(BossTargetFrameContainer, "visibility", "hide")
        BossTargetFrameContainer:UnregisterAllEvents()
    end
end

local function DisableSpellActivationOverlay()
    SpellActivationOverlayFrame:Hide()
    RegisterStateDriver(SpellActivationOverlayFrame, "visibility", "hide")
    SpellActivationOverlayFrame:UnregisterAllEvents()
end

-- Основная функция, которая управляет отображением всех элементов UI Blizzard (1 = "Показать", 2 = "Скрыть")
function ConsoleMenu:HideBlizzardUI()

    -- Регистрируем события только если соответствующие настройки установлены на скрытие (2)
    if ConsoleMenuDB.hideTalkingHeadFrame == 2 then
        ConsoleMenu:RegisterEvent("TALKINGHEAD_REQUESTED", "HideTalkingHeadFrame")
    else
        ConsoleMenu:UnregisterEvent("TALKINGHEAD_REQUESTED")
    end
    
    if ConsoleMenuDB.hideObjectiveTrackerTopBannerFrame == 2 then
        ConsoleMenu:RegisterEvent("QUEST_LOG_UPDATE", "DisableObjectiveTrackerTopBannerFrame")
    else
        ConsoleMenu:UnregisterEvent("QUEST_LOG_UPDATE")
    end

    -- Применяем функции скрытия только если значение настройки равно 2 (скрыть)
    if ConsoleMenuDB.hideLootFrame == 2 then
        DisableLootFrame()
    end
    
    if ConsoleMenuDB.hideUIWidgetPowerBarContainerFrame == 2 then
        HideUIWidgetPowerBarContainerFrame()
    end
    
    if ConsoleMenuDB.hideUIErrorsFrame == 2 then
        DisableUIErrorsFrame()
    end
    
    if ConsoleMenuDB.hideAlertFrame == 2 then
        DisableAlertFrame()
    end
    
    if ConsoleMenuDB.hideCompactPartyFrame == 2 then
        HideCompactPartyFrame()
    end
    
    if ConsoleMenuDB.hideCompactRaidFrame == 2 then
        HideCompactRaidFrame()
    end
    
    if ConsoleMenuDB.hideStanceBar == 2 then
        HideStanceBar()
    end
    
    if ConsoleMenuDB.hideZoneTextFrame == 2 then
        DisableZoneTextFrame()
    end
    
    if ConsoleMenuDB.hideBagsBarsBar == 2 then
        HideBagsBagsBar()
    end
    
    if ConsoleMenuDB.hideMicroMenu == 2 then
        DisableMicroMenu()
    end
    
    if ConsoleMenuDB.hideMinimap == 2 then
        DisableMinimap()
    end
    
    if ConsoleMenuDB.hidePlayerCastingBarFrame == 2 then
        DisablePlayerCastingBarFrame()
    end
    
    if ConsoleMenuDB.hidePlayerFrame == 1 then
        DisablePlayerFrame()
    end
    
    if ConsoleMenuDB.hideTargetFrame == 2 then
        HideTargetFrame()
    end
    
    if ConsoleMenuDB.hidePetActionBar == 2 then
        DisablePetActionBar()
    end
    
    if ConsoleMenuDB.hideActionBar == 1 then
        DisableActionBar()
    end
    
    if ConsoleMenuDB.hideObjectiveTracker == 2 then
        HideObjectiveTrackerFrame()
    end
    
    if ConsoleMenuDB.hideBuffFrame == 2 then
        HideBuffFrame()
    end
    
    if ConsoleMenuDB.hideDebuffFrame == 2 then
        HideDebuffFrame()
    end
    
    if ConsoleMenuDB.hideZoneAbilityFrame == 2 then
        DisableZoneAbilityFrame()
    end
    
    if ConsoleMenuDB.hideBossTargetFrameContainer == 2 then
        DisableBossTargetFrameContainer()
    end

    if ConsoleMenuDB.hideSpellActivationOverlay == 2 then
        DisableSpellActivationOverlay()
    end
end