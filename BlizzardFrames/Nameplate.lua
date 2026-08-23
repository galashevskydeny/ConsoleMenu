local ConsoleMenu = _G.ConsoleMenu
local healthBarHeight = 16
local castBarHeight = 12
local auraIconSize = 32
local healthInset = 36
local castExtraInset = 12
local npcNameColorR, npcNameColorG, npcNameColorB, npcNameColorA = 1.0, 0.960784, 0.772549, 1.0
local healthBarColorR, healthBarColorG, healthBarColorB = 0.188235, 0.811765, 0.556863
local barTexturePath = "Interface\\AddOns\\ConsoleMenu\\Assets\\EnemyHealthBar.png"
local fontName = "Fonts\\FRIZQT___CYR.TTF"
local namedPoints = {
    "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT",
    "LEFT", "RIGHT", "TOP", "BOTTOM", "CENTER",
}

local function CallWidget(object, methodName, ...)
    if object == nil then
        return false
    end
    local ok, result = pcall(function(...)
        local method = object[methodName]
        if type(method) ~= "function" then
            return nil
        end
        return method(object, ...)
    end, ...)
    if not ok then
        return false
    end
    return true, result
end

local function IsForbiddenObject(object)
    local ok, forbidden = CallWidget(object, "IsForbidden")
    return (not ok) or forbidden
end

local function ClearAllNamedPoints(region)
    if not region then
        return
    end
    local ok, hasClearPoint = pcall(function()
        return region.ClearPoint ~= nil
    end)
    if ok and hasClearPoint then
        for _, point in ipairs(namedPoints) do
            CallWidget(region, "ClearPoint", point)
        end
    else
        CallWidget(region, "ClearAllPoints")
    end
end

-- SetAtlas(nil) в Midnight недопустим (atlas не nilable). SetTexture снимает атлас;
-- ClearTextureSlice убирает nineslice от ui-castingbar-filling-*, иначе tint не берётся.
-- resetTexCoord только для фона: на fill StatusBar сам кропает ширину, SetTexCoord(0,1)
-- каждый кадр сбрасывает обрезку и даёт моргание / срезанный правый край.
local function SetFileTexture(region, path, resetTexCoord)
    if not region then
        return
    end
    CallWidget(region, "SetTexture", path)
    CallWidget(region, "ClearTextureSlice")
    if resetTexCoord then
        CallWidget(region, "SetTexCoord", 0, 1, 0, 1)
    end
end

local function ApplyBarColor(bar, texture, r, g, b, a)
    if bar then
        CallWidget(bar, "SetStatusBarDesaturated", true)
        CallWidget(bar, "SetStatusBarColor", r, g, b, a)
    end
    if texture then
        CallWidget(texture, "SetDesaturated", true)
        CallWidget(texture, "SetVertexColor", r, g, b, a)
    end
end

local function GetUnitFrameCastBar(unitFrame)
    if not unitFrame then
        return nil
    end
    if unitFrame.castBar then
        return unitFrame.castBar
    end
    local container = unitFrame.CastBarsContainer
    return container and container.castBar
end

local function IsNamePlateUnitFrame(frame)
    return frame ~= nil
        and frame.HealthBarsContainer ~= nil
        and GetUnitFrameCastBar(frame) ~= nil
end

local function IsNamePlateCastBar(castBar)
    if not castBar then
        return false
    end
    if NamePlateCastingBarMixin and castBar.ShouldShowCastBar == NamePlateCastingBarMixin.ShouldShowCastBar then
        return true
    end
    local ok, parent = CallWidget(castBar, "GetParent")
    return ok and parent ~= nil and parent.castBar == castBar and parent.HealthBarsContainer ~= nil
end

local function IsEnemyNameplate(unitFrame)
    if not unitFrame then
        return false
    end
    if unitFrame.IsFriend then
        local ok, isFriend = CallWidget(unitFrame, "IsFriend")
        if ok then
            return not isFriend
        end
    end
    local unit = unitFrame.unit
    if not unit then
        return false
    end
    local attackOk, canAttack = pcall(UnitCanAttack, "player", unit)
    local deadOk, isDead = pcall(UnitIsDead, unit)
    return attackOk and canAttack and deadOk and not isDead
end

