local players = game:GetService("Players")
local run_service = game:GetService("RunService")
local tween_service = game:GetService("TweenService")

local client = players.LocalPlayer
local mouse = client:GetMouse()

local aux = oh.auxiliary
local env = oh.environment

local assets = oh.assets
local gui = oh.gui
local base = gui.Base
local drop_down = {
    upvalue = gui.UpvalueDropdown,
    closure = gui.FunctionDropdown
}

local body = base.Body

local window = body.Tabs.UpvalueScanner
local results = window.Results

local set_upvalue = window.SetValue

local poll = false
local functions = {}
local events = {}

--[[
    A U X I L I A R Y
]]--

local find_upvalues = function(value)
    local results = {}

    for i,v in next, env.get_gc() do
        if type(v) == "function" and not env.is_x_closure(v) then
		warn(v)
            results[v] = {}
            for k,x in next, env.get_upvalues(v) do
                if (type(x) == "string" and x:find(value)) or tostring(x) == tostring(value) then
                    table.insert(results[v], k, x)
                end 
            end

			if #results[v] == 0 then 
				results[v] = nil
			end
        end
    end

    return results
end

--[[
    C O R E
]]--

local make_log = function(closure)
    local closure_pod = assets.Function:Clone()
    local name = tostring(closure)

    closure_pod.Name = name
    closure_pod.Label.Text = name
    closure_pod.Parent = results

    results.CanvasSize = results.CanvasSize + UDim2.new(0, 0, 0, 16)

    return closure_pod
end

local selected_edit_type = set_upvalue.Types.String
local edit_current_upvalue = function(closure, index)
    local raw_value = set_upvalue.Input.Text
    local selected_edit_type = selected_edit_type.Name:lower()

    events.set_upvalue = set_upvalue.Change.MouseButton1Click:Connect(function()
        if selected_edit_type == "string" then
        elseif selected_edit_type == "number" then
            raw_value = tonumber(raw_value) or 0
        elseif selected_edit_type == "boolean" then
            raw_value = raw_value == "true"
        else
            local success, result = pcall(loadstring("return " .. raw_value))
            local typeof
            local init = Color3.fromRGB(150, 0, 0)
            local exit = Color3.fromRGB(200, 200, 200)
            local init_animation = tween_service:Create(set_upvalue.Input, TweenInfo.new(0.1), {TextColor3 = init})
            local exit_animation = tween_service:Create(set_upvalue.Input, TweenInfo.new(0.1), {TextColor3 = init})

            if success then
                raw_value = result 
                typeof = type(raw_value)
            else
                init_animation:Play()
                wait(0.1)
                exit_animation:Play()
                return
            end

            if (selected_edit_type == "table" and typeof ~= "table") 
            or (selected_edit_type == "function" and typeof ~= "function")
            or (selected_edit_type == "userdata" and typeof ~= "userdata") then
                init_animation:Play()
                wait(0.1)
                exit_animation:Play()
                return
            end 
        end

        env.set_upvalue(closure, index, raw_value)
        events.set_upvalue:Disconnect()
        events.set_upvalue = nil
        set_upvalue.Visible = false
    end)
end

local make_upvalue = function(container, closure, index, value)
    local upvalue = assets.Upvalue:Clone()
    local new_size = UDim2.new(0, 0, 0, 16)
    local cached_value = value

    upvalue.Icon.Image = oh.icons[type(value)]
    upvalue.Index.Text = tostring(index)
    upvalue.Value.Text = tostring(value)
    upvalue.Parent = container.Upvalues

    container.Size = container.Size + new_size
    results.CanvasSize = results.CanvasSize + new_size

    while not upvalue.Value.TextFits do
        upvalue.Size = upvalue.Size + new_size
        container.Size = container.Size + new_size
        results.CanvasSize = results.CanvasSize + new_size
    end
    
    upvalue.MouseButton2Click:Connect(function()
        if not set_upvalue.Visible then
            if events.change and events.reset and events.script then
                events.change:Disconnect()
                events.reset:Disconnect()
                events.script:Disconnect()
                events.change = nil
                events.reset = nil
                events.script = nil
            end

            drop_down.upvalue.Position = UDim2.new(0, mouse.X + 5, 0, mouse.Y + 5)

            events.change = drop_down.upvalue.Change.MouseButton1Click:Connect(function()
                set_upvalue.Visible = true
                drop_down.upvalue.Visible = false
                edit_current_upvalue(closure, index)
            end)

            events.reset = drop_down.upvalue.Reset.MouseButton1Click:Connect(function()
                env.set_upvalue(closure, index, cached_value)
                drop_down.upvalue.Visible = false
            end)

            events.script = drop_down.upvalue.Script.MouseButton1Click:Connect(function()
                drop_down.upvalue.Visible = false
            end)

            drop_down.upvalue.Visible = true
        end
    end)

    return upvalue
end

local create_closure = function(closure, upvalues)
    if functions[closure] then
        return functions[closure]
    end

    local closure_data = {}

    closure_data.upvalues = {}
    closure_data.window = make_log(closure)

    closure_data.update = function()
        local new_size = UDim2.new(0, 0, 0, 16)

        for index,upvalue in next, closure_data.upvalues do
            upvalue.Value.Text = tostring(env.get_upvalue(closure, index))

            while not upvalue.Value.TextFits do
                upvalue.Size = upvalue.Size + new_size
                closure_data.window.Size = closure_data.window.Size + new_size
                results.CanvasSize = results.CanvasSize + new_size
            end
        end
    end

    for index,value in next, upvalues do
        closure_data.upvalues[index] = make_upvalue(closure_data.window, closure, index, value)        
    end

    return closure_data
end

--[[
    I N T E R F A C E
]]--

window.Query:GetPropertyChangedSignal("Text"):Connect(function()
    poll = false
end)

local search_upvalues = function()
    if window.Query.Text:gsub(' ', '') == "" then
        return
    end

    for i, result in next, results:GetChildren() do
        if result:IsA("Frame") then
            result:Destroy()
        end
    end

    results.CanvasSize = UDim2.new(0, 0, 0, 0)

    functions = {}

    for closure,upvalues in next, find_upvalues(window.Query.Text) do
        functions[closure] = create_closure(closure, upvalues) 
    end

    window.Query.Text = ""
    poll = true
end

window.Query.FocusLost:Connect(function(returned)
    if returned then
        search_upvalues()
    end
end)

window.Find.MouseButton1Click:Connect(search_upvalues)

set_upvalue.Cancel.MouseButton1Click:Connect(function()
    set_upvalue.Visible = false
end)

-- E V E N T S
mouse.Button1Up:Connect(function()
    drop_down.upvalue.Visible = false
end)

-- Upvalue Polling
oh.event_list.poll_upvalues = run_service.RenderStepped:Connect(function()
    if poll then
        for i,upvalues in next, functions do
            upvalues.update()
        end
    end
end)

for i,type in next, set_upvalue.Types:GetChildren() do
    if type:IsA("Frame") then
        type.Toggle.MouseButton1Click:Connect(function()
            selected_edit_type.Toggle.Image = "rbxassetid://4137040743" 
            type.Toggle.Image = "rbxassetid://4136986319"
            selected_edit_type = type
        end)
    end
end
