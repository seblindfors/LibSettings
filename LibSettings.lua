---@class LibSettings
local Lib = LibStub:NewLibrary('LibSettings', 0.5);
if not Lib then return end;
---------------------------------------------------------------
-- Helpers
---------------------------------------------------------------
local Settings, CHILDREN, DELIMITER, Env = Settings, 1, '.', {
    DEF_ELEM_WIDTH = 280,
    DEF_ELEM_HEIGHT = 26,
    CHILDREN = 1,
};

---------------------------------------------------------------
-- Identity
---------------------------------------------------------------
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

function Env.GetIdentity(props, parent, index)
    return
        props.name,
        GenerateTableID(props, index),
        GenerateUniqueVariableID(props, parent, index);
end

---------------------------------------------------------------
-- Callbacks
---------------------------------------------------------------
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

    ---@param  props     LibSettings.Setting       Properties of the setting
    ---@param  parent    LibSettings.Result.Layout Parent tree node of the setting
    ---@return LibSettings.Setter|nil set          Callback function for setting a value, if any
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

    ---@param  props     LibSettings.Setting       Properties of the setting
    ---@param  parent    LibSettings.Result.Layout Parent tree node of the setting
    ---@return LibSettings.Getter|nil get          Callback function for getting a value, if any
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
function Env.MountControls(props, setting, set, get)
    if props.cvar then
        set = GenerateClosure(setting.SetValue, setting);
        get = GenerateClosure(setting.GetValue, setting);
        return set, get;
    end
    local variable = setting:GetVariable();
    if set then
        Settings.SetOnValueChangedCallback(variable, set, props);
        set = GenerateClosure(setting.SetValue, setting);
    end
    if get then
        get = GenerateClosure(get, props, setting);
        local currentValue = get();
        if ( currentValue == nil ) then
            setting:SetValue(props.default);
        else
            setting:SetValue(currentValue);
        end
    end
    return set, get;
end

function Env.GetCallbacks(props, parent)
    return
        MakeSetter(props, parent) --[[@as LibSettings.Set]],
        MakeGetter(props, parent) --[[@as LibSettings.Get]];
end

---------------------------------------------------------------
-- Initializers and setting generators
---------------------------------------------------------------
---@param  props     LibSettings.Setting       Properties of the setting
---@param  parent    LibSettings.Result.Layout Parent tree node of the setting
---@param  name      string                    Name of the setting
---@param  variable  string                    Variable name of the setting
---@param  varType   string                    Type of the setting variable
function Env.MakeSetting(props, parent, name, variable, varType)
    if props.cvar then
        return Settings.RegisterCVarSetting(parent.object, props.cvar, varType, name);
    end
    return Settings.RegisterAddOnSetting(parent.object, name, variable, varType, props.default);
end

---@param  props     LibSettings.ListItem      Base properties of the element
---@param  parent    LibSettings.Result.Layout Parent tree node of the element
---@param  index     integer                   Index of the element in the parent
function Env.MakeElement(props, parent, index)
    return Lib.Types.Element(
        props  --[[@as LibSettings.Types.Element]],
        parent --[[@as LibSettings.Result.Layout]],
        index
    ) --[[@as Blizzard.Initializer]];
end

---------------------------------------------------------------
-- Predicates and events
---------------------------------------------------------------
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
            for _, predicate in _unpack(predicates) do
                init[method](init, unpack(predicate));
            end
        end
    end

    Env.UnpackEvents         = GenerateClosure(__unpack, 'string')   --[[@as function]];
    Env.PackPredicates       = GenerateClosure(__pack,   'function') --[[@as function]];
    Env.UnpackPredicates     = GenerateClosure(__unpack, 'function') --[[@as function]];
    Env.UnpackAnchors        = GenerateClosure(__unpack, 'table')    --[[@as function]];
    Env.AddStateFrameEvents  = GenerateClosure(__add,    'AddStateFrameEvent', Env.UnpackEvents)       --[[@as function]];
    Env.AddShownPredicates   = GenerateClosure(__add,    'AddShownPredicate',  Env.UnpackPredicates)   --[[@as function]];
    Env.AddModifyPredicates  = GenerateClosure(__add,    'AddModifyPredicate', Env.UnpackPredicates)   --[[@as function]];
    Env.AddAnchorPoints      = GenerateClosure(__addtbl, 'AddAnchorPoint',     Env.UnpackAnchors)      --[[@as function]];

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

    function Env.SetParentInitializer(init, parentResult, lookup, modifier)
        if type(lookup) == 'string' then
            local errorMsg = ('Parent initializer %q not found in %q.'):format(lookup, init:GetName());
            for key in lookup:gmatch('[^%.]+') do
                assert(parentResult, errorMsg);
                parentResult = parentResult[key];
            end
            assert(parentResult, errorMsg);
            return ResolveAndSetParentInitializer(init, parentResult.object, modifier);
        end
    end
