local HttpService = game:GetService("HttpService")
local themeEngine = {}

function themeEngine.ParseTheme()
    
end

function IsUserIsHavingThemeFile()
    if isFile('Hydroxide/theme.json') then 
        return true
    else
        writefile(
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
