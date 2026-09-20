local ConsoleMenu = _G.ConsoleMenu
local Nameplates = ConsoleMenu.Nameplates

-- Собирает слой индикатора: здоровье, имя, звание, заклинание и ауры.
function Nameplates.CreateDisplay(parent)
    local display = CreateFrame("Frame", nil, parent)
    display:SetAllPoints(parent)
    pcall(display.SetFlattensRenderLayers, display, true)
    pcall(display.SetClipsChildren, display, false)
    pcall(parent.SetClipsChildren, parent, false)
    display:Hide()

    display.healthBar = Nameplates.CreateHealthBar(display)
    display.healthBar:SetPoint("BOTTOMLEFT", display, "LEFT", Nameplates.healthInset, 4)
    display.healthBar:SetPoint("BOTTOMRIGHT", display, "RIGHT", -Nameplates.healthInset, 4)

    display.shadow = display:CreateTexture(nil, "BACKGROUND")
    display.shadow:SetTexture(Nameplates.shadowTexturePath)
    display.shadow:SetVertexColor(0, 0, 0, Nameplates.shadowAlpha)
    display.shadow:SetPoint("TOPLEFT", display.healthBar, "TOPLEFT", -Nameplates.shadowPadding, Nameplates.shadowPadding)
    display.shadow:SetPoint("BOTTOMRIGHT", display.healthBar, "BOTTOMRIGHT", Nameplates.shadowPadding, -Nameplates.shadowPadding)
    display.shadow:Hide()

    display.nameFrame = CreateFrame("Frame", nil, display)
    display.nameFrame:SetSize(10, 10)
    display.nameFrame:SetPoint("BOTTOM", display.healthBar, "TOP", 0, Nameplates.nameSpacing)

    display.name = display.nameFrame:CreateFontString(nil, "OVERLAY")
    display.name:SetFont(Nameplates.fontName, Nameplates.enemyNameFontSize, "SLUG")
    display.name:SetTextColor(
        Nameplates.npcNameColorR,
        Nameplates.npcNameColorG,
        Nameplates.npcNameColorB,
        Nameplates.npcNameColorA
    )
    display.name:SetJustifyH("CENTER")
    display.name:SetWordWrap(false)
    display.name:SetPoint("BOTTOM", display.nameFrame, "BOTTOM", 0, 0)

    display.castLarge, display.castSmall = Nameplates.CreateCastLayers(display)
    display.castLarge:SetPoint("TOPLEFT", display.healthBar, "TOPLEFT", 0, 0)
    display.castLarge:SetPoint("BOTTOMRIGHT", display.healthBar, "BOTTOMRIGHT", 0, 0)

    display.castSmall:SetPoint("TOPLEFT", display.healthBar, "BOTTOMLEFT", Nameplates.castExtraInset, -4)
    display.castSmall:SetPoint("TOPRIGHT", display.healthBar, "BOTTOMRIGHT", -Nameplates.castExtraInset, -4)
    display.castSmall:SetHeight(Nameplates.castBarHeight)

    display.auras = Nameplates.CreateAuras(display)
    display.auras:SetPoint("RIGHT", display.healthBar, "LEFT", -8, 0)

    local healthLevel = display.healthBar:GetFrameLevel()
    display.castSmall:SetFrameLevel(healthLevel + 2)
    display.castLarge:SetFrameLevel(healthLevel + 3)
    display.auras:SetFrameLevel(healthLevel + 4)
    display.nameFrame:SetFrameLevel(healthLevel + 5)

    display:SetScript("OnEvent", function(self, event, eventUnit)
        if event == "UNIT_NAME_UPDATE" then
            Nameplates.UpdateName(self)
            return
        end
        if event == "UNIT_HEALTH" or event == "UNIT_FLAGS" then
            Nameplates.UpdateDeathVisibility(self)
            return
        end
        for _, castEvent in ipairs(Nameplates.CastEvents()) do
            if event == castEvent then
                Nameplates.UpdateCastLayers(self.castLarge, self.castSmall, self.healthBar, self.nameFrame, self.unit)
                return
            end
        end
    end)

    return display
end

-- Показывает тень только у увеличенного индикатора противника.
function Nameplates.ApplyFocusShadow(display)
    local shadow = display.shadow
    if not shadow then
        return
    end
    local shouldShow = display.unit and display.isEnemy and Nameplates.ShouldShowEnemyName(display.unit)
    shadow:SetShown(shouldShow)
end

