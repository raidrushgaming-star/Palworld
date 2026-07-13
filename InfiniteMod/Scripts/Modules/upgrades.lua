local Hooks = require("Core.Hooks")
local Utils = require("Core.Utils")

local UpgradesModule = {}

local ipairs = Utils.ipairs
local HooksRegisterSimple = Hooks.RegisterSimple
local safeCall = Utils.safeCall
local isValidUObject = Utils.isValidUObject
local GarbageCollect = Utils.CollectGarbage
local ExecuteWithDelay = Utils.ExecuteWithDelay
local ModifyDataTable = Utils.ModifyDataTable
local runOnGameThread = Utils.runOnGameThread
local StaticFindObject = Utils.StaticFindObject
local hooked = false
local patchedObjects, cleanupCache = Utils.createCacheCleanup(Utils.CACHE_CLEANUP_INTERVAL)
local initialized = false
local patchedTables = {}
local canProcessHook = Utils.CreateChecker(1500)
local TABLE_MONSTER = "/Game/Pal/DataTable/Character/DT_PalMonsterParameter.DT_PalMonsterParameter"
local UPGRADES_PATH = "/Script/Pal.PalCharacterParameterComponent:OnInitializedCharacter"
local PAL_UTILITY_PATH = "/Script/Pal.Default__PalUtility"

local function ConditionalModifier(currentValue)
    if currentValue and currentValue > 0 then
        return 10
    end
    return currentValue
end

local MONSTER_MODIFICATIONS = {
    WorkSuitability_EmitFlame = ConditionalModifier,
    WorkSuitability_Watering = ConditionalModifier,
    WorkSuitability_Seeding = ConditionalModifier,
    WorkSuitability_GenerateElectricity = ConditionalModifier,
    WorkSuitability_Handcraft = ConditionalModifier,
    WorkSuitability_Collection = ConditionalModifier,
    WorkSuitability_Deforest = ConditionalModifier,
    WorkSuitability_Mining = ConditionalModifier,
    WorkSuitability_ProductMedicine = ConditionalModifier,
    WorkSuitability_Cool = ConditionalModifier,
    WorkSuitability_Transport = ConditionalModifier,
    WorkSuitability_MonsterFarm = ConditionalModifier,
}

local function ApplyMods()
    runOnGameThread(function()
        safeCall(function()
            ModifyDataTable(TABLE_MONSTER, MONSTER_MODIFICATIONS, {
                cache = patchedTables,
            })
        end)
        GarbageCollect()
    end)
end

function UpgradesModule.Initialize()
    if hooked then
        return true
    end
    local ok = safeCall(function()
        HooksRegisterSimple(UPGRADES_PATH, "Upgrades", function(self, palCharacter)
            local t = safeCall(function()
                return self and self:get()
            end)
            local s = safeCall(function()
                return t and t.IndividualParameter and t.IndividualParameter.SaveParameter
            end)
            if not s then
                return
            end

            local PalUtil = safeCall(function()
                return StaticFindObject(PAL_UTILITY_PATH)
            end)
            if not PalUtil or not isValidUObject(PalUtil) then
                return
            end
            if not safeCall(function()
                return PalUtil:IsBaseCampPal(t)
            end) then
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
        end)
        return true
    end)

    if not initialized then
        safeCall(function()
            Hooks.OnClientRestart("Workers", 2000, function()
                if not canProcessHook() then
                    return
                end
                patchedTables = {}
                ApplyMods()
            end)
            ExecuteWithDelay(3000, ApplyMods)
        end)
        initialized = true
    end

    if ok then
        hooked = true
    end
    return true
end

return UpgradesModule
