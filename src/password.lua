local Class  = require "hump.class"

local Prompt = require "prompt"

local Password = Class {

    __includes = Prompt,

    init = function(self, options)
        -- Can't suggest anything
        options.default = nil
        options.possibleValues = nil

        self.hidden = options.hidden

        Prompt.init(self, options)

        self.actual = ""
    end

}

function Password:insertAtCurrentPosition(text)
    -- Insert text at currentPosition
    self.actual =
        self.actual:sub(1, self.currentPosition.x)
        .. text
        .. self.actual:sub(self.currentPosition.x + 1)

    self.buffer =
        self.hidden
            and ""
            or self.buffer:sub(1, self.currentPosition.x)
                .. ("*"):rep(utf8.len(text))
                .. self.buffer:sub(self.currentPosition.x + 1)
end

function Password:processInput(input)
    Prompt.processInput(self, input)

    if self.hidden then
        self.currentPosition.x = 0
    end
end

function Password:complete()
end

function Password:processedResult()
    -- Remove trailing newline char
    return self.actual:sub(1, -2)
end

return Password
