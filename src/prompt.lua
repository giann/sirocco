local Class  = require "hump.class"
local term   = require "term"
local cursor = term.cursor
local colors = term.colors

-- If not in here, won't be recognized
-- TODO: get current terminfo instead
local escapeCodes = {
    -- Why do i need to reimplement those ?
    -- I guess they're not escape codes
    home      = "\1",
    ["end"]   = "\5",
    clearl    = "\11",
    backspace = "\127",

    left    = "\27[D",
    right   = "\27[C",
    down    = "\27[B",
    up      = "\27[A",
}

local Prompt = Class {

    init = function(self, options)
        self.input = options.input or io.stdin
        self.output = options.output or io.stdout
        self.hidden = options.hidden or false
        self.obfuscated = options.obfuscated or false
        self.prompt = options.prompt or "> "
        self.placeholder = options.placeholder or "Type your answer"

        self.buffer = nil
        self.cursorPosition = 1

        -- Only those escape codes are allowed
        -- [escapceCode.code] = function() ... end | true | false
        self.keybinding = {
            [escapeCodes.up]   = false,
            [escapeCodes.down] = false,
            [escapeCodes.left] = function()
                self:moveCursor(-1)
            end,
            [escapeCodes.right] = function()
                self:moveCursor(1)
            end,
            [escapeCodes.home] = function()
                self:moveCursor(-self.cursorPosition + 1)
            end,
            [escapeCodes.clearl] = function()
                term.cleareol()
                self.buffer = ""
            end,
            [escapeCodes.backspace] = function()
                if self.cursorPosition > 1 then
                    self:moveCursor(-1)

                    -- Delete char at cursorPosition
                    self.buffer = self.buffer:sub(1, self.cursorPosition - 1)
                        .. self.buffer:sub(self.cursorPosition + 1)

                    -- Move back, erase and print again
                    self:moveCursor(-self.cursorPosition + 1)
                    term.cleareol()
                    self.output:write(self.buffer)
                    self.cursorPosition = self.buffer:len() + 1
                end
            end
        }
    end

}

function Prompt:moveCursor(chars)
    if chars > 0 then
        chars = math.min(self.buffer:len() - self.cursorPosition + 1, chars)

        if chars > 0 then
            self.cursorPosition = self.cursorPosition + chars
            cursor.goright(chars)
        end
    elseif chars < 0 then
        chars = math.abs(chars)
        cursor.goleft(chars)
        self.cursorPosition = math.max(1, self.cursorPosition - chars)
    end
end

function Prompt:readInput()
    if self.input == io.stdin then
        -- Raw mode to get chars by chars
        os.execute("/usr/bin/env stty raw opost -echo 2> /dev/null")
    end

    -- Starting reference
    cursor:save()

    local char
    self.buffer = ""
    local escapeCode = ""
    repeat
        char = self.input:read(1)

        if self:filterInput(char) then
            escapeCode = escapeCode .. char

            local handledEscapeCode = self:handleEscapeCode(escapeCode)
            if handledEscapeCode == "consumed" then
                -- Escape code was consumed
                escapeCode = ""
            elseif handledEscapeCode ~= "wait" then
                -- Not an escape code

                -- Insert text at cursorPosition
                self.buffer =
                    self.buffer:sub(1, self.cursorPosition - 1)
                    .. escapeCode
                    .. self.buffer:sub(self.cursorPosition)

                -- TODO: take self.hidden into account
                local value = escapeCode
                    .. self.buffer:sub(self.cursorPosition + 1)

                self.output:write(
                    self.hidden
                        and ""
                        or (self.obfuscated
                                and ("*"):rep(#value)
                                or value))
                cursor:restore()
                cursor.goright(self.cursorPosition)
                self.cursorPosition = self.cursorPosition + #escapeCode

                escapeCode = ""
            end

            if self.placeholder and self.buffer:len() > 0 then
                self.placeholder = nil
                term.cleareol()
            end
        end
    until char == "\r" -- Stop on newline
        or char == "\n"

    -- Restore normal mode
    os.execute("/usr/bin/env stty sane")

    local result = self.buffer

    self.buffer = nil

    return result
end

function Prompt:filterInput(input)
    return true
end

function Prompt:validateInput(input)
    return true
end

function Prompt:query()
    self.output:write(self.prompt)

    cursor:save()
    self.output:write(colors.bright .. colors.black .. (self.placeholder or "") .. colors.reset)
    cursor:restore()

    local input = self:readInput()

    self.output:write "\n"

    return self:validateInput(input) and input or nil
end

function Prompt:handleEscapeCode(escapeCode)
    local validEscapeCode = false
    local startOfValidEscapeCode = false
    for _, code  in pairs(escapeCodes) do
        if code == escapeCode then
            validEscapeCode = true
            break
        elseif escapeCode == code:sub(1, #escapeCode) then
            startOfValidEscapeCode = true
        end
    end

    if not validEscapeCode then
        return startOfValidEscapeCode and "wait" or false
    end

    local binding = self.keybinding[escapeCode]

    if binding then
        if type(binding) == "function" then
            binding()
        else
            -- Forward it
            self.output:write(escapeCode)
        end
    elseif binding == nil then
        -- Not handled let it be
        return false
    end

    -- binding == false -> blacklisted
    return "consumed"
end

local answer = Prompt {
    prompt = "A simple question\n> ",
    placeholder = "A simple answer"
}:query()

term.cleareol()

print("Answer was:")
for i = 1, #answer do
    io.write(answer:sub(i, i):byte() .. " [" .. answer:sub(i, i) .. "] ")
end
print()

return Prompt
