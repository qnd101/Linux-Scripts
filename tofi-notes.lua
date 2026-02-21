#!/bin/env luajit

local home_dir = os.getenv("HOME")
package.path = home_dir..'/scripts/lua/?.lua;' .. package.path
local tofi = require "tofi"
local uv = require "luv"
local lfs = require "lfs"

-- Define a queue type
Queue = {}
Queue = {
    __index = {
        push = function(queue, obj)
            queue.last = queue.last + 1
            queue[queue.last] = obj
        end,
        pop = function(queue)
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
    local result = { first = 1, last = #list }
    for i = 1, #list do
        result[i] = list[i]
    end
    setmetatable(result, Queue)
    return result
end

local function shellEscape(str)
    -- Wrap the string in single quotes
    -- Replace any existing ' with '\''
    return "'" .. string.gsub(str, "'", "'\\''") .. "'"
end

local function getExtension(path)
    return path:match('%.([^.]+)$')
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

for _, base_dir in ipairs(base_paths) do
    dir_queue = Queue.new { '' }
    for child_dir in
    function() return dir_queue:pop() end
    do
        local full_dir = base_dir .. child_dir
        for child in lfs.dir(full_dir) do
            -- Ignore files/folders starting with dot
            if string.match(child, '^%.') then
                goto continue
            end
            local fullpath = full_dir .. child
            local attr = lfs.attributes(fullpath)
            if not attr then goto continue end
            if attr.mode == 'file' then
                local extension = getExtension(child)
                if extension == 'pdf' or extension == 'md' then
                    local relpath = child_dir .. child
                    table.insert(tofi_strings, relpath)
                    inv_table[relpath] = fullpath
                end
            elseif attr.mode == 'directory' then
                dir_queue:push(child_dir .. child .. '/')
            end
            ::continue::
        end
    end
end

local getInfo = tofi.spawnTofi(tofi_strings, 800, nil, 'Notes: ')
uv.run()
local output = string.gsub(getInfo().output, '\n', '')

if #output == 0 then return end
local extension = getExtension(output)
if extension == 'pdf' then
    os.execute('xdg-open ' .. shellEscape(inv_table[output]) .. ' &')
elseif extension == 'md' then
    -- Use my custom script for viewing mardown
    os.execute(home_dir..'/scripts/view-md.sh ' .. shellEscape(inv_table[output]))
end
