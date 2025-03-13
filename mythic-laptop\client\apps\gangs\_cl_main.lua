RegisterNetEvent("Characters:Client:Spawn", function()
    SetGlobalData()
    if GetResourceKvpString("laptop_preferences") == nil then
        SetResourceKvp("laptop_preferences", json.encode({ background = '', whiteFont = true }))
    end
end)

-- RegisterNetEvent(Config.UiName.."-ui/client/ui-reset", function()
--     SetTimeout(100, SetGlobalData)
-- end)

-- Code

local NetProp, AllProps, HasProp, AttachedProps = {}, {}, false, {}
local PropList = {}
local PropList1 = {
	['Laplet'] = {
		["Model"] = "hei_prop_dlc_tablet",
		["Bone"] = 60309,
		['X'] = 0.03,
		['Y'] = 0.002,
		['Z'] = -0.0,
		['XR'] = 0.0,
		['YR'] = 160.0,
		['ZR'] = 0.0,
    	["VertexIndex"] = 0
	}
}
function AttachProp1(Name)
    if PropList1[Name] ~= nil then
        AttachedProps[Name] = true
        HasProp = true
        local ObjectHash = GetHashKey(PropList1[Name]['Model'])
        if RequestaModel(ObjectHash) then
            local CurrentProp = CreateObject(ObjectHash, 0, 0, 0, true, false, false)
            local PropNetId = ObjToNet(CurrentProp)
            SetNetworkIdExistsOnAllMachines(PropNetId, true)
            SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(CurrentProp), true)
            AttachEntityToEntity(CurrentProp, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), PropList1[Name]['Bone']), PropList1[Name]['X'], PropList1[Name]['Y'], PropList1[Name]['Z'], PropList1[Name]['XR'], PropList1[Name]['YR'], PropList1[Name]['ZR'], true, true, false, true, 1, true)
            table.insert(NetProp, PropNetId)
            table.insert(AllProps, CurrentProp)
            table.insert(PropList, {
                ['Name'] = Name,
                ['NetId'] = PropNetId,
                ['Object'] = CurrentProp
            })
        end
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

function RemoveProps1()
    -- Remove networked props
    for k, v in pairs(NetProp) do
        local propEntity = NetToObj(v)
        if DoesEntityExist(propEntity) then
            NetworkRequestControlOfEntity(propEntity)
            SetEntityAsMissionEntity(propEntity, true, true)
            DeleteObject(propEntity)
        end
    end

    -- Remove all props attached to the player
    for k, v in pairs(AllProps) do
        if DoesEntityExist(v) then
            NetworkRequestControlOfEntity(v)
            SetEntityAsMissionEntity(v, true, true)
            DeleteObject(v)
        end
    end

    -- Clear all lists and flags
    AllProps, NetProp, AttachedProps, PropList = {}, {}, {}, {}
    HasProp = false
    -- Optionally clear any tasks if needed
    -- ClearPedTasks(PlayerPedId())
end


function hasValue(tbl, value)
	for k, v in ipairs(tbl) do
		if v == value or (type(v) == "table" and hasValue(v, value)) then
			return true
		end
	end
	return false
end

RegisterNetEvent("mythic-laptop/client/open", function(Type)
    LaptopVisible = true

    AttachProp1('Laplet')
    RequestAnimDict('amb@code_human_in_bus_passenger_idles@female@tablet@base')
    TaskPlayAnim(PlayerPedId(), "amb@code_human_in_bus_passenger_idles@female@tablet@base", "base", 3.0, 3.0, -1, 49, 0, 0, 0, 0)

    -- local Hour, Minute = exports['mythic-weathersync']:GetCurrentTime()
    local Hour, Minute = 12, 10
    SetNuiFocus(true, true)
    -- Prepare the data to be sent
    local dataToSend = {
        Visible = true,
        HasVPN = hasValue(LocalPlayer.state.Character:GetData("States"), "PHONE_VPN"),
        Time = (Hour < 10 and "0" .. Hour or Hour) .. ":" .. (Minute < 10 and "0" .. Minute or Minute),
        Preferences = json.decode(GetResourceKvpString("laptop_preferences")),
        Type = Type,
        PlayerData = {
            Cid = LocalPlayer.state.Character:GetData("SID")
        },
    }

    -- Debug: Kprint the data before sending it
    Kprint("Sending data to UI:", json.encode(dataToSend))

    -- Now send the data
    SendUIMessage("Laptop/SetVisiblity", dataToSend)

end)

RegisterNetEvent("mythic-laptop/client/add-cotification", function(Logo, Colors, Title, Message)
    SendUIMessage("Laptop/AddNotification", {
        Logo = Logo,
        Colors = Colors,
        Title = Title,
        Message = Message,
    })
end)

-- UI Wrapper Functions
function SetGlobalData()

end

function SendUIMessage(Action, Data)
    SendNUIMessage({
        Action = Action,
        Data = Data
    })
end
exports("SendUIMessage", SendUIMessage)

RegisterNUICallback("Laptop/Close", function(Data, cb)
    LaptopVisible = false
    SetNuiFocus(false, false)

    SendUIMessage("Laptop/SetVisiblity", {
        Visible = false,
    })

    RemoveProps1()
    StopAnimTask(PlayerPedId(), "amb@code_human_in_bus_passenger_idles@female@tablet@base", "base", 1.0)

    cb("Ok")
end)

RegisterNUICallback("Laptop/SaveSettings", function(Data, cb)
    SetResourceKvp("laptop_preferences", json.encode(Data))
    cb("Ok")
end)

RegisterNUICallback("Laptop/GetLocale", function(Data, cb)
    cb(Config.Locale)
end)

RegisterNetEvent("mythic-laptop/client/unknown/accept-invite", function(data)
    Kprint("HERE                                         :",json.encode(data))
    Kprint("HERE                                         :",json.encode(data))
    Kprint("HERE                                         :",json.encode(data))
    Kprint("HERE                                         :",json.encode(data))
    Kprint("HERE                                         :",json.encode(data))
    TriggerServerEvent("mythic-laptop/server/unknown/accept-invite", data)
end)
