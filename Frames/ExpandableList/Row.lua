-- Строка раскрывающегося списка: значок, название, описание и дополнительный блок.

local ConsoleMenu = _G.ConsoleMenu
local ExpandableList = ConsoleMenu.ExpandableList

-- Создать круглую текстуру для значка дополнительного блока.
local function CreateCircleIconTexture(parent, drawLayer, subLevel)
    local texture = parent:CreateTexture(nil, drawLayer, nil, subLevel)
    local mask = parent:CreateMaskTexture()
    mask:SetAllPoints(texture)
    mask:SetTexture(ExpandableList.circleMaskPath, "CLAMPTOBLACK")
    texture:AddMaskTexture(mask)
    return texture, mask
end

-- Обычное расположение значка и текста.
local function ApplyDefaultLayout(frame)
    frame.icon:ClearAllPoints()
    frame.icon:SetPoint("LEFT", frame, "LEFT", 0, 0)
    frame.text:ClearAllPoints()
    frame.text:SetPoint("LEFT", frame.icon, "RIGHT", ExpandableList.sectionPadding * 2, -2)
    frame.text:SetPoint("RIGHT", frame, "RIGHT", -ExpandableList.sectionPadding * 4, -2)
end

-- Расположение текста разделителя без значка.
local function ApplySeparatorLayout(frame)
    frame.text:ClearAllPoints()
    frame.text:SetPoint("LEFT", frame, "LEFT", 0, -2)
    frame.text:SetPoint("RIGHT", frame, "RIGHT", -ExpandableList.sectionPadding * 4, -2)
end

-- Расположение раскрытой строки с описанием.
local function ApplyExpandedLayout(frame)
    frame.icon:ClearAllPoints()
    frame.icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -ExpandableList.sectionPadding)
    frame.text:ClearAllPoints()
    frame.text:SetPoint("TOPLEFT", frame.icon, "TOPRIGHT", ExpandableList.sectionPadding * 2, 0)
    frame.text:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -ExpandableList.sectionPadding * 4, -ExpandableList.sectionPadding)
end

-- Высота дополнительного блока с учётом значков.
local function UpdateExtraHeight(frame)
    local extra = frame.text.extra
    local textHeight = extra.text:GetStringHeight()
    if textHeight <= 0 then
        textHeight = ExpandableList.itemFontSize
    end

    local iconHeight = 0
    if extra.icon:IsShown() then
        iconHeight = ExpandableList.extraIconSize
        if extra.icon.texture2:IsShown() then
            iconHeight = ExpandableList.extraIconDualHeight
        end
    end

    extra:SetHeight(math.max(textHeight, iconHeight))
end

-- Высота текста строки: название, описание и дополнительный блок.
local function UpdateTextHeight(frame)
    local titleHeight = frame.text.title:GetStringHeight()
    if titleHeight <= 0 then
        titleHeight = ExpandableList.itemFontSize
    end

    local totalHeight = titleHeight
    local hasDescription = frame.text.description and frame.text.description:IsShown()
    local descriptionHeight = 0

    if hasDescription then
        descriptionHeight = frame.text.description:GetStringHeight()
        if descriptionHeight <= 0 then
            descriptionHeight = ExpandableList.descriptionFontSize
        end
        totalHeight = totalHeight + ExpandableList.sectionPadding + descriptionHeight
    end

    if frame.text.extra and frame.text.extra:IsShown() then
        local extraHeight = frame.text.extra.text:GetStringHeight()
        if extraHeight <= 0 then
            extraHeight = ExpandableList.itemFontSize
        end
        local extraIconHeight = ExpandableList.extraIconSize
        if frame.text.extra.icon.texture2:IsShown() then
            extraIconHeight = ExpandableList.extraIconDualHeight
        end
        extraHeight = math.max(extraHeight, extraIconHeight)
        local extraTopGap = ExpandableList.sectionPadding
        if descriptionHeight > ExpandableList.descriptionFontSize * 1.5 then
            extraTopGap = ExpandableList.sectionPadding * 2
        end
        totalHeight = totalHeight + extraTopGap + extraHeight
    end

    frame.text.height = totalHeight
    frame.text:SetHeight(totalHeight)
end

-- Скрыть описание и дополнительный блок.
local function CollapseExtra(frame)
    if frame.text.description then
        frame.text.description:SetText("")
        frame.text.description:Hide()
    end

    local extra = frame.text.extra
    extra.text:SetText("")
    extra:Hide()
    extra.icon.texture:SetTexture(nil)
    extra.icon.texture2:SetTexture(nil)
    extra.icon.texture2:Hide()
    extra.icon:SetSize(ExpandableList.extraIconSize, ExpandableList.extraIconSize)
    extra.icon:Hide()
    extra:SetHeight(0)
