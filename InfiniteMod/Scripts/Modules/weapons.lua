local Hooks = require("Core.Hooks")
local Utils = require("Core.Utils")

local WeaponsModule = {}

local safeCall = Utils.safeCall
local isValidUObject = Utils.isValidUObject
local isSafeInstance = Utils.isSafeInstance
local HooksNotify = Hooks.Notify
local hooked = false
local patchedWeapons, cleanupCache = Utils.createCacheCleanup(Utils.CACHE_CLEANUP_INTERVAL)

local function applyWeaponSettings(w)
    if not isValidUObject(w) or not isSafeInstance(w) then
        return
    end
    local address = safeCall(function()
        return w:GetAddress()
    end)
    if not address then
        return
    end
    if patchedWeapons[address] then
        return
    end
    local function safeSet(field, value)
        safeCall(function()
            w[field] = value
        end)
    end
    safeSet("CoolDownTime", 0.1)
    patchedWeapons[address] = true
    cleanupCache()
end

function WeaponsModule.Initialize()
    if hooked then
        return true
    end
    local ok = safeCall(function()
        HooksNotify("/Script/Pal.PalWeaponBase", "Weapons", applyWeaponSettings)
        return true
    end)
    if ok then
        hooked = true
    end
    return true
end

return WeaponsModule
