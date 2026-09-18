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

-- Системный шрифт клиента, чтобы подписи следовали языку и масштабу интерфейса.
ExpandableList.fontName = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
ExpandableList.maskTexturePath = "Interface\\AddOns\\ConsoleMenu\\Assets\\Mask.png"
ExpandableList.circleMaskPath = "Interface\\AddOns\\ConsoleMenu\\Assets\\MaskCircle.png"
ExpandableList.backgroundTexturePath = "Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorundDark.png"
ExpandableList.maskWrapMode = "CLAMPTOBLACKADDITIVE"
ExpandableList.iconBorderAtlas = "UI-HUD-ActionBar-IconFrame"

ExpandableList.titleColorR = 1
ExpandableList.titleColorG = 0.976
ExpandableList.titleColorB = 0.855
ExpandableList.separatorColorR = 1.0
ExpandableList.separatorColorG = 0.960784
ExpandableList.separatorColorB = 0.772549
ExpandableList.separatorColorA = 0.6

-- Путь шрифта обычных подписей с учётом языка клиента.
function ExpandableList.GetBodyFontPath()
    return STANDARD_TEXT_FONT or ExpandableList.fontName
end

-- Путь шрифта заголовка пустого списка из объекта оформления задания.
function ExpandableList.GetTitleFontPath()
    local fontObject = _G.QuestFont or _G.QuestTitleFont or _G.GameFontNormalHuge
    if fontObject and fontObject.GetFont then
        local path = fontObject:GetFont()
        if path then
            return path
        end
    end
    return ExpandableList.GetBodyFontPath()
end

-- Назначить шрифт обычной подписи.
function ExpandableList.ApplyBodyFont(fontString, size, flags)
    if not fontString then
        return
    end
    fontString:SetFont(ExpandableList.GetBodyFontPath(), size, flags or "OUTLINE")
end

-- Назначить шрифт заголовка пустого списка.
function ExpandableList.ApplyTitleFont(fontString, size, flags)
    if not fontString then
        return
    end
    fontString:SetFont(ExpandableList.GetTitleFontPath(), size, flags or "OUTLINE")
end

-- Строка является разделителем и не выбирается.
function ExpandableList.IsSeparator(element)
    return element and element.type == "separator"
end

-- Обычная строка, которую можно выбрать и раскрыть.
function ExpandableList.IsSelectable(element)
    return element ~= nil and not ExpandableList.IsSeparator(element)
end

-- Можно ли выбрать строку с учётом правила потребителя.
function ExpandableList.CanSelect(list, element)
    if not element then
        return false
    end
    if list and list.isSelectable then
        return list.isSelectable(element) and true or false
    end
    return ExpandableList.IsSelectable(element)
end

-- Совпадают ли две строки по правилу потребителя или по тождеству.
function ExpandableList.AreEqual(list, left, right)
    if not left or not right then
        return false
    end
    if list and list.areElementsEqual then
        return list.areElementsEqual(left, right) and true or false
    end
    return left == right
end
