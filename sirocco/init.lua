-- Hack to find tui until it has a luarocks spec
local currentPath = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]]

package.path = package.path
    .. ";" .. currentPath .. "../lib/tui/?.lua"
    .. ";" .. currentPath .. "../lib/tui/?/init.lua"

return {
    prompt   = require "sirocco.prompt",
    password = require "sirocco.password",
    confirm  = require "sirocco.confirm",
    list     = require "sirocco.list",
}
