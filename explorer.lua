local aux = oh.auxiliary
local explorer = oh.gui.Base.Body.Explorer
local make_node
local resize_ancestry

resize_ancestry = function(container, new)
	if container ~= explorer.Parent then 
		if container.ClassName == "ScrollingFrame" then
			container.CanvasSize = container.CanvasSize + new
		elseif container.ClassName == "Frame" then 
			container.Size = container.Size + new
		end
		
		resize_ancestry(container.Parent, new)
	end
end

make_node = function(table, settings)
	local node = oh.assets.Node:Clone()
    node.Parent = (settings.self and explorer) or settings.parent

	if settings.self then 
		local collapsed = true
		local created = false

		node.Label.Text = settings.text or tostring(table)
		node.Parent = settings.parent or explorer

        node.Collapse.MouseButton1Click:Connect(function()
			local offset = 0            
			collapsed = not collapsed 

			if not created then 
				for i,v in pairs(table) do
					make_node(table, {
						index = i,
						parent = node.Children
					})
				end

				created = true
			end

			if not collapsed then 
				node.Collapse.Image = "rbxassetid://3271004659"
				
				for i,v in next, table do
					offset = offset + 20
				end
			else
				node.Collapse.Image = "rbxassetid://3270754211"

				for i,v in next, table do
					offset = offset - 20
				end
            end
			resize_ancestry(node.Children, UDim2.new(0, 0, 0, offset))
        end)
        
        explorer.CanvasSize = explorer.CanvasSize + UDim2.new(0, 0, 0, 20)

		aux.apply_highlight(node.Collapse, {property = "ImageColor3"})
	else
		local value = table[settings.index]
		local type = typeof(value)
		node.Icon.Image = oh.icons[type]
		node.Collapse.Visible = false
		node.Parent = settings.parent
		node.Label.Text = tostring(settings.index)
	end
end

make_node(debug.getprotos(1), {text = "Current Protos", self = true})
print(#debug.getprotos(1))