local function ApplyCastBarFill(castBar)
    if not castBar then
        return
    end
    -- SetStatusBarTexture с addon-кода tainted и молча падает; меняем сам fill.
    local ok, fillTexture = CallWidget(castBar, "GetStatusBarTexture")
    if not (ok and fillTexture) then
        fillTexture = nil
    else
        SetFileTexture(fillTexture, barTexturePath)
    end
    ApplyBarColor(castBar, fillTexture, npcNameColorR, npcNameColorG, npcNameColorB, npcNameColorA)
    if castBar.Spark then
        CallWidget(castBar.Spark, "Hide")
    end
    if castBar.Flash then
        CallWidget(castBar.Flash, "Hide")
        CallWidget(castBar.Flash, "SetAlpha", 0)
    end
end

local function EnsureCastBarFillHook(castBar)
    if not castBar or castBar._consoleMenuFillHook then
        return
    end
    castBar._consoleMenuFillHook = true
    local function reapplyFill(self)
        if self._consoleMenuApplyingFill then
            return
        end
        self._consoleMenuApplyingFill = true
        ApplyCastBarFill(self)
        self._consoleMenuApplyingFill = false
    end
    -- Только смена атласа Blizzard. SetValue/OnUpdate каждый кадр снова
    -- ставили текстуру и срезали правый край fill.
    hooksecurefunc(castBar, "SetStatusBarTexture", reapplyFill)
end

local function HideHealthOverlays(healthBar)
    if not healthBar then
        return
    end
    if healthBar.deselectedOverlay then
        CallWidget(healthBar.deselectedOverlay, "Hide")
    end
    if healthBar.selectedBorder then
        CallWidget(healthBar.selectedBorder, "Hide")
        CallWidget(healthBar.selectedBorder, "SetAlpha", 0)
    end
end

local function ApplyCastBarSkin(castBar)
    if not castBar then
        return
    end

    EnsureCastBarFillHook(castBar)
    if not castBar._consoleMenuFillSkinned then
        ApplyCastBarFill(castBar)
        castBar._consoleMenuFillSkinned = true
    end
    pcall(PixelUtil.SetHeight, castBar, castBarHeight)

    local icon = castBar.Icon
    if icon then
        local iconSize = 16
        if NamePlateSetupOptions and NamePlateSetupOptions.castIconWidth then
            iconSize = NamePlateSetupOptions.castIconWidth
        end
        ClearAllNamedPoints(icon)
        pcall(PixelUtil.SetSize, icon, iconSize, iconSize)
        pcall(PixelUtil.SetPoint, icon, "RIGHT", castBar, "LEFT", -4, 0)
    end
    if castBar.BorderShield then
        CallWidget(castBar.BorderShield, "Hide")
    end
    if castBar.Border then
        CallWidget(castBar.Border, "Hide")
    end
    if castBar.BarBorder then
        CallWidget(castBar.BarBorder, "Hide")
    end
    if castBar.ImportantCastIndicator then
        CallWidget(castBar.ImportantCastIndicator, "Hide")
    end
    if castBar.CastTargetIndicator then
        CallWidget(castBar.CastTargetIndicator, "Hide")
    end
    if castBar.StandardGlow then
        CallWidget(castBar.StandardGlow, "Hide")
    end
    if castBar.ChannelShadow then
        CallWidget(castBar.ChannelShadow, "Hide")
    end
    if castBar.CraftingGlow then
        CallWidget(castBar.CraftingGlow, "Hide")
    end

    local background = castBar.Background or castBar.background or castBar.bgTexture
    if background then
        if not background._consoleMenuSkinned then
            SetFileTexture(background, barTexturePath, true)
            CallWidget(background, "SetVertexColor", 0, 0, 0, 0.5)
            background._consoleMenuSkinned = true
        end
        ClearAllNamedPoints(background)
        pcall(PixelUtil.SetPoint, background, "TOPLEFT", castBar, "TOPLEFT", 1, 0)
        pcall(PixelUtil.SetPoint, background, "BOTTOMRIGHT", castBar, "BOTTOMRIGHT", -1, 0)
        CallWidget(background, "Show")
    end

    local text = castBar.Text
    if text then
        ClearAllNamedPoints(text)
        CallWidget(text, "SetWidth", 0)
        CallWidget(text, "SetWordWrap", false)
        CallWidget(text, "SetJustifyH", "CENTER")
        CallWidget(text, "SetFont", fontName, 12, "SLUG")
        CallWidget(text, "SetTextColor", npcNameColorR, npcNameColorG, npcNameColorB, npcNameColorA)
        pcall(PixelUtil.SetPoint, text, "TOP", castBar, "BOTTOM", 0, -8)
    end

    local targetText = castBar.CastTargetNameText
    if targetText then
        ClearAllNamedPoints(targetText)
        CallWidget(targetText, "SetWidth", 0)
        CallWidget(targetText, "SetWordWrap", false)
        CallWidget(targetText, "SetJustifyH", "CENTER")
        CallWidget(targetText, "SetTextColor", npcNameColorR, npcNameColorG, npcNameColorB, npcNameColorA)
        if text then
            pcall(PixelUtil.SetPoint, targetText, "TOP", text, "BOTTOM", 0, -2)
        else
            pcall(PixelUtil.SetPoint, targetText, "TOP", castBar, "BOTTOM", 0, -8)
        end
    end
