---@class LibSettings
local Lib = LibStub:NewLibrary('LibSettings', 0.1)
if not Lib then return end; local _ = CreateCounter();
---------------------------------------------------------------------------------------
Lib.Types                       =  {--[[@enum (key) Types                            ]]
---------------------------------------------------------------------------------------
    -- Widgets
    Binding                     =_()--[[@as LibSettings.Type.Binding                ]];
    Button                      =_()--[[@as LibSettings.Type.Button                 ]];
    CheckBox                    =_()--[[@as LibSettings.Type.CheckBox               ]];
    CheckBoxDropDown            =_()--[[@as LibSettings.Type.CheckBoxDropDown       ]];
    CheckBoxSlider              =_()--[[@as LibSettings.Type.CheckBoxSlider         ]];
    DropDown                    =_()--[[@as LibSettings.Type.DropDown               ]];
    Element                     =_()--[[@as LibSettings.Type.Element                ]];
    Header                      =_()--[[@as LibSettings.Type.Header                 ]];
    Slider                      =_()--[[@as LibSettings.Type.Slider                 ]];
    Spacer                      =_()--[[@as LibSettings.Type.Spacer                 ]];
    Key                         =_()--[[@as LibSettings.Type.Key                    ]];
    -- Containers
    CanvasLayoutCategory        =_()--[[@as LibSettings.Category.Canvas             ]];
    CanvasLayoutSubcategory     =_()--[[@as LibSettings.Category.Canvas             ]];
    VerticalLayoutCategory      =_()--[[@as LibSettings.Category.Vertical           ]];
    VerticalLayoutSubcategory   =_()--[[@as LibSettings.Category.Vertical           ]];
    ExpandableSection           =_()--[[@as LibSettings.Type.ExpandableSection      ]];
---------------------------------------------------------------------------------------
---@class LibSettings.ListItem
    ---@field  name         string               Display name of the elment
    ---@field  id           string               Generative identifier of the element
---------------------------------------------------------------------------------------
---@class LibSettings.Option
    ---@field  value        any                  Value of the option
    ---@field  name         string               Display name of the option
    ---@field  tooltip      string               Optional tooltip line for the option
    ---@field  disabled     boolean              Option is disabled
---------------------------------------------------------------------------------------
---@class LibSettings.OptionList
    ---@field  [1]          any                  Value of the option
    ---@field  [2]          string               Display name of the option
    ---@field  [3]          string               Optional tooltip line for the option
---------------------------------------------------------------------------------------
---@class LibSettings.Options<i, LibSettings.OptionList>
---------------------------------------------------------------------------------------
---@class LibSettings.Canvas : Frame
    ---@field  OnCommit      function            Callback function for committing
    ---@field  OnDefault     function            Callback function for resetting
    ---@field  OnRefresh     function            Callback function for refreshing
    ---@source Interface/SharedXML/Settings/Blizzard_SettingsCanvas.lua
---------------------------------------------------------------------------------------
---@class LibSettings.Variable : LibSettings.ListItem
    ---@field  variable     string               Unique variable ID of the element
    ---@field  search       boolean              Show the element in search results
    ---@field  tooltip      string               Tooltip for the element
    ---@field  show         LibSettings.Pred     Predicate(s) for showing the element
    ---@field  modify       LibSettings.Pred     Predicate(s) for allowing modification
    ---@field  event        LibSettings.Event    Event to trigger the element to update
    ---@field  parent       string               Relative key to parent initializer
---------------------------------------------------------------------------------------
---@class LibSettings.Setting : LibSettings.Variable
    ---@field  set          function             Callback function for setting a value
    ---@field  get          function             Function to get current value
    ---@field  key          any                  Key for value in storage table
    ---@field  table        table|string         Table/global ref. to store value
---------------------------------------------------------------------------------------
---@class LibSettings.Type.Header : LibSettings.ListItem
---------------------------------------------------------------------------------------
---@class LibSettings.Type.Spacer
---------------------------------------------------------------------------------------
---@class LibSettings.Type.ExpandableSection : LibSettings.ListItem
    ---@field  expanded     boolean              Section is expanded by default
---------------------------------------------------------------------------------------
---@class LibSettings.Type.Key : LibSettings.Variable
    ---@field  agnostic     boolean              Key chord is agnostic to meta key side
    ---@field  single       boolean              Key chord is single key
---------------------------------------------------------------------------------------
---@class LibSettings.Type.Element : LibSettings.Variable
    ---@field  width        number               Width of the element : DEF_ELEM_WIDTH
    ---@field  height       number               Height of the element : DEF_ELEM_HEIGHT
    ---@field  extent       number               Extent of the element (height + padding)
---------------------------------------------------------------------------------------
---@class LibSettings.Type.Binding : LibSettings.Variable
    ---@field  binding      string               Binding to modify
---------------------------------------------------------------------------------------
---@class LibSettings.Type.Button : LibSettings.Variable
    ---@field  click        function             Callback function for the button
    ---@field  title        string               Title of the button
---------------------------------------------------------------------------------------
---@class LibSettings.Type.CheckBox : LibSettings.Setting
    ---@field  default      boolean              Default value of the checkbox
---------------------------------------------------------------------------------------
---@class LibSettings.Type.DropDown : LibSettings.Setting
    ---@field  default      any                  Default value of the dropdown
    ---@field  options      LibSettings.Options | LibSettings.OptGen Options table or generator
---------------------------------------------------------------------------------------
---@class LibSettings.Type.Slider : LibSettings.Setting
    ---@field  default      number               Default value of the slider
    ---@field  min          number               Minimum value of the slider
    ---@field  max          number               Maximum value of the slider
    ---@field  step         number               Step value of the slider
    ---@field  format       function             Function to format the slider value
---------------------------------------------------------------------------------------
---@class LibSettings.Type.CheckBoxDropDown : LibSettings.Type.CheckBox
    ---@field [1] LibSettings.Type.DropDown      Dropdown next to the checkbox
---------------------------------------------------------------------------------------
---@class LibSettings.Type.CheckBoxSlider : LibSettings.Type.CheckBox
    ---@field [1] LibSettings.Type.Slider        Slider next to the checkbox
---------------------------------------------------------------------------------------
---@class LibSettings.Category.Vertical : LibSettings.Setting
    ---@field [1] table<integer, LibSettings.ListItem> List of child elements
---------------------------------------------------------------------------------------
---@class LibSettings.Category.Canvas : LibSettings.ListItem
    ---@field  frame        LibSettings.Canvas   Frame to insert in the canvas
---------------------------------------------------------------------------------------
---@class LibSettings.Result.Base
    ---@field  object       LibSettings.Widget   Widget object that was created
    ---@field  id           string               Unique identifier of the object
---------------------------------------------------------------------------------------
---@class LibSettings.Result.Init : LibSettings.Result.Base
    ---@field  data         table                Data table for the initializer
    ---@field  InitFrame    function            Callback function for initializing
    ---@field  Resetter     function            Callback function for resetting
    ---@field  AddSearchTags function            Callback function for adding tags
---------------------------------------------------------------------------------------
---@class LibSettings.Result.Setting : LibSettings.Result.Base
    ---@field  setValue     LibSettings.SetValue Wrapped function for setting a value
    ---@field  getValue     LibSettings.GetValue Wrapped function for getting a value
---------------------------------------------------------------------------------------
---@class LibSettings.Result.Combined : LibSettings.Result.Base
    ---@field  setValue     LibSettings.SetValue Wrapped function for setting a value
    ---@field  getValue     LibSettings.GetValue Wrapped function for getting a value
    ---@field  setOption    LibSettings.SetValue Wrapped function for setting an option
    ---@field  getOption    LibSettings.GetValue Wrapped function for getting an option
---------------------------------------------------------------------------------------
---@class LibSettings.Result.Layout : LibSettings.Result.Base
    ---@field  layout       LibSettings.Layout   Layout object that was created
    ---@field  children     table                Nested table of created child widgets
    ---@field  setValue     LibSettings.Setter   Callback function for setting a value
    ---@field  getValue     LibSettings.Getter   Callback function for getting a value
---------------------------------------------------------------------------------------
---@alias LibSettings.Widget   table
---@alias LibSettings.Layout   table
---@alias LibSettings.Pred     function|table<integer, function>
---@alias LibSettings.Event    string|table<integer, string>
---@alias LibSettings.SetValue fun(value: any)
---@alias LibSettings.GetValue fun() : any
---@alias LibSettings.Getter   fun(internal: LibSettings.Setting, setting: LibSettings.Widget) : any
---@alias LibSettings.Setter   fun(internal: LibSettings.Setting, setting: LibSettings.Widget, value: any)
---@alias LibSettings.Set      fun(props: LibSettings.Setting, parent: LibSettings.Result.Layout?) : LibSettings.Setter
---@alias LibSettings.Get      fun(props: LibSettings.Setting, parent: LibSettings.Result.Layout?) : LibSettings.Getter
---@alias LibSettings.OptGen   fun(interal: LibSettings.Setting) : LibSettings.Option[]
---@alias LibSettings.OptList  fun(options: LibSettings.Options) : LibSettings.Option[]
---@alias LibSettings.GetOpts  LibSettings.OptGen | LibSettings.OptList
---@alias LibSettings.Factory  fun(props: LibSettings.ListItem, parent: LibSettings.Result.Layout?, index: number, noCreate: boolean?): ...
---------------------------------------------------------------------------

    'Category',                   -- (category, group)
    'AddOnCategory',              -- (category)
    'Initializer',                -- (category, initializer)
    'AddOnSetting',               -- (categoryTbl, name, variable, variableType, defaultValue)
    'ProxySetting',               -- (categoryTbl, variable, variableTbl, variableType, name, defaultValue, getValue, setValue, commitValue)
    'CVarSetting',                -- (categoryTbl, variable, variableType, name)
    'ModifiedClickSetting'       -- (categoryTbl, variable, name, defaultValue)
}; local Types = Lib.Types;

