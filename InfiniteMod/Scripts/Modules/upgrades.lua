local Timing = require("Core.Timing")
local Hooks = require("Core.Hooks")
local Utils = require("Core.Utils")

local UpgradesModule = {}

local ipairs = Utils.ipairs
local HooksRegisterSimple = Hooks.RegisterSimple
local safeCall = Utils.safeCall
local isValidUObject = Utils.isValidUObject
local hooked = false
local patchedObjects, cleanupCache = Utils.createCacheCleanup(Timing.CACHE_CLEANUP_INTERVAL)

function UpgradesModule.Initialize()
    if hooked then
        return true
    end
    local ok = safeCall(function()
        HooksRegisterSimple(
            "/Script/Pal.PalCharacterParameterComponent:OnInitializedCharacter",
            "Upgrades",
            function(self, palCharacter)
                local t = safeCall(function()
                    return self and self:get()
                end)
                local s = safeCall(function()
                    return t and t.IndividualParameter and t.IndividualParameter.SaveParameter
                end)
                if not s then
                    return
                end
                local key = safeCall(function()
                    return t:GetAddress()
                end)
                if not key then
                    return
                end
                if patchedObjects[key] then
                    return
                end
                safeCall(function()
                    s.Rank = 5
                end)
                safeCall(function()
                    s.bIsAwakening = true
                end)
                safeCall(function()
                    s.FriendshipPoint = 200000
                end)
                for _, param in ipairs({ "Talent_HP", "Talent_Melee", "Talent_Shot", "Talent_Defense" }) do
                    safeCall(function()
                        s[param] = 100
                    end)
                end
                for _, param in ipairs({ "Rank_HP", "Rank_Attack", "Rank_Defence", "Rank_CraftSpeed" }) do
                    safeCall(function()
                        s[param] = 20
                    end)
                end
                patchedObjects[key] = true
                cleanupCache()
            end
        )
        return true
    end)
    if ok then
        hooked = true
    end
    return true
end

return UpgradesModule
