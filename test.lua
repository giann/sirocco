package.path = package.path .. ";src/?.lua;lib/tui/?/init.lua;lib/tui/?.lua"

local Prompt   = require "prompt"
local List     = require "list"
local Password = require "password"
local colors   = require "term".colors

Prompt {
    prompt      = "A simple question\n❱ ",
    placeholder = "A simple answer",
    required    = true
}:loop()

Prompt {
    prompt  = "Another question\n❱ ",
    default = "With a default answer",
}:loop()

Prompt {
    prompt         = "What programming languages do you know ?\n❱ ",
    placeholder    = "Try tab to get some suggestions...",
    possibleValues = {
        "lua",
        "c",
        "javascript",
        "php",
        "python",
        "rust",
        "go"
    }
}:loop()

List {
    prompt   = "How do you say 'Hello'?",
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
}:loop()

List {
    prompt   = "Here's a list with some already selected options:",
    default  = { 2, 4 },
    required = true,
    items    = {
        {
            value = "First",
            label = "First"
        },
        {
            value = "Second",
            label = "Second"
        },
        {
            value = "Third",
            label = "Third"
        },
        {
            value = "Fourth",
            label = "Fourth"
        },
    },
}:loop()

List {
    prompt   = "Where are you from?",
    multiple = false,
    items    = {
        {
            value = "New York",
            label = "New York"
        },
        {
            value = "Paris",
            label = "Paris"
        },
        {
            value = "Rome",
            label = "Rome"
        }
    },
}:loop()

Password {
    prompt = "Enter your secret\n❱ ",
}:loop()

Password {
    prompt = "Enter your secret (hidden answer)\n❱ ",
    hidden = true
}:loop()

Prompt {
    prompt      = "What's your birthday?\n❱ ",
    placeholder = "YYYY-mm-dd",
    validator   = function(buffer)
        if utf8.len(buffer) > 0 then
            local matches = { buffer:match("([1-9][0-9][0-9][0-9])%-([0-1][0-9])%-([0-3][0-9])") }

            if matches[1] == nil
                or tonumber(matches[2]) > 12
                or tonumber(matches[3]) > 31 then
                return colors.yellow .. "Not a valid date!" .. colors.reset
            end
        end
    end
}:loop()