function Lib:AddCustomType(name, factory, silent)
    local typeExists = not not self.Types[name];
    if typeExists and not silent then
        error(('Type already exists: %q'):format(tostring(name)), 2);
    end
    self.Types[name] = _();
    self.Factory[self.Types[name]] = factory;
end

---------------------------------------------------------------
-- Helpers
---------------------------------------------------------------
local Settings, CHILDREN, DELIMITER = Settings, 1, '.';
local DEF_ELEM_WIDTH, DEF_ELEM_HEIGHT = 280, 26;

local function CreateOptionsTable(options) ---@type LibSettings.OptList
    local container = Settings.CreateControlTextContainer();
    for _, option in ipairs(options) do
        container:Add(unpack(option));
    end
    return container:GetData();
end

local function CreateSliderOptions(props)
    local options = Settings.CreateSliderOptions(props.min, props.max, props.step);
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, props.format);
    return options;
end

---@return string|integer|nil
local function GenerateTableID(props, index)
    return props.id
        or props.variable
        or index
        or props.name;
end

local function GenerateUniqueVariableID(props, parent, index)
    local parentID = parent and parent.id;
    if props.variable then
        return props.variable;
    elseif props.id then
        return parentID and parentID .. DELIMITER .. props.id or props.id;
    elseif props.name then
        return parentID and parentID .. DELIMITER .. props.name or props.name;
    end
    return parentID and parentID .. DELIMITER .. index or index;
