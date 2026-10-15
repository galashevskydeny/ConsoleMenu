-- Полёт кружка умения: сжатие до ребра, подъём, наклон и смена стороны.

local ConsoleMenu = _G.ConsoleMenu

-- Показ стороны и обновление остального содержимого. Их задаёт сама кнопка.
local showSide
local refreshRest

-- Кнопки, которые сейчас в воздухе, и общий ход для них.
local flipping = {}
local flipDriver

-- Запоминает показ стороны и обновление содержимого кнопки.
function ConsoleMenu:BindModelFlight(show, refresh)
    showSide = show
    refreshRest = refresh
end

-- Возвращает панель команд в момент полёта. При загрузке этого файла панели ещё нет.
local function Bar()
    return ConsoleMenu.ActionBar
end

-- Крутит рисунок, если клиент это умеет.
local function SetPieceRotation(piece, angle)
    if piece and piece.SetRotation then
        piece:SetRotation(angle or 0)
    end
end

-- Красит рисунок и наклоняет его на текущий шаг полёта.
local function PaintPiece(texture, shade, axis)
    if not texture then
        return
    end
    texture:SetVertexColor(shade, shade, shade)
    SetPieceRotation(texture, axis)
end

-- Возвращает кружок на обычное место после подброса.
local function SeatAbility(btn)
    local bar = Bar()
    local ability = btn.Ability
    local icon = btn.IconFrame
    if not ability or not icon or not bar then
        return
    end
    if bar.slot12Slots and bar.slot12Slots[btn.slotID] and bar.PlaceSlot12Icon then
        bar.PlaceSlot12Icon(btn)
    else
        ability:ClearAllPoints()
        ability:SetPoint("CENTER", btn, "CENTER", 0, 0)
        ability:SetSize(bar.buttonSize, bar.buttonSize)
    end
    icon:ClearAllPoints()
    icon:SetSize(bar.buttonSize, bar.buttonSize)
    icon:SetPoint("CENTER", ability, "CENTER", 0, 0)
    SetPieceRotation(btn.Front and btn.Front.texture, 0)
    SetPieceRotation(btn.Back and btn.Back.texture, 0)
    SetPieceRotation(icon.background, 0)
    if btn.Front then
        btn.Front.texture:SetVertexColor(1, 1, 1)
    end
    if btn.Back then
        btn.Back.texture:SetVertexColor(1, 1, 1)
    end
end

-- Подброс: сжимает кружок до ребра и приподнимает его.
-- Возвращает истину, когда уже видна новая сторона.
local function ApplyToss(btn, amount, tilt)
    local bar = Bar()
    local ability = btn.Ability
    local icon = btn.IconFrame
    if not ability or not icon or not bar then
        return false
    end
    local size = bar.buttonSize
    local turns = bar.boostCoinTurns or 1
    if turns < 1 then
        turns = 1
    end
    local edge = bar.boostFlipEdge or 0.07
    local thin = 1
    local axis = 0
    local slide = 0
    local lift = 0
    local shade = 1
    local scale = 1
    local showAlt = amount >= 1

    if amount > 0 and amount < 1 then
        local rise = amount ^ 0.62
        local hop = math.sin(rise * math.pi)
        local spun = amount * amount * (3 - 2 * amount)
        local spin = spun * turns * math.pi
        thin = math.abs(math.cos(spin))
        if thin < edge then
            thin = edge
        end
        showAlt = math.cos(spin) < 0
        local tiltAmount = tilt or 0.7
        local direction = tiltAmount >= 0 and 1 or -1
        axis = tiltAmount * hop * 0.85
        slide = math.sin(amount * math.pi) * direction * (bar.boostFlipNudge or 6)
        lift = hop * (bar.boostFlipLift or 26)
        scale = 1 + hop * 0.12
        shade = 0.35 + 0.65 * thin
    end

    local height = size * scale
    local width = height * thin
    if width < 0.01 then
        width = 0.01
    end
    ability:ClearAllPoints()
    ability:SetSize(width, height)
    local wide = bar.slot12Slots and bar.slot12Slots[btn.slotID]
    if wide then
        ability:SetPoint("LEFT", btn, "LEFT", (bar.slot12IconPadding or 0) + 4 + slide, lift)
    else
        ability:SetPoint("CENTER", btn, "CENTER", slide, lift)
    end
    PaintPiece(btn.Front and btn.Front.texture, shade, axis)
    PaintPiece(btn.Back and btn.Back.texture, shade, axis)
    PaintPiece(icon.background, shade, axis)
    icon:ClearAllPoints()
    icon:SetSize(width, height)
    icon:SetPoint("CENTER", ability, "CENTER", 0, 0)
    return showAlt
end

