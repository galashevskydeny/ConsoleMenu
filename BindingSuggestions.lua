-- BindingSuggestions.lua
local ConsoleMenu = _G.ConsoleMenu
ConsoleMenu.ActionInfo = {}

function ConsoleMenu:InitActionInfoFrame()
    if not self.ActionInfoFrame then
        self.ActionInfoFrame = CreateFrame("Frame")
    end
    
    self.ActionInfoFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.ActionInfoFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    self.ActionInfoFrame:RegisterEvent("UPDATE_BINDINGS")
    self.ActionInfoFrame:RegisterEvent("GAME_PAD_ACTIVE_CHANGED")
    self.ActionInfoFrame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
    self.ActionInfoFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")

    self.ActionInfoFrame:SetScript("OnEvent", function(frame, event, ...)
        if not ConsoleMenu or not ConsoleMenu.UpdateActionInfo then
            return
        end
        
        ConsoleMenu:UpdateActionInfo()
    end)
end
--
function ConsoleMenu:UpdateActionInfo()
    ConsoleMenu.ActionInfo = {}

    for slot = 1, 139 do
        local actionType, id = GetActionInfo(slot)
        
        if actionType and id then
            local key = actionType .. "_" .. id
            if not ConsoleMenu.ActionInfo[key] then
                ConsoleMenu.ActionInfo[key] = {
                    actionType = actionType,
                    id = id,
                    slots = {}, -- Храним все слоты, где находится это действие
                }
            end
            -- Добавляем слот в список
            table.insert(ConsoleMenu.ActionInfo[key].slots, slot)
        end
    end
end

--
function ConsoleMenu:GetBindingCommandBySlotID(slotID)
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
        [3] = "MULTIACTIONBAR3BUTTON%d",
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

    local toggles = { GetActionBarToggles() }

    if not toggles[barID] and barID == GetActionBarPage() then
        bindingFormat = "ACTIONBUTTON%d"
    end

    return bindingFormat:format(buttonID)
end

--  Функция получения кнопки по идентификатору заклинания
function ConsoleMenu:GetBinding(actionType, id)
    local entry = ConsoleMenu.ActionInfo[actionType .. "_" .. id]
    if entry and entry.slots and #entry.slots > 0 then
        local currentPage = GetActionBarPage()
        local NUM_ACTIONBAR_BUTTONS = 12
        
        -- Сначала пытаемся найти слот на текущей странице (для слотов 1-48)
        for _, slot in ipairs(entry.slots) do
            if slot >= 1 and slot <= 48 then
                local slotPage = math.ceil(slot / NUM_ACTIONBAR_BUTTONS)
                if slotPage == currentPage then
                    local bindingCommand = self:GetBindingCommandBySlotID(slot)
                    if bindingCommand then
                        local key1, key2 = GetBindingKey(bindingCommand)
                        return key1
                    end
                end
            end
        end
        
        -- Если не нашли на текущей странице, пробуем найти на любой странице
        -- (для MULTIACTIONBAR и других постоянных баров, или если действие не на текущей странице)
        for _, slot in ipairs(entry.slots) do
            local bindingCommand = self:GetBindingCommandBySlotID(slot)
            if bindingCommand then
                local key1, key2 = GetBindingKey(bindingCommand)
                if key1 then
                    return key1
                end
            end
        end
    end
    return nil
end

--  Функция получения кнопки по идентификатору бинда
function ConsoleMenu:GetCommandBinding(bindingCommand)

    if bindingCommand then
        local key1, key2 = GetBindingKey(bindingCommand)

        return key1
    end

    return nil
    
end

--
function ConsoleMenu:FindMacroIndexByName(macroName)
    local totalMacros = GetNumMacros()
    for i = 1, totalMacros do
        local name = GetMacroInfo(i)
        if name == macroName then
            return i
        end
    end
    return nil
end

