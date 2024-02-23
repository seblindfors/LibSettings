local MODULE_NAME = 'Controls';
local MODULE_VER  = 1;

local Lib = LibStub('LibSettings'):Module(MODULE_NAME, MODULE_VER);
if not Lib then return end ---@diagnostic disable: undefined-global

---------------------------------------------------------------------------------------
---@class LibSettings.OptionList
---@field  [1]          any                  Value of the option
---@field  [2]          string               Display name of the option
---@field  [3]          string               Optional tooltip line for the option
---------------------------------------------------------------------------------------
---@class LibSettings.Options<i, LibSettings.OptionList>
---------------------------------------------------------------------------------------
---@alias LibSettings.OptGen   fun(internal: LibSettings.Setting) : Blizzard.Option[]
---@alias LibSettings.OptList  fun(options: LibSettings.Options) : Blizzard.Option[]
---@alias LibSettings.GetOpts  LibSettings.OptGen | LibSettings.OptList
---------------------------------------------------------------------------------------
---@class Blizzard.Option
---@field  value        any                  Value of the option
---@field  name         string               Display name of the option
---@field  tooltip      string               Optional tooltip line for the option
---@field  disabled     boolean              Option is disabled
---------------------------------------------------------------------------------------
---@class LibSettings.Types.Binding : LibSettings.Variable
---@field  binding      string               Binding to modify
---------------------------------------------------------------------------------------
---@class LibSettings.Types.Button : LibSettings.Variable
---@field  click        function             Callback function for the button
---@field  title        string               Title of the button
---------------------------------------------------------------------------------------
---@class LibSettings.Types.CheckBox : LibSettings.Setting
---@field  default      boolean              Default value of the checkbox
---------------------------------------------------------------------------------------
---@class LibSettings.Types.CheckBoxDropDown : LibSettings.Types.CheckBox
---@field [1] LibSettings.Types.DropDown      Dropdown next to the checkbox
---------------------------------------------------------------------------------------
---@class LibSettings.Types.CheckBoxSlider : LibSettings.Types.CheckBox
---@field [1] LibSettings.Types.Slider        Slider next to the checkbox
---------------------------------------------------------------------------------------
---@class LibSettings.Types.DropDown : LibSettings.Setting
---@field  default      any                  Default value of the dropdown
---@field  options      LibSettings.Options | LibSettings.OptGen Options table or generator
---------------------------------------------------------------------------------------
---@class LibSettings.Types.Slider : LibSettings.Setting
---@field  default      number               Default value of the slider
---@field  min          number               Minimum value of the slider
---@field  max          number               Maximum value of the slider
---@field  step         number               Step value of the slider
---@field  format       function             Function to format the slider value
---------------------------------------------------------------------------------------

-- Dropdown options
local function CreateOptionsTable(options) ---@type LibSettings.OptList
    local container = Settings.CreateControlTextContainer();
    for _, option in ipairs(options) do
        container:Add(unpack(option));
    end
    return container:GetData();
end

---@param  props     LibSettings.Types.DropDown Properties of the dropdown
---@return LibSettings.GetOpts   options Options table generator
local function MakeOptions(props)
    if type(props.options) == 'function' then
        return GenerateClosure(props.options, props) --[[@as LibSettings.OptGen]];
    else
        return GenerateClosure(CreateOptionsTable, props.options) --[[@as LibSettings.OptList]];
    end
end

-- Slider options
local function CreateSliderOptions(props)
    local options = Settings.CreateSliderOptions(props.min, props.max, props.step);
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, props.format);
    return options;
end

---@type fun(props: LibSettings.Types.Binding, parent: LibSettings.Result.Layout, index: integer): LibSettings.Result.Init, ...
--- Creates a key binding element, with support for meta keys, key chords and single key input. For bindings defined in XML.
Binding
= function(props, parent, index)
    local name, id = GetIdentity(props, parent, index);
    local binding = props.binding;
    local search  = not not props.search;
    local entry   = C_KeyBindings.GetBindingIndex(binding);
    local init    = CreateKeybindingEntryInitializer(entry, search);
    if search then
        init:AddSearchTags(GetBindingName(binding), name);
    end
    parent.layout:AddInitializer(init);
    MountCommon(init, props, parent);
    return init, id;
end

---@type fun(props: LibSettings.Types.Button, parent: LibSettings.Result.Layout, index: integer): LibSettings.Result.Init, ...
--- Creates a button element, with a callback function for when it is clicked.
Button
= function(props, parent, index)
    local name, id = GetIdentity(props, parent, index);
    local click   = props.click;
    local title   = props.title;
    local tooltip = props.tooltip;
    local search  = not not props.search;
    local init    = CreateSettingsButtonInitializer(name, title, click, tooltip, search);
    parent.layout:AddInitializer(init);
    MountCommon(init, props, parent);
    return init, id;
end

