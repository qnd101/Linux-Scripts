#!/usr/bin/env luajit
local lfs = require("lfs")

-- Initialize defaults
local args = {
    iter_low = 1,
    iter_high = -1,
    x_log = false,
    y_log = false,
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
    elseif flag == "--log" then
        args.x_log = val:find("-x") and -1 or (val:find("x") and 1 or 0)
        args.y_log = val:find("-y") and -1 or (val:find("y") and 1 or 0)
    else
        print('Unknown flag "' .. flag .. '"')
    end
    i = i + 2
end

if not args.x_min or not args.x_max then
    if args.x_log == 1 then
        args.x_min = 1e-12
        args.x_max = 1e4
    elseif args.x_log == -1 then
        args.x_max = -1e-12
        args.x_min = -1e4
    else
        args.x_min = -5
        args.x_max = 5
    end
end
if not args.y_min or not args.y_max then
    if args.y_log == 1 then
        args.y_min = 1e-20
        args.y_max = 1e4
    elseif args.y_log == -1 then
        args.y_max = -1e-20
        args.y_min = -1e4
    end
end

local gp = assert(io.popen("gnuplot -persist", "w"), "Could not open pipe to gnuplot.")

gp:write(string.format('set xrange [%g:%g]\n', args.x_min, args.x_max));

if args.y_min and args.y_max then
    gp:write(string.format('set yrange [%g:%g]\n', args.y_min, args.y_max));
end

gp:write(string.format('set xlabel "%s"\n', args.xlabel));
gp:write(string.format('set ylabel "%s"\n', args.ylabel));

if args.x_log == 1 then
    gp:write([[
set logscale x
set format x "10^{%L}"
    ]])
elseif args.x_log == -1 then
    gp:write([[
set nonlinear x via -log10(-x) inverse -10**(-x)
set format x "-10^{%L}"
    ]])
end

if args.y_log == 1 then
    gp:write([[
set logscale y
set format y "10^{%L}"
    ]])
elseif args.y_log == -1 then
    gp:write([[
set nonlinear y via -log10(-y) inverse -10**(-y)
set format y "-10^{%L}"
    ]])
end

gp:write(string.format("call '~/scripts/ghost-plot.gnuplot' '%s' '%d' '%d'\n", file, args.iter_low, args.iter_high));

gp:flush() -- Ensure all commands are sent to the process
gp:close()
