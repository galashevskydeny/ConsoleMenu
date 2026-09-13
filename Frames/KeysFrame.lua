local ConsoleMenu = _G.ConsoleMenu

local maxItemsCount = 5

local frameWidth = 304
local frameHeight = frameWidth

local sectionHeight = 32

local iconSize = sectionHeight
local iconInnerPadding = 8
local iconPlusSize = 12

local stackCountSize = 20
local stackCountOffset = 8
local stackCountShadowOffsef = 12

local padding = 12

local fontSize = 16

local animationDuration = 0.1

-- Проверяет, задана ли кнопка геймпада для эмуляции модификатора
local function IsEmulatedGamePadButton(value)
    return value and value ~= "" and string.upper(value) ~= "NONE"
end

-- Проверяет, есть ли пригодная текстура для клавиши
local function HasUsableTexture(textureInfo)
    return textureInfo and textureInfo.texture and textureInfo.texture ~= ""
end

-- Признак, что перерисовка уже отложена на следующий кадр
local keysFrameUpdateQueued = false

-- Подставляет кнопку геймпада вместо модификатора, если она задана в настройках
local function ResolveModifierKey(modifierKey)
    if not ConsoleMenu:IsGamePadActive() or not modifierKey then
        return modifierKey
    end

    local cvarName
    if modifierKey == "SHIFT" then
        cvarName = "GamePadEmulateShift"
    elseif modifierKey == "CTRL" then
        cvarName = "GamePadEmulateCtrl"
    elseif modifierKey == "ALT" then
        cvarName = "GamePadEmulateAlt"
    else
        return modifierKey
    end

    local emulated = GetCVar(cvarName)
    if IsEmulatedGamePadButton(emulated) and HasUsableTexture(ConsoleMenu.Textures[emulated]) then
        return emulated
    end

    return modifierKey
end

-- Проверяет, можно ли нарисовать подсказку по привязке
local function CanShowKeyBinding(binding)
    if not binding then
        return false
    end

    local mainKey, modifierKey = ConsoleMenu:ParseBindingKey(binding)
    modifierKey = ResolveModifierKey(modifierKey)

    if modifierKey then
        return HasUsableTexture(ConsoleMenu.Textures[mainKey]) and HasUsableTexture(ConsoleMenu.Textures[modifierKey])
    end

    return HasUsableTexture(ConsoleMenu.Textures[mainKey])
end

-- Возвращает контейнер списка подсказок, если он уже создан
local function GetKeysFrame()
    local keysFrame = ConsoleMenuFrame and ConsoleMenuFrame.KeysFrame
    if keysFrame and keysFrame.Items then
        return keysFrame
    end
end

