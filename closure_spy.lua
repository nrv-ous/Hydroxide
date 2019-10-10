local closure_spy = {}
local logged = {}

local env = oh.environment

local dump_table
dump_table = function(t)
    local result = "{ "

    for i,v in next, t do
        if type(i) == "table" then
            result = result .. '[' .. table_string(i)
        elseif type(i) == "string" then
            result = result .. '["' .. i .. '"'
        else
            result = result .. '[' .. tostring(i)
        end
        result = result .. '] = '

        if type(v) == "table" then
            result = result .. table_string(v) 
        elseif type(v) == "string" then
            result = result .. '"' .. v .. '"'
        else
            result = result .. tostring(v)
        end
        result = result .. ', '
    end

    if result:sub(result:len() - 1, result:len()) == ", " then
        result = result:sub(1, result:len() - 2)
    end

    return result .. " }"
end

closure_spy.log = function(closure)
    local old = closure
    logged[closure] = setmetatable({}, {
        __newindex = function(t, i, v)
            
        end
    })

    env.hook_function(closure, newcclosure(function(...)
        local vargs = {...}
        table.insert(logged[closure], {dump_table(vargs), vargs})
    end))
end



return closure_spy