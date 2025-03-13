local HasDiscoveredEnabled, GraffitiBlips, DiscoveredSprays = false, {}, {}
local HasContestedEnabled, ContestedBlips = false, {}

-- [ Code ] --

-- [ Events ] --

RegisterNetEvent('Characters:Client:Logout', function()
    DeleteDiscoveredSprays()
    DeleteContestedSprays()
    HasDiscoveredEnabled = false
    HasContestedEnabled = false
end)

RegisterNetEvent("mythic-graffiti/client/scrub-graffiti", function(Data, Entity)
    if Progress:CurrentAction() ~= nil then return end

    if not Inventory.Items:Has('scrubbingcloth', 1) then
        return Notification:Error("You need a scrubbing cloth..")
    end

    local Graffiti = Config.NearbyGraffitis[Data.entity]
    if not Graffiti then 
        return Notification:Error("The graffiti looks like children's paint..")
    end

    local Spray = Config.Sprays[Graffiti.Type]
    if not Spray then 
        return Notification:Error("The graffiti looks like children's paint..")
    end

    if Spray.IsGang then
        Callbacks:ServerCallback("mythic-graffiti/server/is-gang-online", Graffiti.Type, function(CanBeScrubbed)
            if not CanBeScrubbed then
                return Notification:Error("You can't do this right now, try again later.")
            end

            if Spray.IsGang and CanBeScrubbed then
                local data = {
                    GangId = Graffiti.Type,
                    Type = "Scrub",
                    StreetName = GetStreetName(),
                    Coords = GetEntityCoords(PlayerPedId())
                }
                Callbacks:ServerCallback("mythic-graffiti/server/alert-sprayer", data)
            end

            local dataItem = {
                item = 'scrubbingcloth',
                amount = 1
            }

            TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_MAID_CLEAN", 0, true)

            Progress:Progress({
                name = "scrubbing_graffiti",
                duration = 60000 * 4,
                label = "Scrub, scrub, scrub 🧽💦",
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
                if not cancelled then
                    Callbacks:ServerCallback('mythic-base/remove-item', dataItem, function(DidRemove)
                        if not DidRemove then return end
                        Callbacks:ServerCallback("mythic-graffiti/server/destroy-spray", Graffiti.Key)
                    end)
                end
            end)

        end)
    else
        Notification:Error("You can't do this right now, try again later.")
    end
end)


RegisterNetEvent("mythic-graffiti/client/discover-graffiti", function(Data, Entity)
    Callbacks:ServerCallback("mythic-laptop/server/unknown/get-player-gang", {}, function(Gang)
        if not Gang or Config.Sprays[Gang.Id] == nil then
            return Notification:Error("Gang not found or no sprays available.")
        end

        Callbacks:ServerCallback("mythic-laptop/server/unknown/get-discovered-sprays", Gang.Id, function(Sprays)
            if not Sprays then return Notification:Error("Failed to retrieve discovered sprays.") end

            local Graffiti = Config.NearbyGraffitis[Data.entity]
            if not Graffiti then 
                return Notification:Error("The graffiti looks like children's paint..") 
            end

            local Spray = Config.Sprays[Graffiti.Type]
            if not Spray then 
                return Notification:Error("The graffiti looks like children's paint..") 
            end

            if not Spray.IsGang then
                return Notification:Error("The graffiti doesn't seem to be that exciting..")
            end

            for _, SprayId in pairs(Sprays) do
                if SprayId == Graffiti.Id then
                    return Notification:Error("You've already discovered this graffiti..")
                end
            end

            TriggerServerEvent("mythic-laptop/server/add-discovered", Gang.Id, Graffiti.Id)
        end)
    end)
end)

RegisterNetEvent("mythic-graffiti/client/contest-graffiti", function(Data, Entity)
    Callbacks:ServerCallback("mythic-laptop/server/unknown/get-player-gang", {}, function(Gang)
        if not Gang or Config.Sprays[Gang.Id] == nil then
            return
        end
        if Progress:CurrentAction() ~= nil then
            return
        end
        local Graffiti = Config.NearbyGraffitis[Data.entity]
        if not Graffiti then
            return Notification:Error("The graffiti looks like children's paint..")
        end
        local Spray = Config.Sprays[Graffiti.Type]
        if not Spray then
            return Notification:Error("The graffiti looks like children's paint..")
        end
        if not Spray.IsGang then
            return Notification:Error("The graffiti doesn't seem to be that exciting..")
        end
        Callbacks:ServerCallback("mythic-graffiti/server/is-gang-online", Graffiti.Type, function(IsGangOnline)
            if not IsGangOnline then
                return Notification:Error("You can't do this right now, try again later.")
            end
            Callbacks:ServerCallback("mythic-graffiti/server/can-contest-spray", Gang.Id, function(CanContest)
                if not CanContest then
                    return Notification:Error("You have reached the contest limit, please try again later.")
                end
                if not Inventory.Items:Has("spray_"..string.lower(Gang.Id), 1) then
                    return Notification:Error("You need a spray to spray over this graffiti..")
                end
                local data = {
                    id = Graffiti.Key,
                    clear = false
                }
                Callbacks:ServerCallback("mythic-graffiti/server/set-spray-contested", data, function(Result)
                    if Result then
                        Notification:Info("Conquering Graffiti..")
                        local data = {
                            GangId = Graffiti.Type,
                            Type = "Contest",
                            StreetName = GetStreetName(),
                            Coords = GetEntityCoords(PlayerPedId())
                        }
                        Callbacks:ServerCallback("mythic-graffiti/server/alert-sprayer", Graffiti.Type, "Contest", GetStreetName())
                    end
                end)
            end)
        end)
    end)
end)

RegisterNetEvent("mythic-graffiti/client/claim-graffiti", function(Data, Entity)
    Callbacks:ServerCallback("mythic-laptop/server/unknown/get-player-gang", {}, function(Gang)
        if not Gang or Config.Sprays[Gang.Id] == nil then return end

        Callbacks:ServerCallback("mythic-graffiti/server/can-claim-graffiti", {}, function(CanClaim)
            if not CanClaim then
                return Notification:Error("I think I'll have to wait a while before respraying it....")
            end

            local Graffiti = Config.NearbyGraffitis[Data.entity]
            if not Graffiti then return Notification:Error("The graffiti looks like children's paint..") end

            local Spray = Config.Sprays[Graffiti.Type]
            if not Spray then return Notification:Error("The graffiti looks like children's paint..") end

            if not Spray.IsGang then
                return Notification:Error("The graffiti doesn't seem to be that exciting..")
            end

            IsPlacing = true
            SprayingAnim({255, 255, 255})

            Progress:Progress({
                name = "spraying",
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
                    Callbacks:ServerCallback("mythic-graffiti/server/destroy-spray", Graffiti.Key, function(removed)
                        Wait(1000)
                        if removed then
                            local data = {
                                Type = Gang.Id,
                                Coords = Graffiti.Coords,
                                Rotation = Graffiti.Rotation,
                                _Admin = true
                            }
                            Callbacks:ServerCallback("mythic-graffiti/server/create-spray", data)
                        end
                    end)
                end
            end)
        end)
    end)
end)

RegisterNetEvent("mythic-graffiti/client/toggle-discovered", function()
    HasDiscoveredEnabled = not HasDiscoveredEnabled

    if HasDiscoveredEnabled then
        Callbacks:ServerCallback("mythic-laptop/server/unknown/get-player-gang", {}, function(Gang)
            if Gang then    
                if not Gang or Config.Sprays[Gang.Id] == nil then 
                    return 
                end

                Callbacks:ServerCallback("mythic-laptop/server/unknown/get-discovered-sprays", Gang.Id, function(Sprays)
                    if Sprays then
                        DiscoveredSprays = Sprays
                        ShowDiscoveredSprays()
                        Notification:Success("Enabled Discovered Sprays")
                    end
                end)
            end
        end)
    else
        DeleteDiscoveredSprays()
        Notification:Error("Disabled Discovered Sprays")
    end
end)

RegisterNetEvent("mythic-graffiti/client/toggle-contested", function()
    HasContestedEnabled = not HasContestedEnabled

    if HasContestedEnabled then
        Callbacks:ServerCallback("mythic-laptop/server/unknown/get-player-gang", {}, function(Gang)
            if Gang then    
                if not Gang or Config.Sprays[Gang.Id] == nil then 
                    return 
                end

                Callbacks:ServerCallback("mythic-graffiti/server/get-contested-sprays", Gang.Id, function(Sprays)
                    if Sprays then
                        ContestedSprays = Sprays
                        ShowContestedSprays()
                        Notification:Success("Enabled Contested Sprays")
                    end
                end)
            end
        end)
    else
        DeleteContestedSprays()
        Notification:Error("Disabled Contested Sprays")
    end
end)

RegisterNetEvent("mythic-graffiti/client/update-discovered", function(Data)
    if not HasDiscoveredEnabled then return end
    DiscoveredSprays = Data
    ShowDiscoveredSprays()
end)

RegisterNetEvent("mythic-graffiti/client/remove-spray", function()
    if not LocalPlayer.state.isAdmin then return end

    local Hit, Coords, Entity = RayCastGamePlayCamera(5.0)
    if not Hit or Entity == 0 or Entity == -1 or GetEntityType(Entity) ~= 3 then return Notification:Error("This is not graffiti..") end

    local Graffiti = Config.NearbyGraffitis[Entity]
    if not Graffiti then return Notification:Error("This is not graffiti..") end

    local Spray = Config.Sprays[Graffiti.Type]
    if not Spray then return Notification:Error(Graffiti.Type .. " invalid spray..") end

    Callbacks:ServerCallback("mythic-graffiti/server/destroy-spray", Graffiti.Key)
end)

-- [ Functions ] --

function ShowDiscoveredSprays()
    DeleteDiscoveredSprays()

    for k, v in pairs(DiscoveredSprays) do
        local Graffiti = GetGraffitiById(v)
        if not Graffiti then
            goto Skip
        end

        if not Config.Sprays[Graffiti.Type] then
            kprint(Graffiti.Type .. " invalid graffiti!")
            goto Skip
        end

        if not Config.Sprays[Graffiti.Type].IsGang then
            goto Skip
        end

        GraffitiBlips[Graffiti.Id] = AddBlipForRadius(Graffiti.Coords.x, Graffiti.Coords.y, Graffiti.Coords.z, 90.0)
        SetBlipHighDetail(GraffitiBlips[Graffiti.Id], true)
        SetBlipColour(GraffitiBlips[Graffiti.Id], Config.Sprays[Graffiti.Type].BlipColor)
        SetBlipAsShortRange(GraffitiBlips[Graffiti.Id], false)
        SetBlipAlpha(GraffitiBlips[Graffiti.Id], 130)

        ::Skip::
    end
end

function DeleteDiscoveredSprays()
    for k, v in pairs(GraffitiBlips) do
        RemoveBlip(v)
    end
    GraffitiBlips = {}
end

function ShowContestedSprays()
    DeleteContestedSprays()

    for k, v in pairs(ContestedSprays) do
        local Graffiti = GetGraffitiById(v)
        if not Graffiti then
            goto Skip
        end

        ContestedBlips[Graffiti.Id] = AddBlipForRadius(Graffiti.Coords.x, Graffiti.Coords.y, Graffiti.Coords.z, 50.0)
        SetBlipHighDetail(ContestedBlips[Graffiti.Id], true)
        SetBlipColour(ContestedBlips[Graffiti.Id], 1)
        SetBlipAsShortRange(ContestedBlips[Graffiti.Id], false)
        SetBlipAlpha(ContestedBlips[Graffiti.Id], 130)

        ::Skip::
    end
end

function DeleteContestedSprays()
    for k, v in pairs(ContestedBlips) do
        RemoveBlip(v)
    end
    ContestedBlips = {}
end

function RayCastGamePlayCamera(Distance)
    local CameraRotation = GetGameplayCamRot()
    local CameraCoord = GetGameplayCamCoord()
    local Direction = RotationToDirection(CameraRotation)
    local Destination = {x = CameraCoord.x + Direction.x * Distance, y = CameraCoord.y + Direction.y * Distance, z = CameraCoord.z + Direction.z * Distance}
    local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(CameraCoord.x, CameraCoord.y, CameraCoord.z, Destination.x, Destination.y, Destination.z, -1, PlayerPedId(), 0))
    return b, c, e
end

function GetStreetName(Coords, Type) 
    local Coords = Coords ~= nil and Coords or GetEntityCoords(PlayerPedId())
    local Street1, Street2 = Citizen.InvokeNative(0x2EB41072B4C1E4C0, Coords.x, Coords.y, Coords.z, Citizen.PointerValueInt(), Citizen.PointerValueInt())
    local FirstStreetLabel = GetStreetNameFromHashKey(Street1)
    local SecondStreetLabel = GetStreetNameFromHashKey(Street2)
    if Type ~= 'Single' and SecondStreetLabel ~= nil and SecondStreetLabel ~= "" then 
        FirstStreetLabel = FirstStreetLabel .. " " .. SecondStreetLabel
    end
    return FirstStreetLabel
end