-- Обновляет внешний вид строки подсказки
local function UpdateKeyFrame(frame, binding, title, stackCount)
    if not frame then return false end
    if not binding then return false end
    if not title then return false end

    local mainKey, modifierKey = ConsoleMenu:ParseBindingKey(binding)
    modifierKey = ResolveModifierKey(modifierKey)

    if modifierKey then
        local mainTextureInfo = ConsoleMenu.Textures[mainKey]
        local modifierTextureInfo = ConsoleMenu.Textures[modifierKey]
        if not HasUsableTexture(mainTextureInfo) or not HasUsableTexture(modifierTextureInfo) then
            return false
        end

        frame.Icon.PlusTexture:Show()
        frame.Icon.ModifierTexture:Show()

        local width = iconSize * 2 + iconPlusSize + iconInnerPadding * 2 + iconInnerPadding
        local height = iconSize + iconInnerPadding * 2

        frame:SetHeight(height)
        frame.Icon:SetWidth(width)
        frame.Icon:SetHeight(height)

        frame.Icon.MainTexture:SetTexture(mainTextureInfo.texture)
        frame.Icon.ModifierTexture:SetTexture(modifierTextureInfo.texture)
        frame.Icon.Background:SetTexture(ConsoleMenu.Backgrounds["PAIR"])

        frame.Icon.MainTexture:ClearAllPoints()
        frame.Icon.MainTexture:SetPoint("RIGHT", frame.Icon, "RIGHT", -iconInnerPadding, 0)
        frame.Icon.MainTexture:SetSize(iconSize, iconSize)

        frame.Icon.StackCount:ClearAllPoints()
        frame.Icon.StackCount:SetPoint("BOTTOMRIGHT", frame.Icon.MainTexture, "BOTTOMRIGHT", stackCountOffset, -(stackCountOffset + iconInnerPadding))

        frame.Icon:ClearAllPoints()
        frame.Icon:SetPoint("RIGHT", frame, "RIGHT", iconInnerPadding, 0)
    else
        local textureInfo = ConsoleMenu.Textures[mainKey]
        if not HasUsableTexture(textureInfo) then
            return false
        end

        frame.Icon.PlusTexture:Hide()
        frame.Icon.ModifierTexture:Hide()

        frame:SetHeight(sectionHeight)
        frame.Icon:SetSize(iconSize, iconSize)

        frame.Icon.Background:SetTexture(textureInfo.background)
        frame.Icon.MainTexture:SetTexture(textureInfo.texture)

        frame.Icon.MainTexture:ClearAllPoints()
        frame.Icon.MainTexture:SetAllPoints()

        frame.Icon.StackCount:ClearAllPoints()
        frame.Icon.StackCount:SetPoint("BOTTOMRIGHT", frame.Icon.MainTexture, "BOTTOMRIGHT", stackCountOffset, -stackCountOffset)

        frame.Icon:ClearAllPoints()
        frame.Icon:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    end

    frame.Icon.StackCount.Text:SetText(stackCount)
    frame.Text:SetText(title)

    -- Секретное значение не должно менять видимость счётчика
    if issecretvalue(stackCount) then
        return true
    end

    -- Скрываем счётчик при пустом значении, нуле и единице
    if not stackCount or stackCount == "" or stackCount == "0" or stackCount == 0 or stackCount == "1" or stackCount == 1 then
        frame.Icon.StackCount:Hide()
    else
        frame.Icon.StackCount:Show()
    end

    return true
end

-- Сбрасывает содержимое списка подсказок
function ConsoleMenu:ResetKeysItems()
    local keysFrame = GetKeysFrame()
    if keysFrame then
        keysFrame.Items = {}
    end
end

-- Обновляет видимость и содержимое строк списка
function ConsoleMenu:UpdateKeysFrame()
    if keysFrameUpdateQueued then
        return
    end

    keysFrameUpdateQueued = true
    RunNextFrame(function()
        keysFrameUpdateQueued = false

        local keysFrame = GetKeysFrame()
        if not keysFrame then
            return
        end

        -- Убираем строки без текстуры и сдвигаем остальные к началу
        local compactedItems = {}
        for i = 1, maxItemsCount do
            local item = keysFrame.Items[i]
            if item and item.binding and item.title and CanShowKeyBinding(item.binding) then
                table.insert(compactedItems, item)
            end
        end

        for i = 1, maxItemsCount do
            keysFrame.Items[i] = compactedItems[i]
        end

        local activeItems = 0

        for i = 1, maxItemsCount do
            local frame = keysFrame["Item" .. i]
            local item = keysFrame.Items[i]

            if not item or not frame then
                ConsoleMenu:AnimatedHide(frame)
            else
                if UpdateKeyFrame(frame, item.binding, item.title, item.stackCount) then
                    ConsoleMenu:AnimatedShow(frame)
                    activeItems = activeItems + 1
                else
                    ConsoleMenu:AnimatedHide(frame)
                end
            end
        end

        if activeItems > 0 then
            ConsoleMenu:AnimatedShow(keysFrame.Background)
        else
            ConsoleMenu:AnimatedHide(keysFrame.Background)
        end
    end)
end

-- Удаляет подсказку и уплотняет оставшиеся строки
function ConsoleMenu:DeleteKeysFrameItem(binding, title)
    if not binding then return end

    local keysFrame = GetKeysFrame()
    if not keysFrame then
        return
    end

    local newItems = {}
    for i = 1, maxItemsCount do
        local item = keysFrame.Items[i]
        if item then
            local shouldDelete = item.binding == binding and (not title or item.title == title)
            if not shouldDelete then
                table.insert(newItems, item)
            end
        end
    end

    for i = 1, maxItemsCount do
        keysFrame.Items[i] = newItems[i]
    end
end

