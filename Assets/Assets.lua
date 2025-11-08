local ConsoleMenu = _G.ConsoleMenu

function ConsoleMenu:RegisterAssets()
    -- Текстуры кнопок
    ConsoleMenu.Textures = {
        PADDUP       = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\outline-top.png",
        PADDRIGHT    = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\outline-right.png",
        PADDDOWN     = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\outline-bottom.png",
        PADDLEFT     = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\outline-left.png",
        PAD1         = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\plain-cross.png",
        PAD2         = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\plain-circle.png",
        PAD3         = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\plain-square.png",
        PAD4         = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\plain-triangle.png",
        PAD5         = "",
        PAD6         = "",
        PADLSHOULDER = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\plain-L1.png",
        PADLTRIGGER  = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\plain-L2.png",
        PADRSHOULDER = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\plain-R1.png",
        PADRTRIGGER  = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\plain-R2.png",
        PADLSTICK    = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\L3 press.png",
        PADRSTICK    = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\R3 press.png",
        PADLSTICKUP  = "",
        PADLSTICKRIGHT = "",
        PADLSTICKDOWN  = "",
        PADLSTICKLEFT  = "",
        PADRSTICKUP    = "",
        PADRSTICKRIGHT = "",
        PADRSTICKDOWN  = "",
        PADRSTICKLEFT  = "",
        PADPADDLE1   = "",
        PADPADDLE2   = "",
        PADPADDLE3   = "",
        PADPADDLE4   = "",
        PADFORWARD   = "",
        PADBACK      = "",
        PADSYSTEM    = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\",
        PADSOCIAL    = "",
        PAIRBUTTON   = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\pairButtonTexture.png",
        SHIFT        = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\SHIFT.png",
        CTRL         = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\CTRL.png",
        SPACE        = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\SPACE.png",
        EMPTY        = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\plain.png"
    }

    for i = 65, 90 do -- ASCII коды A (65) до Z (90)
        local letter = string.char(i)
        ConsoleMenu.Textures[letter] = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\" .. letter .. ".png"
    end

    for i = 48, 57 do -- ASCII коды 0 (48) до 9 (57)
        local digit = string.char(i)
        ConsoleMenu.Textures[digit] = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\" .. digit .. ".png"
        ConsoleMenu.Textures["NUMPAD" .. digit] = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\" .. digit .. ".png"

    end

    -- Регистрация текстур в LibSharedMedia (если доступна)
    local LibSharedMedia = LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true)
    if LibSharedMedia then
        LibSharedMedia:Register("statusbar", "EnemyHealthBar", [[Interface\AddOns\ConsoleMenu\Assets\EnemyHealthBar.png]])
        LibSharedMedia:Register("statusbar", "HealthBar", [[Interface\AddOns\ConsoleMenu\Assets\HealthBar.png]])
        LibSharedMedia:Register("statusbar", "BossHealthBar", [[Interface\AddOns\ConsoleMenu\Assets\BossHealthBar.png]])
        LibSharedMedia:Register("statusbar", "FourBar", [[Interface\AddOns\ConsoleMenu\Assets\FourBar.png]])
        LibSharedMedia:Register("statusbar", "FiveBar", [[Interface\AddOns\ConsoleMenu\Assets\FiveBar.png]])
        LibSharedMedia:Register("statusbar", "SixBar", [[Interface\AddOns\ConsoleMenu\Assets\SixBar.png]])
        LibSharedMedia:Register("statusbar", "SevenBar", [[Interface\AddOns\ConsoleMenu\Assets\SevenBar.png]])
        LibSharedMedia:Register("statusbar", "GroupIcon2", [[Interface\AddOns\ConsoleMenu\Assets\GroupIcon2.png]])
        LibSharedMedia:Register("statusbar", "GroupIcon3", [[Interface\AddOns\ConsoleMenu\Assets\GroupIcon3.png]])
        LibSharedMedia:Register("statusbar", "GroupIcon3Line", [[Interface\AddOns\ConsoleMenu\Assets\GroupIcon3Line.png]])
        LibSharedMedia:Register("statusbar", "DpsCounter", [[Interface\AddOns\ConsoleMenu\Assets\DpsCounter.png]])
        LibSharedMedia:Register("statusbar", "Power_Item", [[Interface\AddOns\ConsoleMenu\Assets\Power_Item.png]])
    end  
end