local ConsoleMenu = _G.ConsoleMenu
local Nameplates = ConsoleMenu.Nameplates

local harmfulFilter = "HARMFUL|INCLUDE_NAME_PLATE_ONLY"
local playerHarmfulFilter = "HARMFUL|PLAYER|INCLUDE_NAME_PLATE_ONLY"
local crowdControlFilter = "HARMFUL|INCLUDE_NAME_PLATE_ONLY|CROWD_CONTROL"
local importantBuffFilter = "HELPFUL|INCLUDE_NAME_PLATE_ONLY|IMPORTANT"
local stealableBuffFilter = "HELPFUL|INCLUDE_NAME_PLATE_ONLY|DISPELLABLE"

local npcAuraCVar = "nameplateEnemyNpcAuraDisplay"
local playerAuraCVar = "nameplateEnemyPlayerAuraDisplay"
local showAllPersonalCVar = "nameplateShowAllPersonalAuras"
local auraScaleCVar = "nameplateAuraScale"

local settingCVars = {
    [npcAuraCVar] = true,
    [playerAuraCVar] = true,
    [showAllPersonalCVar] = true,
    [auraScaleCVar] = true,
}

-- Возвращает истину, если значение можно читать и оно истинно.
local function IsReadableTrue(value)
    if issecretvalue and issecretvalue(value) then
        return false
    end
    return value and true or false
end

-- Читает бит настройки индикатора здоровья.
local function GetCVarDisplayBit(cvarName, bitIndex)
    if bitIndex == nil then
        return nil
    end
    if CVarCallbackRegistry and CVarCallbackRegistry.GetCVarBitfieldIndex then
        local ok, value = pcall(CVarCallbackRegistry.GetCVarBitfieldIndex, CVarCallbackRegistry, cvarName, bitIndex)
        if ok and value ~= nil then
            return value and true or false
        end
    end
    if C_CVar and C_CVar.GetCVarBitfield then
        local ok, value = pcall(C_CVar.GetCVarBitfield, cvarName, bitIndex)
        if ok and value ~= nil then
            return value and true or false
        end
    end
    if GetCVarBitfield then
        local ok, value = pcall(GetCVarBitfield, cvarName, bitIndex)
        if ok and value ~= nil then
            return value and true or false
        end
    end
    return nil
end

-- Читает логическую консольную переменную.
local function GetCVarFlag(cvarName)
    if CVarCallbackRegistry and CVarCallbackRegistry.GetCVarValueBool then
        local ok, value = pcall(CVarCallbackRegistry.GetCVarValueBool, CVarCallbackRegistry, cvarName)
        if ok and value ~= nil then
            return value and true or false
        end
    end
    if GetCVarBool then
        local ok, value = pcall(GetCVarBool, cvarName)
        if ok and value ~= nil then
            return value and true or false
        end
    end
    return false
end

-- Возвращает категории эффектов, включённые в настройках индикатора.
local function GetEnabledAuraCategories(unit)
    local categories = {
        showBuffs = true,
        showDebuffs = true,
        showCrowdControl = true,
        showAllPersonal = false,
    }

    local okPlayer, isPlayer = pcall(UnitIsPlayer, unit)
    isPlayer = okPlayer and isPlayer

    local npcEnum = Enum and Enum.NamePlateEnemyNpcAuraDisplay
    local playerEnum = Enum and Enum.NamePlateEnemyPlayerAuraDisplay

    if isPlayer then
        local showBuffs = GetCVarDisplayBit(playerAuraCVar, playerEnum and playerEnum.Buffs or 1)
        local showDebuffs = GetCVarDisplayBit(playerAuraCVar, playerEnum and playerEnum.Debuffs or 2)
        local showLossOfControl = GetCVarDisplayBit(playerAuraCVar, playerEnum and playerEnum.LossOfControl or 3)
        if showBuffs ~= nil then
            categories.showBuffs = showBuffs
        end
        if showDebuffs ~= nil then
            categories.showDebuffs = showDebuffs
        end
        if showLossOfControl ~= nil then
            categories.showCrowdControl = showLossOfControl
        end
    else
        local showBuffs = GetCVarDisplayBit(npcAuraCVar, npcEnum and npcEnum.Buffs or 1)
        local showDebuffs = GetCVarDisplayBit(npcAuraCVar, npcEnum and npcEnum.Debuffs or 2)
        local showCrowdControl = GetCVarDisplayBit(npcAuraCVar, npcEnum and npcEnum.CrowdControl or 3)
        if showBuffs ~= nil then
            categories.showBuffs = showBuffs
        end
        if showDebuffs ~= nil then
            categories.showDebuffs = showDebuffs
        end
        if showCrowdControl ~= nil then
            categories.showCrowdControl = showCrowdControl
        end
    end

    categories.showAllPersonal = GetCVarFlag(showAllPersonalCVar)
    return categories
end

-- Возвращает размер значка с учётом масштаба в настройках индикатора.
local function GetAuraIconSize()
    local scale = 1
    if CVarCallbackRegistry and CVarCallbackRegistry.GetCVarNumberOrDefault then
        local ok, value = pcall(CVarCallbackRegistry.GetCVarNumberOrDefault, CVarCallbackRegistry, auraScaleCVar)
        if ok and value then
            scale = tonumber(value) or 1
        end
    elseif GetCVar then
        local ok, value = pcall(GetCVar, auraScaleCVar)
        if ok and value then
            scale = tonumber(value) or 1
        end
    end
    return Nameplates.auraIconSize * scale
end

