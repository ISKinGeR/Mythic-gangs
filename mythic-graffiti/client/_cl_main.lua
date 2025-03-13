_ready = false
AddEventHandler("Graffiti:Shared:DependencyUpdate", RetrieveComponents)
function RetrieveComponents()
	Logger = exports["mythic-base"]:FetchComponent("Logger")
	Callbacks = exports["mythic-base"]:FetchComponent("Callbacks")
	Progress = exports["mythic-base"]:FetchComponent("Progress")
	PedInteraction = exports["mythic-base"]:FetchComponent("PedInteraction")
    Targeting = exports["mythic-base"]:FetchComponent("Targeting")
	ListMenu = exports["mythic-base"]:FetchComponent("ListMenu")
	Notification = exports["mythic-base"]:FetchComponent("Notification")
	Inventory = exports["mythic-base"]:FetchComponent("Inventory")

    _ready = true
end

AddEventHandler("Core:Shared:Ready", function()
	exports["mythic-base"]:RequestDependencies("Graffiti", {
		"Logger",
		"Callbacks",
		"Progress",
        "PedInteraction",
		"Targeting",
		"ListMenu",
		"Notification",
		"Inventory",

	}, function(error)
		if #error > 0 then
			return
		end
		RetrieveComponents()
        SetupEyes()
		-- Started()

    end)
end)

IsPlacing, SprayingParticle, SprayingCan = false, false, false

RegisterNetEvent('Characters:Client:Spawn', function()
    Citizen.SetTimeout(950, function() 
        DeleteDiscoveredSprays()
        Callbacks:ServerCallback("mythic-graffiti/server/get-sprays",{}, function(data)
            Config.Graffitis = data
        end)
    end)
end)



-- function Started()
--     Citizen.SetTimeout(950, function() 
--         DeleteDiscoveredSprays()
--         Config.Graffitis = {}
--         Callbacks:ServerCallback("mythic-graffiti/server/get-sprays",{}, function(data)
--             Config.Graffitis = data
--         end)
--     end)
-- end


-- [ Code ] --

-- [ Threads ] --

CreateThread(function()
    Wait(1000)
    while not _ready do Wait(100) end

    Callbacks:ServerCallback("mythic-graffiti/server/get-sprays",{}, function(data)
        Config.Graffitis = data
    end)
    while true do
        if LocalPlayer.state.loggedIn then
            local PlayerPos = GetEntityCoords(PlayerPedId())
            if Config.Graffitis then
                for k, v in pairs(Config.Graffitis) do
                    local Distance = #(PlayerPos - v.Coords)
                    if Distance > 100.0 and v.Entity then
                        DeleteObject(v.Entity)
                        v.Entity = false
                        Config.NearbyGraffitis[v.Entity] = nil
                    elseif Distance < 100.0 and not v.Entity then
                        local SprayData = Config.Sprays[v.Type]
                        if SprayData then
                            v.Entity = CreateObjectNoOffset(SprayData.Model, v.Coords, false, false, false)
                            FreezeEntityPosition(v.Entity, true)
                            SetEntityRotation(v.Entity, v.Rotation.x, v.Rotation.y, v.Rotation.z)
                            Config.NearbyGraffitis[v.Entity] = v
                            Config.NearbyGraffitis[v.Entity].Key = k
                        end
                    end
                end
            end
        end
        Wait(1000)
    end
end)

-- [ Functions ] --

function SprayingAnim(SprayColor)
    if SprayingCan then DeleteObject(SprayingCan) end

    local AnimDict, ShakeName, SprayName = "switch@franklin@lamar_tagging_wall", "lamar_tagging_wall_loop_lamar", "lamar_tagging_exit_loop_lamar"
    RequestAnimDict(AnimDict)
    RequestModel("prop_cs_spray_can")

    RequestNamedPtfxAsset("scr_playerlamgraff")
    while not HasNamedPtfxAssetLoaded("scr_playerlamgraff") do Wait(4) end

    local PlyCoords = GetEntityCoords(PlayerPedId())
    SprayingCan = CreateObject("prop_cs_spray_can", PlyCoords.x, PlyCoords.y, PlyCoords.z, true, true, false)
    AttachEntityToEntity(SprayingCan, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 28422), 0, -0.01, -0.012, 0, 0, 0, true, true, false, false, 2, true)

    CreateThread(function()
        TaskPlayAnim(PlayerPedId(), AnimDict, ShakeName, 8.0, -8.0, -1, 8192, 0.0, false, false, false)
        Wait(5500)
        TaskPlayAnim(PlayerPedId(), AnimDict, SprayName, 8.0, -2.0, -1, 8193, 0.0, false, false, false)
    
        if not SprayingParticle then
            UseParticleFxAssetNextCall("scr_playerlamgraff")
            SprayingParticle = StartParticleFxLoopedOnEntity("scr_lamgraff_paint_spray", SprayingCan, 0, 0, 0, 0, 0, 0, 1.0, false, false, false)
            SetParticleFxLoopedColour(SprayingParticle, SprayColor[1] / 255, SprayColor[2] / 255, SprayColor[3] / 255, 0)
            SetParticleFxLoopedAlpha(SprayingParticle, 0.25)
        end
    end)
