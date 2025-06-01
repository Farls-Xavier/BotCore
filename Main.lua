local BotCore = {} -- I will add a gui version for bridged connections later on(never 💔)

local Players = game:GetService("Players")

local TeleportService = game:GetService("TeleportService")
local TextChatService = game:GetService("TextChatService")

local function validate(defaults, args)
	for i,v in pairs(defaults) do
		if args[i] == nil then
			args[i] = v
		end
	end   
	return args
end

local function FindPlayerByDisplayName(name, owner)
    if name == "" or name == nil or name == "nil" then
        return owner
    end

    for i,v in pairs(Players:GetPlayers()) do
        local loweredDName = v.DisplayName:lower()
        local loweredName = v.Name:lower()

        if string.find(loweredDName, name:lower(), 1, true) or string.find(loweredName, name:lower(), 1, true) then
            return v
        end
    end
end

function BotCore.new(params)
    local Bot = validate({
        Owner = 1, -- Main user id.

        Bot = Players.LocalPlayer, -- The bot!

        Prefix = "!", -- What you use to make the commands work eg. !here

        Commands = {}, -- Stores commands duh! will add the basic ones (dictionary). 

        Log = {}, -- Stores all commands that have been used

        Whitelisted = {}, -- Allows these users to use commands at certain ranks and etc (dictionary).

        Excluded = {} -- Doesn't let the bot kill these users wiith kill all and what not.
    }, params)

    local Owner = Players:GetPlayerByUserId(Bot.Owner)

    -- Main functions

    function Bot:GetUserRank(user : Player)
        return Bot.Whitelisted[user.UserId].Rank
    end

    function Bot:GetCommand(command)
        local lowered = command:lower()

        if Bot.Commands[lowered] then
            return Bot.Commands[lowered]
        end

        for _, commandData in Bot.Commands do
            for _, alias in commandData.Aliases do
                if alias:lower() == lowered then
                    return commandData
                end
            end
        end

        return nil
    end

    function Bot.CreateCommand(name : string, aliases : table, requiredRank : number, callback)
        local data = {
            Name = name, -- The name of the command

            Aliases = aliases, -- The other names of the command

            RequiredRank = requiredRank, -- The rank need to run this command

            Callback = callback -- The function of the command
        }

        Bot.Commands[name:lower()] = data
    end

    function Bot.AddUser(user : Player, rank)
        if Bot.Whitelisted[user.UserId] then
            warn("Already found a user for this user")
            return
        end

        Bot.Whitelisted[user.UserId] = {Name = user.Name, Id = user.UserId, Rank = rank}

        user.Chatted:Connect(function(message)
            if not message:sub(1, #Bot.Prefix) == Bot.Prefix then
                return
            end

            local raw = message:sub(#Bot.Prefix + 1)
            local args = {}

            for word in raw:gmatch("%S+") do
                table.insert(args, word)
            end

            local command = args[1]
            table.remove(args, 1)
            
            local commandData = Bot:GetCommand(command)

            if commandData then
                if Bot:GetUserRank(user) <= commandData.RequiredRank and Bot.Whitelisted[user.UserId] ~= nil then
                    commandData.Callback(user, args)
                    Bot.LogCommand(user, commandData.Name, os.date("%H:%M:%S"), table.concat(args, ", "))
                else
                    warn("User (", user.DisplayName, ") does not meet the required rank for this command (", commandData.Name, ")")
                end
            end
        end)
    end

    function Bot.RemoveUser(user : Player)
        if Bot.Whitelisted[user.UserId] then
            Bot.Whitelisted[user.UserId] = nil    
        end
    end

    function Bot.AddExclusion(user : Player)
        Bot.Excluded[user.UserId] = user
    end

    function Bot.RankUp(user : Player, amount)
        if Bot.Whitelisted[user.UserId] then
            Bot.Whitelisted[user.UserId].Rank -= amount
        end
    end

    function Bot.DeRank(user : Player, amount : number)
        if Bot.Whitelisted[user.UserId] then
            Bot.Whitelisted[user.UserId].Rank += amount
        end
    end

    function Bot.LogCommand(sender, name, time, args)
        Bot.Log[sender.DisplayName.."("..time..")"] = {Name = name, Args = args}
    end

    -- Connections

    Players.PlayerRemoving:Connect(function(player)
        if player == Owner then
            game:Shutdown()
        end
    end)

    -- Setup

    Bot.AddUser(Owner, 1)

    Bot.CreateCommand("whitelist", {"wl"}, 1, function(sender, args)
        Bot.AddUser(FindPlayerByDisplayName(args[1], sender), args[2])
    end)

    Bot.CreateCommand("blacklist", {"removewhitelist", "bl"}, 1, function(sender, args)
        Bot.RemoveUser(FindPlayerByDisplayName(args[1], nil))
    end)

    Bot.CreateCommand("exclude", {"exc"}, 1, function(sender, args)
        Bot.AddExclusion(FindPlayerByDisplayName(args[1], sender))
    end)

    Bot.CreateCommand("rankup", {"ru", "addrank"}, 1, function(sender, args)
        Bot.RankUp(FindPlayerByDisplayName(args[1], nil), args[2])
    end)

    Bot.CreateCommand("derank", {"dr", "removerank", "rr"}, 1, function(sender, args)
        Bot.DeRank(FindPlayerByDisplayName(args[1], nil), args[2])
    end)

    Bot.CreateCommand("log", {"usedcommands", "printlog"}, 5, function(sender, args)
        for i,v in pairs(Bot.Log) do
            print(i .. ": command = " .. v.Name .. ", args = " .. v.Args)            
        end
    end)

    Bot.CreateCommand("whois", {"userinfo", "id", "pinfo"}, 5, function(sender, args)
        -- I will make it private message it soon, first I need to figure out how to make it private message...

        local user = FindPlayerByDisplayName(args[1])
        
        local friendsWith = user:IsFriendsWith(sender.UserId)

        print(user.DisplayName, ":", "Rank =", Bot:GetUserRank(user), ":", "friendsWith =", friendsWith)
    end)

    Bot.CreateCommand("rejoin", {"rj"}, 1, function(sender, args)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Bot.Bot)
    end)

    Bot.CreateCommand("shutdown", {"exit", "close"}, 1, function(sender, args)
        game:Shutdown()
    end)

    return Bot
end

return BotCore
