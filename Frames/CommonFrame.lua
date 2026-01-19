-- CommonFrame.lua

local ConsoleMenu = _G.ConsoleMenu

function ConsoleMenu:SetCommonFrame()
    if _G.ConsoleMenuFrame then
        return
    end

    local ConsoleMenuFrame = CreateFrame("Frame", "ConsoleMenuFrame", UIParent)
    ConsoleMenuFrame:SetAllPoints()
    ConsoleMenuFrame:Show()

    -- Фрейм для загрузки M2 модели. Без этого кода фреймы с такой же моделью не будет отображаться.
    if not ConsoleMenuFrame.Glow then
        ConsoleMenuFrame.Glow = CreateFrame("PlayerModel", nil, ConsoleMenuFrame)
    end
    ConsoleMenuFrame.Glow:SetSize(1, 1)
    ConsoleMenuFrame.Glow:SetPoint("TOPLEFT", ConsoleMenuFrame, "TOPLEFT", -1, -1)
    ConsoleMenuFrame.Glow:SetFrameStrata(ConsoleMenuFrame:GetFrameStrata())
    ConsoleMenuFrame.Glow:SetFrameLevel(ConsoleMenuFrame:GetFrameLevel() - 1)
    ConsoleMenuFrame.Glow:SetModel(5201375)
    ConsoleMenuFrame.Glow:SetParent(ConsoleMenuFrame)
    ConsoleMenuFrame.Glow:SetKeepModelOnHide(true)
    ConsoleMenuFrame.Glow:SetAnimation(1)

    ConsoleMenuFrame.Glow:SetTransform(
        CreateVector3D(0.039, 0.039, 0),
        CreateVector3D(0, 0, 0),
        0.017
    )
    ConsoleMenuFrame.Glow:SetAlpha(0)
    ConsoleMenuFrame.Glow:Hide()
end