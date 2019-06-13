*This is not a finished product; there* ***will*** *be bugs.*

<p align="center">
  <img src="https://i.vgy.me/4W76vz.png">
</p>

# Hydroxide
Penetration testing tool for games on the Roblox platform.

```lua
loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/0x90-NOP/Hydroxide/master/main.lua"))()

local scripts, modules = abs.getScripts()

ui.addButton("Scripts", scripts, root, {icon = 3285607721})
ui.addButton("Modules", modules, root, {icon = 3285696601})
ui.addButton("_G", getrenv()._G)
ui.addButton("shared", getrenv().shared)```
