PROG=	orch
WARNS?=	6

SRCS=	orch.c	\
	orch_interp.c \
	orch_lua.c

.if !empty(ORCHLUA_PATH)
CFLAGS+=	-DORCHLUA_PATH=\"${ORCHLUA_PATH}\"

.if empty(ORCHLUA_PATH:M/*)
.error "ORCHLUA_PATH must be an absolute path"
.endif

FILESGROUPS+=	FILES
FILES=		orch.lua
FILESDIR=	${ORCHLUA_PATH}
.endif

LUA_INCDIR?=	/usr/local/include/lua54
LUA_LIB?=	-L/usr/local/lib -llua-5.4

CFLAGS+=	-I${LUA_INCDIR}
LDFLAGS+=	${LUA_LIB}

.if make(lint) && !exists(/usr/local/bin/luacheck)
.error "linting requires devel/lua-luacheck"
.endif
lint:
	luacheck orch.lua

# Just pass this on for now.
check:
	env ORCHLUA_PATH=${.CURDIR} $(MAKE) -C tests check

.include "examples/Makefile.inc"

.include <bsd.prog.mk>
