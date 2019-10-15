local aux = {}
local env = oh.env

local tween_service = game:GetService("TweenService")

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