end

local function GetIdentity(props, parent, index)
    return
        props.name,
        GenerateTableID(props, index),
        GenerateUniqueVariableID(props, parent, index);
end

local function GetTableKey(props, setting)
    return props.key or props.id or setting:GetVariable();
end

---@param  props     LibSettings.Setting Properties of the setting
---@param  parent    LibSettings.Result.Layout Parent tree node of the setting
---@return LibSettings.Setter|nil set Callback function for setting a value, if any
local function MakeSetter(props, parent)
    if props.set then
        return props.set;
    elseif props.table then
        local function InternalGetTable()
            if type(props.table) == 'string' then
                return loadstring('return '..props.table)();
            else
                return props.table;
            end
        end
        return function(internal, setting, value)
            InternalGetTable()[GetTableKey(internal, setting)] = value;
        end
    elseif parent then
        return parent.setValue;
    end
end

---@param  props     LibSettings.Setting        Properties of the setting
---@param  parent    LibSettings.Result.Layout Parent tree node of the setting
---@return LibSettings.Getter|nil get Callback function for getting a value, if any
local function MakeGetter(props, parent)
    if props.get then
        return props.get;
    elseif props.table then
        local function InternalGetTable()
            if type(props.table) == 'string' then
                return loadstring('return '..props.table)();
            else
                return props.table;
            end
        end
        return function(internal, setting)
            return InternalGetTable()[GetTableKey(internal, setting)];
        end
    elseif parent then
        return parent.getValue;
    end
end

---@param  props     LibSettings.Setting Properties of the setting
---@param  setting   LibSettings.Widget  Setting object
---@param  set       LibSettings.Set     Callback function for setting a value
---@param  get       LibSettings.Get     Callback function for getting a value
---@return LibSettings.SetValue  set     Wrapped function for setting a value
---@return LibSettings.GetValue  get     Wrapped function for getting a value
local function MountSettingChanger(props, setting, set, get)
    local variable = setting:GetVariable();
    if set then
        Settings.SetOnValueChangedCallback(variable, set, props);
        set = GenerateClosure(setting.SetValue, setting);
    end
    if get then
        get = GenerateClosure(get, props, setting);
        setting:SetValue(get());
    end
    return set, get;
end

---@param  props     LibSettings.Type.DropDown Properties of the dropdown
---@return LibSettings.GetOpts   options Options table generator
local function MakeOptions(props)
    if type(props.options) == 'function' then
        return GenerateClosure(props.options, props) --[[@as LibSettings.OptGen]];
    else
        return GenerateClosure(CreateOptionsTable, props.options) --[[@as LibSettings.OptList]];
    end
end

local function GetCallbacks(props, parent)
    return
        MakeSetter(props, parent) --[[@as LibSettings.Set]],
        MakeGetter(props, parent) --[[@as LibSettings.Get]];
end

