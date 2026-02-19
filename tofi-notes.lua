#!/bin/env luajit

package.path = '/home/leeyw/scripts/lua/?.lua;'..package.path
local tofi = require "tofi"
local uv = require "luv"
local lfs = require "lfs"

-- Define a queue type
Queue = {}
Queue = {
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
    setmetatable(result, Queue)
    return result
end

local function shell_escape(str)
  -- Wrap the string in single quotes
  -- Replace any existing ' with '\''
  return "'" .. string.gsub(str, "'", "'\\''") .. "'"
end

local base_paths = {
    '/mnt/Data/Notes/',
    '/mnt/Data/CQM/Resources/',
    '/mnt/Data/CQM/Presentations/Summary/'
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

local getInfo = tofi.spawnTofi(tofi_strings, 800, nil, 'Notes: ')
uv.run()
local output = string.gsub(getInfo().output, '\n', '')

if #output > 0 then
    os.execute('xdg-open '..shell_escape(inv_table[output])..' &')
end
