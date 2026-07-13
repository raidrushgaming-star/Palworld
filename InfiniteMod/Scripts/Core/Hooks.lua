local Utils = require("Core.Utils")

local Hooks = {}

local require = Utils.require
local pcall = Utils.pcall
local ipairs = Utils.ipairs
local table_insert = Utils.table_insert
local ExecuteWithDelay = Utils.ExecuteWithDelay
local RegisterHook = Utils.RegisterHook
local NotifyOnNewObject = Utils.NotifyOnNewObject
local LoadAsset = Utils.LoadAsset
local runOnGameThread = Utils.runOnGameThread

local function isBlueprintPath(path)
    return path and path:sub(1, 6) == "/Game/"
end

local function loadBlueprintAsset(path)
    if not isBlueprintPath(path) then
        return true
    end
    if not LoadAsset then
        return true
    end
    local classPath = path:match("^([^:]+)")
    if not classPath then
        return true
    end
    local ok, err = pcall(function()
        LoadAsset(classPath)
    end)
    return ok
end

local registeredHooks = {}
local registeredNotifies = {}

local function isFeatureEnabled(featureName)
    return true
end

local CLIENT_RESTART_PATH = "/Script/Engine.PlayerController:ClientRestart"
local clientRestartHandlers = {}
local clientRestartHookRegistered = false

local function dispatchClientRestart(Context, NewPawn)
    for _, handler in ipairs(clientRestartHandlers) do
        if isFeatureEnabled(handler.featureName) then
            local callback = handler.callback
            local delayMs = handler.delayMs
            if delayMs > 0 then
                if handler.useParams then
                    local ctx, pawn = Context, NewPawn
                    ExecuteWithDelay(delayMs, function()
                        Utils.safeCall(function()
                            return callback(ctx, pawn)
                        end)
                    end)
                else
                    ExecuteWithDelay(delayMs, function()
                        Utils.safeCall(function()
                            return callback()
                        end)
                    end)
                end
            else
                local ok, err
                if handler.useParams then
                    Utils.safeCall(function()
                        return callback(Context, NewPawn)
                    end)
                else
                    Utils.safeCall(function()
                        return callback()
                    end)
                end
            end
        end
    end
end

local function ensureClientRestartHook()
    if clientRestartHookRegistered then
        return true
    end
    local ok, err = pcall(function()
        RegisterHook(CLIENT_RESTART_PATH, dispatchClientRestart)
    end)
    if ok then
        clientRestartHookRegistered = true
    end
    return ok
end

function Hooks.Register(path, featureName, preCallback, postCallback)
    if not path or not featureName then
        return false
    end
    local isScriptPath = path:sub(1, 8) == "/Script/"
    if not isScriptPath then
        loadBlueprintAsset(path)
    end
    local wrapCallback = function(callback)
        if not callback then
            return nil
        end
        return function(...)
            if not isFeatureEnabled(featureName) then
                return
            end
            local ok, r1, r2, r3, r4 = pcall(callback, ...)
            if not ok then
                return
            end
            return r1, r2, r3, r4
        end
    end
    local preId, postId
    local ok, err
    if isScriptPath then
        local wrappedPre = wrapCallback(preCallback) or function() end
        local wrappedPost = wrapCallback(postCallback)
        ok, err = pcall(function()
            if wrappedPost then
                preId, postId = RegisterHook(path, wrappedPre, wrappedPost)
            else
                preId, postId = RegisterHook(path, wrappedPre)
            end
        end)
    else
        local callback = postCallback or preCallback
        local wrappedCallback = wrapCallback(callback)
        if not wrappedCallback then
            return false
        end
        ok, err = pcall(function()
            preId, postId = RegisterHook(path, wrappedCallback)
        end)
    end
    if not ok or not preId then
        return false
    end
    if not registeredHooks[featureName] then
        registeredHooks[featureName] = {}
    end
    table_insert(registeredHooks[featureName], {
        path = path,
        preId = preId,
        postId = postId or 0,
    })
    return true
end

function Hooks.RegisterSimple(path, featureName, callback)
    return Hooks.Register(path, featureName, nil, callback)
end

function Hooks.RegisterBlueprint(path, featureName, callback)
    if not path or not featureName or not callback then
        return false
    end
    if not isBlueprintPath(path) then
        return Hooks.RegisterSimple(path, featureName, callback)
    end
    runOnGameThread(function()
        loadBlueprintAsset(path)
        Hooks.RegisterSimple(path, featureName, callback)
    end)
    return true
end

function Hooks.OnClientRestart(featureName, delayMs, callback, useParams)
    if not featureName or not callback then
        return false
    end
    if not ensureClientRestartHook() then
        return false
    end
    table_insert(clientRestartHandlers, {
        featureName = featureName,
        delayMs = delayMs or 0,
        callback = callback,
        useParams = useParams or false,
    })
    return true
end

function Hooks.Notify(className, featureName, callback)
    if not className or not featureName or not callback then
        return false
    end
    local wrappedCallback = function(obj)
        if not isFeatureEnabled(featureName) then
            return
        end
        Utils.safeCall(function()
            return callback(obj)
        end)
    end
    local ok, err = pcall(function()
        NotifyOnNewObject(className, wrappedCallback)
    end)
    if not ok then
        return false
    end
    if not registeredNotifies[featureName] then
        registeredNotifies[featureName] = {}
    end
    table_insert(registeredNotifies[featureName], {
        path = className,
    })
    return true
end

local dispatcherHandlers = {
    PalGameSetting = {},
}

local dispatcherRegistered = {
    PalGameSetting = false,
}

local function dispatchEvent(handlerType, obj)
    local handlerList = dispatcherHandlers[handlerType]
    if not handlerList then
        return
    end
    for _, handler in ipairs(handlerList) do
        pcall(function()
            handler.callback(obj)
        end)
    end
end

function Hooks.OnPalGameSetting(moduleName, callback)
    table_insert(dispatcherHandlers.PalGameSetting, {
        name = moduleName,
        callback = callback,
    })
    if not dispatcherRegistered.PalGameSetting then
        Hooks.Notify("/Script/Pal.PalGameSetting", "Dispatcher", function(obj)
            dispatchEvent("PalGameSetting", obj)
        end)
        dispatcherRegistered.PalGameSetting = true
    end
end

function Hooks.GetDispatcherStats()
    return {
        PalGameSetting = #dispatcherHandlers.PalGameSetting,
    }
end

return Hooks