local PackPredicates, UnpackPredicates;
local SetParentInitializer, UnpackEvents;
local AddShownPredicates, AddModifyPredicates;
do
    local function __unpack(requiredType, predicate)
        if type(predicate) == requiredType then
            return ipairs{predicate};
        end
        assert(type(predicate) == 'function', ('Predicate must be a %s or table'):format(requiredType));
        return ipairs(predicate);
    end
    local function __pack(requiredType, tbl, key, predicate)
        if type(tbl[key]) == requiredType then
            tbl[key] = { tbl[key], predicate };
        elseif type(tbl[key]) == 'table' then
            tinsert(tbl[key], predicate);
        else
            tbl[key] = predicate;
        end
    end
    local function __add(method, unpack, init, predicates)
        if predicates then
            for _, predicate in unpack(predicates) do
                init[method](init, predicate);
            end
        end
    end

    PackEvents           = GenerateClosure(__pack,   'string')   --[[@as function]];
    UnpackEvents         = GenerateClosure(__unpack, 'string')   --[[@as function]];
    PackPredicates       = GenerateClosure(__pack,   'function') --[[@as function]];
    UnpackPredicates     = GenerateClosure(__unpack, 'function') --[[@as function]];
    AddStateFrameEvents  = GenerateClosure(__add,    'AddStateFrameEvent', UnpackEvents)       --[[@as function]];
    AddShownPredicates   = GenerateClosure(__add,    'AddShownPredicate',  UnpackPredicates)   --[[@as function]];
    AddModifyPredicates  = GenerateClosure(__add,    'AddModifyPredicate', UnpackPredicates)   --[[@as function]];

    local function ResolveAndSetParentInitializer(init, parent, modifier)
        if not modifier then
            local setting = parent.GetSetting and parent:GetSetting();
            if setting then
                if (setting:GetVariableType() == Settings.VarType.Boolean) then
                    modifier = function() return setting:GetValue() end;
                end
            end
        end
        init:SetParentInitializer(parent, modifier);
        return true;
    end

    function SetParentInitializer(init, parentResult, lookup, modifier)
        if type(lookup) == 'string' then
            assert(parentResult, ('Parent initializer %q not found in %q.'):format(lookup, init:GetName()));
            for key in lookup:gmatch('[^%.]+') do
                parentResult = parentResult[key];
                if not parentResult then
                    return false;
                end
            end
            if parentResult then
                return ResolveAndSetParentInitializer(init, parentResult.object, modifier);
            end
        end
    end
end

local function MountCommon(init, props, parent)
    AddShownPredicates(init, props.show)
    AddStateFrameEvents(init, props.event)
    if not SetParentInitializer(init, parent, props.parent, props.modify) then
        AddModifyPredicates(init, props.modify)
    end
end

---------------------------------------------------------------
-- Pools
---------------------------------------------------------------
local Pools = {}; Lib.Pools = Pools;

function Lib:AcquireFromPool(frameType, frameTemplate, parent, init)
    local poolID = frameType..'.'..frameTemplate;
    if not self.Pools[poolID] then
        self.Pools[poolID] = CreateFramePool(frameType, nil, frameTemplate);
    end
    local frame = self.Pools[poolID]:Acquire();
    frame:SetParent(parent);
    if init then
        init(frame);
    end
    return frame;
end

function Lib:ReleaseToPool(frameType, frameTemplate, frame)
    local poolID = frameType..'.'..frameTemplate;
    if self.Pools[poolID] then
        self.Pools[poolID]:Release(frame);
    end
end

