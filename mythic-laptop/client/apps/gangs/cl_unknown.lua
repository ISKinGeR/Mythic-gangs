RegisterNUICallback("Unknown/FetchGang", function(Data, cb)
    if LocalPlayer.state.PlayerGang then return cb(LocalPlayer.state.PlayerGang) end
    Callbacks:ServerCallback("mythic-laptop/server/unknown/get-player-gang", {}, function(response)
        print("ServerCallback Response:", json.encode(response)) -- Check the response from the server
        cb(response)
    end)
end)


RegisterNUICallback("Unknown/AddMember", function(Data, cb)
    Callbacks:ServerCallback("mythic-laptop/server/unknown/add-member", Data, cb)
end)

RegisterNUICallback("Unknown/KickMember", function(Data, cb)
    Callbacks:ServerCallback("mythic-laptop/server/unknown/kick-member", Data, cb)
end)

RegisterNUICallback("Unknown/ToggleDiscoveredGraffitis", function(Data, cb)
    TriggerEvent("mythic-graffiti/client/toggle-discovered")
    cb("Ok")  -- Send response back to the callback
end)

RegisterNUICallback("Unknown/ToggleContestedGraffitis", function(Data, cb)
    TriggerEvent("mythic-graffiti/client/toggle-contested")
    cb("Ok")  -- Send response back to the callback
end)

RegisterNUICallback("Unknown/GetMessages", function(Data, cb)
    Callbacks:ServerCallback("mythic-laptop/server/unknown/get-messages", {}, cb)
end)

RegisterNUICallback("Unknown/SendMessage", function(Data, cb)
    Callbacks:ServerCallback("mythic-laptop/server/unknown/send-message", Data, cb)
end)

RegisterNUICallback("Unknown/FetchTopGang", function(Data, cb)
    Callbacks:ServerCallback("mythic-graffiti/server/get-top-gangs", Data, function(top)
        if top then 
            print(json.encode(top))
            cb(top)
        end
    end)
end)

RegisterNetEvent("mythic-laptop/client/unknown/refresh-gang-chat", function()
    if LocalPlayer.state.laptopOpen then
        Callbacks:ServerCallback("mythic-laptop/server/unknown/get-messages", {}, function(Result)
            SendUIMessage("Unknown/SetMessages", Result)
        end)
    end
end)
