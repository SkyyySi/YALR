# YALR - Yet Another Lua REPL

YALR is a simple REPL for Lua, written in Lua, configured in Lua, breathing Lua.

![YALR screenshot](/assets/screenshot0.png)

YALR is a very early project in its pre-alpha stages. Contributions welcome.

Currently, YALR only supports Linux (and other UNIX-like systems), Windows will
most definitely not work.

To run, just `cd` into the cloned repository and type
```bash
./yalr.lua
```

You may wish to use another Lua version (for example luajit) than what's executed
by `/usr/bin/env lua` by instead running
```bash
luajit yalr.lua
```
