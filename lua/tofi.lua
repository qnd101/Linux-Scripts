-- Simple Lua library for launching tofi

local uv = require "luv"

-- Creates a tofi process and returns a callback to the output
local function spawnTofi(content, width, height, prompt, args)
    -- Parse arguments
    args = args or {}
    for arg1, arg2 in pairs {
        ['--width'] = width,
        ['--height'] = height,
        ['--prompt'] = prompt
    } do
        if arg2 then
            table.insert(args, arg1)
            table.insert(args, tostring(arg2))
        end
    end

    -- Parse content (only string or table accepted!)
    local content_type = type(content)
    assert(content_type == 'string' or content_type == 'table')
    if content_type == 'table' then
        content = table.concat(content, '\n')
    end

    -- Create a process
    local pipe_in = uv.new_pipe(false)
    local stdout = uv.new_pipe(false)
    local options = {
        stdio = { pipe_in, stdout },
        args = args,
    }

    -- Start process
    local info = { output = '' }
    info.handle, info.pid = uv.spawn('tofi', options, function(code, signal)
        info.code = code
        uv.close(stdout)
    end)

    -- Write to stdin and close pipe
    pipe_in:write(content)
    uv.close(pipe_in)

    uv.read_start(stdout, function(err, chunk)
        assert(not err, err)
        if chunk then info.output = info.output .. chunk end
    end)

    return function() return info end
end

return {
    spawnTofi = spawnTofi
}
