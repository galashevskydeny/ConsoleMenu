local ConsoleMenu = _G.ConsoleMenu
local Nameplates = ConsoleMenu.Nameplates

local auraFilter = "HARMFUL|INCLUDE_NAME_PLATE_ONLY"

local function AcquireAuraButton(container, index)
    local button = container.buttons[index]
    if button then
        return button
    end

    button = CreateFrame("Frame", nil, container)
    button:SetSize(Nameplates.auraIconSize, Nameplates.auraIconSize)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(button)
    local edge = 3 / Nameplates.auraIconSize
    button.icon:SetTexCoord(edge, 1 - edge, edge, 1 - edge)
    Nameplates.ApplyCircularMask(button.icon)

    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints(button)
    button.cooldown:SetDrawBling(false)
    button.cooldown:SetHideCountdownNumbers(true)
    Nameplates.Call(button.cooldown, "SetUseCircularEdge", true)
    Nameplates.Call(button.cooldown, "SetSwipeTexture", Nameplates.circleMaskPath)
    Nameplates.Call(button.cooldown, "SetReverse", true)

    button.count = button:CreateFontString(nil, "OVERLAY")
    button.count:SetFont(Nameplates.fontName, 12, "SLUG")
    button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -1)
    button.count:SetTextColor(1, 1, 1, 1)

    if index == 1 then
        button:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    else
        button:SetPoint("RIGHT", container.buttons[index - 1], "LEFT", -4, 0)
    end

    container.buttons[index] = button
    return button
end

function Nameplates.CreateAuras(parent)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(Nameplates.auraIconSize, Nameplates.auraIconSize)
    container.buttons = {}
    container:Hide()

    container:SetScript("OnEvent", function(self, event)
        if event == "UNIT_AURA" then
            Nameplates.UpdateAuras(self)
        end
    end)

    return container
end

function Nameplates.UpdateAuras(container)
    local unit = container.unit
    if not unit then
        container:Hide()
        return
    end

    local shown = 0
    for index = 1, 40 do
        if shown >= Nameplates.maxAuras then
            break
        end
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, auraFilter)
        if not (ok and aura) then
            break
        end
        shown = shown + 1
        local button = AcquireAuraButton(container, shown)
        button:Show()
        if aura.icon then
            button.icon:SetTexture(aura.icon)
        end
        if aura.applications then
            button.count:SetText(aura.applications)
        else
            button.count:SetText("")
        end
        if aura.expirationTime and aura.duration and button.cooldown.SetCooldown then
            pcall(button.cooldown.SetCooldown, button.cooldown, aura.expirationTime - aura.duration, aura.duration)
        end
    end

    for index = shown + 1, #container.buttons do
        container.buttons[index]:Hide()
    end

    if shown > 0 then
        container:Show()
        container:SetWidth(shown * Nameplates.auraIconSize + (shown - 1) * 4)
    else
        container:Hide()
    end
end

function Nameplates.AurasSetUnit(container, unit)
    container:UnregisterAllEvents()
    container.unit = unit
    if not unit then
        container:Hide()
        return
    end
    pcall(container.RegisterUnitEvent, container, "UNIT_AURA", unit)
    Nameplates.UpdateAuras(container)
end