-- Добавляет подсказку или обновляет число зарядов у уже существующей
function ConsoleMenu:AddKeysFrameItem(binding, title, stackCount)
    if not binding then return end
    if not title then return end

    local keysFrame = GetKeysFrame()
    if not keysFrame then
        return
    end

    for i = 1, maxItemsCount do
        local existingItem = keysFrame.Items[i]
        if existingItem and existingItem.binding == binding and existingItem.title == title then
            existingItem.stackCount = stackCount
            return
        end
    end

    local item = {
        binding = binding,
        title = title,
        stackCount = stackCount,
    }

    for i = 1, maxItemsCount do
        if not keysFrame.Items[i] then
            keysFrame.Items[i] = item
            return
        end
    end

    -- Для подтверждения на первой кнопке вытесняем последнюю подсказку
    if binding == "PAD1" and not ConsoleMenu:CheckKeysFrameItem("PAD1") then
        for i = maxItemsCount, 2, -1 do
            keysFrame.Items[i] = keysFrame.Items[i - 1]
        end
        keysFrame.Items[1] = item
    end
end

-- Проверяет, есть ли в списке подсказка с указанной клавишей
function ConsoleMenu:CheckKeysFrameItem(binding)
    if not binding then return end

    local keysFrame = GetKeysFrame()
    if not keysFrame then
        return false
    end

    for i = 1, maxItemsCount do
        local item = keysFrame.Items[i]
        if item and item.binding == binding then
            return true
        end
    end

    return false
end

