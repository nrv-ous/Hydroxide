local base = oh.gui.Base
local drag = base.Drag
local body = base.Body

local close = drag.Close

local extensions = body.Extensions
local tabs = body.Tabs

close.MouseEnter:Connect(function()
    tween_service:Create(close, TweenInfo.new(0.10), {BackgroundColor3 = Color3.fromRGB(200, 0, 0)}):Play()
end)

close.MouseEnter:Connect(function()
    tween_service:Create(close, TweenInfo.new(0.10), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
end)

close.MouseButton1Down:Connect(function()
    tween_service:Create(close, TweenInfo.new(0.10), {BackgroundColor3 = Color3.fromRGB(200, 100, 100)}):Play()
end)

close.MouseButton1Up:Connect(function()
    tween_service:Create(close, TweenInfo.new(0.10), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
end)

for i,v in next, extensions:GetChildren() do
    if v:IsA("TextButton") then
        v.MouseEnter:Connect(function()
            tween_service:Create(v, TweenInfo.new(0.10), {BackgroundColor3 = Color3.fromRGB(80, 80, 80)}):Play()
        end)

        v.MouseLeave:Connect(function()
            tween_service:Create(v, TweenInfo.new(0.10), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
        end)

        v.MouseButton1Down:Connect(function()
            tween_service:Create(v, TweenInfo.new(0.10), {BackgroundColor3 = Color3.fromRGB(120, 120, 120)}):Play()
        end)

        v.MouseButton1Up:Connect(function()
            tween_service:Create(v, TweenInfo.new(0.10), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
        end)
    end
end
