local tween_service = game:GetService("TweenService")

local base = oh.gui.Base
local drag = base.Drag
local body = base.Body

local close = drag.Close

local extensions = body.Extensions
local tabs = body.Tabs

close.MouseEnter:Connect(function()
    local animation = tween_service:Create(close, TweenInfo.new(0.10), {BackgroundColor3 = Color3.fromRGB(200, 0, 0)})
	animation:Play()
end)

close.MouseEnter:Connect(function()
    local animation = tween_service:Create(close, TweenInfo.new(0.10), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)})
	animation:Play()
end)

close.MouseButton1Down:Connect(function()
    local animation = tween_service:Create(close, TweenInfo.new(0.10), {BackgroundColor3 = Color3.fromRGB(200, 100, 100)})
	animation:Play()
end)

close.MouseButton1Up:Connect(function()
    local animation = tween_service:Create(close, TweenInfo.new(0.10), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)})
	animation:Play()
end)

local selected_extension 
for i,v in next, extensions:GetChildren() do
    if v:IsA("TextButton") then
        v.MouseEnter:Connect(function()
            local animation = tween_service:Create(v, TweenInfo.new(0.10), {BackgroundColor3 = Color3.fromRGB(80, 80, 80)})
	        animation:Play()
        end)

        v.MouseLeave:Connect(function()
            local animation = tween_service:Create(v, TweenInfo.new(0.10), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)})
	        animation:Play()
        end)

        v.MouseButton1Down:Connect(function()
            local animation = tween_service:Create(v, TweenInfo.new(0.10), {BackgroundColor3 = Color3.fromRGB(120, 120, 120)})
	        animation:Play()
        end)

        v.MouseButton1Up:Connect(function()
            local animation = tween_service:Create(v, TweenInfo.new(0.10), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)})
            local tab = tabs[v.Name]
            animation:Play()

            if selected_extension then
                selected_extension.Visible = false
            end

            tab.Visible = true
            selected_extension = tab
        end)


    end
end
