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
            self:setChoice(-1)
        end,

        [Prompt.escapeCodes.down] = function()
            self:setChoice(1)
        end,

        [Prompt.escapeCodes.backspace] = false,
        [Prompt.escapeCodes.down]      = false,
        [Prompt.escapeCodes.left]      = false,
        [Prompt.escapeCodes.right]     = false,
        [Prompt.escapeCodes.home]      = false,
        [Prompt.escapeCodes.clearl]    = false,
    }
end

function List:setChoice(newChoice)
    local current = self.currentChoice
    self.currentChoice = math.max(1, math.min(#self.items, self.currentChoice + newChoice))

    if current ~= self.currentChoice then
        
    end
end

-- No input possible except for up/down escape sequences
function List:filterInput(input)
    return false
end

return List
