-- ✓

--[[
    [*] - Upvalue setter
    [*] - Upvalue setter UI
    [~] - Upvalue search
    [X] - Load upvalue visual
    [~] - Upvalue function finder
    [X] - Upvalue updating
]]

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
local change_element = base.SetTableElement

local right_click = oh.ui.RightUpvalueScanner
local right_click_added = oh.ui.RightAdded
local right_click_upvalue = oh.ui.RightUpvalue
local right_click_table = oh.ui.RightTable

local main = tab.Main
local results = main.Results.Clip.Contents
local query = main.Filter.Query
local search_in_tables = main.Options.SearchInTables

local current_upvalues = {} 
local look_in_tables = false
local results_size = UDim2.new(0, 0, 0, 16)
local element_size = UDim2.new(0, 0, 0, 20)

local time = TweenInfo.new(0.15)
local enter_color = Color3.fromRGB(170, 0, 0)
local leave_color = Color3.fromRGB(40, 40, 40)

-- Update all currently searched upvalues
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

local set_button_highlight = function(object)
    for i,v in pairs(object:GetChildren()) do
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
end

set_button_highlight(change_upvalue.Body.Options)
set_button_highlight(change_element.Body.Options)

-- Opens the "Change Value" menu when clicking a function
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
        elseif chosen_type == "function" or chosen_type == "table" or chosen_type == "userdata" then
            local ran, result = pcall(loadstring("return " .. chosen_data))
            if not ran then
                return fail("Your " .. chosen_type .. " input has an error.")
            else
                if type(result) ~= chosen_type then
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

-- Opens the "Change Value" menu when clicking a function
local view_change_element
view_change_element = function(table, index)
    local body = change_element.Body
    local current_index = body.Index
    local change_type = body.ChangeType
    local new_value = body.NewValue.TextBox
    local options = body.Options
    
    local list = current_index.List
    local elements = list.Clip.Elements

    local index_type = type(index)
    local text = index and ((index_type == "table" and oh.to_string(index)) or tostring(index))

    local events = {}
    local index_events = {}

    local close = function()
        for i,v in pairs(elements:GetChildren()) do
            if v:IsA("TextButton") then
                v:Destroy()
            end
        end

        elements.CanvasSize = results_size

        for i,v in pairs(events) do
            v:Disconnect()
        end

        list.Visible = false
        change_element.Visible = false
    end

    change_element.Visible = true

    for i,v in pairs(table) do
        if not index then
            index = i
            index_type = type(index)
            text = (index_type == "table" and oh.to_string(index)) or tostring(index)
        end

        local element = oh.assets.ChangeTableElement:Clone()
        local index_type = type(i)

        element.Icon.Image = oh.icons[index_type]
        element.Label.Text = (index_type == "table" and oh.to_string(i)) or tostring(i)
        element.Label.TextColor3 = oh.syntax[index_type] or oh.default_syntax

        element.MouseButton1Click:Connect(function()
            close()
            view_change_element(table, i)
        end)

        element.Parent = elements
        elements.CanvasSize = elements.CanvasSize + element_size
    end

    local data = table[index]
    local data_type = type(data)

    change_type.Icon.Image = oh.icons[data_type]
    change_type.Label.Text = data_type

    current_index.Label.Text = text
    current_index.Label.TextColor3 = oh.syntax[index_type] or oh.default_syntax

    new_value.Text = oh.to_string(data)

    events.change_type = current_index.Collapse.MouseButton1Click:Connect(function()
        current_index.List.Visible = not current_index.List.Visible
    end)

    events.change_element = change_type.Collapse.MouseButton1Click:Connect(function()
        change_type.List.Visible = not change_type.List.Visible
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
        elseif chosen_type == "function" or chosen_type == "table" or chosen_type == "userdata" then
            local ran, result = pcall(loadstring("return " .. chosen_data))
            if not ran then
                return fail("Your " .. chosen_type .. " input has an error.")
            else
                if type(result) ~= chosen_type then
                    return fail()
                end
            end

            chosen_data = result
        end

        table[index] = chosen_data
        close()
    end)

    events.exit = options.Cancel.MouseButton1Click:Connect(function()
        close()
    end)
