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
local function UpdateKeyFrame(frame, binding, title, stackCount)
    if not frame then return end
    if not binding then return end
    if not title then return end

    if string.find(binding, "SHIFT") or string.find(binding, "CTRL") or string.find(binding, "ALT")then
        -- Кнопка с модификатором

        frame.Icon.PlusTexture:Show()
        frame.Icon.ModifierTexture:Show()

        local width = iconSize * 2 + iconPlusSize + iconInnerPadding * 2 + iconInnerPadding
        local height = iconSize + iconInnerPadding * 2

        frame:SetHeight(height)
        frame.Icon:SetWidth(width)
        frame.Icon:SetHeight(height)

        local mainKey = string.match(binding, ".-%-(.+)$")
        local modifierKey = string.match(binding, "^(.+)%-[^%-]+$")

        if gamePadActive then
            if modifierKey == "SHIFT" then
                modifierKey = GetCVar("GamePadEmulateShift")
            elseif modifierKey == "CTRL" then
                modifierKey = GetCVar("GamePadEmulateCtrl")
            elseif modifierKey == "ALT" then
                modifierKey = GetCVar("GamePadEmulateAlt")
            end
        end

        local mainTexture = ConsoleMenu.Textures[mainKey].texture
        local modifierTexture = ConsoleMenu.Textures[modifierKey].texture
        local background = ConsoleMenu.Backgrounds["PAIR"]

        frame.Icon.MainTexture:SetTexture(mainTexture)
        frame.Icon.ModifierTexture:SetTexture(modifierTexture)
        frame.Icon.Background:SetTexture(background)

        frame.Icon.MainTexture:ClearAllPoints()
        frame.Icon.MainTexture:SetPoint("RIGHT", frame.Icon, "RIGHT", -iconInnerPadding, 0)
        frame.Icon.MainTexture:SetSize(iconSize, iconSize)

        frame.Icon.StackCount:ClearAllPoints()
        frame.Icon.StackCount:SetPoint("BOTTOMRIGHT", frame.Icon.MainTexture, "BOTTOMRIGHT", stackCountOffset, -(stackCountOffset + iconInnerPadding))

        frame.Icon:ClearAllPoints()
        frame.Icon:SetPoint("RIGHT", frame, "RIGHT", iconInnerPadding, 0)

    else
        -- Кнопка без модификатора

        local texture = ConsoleMenu.Textures[binding].texture
        local background = ConsoleMenu.Textures[binding].background

        frame.Icon.PlusTexture:Hide()
        frame.Icon.ModifierTexture:Hide()

        frame:SetHeight(sectionHeight)
        frame.Icon:SetSize(iconSize, iconSize)

        frame.Icon.Background:SetTexture(background)

        frame.Icon.MainTexture:SetTexture(texture)
        frame.Icon.MainTexture:ClearAllPoints()
        frame.Icon.MainTexture:SetAllPoints()

        frame.Icon.StackCount:ClearAllPoints()
        frame.Icon.StackCount:SetPoint("BOTTOMRIGHT", frame.Icon.MainTexture, "BOTTOMRIGHT", stackCountOffset, -stackCountOffset)

        frame.Icon:ClearAllPoints()
        frame.Icon:SetPoint("RIGHT", frame, "RIGHT", 0, 0)

    end

    frame.Icon.StackCount.Text:SetText(stackCount)
    frame.Text:SetText(title)

    if issecretvalue(stackCount) then
        frame.Icon.StackCount:Show()
    else
        -- Удаляем элемент, если стаков 0 и заклинание не пригодно к использованию
        if stackCount == "" or not stackCount or stackCount == "1" then
            frame.Icon.StackCount:Hide()
        else
            frame.Icon.StackCount:Show()
        end
    end
end

-- Функция для сброса элементов списка
function ConsoleMenu:ResetKeysItems()
    if ConsoleMenuFrame.KeysFrame then
    ConsoleMenuFrame.KeysFrame.Items = {}
    end
end

-- Функция для обновления списка
function ConsoleMenu:UpdateKeysFrame()
    C_Timer.After(0.05, function()
        local activeItems = 0

        for i = 1, maxItemsCount do
            local frame = ConsoleMenuFrame.KeysFrame["Item" .. i]
            local item = ConsoleMenuFrame.KeysFrame.Items[i]
            
            if not item then
                ConsoleMenu:AnimatedHide(frame)
            else
                UpdateKeyFrame(frame, item.binding, item.title, item.stackCount)
                ConsoleMenu:AnimatedShow(frame)
                activeItems = activeItems + 1
            end
        end

        if activeItems > 0 then
            ConsoleMenu:AnimatedShow(ConsoleMenuFrame.KeysFrame.Background)
        else
            ConsoleMenu:AnimatedHide(ConsoleMenuFrame.KeysFrame.Background)
        end
    end)
end

-- Функция для удаления элемента из списка
function ConsoleMenu:DeleteKeysFrameItem(binding, title)
    if not binding then return end

    -- Обходим Items и удаляем элемент, равный переданному
    for k, v in pairs(ConsoleMenuFrame.KeysFrame.Items) do
        if v.binding == binding and not title then
            ConsoleMenuFrame.KeysFrame.Items[k] = nil
            break
        elseif v.binding == binding and title then
            if v.binding == binding and v.title == title then
                ConsoleMenuFrame.KeysFrame.Items[k] = nil
                break
            end
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
        if existingItem and existingItem.binding == binding and existingItem.title == title then
            return
        end
    end

    local item = {
        binding = binding,
        title = title,
        stackCount = stackCount,
    }

    local inserted = false
    for i = 1, maxItemsCount do
        if not ConsoleMenuFrame.KeysFrame.Items[i] then
            ConsoleMenuFrame.KeysFrame.Items[i] = item
            inserted = true
            break
        end
    end

    -- PAD1 всегда должен попадать в список, даже если видимые ячейки заняты:
    -- ставим его в конец видимого списка.
    if not inserted and binding == "PAD1" then
        ConsoleMenuFrame.KeysFrame.Items[maxItemsCount] = item
    end
end

function ConsoleMenu:CheckKeysFrameItem(binding)
    if not binding then return end

    for i = 1, maxItemsCount do
        local item = ConsoleMenuFrame.KeysFrame.Items[i]
        if item and item.binding == binding then
            return true
        end
    end

    return false
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

    frame.Background = frame:CreateTexture(nil, "BACKGROUND")
    frame.Background:SetWidth(800)
    frame.Background:SetHeight(320)
    frame.Background:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 400, -64)
    frame.Background:SetAtlas("MapCornerShadow-Right")
    frame.Background:SetAlpha(0.85)
    frame.Background:Hide()

    ConsoleMenu:InitFadeAnimations(frame.Background, animationDuration)

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