end

local function SetNameplateVisualAlpha(unitFrame, alpha)
    local container = unitFrame.HealthBarsContainer
    local castBar = GetUnitFrameCastBar(unitFrame)
    if container then
        CallWidget(container, "SetAlpha", alpha)
    end
    if castBar then
        CallWidget(castBar, "SetAlpha", alpha)
    end
    if unitFrame.name then
        CallWidget(unitFrame.name, "SetAlpha", alpha)
    end
    if unitFrame.AurasFrame then
        CallWidget(unitFrame.AurasFrame, "SetAlpha", alpha)
    end
end

-- Полный стек якорей после Blizzard UpdateAnchors: HP → cast от HP → имя → дебаффы.
local function ApplyConsoleNameplate(unitFrame)
    if IsForbiddenObject(unitFrame) then
        return
    end

    local container = unitFrame.HealthBarsContainer
    local healthBar = container and container.healthBar
    local name = unitFrame.name
    local castBar = GetUnitFrameCastBar(unitFrame)
    local aurasFrame = unitFrame.AurasFrame
    local debuffs = aurasFrame and aurasFrame.DebuffListFrame
    local isEnemy = IsEnemyNameplate(unitFrame)

    if container then
        CallWidget(container, "Show")
        CallWidget(container, "SetAlpha", isEnemy and 1 or 0)
        if isEnemy then
            pcall(PixelUtil.SetHeight, container, healthBarHeight)
            ClearAllNamedPoints(container)
            pcall(PixelUtil.SetPoint, container, "BOTTOMLEFT", unitFrame, "LEFT", healthInset, 4)
            pcall(PixelUtil.SetPoint, container, "BOTTOMRIGHT", unitFrame, "RIGHT", -healthInset, 4)
        end
    end

    if isEnemy and healthBar then
        -- Текстуру/цвет не трогаем на каждом OnSizeChanged: иначе fill моргает
        -- и SetTexCoord срезает правый скруглённый край.
        if not healthBar._consoleMenuSkinned then
            SetFileTexture(healthBar.barTexture, barTexturePath)
            ApplyBarColor(healthBar, healthBar.barTexture, healthBarColorR, healthBarColorG, healthBarColorB, 1)
            if healthBar.bgTexture then
                SetFileTexture(healthBar.bgTexture, barTexturePath, true)
                CallWidget(healthBar.bgTexture, "SetVertexColor", 0, 0, 0, 0.5)
            end
            healthBar._consoleMenuSkinned = true
        end
        if healthBar.bgTexture then
            -- Blizzard каждый UpdateAnchors ставит фон со смещением +6 справа.
            CallWidget(healthBar.bgTexture, "SetAllPoints", container)
        end
        HideHealthOverlays(healthBar)
    end

    if castBar then
        ClearAllNamedPoints(castBar)
        if isEnemy and healthBar then
            pcall(PixelUtil.SetPoint, castBar, "TOPLEFT", healthBar, "BOTTOMLEFT", castExtraInset, -4)
            pcall(PixelUtil.SetPoint, castBar, "TOPRIGHT", healthBar, "BOTTOMRIGHT", -castExtraInset, -4)
        else
            pcall(PixelUtil.SetPoint, castBar, "TOPLEFT", unitFrame, "LEFT", healthInset + castExtraInset, 0)
            pcall(PixelUtil.SetPoint, castBar, "TOPRIGHT", unitFrame, "RIGHT", -(healthInset + castExtraInset), 0)
        end
        ApplyCastBarSkin(castBar)
    end

    if name then
        CallWidget(name, "SetTextColor", npcNameColorR, npcNameColorG, npcNameColorB, npcNameColorA)
        CallWidget(name, "SetFont", fontName, isEnemy and 14 or 16, "SLUG")
        CallWidget(name, "SetJustifyH", "CENTER")
        ClearAllNamedPoints(name)
        CallWidget(name, "SetWidth", 0)
        if isEnemy and healthBar then
            pcall(PixelUtil.SetPoint, name, "BOTTOM", healthBar, "TOP", 0, 8)
        else
            pcall(PixelUtil.SetPoint, name, "CENTER", unitFrame, "CENTER", 0, -12)
        end
    end

    if isEnemy and debuffs and healthBar then
        ClearAllNamedPoints(debuffs)
        pcall(PixelUtil.SetPoint, debuffs, "LEFT", healthBar, "RIGHT", 8, 0)
    end

    if not C_PvP.IsPVPMap() and IsMounted() then
        SetNameplateVisualAlpha(unitFrame, 0)
    else
        if castBar then
            CallWidget(castBar, "SetAlpha", 1)
        end
        if name then
            CallWidget(name, "SetAlpha", 1)
        end
        if aurasFrame then
            CallWidget(aurasFrame, "SetAlpha", 1)
        end
    end
