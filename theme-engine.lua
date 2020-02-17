local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

oh.GuiPart = { -- what gui component I want to theme
    IconComponent = {
        
    },
    TextComponent =  {

    },
    MOTDComponent,
    LogoComponent = {

    }
}
local themeEngine = {}

function themeEngine.isUserIsHavingThemeFile()
    if oh.is_file('Hydroxide/theme.json') then
        return true
    elseif readfile('Hydroxide/theme.json') == '' then -- Hey it's tard proof!
        writefile( -- Will use hexadecimal color value instead of RGB
        'theme.json',
        [[
{
    "Icon": {
        "Table": "rbxassetid://4666594276",
        "Function": ""
    },
    "SyntaxHighlighting": {
        "number": "",
        "string": "",
        "boolean": "" 
    },
    "InterfaceColor": {},
    "Text": {},
    "Tweening": {},
    "MOTD": {},
    "Logo":{}
}
]]
)   elseif not oh.is_file('Hydroxide/theme.json') then
        writefile( -- Will use hexadecimal color value instead of RGB
            'theme.json',
            [[
{
    "Icon": {
        "Table": "rbxassetid://4666594276",
        "Function": ""
    },
    "SyntaxHighlighting": {
        "number": "",
        "string": "",
        "boolean": ""
    },
    "InterfaceColor": {},
    "Text": {},
    "Tweening": {},
    "MOTD": {},
    "Logo": {}
}
]]
)
    end
end

return themeEngine