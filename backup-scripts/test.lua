#!/bin/env luajit
-- Simple script maintaining a cache for backup

-- Policy for cleanup
local hour = 3600
local day = 24 * hour
local cleanup_policy = {
    3 * hour,
    3 * hour,
    3 * hour,
    6 * hour,
    12 * hour,
    day,
    2 * day,
    2 * day + 12 * hour,
    3 * day,
    3 * day + 12 * hour,
    7 * day,
    10 * day,
    14 * day,
    30 * day,
    60 * day,
    90 * day,
    365 * day
}
-- Function for parsing time strings
local function parseTimestamp(input)
    -- 1. Extract parts using Lua patterns
    -- Pattern: %d+ matches digits, %a matches letters (T), %z matches offset
    local pattern = "(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)%.(%d+)([%+%-]%d+:%d+)"
    local y, m, d, hh, mm, ss, nano, offset = input:match(pattern)
    -- 2. Convert core components to a Lua timestamp table
    local ts_table = {
        year  = tonumber(y),
        month = tonumber(m),
        day   = tonumber(d),
        hour  = tonumber(hh),
        min   = tonumber(mm),
        sec   = tonumber(ss)
    }
    -- 3. Get the Unix Timestamp (UTC/Local depending on environment)
    return os.time(ts_table)
end
-- print(parseTimestamp('2026-02-28T16:25:57.531080359+09:00'))

local json = require "cjson"
-- Get the password for repo
local snapshot_data_path = os.getenv("HOME") .. '/backup-snapshots.json'
local snapshot_data_handle = assert(io.open(snapshot_data_path), "ERR: Cannot find snapshot info: " .. snapshot_data_path)
local json_raw = snapshot_data_handle:read("*a")
snapshot_data_handle:close()

-- Get the snapshot data
local snapshot_data = json.decode(json_raw)

-- Parse time info to get duration, then sort in ascending order
local now = os.time()
for i = 1, #snapshot_data do
    snapshot_data[i].duration = now - parseTimestamp(snapshot_data[i].time)
end
table.sort(snapshot_data, function(a, b) return a.duration < b.duration end)

-- Selected snapshots
local selected = {}
for _, max_dur in ipairs(cleanup_policy) do
    local sel = nil
    for idx, data in ipairs(snapshot_data) do
        if not selected[idx] and data.duration < max_dur then
            sel = idx;
        end
    end
    if sel then selected[sel] = true end
end
-- Print snapshots to delete
for idx, data in ipairs(snapshot_data) do
    if not selected[idx] then
        print(data.id)
    end
end
