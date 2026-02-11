#!/bin/env luajit
package.path = "/home/leeyw/scripts/paper-scripts/?.lua;"
    .. "/home/leeyw/scripts/lua/?.lua;"
    .. package.path

local uv = require "luv"
local paperinfo = require "update-metadata"
local fuzzy = require "fuzzy-match"
local tofi = require "tofi"

local paperdb_dir = '/mnt/Data/Papers/DB'
local cache_path = "/mnt/Data/Papers/cache.json"

local cache_data = paperinfo.readCache(cache_path)
local local_dois = paperinfo.getLocalDOIs(paperdb_dir)

if paperinfo.updateCache(local_dois, cache_data) then
    print('Updating cache...')
    paperinfo.writeCache(cache_path, cache_data)
    print('Done!')
end

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

local getInfo = tofi.spawnTofi(lines, 1300, 250, 'Papers: ')

-- Wait til tofi ends
uv.run()

-- Use output to get doi
local output = string.gsub(getInfo().output, '\n', '')

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
local options = { 'Open', 'Copy Path', 'Copy DOI', 'Copy Path URL', 'Copy DOI URL' }
getInfo = tofi.spawnTofi(options, nil, nil, 'Action: ')
uv.run()

output = string.gsub(getInfo().output, '\n', '')
if output == options[1] then
    os.execute('xdg-open '..paper_path..' &')
elseif output == options[2] then
    os.execute('wl-copy '..string.format('"%s"', paper_path)..' &')
elseif output == options[3] then
    os.execute('wl-copy '..string.format('"%s"', doi_selected)..' &')
elseif output == options[4] then
    os.execute('wl-copy '..string.format('"file://%s"', paper_path)..' &')
elseif output == options[5] then
    os.execute('wl-copy '..string.format('"https://doi.org/%s"', doi_selected)..' &')
end