-- Есть ли у эффекта значок, который можно показать.
local function HasAuraIcon(aura)
    local icon = aura.icon
    if issecretvalue and issecretvalue(icon) then
        return true
    end
    return icon and icon ~= 0
end

-- Нужно ли показывать личный отрицательный эффект игрока.
local function ShouldShowPersonalDebuff(aura, showAllPersonal)
    if showAllPersonal then
        return true
    end
    if IsReadableTrue(aura.nameplateShowPersonal) then
        return true
    end
    return issecretvalue and issecretvalue(aura.nameplateShowPersonal)
end

-- Обходит эффекты существа по фильтру.
local function ForEachAura(unit, filter, callback)
    for index = 1, 40 do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
        if not ok or aura == nil then
            break
        end
        callback(aura)
    end
end

-- Собирает эффекты в том же составе, что и стандартный индикатор.
local function CollectAuras(unit)
    local categories = GetEnabledAuraCategories(unit)
    local list = {}
    local seen = {}

    local function addAura(aura)
        if not aura or not HasAuraIcon(aura) then
            return
        end
        local auraInstanceID = aura.auraInstanceID
        if auraInstanceID then
            if seen[auraInstanceID] then
                return
            end
            seen[auraInstanceID] = true
        end
        list[#list + 1] = aura
    end

    if categories.showCrowdControl then
        ForEachAura(unit, crowdControlFilter, addAura)
        ForEachAura(unit, harmfulFilter, function(aura)
            if IsReadableTrue(aura.nameplateShowAll) then
                addAura(aura)
            end
        end)
    end

    if categories.showDebuffs then
        ForEachAura(unit, playerHarmfulFilter, function(aura)
            if ShouldShowPersonalDebuff(aura, categories.showAllPersonal) then
                addAura(aura)
            end
        end)
    end

    if categories.showBuffs then
        ForEachAura(unit, importantBuffFilter, addAura)
        ForEachAura(unit, stealableBuffFilter, addAura)
    end

    return list
end

-- Выставляет круговой таймер, не читая скрытые числа длительности.
local function ApplyAuraCooldown(button, unit, aura)
    local cooldown = button.cooldown
    if not cooldown then
        return
    end

    if C_UnitAuras and C_UnitAuras.GetAuraDuration and aura.auraInstanceID then
        local ok, duration = pcall(C_UnitAuras.GetAuraDuration, unit, aura.auraInstanceID)
        if ok and duration and cooldown.SetCooldownFromDurationObject then
            pcall(cooldown.SetCooldownFromDurationObject, cooldown, duration, true)
            cooldown:Show()
            return
        end
    end

    local duration = aura.duration
    local expirationTime = aura.expirationTime
    if issecretvalue and (issecretvalue(duration) or issecretvalue(expirationTime)) then
        if cooldown.SetCooldown then
            pcall(cooldown.SetCooldown, cooldown, expirationTime - duration, duration)
            cooldown:Show()
        end
        return
    end

    if duration and duration > 0 and expirationTime then
        if cooldown.SetCooldown then
            pcall(cooldown.SetCooldown, cooldown, expirationTime - duration, duration)
            cooldown:Show()
        end
        return
    end

    if cooldown.Clear then
        cooldown:Clear()
    end
    cooldown:Hide()
end

-- Скрывает кнопку эффекта и сбрасывает её таймер.
local function HideAuraButton(button)
    if not button then
        return
    end
    if button.cooldown then
        if button.cooldown.Clear then
            button.cooldown:Clear()
        end
        button.cooldown:Hide()
    end
    button:Hide()
end

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

-- Обновляет уже показанные эффекты после смены настроек индикатора.
local function RefreshAllAuras()
    if not Nameplates.ForEachActiveDisplay then
        return
    end
    Nameplates.ForEachActiveDisplay(function(display)
        if display.auras and display.unit then
            Nameplates.UpdateAuras(display.auras)
        end
    end)
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

    local auras = CollectAuras(unit)
    local iconSize = GetAuraIconSize()
    local shown = 0

    for index = 1, #auras do
        if shown >= Nameplates.maxAuras then
            break
        end
        shown = shown + 1
        local aura = auras[index]
        local button = AcquireAuraButton(container, shown)
        button:SetSize(iconSize, iconSize)
        button:Show()
        -- Значок можно выставить скрытым идентификатором, без ветвления по нему.
        button.icon:SetTexture(aura.icon)

        local applications = aura.applications
        if issecretvalue and issecretvalue(applications) then
            button.count:SetText(applications)
        elseif applications and applications > 1 then
            button.count:SetText(applications)
        else
            button.count:SetText("")
        end

        ApplyAuraCooldown(button, unit, aura)
    end

    for index = shown + 1, #container.buttons do
        HideAuraButton(container.buttons[index])
    end

    if shown > 0 then
        container:Show()
        container:SetWidth(shown * iconSize + (shown - 1) * 4)
        container:SetHeight(iconSize)
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

-- Следит за настройками индикатора здоровья и обновляет эффекты при их смене.
function Nameplates.RegisterAuraSettingEvents()
    if Nameplates.auraSettingsRegistered then
        return
    end
    Nameplates.auraSettingsRegistered = true

    if CVarCallbackRegistry and CVarCallbackRegistry.RegisterCallback then
        for cvarName in pairs(settingCVars) do
            pcall(CVarCallbackRegistry.RegisterCallback, CVarCallbackRegistry, cvarName, RefreshAllAuras)
        end
    end

    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("CVAR_UPDATE")
    watcher:SetScript("OnEvent", function(_, _, cvarName)
        if cvarName and settingCVars[cvarName] then
            RefreshAllAuras()
        end
    end)
end