-- Показывает имя противника только на увеличенном индикаторе цели.
function Nameplates.ApplyNameVisibility(display)
    local shouldShow = false
    if display.unit then
        if display.isEnemy then
            shouldShow = Nameplates.ShouldShowEnemyName(display.unit)
        else
            shouldShow = true
        end
    end
    display.name:SetShown(shouldShow)
    if display.castLarge and display.castLarge.unitName then
        display.castLarge.unitName:SetShown(shouldShow)
    end
    Nameplates.ApplyFocusShadow(display)
end

-- Обновляет имя (у игрока — со званием) на индикаторе и на крупном слое заклинания.
function Nameplates.UpdateName(display)
    local name = Nameplates.GetUnitDisplayName(display.unit)
    display.name:SetText(name)
    if display.castLarge and display.castLarge.unitName then
        display.castLarge.unitName:SetText(name)
    end
    Nameplates.ApplyNameVisibility(display)
end

-- Обновляет видимость имён на всех показанных индикаторах.
function Nameplates.RefreshNameVisibility()
    if not Nameplates.ForEachActiveDisplay then
        return
    end
    Nameplates.ForEachActiveDisplay(function(display)
        Nameplates.ApplyNameVisibility(display)
    end)
end

-- Раскладка союзника: только имя и звание по центру.
function Nameplates.ApplyFriendLayout(display)
    display.healthBar:Hide()
    display.castLarge:Hide()
    display.castSmall:Hide()
    display.auras:Hide()
    display.nameFrame:ClearAllPoints()
    display.nameFrame:SetPoint("CENTER", display, "CENTER", 0, -12)
    display.name:SetFont(Nameplates.fontName, Nameplates.friendNameFontSize, "SLUG")
    display.nameFrame:SetAlpha(1)
    Nameplates.ApplyNameVisibility(display)
end

-- Раскладка противника: полоса здоровья, имя и звание сверху у цели.
function Nameplates.ApplyEnemyLayout(display)
    display.healthBar:Show()
    display.nameFrame:ClearAllPoints()
    display.nameFrame:SetPoint("BOTTOM", display.healthBar, "TOP", 0, Nameplates.nameSpacing)
    display.name:SetFont(Nameplates.fontName, Nameplates.enemyNameFontSize, "SLUG")
    display.healthBar:SetAlpha(1)
    display.nameFrame:SetAlpha(1)
    Nameplates.ApplyNameVisibility(display)
end

-- Скрывает индикатор сразу после смерти существа.
function Nameplates.UpdateDeathVisibility(display)
    if not display then
        return
    end
    if display.unit and Nameplates.ShouldHideDeadUnit(display.unit) then
        display:Hide()
        return
    end
    if display.unit then
        display:Show()
    end
end

-- Привязывает индикатор к существу или скрывает его.
function Nameplates.DisplaySetUnit(display, unit)
    display:UnregisterAllEvents()
    display.unit = unit
    display.isEnemy = false

    if not unit then
        Nameplates.HealthBarSetUnit(display.healthBar, nil)
        Nameplates.AurasSetUnit(display.auras, nil)
        Nameplates.ClearCastLayers(display.castLarge, display.castSmall, display.healthBar, display.nameFrame)
        Nameplates.UpdateName(display)
        display:Hide()
        return
    end

    display.isEnemy = Nameplates.IsEnemyUnit(unit)
    Nameplates.UpdateName(display)
    pcall(display.RegisterUnitEvent, display, "UNIT_NAME_UPDATE", unit)
    pcall(display.RegisterUnitEvent, display, "UNIT_HEALTH", unit)
    if not C_EventUtils or not C_EventUtils.IsEventValid or C_EventUtils.IsEventValid("UNIT_FLAGS") then
        pcall(display.RegisterUnitEvent, display, "UNIT_FLAGS", unit)
    end

    if display.isEnemy then
        Nameplates.ApplyEnemyLayout(display)
        Nameplates.HealthBarSetUnit(display.healthBar, unit)
        Nameplates.AurasSetUnit(display.auras, unit)
        for _, eventName in ipairs(Nameplates.CastEvents()) do
            pcall(display.RegisterUnitEvent, display, eventName, unit)
        end
        Nameplates.UpdateCastLayers(display.castLarge, display.castSmall, display.healthBar, display.nameFrame, unit)
    else
        Nameplates.ApplyFriendLayout(display)
        Nameplates.HealthBarSetUnit(display.healthBar, nil)
        Nameplates.AurasSetUnit(display.auras, nil)
        Nameplates.ClearCastLayers(display.castLarge, display.castSmall, display.healthBar, display.nameFrame)
        Nameplates.ApplyPlateAlpha(display)
    end

    Nameplates.UpdateDeathVisibility(display)
end
