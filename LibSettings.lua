---@class LibSettings
local Lib = LibStub:NewLibrary('LibSettings', 0.1)
if not Lib then return end; local _ = CreateCounter();
---------------------------------------------------------------------------------------
Lib.Types                       =  {--[[@enum (key) Types                            ]]
---------------------------------------------------------------------------------------
    -- Widgets
    Binding                     =_()--[[@as LibSettings.Types.Binding               ]];
    Button                      =_()--[[@as LibSettings.Types.Button                ]];
    CheckBox                    =_()--[[@as LibSettings.Types.CheckBox              ]];
    CheckBoxDropDown            =_()--[[@as LibSettings.Types.CheckBoxDropDown      ]];
    CheckBoxSlider              =_()--[[@as LibSettings.Types.CheckBoxSlider        ]];
    Color                       =_()--[[@as LibSettings.Types.Color                 ]];
    DropDown                    =_()--[[@as LibSettings.Types.DropDown              ]];
    Element                     =_()--[[@as LibSettings.Types.Element               ]];
    Header                      =_()--[[@as LibSettings.Types.Header                ]];
    Key                         =_()--[[@as LibSettings.Types.Key                   ]];
    Slider                      =_()--[[@as LibSettings.Types.Slider                ]];
    Spacer                      =_()--[[@as LibSettings.Types.Spacer                ]];
    -- Containers
    CanvasLayoutCategory        =_()--[[@as LibSettings.Category.Canvas             ]];
    CanvasLayoutSubcategory     =_()--[[@as LibSettings.Category.Canvas             ]];
    VerticalLayoutCategory      =_()--[[@as LibSettings.Category.Vertical           ]];
    VerticalLayoutSubcategory   =_()--[[@as LibSettings.Category.Vertical           ]];
    ExpandableSection           =_()--[[@as LibSettings.Types.ExpandableSection     ]];
---------------------------------------------------------------------------------------
};

--[[ TODO?
    'Category',                   -- (category, group)
    'AddOnCategory',              -- (category)
    'Initializer',                -- (category, initializer)
    'ProxySetting',               -- (categoryTbl, variable, variableTbl, variableType, name, defaultValue, getValue, setValue, commitValue)
    'CVarSetting',                -- (categoryTbl, variable, variableType, name)
    'ModifiedClickSetting'       -- (categoryTbl, variable, name, defaultValue)
]]

function Lib:AddCustomType(name, factory, silent)
    local typeExists = not not self.Types[name];
    if typeExists and not silent then
        error(('Type already exists: %q'):format(tostring(name)), 2);
    end
    self.Types[name] = _();
    self.Factory[self.Types[name]] = factory;
end

local Types = Lib.Types;

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

local MakeSetter, MakeGetter;
do -- Closure generators for setting and getting values.
    local function __key(props, setting)
        return props.key or props.id or setting:GetVariable();
    end

    local function __table(props)
        if type(props.table) == 'string' then
            local tbl = loadstring('return '..props.table)();
            assert(type(tbl) == 'table', ('Evaluated string %q must return a table.'):format(props.table));
            return tbl;
        else
            return props.table;
        end
    end

    ---@param  props     LibSettings.Setting Properties of the setting
    ---@param  parent    LibSettings.Result.Layout Parent tree node of the setting
    ---@return LibSettings.Setter|nil set Callback function for setting a value, if any
    function MakeSetter(props, parent)
        if props.set then
            return props.set;
        elseif props.table then
            return function(internal, setting, value)
                __table(props)[__key(internal, setting)] = value;
            end
        elseif parent then
            return parent.setValue;
        end
    end

    ---@param  props     LibSettings.Setting        Properties of the setting
    ---@param  parent    LibSettings.Result.Layout Parent tree node of the setting
    ---@return LibSettings.Getter|nil get Callback function for getting a value, if any
    function MakeGetter(props, parent)
        if props.get then
            return props.get;
        elseif props.table then
            return function(internal, setting)
                return __table(props)[__key(internal, setting)];
            end
        elseif parent then
            return parent.getValue;
        end
    end
end

---@param  props     LibSettings.Setting Properties of the setting
---@param  setting   Blizzard.Setting    Setting object
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

---@param  props     LibSettings.Types.DropDown Properties of the dropdown
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

