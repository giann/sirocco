local wcwidth = require "wcwidth"

local control_character_threshold = 0x020 -- Smaller than this is control.
local control_character_mask      = 0x1f  -- 0x20 - 1
local meta_character_threshold    = 0x07f -- Larger than this is Meta.
local control_character_bit       = 0x40  -- 0x000000, must be off.
local meta_character_bit          = 0x080 -- x0000000, must be on.
local largest_char                = 255   -- Largest character value.

local function ctrl_char(c)
    return c < control_character_threshold and (c & 0x80) == 0
end

local function meta_char(c)
    return c > meta_character_threshold and c <= largest_char
end


local function ctrl(c)
    return string.char(c:byte() & control_character_mask)
end

-- Nobody really has a Meta key, use Esc instead
local function meta(c)
    return string.char(c:byte() | meta_character_bit)
end

local function Esc(c)
    return "\27" .. c
end

local function unMeta(c)
    return string.char(c:byte() & (~meta_character_bit))
end

local function unCtrl(c)
    return string.upper(string.char(c:byte() | control_character_bit))
end

-- Utf8 aware sub
string.utf8sub = require "utf8_simple".sub

string.utf8width = function(self)
    local len = 0

    for _, rune in utf8.codes(self) do
        local l = wcwidth(rune)
        if l >= 0 then
            len = len + l
        end
    end

    return len
end

return {
    isC = ctrl_char,
    isM = meta_char,
    C   = ctrl,
    M   = meta,
    Esc = Esc,
    unM = unMeta,
    unC = unCtrl,
}