end

-- Показать значки дополнительного блока.
local function ApplyExtraIcons(extra, extraIcons)
    extra.icon.texture:ClearAllPoints()
    extra.icon.texture2:ClearAllPoints()

    local iconCount = extraIcons and #extraIcons or 0
    if iconCount <= 0 then
        extra.icon.texture:SetTexture(nil)
        extra.icon.texture2:SetTexture(nil)
        extra.icon.texture2:Hide()
        extra.icon:SetSize(ExpandableList.extraIconSize, ExpandableList.extraIconSize)
        extra.icon:Hide()
        extra.text:SetPoint("TOPLEFT", extra, "TOPLEFT", 0, 0)
        extra.text:SetPoint("TOPRIGHT", extra, "TOPRIGHT", 0, 0)
        return
    end

    local iconOffset = ExpandableList.extraIconSize - ExpandableList.extraIconOverlap
    if iconCount >= 2 then
        extra.icon:SetSize(ExpandableList.extraIconSize, ExpandableList.extraIconDualHeight)
        extra.icon.texture:SetPoint("TOPLEFT", extra.icon, "TOPLEFT", 0, 0)
        extra.icon.texture:SetPoint("BOTTOMRIGHT", extra.icon, "TOPLEFT", ExpandableList.extraIconSize, -ExpandableList.extraIconSize)
        extra.icon.texture:SetTexture(extraIcons[1])
        extra.icon.texture2:SetTexture(extraIcons[2])
        extra.icon.texture2:SetPoint("TOPLEFT", extra.icon, "TOPLEFT", 0, -iconOffset)
        extra.icon.texture2:SetPoint(
            "BOTTOMRIGHT",
            extra.icon,
            "TOPLEFT",
            ExpandableList.extraIconSize,
            -(ExpandableList.extraIconSize + iconOffset)
        )
        extra.icon.texture2:Show()
    else
        extra.icon:SetSize(ExpandableList.extraIconSize, ExpandableList.extraIconSize)
        extra.icon.texture:SetAllPoints()
        extra.icon.texture:SetTexture(extraIcons[1])
        extra.icon.texture2:SetTexture(nil)
        extra.icon.texture2:Hide()
    end

    extra.icon:SetPoint("LEFT", extra, "LEFT", 0, 0)
    extra.icon:Show()
    extra.text:SetPoint("LEFT", extra.icon, "RIGHT", ExpandableList.sectionPadding, 0)
    extra.text:SetPoint("RIGHT", extra, "RIGHT", 0, 0)
end

-- Свернуть выбранную строку к обычной высоте.
local function CollapseRow(frame, data)
    local wasExpanded = frame:GetHeight() > ExpandableList.sectionHeight
    local descriptionHidden = frame.text.description and not frame.text.description:IsShown()
    if not wasExpanded and descriptionHidden then
        frame.text.title:SetFont(ExpandableList.fontName, ExpandableList.itemFontSize, "OUTLINE")
        frame.text.title:SetText(data.name or "")
        if ExpandableList.IsSeparator(data) then
            frame.text:SetAlpha(1)
        else
            frame.text:SetAlpha(ExpandableList.unfocusedItemTextAlpha)
        end
        return false
    end

    frame:SetHeight(ExpandableList.sectionHeight)
    frame.text.title:SetFont(ExpandableList.fontName, ExpandableList.itemFontSize, "OUTLINE")
    frame.text.title:SetText(data.name or "")
    if ExpandableList.IsSeparator(data) then
        frame.text:SetAlpha(1)
        ApplySeparatorLayout(frame)
    else
        frame.text:SetAlpha(ExpandableList.unfocusedItemTextAlpha)
        ApplyDefaultLayout(frame)
    end
    CollapseExtra(frame)
    UpdateTextHeight(frame)
    return wasExpanded
end

