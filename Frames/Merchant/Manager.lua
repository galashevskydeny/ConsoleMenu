-- Создание окна торговца, события открытия и закрытия, показ и скрытие.

local ConsoleMenu = _G.ConsoleMenu
local Merchant = ConsoleMenu.Merchant
local ExpandableList = ConsoleMenu.ExpandableList

-- Наложить особую рамку значка предмета.
function Merchant.DecorateIcon(iconFrame, data)
    if not iconFrame or not iconFrame.overlay then
        return
    end
    if not data or not data.itemID then
        iconFrame.overlay:Hide()
        return
    end

    local itemID = data.itemID
    if C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItemByID(itemID) then
        iconFrame.overlay:SetAtlas("AzeriteIconFrame")
        iconFrame.overlay:Show()
    elseif C_Item.IsCorruptedItem(itemID) then
        iconFrame.overlay:SetAtlas("Nzoth-inventory-icon")
        iconFrame.overlay:Show()
    elseif C_Item.IsCosmeticItem(itemID) then
        iconFrame.overlay:SetAtlas("CosmeticIconFrame")
        iconFrame.overlay:Show()
    elseif C_Soulbinds.IsItemConduitByItemInfo(itemID) then
        iconFrame.overlay:SetAtlas("ConduitIconFrame")
        iconFrame.overlay:Show()
    elseif C_Item.IsCurioItem(itemID) or C_Item.IsRelicItem(itemID) then
        iconFrame.overlay:SetAtlas("delves-curios-icon-border")
        iconFrame.overlay:Show()
    else
        iconFrame.overlay:Hide()
    end
end

-- Смена выбора в списке: подгрузить соседей и обновить подписи кнопок.
function Merchant.OnListFocusChanged(element)
    if element then
        Merchant.LoadNearTooltipData(element)
        if element.type == "merchantItem" then
            Merchant.LoadNearStackSizeData(element)
        end
    end
    Merchant.UpdateActionKeys(element)
    ConsoleMenu:UpdateKeysFrame()
end

-- Подписка на золото, валюты, прочность и сумки, пока окно открыто.
function Merchant.SetMoneyEventsRegistered(frame, isRegistered)
    if not frame then
        return
    end

    if isRegistered then
        if Merchant.moneyEventsRegistered then
            return
        end
        frame:RegisterEvent("PLAYER_MONEY")
        frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
        frame:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
        frame:RegisterEvent("BAG_UPDATE_DELAYED")
        Merchant.moneyEventsRegistered = true
    else
        if not Merchant.moneyEventsRegistered then
            return
        end
        frame:UnregisterEvent("PLAYER_MONEY")
        frame:UnregisterEvent("CURRENCY_DISPLAY_UPDATE")
        frame:UnregisterEvent("UPDATE_INVENTORY_DURABILITY")
        frame:UnregisterEvent("BAG_UPDATE_DELAYED")
        Merchant.moneyEventsRegistered = false
    end
end

-- Подписка на догрузку подсказок только пока окно видно.
function Merchant.SetTooltipEventsRegistered(frame, isRegistered)
    if not frame then
        return
    end

    if isRegistered then
        if Merchant.tooltipEventsRegistered then
            return
        end
        frame:RegisterEvent("TOOLTIP_DATA_UPDATE")
        Merchant.tooltipEventsRegistered = true
    else
        if not Merchant.tooltipEventsRegistered then
            return
        end
        frame:UnregisterEvent("TOOLTIP_DATA_UPDATE")
        Merchant.tooltipEventsRegistered = false
    end
end

-- Подписки при показе окна торговца.
local function OnMerchantFrameShow(self)
    Merchant.SetMoneyEventsRegistered(self, true)
    Merchant.SetTooltipEventsRegistered(self, true)
    Merchant.RestoreCurrentTabFocus()
    Merchant.ApplyOverrideBindings(self)
end

-- Сброс привязок при скрытии окна торговца.
local function OnMerchantFrameHide(self)
    Merchant.SaveCurrentTabFocus()
    local list = Merchant.GetList()
    if list then
        list.focusedExtent = ExpandableList.sectionHeight
    end
    Merchant.SetMoneyEventsRegistered(self, false)
    Merchant.SetTooltipEventsRegistered(self, false)
    Merchant.ClearOverrideBindings(self)
end

-- Обработка событий окна торговца.
local function OnMerchantFrameEvent(self, event, ...)
    if event == "MERCHANT_CLOSED" then
        Merchant.ResetSelection()
        Merchant.currenciesData = {}
        Merchant.tabs = {}
        Merchant.focusedTabIndex = 1
        Merchant.SetMoneyEventsRegistered(self, false)
        Merchant.SetTooltipEventsRegistered(self, false)
        return
    end

    if event == "TOOLTIP_DATA_UPDATE" then
        local dataInstanceID = ...
        Merchant.OnTooltipDataUpdate(dataInstanceID)
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        if Merchant.pendingClearOverrideBindings and not self:IsShown() then
            Merchant.ClearOverrideBindings(self)
        elseif Merchant.pendingOverrideBindings and self:IsShown() then
            Merchant.ApplyOverrideBindings(self)
        end
        return
    end

    if event == "PLAYER_MONEY" or event == "CURRENCY_DISPLAY_UPDATE" then
        Merchant.LoadCurrenciesData()
        Merchant.UpdateCurrenciesFrame()
        Merchant.UpdateKeysFrame()
        ConsoleMenu:UpdateKeysFrame()
        return
    end

    if event == "UPDATE_INVENTORY_DURABILITY" then
        Merchant.UpdateKeysFrame()
        ConsoleMenu:UpdateKeysFrame()
        return
    end

    if event == "GET_ITEM_INFO_RECEIVED" then
        local itemID, success = ...
        if success == false then
            return
        end
        if Merchant.OnItemInfoReceived(itemID) then
            Merchant.ScheduleRefresh(false)
        end
        return
    end

    if event == "MERCHANT_SHOW" then
        Merchant.ResetSelection()
        Merchant.ScheduleRefresh(true)
        return
    end

    if event == "BAG_UPDATE_DELAYED" then
        local tab = Merchant.tabs[Merchant.focusedTabIndex]
        if tab and tab.code == "sell" then
            Merchant.ScheduleRefresh(false)
        end
        return
    end

    if event == "MERCHANT_UPDATE" then
        Merchant.ScheduleRefresh(false)
    end
