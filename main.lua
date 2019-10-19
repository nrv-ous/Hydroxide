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

local import = function(toimport)
	if type(toimport) == "string" then
		return loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/nrv-ous/Hydroxide/master/" .. toimport))()
	else 
		return game:GetObjects("rbxassetid://" .. toimport)[1]
	end
end

getgenv().oh = {}
oh.env = import("environment.lua") 
oh.aux = import("auxiliary.lua")
oh.gui = import(4055219910)
oh.assets = import(4055228005)

import("visuals.lua")
import("remote_spy.lua")

oh.initialize()
