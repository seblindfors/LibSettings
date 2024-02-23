local MODULE_NAME = 'Key';
local MODULE_VER  = 1;

local Lib = LibStub('LibSettings'):Module(MODULE_NAME, MODULE_VER);
if not Lib then return end ---@diagnostic disable: undefined-global

---------------------------------------------------------------------------------------
---@class LibSettings.Types.Key : LibSettings.Setting
---@field  agnostic     boolean              Key chord is agnostic to meta key side
---@field  single       boolean              Key chord is single key
---------------------------------------------------------------------------------------

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

---@type fun(props: LibSettings.Types.Key, parent: LibSettings.Result.Layout, index: integer): LibSettings.Result.Init, ...
--- Creates a custom key binding element, with support for meta keys, key chords and single key input.
Key
= function(props, parent, index)
    local init, id = MakeElement(props, parent, index);
    local data = init:GetData();
    local setting = MakeSetting(props, parent, data.name, data.variable, Settings.VarType.String);
    init:SetSetting(setting);
    local set, get = MountControls(props, setting, GetCallbacks(props, parent));

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
            button:SetPoint('LEFT', self, 'CENTER', -80, 0);
        end, self);
    end;

    local elementResetter = init.Resetter;
    init.Resetter = function(initializer, self)
        elementResetter(initializer, self);
        CustomBindingManager:SetHandlerRegistered(data.button, false);
        data.button:Release();
        data.button = nil;
    end;

    return init, id, nil, set, get;
end

Lib:Resolve(MODULE_NAME, function(Types, props, parent)
    if not parent then return end;
    local key = props.default;
    if ( props.agnostic ~= nil or props.single ~= nil )
    -- check if the key is a valid key chord
    or ( type(key) == 'string' and key:match('[A-Z-1-9]+') == key ) then
        return Types.Key;
    end
end)