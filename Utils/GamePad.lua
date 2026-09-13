local ConsoleMenu = _G.ConsoleMenu

-- Запоминает, является ли геймпад текущим источником ввода
function ConsoleMenu:SetGamePadActive(active)
    self.gamePadActive = active and true or false
end

-- Возвращает, идёт ли ввод с геймпада
function ConsoleMenu:IsGamePadActive()
    return self.gamePadActive == true
end

-- Включает вибрацию геймпада при вспышке готовности заклинания
function ConsoleMenu:SetVibrationSpellGlow()
    if ConsoleMenuDB.controllerVibration == 2 then
        C_GamePad.SetVibration("High", 1.0)
    end
end