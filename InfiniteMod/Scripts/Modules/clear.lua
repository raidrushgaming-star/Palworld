local Timing = require("Core.Timing")
local Utils = require("Core.Utils")

local ClearModule = {}

local FindFirstOf = Utils.FindFirstOf
local safeCall = Utils.safeCall
local isValidUObject = Utils.isValidUObject
local ExecuteWithDelay = Utils.ExecuteWithDelay
local Key = Utils.Key
local pcall = Utils.pcall
local rawget = Utils.rawget
local PLAYER_CLASS = "PalPlayerCharacter"
local canToggle = Timing.CreateChecker(Timing.KEY_DEBOUNCE)
local keybindRegistered = false

function ClearModule.Keybind()
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
        engineRegister(Key.F3, function()
            ClearModule.Keybind()
        end)
    end)
    if ok then
        keybindRegistered = true
    end
    return ok
end

function ClearModule.Initialize()
    local registered = registerKeybind()
    if not registered then
        ExecuteWithDelay(1000, registerKeybind)
    end
    return true
end

return ClearModule
