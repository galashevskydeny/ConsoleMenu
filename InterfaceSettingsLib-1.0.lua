
-- Register Addon Table (Required) --
------------------------------------- 
	local Addon = ConsoleMenuAddon           -- Addon Table (Table)
    local AddonName = Addon.AddonName           -- Addon Name (String)
    local AddonFileName = Addon.AddonFileName   -- Addon File Name (String)



-- Initialize Library --
------------------------ 
    local LIBRARY_ID, LIBRARY_VERSION = "InterfaceSettingsLib-1.0", 1

    local globalEnv = _G or getfenv(0)

    local InterfaceSettingsLib = globalEnv[LIBRARY_ID] or {}
    globalEnv[LIBRARY_ID] = InterfaceSettingsLib
    globalEnv["InterfaceSettingsLib"] = InterfaceSettingsLib
    globalEnv["ISL_"] = InterfaceSettingsLib

    InterfaceSettingsLib.Version = LIBRARY_VERSION
    InterfaceSettingsLib.Settings = InterfaceSettingsLib.Settings or {}




-- Settings Tables --
--------------------- 

    -- Parent 
        InterfaceSettingsLib[AddonName] = {}

    -- Checkboxes 
        InterfaceSettingsLib[AddonName].Checkboxes = {}

    -- Dropdowns 
        InterfaceSettingsLib[AddonName].Dropdowns = {}

    -- Categories 
        InterfaceSettingsLib[AddonName].Categories = {}

    -- Headers 
        InterfaceSettingsLib[AddonName].Headers = {}



-- Core Functions --
-------------------- 

    -- Register Addon Settings (Checkbox) 
        local function ISL_RegisterAddonSetting(CategoryTable, UniqueName, VariableKey, AddonSettingsTable, VariableType, Name, DefaultValue)
            return Settings.RegisterAddOnSetting(CategoryTable, UniqueName, VariableKey, AddonSettingsTable, VariableType, Name, DefaultValue)
        end

    -- Set Default Value 
        local function ISL_SetDefaultValue(AddonSettingsTable, VariableKey, DefaultValue)
            if AddonSettingsTable[VariableKey] == nil then
                AddonSettingsTable[VariableKey] = DefaultValue
            end
        end



