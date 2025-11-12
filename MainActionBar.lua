-- MainActionBar.lua

local ConsoleMenu = _G.ConsoleMenu

local function CreateSpellBarButtonFrame(parent, actionID)
    local width = 52
    local height = 52
    local buttonFrame = CreateFrame("Frame", nil, parent)
    buttonFrame:SetSize(width, height)

    local textureFileID = C_ActionBar.GetActionTexture(actionID)
    if issecretvalue(textureFileID) then return end

    local texture = buttonFrame:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints(buttonFrame)
    if textureFileID then
        texture:SetTexture(textureFileID)
    end
    
    -- Создаём маску для текстуры
    local mask = buttonFrame:CreateMaskTexture()
    mask:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\MaskCircle.png")
    mask:SetAllPoints(texture)
    texture:AddMaskTexture(mask)
    
    -- Сохраняем ссылку на текстуру в buttonFrame
    buttonFrame.texture = texture
    
    -- Создаём CooldownFrame для автоматической обработки кулдаунов
    local cooldown = CreateFrame("Cooldown", nil, buttonFrame, "CooldownFrameTemplate")
    cooldown:SetAllPoints(buttonFrame)    
    
    buttonFrame.cooldown = cooldown
    
    -- Добавим отдельный фрейм поверх иконки для отображения цифры
    local numberFrame = CreateFrame("Frame", nil, buttonFrame)
    numberFrame:SetAllPoints(buttonFrame)
    numberFrame:SetFrameLevel(buttonFrame:GetFrameLevel() + 2) -- выше иконки

    local numberText = numberFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    numberText:SetPoint("CENTER", numberFrame, "CENTER", 0, 0)
    numberText:Hide()

    buttonFrame.numberFrame = numberFrame
    buttonFrame.numberText = numberText

    buttonFrame:Show()
    return buttonFrame
end


function ConsoleMenu:InitializeMainActionBar()
    if ConsoleMenuDB.hideActionBar ~= 2 then
        return
    end

    -- Создаём родительский фрейм для кнопок (если его ещё нет)
    if not self.MainActionBar then
        self.MainActionBar = CreateFrame("Frame", nil, UIParent)
        self.MainActionBar:SetSize((52 + 2) * 12 - 2, 52)
        self.MainActionBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 100)
        self.MainActionBar:Show()
    end

    self.actionButtons = {}

    for actionID = 1, 12 do
        local btn = CreateSpellBarButtonFrame(self.MainActionBar, actionID)
        btn:SetPoint("LEFT", self.MainActionBar, "LEFT", (actionID - 1) * (btn:GetWidth() + 2), 0)
        btn.actionID = actionID
        self.actionButtons[actionID] = btn
    end


    -- Функция обновления кулдаунов и доступности для всех кнопок
    local function UpdateActionButtonCooldowns()
        for actionID, btn in ipairs(self.actionButtons) do
            -- Используем CooldownFrame для автоматической обработки secret values
            if btn.cooldown then
                local cooldownInfo = C_ActionBar.GetActionCooldown(actionID)
                if cooldownInfo then
                    -- CooldownFrame:SetCooldown может принимать secret values напрямую
                    btn.cooldown:SetCooldown(cooldownInfo.startTime, cooldownInfo.duration, cooldownInfo.modRate, cooldownInfo.isEnabled)
                else
                    btn.cooldown:Hide()
                end
            end
        end
    end

    -- Создаём фрейм для прослушивания событий
    if not self.cooldownEventFrame then
        self.cooldownEventFrame = CreateFrame("Frame")
        self.cooldownEventFrame:SetScript("OnEvent", function(_, event, ...)
            --UpdateActionButtonCooldowns()
        end)
        self.cooldownEventFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
        self.cooldownEventFrame:RegisterEvent("ACTIONBAR_UPDATE_STATE")
        self.cooldownEventFrame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
    end

    -- Вызываем обновление сразу после создания
    --UpdateActionButtonCooldowns()

end

