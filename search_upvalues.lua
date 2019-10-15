local aux = oh.aux
local env = oh.env
local gui = oh.gui

local body = gui.Base.Body
local window = body.Tabs.SearchUpvalues

local upvalues = {}

--[[
    A U X I L I A R Y
]]--

local find_upvalues = function(value)
    local results = {}

    for i,v in next, env.getgc() do
        if type(v) == "function" and not env.is_x_closure(v) then
            results[v] = {}
            for k,x in next, env.getupvalues(v) do
                if (type(x) == "string" and x:find(value)) or x == value then
                    table.insert(results[v], k, x)
                end 
            end
        end
    end

    return result
end

--[[
    I N T E R F A C E
]]--

window.Query.FocusLost:Connect(function(returned)
    if returned then
        upvalues = find_upvalues(window.Query.Text)
        for i,v in next, upvalues do
            local asset = assets.Function:Clone()
            asset.Label.Text = tostring(i)
    
            for k,x in next, v do
                local upvalue = assets.Upvalue:Clone()
                upvalue.Parent = asset
                asset.Size = asset.Size + UDim2.new(0, 0, 0, 25)
            end
    
            asset.Parent = window.Results
            window.Results.CanvasSize = window.Results.CanvasSize + UDim2.new(0, 0, 0, asset.AbsoluteSize.Y)
        end
    
        window.Query.Text = ""

        spawn(function()
            while  do
                for i,v in next, upvalues do
                    for k,x in next, v do
                        if env.get_upvalue(i, k) ~= x then
                            
                        end
                    end
                end

                wait()
            end
        end)
    end
end)
