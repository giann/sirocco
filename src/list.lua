local Class  = require "hump.class"

local Prompt = require "prompt"

local List = Class {

    __includes = Prompt,

    init = function(self, options)
        self.items         = options.items or {
            -- {
            --     value = "a",
            --     label = "the first choice"
            -- }
        }
        self.multiple      = options.multiple or false
        self.currentChoice = nil

        Prompt.init(self, options)
    end

}

function List:registerKeybinding()
    self.keybinding = {
        [Prompt.escapeCodes.up] = function()
            self.currentChoice = math.max(1, self.currentChoice - 1)
        end,

        [Prompt.escapeCodes.down] = function()
            self.currentChoice = math.min(#self.items, self.currentChoice + 1)
        end,

        [Prompt.escapeCodes.backspace] = false,
        [Prompt.escapeCodes.down]      = false,
        [Prompt.escapeCodes.left]      = false,
        [Prompt.escapeCodes.right]     = false,
        [Prompt.escapeCodes.home]      = false,
        [Prompt.escapeCodes.clearl]    = false,
    }
end

-- No input possible except for up/down escape sequences
function List:filterInput(input)
    return false
end

return List