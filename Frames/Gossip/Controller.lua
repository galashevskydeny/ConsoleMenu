-- Обработка кнопок контроллера и мягкий выбор цели.

local ConsoleMenu = _G.ConsoleMenu
local Gossip = ConsoleMenu.Gossip

-- Подключение обработки кнопок контроллера.
function Gossip.EnableController()
    local parentFrame = Gossip.parentFrame
    local controllerHandler = CreateFrame("Frame", "ConsoleMenuGossipController", parentFrame)

    parentFrame:HookScript("OnShow", function()
        Gossip.gamePadActive = Gossip.IsControllerActive()
        controllerHandler:EnableGamePadButton(true)
        controllerHandler:SetScript("OnGamePadButtonDown", function(_, button)
            if button == "PADDUP" then
                Gossip.MoveFocus(-1)
            elseif button == "PADDDOWN" then
                Gossip.MoveFocus(1)
            elseif button == "PAD1" then
                local element = Gossip.GetListElement(Gossip.focusedIndex)
                if element then
                    Gossip.UpdateFocus(element, true)
                    Gossip.SelectOption(element)
                end
            elseif button == "PAD2" then
                C_GossipInfo.CloseGossip()
                CloseQuest()
            elseif button == "PAD3" then
                ConsoleMenu:RepeatCurrentSubtitles()
            elseif button == "PAD4" then
                ConsoleMenu:SkipCurrentSubtitle()
            end
        end)
    end)

    parentFrame:HookScript("OnHide", function()
        controllerHandler:EnableGamePadButton(false)
        controllerHandler:SetScript("OnGamePadButtonDown", nil)
    end)
end

-- Сохранить и отключить мягкий выбор цели.
function Gossip.StoreAndDisableSoftTarget()
    if InCombatLockdown() then
        return
    end
    if not Gossip.softTargetStored then
        Gossip.savedSoftTargetEnemy = GetCVar("SoftTargetEnemy")
        Gossip.savedSoftTargetFriend = GetCVar("SoftTargetFriend")
        Gossip.softTargetStored = true
    end
    SetCVar("SoftTargetEnemy", 0)
    SetCVar("SoftTargetFriend", 0)
end

-- Восстановить мягкий выбор цели после диалога.
function Gossip.RestoreSoftTarget()
    if not Gossip.softTargetStored then
        return
    end
    if InCombatLockdown() then
        return
    end
    SetCVar("SoftTargetEnemy", Gossip.savedSoftTargetEnemy)
    SetCVar("SoftTargetFriend", Gossip.savedSoftTargetFriend)
    Gossip.softTargetStored = false
end
