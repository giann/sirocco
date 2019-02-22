package.path = package.path .. ";./lib/tui/?/init.lua;./lib/tui/?.lua;./lib/utf8_simple/?.lua"

local sirocco = require "sirocco"
local Prompt  = sirocco.prompt
local List    = sirocco.list

-- Clear whole screen for demo
-- io.write("\27[2J\27[1;1H")

List {
    prompt   = ("A long prompt that should wrap"):rep(10),
    required = true,
    items    = {
        {
            value = "Hello",
            label = "Hello"
        },
        {
            value = "Bonjour",
            label = "Bonjour"
        },
        {
            value = "Ciao",
            label = "Ciao"
        },
    },
}:ask()

Prompt {
    prompt      = ("A long prompt that should wrap"):rep(10) .. "\n❱ ",
    placeholder = "A simple answer",
    required = true
}:ask()

Prompt {
    prompt      = "A simple question\n❱ ",
    placeholder = "A simple answer",
}:ask()
