local upvalue_scanner = {}
upvalue_scanner.functions = {
    "is_x_closure",
    "get_upvalues",
    "get_upvalue",
    "set_upvalue",
    "set_clipboard",
    "get_gc"
}

local players = game:GetService("Players")
local run_service = game:GetService("RunService")
local tween_service = game:GetService("TweenService")
local text_service = game:GetService("TextService")

local client = players.LocalPlayer
local mouse = client:GetMouse()

local assets = oh.assets.UpvalueScanner

local base = oh.ui.Base

local tab = base.Body.Contents.Tabs.UpvalueScanner
local change_upvalue = base.SetUpvalue

local right_click = oh.ui.RightUpvalueScanner
local right_click_added = oh.ui.RightAdded

local main = tab.Main
local results = main.Results.Clip.Contents
local query = main.Filter.Query
local search_in_tables = main.Options.SearchInTables

local current_upvalues = {} 
local results_size = UDim2.new(0, 0, 0, 16)

local time = TweenInfo.new(0.15)
local enter_color = Color3.fromRGB(170, 0, 0)
local leave_color = Color3.fromRGB(40, 40, 40)

run_service.RenderStepped:Connect(function()
    for closure, object in pairs(current_upvalues) do
        for i,v in pairs(object.upvalues) do
            v:update()
        end
    end
end)

local change_type = change_upvalue.Body.ChangeType
local list = change_type.List

for i,v in pairs(list.Clip.Types:GetChildren()) do
    if v:IsA("TextButton") then
        v.MouseButton1Click:Connect(function()
            change_type.Icon.Image = oh.icons[v.Name]
            change_type.Label.Text = v.Name

            list.Visible = false
        end)
    end
end

for i,v in pairs(change_upvalue.Body.Options:GetChildren()) do
    if v:IsA("ImageButton") then
        local enter = tween_service:Create(v, time, {ImageColor3 = enter_color})
        local leave = tween_service:Create(v, time, {ImageColor3 = leave_color})

        v.MouseEnter:Connect(function()
            enter:Play()
        end)

        v.MouseLeave:Connect(function()
            leave:Play()
        end)
    end
end

local view_change_value
view_change_value = function(closure, index)
    local body = change_upvalue.Body
    local change_type = body.ChangeType
    local new_value = body.NewValue.TextBox
    local options = body.Options

    local events = {}
    local close = function()
        for i,v in pairs(events) do
            v:Disconnect()
        end

        change_upvalue.Visible = false
    end

    local upvalues = #oh.methods.get_upvalues(closure.data)

    change_upvalue.Visible = true

    if index > upvalues then
        index = upvalues
        change_upvalue.Visible = false
        oh.message("ok", "Fatal error", "The upvalue index does not exist in the function, max is " .. upvalues, function() change_upvalue.Visible = true end)
    end

    local data = oh.methods.get_upvalue(closure.data, index)
    local data_type = type(data)

    change_type.Icon.Image = oh.icons[data_type]
    change_type.Label.Text = data_type

    body.Index.Input.Text = index

    new_value.Text = oh.to_string(data)

    events.change_type = change_type.Collapse.MouseButton1Click:Connect(function()
        change_type.List.Visible = not change_type.List.Visible
    end)

    events.index_change = body.Index.Input.FocusLost:Connect(function()
        local index = tonumber(body.Index.Input.Text)
        
        if not index then
            for i,v in pairs(closure.upvalues) do
                index = i
                break
            end
        end

        close()
        view_change_value(closure, index)
    end)

    events.set_upvalue = options.Set.MouseButton1Click:Connect(function()
        local chosen_type = change_type.Label.Text
        local chosen_data = new_value.Text

        local fail = function(message)
            change_upvalue.Visible = false
            oh.message("ok", "Fatal error", message or "The selected type does not match your input.", function() change_upvalue.Visible = true end)
        end

        if chosen_type == "number" then
            chosen_data = tonumber(chosen_data)

            if not chosen_data then
                return fail()
            end
        elseif chosen_type == "boolean" then
            if chosen_data == "true" then
                chosen_data = true
            elseif chosen_data == "false" then
                chosen_data = false
            else
                return fail()
            end
        elseif chosen_type == "function" then
            local ran, result = pcall(loadstring("return " .. chosen_data))
            if not ran then
                return fail("Your function input has an error.")
            else
                if type(result) ~= "function" then
                    return fail()
                end
            end

            chosen_data = result
        elseif chosen_type == "table" then
            local ran, result = pcall(loadstring("return " .. chosen_data))
            if not ran then
                return fail("Your table input has an error.")
            else
                if type(result) ~= "table" then
                    return fail()
                end
            end

            chosen_data = result
        elseif chosen_type == "userdata" then
            local ran, result = pcall(loadstring("return " .. chosen_data))
            if not ran then
                return fail("Your userdata input has an error.")
            else
                if type(result) ~= "userdata" then
                    return fail()
                end
            end

            chosen_data = result
        end

        oh.methods.set_upvalue(closure.data, index, chosen_data)
        close()
    end)

    events.exit = options.Cancel.MouseButton1Click:Connect(function()
        close()
    end)
