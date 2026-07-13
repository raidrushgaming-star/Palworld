local Utils = {}

Utils.pcall = pcall
Utils.pairs = pairs
Utils.ipairs = ipairs
Utils.type = type
Utils.tostring = tostring
Utils.tonumber = tonumber
Utils.unpack = unpack or table.unpack
Utils.rawget = rawget
Utils.require = require
Utils.string_find = string.find
Utils.table_insert = table.insert
Utils.os_clock = os.clock
Utils.FindAllOf = FindAllOf
Utils.FindFirstOf = FindFirstOf
Utils.StaticFindObject = StaticFindObject
Utils.RegisterHook = RegisterHook
Utils.NotifyOnNewObject = NotifyOnNewObject
Utils.ExecuteWithDelay = ExecuteWithDelay
Utils.ExecuteAsync = ExecuteAsync
Utils.LoadAsset = LoadAsset
Utils.FName = FName
Utils.Key = Key

local pcall = pcall
local FindAllOf = FindAllOf
local ExecuteWithDelay = ExecuteWithDelay
local pairs = pairs
local StaticFindObject = StaticFindObject
local type = type
local table_insert = table.insert
local ipairs = ipairs
local require = require
local rawget = rawget
local os_clock = os.clock
local G = _G
local FName = FName
local DEFAULT_MAX_ROWS = 2000
local GARBAGE_STEP_SIZE = 200
local GARBAGE_FULL_THRESHOLD = 5000
local GARBAGE_MIN_INTERVAL_MS = 10000
local _garbageRequestCount = 0
local _garbageTotalRequests = 0
local _lastGarbageCollectMs = 0

function Utils.safeCall(fn, ...)
    local ok, res = pcall(fn, ...)
    if ok then
        return res
    end
    return nil
end

function Utils.isValidUObject(obj)
    if not obj then
        return false
    end
    local ok, valid = pcall(obj.IsValid, obj)
    return ok and (valid == true)
end

function Utils.getClassName(obj)
    if not obj then
        return nil
    end
    local ok, className = pcall(function()
        local class = obj:GetClass()
        if class then
            local fname = class:GetFName()
            if fname then
                return fname:ToString()
            end
        end
        return nil
    end)
    if ok then
        return className
    end
    return nil
end

function Utils.isSafeInstance(obj)
    if not obj then
        return false
    end
    if not Utils.isValidUObject(obj) then
        return false
    end
    local okName, name = pcall(function()
        return obj:GetName()
    end)
    if okName and type(name) == "string" and name:sub(1, 8) == "Default__" then
        return false
    end
    return true
end

function Utils.getDataTableRows(dt)
    if not dt then
        return nil
    end
    local hasRowStruct = false
    pcall(function()
        local rowStruct = dt.RowStruct
        hasRowStruct = rowStruct and rowStruct:IsValid()
    end)
    if not hasRowStruct then
        return nil
    end
    local rowNames = Utils.safeCall(function()
        return dt:GetRowNames()
    end)
    if not rowNames then
        return nil
    end
    local rows = {}
    for i = 1, #rowNames do
        local name = rowNames[i]
        local row = Utils.safeCall(function()
            return dt:FindRow(name)
        end)
        if row then
            rows[name] = row
        end
    end
    return rows
end

function Utils.ModifyDataTable(tablePath, modifications, options)
    options = options or {}
    local maxRows = options.maxRows or DEFAULT_MAX_ROWS
    local cache = options.cache
    local onlyIfDifferent = options.onlyIfDifferent ~= false
    local rowFilter = options.rowFilter
    if cache and cache[tablePath] then
        return true
    end
    local dataTable = Utils.safeCall(function()
        return StaticFindObject(tablePath)
    end)
    if not Utils.isValidUObject(dataTable) then
        return false
    end
    local rowNames = Utils.safeCall(function()
        return dataTable:GetRowNames()
    end)
    if not rowNames then
        return false
    end
    local changedAny = false
    local processedCount = 0
    for i = 1, #rowNames do
        if processedCount >= maxRows then
            break
        end
        local rowName = rowNames[i]
        if rowFilter and not rowFilter(rowName) then
            processedCount = processedCount + 1
        else
            local rowData = Utils.safeCall(function()
                return dataTable:FindRow(rowName)
            end)
            if rowData then
                for key, value in pairs(modifications) do
                    local shouldSet = true
                    local current = nil

                    if onlyIfDifferent then
                        current = Utils.safeCall(function()
                            return rowData[key]
                        end)
                    end
                    local newValue = value
                    if type(value) == "function" then
                        newValue = Utils.safeCall(function()
                            return value(current)
                        end)
                    end
                    if onlyIfDifferent then
                        shouldSet = current ~= nil and current ~= newValue
                    end
                    if shouldSet then
                        local ok = pcall(function()
                            rowData[key] = newValue
                        end)
                        if ok then
                            changedAny = true
                        end
                    end
                end
            end
            processedCount = processedCount + 1
        end
    end
    if cache and changedAny then
        cache[tablePath] = true
    end
    return changedAny
