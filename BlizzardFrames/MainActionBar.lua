-- MainActionBar.lua

local ConsoleMenu = _G.ConsoleMenu

local frameWidth = 688
local frameHeight = 196

local buttonSize = 52

local paddingPAD = buttonSize * 1.5
local paddingPADD = buttonSize * 1.5

local buttonVerticalPadding = buttonSize * 0.6
local buttonHorizontalPadding = buttonSize * 0.6

local shadowSize = 240

local animationDuration = 0.1

local buttonPositions = {
    PADRSTICK = { "TOP", "PADCenter", "BOTTOM", 0, -buttonVerticalPadding },

    PAD2 = { "LEFT", "PADCenter", "RIGHT", buttonHorizontalPadding, 0 },
    PAD3 = { "RIGHT", "PADCenter", "LEFT", -buttonHorizontalPadding, 0 },
    PAD4 = { "BOTTOM", "PADCenter", "TOP", 0, buttonVerticalPadding },

    PADDUP = { "BOTTOM", "PADDCenter", "TOP", 0, buttonVerticalPadding },
    PADDRIGHT = { "LEFT", "PADDCenter", "RIGHT", buttonHorizontalPadding, 0 },
    PADDLEFT = { "RIGHT", "PADDCenter", "LEFT", -buttonHorizontalPadding, 0 },
    PADDDOWN = { "TOP", "PADDCenter", "BOTTOM", 0, -buttonVerticalPadding },
}

-- Проверка, является ли кулдаун глобальным кулдауном (GCD)
-- ВАЖНО: isOnGCD помечено как NeverSecret = true, поэтому безопасно для чтения
local function IsGlobalCooldown(slotID)
    if not slotID or not C_ActionBar or not C_ActionBar.GetActionCooldown then
        return false;
    end
    
    local cooldownInfo = C_ActionBar.GetActionCooldown(slotID);
    if cooldownInfo and cooldownInfo.isOnGCD then
        return true;
    end
    
    return false;
end

-- Функция обновления текстуры кнопки
local function UpdateActionButtonTexture(slotID)
    local frame = ConsoleMenuFrame.ActionBarFrame

    local btn = frame.actionButtons[slotID]
    if not btn or not btn.texture then return end

    local textureFileID = C_ActionBar.GetActionTexture(slotID)
    if issecretvalue(textureFileID) then
        -- Если слот пуст, скрываем кнопку
        btn.texture:SetTexture(nil)
        ConsoleMenu:AnimatedHide(btn)
        return
    end

    if textureFileID then
        btn.texture:SetTexture(textureFileID)
        -- Кнопка будет показана/скрыта в UpdateButtonPositions на основе биндинга
    else
        btn.texture:SetTexture(nil)
    end
end

-- Функция обновления кулдаунов и доступности для всех кнопок
local function UpdateActionButtonCooldowns()
    local frame = ConsoleMenuFrame.ActionBarFrame

    for slotID, btn in ipairs(frame.actionButtons) do
        -- Используем CooldownFrame для автоматической обработки secret values
        if btn.cooldown then
            local cooldownInfo = C_ActionBar.GetActionCooldown(slotID)
            if cooldownInfo then
                -- CooldownFrame:SetCooldown может принимать secret values напрямую
                btn.cooldown:SetCooldown(cooldownInfo.startTime, cooldownInfo.duration, cooldownInfo.modRate)
            else
                btn.cooldown:Hide()
            end

            RunNextFrame(function()
                if btn.cooldown:IsShown() and not IsGlobalCooldown(slotID) then
                    btn.texture:SetDesaturated(true)
                else
                    btn.texture:SetDesaturated(false)
                end
            end)

        end
    end
end

-- Функция обновления позиций кнопок
local function UpdateButtonPositions(slotID)
    local frame = ConsoleMenuFrame.ActionBarFrame

    -- Обновление позиции конкретной кнопки (если передан slotID)
    if slotID then
        local btn = frame.actionButtons[slotID]
        if not btn then return end
        
        local command = ConsoleMenu:GetBindingCommandBySlotID(slotID)
        local binding = ConsoleMenu:GetCommandBinding(command)
        local position = buttonPositions[binding]

        if position then
            ConsoleMenu:AnimatedShow(btn)
            btn:ClearAllPoints()
            btn:SetPoint(position[1], position[2], position[3], position[4], position[5])
        else
            ConsoleMenu:AnimatedHide(btn)
        end

        return
    end

    -- Обновление всех кнопок (если не передан slotID)
    for slotID, btn in ipairs(frame.actionButtons) do
        local command = ConsoleMenu:GetBindingCommandBySlotID(slotID)
        local binding = ConsoleMenu:GetCommandBinding(command)

        local position = buttonPositions[binding]
        if position then
            ConsoleMenu:AnimatedShow(btn)
            btn:ClearAllPoints()
            btn:SetPoint(position[1], position[2], position[3], position[4], position[5])
        else
            ConsoleMenu:AnimatedHide(btn)
        end
    end
