Config = Config or {}
Config.Debug = false

function Kprint(...)
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