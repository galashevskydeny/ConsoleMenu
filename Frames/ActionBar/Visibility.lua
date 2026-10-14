-- Единственный внешний вход: показать или скрыть панель заклинаний.

local ConsoleMenu = _G.ConsoleMenu
local ActionBar = ConsoleMenu.ActionBar

-- Остальные части аддона просят панель появиться или исчезнуть здесь, а не у кадра напрямую.
function ActionBar.SetBarDesired(shown)
    local frame = ActionBar.GetFrame()
    if frame then
        frame.barDesired = shown and true or false
    end
    if ActionBar.UpdateModifierState then
        ActionBar.UpdateModifierState()
        return
    end
    if not frame then
        return
    end
    if shown then
        frame:Show()
    else
        frame:Hide()
    end
end

-- Можно ли сейчас показывать панель по желанию остальных частей.
function ActionBar.BarIsDesired()
    local frame = ActionBar.GetFrame()
    if not frame or frame.barDesired == nil then
        return true
    end
    return frame.barDesired == true
end
