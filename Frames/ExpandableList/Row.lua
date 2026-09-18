-- Строка раскрывающегося списка: значок, название, описание и дополнительный блок.

local ConsoleMenu = _G.ConsoleMenu
local ExpandableList = ConsoleMenu.ExpandableList

-- Создать круглую текстуру для значка дополнительного блока.
local function CreateCircleIconTexture(parent, drawLayer, subLevel)
    local texture = parent:CreateTexture(nil, drawLayer, nil, subLevel)
    local mask = parent:CreateMaskTexture()
    mask:SetAllPoints(texture)
    mask:SetTexture(ExpandableList.circleMaskPath, ExpandableList.maskWrapMode)
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
    frame.icon:Hide()
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

-- Ширина текста строки по размерам списка, без опоры на ещё не пересчитанную рамку.
local function GetTextBlockWidth(list)
    local listWidth = (list and list.frameWidth) or ExpandableList.frameWidth
    local contentPadding = (list and list.contentPadding) or ExpandableList.contentPadding
    return math.max(80, listWidth - contentPadding - ExpandableList.iconSize - ExpandableList.sectionPadding * 6)
end

-- Высота подписи по уже известному переносу, без завышения по неперенесённой ширине.
local function MeasureFontStringHeight(fontString, fallback)
    if not fontString then
        return fallback
    end

    local lineHeight = fontString.GetLineHeight and fontString:GetLineHeight() or 0
    local lineCount = fontString.GetNumLines and fontString:GetNumLines() or 0
    local wrapped = 0
    if lineHeight > 0 and lineCount > 0 then
        wrapped = lineHeight * lineCount
    end

    local measured = fontString:GetStringHeight() or 0
    local height = math.max(measured, wrapped)
    if height > 1 then
        return height
    end

    return fallback
end

-- Нужно ли ещё раз уточнить высоту: подпись ниже числа строк или одна строка всё ещё шире поля.
local function NeedsWrapRemeasure(fontString)
    if not fontString or not fontString:IsShown() then
        return false
    end

    local lineHeight = fontString.GetLineHeight and fontString:GetLineHeight() or 0
    local lineCount = fontString.GetNumLines and fontString:GetNumLines() or 0
    local measured = fontString:GetStringHeight() or 0
    if lineHeight > 0 and lineCount > 0 and measured + lineHeight < lineHeight * lineCount then
        return true
    end

    -- Длинная строка без абзацев: перенос ещё не выполнен, пока текст шире поля.
    if lineCount <= 1 then
        local width = fontString:GetWidth()
        local stringWidth = fontString:GetStringWidth() or 0
        if width and width > 0 and stringWidth > width + 1 then
            return true
        end
    end

    return false
end

-- Есть ли у раскрытой строки описание или цена, высота которых ещё не совпала со строками.
local function RowHasPendingWrap(frame)
    if not frame or not frame.text then
        return false
    end
    if NeedsWrapRemeasure(frame.text.description) then
        return true
    end
    return frame.text.extra and frame.text.extra:IsShown() and NeedsWrapRemeasure(frame.text.extra.text)
end

-- Высота дополнительного блока с учётом значков.
local function UpdateExtraHeight(frame)
    local extra = frame.text.extra
    local textHeight = MeasureFontStringHeight(extra.text, ExpandableList.itemFontSize)

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
    local titleHeight = MeasureFontStringHeight(frame.text.title, ExpandableList.itemFontSize)
    local totalHeight = titleHeight
    local hasDescription = frame.text.description and frame.text.description:IsShown()
    local descriptionHeight = 0

    if hasDescription then
        descriptionHeight = MeasureFontStringHeight(frame.text.description, ExpandableList.descriptionFontSize)
        totalHeight = totalHeight + ExpandableList.sectionPadding + descriptionHeight
    end

    if frame.text.extra and frame.text.extra:IsShown() then
        local extraHeight = MeasureFontStringHeight(frame.text.extra.text, ExpandableList.itemFontSize)
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
    if not frame.text then
        return
    end

    if frame.text.description then
        frame.text.description:SetText("")
        frame.text.description:Hide()
    end

    local extra = frame.text.extra
    if not extra then
        return
    end
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

    frame:SetScript("OnUpdate", nil)
    frame.wrapRemeasureCount = nil
    frame:SetHeight(ExpandableList.sectionHeight)
    ExpandableList.ApplyBodyFont(frame.text.title, ExpandableList.itemFontSize, "OUTLINE")
    frame.text.title:SetText(data.name or "")
    CollapseExtra(frame)

    if ExpandableList.IsSeparator(data) then
        frame.text:SetAlpha(1)
        ApplySeparatorLayout(frame)
        -- Не даём подписи разделителя сжаться до нуля при повторном показе.
        local titleHeight = MeasureFontStringHeight(frame.text.title, ExpandableList.itemFontSize)
        frame.text:SetHeight(math.max(ExpandableList.itemFontSize, titleHeight))
        return wasExpanded
    end

    frame.text:SetAlpha(ExpandableList.unfocusedItemTextAlpha)
    ApplyDefaultLayout(frame)
    frame.icon:Show()
    UpdateTextHeight(frame)
    return wasExpanded
