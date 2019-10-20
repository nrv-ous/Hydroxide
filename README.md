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

assert(not oh or oh.running, "Hydroxide is already running!")

local import = function(toimport)
	if type(toimport) == "string" then
		return loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/nrv-ous/Hydroxide/master/" .. toimport))()
	else 
		return game:GetObjects("rbxassetid://" .. toimport)[1]
	end
end

getgenv().oh = {}
oh.gui = import(4055219910)
oh.assets = import(4055228005)
oh.environment = import("environment.lua") 
oh.auxiliary = import("auxiliary.lua")

import("visuals.lua")
import("remote_spy.lua")

oh.initialize()
```