local PackPredicates, AddShownPredicates, AddModifyPredicates, AddStateFrameEvents, SetParentInitializer, AddAnchorPoints;
do -- Closure generators for packing and unpacking predicates and events.
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
    local function __addtbl(method, _unpack, init, predicates)
        if predicates then
            for key, predicate in _unpack(predicates) do
                init[method](init, unpack(predicate));
            end
        end
    end

    local UnpackPredicates, UnpackEvents, UnpackAnchors;

    UnpackEvents         = GenerateClosure(__unpack, 'string')   --[[@as function]];
    PackPredicates       = GenerateClosure(__pack,   'function') --[[@as function]];
    UnpackPredicates     = GenerateClosure(__unpack, 'function') --[[@as function]];
    UnpackAnchors        = GenerateClosure(__unpack, 'table')    --[[@as function]];
    AddStateFrameEvents  = GenerateClosure(__add,    'AddStateFrameEvent', UnpackEvents)       --[[@as function]];
    AddShownPredicates   = GenerateClosure(__add,    'AddShownPredicate',  UnpackPredicates)   --[[@as function]];
    AddModifyPredicates  = GenerateClosure(__add,    'AddModifyPredicate', UnpackPredicates)   --[[@as function]];
    AddAnchorPoints      = GenerateClosure(__addtbl, 'AddAnchorPoint',     UnpackAnchors)      --[[@as function]];

    local function ResolveAndSetParentInitializer(init, parent, modifier)
        if not modifier then
            local setting = parent.GetSetting and parent:GetSetting();
            if setting then
                if (setting:GetVariableType() == Settings.VarType.Boolean) then
                    -- If the parent is a checkbox, we want to enable the child if the parent is checked.
                    modifier = GenerateClosure(setting.GetValue, setting);
                end
            end
        end
        init:SetParentInitializer(parent, modifier);
        return true;
    end

    function SetParentInitializer(init, parentResult, lookup, modifier)
        if type(lookup) == 'string' then
            local errorMsg = ('Parent initializer %q not found in %q.'):format(lookup, init:GetName());
            for key in lookup:gmatch('[^%.]+') do
                assert(parentResult, errorMsg);
                parentResult = parentResult[key];
            end
            return ResolveAndSetParentInitializer(init, parentResult.object, modifier);
        end
    end
end

-- Common mounting function for all initializers.
local function MountCommon(init, props, parent)
    AddShownPredicates(init, props.show);
    AddStateFrameEvents(init, props.event);
    if not SetParentInitializer(init, parent, props.parent, props.modify) then
        AddModifyPredicates(init, props.modify);
    end
    if props.new then
        local setting = init.GetSetting and init:GetSetting();
        if setting then
            setting:SetNewTagShown(true);
        end
    end
end

---------------------------------------------------------------
-- Pools
---------------------------------------------------------------
local Pools = {}; Lib.Pools = Pools;

function Lib:AcquireFromPool(wType, wTemplate, init, parent, ...)
    local poolID = wType..'.'..tostring(wTemplate);
    if not self.Pools[poolID] then
        if wType:match('Texture') then
            self.Pools[poolID] = CreateTexturePool(UIParent, wTemplate, ...);
        elseif wType:match('FontString') then
            self.Pools[poolID] = CreateFontStringPool(UIParent, wTemplate, ...);
        else
            self.Pools[poolID] = CreateFramePool(wType, nil, wTemplate, ...);
        end
    end
    local widget = self.Pools[poolID]:Acquire();
    widget:SetParent(parent);
    if init then
        init(widget);
    end
    return widget;
end

