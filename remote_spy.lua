local env = oh.env
local aux = oh.aux
local assets = oh.assets

local gui = oh.gui
local base = gui.Base
local body = base.Body
local tabs = body.Tabs
local window = tabs.RemoteSpy
local inspect = tabs.RemoteSpyInspection
local conditions = tabs.RemoteSpyConditions
local options = window.Options

local drop_down = gui.RSDropdown
local idrop_down = gui.RSIDropdown

local selected_remote 
local selected_option = "RemoteEvent"
local blocked = {}
local removed = {}
local remotes = {}
local ignore = {}

local drop_down_events = {
    remote_spy = {},
    inspection = {}
}

local hard_ignore = { -- hard-coded ignore
    {"CharacterSoundEvent", {
        "string"
    }},
    {"CharacterSoundEvent", {
        "boolean",
        "boolean"
    }},
}

local blocked_args = {}

local tween_service = game:GetService("TweenService")
local client = game:GetService("Players").LocalPlayer
local mouse = client:GetMouse()

local gmt = env.get_metatable(game)
local nmc = gmt.__namecall

--[[
    A U X I L I A R Y
]]--

local transform_path = function(raw)
    local split = raw:split('.')
    local result = ""
    
    if #split == 1 and not game:FindFirstChild(split[1]) then
        return split[1] .. " --[[ Parent is \"nil\" or object is destroyed ]]"
    end
    
    for i,v in next, split do
        if v:find("%A") then
            result = result:sub(1, result:len() - 1)
            v = "[\"" .. v .. "\"]"
        end
        
        result = result .. v .. "."
    end
    
    result = result:gsub("Players.LocalPlayer." .. game:GetService("Players").LocalPlayer.Name, "LocalPlayer")
    result = result:gsub("Players.LocalPlayer[\"" .. game:GetService("Players").LocalPlayer.Name .. "\"]", "LocalPlayer")
    
    return "game." .. result:sub(1, result:len() - 1)
end

local dump_table
dump_table = function(t)
    local result = "{ "

    for i,v in next, t do
        if type(i) == "table" then
            result = result .. '[' .. dump_table(i)
        elseif type(i) == "string" then
            if i:find("%A") then
            result = result .. '["' .. i .. '"'
            else
            result = result .. i
            end
        elseif type(i) == "number" then
        elseif typeof(i) == "Instance" then
            result = result .. '[' .. transform_path(i:GetFullName())
        else
            result = result .. '[' .. tostring(i)
        end
        result = result .. ((type(i) == "string" and ((i:find("%A") and "] = ") or " = ")) or (type(i) ~= "number" and '] = ') or "")

        if type(v) == "table" then
            result = result .. dump_table(v) 
        elseif type(v) == "string" then
            result = result .. '"' .. v .. '"'
        elseif typeof(v) == "Instance" then
            result = result .. transform_path(v:GetFullName())
        elseif typeof(v) == "Vector3" then
            result = result .. "Vector3.new(" .. tostring(v) .. ")"
        elseif typeof(v) == "CFrame" then
            result = result .. "CFrame.new(" .. tostring(v) .. ")"
        elseif typeof(v) == "Color3" then
            result = result .. "Color3.new(" .. tostring(v) .. ")"
        elseif typeof(v) == "Ray" then
            local split = tostring(v):split('}, ')
            local origin = split[1]:gsub('{', "Vector3.new("):gsub('}', ')')
            local direction = split[2]:gsub('{', "Vector3.new("):gsub('}', ')')
            result = result .. "Ray.new(" .. origin .. "), " .. direction .. ')'
        elseif typeof(v) == "ColorSequence" then
            result = result .. "ColorSequence.new(" .. dump_table(v.Keypoints) .. ')'
        elseif typeof(v) == "ColorSequenceKeypoint" then
            result = result .. "ColorSequenceKeypoint.new(" .. v.Time .. ", Color3.new(" .. tostring(v.Value) .. "))" 
        else       
            if type(v) == "userdata" then
                print(typeof(v))
            end
            
            result = result .. tostring(v)
        end
        result = result .. ', '
    end

    if result:sub(result:len() - 1, result:len()) == ", " then
        result = result:sub(1, result:len() - 2)
    end

    return result .. " }"
