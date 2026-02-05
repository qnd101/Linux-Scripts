-- TODO: Add query to arxiv
local json = require "cjson"
local lfs = require "lfs"

local function inspect(data)
    for k, v in pairs(data) do
        print(k, v)
    end
end

local function getInverseTable(data)
    local result = {}
    for k, v in pairs(data) do
        result[v] = k
    end
    return result
end

local function getLocalDOIs(paperdb_dir)
    local dois = {}
    for file in lfs.dir(paperdb_dir) do
        local doi = string.match(file, "(.*).pdf")
        if doi then doi = string.gsub(doi, '_', '/') end
        table.insert(dois, doi)
    end
    return dois
end

-- Read the json cache
local function readCache(cache_path)
    assert(cache_path, "Cache path not given!")
    if not lfs.attributes(cache_path) then
        print("WRN: No file at " .. cache_path .. ". Proceeding with empty cache")
        return {}
    end
    local file = assert(io.open(cache_path, "r"))
    local json_string = file:read("*a")
    file:close()
    return json.decode(json_string)
end

local function writeCache(cache_path, cache)
    assert(cache_path, "Cache path not given!")
    local file = assert(io.open(cache_path, "w"))
    local content = assert(json.encode(cache))
    file:write(content)
    file:close()
end

-- Returns success, result
local function getRESTResponse(uri, isjson)
    local proc = io.popen(string.format("wget -O- '%s' 2> /dev/null", uri))
    -- Check for success of creation & execution
    if not proc then return false, "Failed to start wget process" end

    local response = proc:read("*a")
    if not proc:close() then return false, "wget failed execution" end

    if isjson then
        return pcall(json.decode, response)
    else
        return true, response
    end
end

local function getMetadataFromCrossref(doi)
    local email = 'leeyw101@snu.ac.kr'
    local uri = string.format('https://api.crossref.org/works/%s?mailto=%s', doi, email)
    local issuccess, response = getRESTResponse(uri, true)
    if not issuccess then
        return nil, response
    end
    -- Check for failed response
    local message = response.message
    if not message or not message.title then
        return nil, "Crossref API does not have info of " .. doi
    end

    local authors = {}
    for i = 1, #message.author do
        table.insert(authors, message.author[i].family)
    end

    return {
        doi = doi,
        title = message.title[1],
        year = message.created['date-parts'][1][1],
        authors = authors
    }
end

local function getMetaDataFromArxiv(doi)
    local id = doi:match('^10.48550/arXiv%.(.*)')
    print(id)
    if not id then
        return nil, doi .. " is not an arxiv DOI"
    end
    local api_url = "http://export.arxiv.org/api/query?id_list=" .. id

    local issuccess, response = getRESTResponse(api_url, false)

    if not issuccess then
        return nil, "Failed to parse response as json: " .. response
    end

    local entry = response:match("<entry>(.-)</entry>")
    local title = entry:match("<title>(.-)</title>")
    local updated = entry:match("<updated>(.-)</updated>")
    local year = updated and updated:sub(1, 4) or "N/A"
    local authors_list = {}
    for author in entry:gmatch("<author>(.-)</author>") do
        local name = author:match("<name>(.-)</name>")
        table.insert(authors_list, name)
    end

    return {
        doi = doi,
        title = title,
        year = year,
        authors = authors_list,
    }
end

-- Returns whether the cache_data was updated
local function updateCache(local_dois, cache_data)
    local did_update = false

    local querymethods = {
        { name = 'crossref', func = getMetadataFromCrossref },
        { name = 'arxiv',    func = getMetaDataFromArxiv }
    }

    for _, doi in ipairs(local_dois) do
        if not cache_data[doi] then
            print(string.format("'%s' not in cache.", doi))
            for _, query in ipairs(querymethods) do
                print('Trying ' .. query.name .. '...')
                local data, msg = query.func(doi)
                if data then
                    print("Success!")
                    cache_data[doi] = data
                    did_update = true
                    break
                else
                    print("Failed : " .. msg)
                end
            end
        end
    end

    local inv_local_dois = getInverseTable(local_dois)
    for doi, _ in pairs(cache_data) do
        if not inv_local_dois[doi] then
            print(string.format("'%s' in cache but not in local. Removing...", doi))
            cache_data[doi] = nil
            did_update = true
        end
    end

    return did_update
end

if ... then
    return {
        readCache = readCache,
        writeCache = writeCache,
        getLocalDOIs = getLocalDOIs,
        updateCache = updateCache,
    }
else
    print("Running as a standalone script...")
    local paperdb_dir = '/mnt/Data/Papers/DB/'
    local cache_path = '/mnt/Data/Papers/cache.json'

    local local_dois = getLocalDOIs(paperdb_dir)
    -- Inverse table of local_dois
    local cache_data = readCache(cache_path)

    if updateCache(local_dois, cache_data) then
        print('Updating cache...')
        writeCache(cache_path, cache_data)
        print("Done!")
    else
        print "Nothing to update!"
    end
end
