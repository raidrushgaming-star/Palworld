local Utils = require("Core.Utils")

local BossModule = {}

local GarbageCollect = Utils.CollectGarbage
local FindAllOf = Utils.FindAllOf
local FindFirstOf = Utils.FindFirstOf
local ipairs = Utils.ipairs
local safeCall = Utils.safeCall
local isValidUObject = Utils.isValidUObject
local ExecuteWithDelay = Utils.ExecuteWithDelay
local Key = Utils.Key
local pcall = Utils.pcall
local rawget = Utils.rawget
local NPC_SPAWNER_CLASS = "PalNPCSpawnerBase"
local PLAYER_CLASS = "PalPlayerCharacter"
local canToggle = Utils.CreateChecker(Utils.KEY_DEBOUNCE)
local keybindRegistered = false

function BossModule.Keybind()
    if not canToggle() then
        return
    end
    local spawners = safeCall(function()
        return FindAllOf(NPC_SPAWNER_CLASS)
    end)
    if spawners then
        for _, s in ipairs(spawners) do
            if s and isValidUObject(s) then
                if s.RequestDeleteGroup then
                    safeCall(function()
                        s:RequestDeleteGroup()
                    end)
                end
                if s.SetIgnoreRandomizer then
                    safeCall(function()
                        s:SetIgnoreRandomizer(false)
                    end)
                end
                if s.SpawnRequest_ByOutside then
                    safeCall(function()
                        s:SpawnRequest_ByOutside(true)
                    end)
                end
            end
        end
    end
    GarbageCollect()
end

function BossModule.ClearStatusEffects()
    if not canToggle() then
        return
    end
    local player = safeCall(function()
        return FindFirstOf(PLAYER_CLASS)
    end)
    if not player or not isValidUObject(player) then
        return
    end
    local statusComp = safeCall(function()
        return player.StatusComponent
    end)
    if not statusComp or not isValidUObject(statusComp) then
        return
    end
    safeCall(function()
        statusComp:RemoveAll()
    end)
end

local function registerKeybind()
    if keybindRegistered then
        return true
    end
    local engineRegister = rawget(_G, "RegisterKeyBind")
    if not engineRegister then
        return false
    end
    local ok = pcall(function()
        engineRegister(Key.F2, function()
            BossModule.Keybind()
        end)
        engineRegister(Key.F3, function()
            BossModule.ClearStatusEffects()
        end)
    end)
    if ok then
        keybindRegistered = true
    end
    return ok
end

function BossModule.Initialize()
    local registered = registerKeybind()
    if not registered then
        ExecuteWithDelay(1000, registerKeybind)
    end
    return true
end

return BossModule
