-- Группа кнопок: крест геймпада, общая тень и сдвиг от свечения.

local ConsoleMenu = _G.ConsoleMenu
local ActionBar = ConsoleMenu.ActionBar

-- Оси креста. Верх напротив низа, право напротив лева.
local groupAxes = {
    right = {
        { axis = "y", positive = "PAD4", negative = "PADRSTICK" },
        { axis = "x", positive = "PAD2", negative = "PAD3" },
    },
    left = {
        { axis = "y", positive = "PADDUP", negative = "PADDDOWN" },
        { axis = "x", positive = "PADDRIGHT", negative = "PADDLEFT" },
    },
}

-- Быстрый срыв с места и мягкая посадка. Скорость не остаётся ровной.
local function EaseWhoosh(progress)
    if progress <= 0 then
        return 0
    end
    if progress >= 1 then
        return 1
    end
    local rest = 1 - progress
    return 1 - rest * rest * rest * rest
end

-- Пока иконка переворачивается, новый сдвиг к ней не применяется.
local function PictureTurning(btn)
    return btn.flipBusy or btn.coinActive or btn.coinInAir or (btn.ctrlFlipOwned and not btn.ctrlFaceSettled)
end

-- Кнопка перечислена в таблице отображаемых кнопок группы.
local function ButtonListed(group, btn)
    local list = group.visibleButtons
    if not list or not btn then
        return false
    end
    for index = 1, #list do
        if list[index] == btn then
            return true
        end
    end
    return false
end

-- В группе горит свечение на кнопке, которую нужно показать.
local function GroupHasGlow(group)
    local list = group.visibleButtons
    if not list then
        return false
    end
    for index = 1, #list do
        if list[index].glowReady then
            return true
        end
    end
    return false
end

-- Место кнопки на кресте. Верх и право считаются положительными.
local function ButtonCrossSign(btn)
    local key = btn and btn.mainKey
    if key == "PAD4" or key == "PADDUP" then
        return 0, 1
    end
    if key == "PADRSTICK" or key == "PADDDOWN" then
        return 0, -1
    end
    if key == "PAD2" or key == "PADDRIGHT" then
        return 1, 0
    end
    if key == "PAD3" or key == "PADDLEFT" then
        return -1, 0
    end
    return 0, 0
end

-- Тянет кнопку к тёмной стороне сразу по вертикали и по горизонтали.
local function AddShiftToward(shiftX, shiftY, btn, oppositeX, oppositeY, distance)
    local buttonX, buttonY = ButtonCrossSign(btn)
    if oppositeX ~= buttonX then
        shiftX = shiftX + (oppositeX > buttonX and distance or -distance)
    end
    if oppositeY ~= buttonY then
        shiftY = shiftY + (oppositeY > buttonY and distance or -distance)
    end
    return shiftX, shiftY
end

-- Сторона оси светится на видимой кнопке группы.
local function PoleGlows(group, key)
    local buttons = group.buttons
    if not buttons or not key then
        return false
    end
    for index = 1, #buttons do
        local btn = buttons[index]
        if btn.mainKey == key and btn.glowReady and ButtonListed(group, btn) then
            return true
        end
    end
    return false
end

-- Кнопка записана в списке.
local function ListHas(list, btn)
    if not list or not btn then
        return false
    end
    for index = 1, #list do
        if list[index] == btn then
            return true
        end
    end
    return false
end

-- Вычёркивает кнопку из списка.
local function RemoveFromList(list, btn)
    if not list or not btn then
        return
    end
    for index = #list, 1, -1 do
        if list[index] == btn then
            table.remove(list, index)
        end
    end
end