end

function ConsoleMenu:InitializeNameplate()
    if not ConsoleMenuDB or ConsoleMenuDB.enemyNameplateStyle == 1 then
        return
    end

    local function RefreshNameplatesVisibility()
        if C_PvP.IsPVPMap() then
            return
        end

        for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
            local unitFrame = nameplate.UnitFrame or nameplate
            if IsNamePlateUnitFrame(unitFrame) and not IsForbiddenObject(unitFrame) then
                if IsMounted() then
                    SetNameplateVisualAlpha(unitFrame, 0)
                else
                    SetNameplateVisualAlpha(unitFrame, 1)
                    if not IsEnemyNameplate(unitFrame) and unitFrame.HealthBarsContainer then
                        CallWidget(unitFrame.HealthBarsContainer, "SetAlpha", 0)
                    end
                end
            end
        end
    end

    ConsoleMenu:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED", RefreshNameplatesVisibility)
    ConsoleMenu:RegisterEvent("NAME_PLATE_UNIT_ADDED", RefreshNameplatesVisibility)

    hooksecurefunc(NamePlateUnitFrameMixin, "UpdateAnchors", function(self)
        pcall(ApplyConsoleNameplate, self)
    end)

    local function AfterNamePlateCastBar(self)
        if IsNamePlateCastBar(self) then
            pcall(ApplyCastBarSkin, self)
        end
    end

    local function AfterNamePlateCastBarFill(self)
        if IsNamePlateCastBar(self) then
            pcall(ApplyCastBarFill, self)
        end
    end

    if CastingBarMixin then
        if CastingBarMixin.UpdateBarFillTexture then
            hooksecurefunc(CastingBarMixin, "UpdateBarFillTexture", AfterNamePlateCastBarFill)
        end
        -- В этой сборке fill/spark/flash ставятся атласами в OnEvent/OnUpdate, не в UpdateBarFillTexture.
        for _, methodName in ipairs({
            "OnEvent",
            "OnShow",
            "FinishSpell",
            "HandleInterruptOrSpellFailed",
            "HandleCastStop",
            "UpdateInterruptibleState",
            "SimulateCast",
            "ShowSpark",
        }) do
            if CastingBarMixin[methodName] then
                hooksecurefunc(CastingBarMixin, methodName, AfterNamePlateCastBar)
            end
        end
        if CastingBarMixin.OnUpdate then
            hooksecurefunc(CastingBarMixin, "OnUpdate", function(self)
                if IsNamePlateCastBar(self) then
                    local ok, fillTexture = CallWidget(self, "GetStatusBarTexture")
                    ApplyBarColor(
                        self,
                        (ok and fillTexture) or nil,
                        npcNameColorR, npcNameColorG, npcNameColorB, npcNameColorA
                    )
                end
            end)
        end
    end

    if NamePlateCastingBarMixin and NamePlateCastingBarMixin.ApplyStyleAndAnchoring then
        hooksecurefunc(NamePlateCastingBarMixin, "ApplyStyleAndAnchoring", function(self)
            local ok, parent = CallWidget(self, "GetParent")
            if ok and IsNamePlateUnitFrame(parent) then
                pcall(ApplyConsoleNameplate, parent)
            else
                pcall(ApplyCastBarSkin, self)
            end
        end)
    end

    if CastingBarMixin and CastingBarMixin.UpdateIconShown then
        hooksecurefunc(CastingBarMixin, "UpdateIconShown", function(self)
            if not IsNamePlateCastBar(self) then
                return
            end
            if self.BorderShield then
                CallWidget(self.BorderShield, "Hide")
            end
            local icon = self.Icon
            if icon then
                local iconSize = 16
                if NamePlateSetupOptions and NamePlateSetupOptions.castIconWidth then
                    iconSize = NamePlateSetupOptions.castIconWidth
                end
                ClearAllNamedPoints(icon)
                pcall(PixelUtil.SetSize, icon, iconSize, iconSize)
                pcall(PixelUtil.SetPoint, icon, "RIGHT", self, "LEFT", -4, 0)
            end
        end)
    end

    if NamePlateHealthBarMixin and NamePlateHealthBarMixin.UpdateSelectionBorder then
        hooksecurefunc(NamePlateHealthBarMixin, "UpdateSelectionBorder", function(self)
            HideHealthOverlays(self)
        end)
    end

    hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
        if not IsNamePlateUnitFrame(frame) or IsForbiddenObject(frame) or not IsEnemyNameplate(frame) then
            return
        end
        local healthBar = frame.HealthBarsContainer and frame.HealthBarsContainer.healthBar
        if healthBar then
            ApplyBarColor(healthBar, healthBar.barTexture, healthBarColorR, healthBarColorG, healthBarColorB, 1)
        end
    end)

    hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
        if not IsNamePlateUnitFrame(frame) or IsForbiddenObject(frame) then
            return
        end
        local nameText = frame.name
        if nameText then
            CallWidget(nameText, "SetTextColor", npcNameColorR, npcNameColorG, npcNameColorB, npcNameColorA)
            CallWidget(nameText, "SetWidth", 0)
        end
    end)

    hooksecurefunc(NamePlateAuraItemMixin, "SetAura", function(self, aura)
        if IsForbiddenObject(self) then
            return
        end
        local icon = self.Icon
        if not icon then
            return
        end

        CallWidget(icon, "SetSize", auraIconSize, auraIconSize)
        local edge = 3 / auraIconSize
        CallWidget(icon, "SetTexCoord", edge, 1 - edge, edge, 1 - edge)

        if not icon.mask then
            local parentOk, iconParent = CallWidget(icon, "GetParent")
            if parentOk and iconParent then
                local maskOk, mask = CallWidget(iconParent, "CreateMaskTexture")
                if maskOk and mask then
                    CallWidget(mask, "SetTexture", "Interface\\AddOns\\ConsoleMenu\\Assets\\MaskCircle.png")
                    CallWidget(mask, "SetAllPoints", icon)
                    CallWidget(icon, "AddMaskTexture", mask)
                    icon.mask = mask
                end
            end
        end

        if self.Cooldown then
            CallWidget(self.Cooldown, "SetUseCircularEdge", true)
            CallWidget(self.Cooldown, "SetSwipeTexture", "Interface\\AddOns\\ConsoleMenu\\Assets\\MaskCircle.png")
        end

        local regionsOk, regions = pcall(function()
            return { self:GetRegions() }
        end)
        if regionsOk then
            for _, region in ipairs(regions) do
                local atlasOk, atlas = CallWidget(region, "GetAtlas")
                if atlasOk and (
                    atlas == "UI-HUD-CoolDownManager-IconOverlay"
                    or atlas == "UI-HUD-CoolDownManager-Mask"
                ) then
                    CallWidget(region, "Hide")
                end
            end
        end
    end)
end
