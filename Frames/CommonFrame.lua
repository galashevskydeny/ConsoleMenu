-- CommonFrame.lua

local ConsoleMenu = _G.ConsoleMenu

-- События, после которых предмет задания нужно заново положить в ячейку.
local questUseItemEvents = {
    "QUEST_LOG_UPDATE",
    "QUEST_ACCEPTED",
    "QUEST_REMOVED",
    "QUEST_TURNED_IN",
    "QUEST_WATCH_UPDATE",
    "SUPER_TRACKING_CHANGED",
    "BAG_UPDATE_DELAYED",
    "PLAYER_REGEN_ENABLED",
}

function ConsoleMenu:SetCommonFrame()
    if _G.ConsoleMenuFrame then
        return
    end

    local ConsoleMenuFrame = CreateFrame("Frame", "ConsoleMenuFrame", UIParent)
    ConsoleMenuFrame:SetAllPoints()
    ConsoleMenuFrame:Show()

    for index = 1, #questUseItemEvents do
        ConsoleMenuFrame:RegisterEvent(questUseItemEvents[index])
    end

    ConsoleMenuFrame:SetScript("OnEvent", function()
        ConsoleMenu:UpdateQuestUseItemSlot()
    end)
end