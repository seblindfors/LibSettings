--[[ --Reference
MyAddOn_SavedVars = {}

local function OnSettingChanged(_, setting, value)
    local variable = setting:GetVariable()
    MyAddOn_SavedVars[variable] = value
end

local category = Settings.RegisterVerticalLayoutCategory("My AddOn")

do
    local variable = "toggle"
    local name = "Test Checkbox"
    local tooltip = "This is a tooltip for the checkbox."
    local defaultValue = false

    local setting = Settings.RegisterAddOnSetting(category, name, variable, type(defaultValue), defaultValue)
    Settings.CreateCheckBox(category, setting, tooltip)
    Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
end

do
    local variable = "slider"
    local name = "Test Slider"
    local tooltip = "This is a tooltip for the slider."
    local defaultValue = 180
    local minValue = 90
    local maxValue = 360
    local step = 10

    local setting = Settings.RegisterAddOnSetting(category, name, variable, type(defaultValue), defaultValue)
    local options = Settings.CreateSliderOptions(minValue, maxValue, step)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right);
    Settings.CreateSlider(category, setting, options, tooltip)
    Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
end

do
    local variable = "selection"
    local defaultValue = 2  -- Corresponds to "Option 2" below.
    local name = "Test Dropdown"
    local tooltip = "This is a tooltip for the dropdown."

    local function GetOptions()
        local container = Settings.CreateControlTextContainer()
        container:Add(1, "Option 1")
        container:Add(2, "Option 2")
        container:Add(3, "Option 3")
        return container:GetData()
    end

    local setting = Settings.RegisterAddOnSetting(category, name, variable, type(defaultValue), defaultValue)
    Settings.CreateDropDown(category, setting, GetOptions, tooltip)
    Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
end

Settings.RegisterAddOnCategory(category)
]]

local Lib = LibStub('LibSettings') ---@as LibSettings;

Test_SavedVars = {testCheckBox = false, testSlider = 190, selection = 2, testCheckBox2 = true, testKey = 'ALT-SHIFT-A', color = 'FFAAD372'}

res = Lib({
    name  = 'Test Addon';
    id    = 'testAddon';
    type  = Lib.Types.VerticalLayoutCategory;
    table = Test_SavedVars;
    {
        {
            type     = Lib.Types.Color;
            name     = 'Test Color';
            id       = 'color';
            tooltip  = 'This is a tooltip for the color.';
            default  = 'FFAAD372';
        };
        {
            type     = Lib.Types.Key;
            name     = 'Test Key';
            tooltip  = 'This is a tooltip for the key.';
            id       = 'testKey';
            default  = 'A';
            agnostic = true;
        };
        {
            name     = 'Test Checkbox';
            id       = 'testCheckBox';
            tooltip  = 'This is a tooltip for the checkbox.';
            default  = false;
            new      = true;
            --[[{
                name     = 'Test Slider';
                id       = 'testSlider';
                tooltip  = 'This is a tooltip for the slider.';
                default  = 180;
                min      = 90;
                max      = 360;
                step     = 10;
            };]]
        };
        {
            name    = 'Test Modify Predicate';
            id      = 'testCheckBox2';
            parent  = 'children.testCheckBox';
            default = true;
        };
        {
            name     = 'Test Slider';
            id       = 'testSlider';
            tooltip  = 'This is a tooltip for the slider.';
            parent   = 'children.testCheckBox';
            default  = 180;
            min      = 90;
            max      = 360;
            step     = 10;
        };
        {
            type = Lib.Types.ExpandableSection;
            name = 'Expandable Section';
            id   = 'expandableSection';
            {
                {
                    name     = 'Test Checkbox 2';
                    id       = 'toggle2';
                    tooltip  = 'This is a tooltip for the checkbox.';
                    default  = false;
                    {
                        type     = Lib.Types.Slider;
                        name     = 'Test Slider 2';
                        id       = 'slider2';
                        tooltip  = 'This is a tooltip for the slider.';
                        default  = 180;
                        min      = 90;
                        max      = 360;
                        step     = 10;
                    };
                };
            };
        };
        {
            type = Lib.Types.ExpandableSection;
            name = 'Expandable Section';
            id   = 'expandableSection2';
            {
                {
                    name     = 'Test Checkbox 2';
                    id       = 'toggle3';
                    tooltip  = 'This is a tooltip for the checkbox.';
                    default  = false;
                    {
                        type     = Lib.Types.Slider;
                        name     = 'Test Slider 2';
                        id       = 'slider3';
                        tooltip  = 'This is a tooltip for the slider.';
                        default  = 180;
                        min      = 90;
                        max      = 360;
                        step     = 10;
                    };
                };
            };
        };
        {
            type     = Lib.Types.DropDown;
            name     = 'Test Dropdown';
            id       = 'selection';
            tooltip  = 'This is a tooltip for the dropdown.';
            default  = 2;
            options  = {
                { 1, 'Option 1' };
                { 2, 'Option 2' };
                { 3, 'Option 3' };
            };
        };
        --[[
        {
            type     = Lib.Types.Key;
            name     = 'Test Key';
            tooltip  = 'This is a tooltip for the key.';
            get = function() return {'A'} end;
            set = function(result) DevTools_Dump(result) end;
        };
        {
            type    = Lib.Types.VerticalLayoutSubcategory;
            name    = 'Subcategory';
            {
                {
                    name     = 'Test Checkbox 2';
                    variable = 'toggle2';
                    tooltip  = 'This is a tooltip for the checkbox.';
                    default  = false;
                };
                {
                    type     = Lib.Types.Slider;
                    name     = 'Test Slider 2';
                    variable = 'slider2';
                    tooltip  = 'This is a tooltip for the slider.';
                    default  = 180;
                    min      = 90;
                    max      = 360;
                    step     = 10;
                };
                {
                    type     = Lib.Types.DropDown;
                    name     = 'Test Dropdown 2';
                    variable = 'selection2';
                    tooltip  = 'This is a tooltip for the dropdown.';
                    default  = 2;
                    options  = {
                        { 1, 'Option 1', 'Option-specific tooltip.'};
                        { 2, 'Option 2' };
                        { 3, 'Option 3' };
                    };
                };
                {
                };
                {
                    name    = 'Subcategory 2';
                    {
                        {
                            name     = 'Test Checkbox 3';
                            variable = 'toggle3';
                            tooltip  = 'This is a tooltip for the checkbox.';
                            default  = false;
                        };
                        {
                            type     = Lib.Types.Button;
                            name     = 'Button';
                            tooltip  = 'This is a tooltip for the button.';
                            callback = function(...)
                                print(...)
                            end;
                        };
                        {
                            name     = 'Test Slider 3';
                            variable = 'slider3';
                            tooltip  = 'This is a tooltip for the slider.';
                            default  = 180;
                            min      = 90;
                            max      = 360;
                            step     = 10;
                        };
                        {
                            name     = 'Header';
                        };
                        {
                            name     = 'Test Dropdown 3';
                            variable = 'selection3';
                            tooltip  = 'This is a tooltip for the dropdown.';
                            default  = 2;
                            options  = {
                                { 1, 'Option 1' };
                                { 2, 'Option 2' };
                                { 3, 'Option 3' };
                            };
                        };
                        {
                            binding = 'EXTRAACTIONBUTTON1';
                            name    = 'Test Binding';
                            tooltip = 'This is a tooltip for the binding.';
                        };
                    };
                };
            };
        };]]
    };
})

--DevTools_Dump(res)

--]]
