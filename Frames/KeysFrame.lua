local ConsoleMenu = _G.ConsoleMenu

local maxItemsCount = 5

local frameWidth = 304

local sectionHeight = 40
local sectionPadding = 0
local iconSize = sectionHeight - sectionPadding * 2

local padding = 12

local frameHeight = sectionHeight * maxItemsCount + padding * (maxItemsCount - 1)

local fontSize = 16

-- Функция для инициализации LootList
function ConsoleMenu:SetKeysFrame()
    
    if not ConsoleMenuFrame.KeysFrame then
        local frame = CreateFrame("Frame", "KeysFrame", ConsoleMenuFrame)
        ConsoleMenuFrame.KeysFrame = frame
    end

    local frame = ConsoleMenuFrame.KeysFrame
    frame:SetSize(frameWidth, frameHeight)
    frame:SetPoint("BOTTOMRIGHT", ConsoleMenuFrame, "BOTTOMRIGHT", -48, 48)

    for i = 1, maxItemsCount do
        local item = CreateFrame("Frame", "KeysFrameItem" .. i, frame)
        frame["Item" .. i] = item

        item:SetWidth(frameWidth)
        item:SetHeight(sectionHeight)

        item:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, (sectionHeight * (i-1) + padding * (i-1)))

        -- Иконка
        if not item.Icon then
            item.Icon = CreateFrame("Frame", nil, item)
            item.Icon:SetSize(iconSize, iconSize)
            item.Icon:SetPoint("RIGHT", sectionPadding, 0)

            -- Фон для иконки
            if not item.Icon.Background then
                item.Icon.Background = item.Icon:CreateTexture(nil, "BACKGROUND")
                item.Icon.Background:SetAllPoints()

                local texture = ConsoleMenu.Textures["EMPTY"]
                item.Icon.Background:SetTexture(texture)
            end
        end
    end

end