Config = Config or {}
Config.Debug = false
Config.Graffitis = {}
Config.NearbyGraffitis = {}

-- Editable

Config.DailyLimit = 1 -- How many times can a player spray per day?
Config.Contesttimer = 3 -- How much minuets wanna make the player wait before can clime the graffiti?
Config.NeedOnline = 3 -- How many players need to can scrub/contest they graffitis?
Config.TopCount = 3 -- How many Gangs wanna show in Top Gangs in laptop?  Note: false mean 0
Config.EnableSaler = true -- Do you want enable the saler for sprays?


-- items
Config.ScrubPrice = 60500 
Config.GangSprayPrice = 9999
-- Config.laptopPrice = 45000
-- Config.SprayPrice = 5000

Config.Sprays = {
    ["flying_dragons"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Flying Dragons",
        Model = "mercy_sprays_flying_dragons",
        SprayColor = { 255, 0, 0 },
        BlipColor = 6,
    },
    ["kings"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Kings",
        Model = "mercy_sprays_kings",
        SprayColor = { 255, 255, 255 },
        BlipColor = 0,
    },
    ["los_aztecas"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Los Aztecas",
        Model = "mercy_sprays_los_aztecas",
        SprayColor = { 93, 182, 229 },
        BlipColor = 18,
    },
    ["los_muertos_mc"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Los Muertos MC",
        Model = "mercy_sprays_los_muertos",
        SprayColor = { 255, 255, 255 },
        BlipColor = 62,
    },
    ["marabunta_perrera"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Marabunta Perrera",
        Model = "mercy_sprays_marabunta_perrera",
        SprayColor = { 0, 0, 255 },
        BlipColor = 38,
    },
    ["dark_wolves"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Dark Wolves MC",
        Model = "mercy_sprays_dark_wolves",
        SprayColor = { 208, 201, 183 },
        BlipColor = 16,
    },
    ["ogs"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Original Gangsters",
        Model = "mercy_sprays_ogs",
        SprayColor = { 255, 255, 255 },
        BlipColor = 20,
    },
    ["los_lobos"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Los Lobos",
        Model = "mercy_sprays_los_lobos",
        SprayColor = { 0, 255, 0 },
        BlipColor = 30,
    },
    ["death_sinners"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Death Sinners MC",
        Model = "mercy_sprays_death_sinners",
        SprayColor = { 250, 128, 114 },
        BlipColor = 51,
    },
    ["white_widow"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "White Widow",
        Model = "mercy_sprays_white_widow",
        SprayColor = { 0, 255, 0 },
        BlipColor = 69,
    },
    ["skull_gang"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Skull Gang",
        Model = "mercy_sprays_skull_gang",
        SprayColor = { 255, 255, 255 },
        BlipColor = 53,
    },
    ["grizzley_gang"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Grizzley Gang",
        Model = "mercy_sprays_grizzley_gang",
        SprayColor = { 255, 0, 0 },
        BlipColor = 61,
    },
    ["scum"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Scum",
        Model = "mercy_sprays_scum",
        SprayColor = { 0, 255, 0 },
        BlipColor = 56,
    },
    ["ballas"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Ballas",
        Model = "mercy_sprays_ballas",
        SprayColor = { 128, 0, 128 },
        BlipColor = 7,
    },
    ["wutang"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Wu-Tang",
        Model = "mercy_sprays_wutang",
        SprayColor = { 255, 255, 0 },
        BlipColor = 5,
    },
    ["nameless"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "The Nameless",
        Model = "mercy_sprays_nameless",
        SprayColor = { 255, 105, 180 },
        BlipColor = 8,
    },
    ["21"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "21",
        Model = "mercy_sprays_21",
        SprayColor = { 255, 0, 0 },
        BlipColor = 48,
    },
    ["vatoslocos"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Vatos Loco's",
        Model = "mercy_sprays_vatoslocos",
        SprayColor = { 128, 128, 128 },
        BlipColor = 65,
    },
    ["bumpergang"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "BumperGang",
        Model = "mercy_sprays_bumpergang",
        SprayColor = { 255, 0, 0 },
        BlipColor = 1,
    },
    ["getbackgang"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Get Back Gang",
        Model = "mercy_sprays_getbackgang",
        SprayColor = { 255, 255, 255 },
        BlipColor = 52,
    },
    ["blackcobras"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Black Cobras",
        Model = "mercy_sprays_blackcobras",
        SprayColor = { 255, 0, 0 },
        BlipColor = 50,
    },
    ["blacklist"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Blacklist",
        Model = "mercy_sprays_blacklist",
        SprayColor = { 255, 255, 255 },
        BlipColor = 31,
    },
    ["nls"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "NLS",
        Model = "mercy_sprays_nls",
        SprayColor = { 255, 255, 255 },
        BlipColor = 17,
    },
    ["sopranos"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Sopranos",
        Model = "mercy_sprays_sopranos",
        SprayColor = { 0, 0, 255 },
        BlipColor = 81,
    },
    ["s2n"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Second2None",
        Model = "mercy_sprays_s2n",
        SprayColor = { 255, 255, 255 },
        BlipColor = 23,
    },
    ["tffc"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Thieves & Crooks",
        Model = "mercy_sprays_tffc",
        SprayColor = { 255, 255, 255 },
        BlipColor = 76,
    },
    ["dimeo"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "DiMeo",
        Model = "mercy_sprays_dimeo",
        SprayColor = { 0, 255, 0 },
        BlipColor = 81,
    },
    ["cosanostra"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Cosa Nostra",
        Model = "mercy_sprays_cosanostra",
        SprayColor = { 128, 0, 128 },
        BlipColor = 63,
    },
    ["high_table"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "The High Table",
        Model = "mercy_sprays_high_table",
        SprayColor = { 255, 215, 0 },
        BlipColor = 46,
    },
    ["ant"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Ain't No Telling",
        Model = "mercy_sprays_ant",
        SprayColor = { 45, 245, 220 },
        BlipColor = 36,
    },
    ["wanheda"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Wanheda",
        Model = "mercy_sprays_wanheda",
        SprayColor = { 250, 128, 114 },
        BlipColor = 51,
    },
    ["clutch"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Clutch",
        Model = "mercy_sprays_clutch",
        SprayColor = { 0, 255, 0 },
        BlipColor = 2,
    },
    ["bearly_legal_mc"] = {
        IsGang = true,
        IsBusiness = false,
        Name = "Bearly Legal MC",
        Model = "mercy_sprays_bearlymc",
        SprayColor = { 255, 0, 0 },
        BlipColor = 76,
    },
}

function kprint(...)
    if Config.Debug then
        local args = {...}
        local str_args = {}

        -- Convert each argument to a string
        for _, v in ipairs(args) do
            table.insert(str_args, tostring(v))  -- Ensure all values are converted to strings
        end

        print(table.concat(str_args, " "))  -- Join all stringified arguments
    end
end