end

-- Функция создания кнопки
local function CreateSpellBarButtonFrame(parent, slotID)
    local buttonFrame = CreateFrame("Frame", "ActionButton" .. slotID, parent)
    parent["ActionButton" .. slotID] = buttonFrame

    buttonFrame:SetSize(buttonSize, buttonSize)
    ConsoleMenu:InitFadeAnimations(buttonFrame, animationDuration)

    local textureFileID = C_ActionBar.GetActionTexture(slotID)
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
    cooldown:SetDrawBling(false)
    cooldown:SetDrawSwipe(false)
    cooldown:SetDrawEdge(false)

    
    buttonFrame.cooldown = cooldown
    
    buttonFrame.cooldown:HookScript("OnHide", function()
        -- Кулдаун исчез
        RunNextFrame(function()
            buttonFrame.texture:SetDesaturated(false)
        end)
    end)

    buttonFrame.cooldown:SetScript("OnCooldownDone", function()
        -- Кулдаун закончился
        RunNextFrame(function()
            buttonFrame.texture:SetDesaturated(false)
        end)
    end)

    buttonFrame:Show()
    return buttonFrame
end

function ConsoleMenu:InitializeMainActionBar()

    --if ConsoleMenuDB.actionBarStyle == 1 then return end

    if not C_ActionBar.GetActionCooldown or not C_ActionBar.GetActionTexture then
        return
    end

    -- Создаём родительский фрейм для кнопок (если его ещё нет)
    if not ConsoleMenuFrame.ActionBarFrame then
        ConsoleMenuFrame.ActionBarFrame = CreateFrame("Frame", "ActionBarFrame", ConsoleMenuFrame)
    end

    local frame = ConsoleMenuFrame.ActionBarFrame

    frame:SetSize(frameWidth, frameHeight)
    frame:SetPoint("BOTTOM", ConsoleMenuFrame, "BOTTOM", 0, 48)
    ConsoleMenu:InitFadeAnimations(frame, animationDuration)

    if not frame.PADCenter then
        frame.PADCenter = CreateFrame("Frame", "PADCenter", frame)
        frame.PADCenter:SetPoint("RIGHT", frame, "RIGHT", -paddingPAD, 0)
        frame.PADCenter:SetSize(1, 1)
    end

    if not frame.PADDCenter then
        frame.PADDCenter = CreateFrame("Frame", "PADDCenter", frame)
        frame.PADDCenter:SetPoint("LEFT", frame, "LEFT", paddingPADD, 0)
        frame.PADDCenter:SetSize(1, 1)
    end

    if not frame.PADshadow then
        frame.PADshadow = frame:CreateTexture(nil, "BACKGROUND")
        frame.PADshadow:SetPoint("CENTER", frame.PADCenter, "CENTER", 0, 0)
        frame.PADshadow:SetSize(shadowSize, shadowSize)
        frame.PADshadow:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png")
    end

    if not frame.PADDshadow then
        frame.PADDshadow = frame:CreateTexture(nil, "BACKGROUND")
        frame.PADDshadow:SetPoint("CENTER", frame.PADDCenter, "CENTER", 0, 0)
        frame.PADDshadow:SetSize(shadowSize, shadowSize)
        frame.PADDshadow:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png")
    end

    frame.actionButtons = {}

    for slotID = 1, 12 do
        local btn = CreateSpellBarButtonFrame(frame, slotID)
        btn.slotID = slotID
        frame.actionButtons[slotID] = btn
    end

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")

    frame:RegisterEvent("GAME_PAD_ACTIVE_CHANGED")
    frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    frame:RegisterEvent("ACTIONBAR_SHOWGRID")
    frame:RegisterEvent("ACTIONBAR_HIDEGRID")

    frame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    frame:RegisterEvent("ACTIONBAR_UPDATE_STATE")
    frame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")

    local function OnActionBarEvent(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            for slotID = 1, 12 do
                UpdateActionButtonTexture(slotID)
            end
            UpdateButtonPositions()
            UpdateActionButtonCooldowns()
        elseif event == "GAME_PAD_ACTIVE_CHANGED" or event == "ACTIONBAR_SHOWGRID" or event == "ACTIONBAR_HIDEGRID" then
            UpdateButtonPositions()
        elseif event == "ACTIONBAR_SLOT_CHANGED" then
            local slotID = ...
            UpdateActionButtonTexture(slotID)
            UpdateButtonPositions(slotID)
            UpdateActionButtonCooldowns()
        elseif event == "ACTIONBAR_UPDATE_COOLDOWN" or event == "ACTIONBAR_UPDATE_STATE" or event == "ACTIONBAR_UPDATE_USABLE" then
            UpdateActionButtonCooldowns()
        end
    end

    frame:SetScript("OnEvent", OnActionBarEvent)

end