-- Раскрыть выбранную строку описанием и дополнительным блоком.
local function ExpandRow(frame, data, list)
    local expandInfo = nil
    if list and list.onExpand then
        expandInfo = list.onExpand(data)
    end
    expandInfo = expandInfo or {}

    frame.text.title:SetFont(ExpandableList.fontName, ExpandableList.focusedItemFontSize, "OUTLINE")
    frame.text.title:SetText(expandInfo.title or data.name or "")
    frame.text:SetAlpha(1)

    local descriptionText = expandInfo.description
    if descriptionText and descriptionText ~= "" then
        local listWidth = (list and list.frameWidth) or ExpandableList.frameWidth
        local contentPadding = (list and list.contentPadding) or ExpandableList.contentPadding
        local descriptionWidth = math.max(80, listWidth - contentPadding - ExpandableList.iconSize - ExpandableList.sectionPadding * 6)
        frame.text.description:ClearAllPoints()
        frame.text.description:SetPoint("TOPLEFT", frame.text.title, "BOTTOMLEFT", 0, -ExpandableList.sectionPadding)
        frame.text.description:SetPoint("TOPRIGHT", frame.text.title, "BOTTOMRIGHT", 0, -ExpandableList.sectionPadding)
        frame.text.description:SetWidth(descriptionWidth)
        frame.text.description:SetText(descriptionText)
        frame.text.description:Show()
    else
        frame.text.description:SetText("")
        frame.text.description:Hide()
    end

    local extra = frame.text.extra
    extra:ClearAllPoints()
    extra.icon:ClearAllPoints()
    extra.text:ClearAllPoints()

    if frame.text.description:IsShown() then
        local descriptionHeight = frame.text.description:GetStringHeight()
        local extraTopGap = ExpandableList.sectionPadding
        if descriptionHeight > ExpandableList.descriptionFontSize * 1.5 then
            extraTopGap = ExpandableList.sectionPadding * 2
        end
        extra:SetPoint("TOPLEFT", frame.text.description, "BOTTOMLEFT", 0, -extraTopGap)
    else
        extra:SetPoint("TOPLEFT", frame.text.title, "BOTTOMLEFT", 0, -ExpandableList.sectionPadding)
    end
    extra:SetPoint("TOPRIGHT", frame.text, "TOPRIGHT", 0, 0)

    local extraText = expandInfo.extraText
    if extraText and extraText ~= "" then
        ApplyExtraIcons(extra, expandInfo.extraIcons)
        extra.text:SetText(extraText)
        UpdateExtraHeight(frame)
        extra:Show()
    else
        ApplyExtraIcons(extra, nil)
        extra.text:SetText("")
        extra:Hide()
        extra:SetHeight(0)
    end

    UpdateTextHeight(frame)

    local newExtent = math.max(ExpandableList.sectionHeight, (frame.text.height or ExpandableList.sectionHeight) + ExpandableList.sectionPadding * 2)
    frame:SetHeight(newExtent)
    if newExtent > ExpandableList.sectionHeight then
        ApplyExpandedLayout(frame)
    else
        ApplyDefaultLayout(frame)
    end

    local previousExtent = list and list.focusedExtent or ExpandableList.sectionHeight
    if list then
        list.focusedExtent = newExtent
    end
    return previousExtent ~= newExtent
end

-- Показать или скрыть подробности выбранной строки.
function ExpandableList.SetRowFocused(frame, isFocused)
    local data = frame.listData
    if not data then
        return false
    end

    local list = frame.expandableList
    local canExpand = isFocused and ExpandableList.IsSelectable(data)
    if list and list.isSelectable then
        canExpand = isFocused and list.isSelectable(data)
    end

    if not canExpand then
        return CollapseRow(frame, data)
    end

    return ExpandRow(frame, data, list)
end

