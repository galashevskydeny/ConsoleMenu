local ConsoleMenu = LibStub("AceAddon-3.0"):GetAddon("ConsoleMenu")
local parentFrame
local frames = {}
local focusedIndex = 1

-- Установка иконки пункту списка
local function setIcon(frame, data)
    if not frame.icon then
        frame.icon = CreateFrame("Frame", nil, frame)
        frame.icon:SetSize(32, 32)
        frame.icon:SetPoint("LEFT", 10, 0)
    end

    if not frame.icon.texture then
        frame.icon.texture = frame.icon:CreateTexture(nil, "ARTWORK")
        frame.icon.texture:Hide()
    end

    if not frame.icon.border then
        frame.icon.border = frame.icon:CreateTexture(nil, "OVERLAY")
        frame.icon.border:SetPoint("TOPLEFT", frame.icon.texture, "TOPLEFT", -6, 6)
        frame.icon.border:SetPoint("BOTTOMRIGHT", frame.icon.texture, "BOTTOMRIGHT", 6, -6)
        frame.icon.border:SetAtlas("plunderstorm-actionbar-slot-border")
        frame.icon.border:Hide()
    else
        frame.icon.border:Hide()
    end

    if data.type == "stone" then
        frame.icon.texture:SetAllPoints()
        frame.icon.texture:SetTexture(data.texture)
        ApplyMaskToTexture(frame.icon.texture)
        frame.icon.border:Show()
        frame.icon.texture:Show()
    else
        frame.icon.texture:Hide()
    end
end

-- Создание ScrollBox
local function CreateFastTravelScrollBox()
    local FastTravelScrollBox = CreateFrame("Frame", "FastTravelScroll", UIParent)
    FastTravelScrollBox:SetSize(480, 48 * 3)
    FastTravelScrollBox:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 48, 96)

    local ScrollBox = CreateFrame("Frame", "FastTravelScrollBox", FastTravelScrollBox, "WowScrollBoxList")
    FastTravelScrollBox.ScrollBox = ScrollBox
    ScrollBox:SetPoint("TOPLEFT", FastTravelScrollBox, "TOPLEFT", 0, 0)
    ScrollBox:SetAllPoints()

    local ScrollBar = CreateFrame("EventFrame", "FastTravelScrollBar", FastTravelScrollBox, "MinimalScrollBar")
    FastTravelScrollBox.ScrollBox.ScrollBar = ScrollBar

    ScrollBar:SetPoint("TOPLEFT", ScrollBox, "TOPRIGHT")
    ScrollBar:SetPoint("BOTTOMLEFT", ScrollBox, "BOTTOMRIGHT")

    local DataProvider = CreateDataProvider()
    local ScrollView = CreateScrollBoxListLinearView()
    ScrollView:SetDataProvider(DataProvider)
    ScrollUtil.InitScrollBoxListWithScrollBar(ScrollBox, ScrollBar, ScrollView)

    local function UpdateScrollBarVisibility()
        local totalHeight = ScrollView:GetElementExtent() * DataProvider:GetSize() - 1
        if totalHeight <= FastTravelScrollBox:GetHeight() then
            FastTravelScrollBar:Hide()
        else
            FastTravelScrollBar:Show()
        end
    end

    local function UpdateFocus(newIndex)
        for _, frame in ipairs(frames) do
            if frame and frame.SetFocused then
                frame:SetFocused(false)
            end
        end
        focusedIndex = newIndex
        if frames[focusedIndex] then
            frames[focusedIndex]:SetFocused(true)
            parentFrame.ScrollBox:ScrollToElementDataIndex(newIndex)
        end
    end

    -- Инициализатор для кнопки
    local function Initializer(frame, data)
        table.insert(frames, frame)

        -- Привязка действия "использовать предмет"
        if data.type == "stone" and data.id then
            local item = Item:CreateFromItemID(data.id)
            item:ContinueOnItemLoad(function()
                local name = item:GetItemName()
                frame:SetAttribute("type", "item")
                frame:SetAttribute("item", name)
            end)
        end

        setIcon(frame, data)

        if not frame.text then
            frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            frame.text:SetPoint("LEFT", frame.icon, "RIGHT", 10, 0)
            frame.text:SetPoint("RIGHT", -10, 0)
            frame.text:SetJustifyH("LEFT")
        end

        frame.text:SetFont("Fonts\\FRIZQT___CYR.TTF", 20, "OUTLINE")
        frame.text:SetText(data.name or "???")
        frame.text:SetTextColor(1, 0.976, 0.855)

        if not frame.bg then
            frame.bg = frame:CreateTexture(nil, "BACKGROUND")
            frame.bg:SetAllPoints()
            frame.bg:SetAtlas("Garr_BuildingInfoShadow")
            frame.bg:Hide()
        end

        function frame:SetFocused(isFocused)
            if isFocused then
                frame.text:SetTextColor(1, 0.768, 0.071)
                frame.bg:Show()
            else
                frame.text:SetTextColor(1, 0.976, 0.855)
                frame.bg:Hide()
            end
        end

        frame:SetAttribute("type", "item")
        frame:SetAttribute("item", data.name)

    end

    -- Используем кнопки как элементы
    ScrollView:SetElementExtent(48)
    ScrollView:SetElementInitializer("Button", Initializer, "InsecureActionButtonTemplate,SecureActionButtonTemplate")

    DataProvider:Flush()
    frames = {}

    local itemInfo = 6948
    local itemName, _, _, _, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(itemInfo)

    DataProvider:Insert({
        id = itemInfo,
        type = "stone",
        name = itemName or "Камень возвращения",
        texture = itemTexture,
    })

    DataProvider:Insert({
        type = "stone",
        name = "stone1",
    })

    DataProvider:Insert({
        type = "stone",
        name = "stone2",
    })

    DataProvider:Insert({
        type = "stone",
        name = "stone3",
    })

    UpdateScrollBarVisibility()

    -- Изначально скрываем GossipScrollBox
    FastTravelScrollBox:Hide()

    return FastTravelScrollBox, UpdateFocus
