local Hooks = require("Core.Hooks")
local Utils = require("Core.Utils")

local SizeModule = {}

local PAL_UTILITY_PATH = "/Script/Pal.Default__PalUtility"
local StaticFindObject = Utils.StaticFindObject
local ExecuteWithDelay = Utils.ExecuteWithDelay
local nowMs = Utils.nowMs
local pairs = Utils.pairs
local isValidUObject = Utils.isValidUObject
local SHRUNK_TTL_MS = 10 * 60 * 1000
local lastCacheCleanup = 0
local SHRUNK_CACHE_CLEANUP_INTERVAL = 5 * 60 * 1000
local shrunkChars = {}
local safeCall = Utils.safeCall
local INIT_DELAY_MS = 4000
local PalUtility = nil
local tostring = Utils.tostring

local SCALE = {
    X = 0.5,
    Y = 0.5,
    Z = 0.5,
}

function SizeModule.Initialize()
    local function cleanupShrunkCache()
        local currentTime = nowMs()
        if currentTime - lastCacheCleanup > SHRUNK_CACHE_CLEANUP_INTERVAL then
            for k, v in pairs(shrunkChars) do
                if v and (currentTime - v) >= SHRUNK_TTL_MS then
                    shrunkChars[k] = nil
                end
            end
            lastCacheCleanup = currentTime
        end
    end
    local function GetPalUtility()
        if PalUtility == nil or not isValidUObject(PalUtility) then
            PalUtility = safeCall(function()
                return StaticFindObject(PAL_UTILITY_PATH)
            end)
        end
        return PalUtility
    end
    local function scaledVector3(currentScale)
        return {
            X = currentScale.X * SCALE.X,
            Y = currentScale.Y * SCALE.Y,
            Z = currentScale.Z * SCALE.Z,
        }
    end
    ExecuteWithDelay(INIT_DELAY_MS, function()
        Hooks.RegisterSimple(
            "/Script/Pal.PalCharacterParameterComponent:OnInitialize_AfterSetIndividualParameter",
            "Size",
            function(_, CharacterRef)
                local character = safeCall(function()
                    return CharacterRef and CharacterRef:get()
                end)
                if not character then
                    return
                end
                local key = safeCall(function()
                    return character and character:GetAddress()
                end) or tostring(character)
                if shrunkChars[key] then
                    return
                end
                local PalUtil = GetPalUtility()
                if not isValidUObject(PalUtil) then
                    return
                end
                if
                    not safeCall(function()
                        return PalUtil:IsBaseCampPal(character)
                    end)
                then
                    return
                end
                local origin, boxExtent = {}, {}
                local ok = safeCall(function()
                    character:GetActorBounds(false, origin, boxExtent, true)
                    return true
                end)
                if not ok then
                    return
                end
                local currentScale = safeCall(function()
                    return character:GetActorScale3D()
                end)
                if not currentScale or not currentScale.X then
                    return
                end
                local newScale = scaledVector3(currentScale)
                safeCall(function()
                    character:SetActorScale3D(newScale)
                end)
                shrunkChars[key] = nowMs()
                cleanupShrunkCache()
            end
        )
    end)
    return true
end

return SizeModule
