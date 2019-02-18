LUA_VER         ?= 5.1
LUA_DIR         ?= /usr
LUA_LIBDIR      := $(LUA_DIR)/lib/lua/$(LUA_VER)/term
LUA_INC         := $(LUA_DIR)/include/lua$(LUA_VER)
LUA_SHARE       := $(LUA_DIR)/share/lua/$(LUA_VER)/term
CWARNS          := -Wall -pedantic
CFLAGS          += $(CWARNS) -O3 -I$(LUA_INC) -fPIC
LIB_OPTION      := -shared

LIBRARY         := sirocco/winsize.so
SRC             := sirocco/winsize.c
OBJ             := $(patsubst %.c, %.o, $(SRC))

all: $(LIBRARY)

$(LIBRARY): $(OBJ)
	$(CC) $(CFLAGS) $(LIB_OPTION) -o $(LIBRARY) $(OBJ) -lc

clean:
	$(RM) $(LIBRARY) *.o