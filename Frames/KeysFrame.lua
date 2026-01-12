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

local gamePadActive = false

-- Функция для обновления элемента списка
local function UpdateKeyItem(item, binding, title, stackCount)
    if not item then return end
    if not binding then return end
    if not title then return end

    if string.find(binding, "SHIFT") or string.find(binding, "CTRL") or string.find(binding, "ALT")then
        -- Кнопка с модификатором

        item.Icon.PlusTexture:Show()
        item.Icon.ModifierTexture:Show()

        local width = iconSize * 2 + iconPlusSize + iconInnerPadding * 2 + iconInnerPadding
        local height = iconSize + iconInnerPadding * 2

        item:SetHeight(height)
        item.Icon:SetWidth(width)
        item.Icon:SetHeight(height)

        local mainKey = string.match(binding, ".-%-(.+)$")
        local modifierKey = string.match(binding, "^(.+)%-[^%-]+$")

        if gamePadActive then
            if modifierKey == "SHIFT" then
                modifierKey = GetCVar("GamePadEmulateShift")
            elseif key1 == "CTRL" then
                modifierKey = GetCVar("GamePadEmulateCtrl")
            elseif key1 == "ALT" then
                modifierKey = GetCVar("GamePadEmulateAlt")
            end
        end

        local mainTexture = ConsoleMenu.Textures[mainKey].texture
        local modifierTexture = ConsoleMenu.Textures[modifierKey].texture
        local background = ConsoleMenu.Backgrounds["PAIR"]

        item.Icon.MainTexture:SetTexture(mainTexture)
        item.Icon.ModifierTexture:SetTexture(modifierTexture)
        item.Icon.Background:SetTexture(background)

        item.Icon.MainTexture:ClearAllPoints()
        item.Icon.MainTexture:SetPoint("RIGHT", item.Icon, "RIGHT", -iconInnerPadding, 0)
        item.Icon.MainTexture:SetSize(iconSize, iconSize)

        item.Icon.StackCount:ClearAllPoints()
        item.Icon.StackCount:SetPoint("BOTTOMRIGHT", item.Icon.MainTexture, "BOTTOMRIGHT", stackCountOffset, -(stackCountOffset + iconInnerPadding))

        item.Icon:SetPoint("RIGHT", item, "RIGHT", iconInnerPadding, 0)

    else
        -- Кнопка без модификатора

        local texture = ConsoleMenu.Textures[binding].texture
        local background = ConsoleMenu.Textures[binding].background

        item.Icon.PlusTexture:Hide()
        item.Icon.ModifierTexture:Hide()

        item:SetHeight(sectionHeight)
        item.Icon:SetSize(iconSize, iconSize)

        item.Icon.Background:SetTexture(background)
        item.Icon.MainTexture:SetTexture(texture)

        item.Icon.StackCount:ClearAllPoints()
        item.Icon.StackCount:SetPoint("BOTTOMRIGHT", item.Icon.MainTexture, "BOTTOMRIGHT", stackCountOffset, -stackCountOffset)

    end

    if not stackCount or stackCount == 0 or stackCount == 1 then
        item.Icon.StackCount:Hide()
    else
        item.Icon.StackCount:Show()
        item.Icon.StackCount.Text:SetText(stackCount)
    end

    item.Text:SetText(title)
end

-- Функция для сброса элементов списка
function ConsoleMenu:ResetKeysFrameItems()
    ConsoleMenuFrame.KeysFrame.Items = {}
end

-- Функция для обновления списка
function ConsoleMenu:UpdateKeysFrame()
    print("UpdateKeysFrame")
    for i = 1, maxItemsCount do
        local frame = ConsoleMenuFrame.KeysFrame["Item" .. i]
        local item = ConsoleMenuFrame.KeysFrame.Items[i]

        if not item then
            ConsoleMenu:AnimatedHide(frame)
        else
            UpdateKeyItem(frame, item.binding, item.title, item.stackCount)
            ConsoleMenu:AnimatedShow(frame)
        end
    end
end

-- Функция для удаления элемента из списка
function ConsoleMenu:DeleteKeysFrameItem(binding)
    if not binding then return end

    -- Обходим Items и удаляем элемент, равный переданному item
    for k, v in pairs(ConsoleMenuFrame.KeysFrame.Items) do
        if v.binding == binding then
            ConsoleMenuFrame.KeysFrame.Items[k] = nil
            break
        end
    end

    -- Сдвигаем оставшиеся элементы к началу, чтобы между ними не было пустых слотов
    local newItems = {}
    for i = 1, maxItemsCount do
        local item = ConsoleMenuFrame.KeysFrame.Items[i]
        if item ~= nil then
            table.insert(newItems, item)
        end
    end

    -- Заполняем Items по порядку подряд без пропусков
    for i = 1, maxItemsCount do
        if newItems[i] then
            ConsoleMenuFrame.KeysFrame.Items[i] = newItems[i]
        else
            ConsoleMenuFrame.KeysFrame.Items[i] = nil
        end
    end

