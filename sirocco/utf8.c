#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include <glib.h>

int lua_width(lua_State *L) {
    luaL_checktype(L, 1, LUA_TSTRING);

    size_t len;
    const char *str = lua_tolstring(L, 1, &len);

    // Convert to gunichar
    const gunichar *unistr = g_utf8_to_ucs4(str, -1, NULL, NULL, NULL);

    // Not a valid utf8 string, return regular length of string
    if (unistr == NULL) {
        lua_pushinteger(L, len);

        return 1;
    }

    int width = 0;
    for (int i = 0; i < g_utf8_strlen(str, -1); ++i) {
        width += g_unichar_iswide(unistr[i]) ?
            2 : (g_unichar_iszerowidth(unistr[i]) ? 0 : 1);
    }

    g_free((gpointer)unistr);

    lua_pushinteger(L, width);

    return 1;
}

int luaopen_sirocco_utf8(lua_State *L) {
    lua_newtable(L);
    lua_pushcfunction(L, lua_width);
    lua_setfield(L, -2, "width");

    return 1;
}

// TODO: Makefile

// env MACOSX_DEPLOYMENT_TARGET=10.8 gcc -O2 -fPIC `pkg-config --cflags glib-2.0`  -I/Users/giann/lua53/include -c sirocco/utf8.c -o sirocco/utf8.o `pkg-config --libs glib-2.0`
// env MACOSX_DEPLOYMENT_TARGET=10.8 gcc -bundle -undefined dynamic_lookup -all_load `pkg-config --cflags glib-2.0` -o sirocco/utf8.so sirocco/utf8.o `pkg-config --libs glib-2.0`