end

local toscript = function(compact, remote, params)
    local result = ""
    local method = ({
        RemoteEvent = "FireServer",
        RemoteFunction = "InvokeServer",
        BindableEvent = "Fire",
        BindableFunction = "Invoke"
    })[remote.ClassName]

    for i,v in next, params do
        local tt = type(v)

        result = result .. "local oh" .. i .. " = "

        if tt == "table" then
            result = result .. dump_table(v)
        elseif tt == "string" then
            result = result .. '"' .. v .. '"'
        elseif tt == "number" then
            result = result .. v
        elseif typeof(v) == "Instance" then
            result = result .. transform_path(v:GetFullName())
        elseif typeof(v) == "Vector3" then
            result = result .. "Vector3.new(" .. tostring(v) .. ")"
        elseif typeof(v) == "CFrame" then
            result = result .. "CFrame.new(" .. tostring(v) .. ")"
        elseif typeof(v) == "Color3" then
            result = result .. "Color3.new(" .. tostring(v) .. ")"
        elseif typeof(v) == "Ray" then
            local split = tostring(v):split('}, ')
            local origin = split[1]:gsub('{', "Vector3.new("):gsub('}', ')')
            local direction = split[2]:gsub('{', "Vector3.new("):gsub('}', ')')
            result = result .. "Ray.new(" .. origin .. "), " .. direction .. ')'
        elseif typeof(v) == "ColorSequence" then
            result = result .. "ColorSequence.new(" .. dump_table(v.Keypoints) .. ')'
        elseif typeof(v) == "ColorSequenceKeypoint" then
            result = result .. "ColorSequenceKeypoint.new(" .. v.Time .. ", Color3.new(" .. v.Value .. "))" 
        else
            result = result .. tostring(v)
        end

        result = result .. '\n'
    end

    local feed = ""

    for i = 1, #params do
        feed = feed .. "oh" .. i .. ", "
    end

    return result .. transform_path(remote:GetFullName()) .. ':' .. method .. '(' .. feed:sub(1, feed:len() - 2) .. ')'
end

local inspect_dropdown = function(container, remote, parameters)
    local events = drop_down_events.inspection
    for i,v in next, events do
        v:Disconnect()
    end
    idrop_down.Position = UDim2.new(0, mouse.X + 10, 0, mouse.Y + 10)
    idrop_down.Visible = true

    events.GenerateScript = idrop_down.Script.MouseButton1Click:Connect(function()
        env.to_clipboard(toscript(false, remote, parameters))
    end)

    -- calling script
    -- calling function

    events.Remove = idrop_down:FindFirstChild("Remove").MouseButton1Click:Connect(function()
        inspect.Results.CanvasSize = inspect.Results.CanvasSize - UDim2.new(0, 0, 0, container.AbsoluteSize.Y)
        container:Destroy()
    end)

    events.Ignore = idrop_down.Ignore.MouseButton1Click:Connect(function()
        
    end)

    events.Block = idrop_down.Block.MouseButton1Click:Connect(function()
        
    end)
end

-- Function used to visualize RemoteObject parameters
local create_remote_data = function(remote, parameters)
    local container = assets.RemoteDataPod:Clone()
    container.Parent = inspect.Results

    for i, value in next, parameters do
        -- Method to prevent the __tostring method from detecting Hydroxide
        local __tostring 
        local metatable = env.get_metatable(v)
        local method = metatable and metatable.__tostring

        if method then
            __tostring = method
            env.set_readonly(metatable, false)
            metatable.__tostring = nil
        end

        local parameter = assets.RemoteData:Clone()
        parameter.Icon.Image = "rbxassetid://" .. oh.icons[type(value)]
        parameter.Label.Text = (typeof(value) == "Instance" and value.Name) or tostring(value)
        parameter.Parent = container

        -- Change the size of the parameter's element to fit the literal value length
        local increment = UDim2.new(0, 0, 0, 16)
        container.Size = container.Size + increment
        inspect.Results.CanvasSize = inspect.Results.CanvasSize + increment

        while not parameter.Label.TextFits do
            local increment = UDim2.new(0, 0, 0, 16)
            parameter.Size = parameter.Size + increment
            container.Size = container.Size + increment
            inspect.Results.CanvasSize = inspect.Results.CanvasSize + increment
            wait()
        end

        -- If a __tostring method was found, then reset it to avoid detection
        if __tostring then
            metatable.__tostring = __tostring
            env.set_readonly(metatable, true)
        end
    end

    container.MouseButton2Click:Connect(function()
        inspect_dropdown(container, remote, parameters)
    end)

    aux.apply_highlight(container, nil, nil, true)