function Lib:ReleaseToPool(wType, wTemplate, widget)
    local poolID = wType..'.'..tostring(wTemplate);
    if self.Pools[poolID] then
        self.Pools[poolID]:Release(widget);
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
    -- TODO?
    --[[Types.AddOnCategory] = function(props)
        local name, id = GetIdentity(props);
        local category, layout = Settings.GetCategory(name);
        return category, layout, id;
    end;]]

    -- Layouts
    [Types.VerticalLayoutCategory]
    ---@param  props  LibSettings.Category.Vertical
    ---@return LibSettings.Result.Layout
    = function(props)
        local name, id = GetIdentity(props);
        local set, get = GetCallbacks(props);
        local init, layout = Settings.RegisterVerticalLayoutCategory(name);
        return init, id, layout, set, get;
    end;

    [Types.CanvasLayoutCategory]
    ---@param  props  LibSettings.Category.Canvas
    ---@return LibSettings.Result.Layout
    = function(props)
        local name, id = GetIdentity(props);
        local set, get = GetCallbacks(props);
        local init, layout = Settings.RegisterCanvasLayoutCategory(props.frame, name);
        AddAnchorPoints(init, props.anchor);
        return init, id, layout, set, get;
    end;

    [Types.VerticalLayoutSubcategory]
    ---@param  props  LibSettings.Category.Vertical
    ---@return LibSettings.Result.Layout
    = function(props, parent, index)
        local name, id = GetIdentity(props, parent, index);
        local set, get = GetCallbacks(props, parent);
        local init, layout = Settings.RegisterVerticalLayoutSubcategory(parent.object, name);
        return init, id, layout, set, get;
    end;

    [Types.CanvasLayoutSubcategory]
    ---@param  props  LibSettings.Category.Canvas
    ---@return LibSettings.Result.Layout
    = function(props, parent, index)
        local name, id = GetIdentity(props, parent, index);
        local set, get = GetCallbacks(props, parent);
        local init, layout = Settings.RegisterCanvasLayoutSubcategory(parent.object, props.frame, name);
        AddAnchorPoints(init, props.anchor);
        return init, id, layout, set, get;
    end;

    -- Widgets
    [Types.Element]
    ---@param  props  LibSettings.Types.Element
    ---@return LibSettings.Result.Init
    = function(props, parent, index)
        local name, id, variable = GetIdentity(props, parent, index);
        local data = { name = name, variable = variable, tooltip = props.tooltip };
        local init = Settings.CreateElementInitializer('SettingsListElementTemplate', data);
        if not not props.search then
            init:AddSearchTags(name);
        end
        parent.layout:AddInitializer(init);

        init.GetExtent = function()
            return props.extent or props.height or DEF_ELEM_HEIGHT;
        end;

        init.InitFrame = function(initializer, self)
            SettingsListElementMixin.OnLoad(self);
            ScrollBoxFactoryInitializerMixin.InitFrame(initializer, self);
            self:SetSize(props.width or DEF_ELEM_WIDTH, props.height or DEF_ELEM_HEIGHT);
        end;

        MountCommon(init, props, parent)
        return init, id;
    end;

    [Types.CheckBox]
    ---@param  props  LibSettings.Types.CheckBox
    ---@return LibSettings.Result.Setting
    = function(props, parent, index, noCreate)
        local name, id, variable = GetIdentity(props, parent, index);
        local set, get = GetCallbacks(props, parent);
        local default = props.default;

        local setting, init = Settings.RegisterAddOnSetting(parent.object, name, variable, Settings.VarType.Boolean, default);
        if not noCreate then
            init = Settings.CreateCheckBox(parent.object, setting, props.tooltip);
            MountCommon(init, props, parent);
        end
        return init or setting, id, nil, MountSettingChanger(props, setting, set, get);
    end;

    [Types.Slider]
    ---@param  props  LibSettings.Types.Slider
    ---@return LibSettings.Result.Setting
    = function(props, parent, index, noCreate)
        local name, id, variable = GetIdentity(props, parent, index);
        local set, get = GetCallbacks(props, parent);
        local default  = props.default;
        local setting, init = Settings.RegisterAddOnSetting(parent.object, name, variable, Settings.VarType.Number, default);
        if not noCreate then
            init = Settings.CreateSlider(parent.object, setting, CreateSliderOptions(props), props.tooltip);
            MountCommon(init, props, parent);
        end
        return init or setting, id, nil, MountSettingChanger(props, setting, set, get);
    end;

    [Types.DropDown]
    ---@param  props  LibSettings.Types.DropDown
    ---@return LibSettings.Result.Setting
    = function(props, parent, index, noCreate)
        local name, id, variable = GetIdentity(props, parent, index);
        local set, get = GetCallbacks(props, parent);
        local default  = props.default;
        local setting, init = Settings.RegisterAddOnSetting(parent.object, name, variable, type(default), default);
        if not noCreate then
            init = Settings.CreateDropDown(parent.object, setting, MakeOptions(props), props.tooltip);
            MountCommon(init, props, parent);
        end
        return init or setting, id, nil, MountSettingChanger(props, setting, set, get);
    end;

    [Types.Binding]
    ---@param  props  LibSettings.Types.Binding
    ---@return LibSettings.Result.Init
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
    end;

    [Types.Button]
    ---@param  props  LibSettings.Types.Button
    ---@return LibSettings.Result.Init
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
    end;

    [Types.Header]
    ---@param  props  LibSettings.Types.Header
    ---@return LibSettings.Result.Init
    = function(props, parent, index)
        local name, id = GetIdentity(props, parent, index);
        local init = CreateSettingsListSectionHeaderInitializer(name);
        parent.layout:AddInitializer(init);
        MountCommon(init, props, parent);
        return init, id;
    end;

    [Types.Spacer]
    ---@param  props  LibSettings.Types.Spacer
    ---@return LibSettings.Result.Init
    = function(props, parent, index)
        local _, id = GetIdentity(props, parent, index);
        local init = Settings.CreateElementInitializer('SettingsCategoryListSpacerTemplate', {});
        parent.layout:AddInitializer(init);
        MountCommon(init, props, parent);
        return init, id;
    end;

    [Types.CheckBoxSlider]
    ---@param  props  LibSettings.Types.CheckBoxSlider
    ---@return LibSettings.Result.Combined
    = function(props, parent, index)
        local cbSetting, id, _, cbSet, cbGet = Lib.Factory[Lib.Types.CheckBox](
            props --[[@as LibSettings.Types.CheckBox]], parent, index, true);
        local cbLabel, cbTooltip, cbProps = props.name, props.tooltip, props;

        props = tremove(props, CHILDREN);
        local slSetting, _, _, slSet, slGet = Lib.Factory[Lib.Types.Slider](
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
    end;

    [Types.CheckBoxDropDown]
    ---@param  props  LibSettings.Types.CheckBoxDropDown
    ---@return LibSettings.Result.Combined
    = function(props, parent, index)
        local cbSetting, id, _, cbSet, cbGet = Lib.Factory[Lib.Types.CheckBox](
            props --[[@as LibSettings.Types.CheckBox]], parent, index, true);
        local cbLabel, cbTooltip, cbProps = props.name, props.tooltip, props;

        props = tremove(props, CHILDREN);
        local ddSetting, _, _, ddSet, ddGet = Lib.Factory[Lib.Types.DropDown](
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
            SettingsInbound.RepairDisplay();
        end

        -- TODO: what if child is a canvas?
        function ExpandableSectionMixin:CalculateHeight() return DEF_ELEM_HEIGHT end;
        ExpandableSectionMixin.GetExtent = ExpandableSectionMixin.CalculateHeight;

        ---@param  props  LibSettings.Types.ExpandableSection
        ---@return LibSettings.Result.Init ...
        return function(props, parent, index)
            local name, _, variable = GetIdentity(props, parent, index);
            local init = CreateSettingsExpandableSectionInitializer(name);
            local data = init.data;

            parent.layout:AddInitializer(init);

            data.expanded = props.expanded;
            Mixin(init, ExpandableSectionMixin);

            local function IsExpanded() return data.expanded end;
            for i, child in ipairs(props[CHILDREN] or {}) do
                PackPredicates(child, 'show', IsExpanded);
            end

            local elementInitializer = init.InitFrame;
            init.InitFrame = function(this, self)
                elementInitializer(this, self);
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
                    self:EnableInputs(false);
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
                    self:EnableInputs(false);
                end
            end
        end

        function CustomBindingButtonMixin:EnableInputs(enabled)
            self:EnableKeyboard(enabled);
            self:EnableGamePadButton(enabled);
        end

        function CustomBindingButtonMixin:SetBindingModeActive(isActive, preventBindingManagerUpdate)
            self.isBindingModeActive = isActive;
            self.receivedNonMetaKeyInput = false;
            self.keys = {};
            BindingButtonTemplate_SetSelected(self, isActive);
            if isActive then
                self:RegisterForClicks('AnyDown', 'AnyUp');
                self:EnableInputs(true);
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

        local function OnKeySettingChanged(_, setting, value)
            local finalValue = GetBindingText(value);
            for _, button in CustomBindingManager:EnumerateHandlers(setting) do
                button:OnBindingTextChanged(finalValue);
            end
        end

        ---@param  props  LibSettings.Types.Key
        ---@return LibSettings.Result.Init ...
        return function(props, parent, index)
            local init, id = Lib.Factory[Types.Element](props, parent, index);
            local data = init:GetData();
            local setting = Settings.RegisterAddOnSetting(parent.object, data.name, data.variable, Settings.VarType.String, props.default);
            init:SetSetting(setting);
            local set, get = MountSettingChanger(props, setting, GetCallbacks(props, parent));

            CustomBindingManager:AddSystem(setting,
                function() return CreateKeyChordTableFromString(get()) end,
                function(keys) set(FilterSingle(props, FilterAgnostic(props, CreateKeyChordStringFromTable(keys)))) end
            );

            local handler = CustomBindingHandler:CreateHandler(setting);
            data.OnSettingValueChanged = OnKeySettingChanged;

            handler:SetOnBindingModeActivatedCallback(function(isActive)
                if isActive then
                    SettingsPanel.OutputText:SetFormattedText(BIND_KEY_TO_COMMAND, data.name);
                end
            end);

            handler:SetOnBindingCompletedCallback(function(completedSuccessfully, keys)
                CustomBindingManager:OnDismissed(setting, completedSuccessfully)
                if completedSuccessfully then
                    SettingsPanel.OutputText:SetText(KEY_BOUND);
                end
            end);

            local elementInitializer = init.InitFrame;
            init.InitFrame = function(initializer, self)
                elementInitializer(initializer, self);
                self.cbrHandles:SetOnValueChangedCallback(setting:GetVariable(), data.OnSettingValueChanged, self);
                data.button = Lib:AcquireFromPool('Button', 'CustomBindingButtonTemplate', function(button)
                    Mixin(button, CustomBindingButtonMixin);
                    button:SetCustomBindingHandler(handler);
                    button:SetCustomBindingType(setting);
                    CustomBindingManager:SetHandlerRegistered(button, true);
                    button:SetWidth(200);
                    button:Show();
                    button:EnableInputs(false);
                    local bindingText = CustomBindingManager:GetBindingText(button:GetCustomBindingType());
                    if bindingText then
                        button:SetText(bindingText);
                        button:SetAlpha(1);
                    else
                        button:SetText(GRAY_FONT_COLOR:WrapTextInColorCode(NOT_BOUND));
                        button:SetAlpha(0.8);
                    end
                end, self);
                data.button:SetPoint('LEFT', self, 'CENTER', -80, 0);
            end;

            local elementResetter = init.Resetter;
            init.Resetter = function(initializer, self)
                elementResetter(initializer, self);
                CustomBindingManager:SetHandlerRegistered(data.button, false);
                Lib:ReleaseToPool('Button', 'CustomBindingButtonTemplate', data.button);
                data.button = nil;
            end;

            return init, id, nil, set, get;
        end
    end)() --[[@as LibSettings.Factory]];

    [Types.Color]
    = (function()
        local function GetRGBAHexStringFromColor(color)
            local r, g, b, a = color:GetRGBAAsBytes();
            return ('%.2x%.2x%.2x%.2x'):format(a, r, g, b);
        end

        local function OnColorChanged(color, set)
            local r, g, b = ColorPickerFrame:GetColorRGB();
            local a = ColorPickerFrame:GetColorAlpha();
            color:SetRGBA(r, g, b, a);
            set(GetRGBAHexStringFromColor(color));
        end

        local function OnColorCancel(color, set)
            local r, g, b, a = ColorPickerFrame:GetPreviousValues();
            color:SetRGBA(r, g, b, a);
            set(GetRGBAHexStringFromColor(color));
        end

        local function OnColorButtonClick(data, set)
            local color = data.color;
            local r, g, b, a = color:GetRGBA();
            local onColorChanged = GenerateClosure(OnColorChanged, color, set);
            ColorPickerFrame:SetupColorPickerAndShow({
                hasOpacity  = true;
                swatchFunc  = onColorChanged;
                opacityFunc = onColorChanged;
                cancelFunc  = GenerateClosure(OnColorCancel, color, set);
                r = r; g = g; b = b; opacity = a;
            })
        end

        local function OnColorSettingChanged(data, set, _, _, value)
            data.color = CreateColorFromHexString(value);
            data.text:SetText(data.color:WrapTextInColorCode(value:upper()));
            data.swatch:SetVertexColor(data.color:GetRGBA());
            set(value);
        end

        ---@param  props  LibSettings.Types.Color
        ---@return LibSettings.Result.Init ...
        return function(props, parent, index)
            local init, id = Lib.Factory[Types.Element](props, parent, index);
            local data = init:GetData();
            local setting = Settings.RegisterAddOnSetting(parent.object, data.name, data.variable, Settings.VarType.String, props.default);
            init:SetSetting(setting);
            local set, get = MountSettingChanger(props, setting, GetCallbacks(props, parent));

            data.color = CreateColorFromHexString(get());
            data.OnSettingValueChanged = GenerateClosure(OnColorSettingChanged, data, set);

            local elementInitializer = init.InitFrame;
            init.InitFrame = function(initializer, self)
                elementInitializer(initializer, self);
                self.cbrHandles:SetOnValueChangedCallback(setting:GetVariable(), data.OnSettingValueChanged, self);
                data.button = Lib:AcquireFromPool('Button', nil, function(button)
                    data.swatch = Lib:AcquireFromPool('Texture', 'OVERLAY', function(swatch)
                        swatch:SetPoint('TOPLEFT', button, 'TOPLEFT', -6, 6);
                        swatch:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', 6, -6);
                        swatch:SetTexture('Interface\\ChatFrame\\ChatFrameColorSwatch');
                        swatch:Show();
                        swatch:SetVertexColor(data.color:GetRGBA());
                    end, self);
                    data.background = Lib:AcquireFromPool('Texture', 'BACKGROUND', function(background)
                        background:SetColorTexture(1, 1, 1);
                        background:SetAllPoints(button);
                        background:Show();
                    end, self);
                    data.checkers = Lib:AcquireFromPool('Texture', 'BACKGROUND', function(checkers)
                        checkers:SetTexture(188523); -- Tileset\\Generic\\Checkers
                        checkers:SetTexCoord(.25, 0, 0.5, .25);
                        checkers:SetDesaturated(true);
                        checkers:SetVertexColor(1, 1, 1, 0.75);
                        checkers:SetAllPoints(button);
                        checkers:Show();
                    end, self);
                    data.text = Lib:AcquireFromPool('FontString', 'ARTWORK', function(text)
                        text:SetFontObject('GameFontHighlight');
                        text:SetText(data.color:WrapTextInColorCode(get():upper()));
                        text:SetPoint('LEFT', button, 'RIGHT', 8, 0);
                        text:Show();
                    end, self);
                    button:Show();
                    button:SetSize(24, 24);
                    button:SetHitRectInsets(0, -100, 0, 0);
                    button:SetScript('OnClick', GenerateClosure(OnColorButtonClick, data, set));
                end, self);
                data.button:SetPoint('LEFT', self, 'CENTER', -78, 0);
            end;

            local elementResetter = init.Resetter;
            init.Resetter = function(initializer, self)
                elementResetter(initializer, self);
                Lib:ReleaseToPool('Button', nil, data.button);
                Lib:ReleaseToPool('Texture', 'OVERLAY', data.swatch);
                Lib:ReleaseToPool('Texture', 'BACKGROUND', data.background);
                Lib:ReleaseToPool('Texture', 'BACKGROUND', data.checkers);
                Lib:ReleaseToPool('FontString', 'ARTWORK', data.text);
                data.button:SetScript('OnClick', nil);
                data.button:SetHitRectInsets(0, 0, 0, 0);
                ---@diagnostic disable-next-line: unbalanced-assignments
                data.button, data.swatch, data.background, data.checkers, data.text = nil;
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
-- Create a set of widgets from a props table. The props table
-- is a tree of widget properties, with each node representing
-- a widget or a layout. The root node is the parent of the
-- entire tree, which is the owner of the created widgets.
---------------------------------------------------------------
local function Create(props, parent, index)
    local type, result = props.type, {parent = parent, index = index};
    local factory = type and Factory[type] or ResolveType(props, parent);
    if factory then
        result.object,    ---@return table    object    Widget object that was created
        result.id,        ---@return string   id        Unique identifier of the object
        result.layout,    ---@return table    layout    Layout object that was created
        result.setValue,  ---@return function set       Callback function for setting a value
        result.getValue,  ---@return function get       Callback function for getting a value
        result.setOption, ---@return function setOption Callback function for setting an option
        result.getOption  ---@return function getOption Callback function for getting an option
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
                tinsert(result.children, childResult);
            end
        end
        setmetatable(result, { __index = result.children });
    end
    return result;
end

function Lib:Create(props, owner, layout)
    local result = Create(props, owner, layout);
    Settings.RegisterAddOnCategory(result.object);
    self.Registry[result.id] = result;
    return result;
end

function Lib:Add(props, owner, layout)
    return Create(props, owner, layout);
end

---------------------------------------------------------------
-- LoadAddOnCategory
---------------------------------------------------------------
-- Load a category from an addon, and fire a callback when it's
-- done. The category is not created until the addon is loaded,
-- allowing saved variables to be loaded first.
---------------------------------------------------------------
---@param name      string    Name of the addon to load settings for
---@param generator function  Function to generate a props tree
---@param callback  function? Function to call when the category is created
function Lib:LoadAddOnCategory(name, generator, callback)
    EventUtil.ContinueOnAddOnLoaded(name, function()
        local result = self:Create(generator());
        if callback then
            callback(result);
        end
    end);
end

---------------------------------------------------------------
-- AppendAddOnCategory
---------------------------------------------------------------
-- Append more settings to an addon category, and fire a
-- callback when it's done. The category is not created until
-- the addon in question is loaded, allowing saved variables
-- to be loaded first.
---------------------------------------------------------------
---@param name      string    Name of the addon to observe
---@param generator function  Function to generate an appendage props tree
---@param callback  function? Function to call when the appendage is created
function Lib:AppendAddOnCategory(name, generator, callback)
    EventUtil.ContinueOnAddOnLoaded(name, function()
        local result = self:Add(generator());
        if callback then
            callback(result);
        end
    end);
end

---------------------------------------------------------------
-- Get
---------------------------------------------------------------
-- Get a widget tree from the registry by its unique identifier.
-- This is typically the name of the category, if not specified.
---------------------------------------------------------------
function Lib:Get(id)
    return self.Registry[id];
end

Lib.Registry = {};

setmetatable(Lib, {
    __call  = Lib.Create;
    __index = Lib.Get;
});

return

---------------------------------------------------------------------------------------
-- Documentation
---------------------------------------------------------------------------------------
---@class LibSettings.ListItem
    ---@field  name         string               Display name of the elment
    ---@field  id           string               Generative identifier of the element
---------------------------------------------------------------------------------------
---@class LibSettings.AnchorList
    ---@field  [1]          FramePoint           Anchor point
    ---@field  [2]          number               X offset
    ---@field  [3]          number               Y offset
---------------------------------------------------------------------------------------
---@class LibSettings.Anchors<i, LibSettings.AnchorList>
---------------------------------------------------------------------------------------
---@class LibSettings.OptionList
    ---@field  [1]          any                  Value of the option
    ---@field  [2]          string               Display name of the option
    ---@field  [3]          string               Optional tooltip line for the option
---------------------------------------------------------------------------------------
---@class LibSettings.Options<i, LibSettings.OptionList>
---------------------------------------------------------------------------------------
---@class LibSettings.Canvas : LibSettings.ListItem
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
    ---@field  new          boolean              Show new tag on the element
---------------------------------------------------------------------------------------
---@class LibSettings.Setting : LibSettings.Variable
    ---@field  default      LibSettings.Value    Default value of the setting
    ---@field  set          function             Callback function for setting a value
    ---@field  get          function             Function to get current value
    ---@field  key          any                  Optional key for value in storage table
    ---@field  table        table|string         Table/global ref. to store value
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
---@class LibSettings.Types.Color : LibSettings.Setting
    ---@field  default      string               Default color value in hex (AARRGGBB)
---------------------------------------------------------------------------------------
---@class LibSettings.Types.DropDown : LibSettings.Setting
    ---@field  default      any                  Default value of the dropdown
    ---@field  options      LibSettings.Options | LibSettings.OptGen Options table or generator
---------------------------------------------------------------------------------------
---@class LibSettings.Types.Element : LibSettings.Variable
    ---@field  width        number               Width of the element : DEF_ELEM_WIDTH
    ---@field  height       number               Height of the element : DEF_ELEM_HEIGHT
    ---@field  extent       number               Extent of the element (height + padding)
---------------------------------------------------------------------------------------
---@class LibSettings.Types.ExpandableSection : LibSettings.ListItem
    ---@field  expanded     boolean              Section is expanded by default
---------------------------------------------------------------------------------------
---@class LibSettings.Types.Header : LibSettings.ListItem
---------------------------------------------------------------------------------------
---@class LibSettings.Types.Key : LibSettings.Setting
    ---@field  agnostic     boolean              Key chord is agnostic to meta key side
    ---@field  single       boolean              Key chord is single key
---------------------------------------------------------------------------------------
---@class LibSettings.Types.Slider : LibSettings.Setting
    ---@field  default      number               Default value of the slider
    ---@field  min          number               Minimum value of the slider
    ---@field  max          number               Maximum value of the slider
    ---@field  step         number               Step value of the slider
    ---@field  format       function             Function to format the slider value
---------------------------------------------------------------------------------------
---@class LibSettings.Types.Spacer : LibSettings.ListItem
---------------------------------------------------------------------------------------
---@class LibSettings.Category.Vertical : LibSettings.Setting
    ---@field [1] table<integer, LibSettings.ListItem> List of child elements
---------------------------------------------------------------------------------------
---@class LibSettings.Category.Canvas : LibSettings.ListItem
    ---@field  frame        LibSettings.Canvas   Frame to insert in the canvas
    ---@field  anchor       LibSettings.Anchors  Anchor points for the frame
---------------------------------------------------------------------------------------
---@class LibSettings.Result.Base
    ---@field  id           string               Unique identifier of the object
---------------------------------------------------------------------------------------
---@class LibSettings.Result.Init : LibSettings.Result.Base
    ---@field  object       Blizzard.Initializer Widget object that was created
---------------------------------------------------------------------------------------
---@class LibSettings.Result.Setting : LibSettings.Result.Init
    ---@field  setValue     LibSettings.SetValue Wrapped function for setting a value
    ---@field  getValue     LibSettings.GetValue Wrapped function for getting a value
---------------------------------------------------------------------------------------
---@class LibSettings.Result.Combined : LibSettings.Result.Setting
    ---@field  setOption    LibSettings.SetValue Wrapped function for setting an option
    ---@field  getOption    LibSettings.GetValue Wrapped function for getting an option
---------------------------------------------------------------------------------------
---@class LibSettings.Result.Layout : LibSettings.Result.Base
    ---@field  object       Blizzard.Category    Category object that was created
    ---@field  layout       Blizzard.Layout      Layout object that was created
    ---@field  children     table                Nested table of created child widgets
    ---@field  setValue     LibSettings.Setter   Callback function for setting a value
    ---@field  getValue     LibSettings.Getter   Callback function for getting a value
---------------------------------------------------------------------------------------
---@class Blizzard.Option
    ---@field  value        any                  Value of the option
    ---@field  name         string               Display name of the option
    ---@field  tooltip      string               Optional tooltip line for the option
    ---@field  disabled     boolean              Option is disabled
---------------------------------------------------------------------------------------
---@class Blizzard.Anchor
    ---@field  point        FramePoint           Anchor point
    ---@field  x            number               X offset
    ---@field  y            number               Y offset
---------------------------------------------------------------------------------------
---@alias Blizzard.Setting     table
---@alias Blizzard.Initializer table
---@alias Blizzard.Category    table
---@alias Blizzard.Layout      table
---------------------------------------------------------------------------------------
---@alias LibSettings.Value    string|number|boolean
---@alias LibSettings.Pred     function|table<integer, function>
---@alias LibSettings.Event    string|table<integer, string>
---@alias LibSettings.SetValue fun(value: any)
---@alias LibSettings.GetValue fun() : any
---@alias LibSettings.Getter   fun(internal: LibSettings.Setting, setting: Blizzard.Setting) : any
---@alias LibSettings.Setter   fun(internal: LibSettings.Setting, setting: Blizzard.Setting, value: any)
---@alias LibSettings.Set      fun(props: LibSettings.Setting, parent: LibSettings.Result.Layout?) : LibSettings.Setter
---@alias LibSettings.Get      fun(props: LibSettings.Setting, parent: LibSettings.Result.Layout?) : LibSettings.Getter
---@alias LibSettings.OptGen   fun(internal: LibSettings.Setting) : Blizzard.Option[]
---@alias LibSettings.OptList  fun(options: LibSettings.Options) : Blizzard.Option[]
---@alias LibSettings.GetOpts  LibSettings.OptGen | LibSettings.OptList
---@alias LibSettings.Factory  fun(props: LibSettings.ListItem, parent: LibSettings.Result.Layout?, index: number, noCreate: boolean?): ...
---------------------------------------------------------------------------