-- Functions --
--------------- 

    -- Create Category 
        function InterfaceSettingsLib:CreateCategory(AddonName)

        -- Validate Input 
            if not AddonName or type(AddonName) ~= "string" then
                error("[InterfaceSettingsLib:CreateCategory]: 'AddonName' must be a string.")
            end

        -- Ensure AddonName Is Initialized 
            if not self[AddonName] or not self[AddonName].Categories then
                error("[InterfaceSettingsLib:CreateCategory]: 'AddonName' is not initialized under Register Addon Table.")
            end

        -- Create Vertical Layout Category 
            local Category, Layout = Settings.RegisterVerticalLayoutCategory(AddonName)

        -- Store Category And Layout 
            self[AddonName].Categories[Category:GetName()] = {
                Category = Category,
                Layout = Layout,
            }

        -- Register Category 
            Settings.RegisterAddOnCategory(Category)

        -- Return Category And Layout 
            return Category, Layout

        end

    -- Create Header 
        function InterfaceSettingsLib:CreateHeader(CategoryName, CustomName, HeaderName, HeaderTooltip)

        -- Validate Inputs 
            if not CategoryName or not CustomName or not HeaderName then
                error("[InterfaceSettingsLib:CreateHeader]: 'CategoryName', 'CustomName', and 'HeaderName' are required.")
            end
            if type(CategoryName) ~= "string" or type(CustomName) ~= "string" or type(HeaderName) ~= "string" then
                error("[InterfaceSettingsLib:CreateHeader]: 'CategoryName', 'CustomName', and 'HeaderName' must be strings.")
            end
            local CategoryData = self[AddonName].Categories[CategoryName]
            if not CategoryData then
                error("[InterfaceSettingsLib:CreateHeader]: Category '" .. CategoryName .. "' does not exist.")
            end

        -- Ensure Addon Data Structure Is Properly Initialized 
            if not self[AddonName] or not self[AddonName].Categories or not self[AddonName].Headers then
                error("[InterfaceSettingsLib:CreateHeader]: 'AddonName' is not initialized under Register Addon Table.")
            end

        -- Create Header 
            local Header = CreateSettingsListSectionHeaderInitializer(HeaderName, HeaderTooltip)

        -- Add Header To Layout 
            local Layout = CategoryData.Layout
            Layout:AddInitializer(Header)

         -- Create Unique Name 
            local UniqueName = (CustomName .. HeaderName):gsub("%s+", "")

        -- Store Header 
            HeaderTooltip = HeaderTooltip or ""
            self[AddonName].Headers[UniqueName] = {
                Header = Header,
                Tooltip = HeaderTooltip,
                ParentCategory = CategoryName,
            }

         -- Return Header 
            return Header

        end

    -- Create Subcategory 
        function InterfaceSettingsLib:CreateSubcategory(ParentCategoryTable, SubcategoryName)

        -- Validate Inputs 
            if not ParentCategoryTable or not SubcategoryName then
                error("[InterfaceSettingsLib:CreateSubcategory]: 'ParentCategoryTable' and 'SubcategoryName' are required.")
            end
            if type(ParentCategoryTable) ~= "table" or type(SubcategoryName) ~= "string" then
                error("[InterfaceSettingsLib:CreateSubcategory]: 'ParentCategoryTable' must be a table, and 'SubcategoryName' must be a string.")
            end
            local ParentCategoryName = ParentCategoryTable:GetName()
            if not ParentCategoryName or not self[AddonName].Categories[ParentCategoryName] then
                error("[InterfaceSettingsLib:CreateSubcategory]: Parent category '" .. (ParentCategoryName or "unknown") .. "' does not exist.")
            end

        -- Ensure Addon Data Structure Is Properly Initialized 
            if not self[AddonName] or not self[AddonName].Categories then
                error("[InterfaceSettingsLib:CreateSubcategory]: 'AddonName' is not initialized under Register Addon Table.")
            end

        -- Create Subcategory And Layout 
            local ParentCategoryData = self[AddonName].Categories[ParentCategoryName]
            local Subcategory, SubcategoryLayout = Settings.RegisterVerticalLayoutSubcategory(
                ParentCategoryData.Category,
                SubcategoryName
            )

        -- Store Subcategory And Layout 
            self[AddonName].Categories[SubcategoryName] = {
                Category = Subcategory,
                Layout = SubcategoryLayout,
                Parent = ParentCategoryTable,
            }

        -- Return Subcategory And Layout 
            return Subcategory, SubcategoryLayout

        end

    -- Create Checkbox 
        function InterfaceSettingsLib:CreateCheckbox(CategoryTable, CheckBoxName, UniqueName, VariableKey, AddonSettingsTable, DefaultValue, Tooltip, Callback, Indent)

        -- Validate Inputs 
            if type(CategoryTable) ~= "table" or type(CheckBoxName) ~= "string" or type(UniqueName) ~= "string" then
                error("[InterfaceSettingsLib:CreateCheckbox]: 'CategoryTable' must be a table, and 'CheckBoxName' and 'UniqueName' must be strings.")
            end
            if type(DefaultValue) ~= "boolean" then
                error("[InterfaceSettingsLib:CreateCheckbox]: 'DefaultValue' must be a boolean.")
            end
            if Callback and type(Callback) ~= "function" then
                error("[InterfaceSettingsLib:CreateCheckbox]: 'Callback' must be a function.")
            end

        -- Ensure Addon Data Structure Is Properly Initialized 
            self[AddonName] = self[AddonName] or {}
            self[AddonName].Checkboxes = self[AddonName].Checkboxes or {}

        -- Register Checkbox 
            local Setting = ISL_RegisterAddonSetting(CategoryTable, UniqueName, VariableKey, AddonSettingsTable, type(DefaultValue), CheckBoxName, DefaultValue)

        -- Set Callback 
            if Callback then
                Setting:SetValueChangedCallback(function(setting, value)
                    Callback(Setting, value)
                end)
            end

        -- Create Checkbox 
            local Checkbox = Settings.CreateCheckbox(CategoryTable, Setting, Tooltip)

        -- Store Checkbox 
            self[AddonName].Checkboxes[UniqueName] = Checkbox

        -- Indent Checkbox
            if Indent == true then
                Checkbox:Indent()
            end

        -- Return Checkbox 
            return Checkbox

        end

    -- Create Dropdown 
        function InterfaceSettingsLib:MakeDropdown(CategoryTable, DropdownName, VariableKey, DefaultValue, Tooltip, DropdownOptions, AddonSettingsTable, Callback, Measurement)

        -- Validate Inputs 
            if type(CategoryTable) ~= "table" or type(DropdownName) ~= "string" or type(VariableKey) ~= "string" then
                error("[InterfaceSettingsLib:MakeDropdown]: 'CategoryTable' must be a table, and 'DropdownName', and 'VariableKey' must be strings.")
            end
            if not DropdownOptions or type(DropdownOptions) ~= "table" then
                error("[InterfaceSettingsLib:MakeDropdown]: 'DropdownOptions' must be a table.")
            end
            if Callback and type(Callback) ~= "function" then
                error("[InterfaceSettingsLib:MakeDropdown]: 'Callback' must be a function.")
            end

        -- Ensure Addon Data Structure Is Properly Initialized 
            self[AddonName] = self[AddonName] or {}
            self[AddonName].Dropdowns = self[AddonName].Dropdowns or {}

        -- Generate Dropdown Options 
            local function GetOptions()
                local container = Settings.CreateControlTextContainer()
                for i, option in ipairs(DropdownOptions) do
                    if not Measurement then
                        container:Add(i, option)
                    else
                        container:Add(i, option .. " " .. Measurement)
                    end
                end
                return container:GetData()
            end

        -- Register Dropdown 
            local setting = Settings.RegisterAddOnSetting(CategoryTable, VariableKey, VariableKey, AddonSettingsTable, type(DefaultValue), DropdownName, DefaultValue)
            setting.data = { Tooltip = Tooltip }

        -- Set Callback 
            if Callback then
                setting:SetValueChangedCallback(function(setting, value)
                    Callback(setting, value)
                end)
            end

        -- Create Dropdown 
            local Dropdown = Settings.CreateDropdown(CategoryTable, setting, GetOptions, Tooltip)

        -- Store Dropdown 
            self[AddonName].Dropdowns[VariableKey] = Dropdown

        -- Return Dropdown 
            return Dropdown

        end