--
function ConsoleMenu:SetStyle(aura_env, binding)
    local width = 32
    local height = 32
    local padding = 0
    local offset = 0
    
    if binding ~= nil and binding:match("%-") then
        width = 116
        height = 56
        padding = 4
        offset = 12

        aura_env.region.xOffset = 8
        
        local newTexture = ConsoleMenu.Textures["PAIRBUTTON"]

        if aura_env.region.texture and aura_env.region.bar == nil then
            aura_env.region.texture:SetTexture(newTexture)
        end
        
        aura_env.region.subRegions[4]:SetVisible(true)
        
        local key1, key2 = string.match(binding, "([^%-]+)%-(.+)")
        
        if #C_GamePad.GetAllDeviceIDs() > 1 then
            if key1 == "SHIFT" then
                key1 = GetCVar("GamePadEmulateShift")
            elseif key1 == "CTRL" then
                key1 = GetCVar("GamePadEmulateCtrl")
            elseif key1 == "ALT" then
                key1 = GetCVar("GamePadEmulateAlt")
            end
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
    else
        width = 32
        height = 32

        local newTexture = ConsoleMenu.Textures["EMPTY"]

        aura_env.region.subRegions[4]:SetVisible(false)
        aura_env.region.subRegions[3]:SetVisible(false)
        aura_env.region.subRegions[5]:SetVisible(false)

        if newTexture and aura_env.region and aura_env.region.texture then
            aura_env.region.texture:SetTexture(newTexture)
        end
    end

    aura_env.region.width = width
    aura_env.region.height = height

    aura_env.region:SetWidth(width)
    aura_env.region:SetHeight(height)
    aura_env.region:SetXOffset(offset)

    if aura_env.region.relativeTo then
        aura_env.region.relativeTo.regionData.data.width = width
        aura_env.region.relativeTo.regionData.data.height = height + padding
    end
end

--
function ConsoleMenu:SetProgressBarStyle(aura_env, binding)
    local width = 116
    local height = 56
    local padding = 0
    local offset = 0

    local newTexture = ConsoleMenu.Textures["PAIRBUTTON"]

    if aura_env.region.bar == nil then
        aura_env.region.bar:SetStatusBarTexture(newTexture)
    end
    
    if binding ~= nil and binding:match("%-") then
        
        aura_env.region.subRegions[5]:SetVisible(true)
        
        local key1, key2 = string.match(binding, "([^%-]+)%-(.+)")
        
        if #C_GamePad.GetAllDeviceIDs() > 1 then
            if key1 == "SHIFT" then
                key1 = GetCVar("GamePadEmulateShift")
            elseif key1 == "CTRL" then
                key1 = GetCVar("GamePadEmulateCtrl")
            elseif key1 == "ALT" then
                key1 = GetCVar("GamePadEmulateAlt")
            end
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
        aura_env.region:SetXOffset(offset)

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

-- Функция обновления ауры (тип текстура) с заклинанием
function ConsoleMenu:UpdateSpellTexture(aura_env, source)
    local binding

    local spell = source or aura_env.state.spellName or aura_env.state.name

    if spell ~= nil and tonumber(spell) then
        binding = self:GetBinding("spell", spell)
    elseif spell ~= nil then
        spellInfo = C_Spell.GetSpellInfo(spell)
        binding = self:GetBinding("spell", spellInfo.spellID)
    end

    self:SetStyle(aura_env, binding)
    
end

-- Функция обновления ауры (тип полоса прогресса) с заклинанием
function ConsoleMenu:UpdateSpellBarTexture(aura_env, spell)
    local binding

    if spell ~= nil and tonumber(spell) then
        binding = self:GetBinding("spell", spell)
    elseif spell ~= nil then
        local spellInfo = C_Spell.GetSpellInfo(spell)
        if spellInfo and spellInfo.spellID then
            binding = self:GetBinding("spell", spellInfo.spellID)
        end
    end

    self:SetProgressBarStyle(aura_env, binding)
end

-- Функция обновления ауры (тип текстура) с макросом    
function ConsoleMenu:UpdateMacroTexture(aura_env, macroName)
    local binding

    local macroIndex = self:FindMacroIndexByName(macroName)

    if macroIndex then
        binding = self:GetBinding("macro", macroIndex)
    end

    self:SetStyle(aura_env, binding)
end

-- Функция обновления ауры (тип текстура) с командой привязки клавиш    
function ConsoleMenu:UpdateCommandTexture(aura_env, command)
    local binding

    if command then
        local keys = { GetBindingKey(command) }

        if #C_GamePad.GetAllDeviceIDs() > 1 and #keys > 2 then
            table.sort(keys, function(a, b) return #(a or "") < #(b or "") end)
        end

        binding = keys[1]
    end

    self:SetStyle(aura_env, binding)
end

