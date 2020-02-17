local user_input = game:GetService("UserInputService")
local tween_service = game:GetService("TweenService")
local players = game:GetService("Players")

local client = players.LocalPlayer
local mouse = client:GetMouse()

local tab_text = {
    ConstantScanner = "Constant Scanner",
    UpvalueScanner = "Upvalue Scanner",
    ModuleScanner = "Module Scanner",
    ScriptScanner = "Script Scanner"
}

local from_disk = true

getgenv().oh = {}
getgenv().import = function(file)
    if type(file) == "number" then
        return game:GetObjects("rbxassetid://" .. file)[1]
    end

    if from_disk then
        return loadfile("Hydroxide/" .. file)()
    else
        return loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/nrv-ous/Hydroxide/rebirth" .. file))()
    end
end

oh.icons = {
	table = "rbxassetid://4666594276",
	["function"] = "rbxassetid://4666593447",
	userdata = "rbxassetid://4666594723",
	string = "rbxassetid://4666593882",
	number = "rbxassetid://4666593882",
	boolean = "rbxassetid://4666593882"
}

oh.default_syntax = Color3.fromRGB(200, 200, 200)
oh.syntax = {
    number = Color3.fromRGB(170, 225, 127),
    string = Color3.fromRGB(225, 150, 85),
    boolean = Color3.fromRGB(127, 200, 255)
}

oh.methods = {
    get_metatable = getrawmetatable or debug.getmetatable or false,
    get_constants = debug.getconstants or getconstants or getconsts or false,
    get_upvalues = debug.getupvalues or getupvalues or getupvals or false,
    get_constant = debug.getconstant or getconstant or getconsts or false,
    get_upvalue = debug.getupvalue or getupvalue or getupval or false,
    get_info = debug.getinfo or getinfo or false,
    get_gc = getgc or false,

    set_clipboard = setclipboard or (syn and syn.write_clipboard) or false,
    set_constant = debug.setconstant or setconstant or setconst or false,
    set_upvalue = debug.setupvalue or setupvalue or setupval or false,

    is_l_closure = islclosure or (newcclosure and function(closure) return not newcclosure(closure) end) or false,
    is_x_closure = is_synapse_function or issentinelclosure or is_protosmasher_closure or is_sirhurt_closure or checkclosure or false
}

oh.assert = function(required)
    local bork = ""
    for i,v in pairs(required) do
        if not oh.methods[v] then
            bork = bork .. v
        end
    end

    if bork ~= "" then
        oh.message("ok", ("You cannot use this section; your exploit is missing these functions: %s"):format(bork))
        error("yonks!")
    end
end

oh.to_string = function(data)
    if type(data) == "table" then
        local metatable = oh.methods.get_metatable(data)
        local __tostring
        local condition = metatable and __tostring
        local real_data
        
        if metatable then
            __tostring = metatable.__tostring
        end

        if condition then
            oh.methods.set_readonly(metatable, false)
            metatable.__tostring = nil
        end

        real_data = tostring(data)

        if condition then
            metatable.__tostring = __tostring
            oh.methods.set_readonly(metatable, true)
        end

        return real_data
    else
        return tostring(data)
    end
end

oh.get_closure = function(info)
	local gets = getconstants
	local get = getconstant

	if info.type == 'u' then
		gets = getupvalues
		get = getupvalue
	end

	for i,v in pairs(getgc()) do
		if type(v) == "function" and islclosure(v) and not is_synapse_function(v) and #gets(v) == info.amount then
			if get(v, info.index) == info.value then
				return v
			end
		end
	end
end

oh.create_right_click = function(object, events)
    if oh.right_click then
        oh.right_click.disconnect()

        if oh.right_click.object ~= object then
            oh.right_click.exit()
        end
    end

    oh.right_click = {}
    oh.right_click.object = object
    oh.right_click.disconnect = function()
        for i,v in pairs(events) do
            v:Disconnect()
        end
    end

    oh.right_click.exit = function()
        oh.right_click.disconnect()
        oh.right_click.object.Visible = false
        oh.right_click = nil
    end
end

oh.execute = function()
    oh.ui.Parent = game:GetService("CoreGui")

    local dragging
    local dragInput
    local dragStart
    local startPos

    local show = oh.ui.Show
    local base = oh.ui.Base
    local drag = base.Drag
    local body = base.Body

    local tabs = body.Contents.Tabs
    local selection = body.Tabs
    local contents = selection.Body.Contents
    local selected

    local showing = true

    local show_position = UDim2.new(0.5, -250, 0.5, -200)
    local hide_position = UDim2.new(0.5, -250, 0, -500)

    local show_toggle = UDim2.new(0.5, -10, 0, 5)
    local hide_toggle = UDim2.new(0.5, -10, 0, -100)

    drag.Collapse.MouseButton1Click:Connect(function()
        if showing then
            base:TweenPosition(hide_position, "Out", "Quad", 0.35)
            show:TweenPosition(show_toggle, "In", "Quad", 0.35)
            showing = false
        end
    end)

    show.MouseButton1Click:Connect(function()
        if not showing then
            base:TweenPosition(show_position, "In", "Quad", 0.35)
            show:TweenPosition(hide_toggle, "Out", "Quad", 0.35)
            showing = true
        end
    end)

    for i,v in pairs(contents:GetChildren()) do
        if v:IsA("ImageButton") then
            local time = TweenInfo.new(0.15)
            local hover = tween_service:Create(v.Icon, time, { ImageTransparency = 0.1 })
            local leave = tween_service:Create(v.Icon, time, { ImageTransparency = 0.35 })
            local clicked = tween_service:Create(v.Icon, time, { ImageTransparency = 0 })

            v.MouseEnter:Connect(function()
                if selected ~= v then
                    hover:Play()
                end
            end)

            v.MouseLeave:Connect(function()
                if selected ~= v then
                    leave:Play()
                end
            end)

            v.MouseButton1Click:Connect(function()
                if selected == v then
                    return
                end

                local old_selected = selected

                clicked:Play()
                selected = v

                tabs[v.Name].Visible = true

                selection.Title.Text = tab_text[v.Name] or v.Name

                if old_selected then
                    tabs[old_selected.Name].Visible = false
                    tween_service:Create(old_selected.Icon, time, { ImageTransparency = 0.35 }):Play()
                else
                    tabs.Home.Visible = false
                end
            end)
        end
    end

    drag.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = base.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    drag.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    user_input.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            base.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    oh.message("ok", "Notice!", "The only working feature as of 2/16/20 is the Upvalue Scanner!")
end

mouse.Button1Up:Connect(function()
    if oh.right_click then
        oh.right_click.exit()
    end
end)