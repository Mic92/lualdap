CFLAGS += $(shell pkg-config --cflags lua)
LDLIBS += $(shell pkg-config --libs lua) -lldap

LUA_MODULES := $(shell pkg-config --variable=INSTALL_CMOD lua)

all: lualdap.so

lualdap.so: lualdap.c
	 $(CC) -fPIC -shared $(CFLAGS) -o $@ $^ $(LDLIBS)

install: lualdap.so
	mkdir -p "$(DESTDIR)$(LUA_MODULES)"
	cp lualdap.so "$(DESTDIR)$(LUA_MODULES)"

uninstall:
	rm -f "$(DESTDIR)$(LUA_MODULES)/lualdap.so"

clean:
	rm -f lualdap.so

.PHONY: uninstall clean all
