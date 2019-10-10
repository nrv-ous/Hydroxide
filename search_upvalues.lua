local search_upvalues = {}

local env = oh.environment

local gui = oh.gui
local assets = oh.assets

local body = gui.Base.Body
local window = body.Tabs.SearchUpvalues


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

search_upvalues.prefix = "su"

search_upvalues.scan = function(value)
    
end

return search_upvalues