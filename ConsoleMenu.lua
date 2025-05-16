-- ConsoleMenu.lua

local addonName, ConsoleMenu = ...

ConsoleMenu = LibStub("AceAddon-3.0"):NewAddon("ConsoleMenu", "AceConsole-3.0")
_G[addonName] = ConsoleMenu -- Делаем аддон доступным глобально

function ConsoleMenu:OnInitialize()
    local LibSharedMedia = LibStub:GetLibrary ("LibSharedMedia-3.0")
    LibSharedMedia:Register ("statusbar", "healthbar", [[Interface\AddOns\ConsoleMenu\Assets\manabar.tga]])
    LibSharedMedia:Register ("statusbar", "healthbar2", [[Interface\AddOns\ConsoleMenu\Assets\healthPlate.tga]])

    LibSharedMedia:Register ("statusbar", "HealthBar", [[Interface\AddOns\ConsoleMenu\Assets\HealthBar.png]])
    LibSharedMedia:Register ("statusbar", "ManaBar_Mage_Arcane", [[Interface\AddOns\ConsoleMenu\Assets\ManaBar_Mage_Arcane.png]])

    LibSharedMedia:Register ("statusbar", "GroupIcon2", [[Interface\AddOns\ConsoleMenu\Assets\GroupIcon2.png]])
    LibSharedMedia:Register ("statusbar", "GroupIcon3", [[Interface\AddOns\ConsoleMenu\Assets\GroupIcon3.png]])
    LibSharedMedia:Register ("statusbar", "DpsCounter", [[Interface\AddOns\ConsoleMenu\Assets\DpsCounter.png]])
    LibSharedMedia:Register ("statusbar", "Power_Item", [[Interface\AddOns\ConsoleMenu\Assets\Power_Item.png]])

    self:SetCharacterFrame()
    self:SetPaperDollFrame()
    self:SetReputationFrame()
    self:SetTokenFrame()
    self:SetMailFrame()
    self:SetMerchantFrame()
    self:SetOpenMailFrame()
    self:SetQuestFrame()
    self:SetGossipFrame()
    self:SetPVEFrame()
    --self:SetWorldMapFrame()
    
    self:SetCustomGossipFrame()
    self:SetFastTravelFrame()

end

--  Функция получения кнопки по идентификатору заклинания
function ConsoleMenu:GetSpellBinding(spellID)
    local slots = C_ActionBar.FindSpellActionButtons(spellID)
    local function GetBindingCommandBySlotID(slotID)
        local NUM_ACTIONBAR_BUTTONS = 12

        local abnormal = {
            [133] = "ACTIONBUTTON1",
            [134] = "ACTIONBUTTON2",
            [135] = "ACTIONBUTTON3",
            [136] = "ACTIONBUTTON4",
            [137] = "ACTIONBUTTON5",
            [138] = "ACTIONBUTTON6",
            [139] = "EXTRAACTIONBUTTON1", -- только если CPAPI.ExtraActionButtonID == 139
        }

        -- Приоритет: абнормальные ID
        if abnormal[slotID] then
            return abnormal[slotID]
        end

        local barID = math.ceil(slotID / NUM_ACTIONBAR_BUTTONS)
        local buttonID = (slotID - 1) % NUM_ACTIONBAR_BUTTONS + 1

        local barBindings = {
            [1] = "ACTIONBUTTON%d",
            [6] = "MULTIACTIONBAR1BUTTON%d",
            [5] = "MULTIACTIONBAR2BUTTON%d",
            [4] = "MULTIACTIONBAR3BUTTON%d",
            [4] = "MULTIACTIONBAR4BUTTON%d",
            [13] = "MULTIACTIONBAR5BUTTON%d",
            [14] = "MULTIACTIONBAR6BUTTON%d",
            [15] = "MULTIACTIONBAR7BUTTON%d",
        }

        -- Сопоставим barID по порядку:
        local bindingFormat
        if barBindings[barID] then
            bindingFormat = barBindings[barID]
        elseif barID >= 6 and barID <= 12 then
            -- Относятся к основной панели (pages 6–12 → ACTIONBUTTON)
            bindingFormat = "ACTIONBUTTON%d"
        else
            -- fallback на default
            bindingFormat = "ACTIONBUTTON%d"
        end

        return bindingFormat:format(buttonID)
    end
    
    if slots then
        for _, item in ipairs(slots) do
            local bindingCommand = GetBindingCommandBySlotID(item)
            if bindingCommand then
                local key1, key2 = GetBindingKey(bindingCommand)

                return key1
            end
        end
    end

    return nil
    
end

--  Функция получения кнопки по идентификатору бинда
function ConsoleMenu:GetBinding(bindingCommand)

    if bindingCommand then
        local key1, key2 = GetBindingKey(bindingCommand)

        return key1
    end

    return nil
    
end

