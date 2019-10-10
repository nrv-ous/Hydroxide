local http_spy = {}
local spoofed_requests = {}
local blocked_requests = {}

local env = oh.environment
local gui = oh.gui
local assets = oh.assets
local terminal = oh.terminal

local body = gui.Base.Body
local window = body.HttpSpy
local logged = window.Logged
local options = window.Options

http_spy.prefix = "http"
http_spy.color = Color3.new(0, 1, 0)

http_spy.inspect = function(link)
    
    terminal.output(http_spy.prefix, http_spy.color, "inspecting link")
end

http_spy.spoof = function(link, type, value)
    local return_value 
    if type == "string" then
        return_value = value
    elseif type == "number" then
        return_value = tonumber(value)        
    elseif type == "bool" or type == "boolean" then
        return_value = value == "true"
    elseif type == "table" or type == "function" then
        return_value = loadstring(value)()
    end

    spoofed_requests[link] = return_value
    terminal.output(http_spy.prefix, http_spy.color, "spoofed return value assigned")
end

http_spy.block = function(link)
    blocked_requests[link] = true 
    terminal.output(http_spy.prefix, http_spy.color, "link blocked")
end

http_spy.unblock = function(link)
    blocked_requests[link] = nil
    terminal.output(http_spy.prefix, http_spy.color, "link unblocked")
end

for i,v in next, {
    game.HttpGet,
    game.HttpGetAsync,
    htgetf,
    syn and syn.request,
    game.HttpPost,
    game.HttpPostAsync,
} do
    local old = v
    hookfunction(v, function(...)
        local vargs = {...}
        local verified = true
        local spoof = false

        for i,v in next, vargs do
            if spoofed_requests[v] then
                spoof = spoofed_requests[v]
            end

            if blocked_requests[v] then
                verified = false
            end
        end

        return (spoof or (not verified and nil)) or old(...)
    end)
end

return http_spy