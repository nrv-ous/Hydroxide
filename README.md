*This is not a finished product; there* ***will*** *be bugs.*

<p align="center">
  <img src="https://i.vgy.me/v90wQc.png">
</p>

# Hydroxide

<p align="center">
  <img src="https://i.vgy.me/qJi8FC.png">
</p>
<p align="center">
  Penetration testing tool for games on the Roblox platform.
</p>



## <a href="https://github.com/nrv-ous/Hydroxide/blob/master/main.lua"><b>main.lua</b></a>

```lua
--[[

                ▄████████▄   ▄█▄    ▄█▄   
                ███    ███   ███    ███   
                ███    ███   ███    ███   
                ███    ███   ████▄▄████  ▄███▄▄▄▄███▄ 
                ███    ███   ████▀▀████  ▀███▀▀▀▀███▀  
                ███    ███   ███    ███   
                ███    ███   ███    ███   
                ▀████████▀   ▀█▀    ▀█▀    


                      :::[H:Y:D:R:O:X:I:D:E]:::
                   -- developed by nrv-ous/hush --   
    
    Welcome to Hydroxide, the most superior script development
     tool as of 10/12/19. Feel free to browse the source code, 
    and make any changes. Hydroxide utilizes a module structure 
    for organization and cleanliness, so my apologies if any of 
                      this is a hassle to edit.
]]--

assert(not oh, "Hydroxide is already running!")

local web_import = function(file)
    return loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/nrv-ous/Hydroxide/master/" .. file))()
end

local rbx_import = function(id)
    return game:GetObjects("rbxassetid://" .. id)[1]
end

getgenv().oh = {}
oh.env = web_import("environment.lua") 
oh.aux = web_import("auxiliary.lua")
oh.gui = rbx_import(4055219910)
oh.assets = rbx_import(4055228005)

web_import("visuals.lua")
web_import("remote_spy.lua")

oh.initialize()
```