end

-- Function that is called when updating an upvalue, changes the text and type (if changed), and adjusts the size just in case the value changes
local update = function(upvalue)
    local closure = upvalue.closure
    local value_check = oh.methods.get_upvalue(closure.data, upvalue.index) 
    local elements = upvalue.elements

    if value_check ~= value then
        local closure_ui = closure.ui
        local ui_object = upvalue.ui
        local value_type = type(value_check)

        if value_type ~= type(value) then
            ui_object.Label.TextColor3 = oh.syntax[value_type] or oh.default_syntax
            ui_object.Icon.Image = oh.icons[value_type] or ""
        end

        value = value_check
        
        ui_object.Label.Text = (value_type == "function" and oh.methods.get_info(value).name) or oh.to_string(value)

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
    elseif type(value_check) == "table" and elements then
        local closure_ui = closure.ui
        local ui_object = upvalue.ui

        for i,v in pairs(elements) do
            local value = value_check[i]
            if value and value ~= v then
                local value_type = type(value)
                local value = ui_object.Results[i]
                local label = value.Label

                label.Text = (value_type == "table" and oh.to_string(value)) or tostring(value)
                value.Icon.Image = oh.icons[value_type]

                if not value.Label.TextFits then
                    local height = text_service:GetTextSize(label.Text, 16, "Source", Vector2.new(value.AbsoluteSize.X, 133742069)).Y + 4
                    local old_height = UDim2.new(0, 0, 0, value.AbsoluteSize.Y)
                    local new_height = UDim2.new(0, 0, 0, height)

                    ui_object.Size = ui_object.Size - old_height
                    closure_ui.Size = closure_ui.Size - old_height
                    results.CanvasSize = results.CanvasSize - old_height

                    ui_object.Size = ui_object.Size + new_height
                    closure_ui.Size = closure_ui.Size + new_height
                    results.CanvasSize = results.CanvasSize + new_height
                end
            end
        end
    end
end

-- Function called when you remove an upvalue
local remove = function(upvalue)
    local ui_object = upvalue.ui
    local remove_size = UDim2.new(0, 0, 0, ui_object.AbsoluteSize.Y + 5)

    upvalue.closure.upvalues[upvalue.index] = nil
    ui_object:Destroy()

    upvalue.closure.ui.Size = upvalue.closure.ui.Size - remove_size
    results.CanvasSize = results.CanvasSize - remove_size
end

local update_element = function(element)
    local current_value = table[element.index]

    if current_value ~= element.value then
        local table = element.table
        local ui_object = element.ui
    
        local index = ui_object.Index
        local value = ui_object.Value

        element.value = current_value
    end
end

-- Fucntion called when similar table 
local new_element = function(upvalue, table, i, v)
    local ui_object = upvalue.ui
    local closure_ui = upvalue.closure.ui
    local element = assets.Element:Clone()
    local index = element.Index
    local value = element.Value
    
    local index_type = type(i)
    local value_type = type(v)
    local idx = (index_type == "table" and oh.to_string(i)) or tostring(i)
    local val = (value_type == "table" and oh.to_string(v)) or tostring(v)
    local index_size = text_service:GetTextSize(idx, 16, "SourceSans", Vector2.new(index.AbsoluteSize.X, 133742069)).Y + 4
    local value_size = text_service:GetTextSize(val, 16, "SourceSans", Vector2.new(value.AbsoluteSize.X, 133742069)).Y + 4
    local increment = index_size + value_size
    local increment_size = UDim2.new(0, 0, 0, increment + 5)

    index.Label.Text = idx
    value.Label.Text = val

    index.Label.TextColor3 = oh.syntax[index_type] or oh.default_syntax
    value.Label.TextColor3 = oh.syntax[value_type] or oh.default_syntax

    index.Icon.Image = oh.icons[index_type]
    value.Icon.Image = oh.icons[value_type]
    
    index.Size = UDim2.new(1, 0, 0, index_size)
    value.Size = UDim2.new(1, 0, 0, value_size)
    
    element.Size = UDim2.new(1, 0, 0, increment)
    
    ui_object.Size = ui_object.Size + increment_size
    closure_ui.Size = closure_ui.Size + increment_size
    results.CanvasSize = results.CanvasSize + increment_size
    
    element.MouseButton2Click:Connect(function()
        view_change_element(table, i)
    end)

    element.Name = idx
    element.Parent = ui_object.Elements

    local object = {}
    object.table = table
    object.index = i
    object.ui = element
    object.update = update_element
    object.value = v
