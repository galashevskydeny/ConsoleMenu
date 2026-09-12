local ConsoleMenu = _G.ConsoleMenu
local Nameplates = ConsoleMenu.Nameplates

function Nameplates.CreateHealthBar(parent)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetHeight(Nameplates.healthBarHeight)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    Nameplates.AddBarBackground(bar)
    Nameplates.SkinStatusBar(
        bar,
        Nameplates.healthBarColorR,
        Nameplates.healthBarColorG,
        Nameplates.healthBarColorB,
        1
    )

    if CreateUnitHealPredictionCalculator then
        local ok, calculator = pcall(CreateUnitHealPredictionCalculator)
        if ok and calculator then
            if calculator.SetMaximumHealthMode and Enum and Enum.UnitMaximumHealthMode then
                pcall(calculator.SetMaximumHealthMode, calculator, Enum.UnitMaximumHealthMode.WithAbsorbs)
            end
            if calculator.SetDamageAbsorbClampMode and Enum and Enum.UnitDamageAbsorbClampMode then
                pcall(calculator.SetDamageAbsorbClampMode, calculator, Enum.UnitDamageAbsorbClampMode.MaximumHealth)
            end
            bar.calculator = calculator
        end
    end

    bar:SetScript("OnEvent", function(self, event)
        if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_ABSORB_AMOUNT_CHANGED" then
            Nameplates.UpdateHealthBar(self)
        end
    end)

    return bar
end

function Nameplates.UpdateHealthBar(bar)
    local unit = bar.unit
    if not unit then
        return
    end

    local calculator = bar.calculator
    if calculator and UnitGetDetailedHealPrediction then
        pcall(UnitGetDetailedHealPrediction, unit, nil, calculator)
        local maxOk, maxHealth = pcall(calculator.GetMaximumHealth, calculator)
        local curOk, currentHealth = pcall(calculator.GetCurrentHealth, calculator)
        if maxOk and maxHealth then
            bar:SetMinMaxValues(0, maxHealth)
        end
        if curOk and currentHealth then
            bar:SetValue(currentHealth)
        end
        return
    end

    local maxOk, maxHealth = pcall(UnitHealthMax, unit)
    local curOk, currentHealth = pcall(UnitHealth, unit, true)
    if not curOk then
        curOk, currentHealth = pcall(UnitHealth, unit)
    end
    if maxOk and maxHealth then
        bar:SetMinMaxValues(0, maxHealth)
    end
    if curOk and currentHealth then
        bar:SetValue(currentHealth)
    end
end

function Nameplates.HealthBarSetUnit(bar, unit)
    bar:UnregisterAllEvents()
    bar.unit = unit
    if not unit then
        bar:Hide()
        return
    end
    pcall(bar.RegisterUnitEvent, bar, "UNIT_HEALTH", unit)
    pcall(bar.RegisterUnitEvent, bar, "UNIT_MAXHEALTH", unit)
    if not C_EventUtils or not C_EventUtils.IsEventValid or C_EventUtils.IsEventValid("UNIT_ABSORB_AMOUNT_CHANGED") then
        pcall(bar.RegisterUnitEvent, bar, "UNIT_ABSORB_AMOUNT_CHANGED", unit)
    end
    Nameplates.UpdateHealthBar(bar)
    bar:Show()
end
