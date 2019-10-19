local environment = {
    get_upvalues = debug.getupvalues or getupvalues or getupvals or false,
    get_upvalue = debug.getupvalue or getupvalue or getupval or false,
    get_metatable = getrawmetatable or debug.getmetatable or false,
    get_stack = debug.getstack or getstack or false,
    get_namecall = getnamecallmethod or false,
    get_reg = getreg or debug.getregistry or false,
    get_gc = getgc or false,
    get_thread_context = (syn and syn.get_thread_identity) or getthreadcontext or getcontext or false,
    set_thread_context = (syn and syn.set_thread_identity) or setthreadcontext or setcontext or false,
    set_namecall = setnamecallmethod or false,
    set_upvalue = debug.setupvalue or setupvalue or setupval or false,
    set_readonly = setreadonly or make_writeable or false,
    is_l_closure = islclosure or (iscclosure and function(closure) return not iscclosure(closure) end) or false,
    is_x_closure = is_synapse_function or is_protosmasher_closure or false,
    hook_function = hookfunction or hookfunc or false,
    new_cclosure = newcclosure or false,
    to_clipboard = (syn and syn.write_clipboard) or writeclipboard or toclipboard or setclipboard or false,
    check_caller = checkcaller or false,
}

-- Checks if the exploit has the currently listed functions
for i,v in next, environment do
    assert(v, "Your exploit does not support Hydroxide!")
end

oh.icons = {
    BindableEvent = 4035066852,
    BindableFunction = 4035067356,
    RemoteEvent = 4035067858,
    RemoteFunction = 4035068333,
    string = 3285671510,
    number = 3285671510,
    boolean = 3285671510,
    table = 3285651068,
    ["function"] = 3285661880,
    userdata = 3285664726
}

oh.initialize = function()
    oh.gui.Parent = game:GetService("CoreGui")
end

return environment