---@type fun(props: LibSettings.Types.CheckBox, parent: LibSettings.Result.Layout, index: integer, noInit: boolean): LibSettings.Proto, ...
--- Creates a checkbox element for a boolean setting.
CheckBox
= function(props, parent, index, noInit)
    local name, id, variable = GetIdentity(props, parent, index);
    local set, get = GetCallbacks(props, parent);

    local setting, init = MakeSetting(props, parent, name, variable, Settings.VarType.Boolean);
    if not noInit then
        init = Settings.CreateCheckBox(parent.object, setting, props.tooltip);
        MountCommon(init, props, parent);
    end
    return init or setting, id, nil, MountControls(props, setting, set, get);
end

---@type fun(props: LibSettings.Types.DropDown, parent: LibSettings.Result.Layout, index: integer, noInit: boolean): LibSettings.Proto, ...
--- Creates a dropdown element, with a list of options to choose from.
DropDown
= function(props, parent, index, noInit)
    local name, id, variable = GetIdentity(props, parent, index);
    local set, get = GetCallbacks(props, parent);
    local setting, init = MakeSetting(props, parent, name, variable, type(props.default));
    if not noInit then
        init = Settings.CreateDropDown(parent.object, setting, MakeOptions(props), props.tooltip);
        MountCommon(init, props, parent);
    end
    return init or setting, id, nil, MountControls(props, setting, set, get);
end

---@type fun(props: LibSettings.Types.CheckBoxSlider, parent: LibSettings.Result.Layout, index: integer): LibSettings.Result.Combined, ...
--- Creates a combined element with a checkbox and a slider, where the slider is activated by the checkbox.
CheckBoxSlider
= function(props, parent, index)
    local cbSetting, id, _, cbSet, cbGet = Lib.Types.CheckBox(
        props --[[@as LibSettings.Types.CheckBox]], parent, index, true);
    local cbLabel, cbTooltip, cbProps = props.name, props.tooltip, props;

    props = tremove(props, CHILDREN);
    local slSetting, _, _, slSet, slGet = Lib.Types.Slider(
        props --[[@as LibSettings.Types.Slider]], parent, index, true);
    local slLabel, slTooltip = props.name, props.tooltip;

    local init = CreateSettingsCheckBoxSliderInitializer(
        cbSetting, cbLabel, cbTooltip,
        slSetting, CreateSliderOptions(props), slLabel, slTooltip
    );
    parent.layout:AddInitializer(init);
    MountCommon(init, cbProps);
    MountCommon(init, props, parent);

    cbSet, cbGet = cbSet or nop, cbGet or nop;
    slSet, slGet = slSet or nop, slGet or nop;
    return init, id, nil, cbSet, cbGet, slSet, slGet;
end

---@type fun(props: LibSettings.Types.CheckBoxDropDown, parent: LibSettings.Result.Layout, index: integer): LibSettings.Result.Combined, ...
--- Creates a combined element with a checkbox and a dropdown, where the dropdown is activated by the checkbox.
CheckBoxDropDown
= function(props, parent, index)
    local cbSetting, id, _, cbSet, cbGet = Lib.Types.CheckBox(
        props --[[@as LibSettings.Types.CheckBox]], parent, index, true);
    local cbLabel, cbTooltip, cbProps = props.name, props.tooltip, props;

    props = tremove(props, CHILDREN);
    local ddSetting, _, _, ddSet, ddGet = Lib.Types.DropDown(
        props --[[@as LibSettings.Types.DropDown]], parent, index, true);
    local ddLabel, ddTooltip = props.name, props.tooltip;
    local init = CreateSettingsCheckBoxDropDownInitializer(
        cbSetting, cbLabel, cbTooltip,
        ddSetting, MakeOptions(props), ddLabel, ddTooltip
    );
    parent.layout:AddInitializer(init);
    MountCommon(init, cbProps);
    MountCommon(init, props, parent);

    cbSet, cbGet = cbSet or nop, cbGet or nop;
    ddSet, ddGet = ddSet or nop, ddGet or nop;
    return init, id, nil, cbSet, cbGet, ddSet, ddGet;
end

---@type fun(props: LibSettings.Types.Slider, parent: LibSettings.Result.Layout, index: integer, noInit: boolean): LibSettings.Proto, ...
--- Creates a numerical slider element, with a range and step size.
Slider
= function(props, parent, index, noInit)
    local name, id, variable = GetIdentity(props, parent, index);
    local set, get = GetCallbacks(props, parent);
    local setting, init = MakeSetting(props, parent, name, variable, Settings.VarType.Number);
    if not noInit then
        init = Settings.CreateSlider(parent.object, setting, CreateSliderOptions(props), props.tooltip);
        MountCommon(init, props, parent);
    end
    return init or setting, id, nil, MountControls(props, setting, set, get);
end

Lib:Resolve(MODULE_NAME, function(Types, props, parent)
    if not parent then return end;
    if props.options then
        return Types.DropDown;
    elseif props.step then
        return Types.Slider;
    elseif type(props.default) == 'boolean' then
        if props[CHILDREN] then
            if props[CHILDREN].options then
                return Types.CheckBoxDropDown;
            elseif props[CHILDREN].step then
                return Types.CheckBoxSlider;
            end
            return Types.CheckBoxSlider;
        end
        return Types.CheckBox;
    elseif props.binding then
        return Types.Binding;
    elseif props.click then
        return Types.Button;
    end
end);