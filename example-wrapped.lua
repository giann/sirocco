package.path = package.path .. ";./lib/tui/?/init.lua;./lib/tui/?.lua;"

local sirocco   = require "sirocco"
local Prompt    = sirocco.prompt

-- Clear whole screen for demo
-- io.write("\27[2J\27[1;1H")

Prompt {
    prompt      = "A simple question\n❱ ",
    placeholder = "A simple answer",
}:ask()


Prompt {
    prompt      = ("A long prompt that should wrap"):rep(10) .. "\n❱ ",
    placeholder = "A simple answer",
}:ask()