---------------------------------------------------------------
-- Factory
---------------------------------------------------------------
-- Map of element types to factory functions.
-- Each factory function takes a props table tailored to the type of element,
-- and returns a result table containing the created widget, its unique identifier,
-- and its layout object, as well as any additional callbacks for setting and getting values.
---@type table<LibSettings.ListItem, LibSettings.Factory>
Lib.Factory = {
    -- Layouts
    --[[Types.AddOnCategory] = function(props)
        -- TODO
        local name, id = GetIdentity(props);
        local category, layout = Settings.GetCategory(name);
        return category, layout, id;
    end;]]

    [Types.VerticalLayoutCategory]
    ---@param  props  LibSettings.Category.Vertical
    ---@return LibSettings.Result.Layout
    = function(props)
        local name, id = GetIdentity(props);
        local set, get = GetCallbacks(props);
        local object, layout = Settings.RegisterVerticalLayoutCategory(name);
        return object, id, layout, set, get;
    end;

    [Types.CanvasLayoutCategory]
    ---@param  props  LibSettings.Category.Canvas
    ---@return LibSettings.Result.Layout
    = function(props)
        local name, id = GetIdentity(props);
        local set, get = GetCallbacks(props);
        local object, layout = Settings.RegisterCanvasLayoutCategory(props.frame, name);
        return object, id, layout, set, get;
    end;

    [Types.VerticalLayoutSubcategory]
    ---@param  props  LibSettings.Category.Vertical
    ---@return LibSettings.Result.Layout
    = function(props, parent, index)
        local name, id = GetIdentity(props, parent, index);
        local set, get = GetCallbacks(props, parent);
        local object, layout = Settings.RegisterVerticalLayoutSubcategory(parent.object, name);
        return object, id, layout, set, get;
    end;

    [Types.CanvasLayoutSubcategory]
    ---@param  props  LibSettings.Category.Canvas
    ---@return LibSettings.Result.Layout
    = function(props, parent, index)
        local name, id = GetIdentity(props, parent, index);
        local set, get = GetCallbacks(props, parent);
        local object, layout = Settings.RegisterCanvasLayoutSubcategory(parent.object, props.frame, name);
        return object, id, layout, set, get;
    end;

    -- Widgets
    [Types.Element]
    ---@param  props  LibSettings.Type.Element
    ---@return LibSettings.Result.Init
    = function(props, parent, index)
        local name, id, variable = GetIdentity(props, parent, index);
        local data = { name = name, variable = variable, tooltip = props.tooltip };
        local init = Settings.CreateElementInitializer('SettingsListElementTemplate', data);
        if not not props.search then
            init:AddSearchTags(name)
        end
        parent.layout:AddInitializer(init)

        init.GetExtent = function()
            return props.extent or props.height or DEF_ELEM_HEIGHT;
        end;

        init.InitFrame = function(initializer, self)
            SettingsListElementMixin.OnLoad(self)
            ScrollBoxFactoryInitializerMixin.InitFrame(initializer, self)
            self:SetSize(props.width or DEF_ELEM_WIDTH, props.height or DEF_ELEM_HEIGHT)
        end;

        MountCommon(init, props, parent)
        return init, id;
    end;

    [Types.CheckBox]
    ---@param  props  LibSettings.Type.CheckBox
    ---@return LibSettings.Result.Setting
    = function(props, parent, index, noCreate)
        local name, id, variable = GetIdentity(props, parent, index);
        local set, get = GetCallbacks(props, parent);
        local default = props.default;

        local setting, init = Settings.RegisterAddOnSetting(parent.object, name, variable, Settings.VarType.Boolean, default);
        if not noCreate then
            init = Settings.CreateCheckBox(parent.object, setting, props.tooltip);
            MountCommon(init, props, parent)
        end
        return init or setting, id, nil, MountSettingChanger(props, setting, set, get);
    end;

    [Types.Slider]
    ---@param  props  LibSettings.Type.Slider
    ---@return LibSettings.Result.Setting
    = function(props, parent, index, noCreate)
        local name, id, variable = GetIdentity(props, parent, index);
        local set, get = GetCallbacks(props, parent);
        local default  = props.default;
        local setting, init = Settings.RegisterAddOnSetting(parent.object, name, variable, Settings.VarType.Number, default);
        if not noCreate then
            init = Settings.CreateSlider(parent.object, setting, CreateSliderOptions(props), props.tooltip);
            MountCommon(init, props, parent)
        end
        return init or setting, id, nil, MountSettingChanger(props, setting, set, get);
    end;

    [Types.DropDown]
    ---@param  props  LibSettings.Type.DropDown
    ---@return LibSettings.Result.Setting
    = function(props, parent, index, noCreate)
        local name, id, variable = GetIdentity(props, parent, index);
        local set, get = GetCallbacks(props, parent);
        local default  = props.default;
        local setting, init = Settings.RegisterAddOnSetting(parent.object, name, variable, type(default), default);
        if not noCreate then
            init = Settings.CreateDropDown(parent.object, setting, MakeOptions(props), props.tooltip);
            MountCommon(init, props, parent)
        end
        return init or setting, id, nil, MountSettingChanger(props, setting, set, get);
    end;

    [Types.Binding]
    ---@param  props  LibSettings.Type.Binding
    ---@return LibSettings.Result.Init
    = function(props, parent, index)
        local name, id = GetIdentity(props, parent, index);
        local binding = props.binding;
        local search  = not not props.search;
        local entry   = C_KeyBindings.GetBindingIndex(binding)
        local init    = CreateKeybindingEntryInitializer(entry, search)
        if search then
            init:AddSearchTags(GetBindingName(binding), name)
        end
        parent.layout:AddInitializer(init)
        MountCommon(init, props, parent)
        return init, id;
    end;

    [Types.Button]
    ---@param  props  LibSettings.Type.Button
    ---@return LibSettings.Result.Init
    = function(props, parent, index)
        local name, id = GetIdentity(props, parent, index);
        local click   = props.click;
        local title   = props.title;
        local tooltip = props.tooltip;
        local search  = not not props.search;
        local init    = CreateSettingsButtonInitializer(name, title, click, tooltip, search)
        parent.layout:AddInitializer(init)
        MountCommon(init, props, parent)
        return init, id;
    end;

    [Types.Header]
    ---@param  props  LibSettings.Type.Header
    ---@return LibSettings.Result.Init
    = function(props, parent, index)
        local name, id = GetIdentity(props, parent, index);
        local init = CreateSettingsListSectionHeaderInitializer(name)
        parent.layout:AddInitializer(init)
        MountCommon(init, props, parent)
        return init, id;
    end;

    [Types.Spacer]
    ---@param  props  LibSettings.Type.Spacer
    ---@return LibSettings.Result.Init
    = function(props, parent, index)
        local _, id = GetIdentity(props, parent, index);
        local init = Settings.CreateElementInitializer('SettingsCategoryListSpacerTemplate', {})
        parent.layout:AddInitializer(init)
        MountCommon(init, props, parent)
        return init, id;
    end;

    [Types.CheckBoxSlider]
    ---@param  props  LibSettings.Type.CheckBoxSlider
    ---@return LibSettings.Result.Combined
    = function(props, parent, index)
        local cbSetting, id, _, cbSet, cbGet = Lib.Factory[Lib.Types.CheckBox](
            props --[[@as LibSettings.Type.CheckBox]], parent, index, true);
        local cbLabel, cbTooltip, cbProps = props.name, props.tooltip, props;

        props = tremove(props, CHILDREN);
        local slSetting, _, _, slSet, slGet = Lib.Factory[Lib.Types.Slider](
            props --[[@as LibSettings.Type.Slider]], parent, index, true);
        local slLabel, slTooltip = props.name, props.tooltip;

        local init = CreateSettingsCheckBoxSliderInitializer(
            cbSetting, cbLabel, cbTooltip,
            slSetting, CreateSliderOptions(props), slLabel, slTooltip
        );
        parent.layout:AddInitializer(init)
        MountCommon(init, cbProps)
        MountCommon(init, props, parent)

        cbSet, cbGet = cbSet or nop, cbGet or nop;
        slSet, slGet = slSet or nop, slGet or nop;
        return init, id, nil, cbSet, cbGet, slSet, slGet;
    end;

    [Types.CheckBoxDropDown]
    ---@param  props  LibSettings.Type.CheckBoxDropDown
    ---@return LibSettings.Result.Combined
    = function(props, parent, index)
        local cbSetting, id, _, cbSet, cbGet = Lib.Factory[Lib.Types.CheckBox](
            props --[[@as LibSettings.Type.CheckBox]], parent, index, true);
        local cbLabel, cbTooltip, cbProps = props.name, props.tooltip, props;

        props = tremove(props, CHILDREN);
        local ddSetting, _, _, ddSet, ddGet = Lib.Factory[Lib.Types.DropDown](
            props --[[@as LibSettings.Type.DropDown]], parent, index, true);
        local ddLabel, ddTooltip = props.name, props.tooltip;
        local init = CreateSettingsCheckBoxDropDownInitializer(
            cbSetting, cbLabel, cbTooltip,
            ddSetting, MakeOptions(props), ddLabel, ddTooltip
        );
        parent.layout:AddInitializer(init)
        MountCommon(init, cbProps)
        MountCommon(init, props, parent)

        cbSet, cbGet = cbSet or nop, cbGet or nop;
        ddSet, ddGet = ddSet or nop, ddGet or nop;
        return init, id, nil, cbSet, cbGet, ddSet, ddGet;
    end;

    -- Custom types
    [Types.ExpandableSection]
    = (function()
        local ExpandableSectionMixin = {};

        function ExpandableSectionMixin:OnExpandedChanged(expanded)
            if expanded then
                self.Button.Right:SetAtlas('Options_ListExpand_Right_Expanded', TextureKitConstants.UseAtlasSize);
            else
                self.Button.Right:SetAtlas('Options_ListExpand_Right', TextureKitConstants.UseAtlasSize);
            end
            SettingsInbound.RepairDisplay()
        end

        -- TODO: what if child is a canvas?
        function ExpandableSectionMixin:CalculateHeight() return DEF_ELEM_HEIGHT end;
        ExpandableSectionMixin.GetExtent = ExpandableSectionMixin.CalculateHeight;

        ---@param  props  LibSettings.Type.ExpandableSection
        ---@return LibSettings.Result.Init ...
        return function(props, parent, index)
            local name, _, variable = GetIdentity(props, parent, index);
            local init = CreateSettingsExpandableSectionInitializer(name)
            local data = init.data;

            parent.layout:AddInitializer(init)

            data.expanded = props.expanded;
            Mixin(init, ExpandableSectionMixin)

            local function ShouldShowDescendant()
                return data.expanded;
            end

            for i, child in ipairs(props[CHILDREN] or {}) do
                PackPredicates(child, 'show', ShouldShowDescendant);
            end

            local elementInitializer = init.InitFrame;
            init.InitFrame = function(this, self)
                elementInitializer(this, self)
                if not data.initialized then
                    data.initialized = true;
                    Mixin(self, ExpandableSectionMixin);
                end
            end;
            return parent.object, variable, parent.layout;
        end
    end)() --[[@as LibSettings.Factory]];

    [Types.Key]
    = (function()
        local CustomBindingManager, CustomBindingButtonMixin = CreateFromMixins(CustomBindingManager), CreateFromMixins(CustomBindingButtonMixin);
        CustomBindingManager.handlers     = {};
        CustomBindingManager.systems      = {};
        CustomBindingManager.pendingBinds = {};

        local CreateKeyChordStringFromTable = CreateKeyChordStringFromTable;
        local CreateKeyChordTableFromString = function(keyChordString)
            local keyChordTable = {};
            for key in keyChordString:gmatch('[^%-]+') do
                tinsert(keyChordTable, key);
            end
            return keyChordTable;
        end

        local FilterAgnostic = function(props, keyChordString)
            if not props.agnostic then
                return keyChordString;
            end
            local keyChordTable = CreateKeyChordTableFromString(keyChordString);
            for i, key in ipairs(keyChordTable) do
                keyChordTable[i] = IsMetaKey(key) and (key:gsub('^[LR]', '')) or key;
            end
            return CreateKeyChordStringFromTable(keyChordTable);
        end

        local FilterSingle = function(props, keyChordString)
            if props.single then
                return (keyChordString:match('[^%-]+$'));
            end
            return keyChordString;
        end

        function CustomBindingButtonMixin:OnInput(key, isDown)
            local isButtonRelease = not isDown;
            if not self:IsBindingModeActive() then
                if isButtonRelease then
                    self:EnableKeyboard(false);
                end
                return;
            end
            key = GetConvertedKeyOrButton(key);
            if isDown then
                if key == 'ESCAPE' then
                    self:CancelBinding();
                    return;
                end
                if not IsMetaKey(key) then
                    self.receivedNonMetaKeyInput = true;
                end
                tinsert(self.keys, key);
            end
            CustomBindingManager:SetPendingBind(self:GetCustomBindingType(), self.keys);
            if self.receivedNonMetaKeyInput or isButtonRelease then
                self:NotifyBindingCompleted(true, self.keys);
                if isButtonRelease then
                    self:EnableKeyboard(false);
                end
            end
        end

        function CustomBindingButtonMixin:SetBindingModeActive(isActive, preventBindingManagerUpdate)
            self.isBindingModeActive = isActive;
            self.receivedNonMetaKeyInput = false;
            self.keys = {};
            BindingButtonTemplate_SetSelected(self, isActive);
            if isActive then
                self:RegisterForClicks('AnyDown', 'AnyUp');
                self:EnableKeyboard(true);
            else
                self:RegisterForClicks('LeftButtonUp', 'RightButtonUp');
            end
            if not preventBindingManagerUpdate then
                CustomBindingManager:OnBindingModeActive(self, isActive);
            end
        end

        function CustomBindingButtonMixin:NotifyBindingCompleted(completedSuccessfully, keys)
            CustomBindingManager:OnBindingCompleted(self, completedSuccessfully, keys);
            self:SetBindingModeActive(false);
        end

        return function(props, parent, index)
            local init, id = Lib.Factory[Types.Element](props, parent, index);
            local data = init:GetData();
            local setting = Settings.RegisterAddOnSetting(parent.object, data.variable, Settings.VarType.String, props.default);
            init:SetSetting(setting);
            local set, get = GetCallbacks(props, parent);
            set, get = MountSettingChanger(props, setting, set, get);

            CustomBindingManager:AddSystem(setting,
                function()  return CreateKeyChordTableFromString(get()) end,
                function(keys) set(FilterSingle(props, FilterAgnostic(props, CreateKeyChordStringFromTable(keys)))) end
            );
            local handler = CustomBindingHandler:CreateHandler(setting);

            handler:SetOnBindingModeActivatedCallback(function(isActive)
                if isActive then
                    SettingsPanel.OutputText:SetFormattedText(BIND_KEY_TO_COMMAND, data.name);
                end
            end);

            handler:SetOnBindingCompletedCallback(function(completedSuccessfully, keys)
                CustomBindingManager:OnDismissed(setting, completedSuccessfully)
                if completedSuccessfully then
                    SettingsPanel.OutputText:SetText(KEY_BOUND);
                    local finalValue = GetBindingText(get());
                    for handler, button in CustomBindingManager:EnumerateHandlers(setting) do
                        button:OnBindingTextChanged(finalValue);
                    end
                end
            end);

            local elementInitializer = init.InitFrame;
            init.InitFrame = function(initializer, self)
                elementInitializer(initializer, self);
                self.CustomBindingButton = Lib:AcquireFromPool('Button', 'CustomBindingButtonTemplate', self, function(self)
                    Mixin(self, CustomBindingButtonMixin)
                    self:SetCustomBindingHandler(handler)
                    self:SetCustomBindingType(setting)
                    CustomBindingManager:SetHandlerRegistered(self, true)
                    self:SetWidth(200)
                    self:Show()
                    local bindingText = CustomBindingManager:GetBindingText(self:GetCustomBindingType())
                    if bindingText then
                        self:SetText(bindingText);
                        self:SetAlpha(1);
                    else
                        self:SetText(GRAY_FONT_COLOR:WrapTextInColorCode(NOT_BOUND));
                        self:SetAlpha(0.8);
                    end
                end)
                self.CustomBindingButton:SetPoint('LEFT', self, 'CENTER', -80, 0)
            end;

            local elementResetter = init.Resetter;
            init.Resetter = function(initializer, self)
                elementResetter(initializer, self);
                CustomBindingManager:SetHandlerRegistered(self.CustomBindingButton, false)
                Lib:ReleaseToPool('Button', 'CustomBindingButtonTemplate', self.CustomBindingButton)
                self.CustomBindingButton = nil;
            end;

            return init, id, nil, set, get;
        end
    end)() --[[@as LibSettings.Factory]];
}; local Factory = Lib.Factory;