end


local is_remote = function(object)
    local ran, result = pcall(function()
        return object:IsA("RemoteEvent") or object:IsA("RemoteFunction") or object:IsA("BindableEvent") or object:IsA("BindableFunction")
    end)

    return (ran and (result and {logs = 0, ignored_args = {}, logged = {}})) or nil
end

local display_dropdown = function(remote)
    local events = drop_down_events.remote_spy
    for i,v in next, events do
        v:Disconnect()
    end

    drop_down.Position = UDim2.new(0, mouse.X + 10, 0, mouse.Y + 10)
    drop_down.Visible = true

    drop_down.Block.Text = (blocked[remote] and "Unblock") or "Block"
    drop_down.Ignore.Text = (ignore[remote] and "Spy") or "Ignore"

    events.Block = drop_down.Block.MouseButton1Click:Connect(function()
        blocked[remote] = not blocked[remote]
        local window = remotes[remote].window
        local blocked_color = Color3.fromRGB(150, 0, 0)
        local unblocked_color = Color3.fromRGB(200, 200, 200)

        if ignore[remote] then
            blocked_color = Color3.new(0, 0, 0)
            unblocked_color = Color3.fromRGB(100, 100, 100)
        end
        
        if blocked[remote] then
            local anim = tween_service:Create(window.Label, TweenInfo.new(0.1), {TextColor3 = blocked_color})
            anim:Play()
        else
            local anim = tween_service:Create(window.Label, TweenInfo.new(0.1), {TextColor3 = unblocked_color})
            anim:Play()
        end
    end)

    events.Ignore = drop_down.Ignore.MouseButton1Click:Connect(function()
        ignore[remote] = not ignore[remote]
        local window = remotes[remote].window
        local ignore_color = Color3.fromRGB(100, 100, 100)
        local spy_color = Color3.fromRGB(200, 200, 200)

        if blocked[remote] then
            color = Color3.new(0, 0, 0)
            spy_color = Color3.fromRGB(150, 0, 0)
        end

        if ignore[remote] then
            local anim = tween_service:Create(window.Label, TweenInfo.new(0.1), {TextColor3 = ignore_color})
            anim:Play()
            inspect.Toggle.Text = "Spy"
        else
            local anim = tween_service:Create(window.Label, TweenInfo.new(0.1), {TextColor3 = spy_color})
            anim:Play()
            inspect.Toggle.Text = "Ignore"
        end
    end)

    events.Clear = drop_down.Clear.MouseButton1Click:Connect(function()
        local old_context = env.get_thread_context()
        env.set_thread_context(6)

        local remote = remotes[remote]
        remote.logs = 0
        remote.window.Count.Text = "0"

        for i, result in next, inspect.Results:GetChildren() do
            if not result:IsA("UIListLayout") then
                result:Destroy()
            end
        end

        remote.logged = {}
        inspect.Results.CanvasSize = UDim2.new(0, 0, 0, 0)

        env.set_thread_context(old_context)
    end)

    events.Remove = drop_down:FindFirstChild("Remove").MouseButton1Click:Connect(function()
        local window = remotes[remote].window
        
        ignore[remote] = true
        window.Parent.CanvasSize = window.Parent.CanvasSize - UDim2.new(0, 0, 0, 25)
        window:Destroy()
        remotes[remote] = nil
    end)

    events.Conditions = drop_down.Conditions.MouseButton1Click:Connect(function()
        conditions.Visible = true
        oh.selected_extension.Visible = false
        oh.selected_extension = conditions
    end)