--
function ConsoleMenu:UpdateSpellTexture(aura_env)
    local binding

    local spell = aura_env.state.spellName or aura_env.state.name

    if spell ~= nil and tonumber(spell) then
        binding = self:GetSpellBinding(spell)
    elseif spell ~= nil then
        spellInfo = C_Spell.GetSpellInfo(spell)
        binding = self:GetSpellBinding(spellInfo.spellID)
        print(binding)
    end

    local width = 32
    local height = 32
    
    if binding ~= nil and binding:match("%-") then
        width = 116
        height = 56
        
        local newTexture = ConsoleMenu.Textures["PAIRBUTTON"]

        if aura_env.region.texture and aura_env.region.bar == nil then
            aura_env.region.texture:SetTexture(newTexture)
        end
        
        aura_env.region.subRegions[4]:SetVisible(true)
        
        local key1, key2 = string.match(binding, "([^%-]+)%-(.+)")
        
        if key1 == "SHIFT" then
            key1 = GetCVar("GamePadEmulateShift")
        elseif key1 == "CTRL" then
            key1 = GetCVar("GamePadEmulateCtrl")
        elseif key1 == "ALT" then
            key1 = GetCVar("GamePadEmulateAlt")
        end
        
        local texture1 = ConsoleMenu.Textures[key1]
        local texture2 = ConsoleMenu.Textures[key2]
        
        if texture1 and aura_env.region.subRegions[3] then
            aura_env.region.subRegions[3].texture:SetTexture(texture1)
            aura_env.region.subRegions[3]:SetVisible(true)
        end
        
        if texture2 and aura_env.region.subRegions[5] then
            aura_env.region.subRegions[5].texture:SetTexture(texture2)
            aura_env.region.subRegions[5]:SetVisible(true)
        end
        
    elseif binding ~= nil then
        width = 32
        height = 32

        aura_env.region.subRegions[4]:SetVisible(false)
        aura_env.region.subRegions[3]:SetVisible(false)
        aura_env.region.subRegions[5]:SetVisible(false)

        local newTexture = ConsoleMenu.Textures[binding]
        
        if newTexture and aura_env.region and aura_env.region.texture then
            aura_env.region.texture:SetTexture(newTexture)
        end
    end

    aura_env.region.width = width
    aura_env.region.height = height

    if aura_env.region.relativeTo then
        aura_env.region.relativeTo.regionData.data.width = width
        aura_env.region.relativeTo.regionData.data.height = height
    end
end

--
function ConsoleMenu:UpdateSpellBarTexture(aura_env, spell)
    local binding

    if spell ~= nil and tonumber(spell) then
        binding = self:GetSpellBinding(spell)
    elseif spell ~= nil then
        spellInfo = C_Spell.GetSpellInfo(spell)
        binding = self:GetSpellBinding(spellInfo.spellID)
        print(binding)
    end

    local width = 116
    local height = 56

    local newTexture = ConsoleMenu.Textures["PAIRBUTTON"]

    if aura_env.region.bar == nil then
        aura_env.region.bar:SetStatusBarTexture(newTexture)
    end
    
    if binding ~= nil and binding:match("%-") then
        
        aura_env.region.subRegions[5]:SetVisible(true)
        
        local key1, key2 = string.match(binding, "([^%-]+)%-(.+)")
        
        if key1 == "SHIFT" then
            key1 = GetCVar("GamePadEmulateShift")
        elseif key1 == "CTRL" then
            key1 = GetCVar("GamePadEmulateCtrl")
        elseif key1 == "ALT" then
            key1 = GetCVar("GamePadEmulateAlt")
        end
        
        local texture1 = ConsoleMenu.Textures[key1]
        local texture2 = ConsoleMenu.Textures[key2]
        
        if texture1 and aura_env.region.subRegions[4] then
            aura_env.region.subRegions[4].texture:SetTexture(texture1)
            aura_env.region.subRegions[4]:SetVisible(true)
        end
        
        if texture2 and aura_env.region.subRegions[6] then
            aura_env.region.subRegions[6].texture:SetTexture(texture2)
            aura_env.region.subRegions[6]:SetVisible(true)
        end
        
    elseif binding ~= nil then

        aura_env.region.subRegions[5]:SetVisible(false)
        aura_env.region.subRegions[4]:SetVisible(false)

        local newTexture = ConsoleMenu.Textures[binding]

        if newTexture and aura_env.region.subRegions[6] then
            aura_env.region.subRegions[6].texture:SetTexture(newTexture)
            aura_env.region.subRegions[6]:SetVisible(true)
        end
        
    end

    aura_env.region.width = width
    aura_env.region.height = height

    if aura_env.region.relativeTo then
        aura_env.region.relativeTo.regionData.data.width = width
        aura_env.region.relativeTo.regionData.data.height = height
    end
end

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
}