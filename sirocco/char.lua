local control_character_threshold = 0x020 -- Smaller than this is control.
local control_character_mask      = 0x1f  -- 0x20 - 1
local meta_character_threshold    = 0x07f -- Larger than this is Meta.
local control_character_bit       = 0x40  -- 0x000000, must be off.
local meta_character_bit          = 0x080 -- x0000000, must be on.
local largest_char                = 255   -- Largest character value.

local function CTRL_CHAR(c)
    return c < control_character_threshold and (c & 0x80) == 0
end

local function META_CHAR(c)
    return c > meta_character_threshold and c <= largest_char
end


local function CTRL(c)
    return string.char(c:byte() & control_character_mask)
end

local function META(c)
    return string.char(c:byte() | meta_character_bit)
end


local function UNMETA(c)
    return string.char(c:byte() & (~meta_character_bit))
end

local function UNCTRL(c)
    return string.upper(string.char(c:byte() | control_character_bit))
end

return {
    isC = CTRL_CHAR,
    isM = META_CHAR,
    C   = CTRL,
    M   = META,
    unM = UNMETA,
    unC = UNCTRL,
}