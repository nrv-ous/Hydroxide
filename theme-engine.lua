local HttpService = game:GetService("HttpService")

oh.GuiPart = { -- what gui component I want to theme
    IconComponent = {

    },
    TextComponent =  {

    },
    MOTDComponent
}
local themeEngine = {}

function themeEngine.IsUserIsHavingThemeFile()
    if isFile('Hydroxide/theme.json') then
        return true
    elseif readfile('Hydroxide/theme.json') == '' then -- Hey it's tard proof!
        writefile( -- Will use hexadecimal color value instead of RGB
        'theme.json',
        [[
{
    "Icon": {},
    "SyntaxHighlighting": {},
    "InterfaceColor": {},
    "Text": {},
    "Tweening": {}
}
]]
)    elseif not isFile('Hydroxide/theme.json') then
        writefile( -- Will use hexadecimal color value instead of RGB
            'theme.json',
            [[
{
    "Icon": {},
    "SyntaxHighlighting": {},
    "InterfaceColor": {},
    "Text": {},
    "Tweening": {}
}
]]
)
    end
end

return themeEngine