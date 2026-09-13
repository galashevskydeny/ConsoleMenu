-- Общие сведения и состояние окна диалогов и заданий.

local ConsoleMenu = _G.ConsoleMenu

ConsoleMenu.Gossip = ConsoleMenu.Gossip or {}

local Gossip = ConsoleMenu.Gossip

Gossip.frameWidth = 600
Gossip.viewedItemCount = 3
Gossip.sectionHeight = 52
Gossip.sectionPadding = 8
Gossip.iconSize = Gossip.sectionHeight - Gossip.sectionPadding * 2
Gossip.itemFontSize = 20
Gossip.animationDuration = 0.1
Gossip.questFinishedHideDelay = Gossip.animationDuration + 0.25
-- Пауза, за которую клиент успевает открыть карту полётов вместо меню.
Gossip.taxiConfirmDelay = 0.12
Gossip.fontName = "Fonts\\FRIZQT___CYR.TTF"
Gossip.needMoreTime = "Мне нужно больше времени"
-- Значок пункта полёта у распорядителя.
Gossip.taxiGossipIcon = 132057

Gossip.focusedIndex = 1
Gossip.previousGossip = false
Gossip.savedSoftTargetEnemy = nil
Gossip.savedSoftTargetFriend = nil
Gossip.softTargetStored = false
Gossip.gamePadActive = false
Gossip.parentFrame = nil

-- Тип взаимодействия с точкой полёта в клиенте.
function Gossip.GetTaxiInteractionType()
    local types = Enum and Enum.PlayerInteractionType
    if not types then
        return nil
    end
    return types.TaxiNode or types.Taxi
end

-- Признак активного игрового контроллера.
function Gossip.IsControllerActive()
    if ConsoleMenu.IsGamePadActive then
        return ConsoleMenu:IsGamePadActive()
    end
    return Gossip.gamePadActive
end
