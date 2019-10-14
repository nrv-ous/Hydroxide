local env = oh.env
local aux = oh.aux
local assets = oh.assets

local body = oh.gui.Base.Body
local tabs = body.Tabs
local window = tabs.RemoteSpy
local inspect = tabs.RemoteSpyInspection
local options = window.Options

local selected_remote 
local selected_option = "RemoteEvent"
local remotes = {}
local ignore = {}

local tween_service = game:GetService("TweenService")

local gmt = env.get_metatable(game)
local nmc = gmt.__namecall

--[[
    A U X I L I A R Y
]]--


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
            result = result .. '[' .. ("game." .. i:GetFullName())
        else
            result = result .. '[' .. tostring(i)
        end
        result = result .. ((type(i) == "string" and ((i:find("%A") and "] = ") or " = ")) or (type(i) ~= "number" and '] = ') or "")

        if type(v) == "table" then
            result = result .. dump_table(v) 
        elseif type(v) == "string" then
            result = result .. '"' .. v .. '"'
        elseif typeof(v) == "Instance" then
            result = result .. ("game." .. v:GetFullName())
        elseif typeof(v) == "Vector3" then
            result = result .. "Vector3.new(" .. tostring(v) .. ")"
        elseif typeof(v) == "CFrame" then
            result = result .. "CFrame.new(" .. tostring(v) .. ")"
        elseif typeof(v) == "Color3" then
            result = result .. "Color3.new(" .. tostring(v) .. ")"
        else
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
            result = result .. "game." .. v:GetFullName()
        elseif typeof(v) == "Vector3" then
            result = result .. "Vector3.new(" .. tostring(v) .. ")"
        elseif typeof(v) == "CFrame" then
            result = result .. "CFrame.new(" .. tostring(v) .. ")"
        elseif typeof(v) == "Color3" then
            result = result .. "Color3.new(" .. tostring(v) .. ")"
        else
            result = result .. tostring(v)
        end

        result = result .. '\n'
    end

    local feed = ""

    for i = 1, #params do
        feed = feed .. "oh" .. i .. ", "
    end

    if compact then
        local lresult = ""
        for i,v in next, params do
            if type(v) == "table" then
                v = dump_table(v)
            elseif typeof(v) == "Instance" then
                v = "game." .. v:GetFullName()
            elseif typeof(v) == "Vector3" then
                v = "Vector3.new(" .. v .. ")"
            elseif typeof(v) == "CFrame" then
                v = "CFrame.new(" .. v .. ")"
            elseif typeof(v) == "Color3" then
                v = "Color3.new(" .. v .. ")"
            end

            lresult = lresult .. tostring(v) .. ", "
        end
        result = "game." .. remote:GetFullName() .. ':' .. method .. '(' .. lresult:sub(1, lresult:len() - 2) .. ')'
    else
        result = result .. "game." .. remote:GetFullName() .. ':' .. method .. '(' .. feed:sub(1, feed:len() - 2) .. ')'
    end

    return result
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
        parameter.Size = parameter.Size + increment
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

    container.MouseButton1Click:Connect(function()
        env.to_clipboard(toscript(false, remote, parameters))
    end)

    aux.apply_highlight(container)
end


local is_remote = function(object)
    local ran, result = pcall(function()
        return object:IsA("RemoteEvent") or object:IsA("RemoteFunction") or object:IsA("BindableEvent") or object:IsA("BindableFunction")
    end)

    return (ran and (result and {logs = 0, logged = {}})) or nil
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
        local old_context = env.get_thread_context()
        env.set_thread_context(6)

        if not remotes[obj] then
            remotes[obj] = is_remote(obj)
            local asset = assets.RemoteObject:Clone()
            local b_toggle = asset.Toggle
            local b_inspect = asset.Inspect
            remotes[obj].window = asset
            local logs = window[obj.ClassName]
            asset.Name = obj.Name
            asset.Parent = logs
            asset.Label.Text = obj.Name
            asset.Icon.Image = "rbxassetid://" .. oh.icons[obj.ClassName]
            logs.CanvasSize = logs.CanvasSize + UDim2.new(0, 0, 0, 25)
        
            aux.apply_highlight(b_toggle)
            aux.apply_highlight(b_inspect)
            b_toggle.AutoButtonColor = false
            b_inspect.AutoButtonColor = false
        
            b_toggle.MouseButton1Click:Connect(function()
                local old_context = env.get_thread_context()
                env.set_thread_context(6)
                ignore[obj] = not ignore[obj]
        
                if ignore[obj] then
                    local anim = tween_service:Create(asset.Label, TweenInfo.new(0.1), {TextColor3 = Color3.fromRGB(100, 100, 100)})
                    anim:Play()
                    asset.Toggle.Text = "Spy"
                    inspect.Toggle.Text = "Spy"
                else
                    local anim = tween_service:Create(asset.Label, TweenInfo.new(0.1), {TextColor3 = Color3.fromRGB(200, 200, 200)})
                    anim:Play()
                    asset.Toggle.Text = "Ignore"
                    inspect.Toggle.Text = "Ignore"
                end
        
                env.set_thread_context(old_context)
            end)
        
            b_inspect.MouseButton1Click:Connect(function()
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

        option.MouseButton1Down:Connect(function()
            if selected_option ~= option.Name then
                local anim = tween_service:Create(option, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)})
                anim:Play()
            end
        end)

        option.MouseButton1Up:Connect(function()
            if selected_option ~= option.Name then
                local anim = tween_service:Create(option, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(35, 35 ,35)})
                anim:Play()
            end
        end) 

        option.MouseEnter:Connect(function()
            if selected_option ~= option.Name then
                local anim = tween_service:Create(option, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)})
                anim:Play()
            end
        end) 

        option.MouseLeave:Connect(function()
            if selected_option ~= option.Name then
                local anim = tween_service:Create(option, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(35, 35 ,35)})
                anim:Play()
            end
        end)
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
        remote.window.Toggle.Text = "Spy"
        remote.window.Label.TextColor3 = Color3.fromRGB(100, 100, 100)
    else
        inspect.Toggle.Text = "Ignore"
        remote.window.Toggle.Text = "Ignore"
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

    inspect.Results.CanvasSize = UDim2.new(0, 0, 0, 0)

    env.set_thread_context(old_context)
end)