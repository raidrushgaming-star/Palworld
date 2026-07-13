local Utils = require("Core.Utils")

local Timing = {}

local os_clock = Utils.os_clock
local ToString = Utils.tostring
local tonumber = Utils.tonumber
local ExecuteWithDelay = Utils.ExecuteWithDelay
local table_unpack = Utils.unpack

function Timing.Throttle(fn, intervalMs)
    local lastExec = 0
    local interval = (tonumber(intervalMs) or 0) / 1000
    return function(...)
        local now = os_clock()
        if now - lastExec < interval then
            return
        end
        lastExec = now
        return fn(...)
    end
end

function Timing.ThrottleByKey(fn, intervalMs)
    local lastExec = {}
    local interval = (tonumber(intervalMs) or 0) / 1000
    return function(key, ...)
        local now = os_clock()
        local k = ToString(key)
        if lastExec[k] and now - lastExec[k] < interval then
            return
        end
        lastExec[k] = now
        return fn(key, ...)
    end
end

function Timing.Debounce(fn, delayMs)
    local lastCall = 0
    local timeout = nil
    local delay = (tonumber(delayMs) or 0) / 1000
    return function(...)
        local args = { ... }
        local now = os_clock()
        lastCall = now
        if timeout == nil then
            timeout = ExecuteWithDelay(delayMs, function()
                if os_clock() - lastCall >= delay then
                    fn(table_unpack(args))
                    timeout = nil
                end
            end)
        end
    end
end

function Timing.CreateChecker(intervalMs)
    local lastTime = 0
    local interval = (tonumber(intervalMs) or 0) / 1000
    return function()
        local now = os_clock()
        if now - lastTime < interval then
            return false
        end
        lastTime = now
        return true
    end
end

function Timing.CreateKeyedChecker(intervalMs)
    local lastTimes = {}
    local interval = (tonumber(intervalMs) or 0) / 1000
    return function(key)
        local now = os_clock()
        local k = ToString(key)
        if lastTimes[k] and now - lastTimes[k] < interval then
            return false
        end
        lastTimes[k] = now
        return true
    end
end

Timing.NOTIFY_DEBOUNCE = 100
Timing.KEY_DEBOUNCE = 200
Timing.HOOK_DEBOUNCE = 200
Timing.HOOK_SLOW = 1000
Timing.HOOK_VERY_SLOW = 1500
Timing.DELAY_SHORT = 500
Timing.DELAY_MEDIUM = 1500
Timing.DELAY_STANDARD = 2000
Timing.DELAY_LONG = 3000
Timing.CACHE_CLEANUP_INTERVAL = 300000
Timing.MAX_FINDALL_SMALL = 500
Timing.MAX_FINDALL_STANDARD = 2000

return Timing
