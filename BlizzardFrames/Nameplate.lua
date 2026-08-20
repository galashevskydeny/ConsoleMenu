local ConsoleMenu = _G.ConsoleMenu
local healthBarHeight = 16
local castBarHeight = 12
local auraIconSize = 32
local npcNameColorR, npcNameColorG, npcNameColorB, npcNameColorA = 1.0, 0.960784, 0.772549, 1.0

local function IsObjectOfType(object, objectType)
    return (type(object) == "table" or type(object) == "userdata")
        and object.IsObjectType
        and object:IsObjectType(objectType)
end

-- Функция для применения текстуры castbar с задержкой
local function ApplyCastBarTextureWithDelay(castBar)
    if not IsObjectOfType(castBar, "StatusBar") then
        return
    end
    castBar:SetStatusBarTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\EnemyHealthBar.png")
    if IsObjectOfType(castBar.Text, "FontString") then
        castBar.Text:SetTextColor(npcNameColorR, npcNameColorG, npcNameColorB, npcNameColorA)
    end
    if IsObjectOfType(castBar.CastTargetNameText, "FontString") then
        castBar.CastTargetNameText:SetTextColor(npcNameColorR, npcNameColorG, npcNameColorB, npcNameColorA)
    end
end

-- Функция инициализации модуля Nameplate
function ConsoleMenu:InitializeNameplate()
    
    if not ConsoleMenuDB or ConsoleMenuDB.enemyNameplateStyle == 1 then return end

    -- При смене маунта (сел/слез) обновляем видимость всех неймплейтов
    local function RefreshNameplatesVisibility()
        -- Отключение скрытия в PvP зонах
        if C_PvP.IsPVPMap() then return end

        for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
            
            local unitFrame = nameplate.UnitFrame or nameplate
            if unitFrame then
                if IsMounted() then
                    unitFrame:Hide()
                else
                    unitFrame:Show()
                end
            end
        end
    end
    ConsoleMenu:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED", function()
        RefreshNameplatesVisibility()
    end)

    ConsoleMenu:RegisterEvent("NAME_PLATE_UNIT_ADDED", function()
        RefreshNameplatesVisibility()
    end)

    -- Изменение внешнего вида полосы здоровья
    hooksecurefunc(NamePlateUnitFrameMixin, "UpdateAnchors", function(self)
        local container = self and self.HealthBarsContainer
        local healthBar = container and container.healthBar
        local name = self and self.name
        local castBar = self.castBar
        local unitFrame = self

        local aurasFrame = self and self.AurasFrame
        local debuffs = aurasFrame and aurasFrame.DebuffListFrame

        local fontName = "Fonts\\FRIZQT___CYR.TTF"
        local unit = self.unit
        local isHostile = unit and UnitCanAttack("player", unit) and not UnitIsDead(unit)

        if IsObjectOfType(castBar, "StatusBar") then
            PixelUtil.SetHeight(castBar, castBarHeight)
            ApplyCastBarTextureWithDelay(castBar)
            castBar:SetStatusBarColor(1.0, 0.960784, 0.772549, 1.0)
            castBar:ClearAllPoints()
            if IsObjectOfType(castBar.Background, "Texture") then
                castBar.Background:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\EnemyHealthBar.png")
                castBar.Background:SetVertexColor(0, 0, 0, 0.5)
            end
            PixelUtil.SetPoint(castBar, "TOPLEFT", unitFrame, "LEFT", 48, 0)
            PixelUtil.SetPoint(castBar, "TOPRIGHT", unitFrame, "RIGHT", -48, 0)
            if IsObjectOfType(castBar.Text, "FontString") and IsObjectOfType(castBar.Background, "Texture") then
                castBar.Text:ClearAllPoints()
                PixelUtil.SetPoint(castBar.Text, "TOP", castBar.Background, "BOTTOM", 0, -8)
                castBar.Text:SetFont(fontName, 12, "SLUG")
                castBar.Text:SetTextColor(npcNameColorR, npcNameColorG, npcNameColorB, npcNameColorA)
            end
            if IsObjectOfType(castBar.CastTargetNameText, "FontString") then
                castBar.CastTargetNameText:SetTextColor(npcNameColorR, npcNameColorG, npcNameColorB, npcNameColorA)
            end
        end

        if IsObjectOfType(container, "Frame") then
            -- Не Hide(): якорь имени к скрытому контейнеру съезжает на self (текст по центру).
            container:Show()
            container:SetAlpha(isHostile and 1 or 0)
            if isHostile and IsObjectOfType(unitFrame, "Button") then
                PixelUtil.SetHeight(container, healthBarHeight)
                container:ClearAllPoints()
                PixelUtil.SetPoint(container, "BOTTOMLEFT", unitFrame, "LEFT", 36, 4)
                PixelUtil.SetPoint(container, "BOTTOMRIGHT", unitFrame, "RIGHT", -36, 4)
            end
        end

        if isHostile and IsObjectOfType(healthBar, "StatusBar") then
            -- Меняем вид полосы здоровья
            healthBar:SetStatusBarColor(0.188235, 0.811765, 0.556863) -- Цвет 30CF8E
            if IsObjectOfType(healthBar.barTexture, "Texture") then
                healthBar.barTexture:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\EnemyHealthBar.png")
            end
            if IsObjectOfType(healthBar.bgTexture, "Texture") then
                healthBar.bgTexture:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\EnemyHealthBar.png")
                healthBar.bgTexture:SetVertexColor(0, 0, 0, 0.5)
                healthBar.bgTexture:ClearAllPoints()
                if IsObjectOfType(container, "Frame") then
                    healthBar.bgTexture:SetAllPoints(container)
                end
            end
            if IsObjectOfType(healthBar.deselectedOverlay, "Texture") then
                healthBar.deselectedOverlay:Hide()
            end
            if IsObjectOfType(healthBar.selectedBorder, "Texture") then
                healthBar.selectedBorder:Hide()
                healthBar.selectedBorder:SetAlpha(0)
            end
        end

        -- Blizzard ставит BOTTOMLEFT/BOTTOMRIGHT; ClearAllPoints часто не сбрасывает — снимаем по именам.
        if IsObjectOfType(name, "FontString") then
            name:SetTextColor(npcNameColorR, npcNameColorG, npcNameColorB, npcNameColorA)
            name:SetFont(fontName, isHostile and 14 or 16, "SLUG")
            name:SetJustifyH("CENTER")
            if name.ClearPoint then
                for _, point in ipairs({
                    "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT",
                    "LEFT", "RIGHT", "TOP", "BOTTOM", "CENTER",
                }) do
                    name:ClearPoint(point)
                end
            else
                name:ClearAllPoints()
            end
            name:SetWidth(0)
            if isHostile and IsObjectOfType(healthBar, "StatusBar") then
                PixelUtil.SetPoint(name, "BOTTOM", healthBar, "TOP", 0, 8)
            elseif IsObjectOfType(unitFrame, "Button") then
                PixelUtil.SetPoint(name, "CENTER", unitFrame, "CENTER", 0, -12)
            end
        end

        -- Меняем расположение дебаффов
        if IsObjectOfType(debuffs, "Frame") and IsObjectOfType(healthBar, "StatusBar") then
            debuffs:ClearAllPoints()
            PixelUtil.SetPoint(debuffs, "LEFT", healthBar, "RIGHT", 8, 0)
        end

    end)

    -- Изменение внешнего вида castbar
    hooksecurefunc(NamePlateCastingBarMixin, "OnEvent", function(self, event, ...)
        ApplyCastBarTextureWithDelay(self)
    end)

    hooksecurefunc(NamePlateCastingBarMixin, "HandleInterruptOrSpellFailed", function(self, empoweredInterrupt, event, ...)
        ApplyCastBarTextureWithDelay(self)
    end)

    hooksecurefunc(NamePlateCastingBarMixin, "HandleCastStop", function(self, event, ...)
        ApplyCastBarTextureWithDelay(self)
    end)

    hooksecurefunc(NamePlateCastingBarMixin, "UpdateInterruptibleState", function(self, notInterruptible)
        ApplyCastBarTextureWithDelay(self)
    end)

    hooksecurefunc(NamePlateCastingBarMixin, "FinishSpell", function(self)
        ApplyCastBarTextureWithDelay(self)
    end)

    hooksecurefunc(NamePlateCastingBarMixin, "SimulateCast", function(self, castData)
        ApplyCastBarTextureWithDelay(self)
    end)

    hooksecurefunc(NamePlateCastingBarMixin, "UpdateIconShown", function(self)
        local borderShield = self and self.BorderShield
        if IsObjectOfType(borderShield, "Texture") then
            borderShield:Hide()
        end
    end)

    hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
        -- Проверяем, что это nameplate healthbar
        local healthBar = frame and frame.HealthBarsContainer and frame.HealthBarsContainer.healthBar
        if IsObjectOfType(healthBar, "StatusBar") then
            healthBar:SetStatusBarColor(0.188235, 0.811765, 0.556863) -- Цвет 30CF8E
        end
    end)

    hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
        -- Blizzard может менять цвет имени в бою, принудительно возвращаем кастомный цвет.
        local nameText = frame and frame.name
        if IsObjectOfType(nameText, "FontString") then
            nameText:SetTextColor(npcNameColorR, npcNameColorG, npcNameColorB, npcNameColorA)
            nameText:SetWidth(0)
        end
    end)

    -- Изменение маски дебаффов (круглая маска через CreateMaskTexture + AddMaskTexture)
    hooksecurefunc(NamePlateAuraItemMixin, "SetAura", function(self, aura)
        local icon = self.Icon
        if not icon then return end
    
        -- Размер меняем через icon, а не self
        icon:SetSize(auraIconSize, auraIconSize)
    
        local edge = 3 / auraIconSize
        icon:SetTexCoord(edge, 1 - edge, edge, 1 - edge)
    
        if not icon.mask then
            local mask = icon:GetParent():CreateMaskTexture()
            mask:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\MaskCircle.png")
            mask:SetAllPoints(icon)
            icon:AddMaskTexture(mask)
            icon.mask = mask
        end
    
        if self.Cooldown then
            self.Cooldown:SetUseCircularEdge(true)
            self.Cooldown:SetSwipeTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\MaskCircle.png")
        end
    
        for _, region in ipairs({ self:GetRegions() }) do
            if region.GetAtlas and (
                region:GetAtlas() == "UI-HUD-CoolDownManager-IconOverlay" or
                region:GetAtlas() == "UI-HUD-CoolDownManager-Mask"
            ) then
                region:Hide()
            end
        end
    end)
end

