local ConsoleMenu = _G.ConsoleMenu

function ConsoleMenu:SetVibrationSpellGlow()
    if ConsoleMenuDB.controllerVibration == 2 then
        C_GamePad.SetVibration("High", 1.0)
    end
end