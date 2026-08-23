local ConsoleMenu = _G.ConsoleMenu
local Nameplates = ConsoleMenu.Nameplates

local hiddenFrame = CreateFrame("Frame")
hiddenFrame:Hide()
Nameplates.hiddenFrame = hiddenFrame

local displays = {}
local unitsToDisplay = {}

local function HideBlizzardUnitFrame(nameplate)
    local unitFrame = nameplate.UnitFrame
    if not unitFrame or Nameplates.IsForbidden(unitFrame) then
        return
    end

    unitFrame:SetParent(hiddenFrame)
    unitFrame:UnregisterAllEvents()

    if unitFrame.castBar then
        unitFrame.castBar:UnregisterAllEvents()
    elseif unitFrame.CastBarsContainer and unitFrame.CastBarsContainer.castBar then
        unitFrame.CastBarsContainer.castBar:UnregisterAllEvents()
    end

    if unitFrame.WidgetContainer then
        unitFrame.WidgetContainer:SetParent(nameplate)
    end
end

local function AcquireDisplay(nameplate)
    local display = displays[nameplate]
    if not display then
        display = Nameplates.CreateDisplay(nameplate)
        displays[nameplate] = display
    else
        display:SetParent(nameplate)
        display:SetAllPoints(nameplate)
    end
    return display
end

local function ShouldSkipUnit(unit, nameplate)
    if not unit or not nameplate or Nameplates.IsForbidden(nameplate) then
        return true
    end
    if nameplate.UnitFrame and Nameplates.IsForbidden(nameplate.UnitFrame) then
        return true
    end
    if UnitNameplateShowsWidgetsOnly and UnitNameplateShowsWidgetsOnly(unit) then
        return true
    end
    if UnitIsGameObject and UnitIsGameObject(unit) then
        return true
    end
    return false
end

local function ApplyHitTest(nameplate, hitFrame, unit)
    if not hitFrame then
        return
    end
    if nameplate.SetAllHitTestPoints then
        pcall(nameplate.SetAllHitTestPoints, nameplate, hitFrame)
    end
    if C_NamePlateManager and C_NamePlateManager.SetNamePlateHitTestFrame then
        pcall(C_NamePlateManager.SetNamePlateHitTestFrame, unit, hitFrame)
    end
end

function Nameplates.Install(unit)
    local nameplate = Nameplates.GetNamePlate(unit)
    if not nameplate then
        return
    end

    HideBlizzardUnitFrame(nameplate)

    if ShouldSkipUnit(unit, nameplate) then
        local display = displays[nameplate]
        if display then
            Nameplates.DisplaySetUnit(display, nil)
        end
        return
    end

    local display = AcquireDisplay(nameplate)
    Nameplates.DisplaySetUnit(display, unit)
    local hitFrame = display.isEnemy and display.healthBar or display.nameFrame
    ApplyHitTest(nameplate, hitFrame, unit)
    unitsToDisplay[unit] = display
end

function Nameplates.Uninstall(unit)
    local display = unitsToDisplay[unit]
    if display then
        Nameplates.DisplaySetUnit(display, nil)
        unitsToDisplay[unit] = nil
    end
end

function Nameplates.RefreshMountVisibility()
    for _, display in pairs(unitsToDisplay) do
        if display.unit then
            Nameplates.ApplyPlateAlpha(display)
        end
    end
end

function ConsoleMenu:InitializeNameplate()
    if not ConsoleMenuDB or ConsoleMenuDB.enemyNameplateStyle == 1 then
        return
    end

    ConsoleMenu:RegisterEvent("NAME_PLATE_UNIT_ADDED", function(_, _, unit)
        Nameplates.Install(unit)
    end)

    ConsoleMenu:RegisterEvent("NAME_PLATE_UNIT_REMOVED", function(_, _, unit)
        Nameplates.Uninstall(unit)
    end)

    ConsoleMenu:RegisterEvent("NAME_PLATE_CREATED", function(_, _, nameplate)
        if nameplate and not Nameplates.IsForbidden(nameplate) then
            AcquireDisplay(nameplate)
        end
    end)

    ConsoleMenu:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED", function()
        Nameplates.RefreshMountVisibility()
    end)

    for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
        local unit = nameplate.UnitFrame and nameplate.UnitFrame.unit
        if not unit then
            unit = nameplate.namePlateUnitToken or nameplate.unitToken
        end
        if not unit and nameplate.GetUnit then
            local ok, token = pcall(nameplate.GetUnit, nameplate)
            if ok then
                unit = token
            end
        end
        if unit then
            Nameplates.Install(unit)
        end
    end
end
