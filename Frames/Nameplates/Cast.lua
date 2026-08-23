local ConsoleMenu = _G.ConsoleMenu
local Nameplates = ConsoleMenu.Nameplates

local castEvents = {
    "UNIT_SPELLCAST_START",
    "UNIT_SPELLCAST_STOP",
    "UNIT_SPELLCAST_FAILED",
    "UNIT_SPELLCAST_INTERRUPTED",
    "UNIT_SPELLCAST_INTERRUPTIBLE",
    "UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
    "UNIT_SPELLCAST_CHANNEL_START",
    "UNIT_SPELLCAST_CHANNEL_STOP",
    "UNIT_SPELLCAST_DELAYED",
    "UNIT_SPELLCAST_CHANNEL_UPDATE",
}

if C_EventUtils and C_EventUtils.IsEventValid then
    if C_EventUtils.IsEventValid("UNIT_SPELLCAST_EMPOWER_START") then
        table.insert(castEvents, "UNIT_SPELLCAST_EMPOWER_START")
        table.insert(castEvents, "UNIT_SPELLCAST_EMPOWER_STOP")
        table.insert(castEvents, "UNIT_SPELLCAST_EMPOWER_UPDATE")
    end
else
    table.insert(castEvents, "UNIT_SPELLCAST_EMPOWER_START")
    table.insert(castEvents, "UNIT_SPELLCAST_EMPOWER_STOP")
    table.insert(castEvents, "UNIT_SPELLCAST_EMPOWER_UPDATE")
end

local function GetCastDuration(unit)
    local empowered, channelDuration, castDuration
    if UnitEmpoweredChannelDuration then
        local ok, duration = pcall(UnitEmpoweredChannelDuration, unit, true)
        if ok then
            empowered = duration
        end
    end
    if UnitChannelDuration then
        local ok, duration = pcall(UnitChannelDuration, unit)
        if ok then
            channelDuration = duration
        end
    end
    if UnitCastingDuration then
        local ok, duration = pcall(UnitCastingDuration, unit)
        if ok then
            castDuration = duration
        end
    end
    local duration = empowered or channelDuration or castDuration
    local isChannel = (empowered ~= nil) or (channelDuration ~= nil)
    local isEmpowered = empowered ~= nil
    return duration, isChannel, isEmpowered
end

local function GetCastVisuals(unit, isChannel)
    local displayName, textureID, notInterruptible
    if isChannel then
        local ok, info = pcall(function()
            return { UnitChannelInfo(unit) }
        end)
        if ok and info then
            displayName = info[2]
            textureID = info[3]
            notInterruptible = info[7]
        end
    else
        local ok, info = pcall(function()
            return { UnitCastingInfo(unit) }
        end)
        if ok and info then
            displayName = info[2]
            textureID = info[3]
            notInterruptible = info[8]
        end
    end
    if notInterruptible == nil then
        notInterruptible = false
    end
    return displayName, textureID, notInterruptible
end

local function ApplyTimer(bar, duration, isChannel, isEmpowered)
    if not duration or not bar.SetTimerDuration then
        return false
    end
    local direction = Enum.StatusBarTimerDirection.ElapsedTime
    if isChannel and not isEmpowered then
        direction = Enum.StatusBarTimerDirection.RemainingTime
    end
    local ok = pcall(bar.SetTimerDuration, bar, duration, Enum.StatusBarInterpolation.Immediate, direction)
    return ok
end

local function ApplyFallbackProgress(bar, unit, isChannel)
    local startTime, endTime
    if isChannel then
        local ok, info = pcall(function()
            return { UnitChannelInfo(unit) }
        end)
        if ok and info then
            startTime, endTime = info[4], info[5]
        end
    else
        local ok, info = pcall(function()
            return { UnitCastingInfo(unit) }
        end)
        if ok and info then
            startTime, endTime = info[4], info[5]
        end
    end
    if not startTime or not endTime then
        return
    end
    local maxValue = (endTime - startTime) / 1000
    bar:SetMinMaxValues(0, maxValue)
    if isChannel then
        bar:SetValue((endTime / 1000) - GetTime())
    else
        bar:SetValue(GetTime() - (startTime / 1000))
    end
end

