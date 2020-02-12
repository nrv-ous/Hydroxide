local remote_spy = {}
remote_spy.functions = {
    "get_metatable",
    "set_readonly",
    "hook_function",
    "new_cclosure",
    "check_caller",
    "get_namecall_method"
}

local gmt = oh.methods.get_metatable(game)
local name_call = gmt.__namecall
local methods = {}
local remotes = {
    BindableFunction = "Invoke"
    RemoteFunction = "InvokeServer",
    BindableEvent = "Fire",
    RemoteEvent = "FireServer"
}

local bait = function()end

local cache = setmetatable({}, {
    __newindex = function(t, i, v)
        
    end
})

local show = function(remote)
    if remote.destroyed then
        remote:remove()
    end
end

local ignore = function(remote)
    if remote.destroyed then
        remote:remove()
    end
end

local block = function(remote)
    if remote.destroyed then
        remote:remove()
    end
end

local remove = function(remote)
    
end

local create_remote = function(object)
    local remote = {}
    remote.object = object
    remote.show = show
    remote.ignore = ignore
    remote.block = block

    local destroy_check = object:GetPropertyChangedSignal("Parent"):Connect(bait)

    setmetatable(remote, {
        __index = function(t, i)
            if i == "destroyed" then
                return not destroy_check.Connected
            end
        end
    })

    return remote
end

--[[
    This hook allows us to view any __index calls or localization calls.

    __index:
        Remote.Method(Remote, ...)

    localized:
        local method = Remote.Method
        method(Remote, ...)
]]
for i,v in pairs(remotes) do
    local h
    h = oh.methods.hook_function(
        Instance.new(i)[v], 
        oh.methods.new_cclosure(function(remote, ...)
            local method = remotes[remote.ClassName]

        end)
    )
end

--[[
    This hook allows us to view any __namecall calls.

    __namecall:
        Remote:Method(...)
]]
oh.set_readonly(gmt, false)
gmt.__namecall = function(obj, ...)
    if remotes[obj.ClassName] then
        local method = oh.methods.get_namecall_method()

    end
end