end

---------------------------------------------------------------
-- Common mounting function for all initializers
---------------------------------------------------------------
function Env.MountCommon(init, props, parent)
    Env.AddShownPredicates(init, props.show);
    Env.AddStateFrameEvents(init, props.event);
    if not Env.SetParentInitializer(init, parent, props.parent, props.modify) then
        Env.AddModifyPredicates(init, props.modify);
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
do local pools = {};
    local function MakePoolID(wType, wTemplate)
        return wType..'.'..tostring(wTemplate);
    end

    local function PoolRelease(widget, releaseFunc)
        pools[widget.__poolID]:Release(widget);
        if releaseFunc then
            releaseFunc(widget);
        end
    end

    function Lib:AcquireFromPool(wType, wTemplate, init, parent, ...)
        local poolID = MakePoolID(wType, wTemplate);
        if not pools[poolID] then
            if wType:match('Texture') then
                pools[poolID] = CreateTexturePool(UIParent, wTemplate, ...);
            elseif wType:match('FontString') then
                pools[poolID] = CreateFontStringPool(UIParent, wTemplate, ...);
            else
                pools[poolID] = CreateFramePool(wType, nil, wTemplate, ...);
            end
        end
        local widget = pools[poolID]:Acquire();
        widget.Release, widget.__poolID = PoolRelease, poolID;
        widget:SetParent(parent);
        if init then
            init(widget);
        end
        return widget;
    end

    function Lib:ReleaseToPool(wType, wTemplate, widget)
        local poolID = MakePoolID(wType, wTemplate);
        if pools[poolID] then
            pools[poolID]:Release(widget);
        end
    end
end

---------------------------------------------------------------
-- Types
---------------------------------------------------------------
-- Map of element types to factory functions.
-- Each factory function takes a props table tailored to the type of element,
-- and returns a result table containing the created widget, its unique identifier,
-- and its layout object, as well as any additional callbacks for setting and getting values.
---@enum (key) LibSettings.Types
Lib.Types = {};

local ResolveType = GenerateClosure(function(Types, props, parent)
    for _, resolver in pairs(Lib.Resolvers) do
        local result = resolver(Types, props, parent);
        if result then
            return result;
        end
    end
    error(('Type could not be resolved for object %q'):format(tostring(props.name)), 2);
end, Lib.Types);

---------------------------------------------------------------
-- AddCustomType
---------------------------------------------------------------
-- Add a custom type to the factory. This allows for custom
-- widgets to be created from a props table. The factory
-- function takes a props table tailored to the type of element,
-- and returns a result table containing the created widget,
-- its unique identifier, and its layout object, as well as any
-- additional callbacks for setting and getting values.
---------------------------------------------------------------
function Lib:AddCustomType(name, factory, force)
    local typeExists = not not self.Types[name];
    if typeExists and not force then
        error(('Type already exists: %q'):format(tostring(name)), 2);
    end
    self.Types[name] = factory;
end

---------------------------------------------------------------
-- Module definition
---------------------------------------------------------------
Lib.Modules, Lib.Resolvers = {}, {};
setmetatable(Env, {
    __index = _G;
    __newindex = function(_, name, factory)
        assert(type(factory) == 'function', ('Factory for %q must be a function'):format(name));
        Lib.Types[name] = factory;
    end;
})
function Lib:Module(module, version)
    if (self.Modules[module] or 0) >= version then
        return nil;
    end
    self.Modules[module] = version;
    setfenv(2, Env);
    return self;
end
function Lib:Resolve(module, resolver)
    if not self.Modules[module] then
        error(('Module %q not defined.'):format(module), 2);
    end
    self.Resolvers[module] = resolver;
end

---------------------------------------------------------------
-- Factory
---------------------------------------------------------------
local function Factory(props, parent, index)
    local result = { parent = parent, index = index };
    local factory = props.type or ResolveType(props, parent);
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
            local childResult = Factory(child, result, i);
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

