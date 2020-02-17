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
                   -- developed by nrv-ous/hush and Vini Dalvino --   
]]--
loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/nrv-ous/Hydroxide/rebirth/init.lua"))()

oh.ui = import(4635451696)
oh.assets = import(4636445983)
oh.theme = import('theme-engine.lua')

oh.message = import("message_box.lua")
oh.explorer = import("explorer.lua")

oh.upvalue_scanner = import("upvalue_scanner.lua")
oh.script_scanner = import("script_scanner.lua")

oh.closure_spy = import("closure_spy.lua")
oh.remote_spy = import("remote_spy.lua")
oh.http_spy = import("http_spy.lua")
