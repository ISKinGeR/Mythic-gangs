local GangInvitations = {}
-- Application: Unknown (Gangs)
CreateThread(function()
    while not _Ready do
        Wait(1000)
	print("Not Ready!!, you need to add `_Ready = true` on `mythic-laptop/server/main.lua` in this function `RetrieveComponents()` if didnt do it yet!")
    end
    LoadGangs() -- Init

    function SetPlayerState(Type, source, GangData)
        local playerState = Player(source).state

        if Type == 1 then
            if ServerConfig.Gangs[GangData.Id] then
                local sprays = exports['mythic-graffiti']:GetSpraysByGang(GangData.Id)
                ServerConfig.Gangs[GangData.Id].TotalSprays = #sprays
            end
            playerState.PlayerGang = GangData
        elseif Type == 2 then
            playerState.PlayerGang = nil
        end
    end

    Middleware:Add('Characters:Spawning', function(source)
        local Gang = GetGangByPlayer(Fetch:Source(source):GetData("Character"):GetData("SID"))
        if Gang then
            SetPlayerState(1, source, Gang)
        end
    end, 5)

    Middleware:Add("Characters:Logout", function(source)
        local playerState = Player(source).state
        if playerState.PlayerGang then
            SetPlayerState(2, source)
        end
    end)

    Chat:RegisterAdminCommand("refreshGangs", function(Source, args, rawCommand)
        local Player = Fetch:Source(Source)
        if not Player then return end
        LoadGangs()
        Execute:Client(Source, "Notification", "Success", "Gangs refreshed!")
    end, {
        help = "Refetch all gangs from DB.",
    }, 0)

    Chat:RegisterAdminCommand("SetGangLeader", function(Source, args, rawCommand)
        local Player = Fetch:Source(Source)
        if not Player then return end
        if not tonumber(args[2]) then return end
        SetGangLeader(args[1],tonumber(args[2]), function(s)
            if s then
                Execute:Client(Source, "Notification", "Success", "Gang Leader Have been changed!")
            else
                Execute:Client(Source, "Notification", "Error", "Error while trying change Gang Leader!")
            end
        end)
    end, {
        help = "Set New Leader For a Gang",
		params = {
			{
				name = "GangId",
				help = "Gang Id",
			},
            {
				name = "SID",
				help = "SID of New leader",
			},
		},
    }, 2)
    
    Callbacks:RegisterServerCallback("mythic-laptop/server/unknown/get-gang-by-id", function(Source, GangId, cb)
        cb(GetGangById(GangId))
    end)

    Callbacks:RegisterServerCallback("mythic-laptop/server/unknown/get-discovered-sprays", function(Source, GangId, cb)
        local Gang = ServerConfig.Gangs[GangId]

        local Result = exports['oxmysql']:executeSync("SELECT `discovered_sprays` FROM `laptop_gangs` WHERE `gang_id` = @GangId", {
            ['@GangId'] = GangId
        })

        if Result[1] == nil then return cb(false) end
        cb(json.decode(Result[1].discovered_sprays))
    end)

    Callbacks:RegisterServerCallback("mythic-laptop/server/unknown/get-player-gang", function(source, data, cb) -- not use anymore!
        Kprint("Try to get player data!")
        local Player = Fetch:Source(source)
        if not Player then 
            Kprint("Player not found!")
            return 
        end
    
        local playerSID = Player:GetData("Character"):GetData("SID")
        Kprint("Player SID:", playerSID)
    
        local Gang = GetGangByPlayer(playerSID)
        if Gang then
            Kprint("Gang found:", json.encode(Gang))
    
            if ServerConfig.Gangs[Gang.Id] then
                local sprays = exports['mythic-graffiti']:GetSpraysByGang(Gang.Id)
                Kprint("Number of sprays for the gang:", #sprays)
    
                ServerConfig.Gangs[Gang.Id].TotalSprays = #sprays
                SetPlayerState(1, source, Gang)
            else
                Kprint("Gang ID not found in ServerConfig.Gangs")
            end
        else
            Kprint("No gang found for player:", playerSID)
        end
    
        cb(Gang)
    end)

    Callbacks:RegisterServerCallback("mythic-laptop/server/unknown/add-member", function(Source, Data, cb)
        local Player = Fetch:Source(Source)
        if not Player then return end
        local Data = { Cid = tonumber(Data.Cid) }
        local Target = Fetch:SID(Data.Cid)
        if not Target then return Execute:Client(Source, "Notification", "Error", "Player not found..") end

        local Gang = GetGangByPlayer(Player:GetData("Character"):GetData("SID"))
        if not Gang then return end

        local TargetGang = GetGangByPlayer(Data.Cid)
        if TargetGang then return end
        
        if GangInvitations[Gang.Id] == nil then GangInvitations[Gang.Id] = {} end
        GangInvitations[Gang.Id][Data.Cid] = true

        -- TriggerClientEvent('mythic-phone/client/notification', Target:GetData('Source'), {
        --     Id = "gang-invite-" .. Target:GetData("Character"):GetData("SID"),
        --     Title = "Gang Invitation",
        --     Message =  Gang.Label .. " is inviting you to their gang.",
        --     Icon = "fas fa-user-ninja",
        --     IconBgColor = "#4f5efc",
        --     IconColor = "white",
        --     Sticky = true,
        --     Duration = 5000,
        --     Buttons = {
        --         {
        --             Icon = "fas fa-check-circle",
        --             Tooltip = "Accept",
        --             Event = "mythic-laptop/server/unknown/accept-invite",
        --             EventType = "server",
        --             EventData = { Id = "gang-invite-" .. Target:GetData("Character"):GetData("SID"), Gang = Gang.Id },
        --             Color = "#2ecc71",
        --         },
        --         {
        --             Icon = "fas fa-times-circle",
        --             Tooltip = "Decline",
        --             EventType = "Client",
        --             Event = "mythic-phone/client/hide-notification",
        --             EventData = Data.Id,
        --             Color = "#f2a365",
        --         },
        --     },
        -- })

        Phone.Notification:AddWithId(
            Target:GetData('Source'),
            "GangSystem",
            "Gang System",
            string.format(
                "%s is inviting you to their gang.",
                Gang.Label
            ),
            os.time() * 1000,
            -1,
            "comanager",
            {
                accept = "mythic-laptop/client/unknown/accept-invite",
                cancel = "mythic-laptop/client/unknown/cansel-invite",
            },
            { Gang = Gang.Id }
        )


        cb(Gang)
    end)

    Callbacks:RegisterServerCallback("mythic-laptop/server/unknown/kick-member", function(Source, Data, cb)
        local Player = Fetch:Source(Source)
        if not Player then return end
    
        local PlayerSID = tonumber(Player:GetData("Character"):GetData("SID"))
        local PlayerCID = tonumber(Data.Cid)
    
        local Gang = GetGangByPlayer(PlayerSID)
        if not Gang then return end
    
        local TargetGang, TargetId = GetGangByPlayer(PlayerCID)
        if not TargetGang then return end
    
        if Gang.Id ~= TargetGang.Id then return end
    
        if PlayerCID == PlayerSID then
            table.remove(ServerConfig.Gangs[Gang.Id].Members, TargetId)
            SetPlayerState(2, Source)
            SaveGang(Gang.Id)
            cb(true)
            return
        end
    
        if tonumber(ServerConfig.Gangs[Gang.Id].leader.cid) == PlayerSID then
            table.remove(ServerConfig.Gangs[Gang.Id].Members, TargetId)
            local Tplayer = Fetch:SID(PlayerCID)
            SetPlayerState(2, Tplayer:GetData('Source'))
            SaveGang(Gang.Id)
            cb(true)
            return
        end
    
        cb(false)
    end)
    

    Callbacks:RegisterServerCallback("mythic-laptop/server/unknown/get-messages", function(Source, data,cb)
        local Player = Fetch:Source(Source)
        if not Player then cb({}) return end

        local Gang = GetGangByPlayer(Player:GetData("Character"):GetData("SID"))
        if not Gang then return end

        local Chats = {}
        local Result = exports['oxmysql']:executeSync('SELECT * FROM `laptop_gangs_chat` WHERE `gang_id` = @GangId ORDER BY `timestamp` DESC', { ['@GangId'] = Gang.Id })

        for k, v in pairs(Result) do
            Chats[#Chats + 1] = {
                Sender = v.sender,
                SenderName = GetPlayerCharName(v.sender) or "Unknown",
                Message = v.message,
                Attachments = json.decode(v.attachments),
                Timestamp = v.timestamp
            }
        end

        cb(Chats)
    end)

    Callbacks:RegisterServerCallback("mythic-laptop/server/unknown/send-message", function(Source, Data, cb)
        local Player = Fetch:Source(Source)
        if not Player then cb({Success = false, Msg = "Invalid Player"}) return end
    
        local Gang = GetGangByPlayer(Player:GetData("Character"):GetData("SID"))
        if not Gang then return end
    
        -- Get the current date and time in the format YYYY-MM-DD HH:MM:SS
        local currentDateTime = os.date("%Y-%m-%d %H:%M:%S")
    
        -- Insert into the database with the timestamp
        exports['oxmysql']:executeSync("INSERT INTO `laptop_gangs_chat` (`gang_id`, `sender`, `message`, `attachments`, `timestamp`) VALUES (@GangId, @Sender, @Message, @Attachments, @Timestamp)", {
            ['@GangId'] = Gang.Id,
            ['@Sender'] = Player:GetData("Character"):GetData("SID"),
            ['@Message'] = Data.Message,
            ['@Attachments'] = json.encode(Data.Attachments),
            ['@Timestamp'] = currentDateTime,  -- Add timestamp to the query
        })
    
        TriggerGangEvent(Gang.Id, "mythic-laptop/client/unknown/refresh-gang-chat")

        local Gang1 = exports['mythic-laptop']:GetGangById(Gang.Id)
        if Gang1 then
            local Leader = Fetch:SID(tonumber(Gang1.Leader.Cid))
            if Leader then
                Phone.Notification:Add(
                    Leader:GetData('Source'),
                    "Laptop Messages - "..Gang1.Id,
                    ("%s - %s"):format(Player:GetData("Character"):GetData("First") .. " " .. Player:GetData("Character"):GetData("Last"), Data.Message),
                    os.time() * 1000,
                    6000,
                    "messages",
                    {}
                )
            end
            
            for k, v in pairs(Gang1.Members) do
                local Target = Fetch:SID(tonumber(v.Cid))
                if Target then
                    Phone.Notification:Add(
                        Target:GetData('Source'),
                        "Laptop Messages - "..Gang1.Id,
                        ("%s - %s"):format(Player:GetData("Character"):GetData("First") .. " " .. Player:GetData("Character"):GetData("Last"), Data.Message),
                        os.time() * 1000,
                        6000,
                        "messages",
                        {}
                    )
                end
            end
        end

        cb({Success = true})
    end)    

    Callbacks:RegisterServerCallback("mythic-laptop/server/unknown/get-crafting-name", function(Source, data,cb)
        local Player = Fetch:Source(Source)
        if not Player then return cb(false) end

        local Gang = GetGangByPlayer(Player:GetData("Character"):GetData("SID"))
        if not Gang then return cb(false) end

        if Gang.TotalSprays >= 54 then
            return cb('Powerful')
        elseif Gang.TotalSprays >= 36 then
            return cb('Feared')
        elseif Gang.TotalSprays >= 24 then
            return cb('Respected')
        elseif Gang.TotalSprays >= 16 then
            return cb('Established')
        elseif Gang.TotalSprays >= 8 then
            return cb('WellKnown')
        elseif Gang.TotalSprays >= 4 then
            return cb('Known')
        end

        cb(false)
    end)
end)

-- Functions

function LoadGangs()
    local Result = exports['oxmysql']:executeSync("SELECT * FROM `laptop_gangs`")

    if not Result or #Result == 0 then
        return
    end

    Kprint("Fetched " .. #Result .. " gangs from database.")

    for k, v in pairs(Result) do

        if not v.gang_id or not v.gang_label or not v.gang_leader or not v.gang_members or not v.gang_metadata then
        else
            ServerConfig.Gangs[v.gang_id] = {
                Id = v.gang_id,
                Label = v.gang_label,
                Leader = {
                    Cid = v.gang_leader, 
                    Name = GetPlayerCharName(v.gang_leader) or "Unknown"
                },
                Members = json.decode(v.gang_members) or {},
                MaxMembers = ServerConfig.GangSizes[v.gang_id] or 7,
                Sales = 0,
                TotalCollected = 0,
                TotalSprays = #(exports['mythic-graffiti']:GetSpraysByGang(v.gang_id) or {}),
                MetaData = json.decode(v.gang_metadata) or {}
            }
        end
    end
end

GetPlayerCharName = function(SID)
    local ReturnValue = promise:new()
    local sidNumber = tonumber(SID)
    if not sidNumber then
        ReturnValue:resolve(nil)
        return Citizen.Await(ReturnValue)
    end

    Database.Game:find({
        collection = "characters",
        query = {
            SID = sidNumber
        }
    }, function(success, result)
        if success then
            if result and result[1] then
                local FirstName = result[1].First or ""
                local LastName = result[1].Last or ""
                local FullName = FirstName .. " " .. LastName
                ReturnValue:resolve(FullName)
            else
                ReturnValue:resolve(nil)
            end
        else
            ReturnValue:resolve(nil)
        end
    end)

    local Result = Citizen.Await(ReturnValue)
    return Result
end

function GetGangById(GangId)
    return ServerConfig.Gangs[GangId] or false
end
exports("GetGangById", GetGangById)

function GetGangByPlayer(CitizenId)
    CitizenId = tostring(CitizenId)

    Kprint("Searching for CitizenId:", CitizenId)

    for k, v in pairs(ServerConfig.Gangs) do
        Kprint("Checking Gang:", json.encode(v))
        Kprint("Check Leader:", v.Leader.Cid)

        if tostring(v.Leader.Cid) == CitizenId then
            Kprint("Found Leader:", v.Leader.Cid)
            return v
        end

        for i, j in pairs(v.Members) do
            Kprint("Checking Member:", j.Cid)
            if tostring(j.Cid) == CitizenId then
                Kprint("Found Member:", j.Cid)
                return v, i
            end
        end
    end
    return false, 0
end

exports("GetGangByPlayer", GetGangByPlayer)

function SaveGang(GangId)
    if ServerConfig.Gangs[GangId] == nil then return end

    exports['oxmysql']:executeSync("UPDATE `laptop_gangs` SET `gang_leader` = @Leader, `gang_members` = @Members WHERE `gang_id` = @GangId", {
        ['@GangId'] = GangId,
        ['@Members'] = json.encode(ServerConfig.Gangs[GangId].Members),
        ['@Leader'] = ServerConfig.Gangs[GangId].Leader.Cid,
    })
end

function SetGangMetadata(GangId, MetaDataId, Value)
    if ServerConfig.Gangs[GangId] == nil then return false end

    ServerConfig.Gangs[GangId].MetaData[MetaDataId] = Value
    exports['oxmysql']:executeSync("UPDATE `laptop_gangs` SET `gang_metadata` = @MetaData WHERE `gang_id` = @GangId", {
        ['@GangId'] = GangId,
        ['@MetaData'] = json.encode(ServerConfig.Gangs[GangId].MetaData),
    })
    return true
end
exports("SetGangMetadata", SetGangMetadata)

function SetGangLeader(GangId, Cid)
    if ServerConfig.Gangs[GangId] == nil then return false end
    ServerConfig.Gangs[GangId].Leader = { Cid = Cid, Name = GetPlayerCharName(Cid) }
    exports['oxmysql']:executeSync("UPDATE `laptop_gangs` SET `gang_leader` = ? WHERE `gang_id` = ?", {
        Cid,
        GangId,
    })
    SaveGang(GangId)
    return true
end
exports("SetGangLeader", SetGangLeader)

function GetGangMetadata(GangId, MetaDataId)
    if ServerConfig.Gangs[GangId] == nil then return false end
    return ServerConfig.Gangs[GangId].MetaData[MetaDataId]
end
exports("GetGangMetadata", GetGangMetadata)

function TriggerGangEvent(GangId, Event, ...)
    local Gang = exports['mythic-laptop']:GetGangById(GangId)
    if not Gang then return end

    local Leader = Fetch:SID(tonumber(Gang.Leader.Cid))
    if Leader then
        TriggerClientEvent(Event, Leader:GetData('Source'), ...)
    end
    
    for k, v in pairs(Gang.Members) do
        local Target = Fetch:SID(tonumber(v.Cid))
        if Target then
            TriggerClientEvent(Event, Target:GetData('Source'), ...)
        end
    end
end
exports("TriggerGangEvent", TriggerGangEvent)

-- Events

RegisterNetEvent("mythic-laptop/server/unknown/accept-invite", function(Data)
    local Source = source
    Kprint("HERE    :",json.encode(Data))
    local Player = Fetch:Source(Source)
    if not Player then
        Phone.Notification:Add(Source,"Employment", "Invalid Invitation!", os.time() * 1000, 6000, "comanager", {
            view = "",
        }, nil)
        return
    end

    local Gang = ServerConfig.Gangs[Data.Gang]
    if not Gang then
        Phone.Notification:Add(Source,"Employment", "Invalid Invitation!", os.time() * 1000, 6000, "comanager", {
            view = "",
        }, nil)
        return
    end

    if not GangInvitations[Data.Gang] or not GangInvitations[Data.Gang][Player:GetData("Character"):GetData("SID")] then
        Phone.Notification:Add(Source,"Employment", "Invalid Invitation!", os.time() * 1000, 6000, "comanager", {
            view = "",
        }, nil)
        return
    end

    if #Gang.Members + 2 > Gang.MaxMembers then
        Phone.Notification:Add(Source,"Employment", "Invalid Invitation!", os.time() * 1000, 6000, "comanager", {
            view = "",
        }, nil)
        return
    end

    Phone.Notification:Add(Source,"Employment", "Accepting Invitation...", os.time() * 1000, 6000, "comanager", {
        view = "",
    }, nil)

    table.insert(ServerConfig.Gangs[Data.Gang].Members, {
        Cid = Player:GetData("Character"):GetData("SID"),
        Name = Player:GetData("Character"):GetData("First") .. " " .. Player:GetData("Character"):GetData("Last")
    })

    SaveGang(Data.Gang)
end)

RegisterNetEvent("mythic-laptop/server/add-discovered", function(GangId, SprayId)
    local Gang = ServerConfig.Gangs[GangId]

    local Result = exports['oxmysql']:executeSync("SELECT `discovered_sprays` FROM `laptop_gangs` WHERE `gang_id` = @GangId", {
        ['@GangId'] = GangId
    })

    if Result[1] == nil then return end

    local DiscoveredSprays = json.decode(Result[1].discovered_sprays)
    DiscoveredSprays[#DiscoveredSprays + 1] = SprayId

    exports['oxmysql']:executeSync("UPDATE `laptop_gangs` SET `discovered_sprays` = @Sprays WHERE `gang_id` = @GangId", {
        ['@Sprays'] = json.encode(DiscoveredSprays),
        ['@GangId'] = GangId
    })

    local Leader = Fetch:SID(Gang.Leader.Cid)
    if Leader then
        TriggerClientEvent("mythic-graffiti/client/update-discovered", Leader:GetData('Source'), DiscoveredSprays)
    end

    for k, v in pairs(Gang.Members) do
        local Target = Fetch:SID(v.Cid)
        if Target then
            TriggerClientEvent("mythic-graffiti/client/update-discovered", Target:GetData('Source'), DiscoveredSprays)
        end
    end
end)
