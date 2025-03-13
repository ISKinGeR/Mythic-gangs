local PlacingObject, IsPlacing, CanPlace = nil, false, false
local RotationCam = false

CreateThread(function()
    RotationCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", 0)
end)

function CheckRay(coords, direction)
    local rayEndPoint = coords + direction * 1000.0
    local rayHandle = StartShapeTestRay(coords.x, coords.y, coords.z, rayEndPoint.x, rayEndPoint.y, rayEndPoint.z, 1,  PlayerPedId())
    local retval, hit, endCoords, surfaceNormal, materialHash, entityHit = GetShapeTestResultEx(rayHandle)
    return surfaceNormal
end

function GetSprayRotation()
    -- Get the camera rotation in world space
    local camRot = GetGameplayCamRot(2)
    return camRot
end

function SetSprayRotation(Entity)
    CreateThread(function()
        local Rotation = GetSprayRotation()
        SetEntityRotation(Entity, Rotation.x, Rotation.y, Rotation.z, 2, true)

        local MarkerCoords = GetOffsetFromEntityInWorldCoords(PlacingObject, 0, -0.1, 0)

        -- Calculate the distance between the player and the object
        local playerCoords = GetEntityCoords(PlayerPedId())
        local objectCoords = GetEntityCoords(PlacingObject)
        local distance = #(playerCoords - objectCoords)

        -- Adjusted rotation (converting degrees to radians for proper rotation)
        local adjustedRotation = vector3(
            math.rad(Rotation.x),
            math.rad(Rotation.y),
            math.rad(Rotation.z)
        )

        -- Check if the distance is too far or if the rotation is out of the allowed range
        if distance > 4.0 or (adjustedRotation.x < -1.0 or adjustedRotation.x > 1.0) then
            CanPlace = false
        else
            CanPlace = true
        end

        -- Draw the placement marker based on CanPlace
        DrawMarker(6, MarkerCoords.x, MarkerCoords.y, MarkerCoords.z, 0.0, 0.0, 0.0, Rotation.x, Rotation.y, Rotation.z, 0.8, 0.3, 0.8, CanPlace and 0 or 255, CanPlace and 255 or 0, 0, 255, false, false, false, false, false, false, false)
    end)
end


function DoGraffitiPlacer(Model, MaxDistance, StickToGround, PlayerHeading, ZMin, cb)
    local HashEntity = GetHashKey(Model)
    if RequestaModel(HashEntity) then
        local MaxDistance = MaxDistance ~= nil and MaxDistance or 5.0
        local CenterCoords = GetEntityCoords(PlayerPedId()) + (GetEntityForwardVector(PlayerPedId()) * 1.5)
        PlacingObject = CreateObject(HashEntity, CenterCoords, false, false, false)
        
        if PlacingObject ~= false then
            IsPlacing = true
            SetEntityCollision(PlacingObject, false)
            SetEntityAlpha(PlacingObject, 0.3, true)
            CreateThread(function()
                while IsPlacing do
                    Wait(4)

                    -- Disable certain controls
                    DisableControlAction(0, 24, true)
                    DisableControlAction(1, 38, true)
                    DisableControlAction(0, 44, true)
                    DisableControlAction(0, 142, true)
                    DisablePlayerFiring(PlayerPedId(), true)

                    CanPlace = true
                    local _, Coords, _ = RayCastGamePlayCamera(10.0)
                    -- Place the object at the camera's location, adjusted to ZMin height
                    SetEntityCoords(PlacingObject, Coords.x, Coords.y, (ZMin ~= nil and Coords.z - ZMin or Coords.z))
                    SetSprayRotation(PlacingObject)

                    if IsControlJustPressed(0, 177) then
                        DeleteEntity(PlacingObject)
                        IsPlacing, PlacingObject = false, nil
                        cb(false)
                    end
                    
                    if CanPlace and IsControlJustPressed(0, 191) then
                        local EntityCoords, EntityRotation = GetEntityCoords(PlacingObject), GetEntityRotation(PlacingObject)
                        DeleteEntity(PlacingObject)
                        cb(true, EntityCoords, EntityRotation)
                        IsPlacing, PlacingObject = false, nil
                    end

                    if PlacingObject ~= nil and #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(PlacingObject)) > MaxDistance then
                        CanPlace = false
                    end

                    if StickToGround and ZMin == nil then
                        PlaceObjectOnGroundProperly(PlacingObject)
                    end
                end
            end)
        else
            cb(false)
        end
    else
        cb(false)
    end
end

function RequestaModel(Model)
    local Request = 0
    RequestModel(Model)
    while not HasModelLoaded(Model) and Request < 50 do
        Citizen.Wait(100)
        Request = Request + 1
    end
    if Request == 50 then
        return false
    else
        return true
    end
end

function RayCastGamePlayCamera(Distance)
    local CameraRotation = GetGameplayCamRot()
    local CameraCoord = GetGameplayCamCoord()
    local Direction = RotationToDirection(CameraRotation)
    local Destination = {x = CameraCoord.x + Direction.x * Distance, y = CameraCoord.y + Direction.y * Distance, z = CameraCoord.z + Direction.z * Distance}
    local A, B, C, D, E = GetShapeTestResult(StartShapeTestRay(CameraCoord.x, CameraCoord.y, CameraCoord.z, Destination.x, Destination.y, Destination.z, -1, PlayerPedId(), 0))
    return B, C, E
end

function RotationToDirection(Rotation)
    local AdjustedRotation = {x = (math.pi / 180) * Rotation.x, y = (math.pi / 180) * Rotation.y, z = (math.pi / 180) * Rotation.z}
    local Direction = vector3(-math.sin(AdjustedRotation.z) * math.abs(math.cos(AdjustedRotation.x)), math.cos(AdjustedRotation.z) * math.abs(math.cos(AdjustedRotation.x)), math.sin(AdjustedRotation.x))
    return Direction
end