end

local update = function(upvalue)
    local closure = upvalue.closure
    local value_check = oh.methods.get_upvalue(closure.data, upvalue.index) 

    if value_check ~= value then
        local closure_ui = closure.ui
        local ui_object = upvalue.ui
        local value_type = type(value_check)

        if value_type ~= type(value) then
            ui_object.Label.TextColor3 = oh.syntax[value_type] or oh.default_syntax
            ui_object.Icon.Image = oh.icons[value_type] or ""
        end

        value = value_check
        
        ui_object.Label.Text = oh.to_string(value)

        if not ui_object.Label.TextFits then
            local height = text_service:GetTextSize(oh.to_string(value), 16, "SourceSans", Vector2.new(ui_object.AbsoluteSize.X, 133742069)).Y + 4
            local old_height = UDim2.new(0, 0, 0, ui_object.AbsoluteSize.Y)
            local new_height =  UDim2.new(0, 0, 0, height + 5)

            closure_ui.Size = closure_ui.Size - old_height
            results.CanvasSize = results.CanvasSize - old_height

            ui_object.Size = UDim2.new(1, -40, 0, height)
            closure_ui.Size = closure_ui.Size + new_height
            results.CanvasSize = results.CanvasSize + new_height
        end
    end
end

local remove = function(upvalue)
    local ui_object = upvalue.ui
    local remove_size = UDim2.new(0, 0, 0, ui_object.AbsoluteSize.Y + 5)

    upvalue.closure.upvalues[upvalue.index] = nil
    ui_object:Destroy()

    upvalue.closure.ui.Size = upvalue.closure.ui.Size - remove_size
    results.CanvasSize = results.CanvasSize - remove_size
end

local new_upvalue = function(closure, index, value, attributes)
    if closure.upvalues[index] then
        return
    end

    local object = {}
    local closure_ui = closure.ui
    local ui_object

    if attributes and attributes.added then
        ui_object = assets.AddedUpvalue:Clone()
        ui_object.MouseButton2Click:Connect(function()
            local events = {}
            oh.create_right_click(right_click_added, events) 

            right_click_added.Visible = true
            right_click_added.Position = UDim2.new(0, mouse.X + 5, 0, mouse.Y + 5)

            events.remove = right_click_added.List:FindFirstChild("Remove").MouseButton1Click:Connect(function()
                object:remove()
                oh.right_click.exit()
            end)
        end)

        object.added = true
    elseif not attributes then
        ui_object = assets.Upvalue:Clone()
    end

    local height = text_service:GetTextSize(oh.to_string(value), 16, "SourceSans", Vector2.new(ui_object.AbsoluteSize.X, 133742069)).Y + 4
    local new_height = UDim2.new(0, 0, 0, height + 5)

    local value_type = type(value)

    ui_object.Size = UDim2.new(1, -40, 0, height)
    ui_object.Parent = closure_ui.Contents

    ui_object.Index.Text = index
    ui_object.Label.Text = oh.to_string(value)
    ui_object.Label.TextColor3 = oh.syntax[value_type] or oh.default_syntax

    ui_object.Icon.Image = oh.icons[value_type]

    object.ui = ui_object
    object.closure = closure
    object.index = index
    object.update = update
    object.remove = remove
    
    closure_ui.Size = closure_ui.Size + new_height
    results.CanvasSize = results.CanvasSize + new_height
    closure.upvalues[index] = object

    return object
end

