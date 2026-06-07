function ConsoleMenu:SetGameDialog()
    hooksecurefunc("StaticPopup_OnShow", function(dialog)
        if InCombatLockdown() then return end -- важно для protected binding
        local b1, b2 = dialog:GetButton1(), dialog:GetButton2()
        if b1 and b1:IsShown() then
            SetOverrideBindingClick(dialog, true, "PAD1", b1:GetName(), "LeftButton") -- A -> Accept
        end
        if b2 and b2:IsShown() then
            SetOverrideBindingClick(dialog, true, "PAD2", b2:GetName(), "LeftButton") -- B -> Cancel
        end
    end)
    hooksecurefunc("StaticPopup_OnHide", function(dialog)
        ClearOverrideBindings(dialog)
    end)
end