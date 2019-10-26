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

    if pcall(game.GetService, game, split[1]) then
        split[1] = "GetService(\"" .. split[1] .. "\")"
    end
    
    for i,v in next, split do
        if (v:sub(1, 1):match("%A") or v:find("%W")) and not v:find("GetService") then
            result = result:sub(1, result:len())
            v = "[\"" .. v .. "\"]"
        elseif v:find("GetService") then
            v = ':' .. v
        else
            v = '.' .. v
        end
        
        result = result .. v
    end
    
    result = result:gsub("GetService(\"Players\")." .. name, "GetService(\"Players\").LocalPlayer")
    result = result:gsub("GetService(\"Players\")[\"" .. name .. "\"]", "GetService(\"Players\").LocalPlayer")

    return "game" .. result
end
aux.transform_value = function(value)
    local result = ""
    local ttype = typeof(value)
  
    if ttype == "table" then
        result = result .. aux.dump_table(value) 
    elseif ttype == "string" then
        result = result .. '"' .. value .. '"'
    elseif ttype == "Instance" then
        result = result .. aux.transform_path(value:GetFullName())
    elseif ttype == "Vector3" then
        result = result .. "Vector3.new(" .. tostring(value) .. ")"
    elseif ttype == "CFrame" then
        result = result .. "CFrame.new(" .. tostring(value) .. ")"
    elseif ttype == "Color3" then
        result = result .. "Color3.new(" .. tostring(value) .. ")"
    elseif ttype == "Ray" then
        local split = tostring(value):split('}, ')
        local origin = split[1]:gsub('{', "Vector3.new("):gsub('}', ')')
        local direction = split[2]:gsub('{', "Vector3.new("):gsub('}', ')')
        result = result .. "Ray.new(" .. origin .. "), " .. direction .. ')'
    elseif ttype == "ColorSequence" then
        result = result .. "ColorSequence.new(" .. dump_table(v.Keypoints) .. ')'
    elseif ttype == "ColorSequenceKeypoint" then
        result = result .. "ColorSequenceKeypoint.new(" .. value.Time .. ", Color3.new(" .. tostring(value.Value) .. "))" 
    else
        if type(value) == "userdata" then
            print(ttype)
        end
        
        result = result .. tostring(value)
    end

    return result
end

aux.dump_table = function(t)
    local result = "{ "

    for i,v in next, t do
      local class = typeof(index)

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
      elseif class ~= "nil" then
          result = result .. tostring(index)
      end
      
      if class ~= "number" and class ~= "nil" then
        result = result .. " = "
      end

      result = result .. aux.transform_value(v) .. ', '
    end

    if result:sub(result:len() - 1, result:len()) == ", " then
        result = result:sub(1, result:len() - 2)
    end

    return result .. " }"
end

-- Adds a highlight effect to the specified element
aux.apply_highlight = function(button, settings)
    local property = (settings and settings.property) or "BackgroundColor3"
    local condition = (settings and settings.condition) or true
    local old_color = (settings and settings.property and button[settings.property]) or button.BackgroundColor3
    local new_color = (settings and settings.new) or Color3.fromRGB((old_color.r * 255) + 30, (old_color.g * 255) + 30, (old_color.b * 255) + 30)
    local down_color = (settings and settings.down) or Color3.fromRGB((new_color.r * 255) + 30, (new_color.g * 255) + 30, (new_color.b * 255) + 30)

    local new_tween = function()
        if condition then
            local old_context = env.get_thread_context()
            env.set_thread_context(6)

            local animation = tween_service:Create(button, TweenInfo.new(0.10), {[property] = new_color})
            animation:Play()

            env.set_thread_context(old_context)
        end
    end

    local down_tween = function()
        if condition then
            local old_context = env.get_thread_context()
            env.set_thread_context(6)

            local animation = tween_service:Create(button, TweenInfo.new(0.10), {[property] = down_color})
            animation:Play()

            env.set_thread_context(old_context)
        end
    end

    button.MouseEnter:Connect(new_tween)
    button.MouseLeave:Connect(function()
        if condition then
            local old_context = env.get_thread_context()
            env.set_thread_context(6)

            local animation = tween_service:Create(button, TweenInfo.new(0.10), {[property] = old_color})
            animation:Play()

            env.set_thread_context(old_context)
        end
    end)

    if not (settings and settings.mouse2) then
        button.MouseButton1Down:Connect(down_tween)
        button.MouseButton1Up:Connect(new_tween)
    else
        button.MouseButton2Down:Connect(down_tween)
        button.MouseButton2Up:Connect(new_tween)
    end
end

return aux
