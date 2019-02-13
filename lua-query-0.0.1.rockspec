
package = "lua-query"
version = "0.0-1"

source = {
    url = "https://github.com/giann/lua-query/archive/0.0.1.tar.gz",
    dir = "lua-query-0.0.1",
}

description = {
    summary  = "A collection of useful cli prompts",
    homepage = "https://github.com/giann/lua-query",
    license  = "MIT/X11",
}

build = {
    modules = {
      ["query"] = "src/init.lua"
    },
    type = "builtin",
}

dependencies = {
    "lua >= 5.3",
    "arparse >= 0.6.0-1",
    "luafilesystem >= 1.7.0-2",
    "lua-term >= 0.7-1",
}