end

--[[
    C O R E 
]]--

game.DescendantRemoving:Connect(function(object)
    local old_context = env.get_thread_context()
    env.set_thread_context(6)

    if not object:IsDescendantOf(game) and remotes[object] then
        print("destroyed " .. object.Name)
        local logs = window[object.ClassName]
        remotes[object].window:Destroy()
        remotes[object] = nil
        logs.CanvasSize = logs.CanvasSize - UDim2.new(0, 0, 0, 25)
    end

    env.set_thread_context(old_context)
end)

local bind = Instance.new("BindableEvent")
bind.Event:Connect(function(nmc, obj, ...)
    local vargs = {...}
    local methods = {
        FireServer = true,
        InvokeServer = true,
        Fire = true,
        Invoke = true
    }

    if methods[nmc] and not ignore[obj] then
        local guard = false
        if hard_ignore[obj.Name] then
            for i,v in next, vargs do
                if type(hard_ignore[obj.Name][i]) == type(v) then
                    guard = true
                else
                    guard = false
                    return
                end
            end
        end

        if guard then return end

        local old_context = env.get_thread_context()
        env.set_thread_context(6)

        if not remotes[obj] then
            remotes[obj] = is_remote(obj)
            local asset = assets.RemoteObject:Clone()
            remotes[obj].window = asset
            local logs = window[obj.ClassName]
            asset.Name = obj.Name
            asset.Parent = logs
            asset.Label.Text = obj.Name
            asset.Icon.Image = "rbxassetid://" .. oh.icons[obj.ClassName]
            logs.CanvasSize = logs.CanvasSize + UDim2.new(0, 0, 0, 25)
        
            asset.MouseButton1Click:Connect(function()
                local old_context = env.get_thread_context()
                env.set_thread_context(6)
        
                if selected_remote ~= obj then
                    for i,v in next, inspect.Results:GetChildren() do
                        if not v:IsA("UIListLayout") then
                            v:Destroy()
                        end
                    end
        
                    inspect.Results.CanvasSize = UDim2.new(0, 0, 0, 0)
        
                    for i,v in next, remotes[obj].logged do
                        create_remote_data(obj, v)
                    end
                end
        
                local remote = inspect.Remote
                local label = remote.Label
                label.Text = asset.Name
        
                label.Size = UDim2.new(0, label.TextBounds.X + 5, 0, 25)
                label.Position = UDim2.new(1, -(label.TextBounds.X + 10), 0, 0)
                remote.Icon.Position = UDim2.new(1, -(label.TextBounds.X + 35), 0, 0)
        
                body.TabsLabel.Text = "  RemoteSpy : inspect"
        
                inspect.Visible = true
                oh.selected_extension.Visible = false
                oh.selected_extension = inspect
                selected_remote = obj
        
                env.set_thread_context(old_context)
            end)

            asset.MouseButton2Click:Connect(function()
                display_dropdown(obj)
            end)
        
            obj:GetPropertyChangedSignal("Parent"):Connect(function()
                if not obj:IsDescendantOf(game) then
                    asset:Destroy()
                    remotes[object] = nil
                    logs.CanvasSize = logs.CanvasSize - UDim2.new(0, 0, 0, 25)
                end
            end)
        end

        local remote = remotes[obj]

        if selected_remote == obj then
            create_remote_data(obj, vargs)
        end

        table.insert(remote.logged, vargs)
        remote.logs = remote.logs + 1
        remote.window.Count.Text = (remote.logs <= 999 and remote.logs) or "..."

        env.set_thread_context(old_context)
    end
end)

setreadonly(gmt, false)
gmt.__namecall = newcclosure(function(obj, ...)
    bind:Fire(env.get_namecall(), obj, ...)

    if blocked[obj] then
        print(obj.Name .. " is blocked")
        return
    end

    return nmc(obj, ...)
end)

getgenv().remotes = remotes

--[[
    I N T E R F A C E   F U N C T I O N S
]]--

