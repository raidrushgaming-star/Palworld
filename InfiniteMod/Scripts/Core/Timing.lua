local Utils = require("Core.Utils")

local Timing = {}

local os_clock = Utils.os_clock
local tonumber = Utils.tonumber

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
        local k = Utils.tostring(key)
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
