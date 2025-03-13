ServerConfig = ServerConfig or {}

-- Manual option for a max member size.
-- Always do MINUS ONE on the max, the leader doesn't count as a member.
ServerConfig.GangSizes = {
    -- ['devgang'] = 12,
}

ServerConfig.Gangs = {}