-- RemoteObject selection & visual detail
for i, option in next, options:GetChildren() do
    if option:IsA("TextButton") then
        option.MouseButton1Click:Connect(function()
            local old = window[selected_option]
            local old_anim = tween_service:Create(options[selected_option], TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(35, 35, 35)})
            local new_anim = tween_service:Create(option, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(35, 35, 35)})
        
            old.Visible = false
            old_anim:Play()

            window[option.Name].Visible = true
            new_anim:Play()

            selected_option = option.Name
            inspect.Remote.Icon.Image = "rbxassetid://" .. oh.icons[selected_option]
        end)

        aux.apply_highlight(option, Color3.fromRGB(40, 40, 40), Color3.fromRGB(40, 40, 40), false, selected_option ~= option.Name)
    end
end

getgenv().events = drop_down_events

mouse.Button1Up:Connect(function()
    drop_down.Visible = false
    idrop_down.Visible = false
end)

for i,v in next, drop_down:GetChildren() do
    if v:IsA("TextButton") then
        v.MouseButton1Click:Connect(function()
            drop_down.Visible = false
        end)

        aux.apply_highlight(v)
    end
end

for i,v in next, idrop_down:GetChildren() do
    if v:IsA("TextButton") then
        v.MouseButton1Click:Connect(function()
            idrop_down.Visible = false
        end)

        aux.apply_highlight(v)
    end
end

-- Ignore/Spy button inside the inspector
inspect.Toggle.MouseButton1Click:Connect(function() 
    local old_context = env.get_thread_context()
    env.set_thread_context(6)

    ignore[selected_remote] = not ignore[selected_remote]

    local remote = remotes[selected_remote]
    if ignore[selected_remote] then
        inspect.Toggle.Text = "Spy"
        remote.window.Label.TextColor3 = Color3.fromRGB(100, 100, 100)
    else
        inspect.Toggle.Text = "Ignore"
        remote.window.Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    end

    env.set_thread_context(old_context)
end)

-- Clear button inside the inspector
inspect.Clear.MouseButton1Click:Connect(function()
    local old_context = env.get_thread_context()
    env.set_thread_context(6)

    local remote = remotes[selected_remote]
    remote.logs = 0
    remote.window.Count.Text = "0"

    for i, result in next, inspect.Results:GetChildren() do
        if not result:IsA("UIListLayout") then
            result:Destroy()
        end
    end

    remotes[selected_remote].logged = {}
    inspect.Results.CanvasSize = UDim2.new(0, 0, 0, 0)

    env.set_thread_context(old_context)
end)

conditions.Add.MouseButton1Click:Connect(function()
    conditions.AddCondition.Visible = true
end)

local add_condition = conditions.AddCondition
local condition_type = add_condition.Types.String

add_condition.Add.MouseButton1Click:Connect(function()
    local parameter = assets.Parameter:Clone()
    local type = condition_type.Name:lower()
    local new_size = UDim2.new(0, 0, 0, 16)

    parameter.Label.Text = add_condition.Value.Text
    parameter.Parent = add_condition.Parameters
    parameter.Icon.Image = condition_type.Icon.Image

    add_condition.Parameters.CanvasSize = add_condition.Parameters.CanvasSize + new_size

    if add_condition.Value.Text:gsub(' ', '') == "" then
        parameter.Label.Text = "nil"
        return
    end

    if type == "function" or type == "table" or type == "userdata" then
        parameter.Label.Text = type
    end

    while not parameter.Label.TextFits do
        parameter.Size = parameter.Size + new_size
        add_condition.Parameters.CanvasSize = add_condition.Parameters.CanvasSize + new_size
        wait()
    end

    parameter.MouseButton1Click:Connect(function()
        
    end)
end) 

add_condition.Ignore.MouseButton1Click:Connect(function()
    add_condition.Visible = false
    table.insert(remotes[selected_remote].ignored_args)
end)

add_condition.Block.MouseButton1Click:Connect(function()
    add_condition.Visible = false
end)

for i,v in next, add_condition.Types:GetChildren() do
    if v:IsA("Frame") then
        v.Toggle.MouseButton1Click:Connect(function()
            condition_type.Toggle.Image = "rbxassetid://4137040743" 
            v.Toggle.Image = "rbxassetid://4136986319"
            condition_type = v
        end)
    end
end