-- Создаёт список подсказок клавиш
function ConsoleMenu:SetKeysFrame()

    if not ConsoleMenuFrame.KeysFrame then
        local frame = CreateFrame("Frame", "KeysFrame", ConsoleMenuFrame)
        ConsoleMenuFrame.KeysFrame = frame
    end

    local frame = ConsoleMenuFrame.KeysFrame
    frame:SetSize(frameWidth, frameHeight)
    frame:SetPoint("BOTTOMRIGHT", ConsoleMenuFrame, "BOTTOMRIGHT", -48, 48)

    if not frame.Background then
        frame.Background = frame:CreateTexture(nil, "BACKGROUND")
        frame.Background:SetWidth(800)
        frame.Background:SetHeight(320)
        frame.Background:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 400, -64)
        frame.Background:SetAtlas("MapCornerShadow-Right")
        frame.Background:SetAlpha(0.85)
        frame.Background:Hide()

        ConsoleMenu:InitFadeAnimations(frame.Background, animationDuration)
    end

    if not frame.Items then
        frame.Items = {}
    end

    for i = 1, maxItemsCount do
        local item = frame["Item" .. i]
        if not item then
            item = CreateFrame("Frame", "KeysFrameItem" .. i, frame)
            frame["Item" .. i] = item

            item:SetWidth(frameWidth)
            item:SetHeight(sectionHeight)
            item:Hide()

            if i == 1 then
                item:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
            else
                item:SetPoint("BOTTOMRIGHT", frame["Item" .. (i - 1)], "TOPRIGHT", 0, padding)
            end

            ConsoleMenu:InitFadeAnimations(item, animationDuration)
        end

        -- Иконка
        if not item.Icon then
            item.Icon = CreateFrame("Frame", nil, item)
            item.Icon:SetSize(iconSize, iconSize)
            item.Icon:SetPoint("RIGHT", 0, 0)

            -- Фон для иконки
            if not item.Icon.Background then
                item.Icon.Background = item.Icon:CreateTexture(nil, "BACKGROUND")
                item.Icon.Background:SetAllPoints()

                local texture = ConsoleMenu.Textures["PAD1"].background
                item.Icon.Background:SetTexture(texture)
            end

            -- Текстура иконки
            if not item.Icon.MainTexture then
                item.Icon.MainTexture = item.Icon:CreateTexture(nil, "ARTWORK")
                item.Icon.MainTexture:SetAllPoints()
                item.Icon.MainTexture:SetVertexColor(1.0, 0.960784, 0.772549, 1)

                local texture = ConsoleMenu.Textures["PAD1"].texture
                item.Icon.MainTexture:SetTexture(texture)
            end

            if not item.Icon.PlusTexture then
                item.Icon.PlusTexture = item.Icon:CreateTexture(nil, "ARTWORK")
                item.Icon.PlusTexture:SetPoint("RIGHT", item.Icon.MainTexture, "LEFT", -iconInnerPadding / 2, 0)
                item.Icon.PlusTexture:SetSize(iconPlusSize, iconPlusSize)
                item.Icon.PlusTexture:SetVertexColor(1.0, 0.960784, 0.772549, 1)

                local texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\plus.png"
                item.Icon.PlusTexture:SetTexture(texture)
                item.Icon.PlusTexture:Hide()
            end

            if not item.Icon.ModifierTexture then
                item.Icon.ModifierTexture = item.Icon:CreateTexture(nil, "ARTWORK")
                item.Icon.ModifierTexture:SetPoint("RIGHT", item.Icon.PlusTexture, "LEFT", -iconInnerPadding / 2, 0)
                item.Icon.ModifierTexture:SetSize(iconSize, iconSize)
                item.Icon.ModifierTexture:SetVertexColor(1.0, 0.960784, 0.772549, 1)

                local texture = ConsoleMenu.Textures["PADLSHOULDER"].texture
                item.Icon.ModifierTexture:SetTexture(texture)
                item.Icon.ModifierTexture:Hide()
            end

            -- Счётчик зарядов
            if not item.Icon.StackCount then
                item.Icon.StackCount = CreateFrame("Frame", "KeysFrameItemStackCount" .. i, item.Icon)
                item.Icon.StackCount:SetSize(stackCountSize, stackCountSize)
                item.Icon.StackCount:SetPoint("BOTTOMRIGHT", item.Icon.MainTexture, "BOTTOMRIGHT", stackCountOffset, -stackCountOffset)

                item.Icon.StackCount:Hide()

                -- Фон счётчика
                if not item.Icon.StackCount.Background then
                    item.Icon.StackCount.Background = item.Icon.StackCount:CreateTexture(nil, "ARTWORK")
                    item.Icon.StackCount.Background:SetAllPoints()
                    item.Icon.StackCount.Background:SetAlpha(0.5)

                    local texture = ConsoleMenu.Backgrounds["PAD"]
                    item.Icon.StackCount.Background:SetTexture(texture)
                end

                -- Тень счётчика
                if not item.Icon.StackCount.Shadow then
                    item.Icon.StackCount.Shadow = item.Icon.StackCount:CreateTexture(nil, "BACKGROUND")
                    item.Icon.StackCount.Shadow:SetPoint("TOPLEFT", item.Icon.StackCount.Background, "TOPLEFT", -stackCountShadowOffsef, stackCountShadowOffsef)
                    item.Icon.StackCount.Shadow:SetPoint("BOTTOMRIGHT", item.Icon.StackCount.Background, "BOTTOMRIGHT", stackCountShadowOffsef, -stackCountShadowOffsef)

                    local texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png"
                    item.Icon.StackCount.Shadow:SetTexture(texture)
                end

                -- Текст счётчика
                if not item.Icon.StackCount.Text then
                    item.Icon.StackCount.Text = item.Icon.StackCount:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    item.Icon.StackCount.Text:SetAllPoints()
                    item.Icon.StackCount.Text:SetJustifyH("CENTER")
                    item.Icon.StackCount.Text:SetTextColor(1.0, 0.960784, 0.772549, 1)
                    item.Icon.StackCount.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", fontSize, "")
                    item.Icon.StackCount.Text:SetText("")
                end
            end
        end

        -- Подпись действия
        if not item.Text then
            item.Text = item:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            item.Text:SetPoint("RIGHT", item.Icon, "LEFT", -padding, 0)
            item.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", fontSize, "")
            item.Text:SetTextColor(1.0, 0.960784, 0.772549, 1)
            item.Text:SetText("")
        end
    end

    -- Регистрация события изменения режима геймпада
    frame:RegisterEvent("GAME_PAD_ACTIVE_CHANGED")

    local function OnKeysFrameEvent(self, event, ...)
        if event == "GAME_PAD_ACTIVE_CHANGED" then
            ConsoleMenu:SetGamePadActive(...)
            ConsoleMenu:UpdateKeysFrame()
        end
    end

    frame:SetScript("OnEvent", OnKeysFrameEvent)

end