end

-- Пересчитать высоту уже раскрытой строки без повторного сбора описания.
local function RelayoutExpandedRow(frame, list)
    if not frame or not frame.text then
        return false
    end

    if frame.text.description and frame.text.description:IsShown() then
        frame.text.description:SetWidth(GetTextBlockWidth(list))
    end

    local extra = frame.text.extra
    if extra then
        extra:ClearAllPoints()
        if frame.text.description and frame.text.description:IsShown() then
            local descriptionHeight = MeasureFontStringHeight(frame.text.description, ExpandableList.descriptionFontSize)
            local extraTopGap = ExpandableList.sectionPadding
            if descriptionHeight > ExpandableList.descriptionFontSize * 1.5 then
                extraTopGap = ExpandableList.sectionPadding * 2
            end
            extra:SetPoint("TOPLEFT", frame.text.description, "BOTTOMLEFT", 0, -extraTopGap)
        else
            extra:SetPoint("TOPLEFT", frame.text.title, "BOTTOMLEFT", 0, -ExpandableList.sectionPadding)
        end
        extra:SetPoint("TOPRIGHT", frame.text, "TOPRIGHT", 0, 0)
        if extra:IsShown() then
            UpdateExtraHeight(frame)
        end
    end

    UpdateTextHeight(frame)

    local newExtent = math.max(
        ExpandableList.sectionHeight,
        (frame.text.height or ExpandableList.sectionHeight) + ExpandableList.sectionPadding * 2
    )
    frame:SetHeight(newExtent)
    if newExtent <= ExpandableList.sectionHeight then
        ApplyDefaultLayout(frame)
    else
        ApplyExpandedLayout(frame)
    end

    local previousExtent = list and list.focusedExtent or ExpandableList.sectionHeight
    if list then
        list.focusedExtent = newExtent
    end
    return previousExtent ~= newExtent
end

-- Уточнить высоту выбранной строки после переноса и вернуть подпись группы в кадр.
local MAX_WRAP_REMEASURES = 2
local ScheduleFocusedExtentRefresh

local function RemeasureFocusedRow(frame, list)
    if not frame or not list or not frame.listData then
        return
    end
    if not list.IsFocusedElement or not list:IsFocusedElement(frame.listData) then
        return
    end

    local changed = RelayoutExpandedRow(frame, list)
    frame.wrapRemeasureCount = (frame.wrapRemeasureCount or 0) + 1
    if changed then
        if list.UpdateScrollBar then
            list:UpdateScrollBar()
        end
        if ExpandableList.ScrollFocusedIntoView then
            ExpandableList.ScrollFocusedIntoView(list)
        end
    end
    if RowHasPendingWrap(frame) and frame.wrapRemeasureCount < MAX_WRAP_REMEASURES then
        ScheduleFocusedExtentRefresh(frame, list)
    end
end

-- Уточнить высоту на следующем кадре, когда перенос уже известен.
ScheduleFocusedExtentRefresh = function(frame, list)
    if not frame or not list then
        return
    end
    frame:SetScript("OnUpdate", function(self)
        self:SetScript("OnUpdate", nil)
        RemeasureFocusedRow(self, list)
    end)
end

-- Раскрыть выбранную строку описанием и дополнительным блоком.
local function ExpandRow(frame, data, list)
    local expandInfo = nil
    if list and list.onExpand then
        expandInfo = list.onExpand(data)
    end
    expandInfo = expandInfo or {}

    ExpandableList.ApplyBodyFont(frame.text.title, ExpandableList.focusedItemFontSize, "OUTLINE")
    frame.text.title:SetText(expandInfo.title or data.name or "")
    frame.text:SetAlpha(1)
    ApplyExpandedLayout(frame)

    local descriptionText = expandInfo.description
    if descriptionText and descriptionText ~= "" then
        local descriptionWidth = GetTextBlockWidth(list)
        frame.text.description:ClearAllPoints()
        frame.text.description:SetPoint("TOPLEFT", frame.text.title, "BOTTOMLEFT", 0, -ExpandableList.sectionPadding)
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
        local descriptionHeight = MeasureFontStringHeight(frame.text.description, ExpandableList.descriptionFontSize)
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
    if newExtent <= ExpandableList.sectionHeight then
        ApplyDefaultLayout(frame)
    end

    local previousExtent = list and list.focusedExtent or ExpandableList.sectionHeight
    if list then
        list.focusedExtent = newExtent
    end

    frame.wrapRemeasureCount = 0
    if frame.text.description:IsShown() or (frame.text.extra and frame.text.extra:IsShown()) then
        ScheduleFocusedExtentRefresh(frame, list)
    end
    return previousExtent ~= newExtent
