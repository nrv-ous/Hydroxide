local explorer = {}
explorer.functions = {
}

local tween_service = game:GetService("TweenService")

local base = oh.ui.Base
local body = base.Body
local contents = body.Explorer.Body.Clip.Contents
local assets = oh.assets.Explorer

local time = TweenInfo.new(0.15)
local selected_color = Color3.fromRGB(225, 225, 225)
local unselected_color = Color3.fromRGB(200, 200, 200)
local selected_node

local collapsed = "rbxassetid://4229797725"
local opened = "rbxassetid://4229798737"

local resize_ancestry
resize_ancestry = function(obj)
	if obj.Parent == contents then
		--contents.CanvasSize = 
		return
	end

	--if obj.Parent.

	return resize_ancestry(obj.Parent)
end

explorer.make_node = function(value, text, parent_node)
	if parent_node and not parent_node:FindFirstChild("Collapse") then
		return
	end

	local node
	local value_type = typeof(value)

	if value_type == "function" then
		node = assets.ClosureNode:Clone()
	elseif value_type == "table" then
		node = assets.TableNode:Clone()
	else
		node = assets.Node:Clone()
	end

	local button = node.Button
	local collapse = node:FindFirstChild("Collapse")

	local selected = tween_service:Create(button, time, { TextColor3 = selected_color })
	local unselected = tween_service:Create(button, time, { TextColor3 = unselected_color })

	if collapse then
		local collapse_select = tween_service:Create(collapse, time, { ImageTransparency = 0.1 })
		local collapse_unselect = tween_service:Create(collapse, time, { ImageTransparency = 0.35 })
		collapse.Image = collapsed

		collapse.MouseEnter:Connect(function()
			if collapse.Image == collapsed then
				collapse_select:Play()
			end
		end)

		collapse.MouseLeave:Connect(function()
			if collapse.Image == collapsed then
				collapse_unselect:Play()
			end
		end)

		collapse.MouseButton1Click:Connect(function()
			if collapse.Image == collapsed then 
				collapse.Image = opened
				collapse_select:Play()
			else
				collapse.Image = collapsed
			end
		end)
	end

	button.MouseEnter:Connect(function()
		if selected_node ~= node then
			selected:Play()
		end
	end)

	button.MouseLeave:Connect(function()
		if selected_node ~= node then
			unselected:Play()
		end
	end)

	button.MouseButton1Click:Connect(function()
		if selected_node == node then
			unselected:Play()
			selected_node = nil
			return
		end

		local old_selected = selected_node

		selected:Play()
		selected_node = node

		if old_selected then
			tween_service:Create(old_selected.Button, time, { TextColor3 = unselected_color })
		end
	end)
	
	contents.CanvasSize = contents.CanvasSize + UDim2.new(0, 0, 0, node.AbsoluteSize.Y)
	
	node.Type.Image = oh.icons[type(value)]
	node.Button.Text = text

	if parent_node then
		
	end

	node.Parent = parent_node or contents

	return node
end

return explorer