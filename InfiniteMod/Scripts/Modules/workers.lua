local Timing = require("Core.Timing")
local Hooks = require("Core.Hooks")
local Utils = require("Core.Utils")

local WorkersModule = {}

local GarbageCollect = Utils.CollectGarbage
local ExecuteWithDelay = Utils.ExecuteWithDelay
local ModifyDataTable = Utils.ModifyDataTable
local safeCall = Utils.safeCall
local runOnGameThread = Utils.runOnGameThread
local initialized = false
local patchedTables = {}
local canProcessHook = Timing.CreateChecker(1500)
local TABLE_MONSTER = "/Game/Pal/DataTable/Character/DT_PalMonsterParameter.DT_PalMonsterParameter"

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

function WorkersModule.Initialize()
    if initialized then
        return true
    end
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
    return true
end

return WorkersModule
