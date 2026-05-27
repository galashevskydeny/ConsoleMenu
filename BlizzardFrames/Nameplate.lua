local ConsoleMenu = _G.ConsoleMenu
local healthBarHeight = 16
local castBarHeight = 12
local auraIconSize = 32
local npcNameColorR, npcNameColorG, npcNameColorB, npcNameColorA = 1.0, 0.960784, 0.772549, 1.0

-- Функция для применения текстуры castbar с задержкой
local function ApplyCastBarTextureWithDelay(castBar)
    if not castBar then return end
    castBar:SetStatusBarTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\EnemyHealthBar.png")
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
        local container = self.HealthBarsContainer
        local healthBar = self.HealthBarsContainer.healthBar
        local name = self.name
        local castBar = self.castBar
        local unitFrame = self

        local aurasFrame = self.AurasFrame
        local debuffs = aurasFrame.DebuffListFrame

        local fontName, _, _ = name:GetFont()
        
        -- Изменения текста имени
        if name then
            name:ClearAllPoints()
            name:SetTextColor(npcNameColorR, npcNameColorG, npcNameColorB, npcNameColorA)
            local fontName, _, _ = name:GetFont()
            if fontName then
                name:SetFont(fontName, 14, "SLUG")
            end
            PixelUtil.SetPoint(name, "BOTTOM", self.HealthBarsContainer.healthBar, "TOP",0, 8)
        end

        if healthBar then
            -- Меняем вид полосы здоровья
            healthBar:SetStatusBarColor(0.188235, 0.811765, 0.556863) -- Цвет 30CF8E
            healthBar.barTexture:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\EnemyHealthBar.png")
            healthBar.bgTexture:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\EnemyHealthBar.png")
            healthBar.bgTexture:SetVertexColor(0, 0, 0, 0.5)
            healthBar.bgTexture:ClearAllPoints()
            healthBar.bgTexture:SetAllPoints(container)
            healthBar.deselectedOverlay:Hide()
            healthBar.selectedBorder:Hide()
            healthBar.selectedBorder:SetAlpha(0)
            PixelUtil.SetHeight(self.HealthBarsContainer, healthBarHeight)
            container:ClearAllPoints()
            PixelUtil.SetPoint(container, "BOTTOMLEFT", unitFrame, "LEFT", 36, 4)
            PixelUtil.SetPoint(container, "BOTTOMRIGHT", unitFrame, "RIGHT", -36, 4)
        end

        if castBar then
            PixelUtil.SetHeight(castBar, castBarHeight)
            castBar:SetStatusBarTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\EnemyHealthBar.png")
            castBar:SetStatusBarColor(1.0, 0.960784, 0.772549, 1.0)
            castBar:ClearAllPoints()
            castBar.Background:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\EnemyHealthBar.png")
            castBar.Background:SetVertexColor(0, 0, 0, 0.5)
            PixelUtil.SetPoint(castBar, "TOPLEFT", unitFrame, "LEFT", 48, 0)
            PixelUtil.SetPoint(castBar, "TOPRIGHT", unitFrame, "RIGHT", -48, 0)
            castBar.Text:ClearAllPoints()
            PixelUtil.SetPoint(castBar.Text, "TOP", castBar.Background, "BOTTOM", 0, -8)
            castBar.Text:SetFont(fontName, 12, "SLUG")
        end

        -- Меняем расположение дебаффов
        if debuffs then
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
        if self.BorderShield then
            self.BorderShield:Hide();
        end
    end)

    hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
        -- Проверяем, что это nameplate healthbar
        if frame and frame.HealthBarsContainer and frame.HealthBarsContainer.healthBar then
            local healthBar = frame.HealthBarsContainer.healthBar;
            healthBar:SetStatusBarColor(0.188235, 0.811765, 0.556863) -- Цвет 30CF8E
        end
    end)

    hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
        -- Blizzard может менять цвет имени в бою, принудительно возвращаем кастомный цвет.
        if frame and frame.HealthBarsContainer and frame.HealthBarsContainer.healthBar and frame.name then
            frame.name:SetTextColor(npcNameColorR, npcNameColorG, npcNameColorB, npcNameColorA)
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

