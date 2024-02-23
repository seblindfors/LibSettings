local MODULE_NAME = 'Color';
local MODULE_VER  = 1;

local Lib = LibStub('LibSettings'):Module(MODULE_NAME, MODULE_VER);
if not Lib then return end ---@diagnostic disable: undefined-global

---------------------------------------------------------------------------------------
---@class LibSettings.Types.Color : LibSettings.Setting
---@field  default      string               Default color value in hex (AARRGGBB)
---------------------------------------------------------------------------------------

local function GetRGBAHexStringFromColor(color)
    local r, g, b, a = color:GetRGBAAsBytes();
    return ('%.2x%.2x%.2x%.2x'):format(a, r, g, b);
end

local function GetColorAlpha()
    if ColorPickerFrame.GetColorAlpha then
        return ColorPickerFrame:GetColorAlpha();
    end
    -- TODO: Remove > 3.4.3.52237
    return 1 - OpacitySliderFrame:GetValue();
end

local function GetPreviousValues()
    local picker = ColorPickerFrame;
    if picker.GetPreviousValues then
        return picker:GetPreviousValues();
    end
    -- TODO: Remove > 3.4.3.52237
    return unpack(picker.previousValues);
end

local function SetupColorPickerAndShow(info)
    local picker, swatch = ColorPickerFrame, ColorSwatch;
    if picker.SetupColorPickerAndShow then
        return picker:SetupColorPickerAndShow(info);
    end
    -- TODO: Remove > 3.4.3.52237
    picker:Hide()
    picker:SetColorRGB(info.r, info.g, info.b, info.a)
    picker.hasOpacity     = info.hasOpacity;
    picker.opacity        = 1 - info.opacity;
    picker.previousValues = {info.r, info.g, info.b, info.a};
    picker.func           = info.swatchFunc;
    picker.cancelFunc     = info.cancelFunc;
    picker.opacityFunc    = info.swatchFunc;
    picker:Show()
    swatch:SetColorTexture(info.r, info.g, info.b)
end

local function OnColorChanged(color, set)
    local r, g, b = ColorPickerFrame:GetColorRGB();
    local a = GetColorAlpha();
    color:SetRGBA(r, g, b, a);
    set(GetRGBAHexStringFromColor(color));
end

local function OnColorCancel(color, set)
    local r, g, b, a = GetPreviousValues();
    color:SetRGBA(r, g, b, a);
    set(GetRGBAHexStringFromColor(color));
end

local function OnColorButtonClick(data, set)
    local color = data.color;
    local r, g, b, a = color:GetRGBA();
    local onColorChanged = GenerateClosure(OnColorChanged, color, set);
    SetupColorPickerAndShow({
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

---@type fun(props: LibSettings.Types.Color, parent: LibSettings.Result.Layout, index: integer): LibSettings.Result.Init, ...
--- Creates a color picker element.
Color
= function(props, parent, index)
    local init, id = MakeElement(props, parent, index);
    local data = init:GetData();
    local setting = MakeSetting(props, parent, data.name, data.variable, Settings.VarType.String);
    init:SetSetting(setting);
    local set, get = MountControls(props, setting, GetCallbacks(props, parent));

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
                swatch:SetTexCoord(0, 1, 0, 1);
                swatch:Show();
                swatch:SetVertexColor(data.color:GetRGBA());
            end, self);
            data.background = Lib:AcquireFromPool('Texture', 'BACKGROUND', function(background)
                background:SetColorTexture(1, 1, 1);
                background:SetAllPoints(button);
                background:Show();
            end, self);
            data.checkers = Lib:AcquireFromPool('Texture', 'ARTWORK', function(checkers)
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
            button:SetPoint('LEFT', self, 'CENTER', -78, 0);
            button:SetHitRectInsets(0, -100, 0, 0);
            button:SetScript('OnClick', GenerateClosure(OnColorButtonClick, data, set));
        end, self);
    end;

    local elementResetter = init.Resetter;
    init.Resetter = function(initializer, self)
        elementResetter(initializer, self);
        data.button:Release(function(button)
            button:SetScript('OnClick', nil);
            button:SetHitRectInsets(0, 0, 0, 0);
        end);
        data.swatch:Release();
        data.background:Release();
        data.checkers:Release();
        data.text:Release();
        ---@diagnostic disable-next-line: unbalanced-assignments
        data.button, data.swatch, data.background, data.checkers, data.text = nil;
    end;

    return init, id, nil, set, get;
end

Lib:Resolve(MODULE_NAME, function(Types, props, parent)
    if not parent then return end;
    local color = props.default;
    -- check if the default value is a string with 8 characters and the characters are hexadecimal
    if ( type(color) == 'string' and #color == 8 and tonumber(color, 16) ) then
        return Types.Color;
    end
end);