end

local generate_script = function(closure, index)
    index = index or "upvalue_index_here -- replace this with the index of the upvalue"

    local script = [[
-- This script was generated by Hydroxide

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
local oh_index = <IDX>
local oh_new_value = type_your_value_here -- replace this with the value that you want to set the upvalue to

oh_set_upvalue(oh_<FORMAT>, oh_index, oh_new_value)

-- WARNING: THIS SCRIPT MAY NOT WORK, DO NOT RELY ON THE UPVALUE SCANNER FOR 100% FUNCTIONAL SCRIPTS!
-- "scout_closure" may not find the correct function if there are multiple functions with the same name
]]

    script = script:gsub("<FORMAT>", closure.name)
    script = script:gsub("<IDX>", index)

    oh.methods.set_clipboard(script)
end

local new_upvalue = function(closure, index, value, attributes)
    if closure.upvalues[index] then
        return
    end

    local object = {}
    local closure_ui = closure.ui
    local ui_object

    if attributes then
        if attributes.added then
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

                events.change_value = right_click_added.List.ChangeValue.MouseButton1Click:Connect(function()
                    view_change_value(closure, object.index)
                    oh.right_click.exit()
                end)

                events.make_script = right_click_added.List.MakeScript.MouseButton1Click:Connect(function()
                    generate_script(closure, object.index)
                    oh.right_click.exit()
                end)
            end)

            object.added = true
        elseif attributes.table then
            ui_object = assets.TableUpvalue:Clone()
            ui_object.Label.MouseButton2Click:Connect(function()
                local events = {}
                oh.create_right_click(right_click_table, events) 
    
                right_click_table.Visible = true
                right_click_table.Position = UDim2.new(0, mouse.X + 5, 0, mouse.Y + 5)
    
                events.change_value = right_click_table.List.ChangeElement.MouseButton1Click:Connect(function()
                    view_change_element(value)
                    oh.right_click.exit()
                end)

                events.make_script = right_click_table.List.MakeScript.MouseButton1Click:Connect(function()
                    generate_script(closure, object.index)
                    oh.right_click.exit()
                end)
            end)

            object.elements = attributes.table
        end
    elseif not attributes then
        ui_object = assets.Upvalue:Clone()
        ui_object.MouseButton2Click:Connect(function()
            local events = {}
            oh.create_right_click(right_click_upvalue, events) 

            right_click_upvalue.Visible = true
            right_click_upvalue.Position = UDim2.new(0, mouse.X + 5, 0, mouse.Y + 5)

            events.change_value = right_click_upvalue.List.ChangeValue.MouseButton1Click:Connect(function()
                view_change_value(closure, object.index)
                oh.right_click.exit()
            end)

            events.make_script = right_click_upvalue.List.MakeScript.MouseButton1Click:Connect(function()
                generate_script(closure, object.index)
                oh.right_click.exit()
            end)
        end)
    end

    local height = text_service:GetTextSize(oh.to_string(value), 16, "SourceSans", Vector2.new(ui_object.AbsoluteSize.X, 133742069)).Y + 4
    local new_height = UDim2.new(0, 0, 0, height + 5)

    local value_type = type(value)

    ui_object.Size = UDim2.new(1, -40, 0, height)
    ui_object.Parent = closure_ui.Contents

    ui_object.Index.Text = index
    ui_object.Label.Text = (value_type == "function" and oh.methods.get_info(value).name) or oh.to_string(value)
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
    local view_label = list.ViewAllUpvalues.Label
    local name = oh.methods.get_info(closure).name

    object.ui = ui_object
    object.data = closure
    object.upvalues = {}
    object.new_upvalue = new_upvalue
    object.name = ((name == "" or not name) and tostring(closure)) or name

    ui_object.Icon.Image = oh.icons["function"]
    ui_object.Label.Text = object.name
    ui_object.Parent = results

    ui_object.Label.MouseButton2Click:Connect(function()
        local events = {}

        oh.create_right_click(right_click, events)

        right_click.Visible = true
        right_click.Position = UDim2.new(0, mouse.X + 5, 0, mouse.Y + 5)

        if viewing_all_upvalues then
            view_label.Text = "Delete Unrelated"
        else
            view_label.Text = "View All Upvalues"
        end

        events.view_upvalues = list.ViewAllUpvalues.MouseButton1Click:Connect(function()
            viewing_all_upvalues = not viewing_all_upvalues
            
            if viewing_all_upvalues then
                for i,v in pairs(oh.methods.get_upvalues(closure)) do
                    object:new_upvalue(i, v, (not object.upvalues[i] and {added = true}) or nil)
                end

                view_label.Text = "Delete Unrelated"
            else
                for i,v in pairs(object.upvalues) do
                    if v.added then
                        v:remove()
                    end
                end

                view_label.Text = "View All Upvalues"
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
            generate_script(object)
            oh.right_click.exit()
        end)
    end)

    results.CanvasSize = results.CanvasSize + UDim2.new(0, 0, 0, ui_object.AbsoluteSize.Y + 5)

    return object