---------------------------------------------------------------
-- Create
---------------------------------------------------------------
-- Create a set of widgets from a props table. The props table
-- is a tree of widget properties, with each node representing
-- a widget or a layout. The root node is the parent of the
-- entire tree, which is the owner of the created widgets.
---------------------------------------------------------------
function Lib:Create(props, owner, layout)
    local result = Factory(props, owner, layout);
    if not owner then
        Settings.RegisterAddOnCategory(result.object);
        self.Registry[result.id] = result;
    end
    return result;
end

---------------------------------------------------------------
-- Add
---------------------------------------------------------------
-- Add more widgets to an existing set of widgets. This is
-- similar to Create, but the widgets are appended to an
-- existing set of widgets, rather than creating a new set.
---------------------------------------------------------------
function Lib:Add(props, owner, layout)
    return Factory(props, owner, layout);
end

---------------------------------------------------------------
-- LoadAddOnCategory
---------------------------------------------------------------
-- Load a category from an addon, and fire a callback when it's
-- done. The category is not created until the addon is loaded,
-- allowing saved variables to be loaded first.
---------------------------------------------------------------
---@param  name      string    Name of the addon to load settings for
---@param  generator function  Function to generate a props tree
---@param  callback  function? Function to call when the category is created
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
---@param  name      string    Name of the addon to observe
---@param  generator function  Function to generate an appendage props tree
---@param  callback  function? Function to call when the appendage is created
function Lib:AppendAddOnCategory(name, generator, callback)
    EventUtil.ContinueOnAddOnLoaded(name, function()
        local result = self:Add(generator());
        if callback then
            callback(result);
        end
    end);
end

---------------------------------------------------------------
-- Open
---------------------------------------------------------------
-- Open a category by its object reference. This will show
-- the category in the settings panel.
---------------------------------------------------------------
---@param  category  LibSettings.Result.Layout Category object
---@return boolean   success Whether the category was opened
function Lib:Open(category)
    assert(type(category) == 'table', 'Usage: LibSettings:Open(category)');
    assert(category.object and category.object.ID, 'Invalid category object');
    return Settings.OpenToCategory(category.object.ID);
end

---------------------------------------------------------------
-- OpenByID
---------------------------------------------------------------
-- Open a category by its unique identifier. This will show
-- the category in the settings panel.
---------------------------------------------------------------
---@param  id        string    Unique identifier of the category
---@return boolean   success   Whether the category was opened
function Lib:OpenByID(id)
    assert(type(id) == 'string', 'Usage: LibSettings:OpenByID(id)');
    local category = self.Registry[id];
    assert(category, 'Category not found: '..tostring(id));
    return Settings.OpenToCategory(category.object.ID);
end

---------------------------------------------------------------
-- Get
---------------------------------------------------------------
-- Get a widget tree from the registry by its unique identifier.
-- This is typically the name of the category, if not specified.
---------------------------------------------------------------
---@param  id        string    Unique identifier of the category
---@return LibSettings.Result.Layout category Category object
function Lib:Get(id)
    return self.Registry[id];
end

Lib.Registry = {};

return setmetatable(Lib, {
    __call  = Lib.Create;
    __index = Lib.Get;
});

---------------------------------------------------------------------------------------
-- Documentation
---------------------------------------------------------------------------------------
---@class LibSettings.ListItem
    ---@field  name         string               Display name of the elment
    ---@field  id           string               Generative identifier of the element
    ---@field  type         function?            Factory function for the element
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
    ---@field  cvar         string               CVar to store and access value
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
---@alias LibSettings.Proto    LibSettings.Result.Setting|Blizzard.Setting
---@alias LibSettings.SetValue fun(value: any)
---@alias LibSettings.GetValue fun() : any
---@alias LibSettings.Getter   fun(internal: LibSettings.Setting, setting: Blizzard.Setting) : any
---@alias LibSettings.Setter   fun(internal: LibSettings.Setting, setting: Blizzard.Setting, value: any)
---@alias LibSettings.Set      fun(props: LibSettings.Setting, parent: LibSettings.Result.Layout?) : LibSettings.Setter
---@alias LibSettings.Get      fun(props: LibSettings.Setting, parent: LibSettings.Result.Layout?) : LibSettings.Getter
---------------------------------------------------------------------------