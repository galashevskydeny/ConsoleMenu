-- Общие сведения раскрывающегося списка: размеры, шрифты и цвета без состояния окна.

local ConsoleMenu = _G.ConsoleMenu

ConsoleMenu.ExpandableList = ConsoleMenu.ExpandableList or {}

local ExpandableList = ConsoleMenu.ExpandableList

ExpandableList.frameWidth = 480
ExpandableList.contentPadding = 38
ExpandableList.sectionHeight = 80
ExpandableList.sectionPadding = 10
ExpandableList.unfocusedItemTextAlpha = 0.6
ExpandableList.iconSize = ExpandableList.sectionHeight - ExpandableList.sectionPadding * 2

ExpandableList.emptyListFontSize = 32
ExpandableList.emptyListDescriptionFontSize = 20
ExpandableList.itemFontSize = 18
ExpandableList.focusedItemFontSize = ExpandableList.itemFontSize + 2
ExpandableList.descriptionFontSize = 14

ExpandableList.extraIconSize = 20
ExpandableList.extraIconOverlap = ExpandableList.extraIconSize / 4
ExpandableList.extraIconDualHeight = ExpandableList.extraIconSize * 2 - ExpandableList.extraIconOverlap

ExpandableList.backgroundVOffset = 640
ExpandableList.backgroundHOffset = 440

ExpandableList.fontName = "Fonts\\FRIZQT___CYR.TTF"
ExpandableList.emptyTitleFontName = "Fonts\\morpheus_cyr.ttf"
ExpandableList.maskTexturePath = "Interface\\AddOns\\ConsoleMenu\\Assets\\Mask.png"
ExpandableList.circleMaskPath = "Interface\\AddOns\\ConsoleMenu\\Assets\\MaskCircle.png"
ExpandableList.backgroundTexturePath = "Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorundDark.png"

ExpandableList.titleColorR = 1
ExpandableList.titleColorG = 0.976
ExpandableList.titleColorB = 0.855
ExpandableList.separatorColorR = 1.0
ExpandableList.separatorColorG = 0.960784
ExpandableList.separatorColorB = 0.772549
ExpandableList.separatorColorA = 0.6

-- Строка является разделителем и не выбирается.
function ExpandableList.IsSeparator(element)
    return element and element.type == "separator"
end

-- Обычная строка, которую можно выбрать и раскрыть.
function ExpandableList.IsSelectable(element)
    return element ~= nil and not ExpandableList.IsSeparator(element)
end
