-- Тексты и проверка готовности на экране сдачи задания.

local ConsoleMenu = _G.ConsoleMenu
local Gossip = ConsoleMenu.Gossip

-- Текст сдачи с количеством.
local function AppendRequiredCount(text, amount)
    return string.format("Отдать %s x%s", text, amount)
end

-- Первая буква строки в нижнем регистре с учётом кириллицы.
local function LowerFirstLetter(text)
    if not text or text == "" then
        return text
    end
    if string.byte(text) >= 0xC0 then
        return string.lower(string.sub(text, 1, 2)) .. string.sub(text, 3)
    end
    return string.lower(string.sub(text, 1, 1)) .. string.sub(text, 2)
end

-- Количество валюты с учётом скрытых значений.
local function GetCurrencyAmount(amount)
    if not amount or issecretvalue(amount) then
        return 0
    end
    return amount
end

-- Отображаемое имя валюты, в том числе из контейнера.
local function GetCurrencyDisplayName(currencyID, quantity, fallbackName)
    local containerInfo = C_CurrencyInfo.GetCurrencyContainerInfo(currencyID, quantity)
    if containerInfo and containerInfo.name and containerInfo.name ~= "" then
        return containerInfo.name
    end
    return fallbackName
end

-- Реплика о недостающей валюте.
local function FormatCollectMoreCurrency(currency, current)
    local currentAmount = GetCurrencyAmount(current)
    local requiredAmount = GetCurrencyAmount(currency.requiredAmount)
    local remaining = math.max(requiredAmount - currentAmount, 1)
    local currencyName = GetCurrencyDisplayName(currency.currencyID, remaining, currency.name)
    currencyName = LowerFirstLetter(currencyName)

    return string.format("Мне нужно собрать еще %d %s", remaining, currencyName)
end

-- Обход требуемых валют задания.
local function ForEachRequiredCurrency(callback)
    local numRequiredCurrencies = GetNumQuestCurrencies() or 0
    for index = 1, numRequiredCurrencies do
        local currency = C_QuestOffer.GetQuestRequiredCurrencyInfo(index)
        if currency and callback(currency) == false then
            return false
        end
    end
    return true
end

