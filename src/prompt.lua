local Class  = require "hump.class"

-- TODO: tui.getnext reads from stdin by default
local tui    = require "tui"

-- TODO: remove
local term   = require "term"
local colors = term.colors

local Prompt
Prompt = Class {

    -- If not in here, won't be recognized
    -- TODO: get current terminfo instead
    escapeCodes = {
        cleardown = "\27[J",
        getcursor = "\27[6n\n",
        left      = "\27[D",
        right     = "\27[C",
        down      = "\27[B",
        up        = "\27[A",
    },

    init = function(self, options)
        self.input          = options.input or io.stdin
        self.output         = options.output or io.stdout
        self.prompt         = options.prompt or "> "
        self.placeholder    = options.placeholder
        self.possibleValues = options.possibleValues or {}

        self.required = false
        if options.required ~= nil then
            self.required = options.required
        end

        self.buffer = options.default or ""
        self.pendingBuffer = ""

        self.currentPosition = {
            x = options.default and utf8.len(options.default) or 0,
            y = 0
        }

        self.startingPosition = {
            x = false,
            y = false
        }

        self.promptPosition = {
            x = false,
            y = false
        }

        -- Will be printed below
        self.message = nil

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
        ["\1"] = function() -- Home
            self:moveCursor(-self.currentPosition.x)
        end,
        ["\5"] = function() -- End
            self.currentPosition.x = utf8.len(self.buffer)
        end,
        ["\11"] = function() -- Clear line
            self.buffer = ""
        end,
        ["\9"] = function() -- Tab
            self:complete()
        end,
        ["\127"] = function() -- Backspace
            if self.currentPosition.x > 0 then
                self:moveCursor(-1)

                -- Delete char at currentPosition
                self.buffer = self.buffer:sub(1, self.currentPosition.x)
                    .. self.buffer:sub(self.currentPosition.x + 2)
            end
        end
    }
end

function Prompt:complete()
    if #self.possibleValues > 0 then
        local matches = {}
        local count = 0
        for _, value in ipairs(self.possibleValues) do
            if value:sub(1, #self.buffer) == self.buffer then
                table.insert(matches, value)
                count = count + 1
            end
        end

        if count > 1 then
            self.message = table.concat(matches, " ")
        elseif count == 1 then
            self.buffer = matches[1]
            self.currentPosition.x = utf8.len(self.buffer)
        end
    end
end

function Prompt:handleBindings()
    -- Ctrl-c and Ctrl-d interrupt everything
    if self.pendingBuffer == "\3"
        or self.pendingBuffer == "\4" then
        self:after()
        os.exit()
    end

    -- New line ends the query
    if self.pendingBuffer == "\n"
        or self.pendingBuffer == "\r" then
        self.finished = true
        self.pendingBuffer = ""
        return "consumed"
    end

    local binding = self.keybinding[self.pendingBuffer]

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

    if not validEscapeCode and not binding then
        return startOfValidEscapeCode and "wait" or false
    end

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

function Prompt:insertAtCurrentPosition(text)
    -- Insert text at currentPosition
    self.buffer =
        self.buffer:sub(1, self.currentPosition.x)
        .. text
        .. self.buffer:sub(self.currentPosition.x + 1)
end

function Prompt:moveCursor(chars)
    if chars > 0 then
        chars = math.min(utf8.len(self.buffer) - self.currentPosition.x, chars)

        if chars > 0 then
            self.currentPosition.x = self.currentPosition.x + chars
        end
    elseif chars < 0 then
        self.currentPosition.x = math.max(0, self.currentPosition.x + chars)
    end
end

function Prompt:processInput(input)
    self:insertAtCurrentPosition(input)

    self.currentPosition.x = self.currentPosition.x + utf8.len(input)

    self.message = nil
end

function Prompt:handleInput()
    self.pendingBuffer = self.pendingBuffer .. tui.getnext()

    local handled = self:handleBindings()

    -- Not an escape code
    if handled ~= "consumed"
        and handled ~= "wait" then
        self:processInput(self.pendingBuffer)

        -- Consume pending
        self.pendingBuffer = ""
    end
end

function Prompt:render()
    -- Go back to start
    self:setCursor(self.startingPosition.x, self.startingPosition.y)

    -- Clear down
    self.output:write(Prompt.escapeCodes.cleardown)

    -- Print prompt
    self.output:write(
        colors.bright .. colors.blue
        .. self.prompt
        .. colors.reset
    )

    -- Print placeholder
    if self.placeholder
        and (not self.promptPosition.x or not self.promptPosition.y)
        and utf8.len(self.buffer) == 0 then
        self.output:write(colors.bright .. colors.black .. (self.placeholder or "") .. colors.reset)
    end

    -- Print current value
    self.output:write(self.buffer)

    -- First time we need to initialize current position
    if not self.promptPosition.x or not self.promptPosition.y then
        local lastLine = ""
        local lines = 0
        -- Maybe the prompt is on several lines
        for line in self.prompt:gmatch("[^\n]*\n(.*)") do
            lastLine = line
            lines = lines + 1
        end

        if lines == 0 then
            lastLine = self.prompt
        end

        self.promptPosition.x = utf8.len(lastLine) + self.startingPosition.x
        self.promptPosition.y = self.startingPosition.y + lines
    end

    self:renderMessage()

    self:setCursor(
        self.promptPosition.x + self.currentPosition.x,
        self.promptPosition.y + self.currentPosition.y
    )
end

function Prompt:renderMessage()
    if self.message then
        self:setCursor(
            1,
            self.promptPosition.y + self.currentPosition.y + 1
        )

        self.output:write(self.message)

        self:setCursor(
            self.promptPosition.x + self.currentPosition.x,
            self.promptPosition.y + self.currentPosition.y
        )
    end
end

function Prompt:update()
end

function Prompt:processedResult()
    -- Remove trailing newline char
    return self.buffer:sub(1, -2)
end

function Prompt:endCondition()
    local condition = (not self.required or utf8.len(self.buffer) > 0)

    if self.finished and not condition then
        self.message = colors.red .. "Answer is required" .. colors.reset
    end

    self.finished = self.finished and (not self.required or utf8.len(self.buffer) > 0)

    return self.finished
end

function Prompt:getCursor()
    local y, x  = tui.getnext():match("([0-9]*);([0-9]*)")
    return tonumber(x), tonumber(y)
end

function Prompt:setCursor(x, y)
    self.output:write("\27[" .. math.floor(y) .. ";" .. math.floor(x) .. "H")
end

function Prompt:before()
    if self.input == io.stdin then
        -- Raw mode to get chars by chars
        os.execute("/usr/bin/env stty raw opost -echo 2> /dev/null")
    end

    -- Get current position
    self.output:write(Prompt.escapeCodes.getcursor)

    self.startingPosition.x,
        self.startingPosition.y = self:getCursor()
end

function Prompt:after()
    self.output:write("\n")

    -- Restore normal mode
    os.execute("/usr/bin/env stty sane")
end

function Prompt:loop()
    self:before()

    repeat
        self:render()

        self:handleInput()

        self:update()
    until self:endCondition()

    local result = self:processedResult()

    self:after(result)

    return result
end

return Prompt