-- Останавливает общий ход, когда ни одна кнопка больше не в воздухе.
local function StopFlipDriverIfIdle()
    if not flipDriver then
        return
    end
    for index = 1, #flipping do
        if flipping[index].flipBusy then
            return
        end
    end
    flipDriver:Hide()
end

-- Снимает кнопку из списка хода.
local function ForgetFlip(btn)
    for index = #flipping, 1, -1 do
        if flipping[index] == btn then
            table.remove(flipping, index)
        end
    end
end

-- Показывает переднюю или оборотную сторону, если кнопка отдала этот показ.
local function RevealSide(btn, face, slotID, texture)
    if showSide and face then
        showSide(btn, face, slotID, texture)
    end
end

-- Шаг подброса всех кнопок, которые сейчас в воздухе.
local function StepFlips(_, elapsed)
    local bar = Bar()
    for index = #flipping, 1, -1 do
        local btn = flipping[index]
        if btn.flipBusy then
            btn.flipElapsed = (btn.flipElapsed or 0) + (elapsed or 0)
            local duration = btn.flipDuration or 0.2
            local amount = duration > 0 and btn.flipElapsed / duration or 1
            if amount >= 1 then
                amount = 1
            end
            local wasReady = btn.coinTimerReady and true or false
            local showAlt = ApplyToss(btn, amount, btn.flipTilt)
            if showAlt then
                RevealSide(btn, btn.Back, btn.flipTargetSlot, btn.flipTargetTexture)
            else
                RevealSide(btn, btn.Front, btn.flipFromSlot or btn.slotID, btn.flipFromTexture)
            end
            ApplyToss(btn, amount, btn.flipTilt)
            btn.coinTimerReady = showAlt and true or nil
            local readyNow = btn.coinTimerReady and true or false
            if amount >= 1 then
                btn.flipBusy = false
                btn.coinInAir = nil
                btn.coinActive = nil
                btn.coinTimerReady = true
                SeatAbility(btn)
                RevealSide(btn, btn.Front, btn.flipTargetSlot or btn.slotID, btn.flipTargetTexture)
                if btn.Label and btn.slotID and bar and bar.UpdateSlot12Label then
                    bar.UpdateSlot12Label(btn.slotID)
                end
                table.remove(flipping, index)
                if refreshRest then
                    refreshRest(btn)
                end
            elseif readyNow ~= wasReady and refreshRest then
                refreshRest(btn)
            end
        else
            table.remove(flipping, index)
        end
    end
    StopFlipDriverIfIdle()
end

-- Общий ход подброса.
local function EnsureFlipDriver()
    if flipDriver then
        return flipDriver
    end
    flipDriver = CreateFrame("Frame")
    flipDriver:Hide()
    flipDriver:SetScript("OnUpdate", StepFlips)
    return flipDriver
end

-- Прерывает подброс и оставляет кнопку на месте.
function ConsoleMenu:StopModelFlight(btn)
    if not btn then
        return
    end
    ForgetFlip(btn)
    btn.flipBusy = false
    btn.coinInAir = nil
    btn.coinActive = nil
    btn.coinTimerReady = true
    SeatAbility(btn)
    StopFlipDriverIfIdle()
end

-- Начинает переворот с текущей стороны на новую.
function ConsoleMenu:StartModelFlight(btn, fromSlot, fromTexture, targetSlot, targetTexture)
    if not btn then
        return
    end
    local bar = Bar()
    ConsoleMenu:StopModelFlight(btn)
    btn.flipBusy = true
    btn.coinInAir = true
    btn.coinActive = true
    btn.coinTimerReady = nil
    btn.flipElapsed = 0
    btn.flipDuration = bar and bar.boostExpandDuration and bar.boostExpandDuration * 0.55 or 0.26
    btn.flipTilt = ((btn.slotID or 0) % 2 == 0) and 0.7 or -0.6
    btn.flipFromSlot = fromSlot
    btn.flipFromTexture = fromTexture
    btn.flipTargetSlot = targetSlot
    btn.flipTargetTexture = targetTexture
    if btn.IconFrame then
        ConsoleMenu:StopScaleAnimation(btn.IconFrame)
        btn.IconFrame:SetScale(1)
    end
    if fromTexture and btn.Front and btn.Front.texture then
        btn.Front.texture:SetTexture(fromTexture)
    end
    if targetTexture and btn.Back and btn.Back.texture then
        btn.Back.texture:SetTexture(targetTexture)
    end
    RevealSide(btn, btn.Front, fromSlot, fromTexture)
    if btn.HideGlow then
        btn:HideGlow()
    end
    if btn.HideShadow then
        btn:HideShadow(true)
    end
    flipping[#flipping + 1] = btn
    EnsureFlipDriver():Show()
end