end

function GetGraffitiById(Id)
    for k, v in pairs(Config.Graffitis) do
        if v.Id == Id then
            return v
        end
    end

    return false
end

function GetClosestGraffiti(GangOnly, Coords)
    local Pos = Coords or GetEntityCoords(PlayerPedId())
    local ClosestId, ClosestDistance = false, 0
    
    for k, v in pairs(Config.NearbyGraffitis) do
        if not v then goto Skip end
        local Distance = #(Pos - v.Coords)
        if (not ClosestId or Distance < ClosestDistance) and (not GangOnly or Config.Sprays[v.Type].IsGang) then
            ClosestId, ClosestDistance = v.Key, Distance
        end
        ::Skip::
    end

    return ((ClosestId and ClosestDistance < 90.0 and Config.Graffitis[ClosestId]) or false)
end

function IsGangSpray(Entity)
    if Config.NearbyGraffitis[Entity] == nil then 
        return false 
    end
    return Config.Sprays[Config.NearbyGraffitis[Entity].Type].IsGang
end

exports("IsGangSpray", IsGangSpray)

function IsPlayerInSprayGang(Entity)
    if Config.NearbyGraffitis[Entity] == nil then
        return false
    end
    local v = promise:new()

    local Gang = LocalPlayer.state.PlayerGang
    if not Gang then
        Callbacks:ServerCallback("mythic-laptop/server/unknown/get-player-gang", {}, function(ServerGang)
            if ServerGang then
                Gang = ServerGang
            end

            if Gang and Gang.Id == Config.NearbyGraffitis[Entity].Type then
                v:resolve(true)
            else
                v:resolve(false)
            end
        end)
    else
        if Gang.Id == Config.NearbyGraffitis[Entity].Type then
            v:resolve(true)
        else
            v:resolve(false)
        end
    end

    return Citizen.Await(v)
end
exports("IsPlayerInSprayGang", IsPlayerInSprayGang)

function IsGraffitiContested(Entity)
    if Config.NearbyGraffitis[Entity] == nil then return false end
    -- local v = promise:new()
    -- Callbacks:ServerCallback("mythic-graffiti/server/is-graffiti-contested", Config.NearbyGraffitis[Entity].Key, function(isContested)
    --     v:resolve(isContested)
    -- end)
    -- return Citizen.Await(v)
    return GlobalState[string.format("Graffiti:%s:Contested", Config.NearbyGraffitis[Entity].Key)]
end
exports("IsGraffitiContested", IsGraffitiContested)

function IsInGangTurf(GangId)
    local ClosestGraffiti = GetClosestGraffiti(true, GetEntityCoords(PlayerPedId()))
    return ClosestGraffiti and ClosestGraffiti.Type == GangId
end
exports("IsInGangTurf", IsInGangTurf)

-- [ Events ] --

