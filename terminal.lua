local terminal = {}
local modules = {}

local gui = oh.gui
local assets = oh.assets

local body = gui.Base.Body
local window = body.Terminal
local input = window.Input
local output = window.Output

terminal.output = function(prefix, color, content)

end

terminal.command_handler = function()
    local parameters = {}
    local raw = input.Text:split(' ')
    local module = raw[1]
    local command = raw[2]

    if not modules[module] or not modules[module][command] then
        terminal.output("OH", Color3.fromRGB(200, 0, 0), "Invalid command")
        return
    end

    for i = 3, #raw do
        table.insert(parameters, raw[i])
    end

    modules[module][command](unpack(parameters))
end

terminal.add_component = function(module)
    modules[module.prefix] = {}

    for i,v in next, module do
        if type(v) == "function" then
            modules[module.prefix][i] = v
        end
    end
end

return terminal