-- Оставляет кнопку в расчёте сдвига, даже если её уже нет среди кнопок креста.
local function HoldForRelease(group, btn)
    btn.group = group
    btn.glowShiftRelease = true
    if ListHas(group.buttons, btn) then
        return
    end
    group.releasing = group.releasing or {}
    if not ListHas(group.releasing, btn) then
        group.releasing[#group.releasing + 1] = btn
    end
end

-- Снимает кнопку с доводки. Если она больше не в кресте, отвязывает группу.
local function ForgetRelease(group, btn)
    RemoveFromList(group.releasing, btn)
    if btn.group == group and not ListHas(group.buttons, btn) then
        btn.group = nil
    end
end

-- Цель сдвига. Скрываемая едет на штатное место, светящаяся остаётся, остальные тянутся к тёмной кнопке напротив.
local function ShiftTarget(group, btn)
    if btn.glowShiftRelease or not ButtonListed(group, btn) or btn.glowReady then
        return 0, 0
    end
    local distance = ActionBar.glowShiftSize or 0
    if distance < 0 then
        distance = 0
    end
    local shiftX, shiftY = 0, 0
    local axes = group.axes
    for index = 1, #axes do
        local axis = axes[index]
        local positiveGlows = PoleGlows(group, axis.positive)
        local negativeGlows = PoleGlows(group, axis.negative)
        local oppositeX, oppositeY = 0, 0
        local blocked = false
        if positiveGlows and not negativeGlows then
            blocked = btn.mainKey == axis.negative
            if axis.axis == "y" then
                oppositeY = -1
            else
                oppositeX = -1
            end
        elseif negativeGlows and not positiveGlows then
            blocked = btn.mainKey == axis.positive
            if axis.axis == "y" then
                oppositeY = 1
            else
                oppositeX = 1
            end
        end
        if (positiveGlows ~= negativeGlows) and not blocked then
            shiftX, shiftY = AddShiftToward(shiftX, shiftY, btn, oppositeX, oppositeY, distance)
        end
    end
    return shiftX, shiftY
end

-- Цель лежит на штатном месте раскладки.
local function TargetIsHome(shiftX, shiftY)
    return math.abs(shiftX or 0) < 0.05 and math.abs(shiftY or 0) < 0.05
end

-- Возврат на место короче скучивания.
local function ShiftDuration(home)
    local duration = home and ActionBar.glowHomeDuration or ActionBar.glowMotionDuration
    if not duration or duration < 0.01 then
        duration = home and 0.1 or 0.2
    end
    return duration
end

-- Точка на пути от текущего сдвига к цели.
local function ShiftOffset(origin, target, life)
    return (origin or 0) + ((target or 0) - (origin or 0)) * EaseWhoosh(life or 0)
end

-- Записывает сдвиг и ставит кнопку. Во время переворота положение не меняется.
local function CommitShift(btn, shiftX, shiftY)
    if PictureTurning(btn) then
        btn.glowShiftRestart = true
        return
    end
    btn.glowShiftX = shiftX
    btn.glowShiftY = shiftY
    if ActionBar.SeatButton then
        ActionBar.SeatButton(btn)
    end
end

-- Текущий сдвиг поверх раскладки, чтобы обновление места его не стёрло.
function ActionBar.ButtonGlowShift(btn)
    if not btn then
        return 0, 0
    end
    return btn.glowShiftX or 0, btn.glowShiftY or 0
end

-- Записывает нулевой сдвиг и ставит кнопку.
local function WipeShift(btn)
    btn.glowShiftRestart = nil
    btn.glowShiftRelease = nil
    btn.glowShiftOriginX = 0
    btn.glowShiftOriginY = 0
    btn.glowShiftTargetX = 0
    btn.glowShiftTargetY = 0
    btn.glowShiftLife = 1
    btn.glowShiftX = 0
    btn.glowShiftY = 0
    if ActionBar.SeatButton then
        ActionBar.SeatButton(btn)
    end
end

-- Снимает сдвиг через возврат кнопки на штатное место.
function ActionBar.ClearButtonShift(btn)
    if ActionBar.ReturnButtonHome then
        ActionBar.ReturnButtonHome(btn)
    end
end

-- Один шаг сдвига. Повтор к той же цели не начинает движение заново.
local function StepButtonShift(btn, shiftX, shiftY, elapsed)
    local life = btn.glowShiftLife
    local arrived = btn.glowShiftTargetX == shiftX and btn.glowShiftTargetY == shiftY and (life or 0) >= 1
    if not btn.glowShiftRestart and arrived then
        return false
    end

    local sameTarget = btn.glowShiftTargetX == shiftX and btn.glowShiftTargetY == shiftY
    local lifeNow = life or 0
    if btn.glowShiftRestart and sameTarget and lifeNow > 0 then
        btn.glowShiftRestart = nil
        if lifeNow >= 1 then
            CommitShift(btn, shiftX, shiftY)
            return false
        end
        local duration = ShiftDuration(TargetIsHome(shiftX, shiftY))
        btn.glowShiftLife = math.min(1, lifeNow + (elapsed or 0) / duration)
        CommitShift(
            btn,
            ShiftOffset(btn.glowShiftOriginX, shiftX, btn.glowShiftLife),
            ShiftOffset(btn.glowShiftOriginY, shiftY, btn.glowShiftLife)
        )
        return btn.glowShiftLife < 1
    end

    if btn.glowShiftRestart or not sameTarget then
        btn.glowShiftRestart = nil
        btn.glowShiftOriginX = btn.glowShiftX or 0
        btn.glowShiftOriginY = btn.glowShiftY or 0
        btn.glowShiftTargetX = shiftX
        btn.glowShiftTargetY = shiftY
        if math.abs(btn.glowShiftOriginX - shiftX) < 0.05 and math.abs(btn.glowShiftOriginY - shiftY) < 0.05 then
            btn.glowShiftLife = 1
            CommitShift(btn, shiftX, shiftY)
            return false
        end
        btn.glowShiftLife = 0
        return true
    end

    local duration = ShiftDuration(TargetIsHome(shiftX, shiftY))
    btn.glowShiftLife = math.min(1, (life or 0) + (elapsed or 0) / duration)
    CommitShift(
        btn,
        ShiftOffset(btn.glowShiftOriginX, shiftX, btn.glowShiftLife),
        ShiftOffset(btn.glowShiftOriginY, shiftY, btn.glowShiftLife)
    )
    return btn.glowShiftLife < 1
end

-- Ведёт один список кнопок. Скрываемая с нулевым сдвигом из доводки выбывает.
local function StepShiftList(group, list, elapsed, dropWhenHome)
    if not list then
        return false
    end
    local busy = false
    local index = 1
    while index <= #list do
        local btn = list[index]
        local drop = false
        if PictureTurning(btn) then
            btn.glowShiftRestart = true
            busy = true
        elseif btn.glowShiftRelease and not btn:IsShown() then
            WipeShift(btn)
            drop = true
        else
            local shiftX, shiftY = 0, 0
            if btn.glowShiftRelease or not group.shiftHome then
                shiftX, shiftY = ShiftTarget(group, btn)
            end
            if StepButtonShift(btn, shiftX, shiftY, elapsed) then
                busy = true
            elseif dropWhenHome and btn.glowShiftRelease then
                -- Доехала и в кресте её больше нет: дальше сдвиг группы её не тянет.
                btn.glowShiftRelease = nil
                drop = true
            end
        end
        if drop and dropWhenHome then
            if list[index] == btn then
                table.remove(list, index)
            end
            ForgetRelease(group, btn)
        else
            index = index + 1
        end
    end
    return busy
end

-- Ведёт сдвиг кнопок группы и засыпает, когда всем уже некуда ехать.
local function StepGroupShift(group, elapsed)
    local driver = group.shiftDriver
    if not driver then
        return
    end
    local busy = StepShiftList(group, group.buttons, elapsed, false)
    if StepShiftList(group, group.releasing, elapsed, true) then
        busy = true
    end
    if not busy then
        driver:Hide()
    end
end

-- Запускает ход сдвига, если он ещё не идёт.
local function WakeShift(group)
    if not group.shiftDriver then
        local driver = CreateFrame("Frame", nil, group)
        driver:Hide()
        driver:SetScript("OnUpdate", function(_, elapsed)
            StepGroupShift(group, elapsed)
        end)
        group.shiftDriver = driver
    end
    group.shiftDriver:Show()
end

-- Ставит кнопке целью её штатное место. Пока иконка переворачивается, положение не меняется.
function ActionBar.ReturnButtonHome(btn)
    if not btn then
        return
    end
    local group = btn.group
    if not group then
        WipeShift(btn)
        return
    end
    btn.glowShiftRelease = true
    if PictureTurning(btn) then
        btn.glowShiftRestart = true
        HoldForRelease(group, btn)
        WakeShift(group)
        return
    end
    if not btn:IsShown() then
        WipeShift(btn)
        ForgetRelease(group, btn)
        return
    end
    HoldForRelease(group, btn)
    WakeShift(group)
end

-- Возвращает тени обычный размер. Иначе после сжатия она остаётся точкой.
local function RestoreShadowSize(shadow)
    local home = ActionBar.shadowSize
    if not shadow or not home or home < 1 then
        return
    end
    if shadow.lastSize == home then
        return
    end
    shadow:SetSize(home, home)
    shadow.lastSize = home
end

-- Собирает тень группы. Повторный показ или скрытие в ту же сторону не перезапускает проявление.
local function CreateGroupShadow(group)
    local shadow = CreateFrame("Frame", nil, group)
    shadow:SetSize(ActionBar.shadowSize, ActionBar.shadowSize)
    shadow:SetPoint("CENTER", group, "CENTER", 0, 0)
    shadow:EnableMouse(false)
    shadow:SetAlpha(0)
    shadow:Hide()
    if shadow.SetClipsChildren then
        shadow:SetClipsChildren(false)
    end
    local texture = shadow:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints()
    texture:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png")
    ConsoleMenu:InitFadeAnimations(shadow, ActionBar.animationDuration)
    shadow.groupShown = false

    function shadow:ShowShadow()
        if self.groupShown then
            return
        end
        self.groupShown = true
        RestoreShadowSize(self)
        ConsoleMenu:AnimatedShow(self)
    end

    function shadow:HideShadow()
        if not self.groupShown then
            return
        end
        self.groupShown = false
        ConsoleMenu:AnimatedHide(self)
    end

    return shadow
end

-- Включает кнопки из таблицы. При свечении сначала сдвигает остальные.
local function ShowGroup(self)
    local list = self.visibleButtons
    if list and #list > 0 and self.shadow and self.shadow.ShowShadow then
        self.shadow:ShowShadow()
    end
    if GroupHasGlow(self) then
        self:Bunch()
    end
    if not list or not ActionBar.ShowButton then
        return
    end
    for index = 1, #list do
        ActionBar.ShowButton(list[index])
    end
end

-- Прячет кнопки группы, которых нет в таблице. Пустая таблица гасит тень.
local function HideGroup(self)
    local list = self.visibleButtons
    if (not list or #list == 0) and self.shadow and self.shadow.HideShadow then
        self.shadow:HideShadow()
    end
    local buttons = self.buttons
    if not buttons or not ActionBar.HideButton then
        return
    end
    for index = 1, #buttons do
        local btn = buttons[index]
        if not ButtonListed(self, btn) then
            ActionBar.HideButton(btn)
        end
    end
end

-- Обновляет указанную кнопку и заново считает сдвиг, если свечение изменилось.
local function UpdateGroup(self, btn, spellID)
    if btn and btn.Update then
        btn:Update(spellID)
    end
    self:RefreshShift()
end

-- Скучивает кнопки к тёмной кнопке напротив. Видимые снова могут ехать к ней.
local function Bunch(self)
    self.shiftHome = false
    local buttons = self.buttons
    if buttons then
        for index = 1, #buttons do
            local btn = buttons[index]
            if ButtonListed(self, btn) then
                btn.glowShiftRelease = nil
            end
        end
    end
    WakeShift(self)
end

-- Возвращает кнопки на штатные места: у каждой вызывает её собственный возврат.
local function ReturnHome(self)
    self.shiftHome = true
    local buttons = self.buttons
    if buttons then
        for index = #buttons, 1, -1 do
            local btn = buttons[index]
            if btn.ReturnHome then
                btn:ReturnHome()
            end
        end
    end
    local releasing = self.releasing
    if releasing then
        for index = #releasing, 1, -1 do
            local btn = releasing[index]
            if btn.ReturnHome then
                btn:ReturnHome()
            end
        end
    end
end

-- После свечения скучивает кнопки, а после его исчезновения возвращает их на места.
local function RefreshShift(self)
    if GroupHasGlow(self) then
        self:Bunch()
    else
        self:ReturnHome()
    end
end

-- Создаёт фрейм креста на месте прежней точки центра.
function ActionBar.CreateButtonGroup(parent, side)
    local group = CreateFrame("Frame", nil, parent)
    group:SetSize(1, 1)
    group:EnableMouse(false)
    if group.SetClipsChildren then
        group:SetClipsChildren(false)
    end
    if side == "right" then
        group:SetPoint("RIGHT", parent, "RIGHT", -(ActionBar.paddingPAD or 0), 0)
    else
        group:SetPoint("LEFT", parent, "LEFT", ActionBar.paddingPADD or 0, 0)
    end
    group.side = side
    group.axes = groupAxes[side] or groupAxes.left
    group.buttons = {}
    group.visibleButtons = {}
    group.releasing = {}
    group.shadow = CreateGroupShadow(group)
    group.ShowGroup = ShowGroup
    group.HideGroup = HideGroup
    group.UpdateGroup = UpdateGroup
    group.Bunch = Bunch
    group.ReturnHome = ReturnHome
    group.RefreshShift = RefreshShift
    group:Show()
    return group
end

-- Включает кнопку в группу и делает её дочерним фреймом.
function ActionBar.AttachGroupButton(group, btn)
    if not group or not btn or not group.buttons then
        return
    end
    btn.group = group
    btn.glowShiftRelease = nil
    RemoveFromList(group.releasing, btn)
    if btn:GetParent() ~= group then
        btn:SetParent(group)
    end
    local buttons = group.buttons
    for index = 1, #buttons do
        if buttons[index] == btn then
            return
        end
    end
    buttons[#buttons + 1] = btn
end

-- Убирает кнопку из креста, когда привязка рычага исчезла. Сдвиг доводится отдельно.
function ActionBar.DetachGroupButton(group, btn)
    if not group or not btn then
        return
    end
    RemoveFromList(group.buttons, btn)
    RemoveFromList(group.visibleButtons, btn)
    if btn.ReturnHome then
        btn:ReturnHome()
        return
    end
    if ActionBar.ReturnButtonHome then
        ActionBar.ReturnButtonHome(btn)
        return
    end
    if btn.group == group then
        btn.group = nil
    end
end
