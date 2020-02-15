local HttpService = game:GetService("HttpService")
local themeEngine = {}

function themeEngine.ParseTheme()
    
end

function IsUserIsHavingThemeFile()
    if isFile('Hydroxide/theme.json') then 
        return true
    elseif readfile('Hydroxide/theme.json') == nil then
        writefile( -- Will use hexadecimal color value instead of RGB
            'theme.json',
            [[
            {
                "Icon": {},
                "SyntaxHighlighting": {},
                "InterfaceColor": {},
                "Text": {}
            }
            ]]
        )
    end
end

return themeEngine
