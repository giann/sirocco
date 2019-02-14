local Class  = require "hump.class"
local tui    = require "tui"

-- TODO: remove
local term   = require "term"
local colors = term.colors

local Prompt
Prompt = Class {

    -- If not in here, won't be recognized
    -- TODO: get current terminfo instead
    escapeCodes = {
        -- Why do i need to reimplement those ?
        -- I guess they're not escape codes
        home      = "\1",
        ["end"]   = "\5",
        clearl    = "\11",
        backspace = "\127",

        getcursor = "\27[6n\n",
        left      = "\27[D",
        right     = "\27[C",
        down      = "\27[B",
        up        = "\27[A",
    },

    init = function(self, options)
        self.input       = options.input or io.stdin
        self.output      = options.output or io.stdout
        self.hidden      = options.hidden or false
        self.obfuscated  = options.obfuscated or false
        self.prompt      = options.prompt or "> "
        self.placeholder = options.placeholder or "Type your answer"

        self.buffer = ""
        self.pendingBuffer = ""

        self.currentPosition = {
            x = 1,
            y = 1
        }

        self.startingPosition = {
            x = 1,
            y = 1
        }

        self:registerKeybinding()
    end

}

function Prompt:registerKeybinding()
    -- Only those escape codes are allowed
    -- [escapceCode.code] = function() ... end | true | false
    self.keybinding = {
        [Prompt.escapeCodes.up]   = false,
        [Prompt.escapeCodes.down] = false,
        [Prompt.escapeCodes.left] = function()
            self:moveCursor(-1)
        end,
        [Prompt.escapeCodes.right] = function()
            self:moveCursor(1)
        end,
        [Prompt.escapeCodes.home] = function()
            self:moveCursor(-self.currentPosition.x + 1)
        end,
        [Prompt.escapeCodes.clearl] = function()
            self.buffer = ""
        end,
        [Prompt.escapeCodes.backspace] = function()
            if self.currentPosition.x > 1 then
                self:moveCursor(-1)

                -- Delete char at currentPosition
                self.buffer = self.buffer:sub(1, self.currentPosition.x - 1)
                    .. self.buffer:sub(self.currentPosition.x + 1)
            end
        end
    }
end

function Prompt:handleBindings()
    local validEscapeCode = false
    local startOfValidEscapeCode = false
    for _, code  in pairs(Prompt.escapeCodes) do
        if code == self.pendingBuffer then
            validEscapeCode = true
            break
        elseif self.pendingBuffer == code:sub(1, #self.pendingBuffer) then
            startOfValidEscapeCode = true
        end
    end

    if not validEscapeCode then
        return startOfValidEscapeCode and "wait" or false
    end

    local binding = self.keybinding[self.pendingBuffer]

    if binding then
        -- We have a binding for it
        if type(binding) == "function" then
            binding()
        -- We don't have a binding for it but we don't want it in the buffer
        else
            self.output:write(self.pendingBuffer)
        end
    -- We don't handle it at all, it'll be printed and in the buffer
    elseif binding == nil then
        return false
    end

    -- If binding == false, we blacklisted it: do nothing

    -- If we reach here, escape code was consumed
    self.pendingBuffer = ""
    return "consumed"
end

function Prompt:moveCursor(chars)
    if chars > 0 then
        chars = math.min(self.buffer:len() - self.currentPosition.x + 1, chars)

        if chars > 0 then
            self.currentPosition.x = self.currentPosition.x + chars
        end
    elseif chars < 0 then
        self.currentPosition.x = math.max(1, self.currentPosition.x - chars)
    end
end

function Prompt:handleInput()
    self.pendingBuffer = self.pendingBuffer .. tui.getnext()

    local handled = self:handleBindings()

    -- Not an escape code
    if handled ~= "consumed"
        and handled ~= "wait" then
        -- Insert text at currentPosition
        self.buffer =
            self.buffer:sub(1, self.currentPosition.x - 1)
            .. self.pendingBuffer
            .. self.buffer:sub(self.currentPosition.x)

        self.currentPosition.x = self.currentPosition.x + self.pendingBuffer:len()

        -- Consume pending
        self.pendingBuffer = ""
    end
end

function Prompt:render()
    -- Go back to start
    self:setCursor(self.startingPosition.x, self.startingPosition.y)

    -- Clear down
    self.output:write("\27[J")

    -- Print prompt
    self.output:write(self.prompt)

    -- Print placeholder
    if self.currentPosition.x == 1 and self.buffer:len() == 0 then
        self.output:write(colors.bright .. colors.black .. (self.placeholder or "") .. colors.reset)
    end

    -- Print current value
    self.output:write(self.buffer)

    -- Maybe the prompt is on several lines
    local lastLine
    local lines = 0
    for line in self.prompt:gmatch("[^\n]*\n(.*)") do
        lastLine = line
        lines = lines + 1
    end

    self:setCursor(
        lastLine:len() + self.currentPosition.x,
        self.startingPosition.y + lines
    )
end

function Prompt:update()
end

function Prompt:processedResult()
    -- Remove trailing newline char
    return self.buffer:sub(1, -2)
end

function Prompt:endCondition()
    -- Last char is a newline
    local lastChar = self.buffer:sub(-1)
    return lastChar == "\r"
        or lastChar == "\n"
end

function Prompt:getCursor()
    local y, x  = tui.getnext():match("([0-9]*);([0-9]*)")
    return tonumber(x), tonumber(y)
end

function Prompt:setCursor(x, y)
    self.output:write("\27[" .. math.floor(y) .. ";" .. math.floor(x) .. "H")
end

function Prompt:loop()
    if self.input == io.stdin then
        -- Raw mode to get chars by chars
        os.execute("/usr/bin/env stty raw opost -echo 2> /dev/null")
    end

    -- Get current position
    self.output:write(Prompt.escapeCodes.getcursor)

    self.currentPosition.x,
        self.currentPosition.y = self:getCursor()

    self.startingPosition.x = self.currentPosition.x
    self.startingPosition.y = self.currentPosition.y

    repeat
        self:render()

        self:handleInput()

        self:update()
    until self:endCondition()

    self.output:write("\n")

    -- Restore normal mode
    os.execute("/usr/bin/env stty sane")

    return self:processedResult()
end

return Prompt
