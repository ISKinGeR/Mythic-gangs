local ContestedSprays, Contesters = {}, {}


AddEventHandler("Graffiti:Shared:DependencyUpdate", RetrieveComponents)
function RetrieveComponents()
	Database = exports["mythic-base"]:FetchComponent("Database")
	Logger = exports["mythic-base"]:FetchComponent("Logger")
	Callbacks = exports["mythic-base"]:FetchComponent("Callbacks")
	Fetch = exports["mythic-base"]:FetchComponent("Fetch")
	Middleware = exports["mythic-base"]:FetchComponent("Middleware")
	Execute = exports["mythic-base"]:FetchComponent("Execute")
	Inventory = exports["mythic-base"]:FetchComponent("Inventory")
    Wallet = exports["mythic-base"]:FetchComponent("Wallet")
    Phone = exports["mythic-base"]:FetchComponent("Phone")
    Chat = exports["mythic-base"]:FetchComponent("Chat")

end

AddEventHandler("Core:Shared:Ready", function()
	exports["mythic-base"]:RequestDependencies("Graffiti", {
		"Database",
		"Logger",
		"Callbacks",
		"Fetch",
		"Middleware",
		"Execute",
        "Wallet",
        "Phone",
        "Chat",
		"Inventory"
	}, function(error)
		if #error > 0 then
			return
		end
		RetrieveComponents()
        LoadSprays()

        for SprayName, v in pairs(Config.Sprays) do
            Inventory.Items:RegisterUse("spray_"..SprayName, "Graffiti",function(source, itemData)
                TriggerClientEvent('mythic-graffiti/client/place-spray', source, SprayName)
            end)
        end

        Chat:RegisterAdminCommand("refreshSprays", function(Source, args, rawCommand)
            local Player = Fetch:Source(Source)
            if not Player then return end
            LoadSprays()
            Execute:Client(Source, "Notification", "Success", "Sprays refreshed!")
        end, {
            help = "Refetch all gangs Sprays from DB.",
        }, 0)

        -- Callbacks
        Callbacks:RegisterServerCallback("mythic-graffiti/server/is-graffiti-contested", function(source, data, cb)
            if Config.Graffitis[data] then
                if Config.Graffitis[data].Contested then
                    cb(Config.Graffitis[data].Contested)
                else
                    cb(false)
                end
            else
                cb(false)
            end
        end)              
    
        Callbacks:RegisterServerCallback("mythic-graffiti/server/get-top-gangs", function(source, data, cb)
            if not Config or not Config.Graffitis or not next(Config.Graffitis) then
                cb({})
                return
            end
        
            local gangGraffitiCount = {}
        
            for _, graffiti in ipairs(Config.Graffitis) do
                local gang = graffiti.Gang
                if gang then
                    gangGraffitiCount[gang] = (gangGraffitiCount[gang] or 0) + 1
                end
            end
        
            local topGangs = {}
            local count = 0
            for gang, sprays in pairs(gangGraffitiCount) do
                table.insert(topGangs, { gang, sprays })
            end
            table.sort(topGangs, function(a, b) return a[2] > b[2] end)
        
            local result = {}
            for i = 1, math.min((Config.TopCount or 3), #topGangs) do
                result[topGangs[i][1]] = topGangs[i][2]
            end
        
            cb(result)
        end)
              

        Callbacks:RegisterServerCallback("mythic-graffiti/server/get-sprays", function(source, data, cb)
            if (Config and Config.Graffitis == nil) or (Config and next(Config.Graffitis) == nil) then
                cb({})
            end
            cb(Config.Graffitis) 
        end)
        
        Callbacks:RegisterServerCallback("mythic-graffiti/server/is-gang-online", function(source, GangId, cb)
            local Gang = exports['mythic-laptop']:GetGangById(GangId)
            if not Gang then return cb(false) end
            local Online = 0
            local Leader = Fetch:SID(Gang.Leader.Cid)
            if Leader then
                Online += 1
            end
    
            for k, v in pairs(Gang.Members) do
                local Target = Fetch:SID(v.Cid)
                if Target then
                    Online += 1
                    if Online > (Config.NeedOnline or 2) then
                        return cb(true)
                    end
                end
            end
    
            cb(true)
        end)
    
        -- Events
    
        Callbacks:RegisterServerCallback("mythic-graffiti/server/create-spray", function(source, data, cb)
            local Player = Fetch:Source(source)
            local Type = data.Type
            local Coords = data.Coords
            local Rotation = data.Rotation
            local IgnoreItem = data.IgnoreItem
            if Player == nil then return end
    
            local Gang = exports['mythic-laptop']:GetGangByPlayer(Player:GetData("Character"):GetData("SID"))
            local Gang = Config.Sprays[Type].IsGang and Type or false
    
            if IgnoreItem or Inventory.Items:Remove(Player:GetData("Character"):GetData("SID"), 1, "spray_"..Type, 1) then
                local SprayId = #Config.Graffitis + 1
                local GraffitisSprayedToday = exports['mythic-laptop']:GetGangMetadata(Gang, "GraffitisSprayedToday")
    
                if not IgnoreItem and (GraffitisSprayedToday or 0) + 1 > Config.DailyLimit then
                    return Execute:Client(source, "Notification", "Error", "Nice try!")
                end
    
                local result = MySQL.query.await('INSERT INTO `laptop_sprays` (`gang_id`, `type`, `position`, `rotation`) VALUES (?, ?, ?, ?)', {
                    Gang or "",
                    Type,
                    json.encode(Coords),
                    json.encode(Rotation)
                })
                Config.Graffitis[SprayId] = {
                    Id = result.insertId,
                    Gang = Gang or "",
                    Type = Type,
                    Coords = Coords,
                    Rotation = Rotation
                }
    
                if Gang and Type == Gang then
                    TriggerEvent("mythic-laptop/server/add-discovered", Gang, result.insertId)
                    exports['mythic-laptop']:SetGangMetadata(Gang, "LastSprayTimestamp", os.time())
                    exports['mythic-laptop']:SetGangMetadata(Gang, "GraffitisSprayedToday", (GraffitisSprayedToday or 0) + 1)
                end
    
                TriggerClientEvent("mythic-graffiti/client/add-spray", -1, SprayId, Config.Graffitis[SprayId])
            else
                Execute:Client(source, "Notification", "Error", "Where did the spray go?")
            end
        end)
    
        Callbacks:RegisterServerCallback("mythic-graffiti/server/destroy-spray", function(source, GraffitiId, cb)
            if Config.Graffitis[GraffitiId] == nil then return end
            local SprayId = Config.Graffitis[GraffitiId].Id
            local result = MySQL.query.await('DELETE FROM `laptop_sprays` WHERE `id` = ?', {
                SprayId
            })
    
            if ContestedSprays[Config.Graffitis[GraffitiId].Type] then
                ContestedSprays[Config.Graffitis[GraffitiId].Type] = false
            end
    
            table.remove(Config.Graffitis, GraffitiId)
            TriggerClientEvent("mythic-graffiti/client/destroy-graffiti", -1, GraffitiId)
    
            local result = MySQL.query.await('SELECT `gang_id`, `discovered_sprays` FROM `laptop_gangs` WHERE `discovered_sprays` LIKE ?', {
                "%" .. SprayId .. "%"
            })
    
            for k, v in pairs(result) do
                local DiscoveredSprays = json.decode(v.discovered_sprays)
                for i = 1, #DiscoveredSprays, 1 do
                    local DiscoveredSprayId = DiscoveredSprays[i]
                    if DiscoveredSprayId == SprayId then
                        table.remove(DiscoveredSprays, i)
                    end
                end
                local result = MySQL.query.await('UPDATE `laptop_gangs` SET `discovered_sprays` = ? WHERE `gang_id` = ?', {
                    json.encode(DiscoveredSprays),
                    v.gang_id
                })
                cb(true)

                local gang1 = exports['mythic-laptop']:GetGangById(v.gang_id)
                if not gang1 then return end


                local Leader = Fetch:SID(gang1.Leader.Cid)
                if Leader then
                    TriggerClientEvent("mythic-graffiti/client/update-discovered", Leader:GetData('Source'), DiscoveredSprays)
                end
                for k, v in pairs(gang1.Members) do
                    local Target = Fetch:SID(v.Cid)
                    if Target then
                        TriggerClientEvent("mythic-graffiti/client/update-discovered", Target:GetData('Source'), DiscoveredSprays)
                    end
                end
            end
        end)
    
        Callbacks:RegisterServerCallback("mythic-graffiti/server/alert-sprayer", function(source, data, cb)
            local Player = Fetch:Source(source)
            local GangId = data.GangId
            local Type = data.Type
            local StreetName = data.StreetName
            local Coords = data.Coords
            if Player == nil then return end
    
            local Sprayers = exports['mythic-laptop']:GetGangById(GangId)
            if not Sprayers then return end
    
            local Gang = exports['mythic-laptop']:GetGangByPlayer(Player:GetData("Character"):GetData("SID"))
            if Gang and Gang.Id == Sprayers.Id then return end
    
            local Content = ""
            if Type == "Scrub" then
                Content = "Someone is scrubbing our graffiti!"
            elseif Type == "Contest" then
                Content = Gang.Label .. " is taking our graffiti! Toggle Contested Sprays in the app!"
            end
    
            local Leader = Fetch:SID(tonumber(Sprayers.Leader.Cid))
            if Leader then

                Phone.Email:Send(
                    Leader:GetData('Source'),
                    string.format("%s@Unknown.cc",Sprayers.Id),
                    os.time() * 1000,
                    "Important",
                    string.format(
                        [[
                        %s
                        <br /><br/>
                        %s
                        <br /><br/>
                        click the link attached above to mark the place!
                    ]],
                        Content,
                        StreetName
                    ),
                    {
                        hyperlink = {
                            event = 'GangSystem:MarkPlace',
                            data = Coords
                        },
                        expires = (os.time() + (60 * 5)) * 1000,
                    }
                )

            end
    
            for k, v in pairs(Sprayers.Members) do
                local Target = Fetch:SID(tonumber(v.Cid))
                if Target then
                    Phone.Email:Send(
                        Target:GetData('Source'),
                        string.format("%s@Unknown.cc",Sprayers.Id),
                        os.time() * 1000,
                        "Important",
                        string.format(
                            [[
                            %s
                            <br /><br/>
                            %s
                            <br /><br/>
                            click the link attached above to mark the place!
                        ]],
                            Content,
                            StreetName
                        ),
                        {
                            hyperlink = {
                                event = 'GangSystem:MarkPlace',
                                data = Coords
                            },
                            expires = (os.time() + (60 * 5)) * 1000,
                        }
                    )
                end
            end
        end)
    
        Callbacks:RegisterServerCallback("mythic-graffiti/server/set-spray-contested", function(source, data, cb)        
            local Player = Fetch:Source(source)
            if Player == nil then
                return
            end
            local SprayId = data.id
            if not Config.Graffitis[SprayId] then
                return
            end
            local Clear = data.clear
            if Clear then
                -- Set the contested status to false in GlobalState instead of Config
                GlobalState[string.format("Graffiti:%s:Contested", SprayId)] = false
                ContestedSprays[Config.Graffitis[SprayId].Type] = false
                Contesters[Player:GetData("Character"):GetData("SID")] = false
                return cb(false)
            end
            local Gang = exports['mythic-laptop']:GetGangByPlayer(Player:GetData("Character"):GetData("SID"))
            
            if not Gang then
                return
            end
        
            -- Fetch the contested status from GlobalState
            local contested = GlobalState[string.format("Graffiti:%s:Contested", SprayId)] or false
            if contested then
                Execute:Client(source, "Notification", "Error", "Graffiti is already being contested by someone else..")
                return cb(false)
            end
        
            if ContestedSprays[Config.Graffitis[SprayId].Type] then
                Execute:Client(source, "Notification", "Error", "Can't do this right now..")
                return cb(false)
            end
            if ContestedSprays[Config.Graffitis[SprayId].Type] == nil then
                ContestedSprays[Config.Graffitis[SprayId].Type] = {}
            end
            table.insert(ContestedSprays[Config.Graffitis[SprayId].Type], Config.Graffitis[SprayId].Id)
        
            -- Set the contested status to the Gang's ID in GlobalState
            GlobalState[string.format("Graffiti:%s:Contested", SprayId)] = Gang.Id
            Config.Graffitis[SprayId].ContestTimestamp = os.time()
            Contesters[Player:GetData("Character"):GetData("SID")] = SprayId
            exports['mythic-laptop']:SetGangMetadata(Gang.Id, "LastSprayContest", os.time())
            
            local spraysContested = exports['mythic-laptop']:GetGangMetadata(Gang.Id, "SpraysContested") or 0
            spraysContested = spraysContested + 1
            exports['mythic-laptop']:SetGangMetadata(Gang.Id, "SpraysContested", spraysContested)
            cb(true)
        end)
        
    
        Callbacks:RegisterServerCallback("mythic-graffiti/server/get-contested-sprays", function(source, GangId, cb)
            cb(ContestedSprays[GangId] or {})
        end)
    
        Callbacks:RegisterServerCallback("mythic-graffiti/server/can-claim-graffiti", function(source, data, cb)
            local Player = Fetch:Source(source)
            if Player == nil then return end
    
            if not Contesters[Player:GetData("Character"):GetData("SID")] then
                return cb(false)
            end
    
            local SprayId = Contesters[Player:GetData("Character"):GetData("SID")]
            cb(os.time() >= Config.Graffitis[SprayId].ContestTimestamp + (60 * (Config.Contesttimer or 1)))
        end)
    
        Callbacks:RegisterServerCallback("mythic-base/remove-item", function(source, data, cb)
            local Player = Fetch:Source(source)
            if Player == nil then return cb(false) end
            cb(Inventory.Items:Remove(Player:GetData("Character"):GetData("SID"), 1, data.item, data.amount))
        end)

        Callbacks:RegisterServerCallback("mythic-laptop/server/unknown/has-gang-reached-limit", function(source, GangId, cb)
            local Gang = exports['mythic-laptop']:GetGangById(GangId)
            if Gang == nil then
                return cb(false)
            end
    
            local TimestampOfToday = os.time({ hour = 0, min = 0, sec = 0, day = os.date("%d"), month = os.date("%m"), year = os.date("%Y") })
            local LastSpray = exports['mythic-laptop']:GetGangMetadata(GangId, "LastSprayTimestamp")
    
            if not LastSpray then
                return cb(false)
            end
    
            -- Compare CurrentTimestamp and LastSprayTimestamp, check if they are on different dates, if so then the daily limit has been reset.
            local DateNow = os.date("%Y-%m-%d", os.time())
            local DateSpray = os.date("%Y-%m-%d", LastSpray)
            local YearNow, MonthNow, DayNow = DateNow:match("(%d+)-(%d+)-(%d+)")
            local YearSpray, MonthSpray, DaySpray = DateSpray:match("(%d+)-(%d+)-(%d+)")
    
            -- if the year, month or day is different, reset 'GraffitisSprayedToday' and return false.
            if YearSpray ~= YearNow or MonthSpray ~= MonthNow or DaySpray ~= DayNow then
                exports['mythic-laptop']:SetGangMetadata(GangId, "GraffitisSprayedToday", 0)
                return cb(false)
            else
                local GraffitisSprayedToday = exports['mythic-laptop']:GetGangMetadata(GangId, "GraffitisSprayedToday")
                cb(GraffitisSprayedToday >= Config.DailyLimit)
            end
        end)
    
        Callbacks:RegisterServerCallback("mythic-graffiti/server/can-contest-spray", function(source, GangId, cb)
            local Gang = exports['mythic-laptop']:GetGangById(GangId)
            if Gang == nil then
                return cb(false)
            end
    
            local TimestampOfToday = os.time({ hour = 0, min = 0, sec = 0, day = os.date("%d"), month = os.date("%m"), year = os.date("%Y") })
            local LastSpray = exports['mythic-laptop']:GetGangMetadata(GangId, "LastSprayContest")
    
            if not LastSpray then
                return cb(true)
            end
    
            -- Compare CurrentTimestamp and LastSprayContest, check if they are on different dates, if so then the daily limit has been reset.
            local DateNow = os.date("%Y-%m-%d", os.time())
            local DateSpray = os.date("%Y-%m-%d", LastSpray)
            local YearNow, MonthNow, DayNow = DateNow:match("(%d+)-(%d+)-(%d+)")
            local YearSpray, MonthSpray, DaySpray = DateSpray:match("(%d+)-(%d+)-(%d+)")
    
            -- if the year, month or day is different, reset 'SpraysContested' and allow contest.
            if YearSpray ~= YearNow or MonthSpray ~= MonthNow or DaySpray ~= DayNow then
                exports['mythic-laptop']:SetGangMetadata(GangId, "SpraysContested", 0)
                return cb(true)
            end
    
            cb(false)
        end)
    end)
end)


-- [ Functions ] --

function GetSpraysByGang(GangId)
    local Retval = {}

    for k, v in pairs(Config.Graffitis) do
        if v.Gang and v.Gang == GangId then
            Retval[#Retval + 1] = v
        end
    end

    return Retval
end

exports("GetSpraysByGang", GetSpraysByGang)

function LoadSprays()
    Config.Graffitis = {}
    local result = MySQL.query.await('SELECT * FROM `laptop_sprays`', {})
    if not result or #result == 0 then
        return
    end
    for k, v in pairs(result) do
        local Coords = json.decode(v.position)
        local Rotation = json.decode(v.rotation)
        if Coords and Rotation then
            table.insert(Config.Graffitis, {
                Id = v.id,
                Gang = v.gang_id,
                Type = v.type,
                Coords = vector3(Coords.x, Coords.y, Coords.z),
                Rotation = vector3(Rotation.x, Rotation.y, Rotation.z)
            })
        end
    end
end

-- [ Events ] --

RegisterNetEvent("mythic-graffiti/server/purchase-spray", function(Data)
    local source = source
    local Player = Fetch:Source(source)
    if Player == nil then return end

    if Config.Sprays[Data.Spray] == nil then return end
    local Cost = Config.Sprays[Data.Spray].IsGang and Config.GangSprayPrice or Config.SprayPrice

    if Config.Sprays[Data.Spray].IsGang then
        local Gang = exports['mythic-laptop']:GetGangByPlayer(Player:GetData("Character"):GetData("SID"))
        if not Gang or Gang.Id ~= Data.Spray then
            return Execute:Client(source, "Notification", "Error", "This spray does not seem to fit you..")
        end
    end

    if not Wallet:Modify(source, -1 * Cost) then
        return Execute:Client(source, "Notification", "Error", "Not enough cash..")
    end
    kprint("spray is: ".. Data.Spray)
    Inventory:AddItem(Player:GetData("Character"):GetData("SID"),"spray_"..Data.Spray, 1, {}, 1)
end)

RegisterNetEvent("mythic-graffiti/server/purchase-scrubcloth", function(Data)
    local source = source
    local Player = Fetch:Source(source)
    if Player == nil then return end

    if not Wallet:Modify(source, -1 * Config.ScrubPrice) then
        return Execute:Client(source, "Notification", "Error", "Not enough cash..")
    end

    Inventory:AddItem(Player:GetData("Character"):GetData("SID"),'scrubbingcloth', 1, {}, 1)
end)

RegisterNetEvent('GangSystem:MarkPlace', function(coords, email)
    local src = source
    TriggerClientEvent("Client:MarkPlace", src, coords)
end)