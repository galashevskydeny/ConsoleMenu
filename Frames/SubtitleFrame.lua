-- SubtitleFrame.lua

local ConsoleMenu = _G.ConsoleMenu
local parentFrame

-- Функция инициализации SubtitleFrame
function ConsoleMenu:SetSubtitleFrame()
    if ConsoleMenuDB.dialogQuestWindowStyle == 2 then
        return
    end

    if not self.SubtitleFrame then
        self.SubtitleFrame = CreateFrame("Frame")
    end

    self.ContextsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
end

