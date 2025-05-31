This is a open sourced project for making alt bots on roblox, I made it readable so its easier to understand! Feel free to fork it or whatever.

Example usage:

local BotCore = loadstring(game:HttpGet("https://raw.githubusercontent.com/Farls-Xavier/BotCore/refs/heads/main/Main.lua"))()
local Bot = BotCore.new({Owner = IDOFYOURMAINACCOUNT, Prefix = "!", Name = "Example Bot"})

Bot.CreateCommand("Test", {"t"}, 5, function(sender, args) -- Sender IS REQUIRED, and args is a table so be sure to use it as such.
    print(args[1], args[2], sender)
end)

-- To get the bots player instance is simple (Bot.Bot)

print(Bot.Bot.Parent)
