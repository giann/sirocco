local Class   = require "hump.class"
local winsize = require "sirocco.winsize"

-- TODO: tui.getnext reads from stdin by default
local tui    = require "tui"
local tparm  = require "tui.tparm".tparm

-- TODO: remove
local term   = require "term"
local colors = term.colors

local Prompt
Prompt = Class {

    init = function(self, options)
        self.input               = options.input or io.stdin
        self.output              = options.output or io.stdout
        self.prompt              = options.prompt or "> "
        self.placeholder         = options.placeholder

        assert(
            not self.placeholder
                or not self.placeholder:find("\n"),
            "New line not allowed in placeholder"
        )

        self.possibleValues      = options.possibleValues or {}
        self.showPossibleValues  = options.showPossibleValues
        self.validator           = options.validator
        self.filter              = options.filter

        self.required = false
        if options.required ~= nil then
            self.required = options.required
        end

        -- Printed buffer (can be wrapped, colored etc.)
        self.displayBuffer = options.default or ""
        -- Unaltered buffer
        self.buffer = options.default or ""
        self.pendingBuffer = ""
        -- Current offset in buffer (has to be translated in (x,y) cursor position)
        self.bufferOffset = 1

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

        self.width = 80
        -- Height is prompt rows + message row
        self.height = 1

        -- Will be printed below
        self.message = nil

        self:registerKeybinding()
    end

}

-- TODO: wrong
function Prompt:getHeight()
    -- Prompt is at least one row + message row
    local height = 2

    -- Prompt can have more than one row
    for _ in self.prompt:gmatch("\n") do
        height = height + 1
    end

    -- Value entered can wrap
    height = height + math.floor(utf8.len(self.buffer) / self.terminalWidth)

    return height
end