end

-- 
local match_query = function(value, value_type, query)   
    return ((value_type == "string" or value_type == "Instance") and tostring(value):lower():find(query:lower(), 1, true)) or oh.to_string(value) == query
end

-- Main upvalue search function, finds any upvalues that are similar to what you search
local find_upvalues = function(query)
    local functions = {}
    results.CanvasSize = results_size

    for i,v in pairs(results:GetChildren()) do
        local empty = v:IsA("ImageLabel") and v:Destroy()
    end

    query = tostring(query)

    for i,v in pairs(oh.methods.get_gc()) do
        if type(v) == "function" and not oh.methods.is_x_closure(v) then
            for k,x in pairs(oh.methods.get_upvalues(v)) do
                local value_type = typeof(x)
                if value_type == "table" and look_in_tables then
                    for l,n in pairs(x) do
                        local index_type = typeof(l)
                        local value_type = typeof(n)

                        if (index_type ~= "number" and match_query(l, index_type, query)) or match_query(n, value_type, query) then
                            local closure = functions[v]
                            local upvalue 
                            local storage = {}

                            if not closure then
                                functions[v] = new_closure(v, oh.to_string(v))
                                closure = functions[v]
                            end

                            if not closure.upvalues[k] then
                                upvalue = closure:new_upvalue(k, x, {table = storage})
                            else
                                upvalue = closure.upvalues[k]
                            end
                            
                            new_element(upvalue, x, l, n)
                        end
                    end
                elseif value_type ~= "function" and match_query(x, value_type, query) then
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

search_in_tables.Filters.MouseButton1Click:Connect(function()
	look_in_tables = not look_in_tables
    search_in_tables.Filters.Label.Text = (look_in_tables == false and '') or '✓'
    
    if look_in_tables then
        oh.message("ok", "Notice!", "Checking this option MAY freeze your game temporarily; be patient!")
    end
end)

query.FocusLost:Connect(function(returned)
    if returned and query.Text:gsub(" ", "") ~= "" then 
        find_upvalues(query.Text)
        query.Text = ""
    end
end)

upvalue_scanner.find_upvalues = find_upvalues

return upvalue_scanner