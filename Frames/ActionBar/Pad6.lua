-- Широкая кнопка сенсорной панели: плашка с круглыми торцами и место подписи.

local ConsoleMenu = _G.ConsoleMenu
local ActionBar = ConsoleMenu.ActionBar

-- Плашка полупрозрачная: нахлёст стыка темнеет, поэтому части сходятся вплотную.
local function SeatPlatePiece(piece)
    if piece.SetSnapToPixelGrid then
        piece:SetSnapToPixelGrid(false)
    end
    if piece.SetTexelSnappingBias then
        piece:SetTexelSnappingBias(0)
    end
end

-- Собирает плашку из трёх частей, чтобы при расширении круглые торцы не растягивались.
function ActionBar.BuildSlot12Plate(buttonFrame)
    local texturePath = ActionBar.slot12PlateTexture
    local capTex = (ActionBar.slot12PlateTexHeight / 2) / ActionBar.slot12PlateTexWidth
    local capWidth = ActionBar.slot12ContainerHeight / 2

    local middle = buttonFrame:CreateTexture(nil, "BACKGROUND", nil, -1)
    middle:SetTexture(texturePath)
    middle:SetTexCoord(capTex, 1 - capTex, 0, 1)
    SeatPlatePiece(middle)

    local left = buttonFrame:CreateTexture(nil, "BACKGROUND", nil, -1)
    left:SetTexture(texturePath)
    left:SetTexCoord(0, capTex, 0, 1)
    left:SetPoint("TOPLEFT", buttonFrame, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", buttonFrame, "BOTTOMLEFT", 0, 0)
    left:SetWidth(capWidth)
    SeatPlatePiece(left)

    local right = buttonFrame:CreateTexture(nil, "BACKGROUND", nil, -1)
    right:SetTexture(texturePath)
    right:SetTexCoord(1 - capTex, 1, 0, 1)
    right:SetPoint("TOPRIGHT", buttonFrame, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", buttonFrame, "BOTTOMRIGHT", 0, 0)
    right:SetWidth(capWidth)
    SeatPlatePiece(right)

    middle:SetPoint("TOPLEFT", left, "TOPRIGHT", 0, 0)
    middle:SetPoint("BOTTOMLEFT", left, "BOTTOMRIGHT", 0, 0)
    middle:SetPoint("TOPRIGHT", right, "TOPLEFT", 0, 0)
    middle:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT", 0, 0)

    buttonFrame.plateLeft = left
    buttonFrame.plateMiddle = middle
    buttonFrame.plateRight = right
end
