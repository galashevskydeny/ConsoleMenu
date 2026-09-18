-- Блок золота и валют текущего торговца справа от списка.

local ConsoleMenu = _G.ConsoleMenu
local Merchant = ConsoleMenu.Merchant

-- Обновить одну строку блока валют.
local function UpdateCurrencyItemFrame(frame, item)
    if not frame then
        return
    end

    if not item then
        frame:Hide()
        return
    end

    frame:Show()

    if not frame.Icon then
        return
    end

    if item.texture then
        frame.Icon:Show()
        frame.Icon.MainTexture:SetTexture(item.texture)
    else
        frame.Icon:Hide()
    end

    if item.name and item.count then
        frame.Text:SetText(item.name .. " " .. item.separator .. item.count)
    elseif item.name then
        frame.Text:SetText(item.name)
    else
        frame.Text:SetText("")
    end
end

-- Считать золото и валюты текущего торговца.
function Merchant.LoadCurrenciesData()
    Merchant.currenciesData = {}

    table.insert(Merchant.currenciesData, {
        count = GetMoneyString(GetMoney(), true),
        name = "Золото",
        texture = "Interface\\Icons\\UI_PlunderCoins.tga",
        separator = "",
    })

    local merchantCurrencyIDs = nil
    if C_MerchantFrame.GetMerchantCurrencies then
        merchantCurrencyIDs = C_MerchantFrame.GetMerchantCurrencies()
    end
    if not merchantCurrencyIDs and GetMerchantCurrencies then
        merchantCurrencyIDs = { GetMerchantCurrencies() }
    end

    if merchantCurrencyIDs then
        for index = 1, #merchantCurrencyIDs do
            if #Merchant.currenciesData >= Merchant.currenciesMaxItems then
                break
            end

            local currencyID = merchantCurrencyIDs[index]
            if currencyID then
                local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
                if info then
                    table.insert(Merchant.currenciesData, {
                        texture = info.iconFileID,
                        name = info.name,
                        count = info.quantity,
                        separator = "x",
                    })
                end
            end
        end
    end
end

-- Обновить блок валют справа.
function Merchant.UpdateCurrenciesFrame()
    local frame = Merchant.GetFrame()
    if not frame or not frame.Currencies then
        return
    end

    for index = 1, Merchant.currenciesMaxItems do
        local currencyFrame = frame.Currencies["Item" .. index]
        UpdateCurrencyItemFrame(currencyFrame, Merchant.currenciesData[index])
    end
end

-- Создать блок валют на окне торговца.
function Merchant.CreateCurrencies(frame)
    if frame.Currencies then
        return frame.Currencies
    end

    local currenciesHeight = Merchant.currenciesSectionHeight * Merchant.currenciesMaxItems
    local currencies = CreateFrame("Frame", "ConsoleMenuMerchantCurrencies", frame)
    frame.Currencies = currencies
    currencies:SetSize(Merchant.currenciesWidth, currenciesHeight)
    currencies:SetPoint("TOPRIGHT", ConsoleMenuFrame, "TOPRIGHT", -64, -48 * 4)

    local ExpandableList = ConsoleMenu.ExpandableList
    currencies.Background = currencies:CreateTexture(nil, "BACKGROUND")
    currencies.Background:SetTexture(ExpandableList.backgroundTexturePath)
    currencies.Background:SetDrawLayer("BACKGROUND", 0)
    currencies.Background:SetPoint("LEFT", currencies, "LEFT", -ExpandableList.backgroundHOffset, 0)
    currencies.Background:SetPoint("RIGHT", currencies, "RIGHT", ExpandableList.backgroundHOffset * 2, 0)
    currencies.Background:SetPoint("TOP", currencies, "TOP", 0, ExpandableList.backgroundVOffset * 0.8)
    currencies.Background:SetPoint("BOTTOM", currencies, "BOTTOM", 0, -ExpandableList.backgroundVOffset * 0.8)
    currencies.Background:SetAlpha(0.75)
    currencies.Background:Show()

    local currenciesIconSize = Merchant.currenciesSectionHeight
    for index = 1, Merchant.currenciesMaxItems do
        local item = CreateFrame("Frame", nil, currencies)
        currencies["Item" .. index] = item
        item:SetWidth(Merchant.currenciesWidth)
        item:SetHeight(Merchant.currenciesSectionHeight)
        item:Hide()

        if index == 1 then
            item:SetPoint("TOPLEFT", currencies, "TOPLEFT", 0, 0)
        else
            item:SetPoint("TOPLEFT", currencies["Item" .. (index - 1)], "BOTTOMLEFT", 0, -Merchant.currenciesIconInnerPadding * 1.5)
        end

        ConsoleMenu:InitFadeAnimations(item, Merchant.animationDuration)

        item.Icon = CreateFrame("Frame", nil, item)
        item.Icon:SetSize(currenciesIconSize, currenciesIconSize)
        item.Icon:SetPoint("RIGHT", item, "RIGHT", 0, 0)

        item.Icon.MainTexture = item.Icon:CreateTexture(nil, "ARTWORK")
        item.Icon.MainTexture:SetAllPoints()
        item.Icon.Mask = item.Icon:CreateMaskTexture()
        item.Icon.Mask:SetAllPoints(item.Icon.MainTexture)
        item.Icon.Mask:SetTexture(ExpandableList.circleMaskPath, ExpandableList.maskWrapMode)
        item.Icon.MainTexture:AddMaskTexture(item.Icon.Mask)

        item.Text = item:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        item.Text:SetPoint("RIGHT", item.Icon, "LEFT", -Merchant.currenciesIconInnerPadding * 2, 0)
        item.Text:SetJustifyH("LEFT")
        item.Text:SetFont(ExpandableList.fontName, Merchant.currenciesFontSize, "")
        item.Text:SetTextColor(1.0, 0.960784, 0.772549, 1)
    end

    return currencies
end
