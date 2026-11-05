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

-- Возвращает значение, если клиент его не скрывает.
function Gossip.Readable(value)
    if value == nil then
        return nil
    end
    if issecretvalue and issecretvalue(value) then
        return nil
    end
    return value
end

-- Высота уже нарисованной подписи. Пока перенос не готов, берётся высота строк шрифта.
local function MeasureLabelHeight(fontString)
    local lineHeight = fontString.GetLineHeight and fontString:GetLineHeight() or 0
    local lineCount = fontString.GetNumLines and fontString:GetNumLines() or 0
    local wrapped = 0
    if lineHeight > 0 and lineCount > 0 then
        wrapped = lineHeight * lineCount
    end

    local measured = fontString:GetStringHeight() or 0
    local height = math.max(measured, wrapped)
    if height > 1 then
        return height, lineHeight
    end
    return Gossip.itemFontSize, lineHeight
end

-- Подпись ещё не перенеслась: текст ниже своих строк или всё ещё шире поля.
function Gossip.OptionTextWrapPending(fontString)
    if not fontString or not fontString:IsShown() then
        return true
    end

    local lineHeight = fontString.GetLineHeight and fontString:GetLineHeight() or 0
    local lineCount = fontString.GetNumLines and fontString:GetNumLines() or 0
    local measured = fontString:GetStringHeight() or 0
    if lineHeight > 0 and lineCount > 0 and measured + lineHeight < lineHeight * lineCount then
        return true
    end

    if lineCount <= 1 then
        local width = fontString:GetWidth() or 0
        local stringWidth = fontString:GetStringWidth() or 0
        if width <= 1 or stringWidth > width + 1 then
            return true
        end
    end

    return false
end

-- Высота пункта по высоте подписи. Одна строка остаётся обычной, лишний текст добавляет рост.
function Gossip.ExtentForLabel(fontString)
    if not fontString then
        return Gossip.sectionHeight
    end

    local textHeight, lineHeight = MeasureLabelHeight(fontString)
    if not lineHeight or lineHeight <= 1 then
        lineHeight = Gossip.itemFontSize
    end
    local extra = textHeight - lineHeight
    if extra < 1 then
        return Gossip.sectionHeight
    end
    return Gossip.sectionHeight + extra
end

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
