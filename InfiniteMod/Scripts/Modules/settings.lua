local Hooks = require("Core.Hooks")
local Utils = require("Core.Utils")

local SettingsModule = {}

local ExecuteAsync = Utils.ExecuteAsync
local ExecuteWithDelay = Utils.ExecuteWithDelay
local pairs = Utils.pairs
local ipairs = Utils.ipairs
local FindAllOf = Utils.FindAllOf
local StaticFindObject = Utils.StaticFindObject
local MAX_FINDALL_RESULTS = Utils.MAX_FINDALL_STANDARD
local safeCall = Utils.safeCall
local tostring = Utils.tostring
local isValidUObject = Utils.isValidUObject
local GAMESETTING_BP = "/Game/Pal/Blueprint/System/BP_PalGameSetting.Default__BP_PalGameSetting_C"
local GAMESETTING_SCRIPT = "/Script/Pal.Default__PalGameSetting"
local GAMESETTING_CLASS_NAMES = { "PalGameSetting", "UPalGameSetting", "BP_PalGameSetting_C" }
local GAMESETTING_PATHS = {
    GAMESETTING_BP,
    GAMESETTING_SCRIPT,
    "/Script/Pal.Default__PalGameSetting",
    "/Script/Pal.PalGameSetting",
}
local HOOK_SERVER_ACK = "/Script/Engine.PlayerController:ServerAcknowledgePossession"
local PAL_UTILITY_PATH = "/Script/Pal.Default__PalUtility"
local patchedObjects, cleanupCache = Utils.createCacheCleanup(Utils.CACHE_CLEANUP_INTERVAL)
local palUtilityDefault = nil

local SETTINGS_PRESETS = {
    BaseCampWorkerEventTriggerProbability = 0,
    PalBoxPageNum = 100,
    worldmapUIMaskClearSize = 2000,
    CharacterMaxLevel = 100,
    GuildCharacterMaxLevel = 100,
    MaxUseablePoint_SumStatusPointAndExStatusPoint_PerParameter = 100,
}

local cachedSettings = nil

local function getSettings()
    if cachedSettings then
        return cachedSettings
    end
    local settings = {}
    for k, v in pairs(SETTINGS_PRESETS) do
        settings[k] = v
    end
    cachedSettings = settings
    return settings
end

local function applyToObject(obj)
    if not isValidUObject(obj) then
        return
    end
    local key = safeCall(function()
        return obj:GetAddress()
    end) or tostring(obj)
    if patchedObjects[key] then
        return
    end
    safeCall(function()
        local settings = getSettings()
        local modified = 0
        for k, v in pairs(settings) do
            local cur = safeCall(function()
                return obj[k]
            end)
            if cur ~= v then
                safeCall(function()
                    obj[k] = v
                end)
                modified = modified + 1
            end
        end
        if modified > 0 then
            patchedObjects[key] = true
        end
    end)
    cleanupCache()
end

local function collectGameSettingObjects()
    local results = {}
    local seen = {}
    local function add(obj)
        if not isValidUObject(obj) then
            return
        end
        local key = safeCall(function()
            return obj:GetAddress()
        end) or tostring(obj)
        if seen[key] then
            return
        end
        seen[key] = true
        results[#results + 1] = obj
    end

    for _, path in ipairs(GAMESETTING_PATHS) do
        local obj = safeCall(function()
            return StaticFindObject(path)
        end)
        add(obj)
    end

    for _, className in ipairs(GAMESETTING_CLASS_NAMES) do
        local objs = safeCall(function()
            return FindAllOf(className)
        end)
        if objs then
            for _, obj in ipairs(objs) do
                add(obj)
            end
        end
    end

    return results
end

local function getPalUtility()
    if palUtilityDefault == nil then
        palUtilityDefault = safeCall(function()
            return StaticFindObject(PAL_UTILITY_PATH)
        end)
    end
    if not palUtilityDefault or not isValidUObject(palUtilityDefault) then
        return nil
    end
    return palUtilityDefault
end

local function applyToActiveGameSetting(worldContextObject)
    local utility = getPalUtility()
    if not utility or not isValidUObject(utility) then
        return
    end
    local settings = safeCall(function()
        return utility:GetGameSetting(worldContextObject)
    end)
    if not isValidUObject(settings) then
        return
    end
    applyToObject(settings)
end

function SettingsModule.Apply(obj)
    applyToObject(obj)
end

function SettingsModule.GetSettings()
    return getSettings()
end

function SettingsModule.Initialize()
    local function applyAllSettings()
        local objs = collectGameSettingObjects()
        local processed = 0
        for _, o in ipairs(objs) do
            if processed >= MAX_FINDALL_RESULTS then
                break
            end
            applyToObject(o)
            processed = processed + 1
        end
    end
    ExecuteWithDelay(2000, applyAllSettings)
    Hooks.OnPalGameSetting("Settings", applyToObject)
    Hooks.Notify("/Script/Pal.PalGameSetting", "Settings", applyToObject)
    Hooks.RegisterSimple(HOOK_SERVER_ACK, "Settings", function(Context)
        local ctx = safeCall(function()
            return Context and Context:get()
        end)
        local pawn = safeCall(function()
            return ctx and ctx.Pawn
        end)
        applyToActiveGameSetting(pawn or ctx)
    end)

    return true
end

return SettingsModule
