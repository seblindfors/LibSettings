local MODULE_NAME = 'Container';
local MODULE_VER  = 1;

local Lib = LibStub('LibSettings'):Module(MODULE_NAME, MODULE_VER);
if not Lib then return end ---@diagnostic disable: undefined-global

---------------------------------------------------------------------------------------
---@class LibSettings.AnchorList
---@field  [1]          FramePoint           Anchor point
---@field  [2]          number               X offset
---@field  [3]          number               Y offset
---------------------------------------------------------------------------------------
---@class LibSettings.Anchors<i, LibSettings.AnchorList>
---------------------------------------------------------------------------------------
---@class LibSettings.Canvas : LibSettings.ListItem
---@field  OnCommit      function            Callback function for committing
---@field  OnDefault     function            Callback function for resetting
---@field  OnRefresh     function            Callback function for refreshing
---@source Interface/SharedXML/Settings/Blizzard_SettingsCanvas.lua
---------------------------------------------------------------------------------------
---@class LibSettings.Category.Vertical : LibSettings.Setting
---@field [1] table<integer, LibSettings.ListItem> List of child elements
---------------------------------------------------------------------------------------
---@class LibSettings.Category.Canvas : LibSettings.ListItem
---@field  frame        LibSettings.Canvas   Frame to insert in the canvas
---@field  anchor       LibSettings.Anchors  Anchor points for the frame
---------------------------------------------------------------------------------------
---@class LibSettings.Types.ExpandableSection : LibSettings.ListItem
---@field  expanded     boolean              Section is expanded by default
---------------------------------------------------------------------------------------

---@type fun(props: LibSettings.Category.Vertical): LibSettings.Result.Layout, ...
--- Creates a vertical layout category, with a list of elements to render vertically inside the settings panel.
VerticalLayoutCategory
= function(props)
    local name, id = GetIdentity(props);
    local set, get = GetCallbacks(props);
    local init, layout = Settings.RegisterVerticalLayoutCategory(name);
    return init, id, layout, set, get;
end

---@type fun(props: LibSettings.Category.Canvas): LibSettings.Result.Layout, ...
--- Creates a canvas layout category, with a frame to anchor inside the settings panel.
CanvasLayoutCategory
= function(props)
    local name, id = GetIdentity(props);
    local set, get = GetCallbacks(props);
    local init, layout = Settings.RegisterCanvasLayoutCategory(props.frame, name);
    AddAnchorPoints(init, props.anchor);
    return init, id, layout, set, get;
end

---@type fun(props: LibSettings.Category.Vertical, parent: LibSettings.Result.Layout, index: integer): LibSettings.Result.Layout, ...
--- Creates a subcategory in a vertical layout.
VerticalLayoutSubcategory
= function(props, parent, index)
    local name, id = GetIdentity(props, parent, index);
    local set, get = GetCallbacks(props, parent);
    local init, layout = Settings.RegisterVerticalLayoutSubcategory(parent.object, name);
    return init, id, layout, set, get;
end

---@type fun(props: LibSettings.Category.Canvas, parent: LibSettings.Result.Layout, index: integer): LibSettings.Result.Layout, ...
--- Creates a canvas layout subcategory, with a frame to anchor inside the settings panel.
CanvasLayoutSubcategory
= function(props, parent, index)
    local name, id = GetIdentity(props, parent, index);
    local set, get = GetCallbacks(props, parent);
    local init, layout = Settings.RegisterCanvasLayoutSubcategory(parent.object, props.frame, name);
    AddAnchorPoints(init, props.anchor);
    return init, id, layout, set, get;
end

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

---@type fun(props: LibSettings.Types.ExpandableSection, parent: LibSettings.Result.Layout, index: integer): LibSettings.Result.Init, ...
--- Creates an expandable section element, with support for hiding and showing children based on its state.
ExpandableSection
= function(props, parent, index)
    local name, _, variable = GetIdentity(props, parent, index);
    local init = CreateSettingsExpandableSectionInitializer(name);
    local data = init.data;

    parent.layout:AddInitializer(init);

    data.expanded = props.expanded;
    Mixin(init, ExpandableSectionMixin);

    local function IsExpanded() return data.expanded end;
    for _, child in ipairs(props[CHILDREN] or {}) do
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

Lib:Resolve(MODULE_NAME, function(Types, props, parent)
    if not parent then
        if props.frame then
            return Types.CanvasLayoutCategory;
        else
            return Types.VerticalLayoutCategory;
        end
    end
    if props.frame then
        return Types.CanvasLayoutSubcategory;
    elseif ( props.expanded ~= nil ) then
        return Types.ExpandableSection;
    -- if the child(ren) is sequential, it's a vertical layout
    elseif props[CHILDREN] and #props[CHILDREN] > 0 then
        return Types.VerticalLayoutSubcategory;
    end
end);