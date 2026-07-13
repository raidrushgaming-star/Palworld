local Utils = require("Core.Utils")
local safeCall = Utils.safeCall
local _require = Utils.require
local pcall = Utils.pcall
local ipairs = Utils.ipairs
local type = Utils.type
local require = Utils.require

local module_file_map = { "settings", "boss", "clear", "give", "size", "travel", "upgrades", "weapons", "workers" }

for _, moduleName in ipairs(module_file_map) do
    local ok, module_or_err = pcall(_require, "Modules." .. moduleName)
    if ok and module_or_err and type(module_or_err) == "table" and type(module_or_err.Initialize) == "function" then
        local init_ok, init_err = pcall(module_or_err.Initialize)
        if not init_ok then
        end
    end
end

return true
