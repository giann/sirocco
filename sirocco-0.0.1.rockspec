
package = "sirocco"
version = "0.0-1"

source = {
    url = "https://github.com/giann/sirocco/archive/0.0.1.tar.gz",
    dir = "sirocco-0.0.1",
}

description = {
    summary  = "A collection of useful cli prompts",
    homepage = "https://github.com/giann/sirocco",
    license  = "MIT/X11",
}

build = {
    modules = {
      ["sirocco"]          = "src/init.lua",
      ["sirocco.prompt"]   = "src/prompt.lua",
      ["sirocco.password"] = "src/password.lua",
      ["sirocco.list"]     = "src/list.lua",
      ["sirocco.confirm"]  = "src/confirm.lua",
    },
    type = "builtin",
}

dependencies = {
    "lua >= 5.3",
    "arparse >= 0.6.0-1",
    "luafilesystem >= 1.7.0-2",
    "lua-term >= 0.7-1",
    "hump >= 0.4-2"
}
