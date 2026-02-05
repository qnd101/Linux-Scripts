#!/bin/env luajit

local uv = require "luv"

local script_dir = arg[0]:match("(.-)[^/%\\]+$")
if script_dir == "" then script_dir = "./" end
package.path = script_dir .. "?.lua;" .. package.path

local paperdb_dir = '/mnt/Data/Papers/DB'
local cache_path = "/mnt/Data/Papers/cache.json"

local paperinfo = require "update-metadata"
local fuzzy = require "fuzzy-match"

local cache_data = paperinfo.readCache(cache_path)
local local_dois = paperinfo.getLocalDOIs(paperdb_dir)

if paperinfo.updateCache(local_dois, cache_data) then
    print('Updating cache...')
    paperinfo.writeCache(cache_path, cache_data)
    print('Done!')
end

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


local pipe_in, getOutput = spawnTofi(
    { '--width', '1300', '--height', '250', '--prompt-text', 'Papers: ' }
)

local inv_table = {}
local lines = ''
for doi, paper_data in pairs(cache_data) do
    local author_string = (#paper_data.authors <= 2)
        and table.concat(paper_data.authors, ' & ')
        or paper_data.authors[1]..' et al.'

    local shorthand = author_string ..' ('..paper_data.year..')'

    local line = string.format("%-30s %s", shorthand, paper_data.title)

    inv_table[line] = doi
    lines = lines .. line .. '\n'
end
pipe_in:write(lines)
uv.close(pipe_in)
-- Wait til tofi ends
uv.run()

-- Use output to get doi
local output = string.gsub(getOutput(), '\n', '')

if #output == 0 then
    print "Nothing Selected!"
    return
end
-- There were some unicode issues related to the author name 
-- ex. tofi changes 'Žitko' from NFC into NFD for better fuzzy matching
-- Instead of dealing with unicodes directly, we just find the best match
local doi_selected = assert(tostring(fuzzy.fuzzy_index(output, inv_table)))

local paper_path = paperdb_dir..'/'..string.gsub(doi_selected,'/','_')..'.pdf'
-- print('Selected: '..doi_selected)

-- Create another window for the next action 
pipe_in, getOutput =  spawnTofi {'--prompt-text', 'Action: '}

local options = { 'Open', 'Copy URL', 'Copy Path', 'Copy DOI' }
pipe_in:write(table.concat(options, '\n'))
uv.close(pipe_in)
uv.run()

output = string.gsub(getOutput(), '\n', '')
if output == options[1] then
    os.execute('xdg-open '..paper_path)
elseif output == options[2] then
    os.execute('wl-copy '..string.format('"file://%s"', paper_path))
elseif output == options[3] then
    os.execute('wl-copy '..string.format('"%s"', paper_path))
elseif output == options[4] then
    os.execute('wl-copy '..string.format('"%s"', doi_selected))
end