end

function Utils.processAllOf(className, processor, options)
    options = options or {}
    local objs = Utils.safeCall(function()
        return FindAllOf(className)
    end)
    if not objs then
        return 0
    end
    local processed = 0
    local maxResults = options.maxResults or 2000
    local inGameThread = options.gameThread
    local validate = options.validate ~= false
    local function iterate()
        for _, obj in ipairs(objs) do
            if processed >= maxResults then
                break
            end
            if not validate or Utils.isValidUObject(obj) then
                Utils.safeCall(function()
                    processor(obj)
                end)
                processed = processed + 1
            end
        end
    end
    if inGameThread then
        Utils.runOnGameThread(iterate)
    else
        iterate()
    end
    if options.gc ~= false then
        if options.gcDelay then
            ExecuteWithDelay(options.gcDelay, function()
                Utils.runOnGameThread(Utils.CollectGarbage)
            end)
        elseif inGameThread then
            Utils.runOnGameThread(Utils.CollectGarbage)
        else
            Utils.CollectGarbage()
        end
    end
    return processed
end

function Utils.nowMs()
    return (os_clock and os_clock() or 0) * 1000
end

function Utils.CollectGarbage()
    local collectgarbage = rawget(_G, "collectgarbage")
    if not collectgarbage then
        return
    end
    local now = Utils.nowMs()
    _garbageTotalRequests = _garbageTotalRequests + 1
    _garbageRequestCount = _garbageRequestCount + 1
    collectgarbage("step", GARBAGE_STEP_SIZE)
    if _garbageRequestCount >= GARBAGE_FULL_THRESHOLD and (now - _lastGarbageCollectMs) >= GARBAGE_MIN_INTERVAL_MS then
        collectgarbage("collect")
        _lastGarbageCollectMs = now
        _garbageRequestCount = 0
    end
end

local _registeredCaches = {}
local _lastGlobalCleanup = 0
local _globalCleanupInterval = 300000
local _globalCleanupScheduled = false

local function runGlobalCacheCleanup()
    local currentTime = Utils.nowMs()
    if currentTime - _lastGlobalCleanup < _globalCleanupInterval then
        return
    end
    for i = 1, #_registeredCaches do
        local cache = _registeredCaches[i]
        if cache then
            for k in pairs(cache) do
                cache[k] = nil
            end
        end
    end
    _lastGlobalCleanup = currentTime
end

local function scheduleGlobalCleanup()
    if _globalCleanupScheduled then
        return
    end
    _globalCleanupScheduled = true
    local ExecuteWithDelay = Utils.ExecuteWithDelay
    if ExecuteWithDelay then
        local function tick()
            runGlobalCacheCleanup()
            ExecuteWithDelay(_globalCleanupInterval, tick)
        end
        ExecuteWithDelay(_globalCleanupInterval, tick)
    end
end

function Utils.createCacheCleanup(intervalMs)
    local cache = {}
    _registeredCaches[#_registeredCaches + 1] = cache
    scheduleGlobalCleanup()
    local function cleanup()
        runGlobalCacheCleanup()
    end
    return cache, cleanup
end

function Utils.runOnGameThread(fn)
    if Utils.ExecuteInGameThread then
        Utils.ExecuteInGameThread(fn)
    else
        fn()
    end
end

local tonumber = Utils.tonumber

function Utils.CreateChecker(intervalMs)
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

function Utils.CreateKeyedChecker(intervalMs)
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

Utils.NOTIFY_DEBOUNCE = 100
Utils.KEY_DEBOUNCE = 200
Utils.HOOK_DEBOUNCE = 200
Utils.HOOK_SLOW = 1000
Utils.HOOK_VERY_SLOW = 1500
Utils.DELAY_SHORT = 500
Utils.DELAY_MEDIUM = 1500
Utils.DELAY_STANDARD = 2000
Utils.DELAY_LONG = 3000
Utils.CACHE_CLEANUP_INTERVAL = 300000
Utils.MAX_FINDALL_SMALL = 500
Utils.MAX_FINDALL_STANDARD = 2000

return Utils
