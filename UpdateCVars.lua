local ConsoleMenu = _G.ConsoleMenu

-- Скрывает текст боя (всплывающих цифр)
local function HideFloatingText()
    SetCVar("threatShowNumeric", 0)
    SetCVar("enableFloatingCombatText", 0)
    SetCVar("floatingCombatTextCombatDamage", 0)
end

-- Скрывает уведомления о входе/выходе членов гильдии из онлайна
local function HideGuildMemberNotification()
    SetCVar("guildMemberNotify", 0)
end

-- Скрывает облака с субтитрами над головой персонажей и игроков
local function HideChatBubble()
    SetCVar("chatBubbles", 0)
    SetCVar("chatBubblesParty", 0)
end

-- Скрывает выделение под квестодателем
local function HideQuestCircle()
    SetCVar("ShowQuestUnitCircles", "0")
    SetCVar("ObjectSelectionCircle", "0")
end

-- Устанавливает базовые для необходимого пользовательского опыта значения soft target
function ConsoleMenu:SetBaseSoftTargetSettings()
    SetCVar("SoftTargetFriend", 1)
    SetCVar("SoftTargetFriend", 1)
    SetCVar("SoftTargetNameplateEnemy", 1)
    SetCVar("SoftTargetIconInteract", 0)
    SetCVar("SoftTargetFriendRange", 5)
    SetCVar("SoftTargetForce", 0)

    -- Фокусировка на врагах только если персонаж не верхом
    if IsMounted() then
        SetCVar("SoftTargetEnemy", 0)
    else
        SetCVar("SoftTargetEnemy", 1)
    end
end

-- Устанавливает значения настроек soft target для боя
function ConsoleMenu:SetCombatSoftTargetSettings()
    SetCVar("SoftTargetEnemy", 1)
    SetCVar("SoftTargetForce", 0)
end

-- Устанавливает значения настроект soft target в зонах святилищах
function ConsoleMenu:SetSanctuarySoftTargetSettings()
    local pvpType, _, _ = C_PvP.GetZonePVPInfo()

    if pvpType == "sanctuary" then
        SetCVar("SoftTargetEnemy", 0)
    end
end

-- Устанавливает базовые для необходимого пользовательского опыта значения настроек отображения имен
local function SetBaseUnitNameSettings()
    SetCVar("nameplateShowSelf", 0)
    SetCVar("UnitNameEnemyGuardianName", 0)
    SetCVar("UnitNameEnemyMinionName", 0)
    SetCVar("UnitNameEnemyPetName", 0)
    SetCVar("UnitNameEnemyPlayerName", 0)
    SetCVar("UnitNameEnemyTotemName", 0)

    SetCVar("UnitNameFriendlyGuardianName", 0)
    SetCVar("UnitNameFriendlyMinionName", 0)
    SetCVar("UnitNameFriendlyPetName", 0)
    SetCVar("UnitNameFriendlyPlayerName", 0)
    SetCVar("UnitNameFriendlySpecialNPCName", 0)
    SetCVar("UnitNameFriendlyTotemName", 0)
    SetCVar("UnitNameGuildTitle", 0)
    SetCVar("UnitNameHostleNPC", 0)
    SetCVar("UnitNameInteractiveNPC", 0)
end

-- Устанаваливает базовые для необходимого пользовательского опыта значения различных игровых настроек 
local function SetBaseSettings()
    -- Автоматический сбор добычи
    SetCVar("autoLootDefault", 1)
    -- Автоматическое отслеживание квестов
    SetCVar("autoQuestWatch", 0)

    SetCVar("Sound_ZoneMusicNoDelay", 1)

    -- Скрытие отображения уроков в интерфейсе
    SetCVar("showTutorials", 0)
end

-- Устанавливает базовые для необходимого пользовательского опыта значения настроек графики
local function SetBaseGraphicsSettings()
    SetCVar("NotchedDisplayMode", 0)
    SetCVar("graphicsOutlineMode", 0)
    SetCVar("useMaxFPS", 0)
    SetCVar("useMaxFPSBk", 0)
    SetCVar("useTargetFPS", 0)
    SetCVar("Gamma", 0.9)
    SetCVar("Contrast", 80)
    SetCVar("Brightness", 65)
end


function ConsoleMenu:UpdateCVars()
    HideFloatingText()
    HideGuildMemberNotification()
    HideChatBubble()
    HideQuestCircle()
    self:SetBaseSoftTargetSettings()
    SetBaseUnitNameSettings()
    SetBaseSettings()
    SetBaseGraphicsSettings()
end