package.path = package.path .. ";./lib/tui/?/init.lua;./lib/tui/?.lua;"

local sirocco   = require "sirocco"
local Prompt    = sirocco.prompt
local List      = sirocco.list
local Password  = sirocco.password
local Confirm   = sirocco.confirm
local Composite = sirocco.composite
local colors    = require "term".colors

-- Clear whole screen for demo
-- io.write("\27[2J\27[1;1H")

Prompt {
    prompt      = "A simple question\n❱ ",
    placeholder = "A simple answer",
    required    = true
}:ask()

Composite {
    prompt = "What's your birthday? ",
    separator = " / ",
    fields = {
        {
            placeholder = "YYYY",
            filter = function(input)
                return input:match("%d")
                    and input
                    or ""
            end,
            length = 4,
        },
        {
            placeholder = "mm",
            filter = function(input)
                return input:match("%d")
                    and input
                    or ""
            end,
            length = 2,
        },
        {
            placeholder = "dd",
            filter = function(input)
                return input:match("%d")
                    and input
                    or ""
            end,
            length = 2,
        },
    }
}:ask()

Prompt {
    prompt  = "Another question\n❱ ",
    default = "With a default answer",
}:ask()

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
}:ask()

Prompt {
    prompt            = "What's you education level?",
    showPossibleValues = true,
    possibleValues = {
        "highschool",
        "college",
        "doctorate"
    },
    validator = function(buffer)
        local ok = false
        for _, v in ipairs {
            "highschool",
            "college",
            "doctorate"
        } do
            if v == buffer then
                ok = true
                break
            end
        end

        return ok, not ok and colors.red .. "Not a valid answer" .. colors.reset
    end
}:ask()

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
}:ask()

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
}:ask()

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
}:ask()

Password {
    prompt = "Enter your secret\n❱ ",
}:ask()

Password {
    prompt = "Enter your secret (hidden answer)\n❱ ",
    hidden = true
}:ask()

Prompt {
    prompt      = "What's your birthday?\n❱ ",
    placeholder = "YYYY-mm-dd",
    validator   = function(buffer)
        if utf8.len(buffer) > 0 then
            local matches = { buffer:match("([1-9][0-9][0-9][0-9])%-([0-1][0-9])%-([0-3][0-9])") }

            if matches[1] == nil
                or tonumber(matches[2]) > 12
                or tonumber(matches[3]) > 31 then
                return false, colors.yellow .. "Not a valid date!" .. colors.reset
            end
        end

        return true
    end
}:ask()

Prompt {
    prompt = "Only numbers allowed\n❱ ",
    filter = function(input)
        return input:match("%d")
            and input
            or ""
    end
}:ask()

Confirm {
    prompt = "All finished?"
}:ask()
