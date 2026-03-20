#!/usr/bin/env luajit
local lfs = require("lfs")

-- Initialize defaults
local args = {
    iter_low = 0,
    iter_high = -1,
    x_min = -5,
    x_max = 5,
    y_min = 0,
    y_max = 2,
    xlabel = "ω",
    ylabel = "",
}

local file = arg[1]
if not file then
    error("Provide file to plot!")
end
assert(lfs.attributes(file), 'file "' .. file .. '" does not exist!')

local i = 2
while i <= #arg do
    local flag = arg[i]
    local val = arg[i + 1]

    if not val then break end

    if flag == "--iter" then
        if val:find(":") then
            args.iter_low, args.iter_high = val:match("([^:]+):([^:]+)")
        else
            args.iter_low = -tonumber(val)
        end
    elseif flag == "--xlim" then
        if val:find(":") then
            args.x_min, args.x_max = val:match("([^:]+):([^:]+)")
        else
            local n = tonumber(val)
            args.x_min, args.x_max = -n, n
        end
    elseif flag == "--ylim" then
        if val:find(":") then
            args.y_min, args.y_max = val:match("([^:]+):([^:]+)")
        else
            local n = tonumber(val)
            args.y_min, args.y_max = 0, n
        end
    elseif flag == "--xlabel" then
        args.xlabel = val
    elseif flag == "--ylabel" then
        args.ylabel = val
    else
        print('Unknown flag "'.. flag.. '"')
    end
    i = i + 2
end

-- 2. Construct the shell command to call gnuplot with 6 positional args
local cmd = string.format("gnuplot -c ~/scripts/ghost-plot.gnuplot '%s' '%d' '%d' '%f' '%f' '%f' '%f' '%s' '%s'",
    file,
    args.iter_low, args.iter_high,
    args.x_min, args.x_max,
    args.y_min, args.y_max,
    args.xlabel, args.ylabel
)

-- Execute
os.execute(cmd)
