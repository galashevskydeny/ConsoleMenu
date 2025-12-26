-- CommonFrame.lua

local ConsoleMenu = _G.ConsoleMenu

function ConsoleMenu:SetCommonFrame()
    if _G.ConsoleMenuFrame then
        return
    end

    local ConsoleMenuFrame = CreateFrame("Frame", "ConsoleMenuFrame", UIParent)
    ConsoleMenuFrame:SetAllPoints()
    ConsoleMenuFrame:Show()
end