RegisterNetEvent("mythic-graffiti/client/place-spray", function(Type, IsAdmin)
    if IsPlacing or Progress:CurrentAction() ~= nil then return end
    IsPlacing = true

    if not Config.Sprays[Type] then
        IsPlacing = false
        return Notification:Error("Spraytype does not exist..")
    end

    local _Admin = IsAdmin and LocalPlayer.state.isAdmin

    DoGraffitiPlacer(Config.Sprays[Type].Model, 4.0, false, true, nil, function(Placed, Coords, Rotation)
        if not Placed then
            IsPlacing = false
            return Notification:Error("You canceled spraying")
        end

        local Gang = LocalPlayer.state.PlayerGang
        if not Gang then
            Callbacks:ServerCallback("mythic-laptop/server/unknown/get-player-gang", {}, function(ServerGang)
                if not ServerGang then
                    IsPlacing = false
                    return
                end
                Gang = ServerGang

                Callbacks:ServerCallback("mythic-laptop/server/unknown/has-gang-reached-limit", { Type }, function(HasGangReachedLimit)
                    if not _Admin and Config.Sprays[Type].IsGang and HasGangReachedLimit then
                        IsPlacing = false
                        return Notification:Error("Your group has reached the daily limit, please try again tomorrow.")
                    end

                    local ClosestGraffiti = GetClosestGraffiti(true, Coords)

                    if ClosestGraffiti and ClosestGraffiti.Type ~= Type and Config.Sprays[Type].IsGang then
                        IsPlacing = false
                        return Notification:Error("You cannot place sprays on hostile territory!")
                    end

                    if ClosestGraffiti and ClosestGraffiti.Type == Type and Config.Sprays[Type].IsGang and #(GetEntityCoords(PlayerPedId()) - ClosestGraffiti.Coords) < 75.0 then
                        IsPlacing = false
                        return Notification:Error("You are too close to another spray!")
                    end

                    TaskTurnPedToFaceCoord(PlayerPedId(), Coords.x, Coords.y, Coords.z, 1000)
                    Wait(1000)

                    local Alpha = 0
                    local TempSpray = CreateObjectNoOffset(Config.Sprays[Type].Model, Coords, false, false, false)
                    local Offset = GetOffsetFromEntityInWorldCoords(TempSpray, 0.0, 0.5, 0.0)
                    TaskGoToCoordAnyMeans(PlayerPedId(), Offset.x, Offset.y, Offset.z, 1.0, 0, 0, 786603, 0xbf800000)
                    FreezeEntityPosition(TempSpray, true)
                    SetEntityRotation(TempSpray, Rotation.x, Rotation.y, Rotation.z)
                    SetEntityAlpha(TempSpray, 0, false)

                    Wait(2000)

                    SprayingAnim(Config.Sprays[Type].SprayColor)

                    CreateThread(function()
                        while Alpha < 255 do
                            Alpha = Alpha + 51
                            SetEntityAlpha(TempSpray, Alpha, false)
                            Wait(7956)
                        end
                    end)

                    Progress:Progress({
                        name = "spray_graffiti",
                        duration = 40000,
                        label = "Spraying...",
                        useWhileDead = false,
                        canCancel = true,
                        ignoreModifier = true,
                        controlDisables = {
                            disableMovement = true,
                            disableCarMovement = true,
                            disableMouse = false,
                            disableCombat = true,
                        },
                    }, function(cancelled)
                        ClearPedTasks(PlayerPedId())
                        StopParticleFxLooped(SprayingParticle, true)
                        DeleteObject(TempSpray)
                        DeleteObject(SprayingCan)
                        StopAnimTask(PlayerPedId(), "switch@franklin@lamar_tagging_wall", "lamar_tagging_exit_loop_lamar", 1.0)
                        IsPlacing, SprayingParticle = false, false
                    
                        if not cancelled then
                            local data = {
                                Type = Type,
                                Coords = Coords,
                                Rotation = Rotation,
                                _Admin = _Admin
                            }
                            Callbacks:ServerCallback("mythic-graffiti/server/create-spray", data)
                        end
                    end)
                end)
            end)
        else
            Callbacks:ServerCallback("mythic-laptop/server/unknown/has-gang-reached-limit", { Type }, function(HasGangReachedLimit)
                if not _Admin and Config.Sprays[Type].IsGang and HasGangReachedLimit then
                    IsPlacing = false
                    return Notification:Error("Your group has reached the daily limit, please try again tomorrow.")
                end

                local ClosestGraffiti = GetClosestGraffiti(true, Coords)

                if ClosestGraffiti and ClosestGraffiti.Type ~= Type and Config.Sprays[Type].IsGang then
                    IsPlacing = false
                    return Notification:Error("You cannot place sprays on hostile territory!")
                end

                if ClosestGraffiti and ClosestGraffiti.Type == Type and Config.Sprays[Type].IsGang and #(GetEntityCoords(PlayerPedId()) - ClosestGraffiti.Coords) < 75.0 then
                    IsPlacing = false
                    return Notification:Error("You are too close to another spray!")
                end

                TaskTurnPedToFaceCoord(PlayerPedId(), Coords.x, Coords.y, Coords.z, 1000)
                Wait(1000)

                local Alpha = 0
                local TempSpray = CreateObjectNoOffset(Config.Sprays[Type].Model, Coords, false, false, false)
                local Offset = GetOffsetFromEntityInWorldCoords(TempSpray, 0.0, 0.5, 0.0)
                TaskGoToCoordAnyMeans(PlayerPedId(), Offset.x, Offset.y, Offset.z, 1.0, 0, 0, 786603, 0xbf800000)
                FreezeEntityPosition(TempSpray, true)
                SetEntityRotation(TempSpray, Rotation.x, Rotation.y, Rotation.z)
                SetEntityAlpha(TempSpray, 0, false)

                Wait(2000)

                SprayingAnim(Config.Sprays[Type].SprayColor)

                CreateThread(function()
                    while Alpha < 255 do
                        Alpha = Alpha + 51
                        SetEntityAlpha(TempSpray, Alpha, false)
                        Wait(7956)
                    end
                end)

                Progress:Progress({
                    name = "spray_graffiti",
                    duration = 40000,
                    label = "Spraying...",
                    useWhileDead = false,
                    canCancel = true,
                    ignoreModifier = true,
                    controlDisables = {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    },
                }, function(cancelled)
                    ClearPedTasks(PlayerPedId())
                    StopParticleFxLooped(SprayingParticle, true)
                    DeleteObject(TempSpray)
                    DeleteObject(SprayingCan)
                    StopAnimTask(PlayerPedId(), "switch@franklin@lamar_tagging_wall", "lamar_tagging_exit_loop_lamar", 1.0)
                    IsPlacing, SprayingParticle = false, false
                
                    if not cancelled then
                        local data = {
                            Type = Type,
                            Coords = Coords,
                            Rotation = Rotation,
                            _Admin = _Admin
                        }
                        Callbacks:ServerCallback("mythic-graffiti/server/create-spray", data)
                    end
                end)
            end)
        end
    end)
end)