local new_closure = function(closure)
    local object = {}
    local viewing_all_upvalues = false
    local ui_object = assets.Function:Clone()
    local list = right_click.List
    local name = oh.methods.get_info(closure).name

    object.ui = ui_object
    object.data = closure
    object.upvalues = {}
    object.new_upvalue = new_upvalue
    object.name = ((name == "" or not name) and tostring(closure)) or name

    ui_object.Icon.Image = oh.icons["function"]
    ui_object.Label.Text = object.name
    ui_object.Parent = results

    list.ViewAllUpvalues.Label.Text = "View All Upvalues"

    ui_object.Label.MouseButton2Click:Connect(function()
        local events = {}

        oh.create_right_click(right_click, events)

        right_click.Visible = true
        right_click.Position = UDim2.new(0, mouse.X + 5, 0, mouse.Y + 5)

        events.view_upvalues = list.ViewAllUpvalues.MouseButton1Click:Connect(function()
            viewing_all_upvalues = not viewing_all_upvalues
            
            if viewing_all_upvalues then
                for i,v in pairs(oh.methods.get_upvalues(closure)) do
                    object:new_upvalue(i, v, (not object.upvalues[i] and {added = true}) or nil)
                end

                list.ViewAllUpvalues.Label.Text = "Delete Unrelated"
            else
                for i,v in pairs(object.upvalues) do
                    if v.added then
                        v:remove()
                    end
                end

                list.ViewAllUpvalues.Label.Text = "View All Upvalues"
            end

            oh.right_click.exit()
        end)

        events.closure_spy = list.ClosureSpy.MouseButton1Click:Connect(function()
            oh.right_click.exit()
        end)

        events.change_value = list.ChangeValue.MouseButton1Click:Connect(function()
            for i,v in pairs(object.upvalues) do
                view_change_value(object, i)
                break
            end

            oh.right_click.exit()
        end)

        events.explorer = list.Explorer.MouseButton1Click:Connect(function()
            oh.right_click.exit()
        end)

        events.rename = list.Rename.MouseButton1Click:Connect(function()
            oh.input("okcancel", "Rename Function", "New function name...", function(name)
                object.name = name
                ui_object.Label.Text = name
            end)

            oh.right_click.exit()
        end)

        events.make_script = list.MakeScript.MouseButton1Click:Connect(function()
            local script = [[
-- This script was generated by Hydroxide
-- WARNING: THIS SCRIPT MAY NOT WORK, DO NOT RELY ON THE UPVALUE SCANNER FOR 100% FUNCTIONAL SCRIPTS!
-- "oh_find_function" may not find the correct function if there are multiple functions with the same name

local oh_get_gc = getgc or false
local oh_is_x_closure = is_synapse_function or issentinelclosure or is_protosmasher_closure or is_sirhurt_closure or checkclosure or false
local oh_get_info = debug.getinfo or getinfo or false
local oh_set_upvalue = debug.setupvalue or setupvalue or setupval or false

if not oh_get_gc and not oh_is_x_closure and not oh_get_info and not oh_set_upvalue then
    warn("Your exploit does not support this script")
    return
end

local oh_find_function = function(name)
    for i,v in pairs(oh_get_gc()) do
        if type(v) == "function" and not oh_is_x_closure(v) then
            if oh_get_info(v).name == name then
                return v
            end
        end
    end
end

local oh_<FORMAT> = oh_find_function("<FORMAT>")
local oh_index = upvalue_index_here -- replace this with the index of the upvalue
local oh_new_value = type_your_value_here -- replace this with the value that you want to set the upvalue to

oh_set_upvalue(oh_<FORMAT>, oh_index, oh_new_value)
            ]]

            oh.methods.set_clipboard(script:gsub("<FORMAT>", name))
            oh.right_click.exit()
        end)
    end)

    results.CanvasSize = results.CanvasSize + UDim2.new(0, 0, 0, ui_object.AbsoluteSize.Y + 5)

    return object
end

local find_upvalues = function(query)
    local functions = {}
    results.CanvasSize = results_size

    for i,v in pairs(results:GetChildren()) do
        if v:IsA("ImageLabel") then
            v:Destroy()
        end
    end

    query = tostring(query)

    for i,v in pairs(oh.methods.get_gc()) do
        if type(v) == "function" and not oh.methods.is_x_closure(v) then
            for k,x in pairs(oh.methods.get_upvalues(v)) do
                local value_type = typeof(x)
                if (value_type ~= "function" and value_type ~= "table") and (((value_type == "string" or value_type == "Instance") and tostring(x):lower():find(query:lower(), 1, true)) or tostring(x) == tostring(query)) then
                    local closure = functions[v]
                    if not closure then
                        functions[v] = new_closure(v, tostring(v))
                        closure = functions[v]
                    end

                    closure:new_upvalue(k, x)
                end
            end
        end
    end

    current_upvalues = functions
end

local look_in_tables = false
search_in_tables.Filters.MouseButton1Click:Connect(function()
	look_in_tables = not look_in_tables
    local check_text = (look_in_tables == false and '') or '✓'
    
	search_in_tables.Filters.Label.Text = check_text
end)

query.FocusLost:Connect(function(returned)
    if returned and query.Text:gsub(" ", "") ~= "" then 
        find_upvalues(query.Text)
        query.Text = ""
    end
end)

upvalue_scanner.find_upvalues = find_upvalues

return upvalue_scanner
