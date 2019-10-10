if oh then
    error("Hydroxide is already running!")
end

local environment = {
    get_upvalues = debug.getupvalues or getupvalues or getupvals or false,
    get_upvalue = debug.getupvalue or getupvalue or getupval or false,
    get_metatable = getrawmetatable or debug.getmetatable or false,
    get_objects = (game.GetObjects and function(asset_id) return game:GetObjects(asset_id) end)
    get_stack = debug.getstack or getstack or false,
    get_namecall = getnamecallmethod or false,
    set_namecall = setnamecallmethod or false,
    get_reg = getreg or debug.getregistry or false,
    get_gc = getgc or false,
    set_upvalue = debug.setupvalue or setupvalue or setupval or false,
    set_readonly = setreadonly or make_writeable or false,
    is_l_closure = islclosure or (iscclosure and function(closure) return not iscclosure(closure) end) or false,
    is_x_closure = is_synapse_function or is_protosmasher_closure or false,
    http_get = (game.HttpGetAsync and function(url) return game:HttpGetAsync(url) end) or (game.HttpGet and function(url) return game:HttpGet(url, true) end) or false,
    hook_function = hookfunction or hookfunc or false
}

for i,v in next, environment do
    if not v then
        error("Your exploit does not support Hydroxide!")
    end
end

local web_import = function(file)
    return loadstring(environment.http_get("https://raw.githubusercontent.com/nrv-ous/Hydroxide/master/" .. file))()
end

local rbx_import = function(id)
    return environment.get_objects("rbxassetid://" .. id)[1]
end

getgenv().oh = {}
oh.gui = rbx_import()
oh.assets = rbx_import()
oh.environment = environment
oh.aux = web_import("auxiliary.lua")

