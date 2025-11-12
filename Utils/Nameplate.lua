local ConsoleMenu = _G.ConsoleMenu

-- Функция инициализации модуля Nameplate
function ConsoleMenu:InitializeNameplate()
    
    if not ConsoleMenuDB or ConsoleMenuDB.enemyNameplateStyle == 2 then return end

    hooksecurefunc(NamePlateUnitFrameMixin, "UpdateAnchors", function(self)
        local container = self.HealthBarsContainer
        local healthBar = self.HealthBarsContainer.healthBar
        local name = self.name
        local castBar = self.castBar
        local unitFrame = self
        
        -- Изменения текста имени
        name:ClearAllPoints()
        name:SetTextColor(1.0, 0.960784, 0.772549, 1.0)
        local fontName, _, _ = name:GetFont()
        name:SetFont(fontName, 12, "SLUG")
        PixelUtil.SetPoint(name, "BOTTOM", self.HealthBarsContainer.healthBar, "TOP",0, 8)

        -- Меняем вид полосы здоровья
        healthBar:SetStatusBarColor(0.188235, 0.811765, 0.556863) -- Цвет 30CF8E
        healthBar.barTexture:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\EnemyHealthBar.png")
        healthBar.bgTexture:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\EnemyHealthBar.png")
        healthBar.bgTexture:SetVertexColor(0, 0, 0, 0.5)
        healthBar.bgTexture:ClearAllPoints()
        healthBar.bgTexture:SetAllPoints(container);
        healthBar.selectedBorder:Hide()
        healthBar.selectedBorder:SetAlpha(0)
        -- Изменения вида контейнера полосы здоровья
        PixelUtil.SetHeight(self.HealthBarsContainer, 16)
        container:ClearAllPoints()
        PixelUtil.SetPoint(container, "BOTTOMLEFT", unitFrame, "LEFT", 36, 4)
        PixelUtil.SetPoint(container, "BOTTOMRIGHT", unitFrame, "RIGHT", -36, 4)

        -- Изменения вида castBar
        local setupOptions = NamePlateSetupOptions
        local spellNameInsideCastBar = setupOptions and setupOptions.spellNameInsideCastBar

        PixelUtil.SetHeight(castBar, 12)
        castBar:SetStatusBarTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\EnemyHealthBar.png");
        castBar:SetStatusBarColor(1.0, 0.960784, 0.772549, 1.0)
        castBar:ClearAllPoints()
        PixelUtil.SetPoint(castBar, "TOPLEFT", unitFrame, "LEFT", 48, 0);
        PixelUtil.SetPoint(castBar, "TOPRIGHT", unitFrame, "RIGHT", -48, 0);

    end)

    hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
        -- Проверяем, что это nameplate healthbar
        if frame and frame.HealthBarsContainer and frame.HealthBarsContainer.healthBar then
            local healthBar = frame.HealthBarsContainer.healthBar;
            healthBar:SetStatusBarColor(0.188235, 0.811765, 0.556863) -- Цвет 30CF8E
        end
    end)
end