end

-- Функция для добавления элемента в список
function ConsoleMenu:AddKeysFrameItem(binding, title, stackCount)
    if not binding then return end
    if not title then return end

    -- Проверяем, существует ли уже элемент с таким binding
    for i = 1, maxItemsCount do
        local existingItem = ConsoleMenuFrame.KeysFrame.Items[i]
        if existingItem and existingItem.binding == binding then
            return
        end
    end

    local item = {
        binding = binding,
        title = title,
        stackCount = stackCount,
    }

    for i = 1, maxItemsCount do
        if not ConsoleMenuFrame.KeysFrame.Items[i] then
            ConsoleMenuFrame.KeysFrame.Items[i] = item
            break
        end
    end
end

-- Функция для инициализации LootList
function ConsoleMenu:SetKeysFrame()
    
    if not ConsoleMenuFrame.KeysFrame then
        local frame = CreateFrame("Frame", "KeysFrame", ConsoleMenuFrame)
        ConsoleMenuFrame.KeysFrame = frame
    end

    local frame = ConsoleMenuFrame.KeysFrame
    frame:SetSize(frameWidth, frameHeight)
    frame:SetPoint("BOTTOMRIGHT", ConsoleMenuFrame, "BOTTOMRIGHT", -48, 48)

    if not ConsoleMenuFrame.KeysFrame.Items then
        ConsoleMenuFrame.KeysFrame.Items = {}
    end

    for i = 1, maxItemsCount do
        local item = CreateFrame("Frame", "KeysFrameItem" .. i, frame)
        frame["Item" .. i] = item

        item:SetWidth(frameWidth)
        item:SetHeight(sectionHeight)

        item:Hide()

        if i == 1 then
            item:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        else
            item:SetPoint("BOTTOMRIGHT", frame["Item" .. (i-1)], "TOPRIGHT", 0, padding)
        end

        ConsoleMenu:InitFadeAnimations(item, animationDuration)

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

            -- Счетчик стаков
            if not item.Icon.StackCount then
                item.Icon.StackCount = CreateFrame("Frame", "KeysFrameItemStackCount" .. i, item.Icon)
                item.Icon.StackCount:SetSize(stackCountSize, stackCountSize)
                item.Icon.StackCount:SetPoint("BOTTOMRIGHT", item.Icon.MainTexture, "BOTTOMRIGHT", stackCountOffset, -stackCountOffset)

                item.Icon.StackCount:Hide()

                -- Фон счетчика
                if not item.Icon.StackCount.Background then
                    item.Icon.StackCount.Background = item.Icon.StackCount:CreateTexture(nil, "ARTWORK")
                    item.Icon.StackCount.Background:SetAllPoints()
                    item.Icon.StackCount.Background:SetAlpha(0.5)

                    local texture = ConsoleMenu.Backgrounds["PAD"]
                    item.Icon.StackCount.Background:SetTexture(texture)
                end

                -- Тень счетчика
                if not item.Icon.StackCount.Shadow then
                    item.Icon.StackCount.Shadow = item.Icon.StackCount:CreateTexture(nil, "BACKGROUND")
                    item.Icon.StackCount.Shadow:SetPoint("TOPLEFT", item.Icon.StackCount.Background, "TOPLEFT", -stackCountShadowOffsef, stackCountShadowOffsef)
                    item.Icon.StackCount.Shadow:SetPoint("BOTTOMRIGHT", item.Icon.StackCount.Background, "BOTTOMRIGHT", stackCountShadowOffsef, -stackCountShadowOffsef)

                    local texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png"
                    item.Icon.StackCount.Shadow:SetTexture(texture)
                end

                -- Текст счетчика
                if not item.Icon.StackCount.Text then
                    item.Icon.StackCount.Text = item.Icon.StackCount:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    item.Icon.StackCount.Text:SetAllPoints()
                    item.Icon.StackCount.Text:SetJustifyH("CENTER")
                    item.Icon.StackCount.Text:SetTextColor(1.0, 0.960784, 0.772549, 1)
                    item.Icon.StackCount.Text:SetText("2")
                end
            end
        
        end

        -- Текст
        if not item.Text then
            item.Text = item:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            item.Text:SetPoint("RIGHT", item.Icon, "LEFT", -padding, 0)
            item.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", fontSize, "")
            item.Text:SetTextColor(1.0, 0.960784, 0.772549, 1)
            item.Text:SetText("Взаимодействие")
        end

    end

    -- Регистрация события изменения режима геймпада
    frame:RegisterEvent("GAME_PAD_ACTIVE_CHANGED")

    local function OnKeysFrameEvent(self, event, ...)
        if event == "GAME_PAD_ACTIVE_CHANGED" then
            gamePadActive = ...
        end
    end

    frame:SetScript("OnEvent", OnKeysFrameEvent)

end