-- Создать поля строки при первом показе.
local function EnsureRowWidgets(frame)
    if not frame.icon then
        frame.icon = CreateFrame("Frame", nil, frame)
        frame.icon:SetSize(ExpandableList.iconSize, ExpandableList.iconSize)
        frame.icon:SetPoint("LEFT", 0, 0)
    end

    if not frame.icon.texture then
        frame.icon.texture = frame.icon:CreateTexture(nil, "ARTWORK")
        frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", 2, -2)
        frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -2, 2)
    end

    if not frame.icon.mask then
        frame.icon.mask = frame.icon:CreateMaskTexture()
        frame.icon.mask:SetAllPoints(frame.icon)
        frame.icon.mask:SetTexture(ExpandableList.maskTexturePath, "CLAMPTOBLACK")
        frame.icon.texture:AddMaskTexture(frame.icon.mask)
    end

    if not frame.icon.border then
        frame.icon.border = frame.icon:CreateTexture(nil, "OVERLAY")
        frame.icon.border:SetAtlas("plunderstorm-actionbar-slot-border")
        frame.icon.border:SetPoint("TOPLEFT", frame.icon.texture, "TOPLEFT", -11, 11)
        frame.icon.border:SetPoint("BOTTOMRIGHT", frame.icon.texture, "BOTTOMRIGHT", 11, -11)
    end

    if not frame.icon.overlay then
        frame.icon.overlay = frame.icon:CreateTexture(nil, "OVERLAY", nil, 1)
        frame.icon.overlay:SetAllPoints(frame.icon.texture)
    end

    if frame.text then
        return
    end

    frame.text = CreateFrame("Frame", nil, frame)
    frame.text:SetPoint("LEFT", frame.icon, "RIGHT", ExpandableList.sectionPadding * 2, 0)
    frame.text:SetHeight(ExpandableList.sectionHeight)

    frame.text.title = frame.text:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.text.title:SetPoint("TOPLEFT", frame.text, "TOPLEFT", 0, 0)
    frame.text.title:SetPoint("TOPRIGHT", frame.text, "TOPRIGHT", 0, 0)
    frame.text.title:SetJustifyH("LEFT")
    frame.text.title:SetFont(ExpandableList.fontName, ExpandableList.itemFontSize, "OUTLINE")

    frame.text.extra = CreateFrame("Frame", nil, frame.text)
    frame.text.extra:Hide()

    frame.text.extra.text = frame.text.extra:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.text.extra.text:SetJustifyH("LEFT")
    frame.text.extra.text:SetFont(ExpandableList.fontName, ExpandableList.itemFontSize, "OUTLINE")
    frame.text.extra.text:SetTextColor(
        ExpandableList.titleColorR,
        ExpandableList.titleColorG,
        ExpandableList.titleColorB,
        1
    )

    frame.text.extra.icon = CreateFrame("Frame", nil, frame.text.extra)
    frame.text.extra.icon:SetSize(ExpandableList.extraIconSize, ExpandableList.extraIconSize)
    frame.text.extra.icon.texture, frame.text.extra.icon.mask = CreateCircleIconTexture(
        frame.text.extra.icon,
        "ARTWORK",
        0
    )
    frame.text.extra.icon.texture:SetAllPoints()
    frame.text.extra.icon.texture2, frame.text.extra.icon.mask2 = CreateCircleIconTexture(
        frame.text.extra.icon,
        "ARTWORK",
        1
    )
    frame.text.extra.icon.texture2:Hide()
    frame.text.extra.icon:Hide()

    frame.text.description = frame.text:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.text.description:SetJustifyH("LEFT")
    frame.text.description:SetJustifyV("TOP")
    frame.text.description:SetNonSpaceWrap(true)
    frame.text.description:SetWordWrap(true)
    frame.text.description:SetFont(ExpandableList.fontName, ExpandableList.descriptionFontSize, "")
    frame.text.description:Hide()
end

-- Сбросить визуальное состояние перед новой отрисовкой.
local function ResetRowVisuals(frame)
    frame.text.title:SetText("")
    frame.text:Show()
    frame.text:SetAlpha(1)
    frame.text.title:SetAlpha(1)
    frame.text.title:SetTextColor(
        ExpandableList.titleColorR,
        ExpandableList.titleColorG,
        ExpandableList.titleColorB,
        1
    )
    frame.icon:Show()
    frame.icon.texture:SetTexture(nil)
    frame.icon.texture:SetDesaturated(false)
    frame.icon.texture:Hide()
    frame.icon.border:Hide()
    frame.icon.overlay:Hide()
    CollapseExtra(frame)
end

-- Отрисовать строку списка по данным.
function ExpandableList.InitializeRow(frame, data, list)
    if not frame then
        return
    end

    EnsureRowWidgets(frame)
    frame.expandableList = list
    ResetRowVisuals(frame)

    if not data then
        frame.listData = nil
        frame:SetHeight(ExpandableList.sectionHeight)
        frame.text:Hide()
        return
    end

    frame.listData = data
    frame.text.title:SetText(data.name or "")

    if ExpandableList.IsSeparator(data) then
        ApplySeparatorLayout(frame)
        frame.text.title:SetTextColor(
            ExpandableList.separatorColorR,
            ExpandableList.separatorColorG,
            ExpandableList.separatorColorB,
            ExpandableList.separatorColorA
        )
        frame.icon:Hide()
    else
        ApplyDefaultLayout(frame)
        frame.text.title:SetTextColor(
            ExpandableList.titleColorR,
            ExpandableList.titleColorG,
            ExpandableList.titleColorB,
            1
        )
        if data.texture then
            frame.icon.texture:SetTexture(data.texture)
            frame.icon.texture:SetDesaturated(data.isUnavailable or false)
            frame.icon.texture:Show()
            frame.icon.border:Show()
        end
        if list and list.onDecorateIcon then
            list.onDecorateIcon(frame.icon, data)
        end
    end

    frame.SetFocused = ExpandableList.SetRowFocused
    local isFocused = list and list.IsFocusedElement and list:IsFocusedElement(data)
    frame:SetFocused(isFocused)
end