end

-- Создать раскрывающийся список на окне торговца.
local function CreateMerchantList(frame)
    Merchant.list = ExpandableList.Create(frame, {
        namePrefix = "ConsoleMenuMerchant",
        frameWidth = ExpandableList.frameWidth,
        contentPadding = ExpandableList.contentPadding,
        isSelectable = Merchant.IsSelectable,
        areElementsEqual = Merchant.AreElementsEqual,
        onExpand = Merchant.GetExpandInfo,
        onDecorateIcon = Merchant.DecorateIcon,
        onFocusChanged = Merchant.OnListFocusChanged,
    })
    return Merchant.list
end

-- Создание окна торговца.
function ConsoleMenu:SetItemListFrame()
    if ConsoleMenuDB.merchantWindowStyle == 2 then
        return
    end
    Merchant.CreateFrame()
end

-- Создание окна торговца.
function Merchant.CreateFrame()
    if ConsoleMenuDB.merchantWindowStyle == 2 then
        return
    end

    if ConsoleMenuFrame.ItemListFrame and ConsoleMenuFrame.ItemListFrame.IsMerchantFrameInitialized then
        return ConsoleMenuFrame.ItemListFrame
    end

    if not ConsoleMenuFrame.ItemListFrame then
        local frame = CreateFrame("Frame", "ConsoleMenuMerchantFrame", ConsoleMenuFrame)
        ConsoleMenuFrame.ItemListFrame = frame
    end

    local frame = ConsoleMenuFrame.ItemListFrame
    Merchant.frame = frame
    ConsoleMenu:InitFadeAnimations(frame, Merchant.animationDuration)

    frame:SetPoint("TOPLEFT", ConsoleMenuFrame, "TOPLEFT", Merchant.frameLeftOffset, -48 * 4)
    frame:SetWidth(ExpandableList.frameWidth)
    frame:SetPoint("BOTTOMLEFT", ConsoleMenuFrame, "BOTTOMLEFT", Merchant.frameLeftOffset, 48 * 4 + 2)
    frame:Hide()

    if not frame.Background then
        frame.Background = frame:CreateTexture(nil, "BACKGROUND")
        frame.Background:SetParent(frame)
        frame.Background:SetTexture(ExpandableList.backgroundTexturePath)
        frame.Background:SetDrawLayer("BACKGROUND", 0)
        frame.Background:Show()
        frame.Background:SetAlpha(1)
    end

    if not frame.AdditionalShadow then
        frame.AdditionalShadow = frame:CreateTexture(nil, "BACKGROUND")
        frame.AdditionalShadow:SetParent(frame)
        frame.AdditionalShadow:SetTexture(ExpandableList.backgroundTexturePath)
        frame.AdditionalShadow:SetDrawLayer("BACKGROUND", 0)
        frame.AdditionalShadow:Show()
        frame.AdditionalShadow:SetAlpha(1)
    end

    CreateMerchantList(frame)
    Merchant.CreateCurrencies(frame)
    Merchant.CreateTabs(frame)
    Merchant.CreateControllerButtons(frame)

    if not frame.FocusBindingHooksSet then
        frame.FocusBindingHooksSet = true
        frame:HookScript("OnShow", OnMerchantFrameShow)
        frame:HookScript("OnHide", OnMerchantFrameHide)
    end

    frame:RegisterEvent("MERCHANT_SHOW")
    frame:RegisterEvent("MERCHANT_UPDATE")
    frame:RegisterEvent("MERCHANT_CLOSED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    frame:SetScript("OnEvent", OnMerchantFrameEvent)

    frame.IsMerchantFrameInitialized = true
    return frame
end

-- Показать окно торговца.
function ConsoleMenu:ShowItemListFrame()
    Merchant.Show()
end

-- Показать окно торговца.
function Merchant.Show()
    local frame = Merchant.GetFrame()
    local list = Merchant.GetList()
    if not frame or not list then
        return
    end

    list:UpdateScrollBar()
    Merchant.UpdateCurrenciesFrame()
    ConsoleMenu:AnimatedShow(frame)
end

-- Скрыть окно торговца.
function ConsoleMenu:HideItemListFrame()
    Merchant.Hide()
end

-- Скрыть окно торговца.
function Merchant.Hide()
    local frame = Merchant.GetFrame()
    local list = Merchant.GetList()
    if not frame or not list then
        return
    end
    ConsoleMenu:AnimatedHide(frame)
end

-- Обновить подписи кнопок окна торговца.
function ConsoleMenu:UpdateItemListFrameKeysFrame()
    Merchant.UpdateKeysFrame()
end
