local function string_distance(s, t)
    if s == t then return 0 end
    if #s == 0 then return #t end
    if #t == 0 then return #s end

    local v0 = {}
    local v1 = {}

    for i = 0, #t do v0[i + 1] = i end

    for i = 0, #s - 1 do
        v1[1] = i + 1
        for j = 0, #t - 1 do
            local cost = (s:sub(i + 1, i + 1) == t:sub(j + 1, j + 1)) and 0 or 1
            v1[j + 2] = math.min(v1[j + 1] + 1, v0[j + 2] + 1, v0[j + 1] + cost)
        end
        for j = 0, #t do v0[j + 1] = v1[j + 1] end
    end

    return v1[#t + 1]
end

local function fuzzy_index(input_key, dict)
    local min_score = 10000
    local best_key = nil

    for key, _ in pairs(dict) do
        -- Calculate the edit distance between the input and the current table key
        local score = string_distance(input_key, key)
        -- If this key is closer than our previous best, update it
        if score < min_score then
            min_score = score
            best_key = key
        end
        -- Optimization: If we found an exact byte match (0), we can stop early
        if min_score == 0 then break end
    end
    -- Return the value associated with the best matching key
    if best_key then
        return dict[best_key]
    end
    return nil
end

return {
    string_distance = string_distance,
    fuzzy_index = fuzzy_index
}
