local ConsoleMenu = _G.ConsoleMenu
local Nameplates = ConsoleMenu.Nameplates

function Nameplates.CreateDisplay(parent)
    local display = CreateFrame("Frame", nil, parent)
    display:SetAllPoints(parent)
    pcall(display.SetFlattensRenderLayers, display, true)
    display:Hide()

    display.healthBar = Nameplates.CreateHealthBar(display)
    display.healthBar:SetPoint("BOTTOMLEFT", display, "LEFT", Nameplates.healthInset, 4)
    display.healthBar:SetPoint("BOTTOMRIGHT", display, "RIGHT", -Nameplates.healthInset, 4)

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
        for _, castEvent in ipairs(Nameplates.CastEvents()) do
            if event == castEvent then
                Nameplates.UpdateCastLayers(self.castLarge, self.castSmall, self.healthBar, self.nameFrame, self.unit)
                return
            end
        end
    end)

    return display
end

function Nameplates.UpdateName(display)
    local unit = display.unit
    if not unit then
        display.name:SetText("")
        return
    end
    local ok, name = pcall(UnitName, unit)
    if ok and name then
        display.name:SetText(name)
    end
end

function Nameplates.ApplyFriendLayout(display)
    display.healthBar:Hide()
    display.castLarge:Hide()
    display.castSmall:Hide()
    display.auras:Hide()
    display.nameFrame:ClearAllPoints()
    display.nameFrame:SetPoint("CENTER", display, "CENTER", 0, -12)
    display.name:SetFont(Nameplates.fontName, Nameplates.friendNameFontSize, "SLUG")
    display.nameFrame:SetAlpha(1)
end

function Nameplates.ApplyEnemyLayout(display)
    display.healthBar:Show()
    display.nameFrame:ClearAllPoints()
    display.nameFrame:SetPoint("BOTTOM", display.healthBar, "TOP", 0, Nameplates.nameSpacing)
    display.name:SetFont(Nameplates.fontName, Nameplates.enemyNameFontSize, "SLUG")
    display.healthBar:SetAlpha(1)
    display.nameFrame:SetAlpha(1)
end

function Nameplates.DisplaySetUnit(display, unit)
    display:UnregisterAllEvents()
    display.unit = unit
    display.isEnemy = false

    if not unit then
        Nameplates.HealthBarSetUnit(display.healthBar, nil)
        Nameplates.AurasSetUnit(display.auras, nil)
        Nameplates.ClearCastLayers(display.castLarge, display.castSmall, display.healthBar, display.nameFrame)
        display.name:SetText("")
        display:Hide()
        return
    end

    display.isEnemy = Nameplates.IsEnemyUnit(unit)
    Nameplates.UpdateName(display)
    pcall(display.RegisterUnitEvent, display, "UNIT_NAME_UPDATE", unit)

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

    display:Show()
end
