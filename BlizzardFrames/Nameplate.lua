local ConsoleMenu = _G.ConsoleMenu

-- Функция для применения текстуры castbar с задержкой
local function ApplyCastBarTextureWithDelay(castBar)
    if not castBar then
        return
    end
    
    castBar:SetStatusBarTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\EnemyHealthBar.png")
end

-- Функция инициализации модуля Nameplate
function ConsoleMenu:InitializeNameplate()
    
    if not ConsoleMenuDB or ConsoleMenuDB.enemyNameplateStyle == 1 then return end

    SetCVar(NamePlateConstants.INFO_DISPLAY_CVAR, 0);


    hooksecurefunc(NamePlateUnitFrameMixin, "UpdateAnchors", function(self)
        local container = self.HealthBarsContainer
        local healthBar = self.HealthBarsContainer.healthBar
        local name = self.name
        local castBar = self.castBar
        local unitFrame = self

        if IsMounted() then
            self:Hide()
        end
        
        -- Изменения текста имени
        name:ClearAllPoints()
        name:SetTextColor(1.0, 0.960784, 0.772549, 1.0)
        local fontName, _, _ = name:GetFont()
        name:SetFont(fontName, 14, "SLUG")
        PixelUtil.SetPoint(name, "BOTTOM", self.HealthBarsContainer.healthBar, "TOP",0, 8)

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
        PixelUtil.SetHeight(self.HealthBarsContainer, 16)
        container:ClearAllPoints()
        PixelUtil.SetPoint(container, "BOTTOMLEFT", unitFrame, "LEFT", 36, 4)
        PixelUtil.SetPoint(container, "BOTTOMRIGHT", unitFrame, "RIGHT", -36, 4)

        PixelUtil.SetHeight(castBar, 12)
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

    end)

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
end

