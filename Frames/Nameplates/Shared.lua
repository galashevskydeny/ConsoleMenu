local ConsoleMenu = _G.ConsoleMenu

ConsoleMenu.Nameplates = ConsoleMenu.Nameplates or {}

local Nameplates = ConsoleMenu.Nameplates

Nameplates.healthBarHeight = 16
Nameplates.castBarHeight = 12
Nameplates.auraIconSize =24
Nameplates.castIconSize = 24
Nameplates.enemyNameFontSize = 14
Nameplates.friendNameFontSize = 16
Nameplates.uninterruptibleCastFontSize = 12
Nameplates.healthInset = 36
Nameplates.castExtraInset = 12
Nameplates.nameSpacing = 8
Nameplates.castIconSpacing = 8
Nameplates.maxAuras = 8

Nameplates.npcNameColorR = 1.0
Nameplates.npcNameColorG = 0.960784
Nameplates.npcNameColorB = 0.772549
Nameplates.npcNameColorA = 1.0

Nameplates.healthBarColorR = 0.188235
Nameplates.healthBarColorG = 0.811765
Nameplates.healthBarColorB = 0.556863

Nameplates.barTexturePath = "Interface\\AddOns\\ConsoleMenu\\Assets\\EnemyHealthBar.png"
Nameplates.maskTexturePath = "Interface\\AddOns\\ConsoleMenu\\Assets\\Mask.png"
Nameplates.circleMaskPath = "Interface\\AddOns\\ConsoleMenu\\Assets\\MaskCircle.png"
Nameplates.fontName = "Fonts\\FRIZQT___CYR.TTF"

function Nameplates.Call(object, methodName, ...)
    if object == nil then
        return false
    end
    local ok, a, b, c, d, e = pcall(function(...)
        local method = object[methodName]
        if type(method) ~= "function" then
            return
        end
        return method(object, ...)
    end, ...)
    if not ok then
        return false
    end
    return true, a, b, c, d, e
end

function Nameplates.IsForbidden(object)
    local ok, forbidden = Nameplates.Call(object, "IsForbidden")
    return (not ok) or forbidden
end

function Nameplates.SkinStatusBar(bar, r, g, b, a)
    if not bar then
        return
    end
    Nameplates.Call(bar, "SetStatusBarTexture", Nameplates.barTexturePath)
    local ok, fill = Nameplates.Call(bar, "GetStatusBarTexture")
    if ok and fill then
        Nameplates.Call(fill, "SetTexture", Nameplates.barTexturePath)
        Nameplates.Call(fill, "ClearTextureSlice")
        Nameplates.Call(fill, "SetDesaturated", true)
        Nameplates.Call(fill, "SetVertexColor", r, g, b, a)
    end
    Nameplates.Call(bar, "SetStatusBarDesaturated", true)
    Nameplates.Call(bar, "SetStatusBarColor", r, g, b, a)
end

function Nameplates.AddBarBackground(bar)
    local background = bar:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(Nameplates.barTexturePath)
    background:SetAllPoints(bar)
    background:SetVertexColor(0, 0, 0, 0.5)
    bar.background = background
    return background
end

function Nameplates.ApplyCircularMask(icon)
    if not icon or icon._consoleMenuMask then
        return
    end
    local parent = icon:GetParent()
    if not parent then
        return
    end
    local mask = parent:CreateMaskTexture()
    mask:SetTexture(Nameplates.circleMaskPath)
    mask:SetAllPoints(icon)
    icon:AddMaskTexture(mask)
    icon._consoleMenuMask = mask
end

function Nameplates.IsEnemyUnit(unit)
    if not unit then
        return false
    end
    local attackOk, canAttack = pcall(UnitCanAttack, "player", unit)
    local deadOk, isDead = pcall(UnitIsDead, unit)
    return attackOk and canAttack and deadOk and not isDead
end

function Nameplates.ShouldHideOnMount()
    if C_PvP and C_PvP.IsPVPMap and C_PvP.IsPVPMap() then
        return false
    end
    return IsMounted and IsMounted()
end

function Nameplates.GetNamePlate(unit)
    if not unit then
        return nil
    end
    local ok, nameplate = pcall(C_NamePlate.GetNamePlateForUnit, unit, issecure())
    if ok and nameplate then
        return nameplate
    end
    ok, nameplate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
    if ok then
        return nameplate
    end
    return nil
end

function Nameplates.ApplyPlateAlpha(display)
    if not display then
        return
    end
    if Nameplates.ShouldHideOnMount() then
        display:SetAlpha(0)
        return
    end
    display:SetAlpha(1)
end
