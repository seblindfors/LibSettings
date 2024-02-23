local MODULE_NAME = 'Element';
local MODULE_VER  = 1;

local Lib = LibStub('LibSettings'):Module(MODULE_NAME, MODULE_VER);
if not Lib then return end ---@diagnostic disable: undefined-global

---------------------------------------------------------------------------------------
---@class LibSettings.Types.Element : LibSettings.Variable
---@field  width        number               Width of the element : DEF_ELEM_WIDTH
---@field  height       number               Height of the element : DEF_ELEM_HEIGHT
---@field  extent       number               Extent of the element (height + padding)
---------------------------------------------------------------------------------------
---@class LibSettings.Types.Header : LibSettings.ListItem
---------------------------------------------------------------------------------------
---@class LibSettings.Types.Spacer : LibSettings.ListItem
---------------------------------------------------------------------------------------

---@type fun(props: LibSettings.Types.Element, parent: LibSettings.Result.Layout, index: integer): LibSettings.Result.Init, ...
--- Creates a basic element, with a name and a tooltip. This is the base for all other list elements.
Element
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
end

---@type fun(props: LibSettings.Types.Header, parent: LibSettings.Result.Layout, index: integer): LibSettings.Result.Init, ...
--- Creates a header element, which is a simple text to separate elements.
Header
= function(props, parent, index)
    local name, id = GetIdentity(props, parent, index);
    local init = CreateSettingsListSectionHeaderInitializer(name);
    parent.layout:AddInitializer(init);
    MountCommon(init, props, parent);
    return init, id;
end

---@type fun(props: LibSettings.Types.Spacer, parent: LibSettings.Result.Layout, index: integer): LibSettings.Result.Init, ...
--- Creates a spacer element, which is a simple line to separate elements.
Spacer
= function(props, parent, index)
    local _, id = GetIdentity(props, parent, index);
    local init = Settings.CreateElementInitializer('SettingsCategoryListSpacerTemplate', {});
    parent.layout:AddInitializer(init);
    MountCommon(init, props, parent);
    return init, id;
end

Lib:Resolve(MODULE_NAME, function(Types, props, parent)
    if not parent then return end;
    if not next(props) then
        return Types.Spacer;
    -- if the props table only has name, return header
    elseif props.name and not next(props, next(props)) then
        return Types.Header;
    end
end);