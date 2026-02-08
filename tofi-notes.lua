#!/bin/env luajit

-- Define a queue type
Queue = {}
Queue.metatable = {
    __index = {
        push = function (queue, obj)
            queue.last = queue.last + 1
            queue[queue.last] = obj
        end,
        pop = function (queue)
            if queue.last < queue.first then
                return nil
            end
            local result = queue[queue.first]
            queue[queue.first] = nil
            queue.first = queue.first + 1
            return result
        end
    },
}
function Queue.new(list)
    list = list or {}
    local result = {first = 1, last = #list}
    for i = 1, #list do
        result[i] = list[i]
    end
    setmetatable(result, Queue.metatable)
    return result
end

local function shell_escape(str)
  -- Wrap the string in single quotes
  -- Replace any existing ' with '\''
  return "'" .. string.gsub(str, "'", "'\\''") .. "'"
end

local uv = require "luv"
local function spawnTofi(args)
    local pipe_in = uv.new_pipe(false)
    local pipe_out = uv.new_pipe(false)
    local options = {
        stdio = { pipe_in, pipe_out },
        args = args,
    }
    uv.spawn('tofi', options, function(code, signal)
        assert(code == 0, "Failed to spawn tofi")
        uv.close(pipe_out)
    end)
    local output = ""
    uv.read_start(pipe_out, function(err, chunk)
        if chunk then output = output .. chunk end
    end)

    return pipe_in, function ()
        return output end
end

local lfs = require "lfs"

local base_paths = {
    '/mnt/Data/Notes/',
    '/mnt/Data/CQM/Resources/'
}

-- Recursive search for all pdf files under directory 
local inv_table = {}
local tofi_strings = {}
local dir_queue = Queue.new(base_paths)

for base_dir in
    function() return dir_queue:pop() end
    do

    for child in lfs.dir(base_dir) do
        if string.match(child, '^%.') then
            goto continue
        end

        local fullpath = base_dir..child
        local attr = lfs.attributes(fullpath)
        if not attr then goto continue end

        if attr.mode == 'file' and string.match(child, '.pdf$') then
            table.insert(tofi_strings, child)
            inv_table[child] = fullpath
        elseif attr.mode == 'directory' then
            dir_queue:push(fullpath..'/')
        end

        ::continue::
    end
end

local pipe_in, getOutput = spawnTofi{'--prompt-text', "Note: "}
pipe_in:write(table.concat(tofi_strings, '\n'))
uv.close(pipe_in)
uv.run()
local output = string.gsub(getOutput(), '\n', '')

if #output > 0 then
    os.execute('xdg-open '..shell_escape(inv_table[output])..' &')
end
