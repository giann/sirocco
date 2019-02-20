
package = "sirocco"
version = "0.0.1-3"
rockspec_format = "3.0"

source = {
    url = "git://github.com/giann/sirocco",
}

description = {
    summary  = "A collection of useful cli prompts",
    homepage = "https://github.com/giann/sirocco",
    license  = "MIT/X11",
}

build = {
    modules = {
        ["sirocco"]            = "sirocco/init.lua",
        ["sirocco.composite"]  = "sirocco/composite.lua",
        ["sirocco.confirm"]    = "sirocco/confirm.lua",
        ["sirocco.list"]       = "sirocco/list.lua",
        ["sirocco.password"]   = "sirocco/password.lua",
        ["sirocco.prompt"]     = "sirocco/prompt.lua",
        ["sirocco.char"]       = "sirocco/char.lua",
        ["sirocco.winsize"]    = "sirocco/winsize.c",
        ["tui"]                = "lib/tui/tui/init.lua",
        ["tui.filters"]        = "lib/tui/tui/filters.lua",
        ["tui.terminfo"]       = "lib/tui/tui/terminfo.lua",
        ["tui.tparm"]          = "lib/tui/tui/tparm.lua",
        ["tui.tput"]           = "lib/tui/tui/tput.lua",
        ["tui.util"]           = "lib/tui/tui/util.lua",
    },
    type = "builtin",
}

dependencies = {
    "lua >= 5.3",
    "lua-term >= 0.7-1",
    "hump >= 0.4-2"
}