RegisterNetEvent("mythic-graffiti/client/add-spray", function(SprayId, SprayData)
    if not LocalPlayer.state.loggedIn then return end
    kprint("[DEBUG] Spray ID:", SprayId)
    kprint("[DEBUG] Spray Data:", SprayData)
    Config.Graffitis[SprayId] = SprayData
end)

RegisterNetEvent("mythic-graffiti/client/destroy-graffiti", function(SprayId)
    if not LocalPlayer.state.loggedIn then return end

    if not Config.Graffitis[SprayId] then
        return
    end

    if Config.Graffitis[SprayId].Entity then
        Config.NearbyGraffitis[Config.Graffitis[SprayId].Entity] = false
        DeleteObject(Config.Graffitis[SprayId].Entity)
    end

    table.remove(Config.Graffitis, SprayId)
end)

RegisterNetEvent("mythic-graffiti/client/purchase-gang-spray", function()
    kprint("[DEBUG] Triggered purchase-gang-spray event")

    local Gang = LocalPlayer.state.PlayerGang
    if not Gang then
        Callbacks:ServerCallback("mythic-laptop/server/unknown/get-player-gang", {}, function(ServerGang)
            if not ServerGang then
                kprint("[DEBUG] Invalid gang data returned from server.")
                return
            end
            Gang = ServerGang
            
            if not Config.Sprays[Gang.Id] then
                kprint("[DEBUG] Invalid spray or spray not found for Gang ID:", Gang and Gang.Id or "nil")
                return
            end
    
            local menuData = {
                main = {
                    label = "Purchase Gang Spray",
                    items = {}
                }
            }
    
            table.insert(menuData.main.items, {
                label = Config.Sprays[Gang.Id].Name .. " Spray ($" .. Config.GangSprayPrice .. ")",
                icon = 'spray-can',
                event = 'graffiti/server/purchase-spray',
                data = { Spray = Gang.Id },
            })
    
            Citizen.SetTimeout(50, function()
                ListMenu:Show(menuData)
            end)
        end)
    else
        if not Config.Sprays[Gang.Id] then
            kprint("[DEBUG] Invalid spray or spray not found for Gang ID:", Gang and Gang.Id or "nil")
            return
        end
    
        local menuData = {
            main = {
                label = "Purchase Gang Spray",
                items = {}
            }
        }
    
        table.insert(menuData.main.items, {
            label = Config.Sprays[Gang.Id].Name .. " Spray ($" .. Config.GangSprayPrice .. ")",
            icon = 'spray-can',
            event = 'graffiti/server/purchase-spray',
            data = { Spray = Gang.Id },
        })
    
        Citizen.SetTimeout(50, function()
            ListMenu:Show(menuData)
        end)
    end
end)


-- RegisterNetEvent("mythic-graffiti/client/purchase-spray", function()
--     kprint("[DEBUG] Triggered purchase-spray event")

--     local menuData = {
--         main = {
--             label = "Purchase Spray",
--             items = {}
--         }
--     }

--     for k, v in pairs(Config.Sprays) do

--         if not v.IsGang then
--             table.insert(menuData.main.items, {
--                 label = v.Name .. " Spray",
--                 icon = 'spray-can',
--                 event = 'graffiti/server/purchase-spray',
--                 data = { Spray = k },
--             })
--         end
--     end

--     ListMenu:Show(menuData)
-- end)

RegisterNetEvent("mythic-graffiti/client/purchase-scrubcloth", function()
    TriggerServerEvent("mythic-graffiti/server/purchase-scrubcloth")
end)

RegisterNetEvent("graffiti/server/purchase-spray", function(data)
    -- kprint(json.encode(data))
    TriggerServerEvent("mythic-graffiti/server/purchase-spray", data)
end)

RegisterNetEvent('Client:MarkPlace', function(coords)
    DeleteWaypoint()
    Wait(1000)
    SetNewWaypoint(coords.x, coords.y)
end)

AddEventHandler("onResourceStop", function()
    if Config.Graffitis then
        for k, v in pairs(Config.Graffitis) do
            if v.Entity then
                DeleteObject(v.Entity)
            end
        end
    end
end)