function Nameplates.CreateCastLayers(parent)
    local large = CreateFrame("Frame", nil, parent)
    large:Hide()

    large.bar = CreateFrame("StatusBar", nil, large)
    large.bar:SetAllPoints(large)
    Nameplates.AddBarBackground(large.bar)
    Nameplates.SkinStatusBar(
        large.bar,
        Nameplates.npcNameColorR,
        Nameplates.npcNameColorG,
        Nameplates.npcNameColorB,
        Nameplates.npcNameColorA
    )

    large.iconFrame = CreateFrame("Frame", nil, large)
    large.iconFrame:SetSize(Nameplates.castIconSize, Nameplates.castIconSize)
    large.iconFrame:SetPoint("RIGHT", large, "LEFT", -Nameplates.castIconSpacing, 0)

    large.icon = large.iconFrame:CreateTexture(nil, "ARTWORK")
    large.icon:SetAllPoints(large.iconFrame)
    local edge = 3 / Nameplates.castIconSize
    large.icon:SetTexCoord(edge, 1 - edge, edge, 1 - edge)
    Nameplates.ApplyCircularMask(large.icon)

    large.text = large:CreateFontString(nil, "OVERLAY")
    large.text:SetFont(Nameplates.fontName, Nameplates.enemyNameFontSize, "SLUG")
    large.text:SetTextColor(
        Nameplates.npcNameColorR,
        Nameplates.npcNameColorG,
        Nameplates.npcNameColorB,
        Nameplates.npcNameColorA
    )
    large.text:SetJustifyH("CENTER")
    large.text:SetWordWrap(false)
    large.text:SetPoint("TOP", large, "BOTTOM", 0, -8)

    local small = CreateFrame("Frame", nil, parent)
    small:Hide()

    small.bar = CreateFrame("StatusBar", nil, small)
    small.bar:SetAllPoints(small)
    Nameplates.AddBarBackground(small.bar)
    Nameplates.SkinStatusBar(
        small.bar,
        Nameplates.npcNameColorR,
        Nameplates.npcNameColorG,
        Nameplates.npcNameColorB,
        Nameplates.npcNameColorA
    )

    small.text = small:CreateFontString(nil, "OVERLAY")
    small.text:SetFont(Nameplates.fontName, Nameplates.uninterruptibleCastFontSize, "SLUG")
    small.text:SetTextColor(
        Nameplates.npcNameColorR,
        Nameplates.npcNameColorG,
        Nameplates.npcNameColorB,
        Nameplates.npcNameColorA
    )
    small.text:SetJustifyH("CENTER")
    small.text:SetWordWrap(false)
    small.text:SetPoint("TOP", small, "BOTTOM", 0, -8)

    return large, small
end

function Nameplates.ClearCastLayers(large, small, healthBar, nameFrame)
    large:Hide()
    small:Hide()
    if healthBar then
        healthBar:SetAlpha(1)
    end
    if nameFrame then
        nameFrame:SetAlpha(1)
    end
    Nameplates.ApplyPlateAlpha(large and large:GetParent())
end

function Nameplates.UpdateCastLayers(large, small, healthBar, nameFrame, unit)
    if not unit then
        Nameplates.ClearCastLayers(large, small, healthBar, nameFrame)
        return
    end

    local duration, isChannel, isEmpowered = GetCastDuration(unit)
    if duration == nil then
        Nameplates.ClearCastLayers(large, small, healthBar, nameFrame)
        return
    end

    local displayName, textureID, notInterruptible = GetCastVisuals(unit, isChannel)

    large:Show()
    small:Show()

    if not ApplyTimer(large.bar, duration, isChannel, isEmpowered) then
        ApplyFallbackProgress(large.bar, unit, isChannel)
    end
    if not ApplyTimer(small.bar, duration, isChannel, isEmpowered) then
        ApplyFallbackProgress(small.bar, unit, isChannel)
    end

    if textureID then
        large.icon:SetTexture(textureID)
    end
    if displayName then
        large.text:SetText(displayName)
        small.text:SetText(displayName)
    end

    pcall(function()
        if healthBar and healthBar.SetAlphaFromBoolean then
            healthBar:SetAlphaFromBoolean(notInterruptible, 255, 0)
        end
        if nameFrame and nameFrame.SetAlphaFromBoolean then
            nameFrame:SetAlphaFromBoolean(notInterruptible, 255, 0)
        end
        if large.SetAlphaFromBoolean then
            large:SetAlphaFromBoolean(notInterruptible, 0, 255)
        end
        if small.SetAlphaFromBoolean then
            small:SetAlphaFromBoolean(notInterruptible, 255, 0)
        end
    end)
    Nameplates.ApplyPlateAlpha(large:GetParent())
end

function Nameplates.CastEvents()
    return castEvents
end