end

local function MoveFocus(delta)
    local newIndex = math.max(1, math.min(focusedIndex + delta, #frames))
    updateFocus(newIndex)
end

local function toggleController(updateFocus)
    local controllerHandler = CreateFrame("Frame", "ControllerHandlerFrame", parentFrame)

    parentFrame:HookScript("OnShow", function()
        
        controllerHandler:EnableGamePadButton(true)
        controllerHandler:SetScript("OnGamePadButtonDown", function(_, button)
            if button == "PADDUP" then
                MoveFocus(-1)
            elseif button == "PADDDOWN" then
                MoveFocus(1)
            elseif button == "PAD1" then
                if frames[focusedIndex] then
                    frames[focusedIndex]:Click()
                end
            elseif button == "PAD2" then
                FastTravelScroll:Hide()
            end
        end)
    end)

    parentFrame:HookScript("OnHide", function()
        controllerHandler:EnableGamePadButton(false)
        controllerHandler:SetScript("OnGamePadButtonDown", nil)
    end)
end

function ConsoleMenu:SetFastTravelFrame()
    parentFrame, updateFocus = CreateFastTravelScrollBox()
    toggleController(updateFocus)
end

SLASH_FASTTRAVEL1 = "/fasttravel"
SlashCmdList["FASTTRAVEL"] = function()
    if parentFrame and parentFrame:IsShown() then
        print("FastTravel уже открыт.")
        return
    end

    if not parentFrame or not updateFocus then
        ConsoleMenu:SetFastTravelFrame()
    end

    if parentFrame then
        parentFrame:Show()
    end

    if updateFocus then
        updateFocus(1)
    end
end
