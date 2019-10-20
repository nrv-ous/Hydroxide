local aux = {}
local env = oh.environment

local players = game:GetService("Players")
local tween_service = game:GetService("TweenService")

local client = players.LocalPlayer

aux.transform_path = function(path)
    local split = path:split('.')
    local result = ""
    local name = client.Name
    
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
    
    result = result:gsub("Players." .. name, "LocalPlayer")
    result = result:gsub("Players[\"" .. name .. "\"]", "LocalPlayer")
    
    return "game." .. result:sub(1, result:len() - 1)
end

aux.transform_value = function(value)
    local origin 
    local direction
    local type = typeof(value)

    if type == "Ray" then
        local split = tostring(value):split("}, ")
        origin = split[1]:gsub('{', "Vector3.new("):gsub('}', ')')
        direction = split[2]:gsub('{', "Vector3.new("):gsub('}', ')')
    end

    local transformations = {
        string = type == "string" and '"' .. value .. '"',
        table = type == "table" and aux.dump_table(value),
        Instance = type == "Instance" and aux.transform_path(value:GetFullName()),
        Vector3 = type == "Vector3" and "Vector3.new(" .. tostring(value) .. ')',
        CFrame = type == "CFrame" and "CFrame.new(" .. tostring(value) .. ')',
        Color3 = type == "Color3" and "Color3.new(" .. tostring(value) .. ')',
        Ray = type == "Ray" and "Ray.new(" .. origin .. "), " .. direction .. ')',
        ColorSequence = type == "ColorSequence" and "ColorSequence.new(" .. aux.dump_table(v.KeyPoints) .. ')',
        ColorSequenceKeypoint = type == "ColorSequenceKeypoint" and "ColorSequenceKeypoint.new(" .. v.Time .. ", Color3.new(" .. tostring(v.Value) .. "))",
    }

    return transformations[typeof(value)] or tostring(value)
end

aux.dump_table = function(table)
    local result = "{ "

    for index, value in next, table do
        local class = type(index)

        if class == "table" then
            result = result .. '[' .. aux.dump_table(index) .. ']'
        elseif class == "string" then
            if index:find("%A") then
                result = result .. "[\"" .. index .. "\"]"
            else
                result = result .. index
            end
        elseif class == "number" then
        elseif class == "Instance" then
            result = result .. '[' .. aux.transform_path(index:GetFullName()) .. ']'
        else
            result = result .. tostring(index)
        end

        if class ~= "number" then
            result = result .. " = "
        end

        result = result .. aux.transform_value(value) .. ', '

        if result:sub(result:len() - 1, result:len()) == ", " then
            result = result:sub(1, result:len() - 2)
        end

        return result .. " }"
    end
end

-- Adds a highlight effect to the specified element
aux.apply_highlight = function(button, new, down, mouse2, condition)
    local old_color = button.BackgroundColor3 
    local new_color = new or Color3.fromRGB((old_color.r * 255) + 30, (old_color.g * 255) + 30, (old_color.b * 255) + 30)
    local down_color = down or Color3.fromRGB((new_color.r * 255) + 30, (new_color.g * 255) + 30, (new_color.b * 255) + 30)
    condition = condition or true

    button.MouseEnter:Connect(function()
        local old_context = env.get_thread_context()
        env.set_thread_context(6)
        
        if condition then
            local animation = tween_service:Create(button, TweenInfo.new(0.10), {BackgroundColor3 = new_color})
            animation:Play()
        end

        env.set_thread_context(old_context)
    end)

    button.MouseLeave:Connect(function()
        local old_context = env.get_thread_context()
        env.set_thread_context(6)
        
        if condition then
            local animation = tween_service:Create(button, TweenInfo.new(0.10), {BackgroundColor3 = old_color})
            animation:Play()
        end

        env.set_thread_context(old_context)
    end)

    if not mouse2 then
        button.MouseButton1Down:Connect(function()
            local old_context = env.get_thread_context()
            env.set_thread_context(6)

            if condition then
                local animation = tween_service:Create(button, TweenInfo.new(0.10), {BackgroundColor3 = down_color})
                animation:Play()
            end

            env.set_thread_context(old_context)
        end)

        button.MouseButton1Up:Connect(function()
            local old_context = env.get_thread_context()
            env.set_thread_context(6)
            
            if condition then
                local animation = tween_service:Create(button, TweenInfo.new(0.10), {BackgroundColor3 = new_color})
                animation:Play()
            end

            env.set_thread_context(old_context)
        end)
    else
        button.MouseButton2Down:Connect(function()
            local old_context = env.get_thread_context()
            env.set_thread_context(6)
            
            if condition then
                local animation = tween_service:Create(button, TweenInfo.new(0.10), {BackgroundColor3 = down_color})
                animation:Play()
            end
            
            env.set_thread_context(old_context)
        end)

        button.MouseButton2Up:Connect(function()
            local old_context = env.get_thread_context()
            env.set_thread_context(6)
            
            if condition then
                local animation = tween_service:Create(button, TweenInfo.new(0.10), {BackgroundColor3 = new_color})
                animation:Play()
            end

            env.set_thread_context(old_context)
        end)
    end
end

return aux
