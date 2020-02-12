local http_spy = {}
http_spy.functions = {
    "hook_function"
}

local get = {
    game.HttpGet,
    game.HttpGetAsync,
    HttpGet,
    htgetf
}

local post = {
    game.HttpPost,
    game.HttpPostAsync
}

http_spy.monitor = function(link)

end

http_spy.block = function(host, ...)

end

for i,v in pairs(get) do
    local h 
    h = hookfunction(v, newcclosure(function(...)
        
    end))
end