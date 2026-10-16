-- Вход свечения. Соседние кнопки меняют размер в обновлении рисунка,
-- а к тёмной кнопке напротив их сдвигает группа.

local ConsoleMenu = _G.ConsoleMenu
local ActionBar = ConsoleMenu.ActionBar

-- Умение должно засветиться или погаснуть. Пока кнопка крутится, кольцо только запоминается.
function ActionBar.NoteSpellGlow(slotID, spellID, event)
    if ActionBar.UpdateGlow then
        ActionBar.UpdateGlow(slotID, spellID, event)
    end
end

-- После переворота доигрывает отложенное свечение.
function ActionBar.FlushPendingGlow(btn)
    if not btn or not btn.glowPendingSlot then
        return
    end
    local slotID = btn.glowPendingSlot
    local spellID = btn.glowPendingSpell
    local event = btn.glowPendingEvent
    btn.glowPendingSlot = nil
    btn.glowPendingSpell = nil
    btn.glowPendingEvent = nil
    ActionBar.NoteSpellGlow(slotID, spellID, event)
end
