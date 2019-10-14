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

-- Used to check if a specified object is actually a RemoteObject, if it is then it assigns a table to it.
local is_remote = function(object)
    local ran, is_remote = pcall(function()
        return object:IsA("RemoteEvent") or object:IsA("RemoteFunction") or object:IsA("BindableEvent") or object:IsA("BindableFunction")
    end)

    if ran and is_remote then
        local remote_data = {
            logs = 0, -- Amount of times the remote is called
            logged = {}, -- Where parameters will be stored
            ignored_args = {} -- Paramters in here will determine if the remote is logged or not
        }

        return remote_data 
    end
end

--[[
    I N T E R F A C E
]]--

-- Function used to visualize RemoteObject parameters
local create_remote_data = function(parameters)
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
        parameter.Label.Text = (typeof(v) == "Instance" and value.Name) or tostring(v)
        parameter.Parent = container

        -- Change the size of the parameter's element to fit the literal value length
        repeat
            local increment = UDim2.new(0, 0, 0, 16)
            parameter.Size = parameter.Size + increment
            container.Size = container.Size + increment
            inspect.Results.CanvasSize = inspect.Results.CanvasSize + increment
            wait()
        until parameter.Label.TextFits

        -- If a __tostring method was found, then reset it to avoid detection
        if __tostring then
            metatable.__tostring = __tostring
            env.set_readonly(metatable, true)
        end
    end

    aux.apply_highlight(container)
end

-- Log any remote that has just been recently stored
setmetatable(remotes, { __newindex = function(t, remote, remote_data)
    if not is_remote(remote) then return end

    local class_logs = window[remote.ClassName]
    local log = assets.RemoteObject:Clone()

    log.Name = remote.Name
    log.Parent = class_logs
    log.Label.Text = remote.Name
    log.Icon.Image = "rbxassetid://" .. oh.icons[remote.ClassName]

    class_logs.CanvasSize = class_logs.CanvasSize + UDim2.new(0, 0, 0, 25)

    log.Inspect.MouseButton1Click:Connect(function()
        local old_context = env.get_thread_context()
        env.set_thread_context(6)

        -- If the newly selected remote is not the previous, then change the previously logged parameters to the current ones
        if selected_remote ~= remote then
            -- Remove any old logged parameters
            for i, parameter in next, inspect.Results:GetChildren() do
                if not parameter:IsA("UIListLayout") then
                    parameter:Destroy()
                end
            end

            -- Reset the canvas size
            inspect.Results.CanvasSize = UDim2.new(0, 0, 0, 0)

            -- Create new parameter logs for the current remote
            for i, parameters in next, remotes[remote].logged do
                create_remote_data(parameters)
            end
        end

        -- Set the text of the inspection label to the current remote's name
        local label = inspect.Remote.Label
        label.Text = log.Name
        label.Size = UDim2.new(0, -(label.TextBoundsX + 5), 0, 25)
        label.Position = UDim2.new(0, -(label.TextBoundsX + 10), 0, 25)
        inspect.Remote.Icon.Position = UDim2.new(-(label.TextBounds.X + 35), 0, 0)

        body.TabsLabel.Text = "  RemoteSpy : Inspection"

        -- Change the currently selected extension to the inspection tab
        inspect.Visible = true
        oh.selected_extension.Visible = false
        oh.selected_extension = inspection
        selected_remote = remote

        env.set_thread_context(old_context)
    end)

    -- ignore/spy
    log.Toggle.MouseButton1Click:Connect(function() 
        local old_context = env.get_thread_context()
        env.set_thread_context(6)

        ignore[remote] = not ignore[remote]

        if ignore[remote] then
            local anim = tween_service:Create(log.Label, TweenInfo.new(0.1), {TextColor3 = Color3.fromRGB(100, 100, 100)})
            anim:Play()
            asset.Toggle.Text = "Spy"
            inspect.Toggle.Text = "Spy"
        else
            local anim = tween_service:Create(log.Label, TweenInfo.new(0.1), {TextColor3 = Color3.fromRGB(200, 200, 200)})
            anim:Play()
            asset.Toggle.Text = "Spy"
            inspect.Toggle.Text = "Spy"
        end

        env.set_thread_context(old_context)
    end)
end})

--[[
    C O R E 
]]--

-- The infamous namecall hook :flushed:
setreadonly(gmt, false)
gmt.__namecall = env.new_cclosure(function(object, ...) 
    local vargs = {...}    
    local methods = {
        FireServer = true,
        InvokeServer = true,
        Fire = true,
        Invoke = true
    }

    -- Check if a remote method has been called, and if it is then check if it's not being ignored
    if methods[env.get_namecall()] and not ignore[object] then 
        local old_context = env.get_thread_context()
        env.set_thread_context(6)

        -- If the remote was not stored, then store it
        if not remotes[object] then
            remotes[object] = is_remote(object) 
        end
        
        local remote = remotes[object]

        -- If we are currently viewing the remote, then log the call
        if selected_remote == object then
            create_remote_data(vargs)
        end

        -- Put remote call in storage
        table.insert(remote.logged, vargs)

        -- Count how many times the remote has been called
        remote.logs = remote.logs + 1
        remote.window.Count.Text = (remote.Logs <= 999 and remote.Logs) or "..." -- If the call exceeds 999, then change the text to an ellipsis

        env.set_thread_context(old_context)
    end 

    return nmc(object, ...)
end)

game.DescendantRemoving:Connect(function(object) 
    local old_context = env.get_thread_context()
    env.set_thread_context(6)

    if not object:IsDescendantOf(game) and remotes[object] then
        local logs = window[object.ClassName]
        local window = remotes[object].window

        logs.CanvasSize = logs.CanvasSize - window.Size
        window:Destroy()
        remotes[object] = nil
    end

    env.set_thread_context(old_context)
end)

--[[
    I N T E R F A C E 
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
        if not v:IsA("UIListLayout") then
            v:Destroy()
        end
    end

    inspect.Results.CanvasSize = UDim2.new(0, 0, 0, 0)

    env.set_thread_context(old_context)
end)