local function ResolveType(props, parent)
    if not parent then
        if props.frame then
            return Factory[Types.CanvasLayoutCategory];
        else
            return Factory[Types.VerticalLayoutCategory];
        end
    elseif props.options then
        return Factory[Types.DropDown];
    elseif props.step then
        return Factory[Types.Slider];
    elseif type(props.default) == 'boolean' then
        if props[CHILDREN] then
            if props[CHILDREN].options then
                return Factory[Types.CheckBoxDropDown];
            elseif props[CHILDREN].step then
                return Factory[Types.CheckBoxSlider];
            end
            return Factory[Types.CheckBoxSlider];
        end
        return Factory[Types.CheckBox];
    elseif props.binding then
        return Factory[Types.Binding];
    elseif not props[CHILDREN] then
        return Factory[Types.Header];
    elseif props.frame then
        return Factory[Types.CanvasLayoutSubcategory];
    else
        return Factory[Types.VerticalLayoutSubcategory];
    end
end

---------------------------------------------------------------
-- Create
---------------------------------------------------------------
-- @param props            table    Properties of the widget
-- @param parent           table    Parent tree node
-- @param index            number   Index of the widget in the parent tree node
-- @return result          table    Nested table of created widgets
-- @return result.object   table    Widget object that was created
-- @return result.id       string   Unique identifier of the object
-- @return result.layout   table    Layout object that was created
-- @return result.set      function Callback function for setting a value
-- @return result.get      function Callback function for getting a value
-- @return result.setOption function Callback function for setting an option
-- @return result.getOption function Callback function for getting an option
-- @return result.children table    Nested table of created child widgets
---------------------------------------------------------------
local function Create(props, parent, index)
    local type, result = props.type, {parent = parent, index = index};
    local factory = type and Factory[type] or ResolveType(props, parent);
    if factory then
        result.object,    -- @param object table Widget object that was created
        result.id,        -- @param id     string Unique identifier of the object
        result.layout,    -- @param layout table  Layout object that was created
        result.setValue,  -- @param set    function Callback function for setting a value
        result.getValue,  -- @param get    function Callback function for getting a value
        result.setOption, -- @param setOption function Callback function for setting an option
        result.getOption  -- @param getOption function Callback function for getting an option
        = factory(props, parent, index);
    end
    local children = props[CHILDREN];
    if children then
        result.children = {};
        for i, child in ipairs(children) do
            local childResult = Create(child, result, i);
            local childName   = childResult.id;
            if childName then
                result.children[childName] = childResult;
            elseif childResult then
                tinsert(result.children, childResult)
            end
        end
        setmetatable(result, { __index = result.children })
    end
    return result;
end

function Lib:Create(props, owner, layout)
    local result = Create(props, owner, layout)
    Settings.RegisterAddOnCategory(result.object)
    return result;
end

function Lib:Get(id)
    -- TODO
end

setmetatable(Lib, {
    __call  = Lib.Create;
    __index = Lib.Get;
})

Test_SavedVars = {testCheckBox = false, testSlider = 190, selection = 2, testCheckBox2 = true, testKey = 'ALT-SHIFT-A'}

res = Lib({
    name  = 'ConsolePort';
    type  = Lib.Types.VerticalLayoutCategory;
    table = Test_SavedVars;
    {
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
            id   = 'expandableSection';
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