local http_service  = game:GetService("HttpService")
local core_gui = game:GetService("CoreGui")

oh.gui_part = { -- what gui component I want to hydroxide_theme
    icon_component = {

    },
        text_component =  {

    },
    motd_component,
    logo_component = {

    }
}
local theme_engine = {}

function theme_engine.is_user_is_having_theme_file()
    if oh.is_file('hydroxide_theme.json') then
        return true
    elseif readfile('hydroxide_theme.json') == '' then -- Hey it's tard proof!
        writefile( -- Will use hexadecimal color value instead of RGB
            'hydroxide_theme.json',
            [[
{
    "icon": {
        "table": "rbxassetid://4666594276",
        "function": ""
    },
    "syntax_highlighting": {
        "defaultsyntax": {
            "R": 200,
            "G": 200,
            "B": 200
        },
        "number": {
            "R": 170,
            "G": 225,
            "B": 85
        },
        "string": {
            "R": 225,
            "G": 150,
            "B": 85
        },
        "boolean": {
            "R": 127,
            "G": 200,
            "B": 255
        }
    },
    "interface_color": {},
    " text": {},
    "tweening": {},
    "motd": {},
    "logo":{}
}]]
)        
    elseif not oh.is_file('hydroxide_theme.json') then
        writefile( -- Will use hexadecimal color value instead of RGB
            'hydroxide_theme.json',
            [[
{
    "icon": {
        "table": "rbxassetid://4666594276",
        "function": ""
    },
    "syntax_highlighting": {
        "defaultsyntax": {
            "R": 200,
            "G": 200,
            "B": 200
        },
        "number": {
            "R": 170,
            "G": 225,
            "B": 85
        },
        "string": {
            "R": 225,
            "G": 150,
            "B": 85
        },
        "boolean": {
            "R": 127,
            "G": 200,
            "B": 255
        }
    },
    "interface_color": {},
    " text": {},
    "tweening": {},
    "motd": {},
    "logo":{}
}]]
)
    end
end

return theme_engine