local ConsoleMenu = _G.ConsoleMenu

function ConsoleMenu:RegisterAssets()
    -- Фоны кнопок
    ConsoleMenu.Backgrounds = {
        PAD = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\key-background.png",
        SHOULDER = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\shoulder-background.png",
        TRIGGER = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\trigger-background.png",
        STICK = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\stick-background.png",
        KEY = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\key-background.png",
        TOUCH = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\touch-background.png",
        PAIR = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\pairButtonTexture.png",
    }

    -- Текстуры кнопок
    ConsoleMenu.Textures = {
        PADDUP       = {
            texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\outline-top.png",
            background = "",
        },
        PADDRIGHT    = {
            texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\outline-right.png",
            background = "",
        },
        PADDDOWN     = {
            texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\outline-bottom.png",
            background = "",
        },
        PADDLEFT     = {
            texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\outline-left.png",
            background = "",
        },
        PAD1         = {
            texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\plain-cross.png",
            background = ConsoleMenu.Backgrounds["PAD"],
        },
        PAD2         = {
            texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\plain-circle.png",
            background = ConsoleMenu.Backgrounds["PAD"],
        },
        PAD3         = {
            texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\plain-square.png",
            background = ConsoleMenu.Backgrounds["PAD"],
        },
        PAD4         = {
            texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\plain-triangle.png",
            background = ConsoleMenu.Backgrounds["PAD"],
        },
        PAD5         = {
            texture = "",
            background = "",
        },
        PAD6         = {
            texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\TouchRight.png",
            background = ConsoleMenu.Backgrounds["TOUCH"],
        },
        PADLSHOULDER = {
            texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\plain-L1.png",
            background = ConsoleMenu.Backgrounds["SHOULDER"],
        },
        PADLTRIGGER  = {
            texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\plain-L2.png",
            background = ConsoleMenu.Backgrounds["TRIGGER"],
        },
        PADRSHOULDER = {
            texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\plain-R1.png",
            background = ConsoleMenu.Backgrounds["SHOULDER"],
        },
        PADRTRIGGER  = {
            texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\plain-R2.png",
            background = ConsoleMenu.Backgrounds["TRIGGER"],
        },
        PADLSTICK    = {
            texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\L3 press.png",
            background = ConsoleMenu.Backgrounds["STICK"],
        },
        PADRSTICK    = {
            texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\R3 press.png",
            background = ConsoleMenu.Backgrounds["STICK"],
        },
        PADLSTICKUP  = {
            texture = "",
            background = "",
        },
        PADLSTICKRIGHT = {
            texture = "",
            background = "",
        },
        PADLSTICKDOWN  = {
            texture = "",
            background = "",
        },
        PADLSTICKLEFT  = {
            texture = "",
            background = "",
        },
        PADRSTICKUP    = {
            texture = "",
            background = "",
        },
        PADRSTICKRIGHT = {
            texture = "",
            background = "",
        },
        PADRSTICKDOWN  = {
            texture = "",
            background = "",
        },
        PADRSTICKLEFT  = {
            texture = "",
            background = "",
        },
        PADPADDLE1   = {
            texture = "",
            background = "",
        },
        PADPADDLE2   = {
            texture = "",
            background = "",
        },
        PADPADDLE3   = {
            texture = "",
            background = "",
        },
        PADPADDLE4   = {
            texture = "",
            background = "",
        },
        PADFORWARD   = {
            texture = "",
            background = "",
        },
        PADBACK      = {
            texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\TouchLeft.png",
            background = ConsoleMenu.Backgrounds["TOUCH"],
        },
        PADSYSTEM    = {
            texture = "",
            background = "",
        },
        PADSOCIAL    = {
            texture = "",
            background = "",
        },
        SHIFT        = {
            texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\SHIFT.png",
            background = ConsoleMenu.Backgrounds["KEY"],
        },
        CTRL         = {
            texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\CTRL.png",
            background = ConsoleMenu.Backgrounds["KEY"],
        },
        SPACE        = {
            texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\SPACE.png",
            background = ConsoleMenu.Backgrounds["KEY"],
        },
        PADDLEFTRIGHT = {
            texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\outline-left-right.png",
            background = "",
        },
    }

    local equal = string.char(61)
    ConsoleMenu.Textures[equal] = {
        texture = "",
        background = ConsoleMenu.Backgrounds["KEY"]
    }
    
    local minus = string.char(45)
    ConsoleMenu.Textures[minus] = {
        texture = "",
        background = ConsoleMenu.Backgrounds["KEY"]
    }

    for i = 65, 90 do -- ASCII коды A (65) до Z (90)
        local letter = string.char(i)
        ConsoleMenu.Textures[letter] = {
            texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\" .. letter .. ".png",
            background = ConsoleMenu.Backgrounds["KEY"]
        }
    end

    for i = 48, 57 do -- ASCII коды 0 (48) до 9 (57)
        local digit = string.char(i)
        ConsoleMenu.Textures[digit] = {
            texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\" .. digit .. ".png",
            background = ConsoleMenu.Backgrounds["KEY"]
        }
        ConsoleMenu.Textures["NUMPAD" .. digit] = {
            texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\" .. digit .. ".png",
            background = ConsoleMenu.Backgrounds["KEY"]
        }
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