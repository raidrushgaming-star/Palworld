local Hooks = require("Core.Hooks")
local Utils = require("Core.Utils")

local TravelModule = {}

local ExecuteWithDelay = Utils.ExecuteWithDelay
local ExecuteAsync = Utils.ExecuteAsync
local StaticFindObject = Utils.StaticFindObject
local FindAllOf = Utils.FindAllOf
local isValidUObject = Utils.isValidUObject
local safeCall = Utils.safeCall
local HooksRegisterBlueprint = Hooks.RegisterBlueprint
local HooksOnClientRestart = Hooks.OnClientRestart
local HOOK_MAP_SETUP = "/Game/Pal/Blueprint/UI/UserInterface/Map/WBP_Map_Base.WBP_Map_Base_C:OnSetup"
local HOOK_SERVER_ACK = "/Script/Engine.PlayerController:ServerAcknowledgePossession"
local PalUtilityDefault = nil
local hooked = false
local hooksInitialized = false

local function GetPalUtility()
    if PalUtilityDefault == nil then
        PalUtilityDefault = safeCall(function()
            return StaticFindObject("/Script/Pal.Default__PalUtility")
        end)
    end
    if not PalUtilityDefault or not isValidUObject(PalUtilityDefault) then
        return nil
    end
    return PalUtilityDefault
end

local function onMapSetup(Context)
    local ui = safeCall(function()
        return Context and Context:get()
    end)
    if ui and ui.SetPropertyValue then
        safeCall(function()
            ui:SetPropertyValue("Can Fast Travel", true)
        end)
    end
end

local function UnlockFastTravelPoints()
    local points = safeCall(function()
        return FindAllOf("PalLocationPointFastTravel") or {}
    end)
    if points and #points > 0 then
        for _, point in ipairs(points) do
            safeCall(function()
                if point and point.ShouldUnlockFlag ~= nil then
                    point.ShouldUnlockFlag = false
                end
            end)
        end
        return
    end
    ExecuteWithDelay(4000, UnlockFastTravelPoints)
end

local function DoHooks()
    if hooked then
        return
    end
    local ok = safeCall(function()
        HooksRegisterBlueprint(HOOK_MAP_SETUP, "Travel", onMapSetup)
        return true
    end)
    if ok then
        hooked = true
    end
end

local function onClientRestart(Context, NewPawn)
    if not hooked then
        DoHooks()
    end
end

local function onServerAcknowledge(Context, NewPawn)
    local PalUtility = GetPalUtility()
    if PalUtility and isValidUObject(PalUtility) then
        if not hooked then
            DoHooks()
        end
    end
end

function TravelModule.Initialize()
    if hooksInitialized then
        return true
    end
    safeCall(function()
        HooksOnClientRestart("Travel", 0, onClientRestart, true)
        Hooks.RegisterSimple(HOOK_SERVER_ACK, "Travel", onServerAcknowledge)
    end)
    hooksInitialized = true
    ExecuteAsync(function()
        ExecuteWithDelay(2000, UnlockFastTravelPoints)
    end)
    return true
end

safeCall(function()
    TravelModule.Initialize()
end)

return TravelModule