function Prompt:registerKeybinding()
    local function home()
        self:setOffset(1)
    end

    local function end_()
        self:setOffset(utf8.len(self.buffer))
    end

    -- Only those escape codes are allowed
    -- [escapceCode.code] = function() ... end | true | false
    self.keybinding = {
        [Prompt.escapeCodes.key_up]   = false,
        [Prompt.escapeCodes.key_down] = false,

        [Prompt.escapeCodes.key_left] = function()
            self:moveOffsetBy(-1)
        end,

        [Prompt.escapeCodes.key_right] = function()
            self:moveOffsetBy(1)
        end,

        ["\1"] = home,
        [Prompt.escapeCodes.key_home] = home,

        ["\5"] = end_,
        [Prompt.escapeCodes.key_end] = end_,
        ["\11"] = function() -- Clear line
            self.buffer = self.buffer:sub(
                1,
                self.bufferOffset - 1
            )
        end,

        [Prompt.escapeCodes.tab] = function() -- Tab
            self:complete()
        end,

        [Prompt.escapeCodes.key_backspace] = function()
            if self.currentPosition.x > 0 then
                self:moveOffsetBy(-1)

                -- Delete char at currentPosition
                self.buffer = self.buffer:sub(1, self.bufferOffset-1)
                    .. self.buffer:sub(self.bufferOffset + 1)
            end
        end,

        -- Clear screen
        ["\12"] = function()
            self:setCursor(1,1)

            self.bufferOffset = 1

            self.startingPosition = {
                x = 1,
                y = 1
            }

            self.promptPosition = {
                x = false,
                y = false
            }

            self.output:write(Prompt.escapeCodes.clr_eos)
        end,
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
            self:setOffset(utf8.len(self.buffer))

            if self.validator then
                local _, message = self.validator(self.buffer)
                self.message = message
            end
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
        or self.pendingBuffer == "\r"
        or self.pendingBuffer == Prompt.escapeCodes.key_enter then
        self.finished = true
        self.pendingBuffer = ""
        return "consumed"
    end

    local binding = self.keybinding[self.pendingBuffer]

    local validEscapeCode = false
    local startOfValidEscapeCode = false
    for _, code  in pairs(Prompt.escapeCodes) do
        if type(code) == "string" then
            if code == self.pendingBuffer then
                validEscapeCode = true
                break
            elseif self.pendingBuffer == code:sub(1, #self.pendingBuffer) then
                startOfValidEscapeCode = true
            end
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
        self.buffer:sub(1, self.bufferOffset)
        .. text
        .. self.buffer:sub(self.bufferOffset + 1)
end

function Prompt:updateCurrentPosition()
    local offset = self.promptPosition.x + self.bufferOffset

    local rows = 0
    while offset - 1 > self.terminalWidth do
        offset = offset - self.terminalWidth
        rows = rows + 1
    end

    self.currentPosition.x = offset - self.promptPosition.x - 1
    self.currentPosition.y = rows
end

-- Take value buffer and format/wrap it
function Prompt:renderDisplayBuffer()
    -- local buffer = self.buffer
    -- self.displayBuffer = ""

    -- while #buffer > 0 do
    --     self.displayBuffer = self.displayBuffer
    --         .. buffer:sub(1, self.terminalWidth)

    --     buffer = buffer:sub(self.terminalWidth + 1)
    -- end

    -- Terminal wraps printed text on its own
    self.displayBuffer = self.buffer
end

-- Set offset and move cursor accordingly
function Prompt:setOffset(offset)
    self.bufferOffset = offset
    self:updateCurrentPosition()
end

-- Move offset by increment and move cursor accordingly
function Prompt:moveOffsetBy(chars)
    if chars > 0 then
        chars = math.min(utf8.len(self.buffer) - self.bufferOffset, chars)

        if chars > 0 then
            self.bufferOffset = self.bufferOffset + chars
        end
    elseif chars < 0 then
        self.bufferOffset = math.max(0, self.bufferOffset + chars)
    end

    self:updateCurrentPosition()
end

function Prompt:processInput(input)
    input = self.filter
        and self.filter(input)
        or input

    self:insertAtCurrentPosition(input)

    self.bufferOffset = self.bufferOffset + utf8.len(input)

    self:updateCurrentPosition()

    if self.validator then
        local _, message = self.validator(self.buffer)
        self.message = message
    end

    self:renderDisplayBuffer()
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
    self.output:write(Prompt.escapeCodes.clr_eos)

    local inlinePossibleValues = self.showPossibleValues and #self.possibleValues > 0
        and " ("
            .. table.concat(self.possibleValues, ", ")
            .. ") "
        or ""

    -- Print prompt
    self.output:write(
        colors.bright .. colors.blue
        .. self.prompt
        .. inlinePossibleValues
        .. colors.reset
    )

    -- Print placeholder
    if self.placeholder
        and (not self.promptPosition.x or not self.promptPosition.y)
        and utf8.len(self.displayBuffer) == 0 then
        self.output:write(
            colors.bright .. colors.black
            .. (self.placeholder or "")
            .. colors.reset
        )
    end

    -- Print current value
    self.output:write(self.displayBuffer)

    -- First time we need to initialize current position
    if not self.promptPosition.x or not self.promptPosition.y then
        local x, y = self.startingPosition.x, self.startingPosition.y - 1
        local prompt = self.prompt .. inlinePossibleValues
        local part
        while #prompt > 0 do
            part = prompt:sub(1, self.terminalWidth)
            prompt = prompt:sub(self.terminalWidth + 1)

            y = y + 1

            for _ in part:gmatch("\n") do
                y = y + 1
            end
        end

        local lastLine = ""
        local lines = 0
        -- Maybe the prompt is on several lines
        for line in part:gmatch("[^\n]*\n(.*)") do
            lastLine = line
            lines = lines + 1
        end

        if lines == 0 then
            lastLine = self.prompt
        end

        self.promptPosition.x, self.promptPosition.y = x + utf8.len(lastLine), y
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
    self.terminalWidth, self.terminalHeight = winsize()

    self.width = self.terminalWidth

    -- Scroll up if at the terminal's bottom
    local heightDelta = (self.startingPosition.y + self.height) - self.terminalHeight - 1
    if heightDelta > 0 then
        -- Scroll up
        self.output:write(tparm(Prompt.escapeCodes.parm_index, heightDelta))

        -- Shift everything up
        self.startingPosition.y = self.startingPosition.y - heightDelta
    end

    self:renderDisplayBuffer()
end

function Prompt:processedResult()
    return self.buffer
end

function Prompt:endCondition()
    if self.finished and self.required and utf8.len(self.buffer) == 0 then
        self.finished = false
        self.message = colors.red .. "Answer is required" .. colors.reset
    end

    -- Only validate if required or if something is in the buffer
    if self.finished and self.validator and (self.required or utf8.len(self.buffer) > 0) then
        local ok, message = self.validator(self.buffer)
        self.finished = self.finished and (ok or not self.required)
        self.message = message
    end

    return self.finished
end

function Prompt:getCursor()
    local y, x  = tui.getnext():match("([0-9]*);([0-9]*)")
    return tonumber(x), tonumber(y)
end

function Prompt:setCursor(x, y)
    self.output:write(tparm(Prompt.escapeCodes.cursor_address, y, x))
end

function Prompt:before()
    if self.input == io.stdin then
        -- Raw mode to get chars by chars
        os.execute("/usr/bin/env stty raw opost -echo 2> /dev/null")
    end

    -- Get current position
    self.output:write(Prompt.escapeCodes.user7)

    self.startingPosition.x,
        self.startingPosition.y = self:getCursor()

    -- Wrap prompt if needed
    self.terminalWidth, self.terminalHeight = winsize()
    self.height = self:getHeight()
end

function Prompt:after()
    self.output:write("\n")

    -- Restore normal mode
    os.execute("/usr/bin/env stty sane")
end

function Prompt:ask()
    self:before()

    repeat
        self:update()

        self:render()

        self:handleInput()
    until self:endCondition()

    local result = self:processedResult()

    self:after(result)

    return result
end

-- If can't find terminfo, fallback to minimal list of necessary codes
local ok, terminfo = pcall(require "tui.terminfo".find)

Prompt.escapeCodes = ok and terminfo or {}

-- Make sure we got everything we need
-- TODO: figure out why some of those are wrong in terminfo
Prompt.escapeCodes.cursor_invisible = Prompt.escapeCodes.cursor_invisible or "\27[?25l"
Prompt.escapeCodes.cursor_visible   = Prompt.escapeCodes.cursor_visible   or "\27[?25h"
Prompt.escapeCodes.clr_eos          = Prompt.escapeCodes.clr_eos          or "\27[J"
Prompt.escapeCodes.cursor_address   = Prompt.escapeCodes.cursor_address   or "\27[%i%p1%d;%p2%dH"
-- Get cursor position (https://invisible-island.net/ncurses/terminfo.ti.html)
Prompt.escapeCodes.user7            = Prompt.escapeCodes.user7            or "\27[6n"
Prompt.escapeCodes.key_left         = Prompt.escapeCodes.key_left         or "\27[D"
Prompt.escapeCodes.key_right        = Prompt.escapeCodes.key_right        or "\27[C"
Prompt.escapeCodes.key_down         = Prompt.escapeCodes.key_down         or "\27[B"
Prompt.escapeCodes.key_up           = Prompt.escapeCodes.key_up           or "\27[A"
Prompt.escapeCodes.key_backspace    = Prompt.escapeCodes.key_backspace    or "\127"
Prompt.escapeCodes.tab              = Prompt.escapeCodes.tab              or "\9"
Prompt.escapeCodes.key_home         = Prompt.escapeCodes.key_home         or "\27" .. "0H"
Prompt.escapeCodes.key_end          = Prompt.escapeCodes.key_end          or "\27" .. "0F"
Prompt.escapeCodes.key_enter        = Prompt.escapeCodes.key_enter        or "\27" .. "0M"
Prompt.escapeCodes.parm_index       = Prompt.escapeCodes.parm_inde        or "\27[%p1%dS"

return Prompt