-- Список требуемых валют задания.
local function GetRequiredCurrencies()
    local currencies = {}
    local numRequiredCurrencies = GetNumQuestCurrencies() or 0
    for index = 1, numRequiredCurrencies do
        local currency = C_QuestOffer.GetQuestRequiredCurrencyInfo(index)
        if currency then
            currencies[#currencies + 1] = currency
        end
    end
    return currencies
end

-- Требуемое золото для сдачи задания.
local function GetRequiredMoney()
    return GetQuestMoneyToGet() or 0
end

-- Есть ли требования помимо предметов.
local function HasNonItemRequirements()
    return GetRequiredMoney() > 0 or (GetNumQuestCurrencies() or 0) > 0
end

-- Выполнены ли требования по золоту и валюте.
local function AreNonItemRequirementsMet()
    local requiredMoney = GetRequiredMoney()
    if requiredMoney > 0 and GetMoney() < requiredMoney then
        return false
    end

    return ForEachRequiredCurrency(function(currency)
        local info = C_CurrencyInfo.GetCurrencyInfo(currency.currencyID)
        local current = GetCurrencyAmount(info and info.quantity)
        local required = GetCurrencyAmount(currency.requiredAmount)
        return current >= required
    end)
end

-- Сколько требуемых предметов уже есть у игрока.
local function CountReadyRequiredItems(numItems)
    local ready = 0
    for index = 1, numItems do
        local _, _, count, _, _, itemID = GetQuestItemInfo("required", index)
        if C_Item.GetItemCount(itemID) >= count then
            ready = ready + 1
        end
    end
    return ready
end

-- Имя и количество требуемого предмета с запасным названием.
local function GetRequiredItemNameAndCount(index)
    local name, _, count = GetQuestItemInfo("required", index)
    local link = GetQuestItemLink("required", index)
    local itemName = link and C_Item.GetItemInfo(link)
    if not itemName or itemName == "" then
        itemName = name
    end
    if not itemName or itemName == "" then
        itemName = "предмет"
    end
    return itemName, count
end

-- Реплика готовности без предметов.
local function GetNonItemReadyText()
    local requiredMoney = GetRequiredMoney()
    local currencies = GetRequiredCurrencies()
    local numCurrencies = #currencies

    if requiredMoney > 0 and numCurrencies == 0 then
        return AppendRequiredCount("золото", GetMoneyString(requiredMoney, true))
    end
    if numCurrencies == 1 and requiredMoney == 0 then
        local currency = currencies[1]
        return AppendRequiredCount(LowerFirstLetter(currency.name), currency.requiredAmount)
    end
    return "Все необходимое при мне"
end

-- Реплика при нехватке золота или валюты.
local function GetUnmetNonItemMessage()
    local requiredMoney = GetRequiredMoney()
    local numCurrencies = GetNumQuestCurrencies() or 0

    if requiredMoney > 0 and GetMoney() < requiredMoney and numCurrencies == 0 then
        return string.format(
            "Золото: %s/%s",
            GetMoneyString(GetMoney(), true),
            GetMoneyString(requiredMoney, true)
        )
    end

    local unmetCurrency
    ForEachRequiredCurrency(function(currency)
        local info = C_CurrencyInfo.GetCurrencyInfo(currency.currencyID)
        local current = GetCurrencyAmount(info and info.quantity)
        local required = GetCurrencyAmount(currency.requiredAmount)
        if current < required then
            unmetCurrency = { currency = currency, current = current }
            return false
        end
    end)

    if unmetCurrency and requiredMoney == 0 and numCurrencies == 1 then
        return FormatCollectMoreCurrency(unmetCurrency.currency, unmetCurrency.current)
    end

    return Gossip.needMoreTime
end

-- Реплика готовности сдать задание.
local function GetQuestProgressReadyText(questID, numItems, isComplete)
    if isComplete then
        if numItems == 1 then
            local itemName, count = GetRequiredItemNameAndCount(1)
            return AppendRequiredCount(itemName .. " при мне.", count)
        end
        if numItems > 1 then
            return "Готово!"
        end
        if HasNonItemRequirements() then
            return GetNonItemReadyText()
        end
        return "Что дальше?"
    end

    if numItems == 1 then
        local name, count = GetRequiredItemNameAndCount(1)
        return AppendRequiredCount(name .. " при мне.", count)
    end
    if numItems > 1 then
        return "Все необходимое при мне"
    end

    return GetNonItemReadyText()
end

-- Готов ли игрок продолжить сдачу задания.
local function IsQuestProgressReady(questID, numItems, isComplete)
    if isComplete then
        return numItems > 0 or not HasNonItemRequirements() or AreNonItemRequirementsMet()
    end
    if numItems > 0 then
        return CountReadyRequiredItems(numItems) == numItems
    end
    if HasNonItemRequirements() then
        return AreNonItemRequirementsMet()
    end
    return false
end

-- Пункты меню на экране прогресса задания.
function Gossip.BuildQuestProgressOptions(dataProvider, questID)
    local isComplete = C_QuestLog.IsComplete(questID)
    local numItems = GetNumQuestItems()

    local function InsertQuestOption(optionType, name)
        dataProvider:Insert({ type = optionType, name = name })
    end

    if IsQuestProgressReady(questID, numItems, isComplete) then
        InsertQuestOption("progressQuest", GetQuestProgressReadyText(questID, numItems, isComplete))
    elseif numItems > 0 then
        InsertQuestOption("goodbye", Gossip.needMoreTime)
    else
        InsertQuestOption("goodbye", GetUnmetNonItemMessage())
    end
end