end

-- Показать или скрыть подробности выбранной строки.
function ExpandableList.SetRowFocused(frame, isFocused)
    local data = frame.listData
    if not data and frame.GetElementData then
        data = frame:GetElementData()
        frame.listData = data
    end
    if not data then
        return false
    end

    local list = frame.expandableList
    local canExpand = isFocused and ExpandableList.CanSelect(list, data)

    if not canExpand then
        return CollapseRow(frame, data)
    end

    return ExpandRow(frame, data, list)
end

-- Создать поля строки при первом показе.
local function EnsureRowWidgets(frame)
    if frame.EnableMouse then
        frame:EnableMouse(false)
    end

    if not frame.icon then
        frame:SetHeight(ExpandableList.sectionHeight)
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
        frame.icon.mask:SetTexture(ExpandableList.maskTexturePath, ExpandableList.maskWrapMode)
        frame.icon.texture:AddMaskTexture(frame.icon.mask)
    end

    if not frame.icon.border then
        frame.icon.border = frame.icon:CreateTexture(nil, "OVERLAY")
        frame.icon.border:SetAtlas(ExpandableList.iconBorderAtlas)
        frame.icon.border:SetPoint("TOPLEFT", frame.icon.texture, "TOPLEFT", -2, 2)
        frame.icon.border:SetPoint("BOTTOMRIGHT", frame.icon.texture, "BOTTOMRIGHT", 4, -4)
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
    ExpandableList.ApplyBodyFont(frame.text.title, ExpandableList.itemFontSize, "OUTLINE")

    frame.text.extra = CreateFrame("Frame", nil, frame.text)
    frame.text.extra:Hide()

    frame.text.extra.text = frame.text.extra:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.text.extra.text:SetJustifyH("LEFT")
    ExpandableList.ApplyBodyFont(frame.text.extra.text, ExpandableList.itemFontSize, "OUTLINE")
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
    ExpandableList.ApplyBodyFont(frame.text.description, ExpandableList.descriptionFontSize, "")
    frame.text.description:Hide()
end

-- Сбросить визуальное состояние перед новой отрисовкой.
local function ResetRowVisuals(frame)
    frame:SetScript("OnUpdate", nil)
    frame.wrapRemeasureCount = nil
    frame:SetHeight(ExpandableList.sectionHeight)
    ExpandableList.ApplyBodyFont(frame.text.title, ExpandableList.itemFontSize, "OUTLINE")
    frame.text.title:SetText("")
    frame.text:Show()
    frame.text:SetAlpha(1)
    frame.text:SetHeight(ExpandableList.itemFontSize)
    frame.text.title:SetAlpha(1)
    frame.text.title:SetTextColor(
        ExpandableList.titleColorR,
        ExpandableList.titleColorG,
        ExpandableList.titleColorB,
        1
    )
    ApplyDefaultLayout(frame)
    frame.icon:Show()
    frame.icon.texture:SetTexture(nil)
    frame.icon.texture:SetDesaturated(false)
    frame.icon.texture:Hide()
    frame.icon.border:Hide()
    frame.icon.overlay:Hide()
    CollapseExtra(frame)
end

-- Сбросить рамку при возврате в набор повторного использования.
function ExpandableList.ResetReleasedRow(frame)
    if not frame then
        return
    end
    frame:SetScript("OnUpdate", nil)
    frame.wrapRemeasureCount = nil
    frame.listData = nil
    frame:SetHeight(ExpandableList.sectionHeight)
    if frame.EnableMouse then
        frame:EnableMouse(false)
    end
    if frame.text then
        CollapseExtra(frame)
        ApplyDefaultLayout(frame)
        frame.text:SetHeight(ExpandableList.itemFontSize)
        frame.text:SetAlpha(1)
    end
    if frame.icon then
        frame.icon:Show()
    end
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
        local titleHeight = MeasureFontStringHeight(frame.text.title, ExpandableList.itemFontSize)
        frame.text:SetHeight(math.max(ExpandableList.itemFontSize, titleHeight))
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
