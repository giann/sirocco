# make LUA_DIR=/path/to/lua

LUA_VER         ?= 5.3
LUA_DIR         ?= /usr
LUA_INC         := $(LUA_DIR)/include/
LUA_LIB         := $(LUA_DIR)/lib/lua/$(LUA_VER)
CWARNS          := -Wall -pedantic
CFLAGS          += $(CWARNS) -O3 -I$(LUA_INC) -fPIC -L$(LUA_LIB)
LIB_OPTION      := -shared

LIBRARY         := sirocco/winsize.so
SRC             := sirocco/winsize.c
OBJ             := $(patsubst %.c, %.o, $(SRC))

all: $(LIBRARY)

$(LIBRARY): $(OBJ)
	$(CC) $(CFLAGS) $(LIB_OPTION) -o $(LIBRARY) $(OBJ) -lc -llua$(LUA_VER)

clean:
	$(RM) $(LIBRARY) *.o
