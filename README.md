# Sirocco
A collection of interactive command line prompts for Lua

<p align="center">
    <img src="https://github.com/giann/lua-query/raw/master/assets/example.gif" alt="lua-query">
</p>

## Installing

Requirements:
- Lua 5.3
- luarocks >= 3.0 (_Note: `hererocks -rlatest` will install 2.4, you need to specify it with `-r3.0`_)

```bash
luarocks install sirocco
```

## Quickstart

See [`example.lua`](https://github.com/giann/sirocco/blob/master/example.lua) for an exhaustive snippet of all sirocco's features.

### Text prompt

<p align="center">
    <img src="https://github.com/giann/lua-query/raw/master/assets/prompt.png" alt="lua-query">
</p>

```lua
Prompt {
    -- The prompt
    prompt         = "A simple question\n❱ ",
    -- A placeholder that will dissappear once the user types something
    placeholder    = "A simple answer",
    -- Whether the answer is required or not
    required       = true,
    -- The default answer
    default        = "A default answer",
    -- When hitting `tab`, will try to autocomplete based on those values
    possibleValues = {
        "some",
        "possible",
        "values",
    },
    -- Must return whether the current text is valid + a message in case it's not
    validator      = function(text)
        return text:match("[a-zA-Z]*"), "Message when not valid"
    end,
    -- If returns false, input will not appear at all
    filter         = function(input)
        return input:match("[a-zA-Z]*")
    end
}:ask() -- Returns the answer
```

### Password

<p align="center">
    <img src="https://github.com/giann/lua-query/raw/master/assets/password.png" alt="lua-query">
</p>

```lua
Password {
    prompt = "Enter your secret (hidden answer)\n❱ ",
    -- When false *** are printed otherwise nothing
    hidden = false
}:ask() -- Returns the answer
```

### Confirm

<p align="center">
    <img src="https://github.com/giann/lua-query/raw/master/assets/confirm.png" alt="lua-query">
</p>

```lua
Confirm {
    prompt = "All finished?"
}:ask() -- Returns the answer
```

### List

<p align="center">
    <img src="https://github.com/giann/lua-query/raw/master/assets/list-single.png" alt="lua-query">
</p>

<p align="center">
    <img src="https://github.com/giann/lua-query/raw/master/assets/list-multiple.png" alt="lua-query">
</p>

```lua
List {
    prompt   = "Where are you from?",
    -- If true can select multiple choices (checklist) otherwise one (radio list)
    multiple = false,
    -- List of choices
    items    = {
        {
            -- The actual value returned if selected
            value = "New York",
            -- The value displayed to the user
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
    -- Indexes of already selected choices
    default  = { 2, 4 },
}:ask() -- Returns the answer
```