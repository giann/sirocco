package.path = package.path .. ";src/?.lua;lib/tui/?/init.lua;lib/tui/?.lua"

local Prompt = require "prompt"
local List = require "list"

Prompt {
    prompt = "A simple question\n❱ ",
    placeholder = "A simple answer"
}:loop()

List {
    prompt = "How do you say 'Hello'?",
    items = {
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
        }
    }
}:loop()

List {
    prompt = "Where are you from?",
    items = {
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
    multiple = false
}:loop()
