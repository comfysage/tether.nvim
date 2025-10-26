# tether.nvim

Track and reattach Neovim sessions

tether.nvim makes Neovim’s remote UI feature easy to use by treating servers as
persistent tethers you can reattach to later. it tracks open servers, lists
them, and helps you connect or detach safely without shutting anything down.

## :sparkles: features

- keeps track of all running Neovim servers
- shows an overview of open sessions and their working directories
- lets you easily attach to an existing session via `vim.ui.select()`
- maintains a small, persistent registry file under Neovim's state path

## :gear: commands

```
:Tether track   — register the current server (auto on UIEnter)
:Tether select  — attach to a tracked server
:Tether print   — print the current registry list
```

## example workflow

start a neovim instance:

```bash
nvim
```

open a directory:

```
:cd ~/dev/project.nvim/
```

detach:

```
:detach
```

open a new instance and select the previous session:

```
:Tether! select -- the ! denotes that the current empty session should be closed
```

## configuration

no setup required for basic use but you can tweak some keybinds to make tethering easier:

```lua
-- easier detach
vim.keymap.set("n", "<C-z>", vim.cmd.detach)
-- easier switching
vim.keymap.set("n", "<C-t>", "<Plug>(tether-select)")
-- switch and stop current session
vim.keymap.set("n", "<C-T>", "<cmd>Tether! select<CR>")
```

## api

this plugin exposes a small lua interface for integration:

```lua
local tether = require('tether')

tether.track()  -- track current session; will save socket and cwd
tether.select() -- attach to a tracked session

require('tether.data'):iter() -- creates a `vim.iter()` iterator over the server tethers
-- -> { { '/run/user/1000/nvim.0000.1', '/home/robin' } }
```

## design notes

tether.nvim doesn't try to be a tmux replacement. it's a session connector
built entirely on Neovim's native remote UI system. you still get full Neovim
state persistence, with the comfort of reconnecting easily to your previous
sessions.

## inspiration

- [neovim/neovim#5035](https://github.com/neovim/neovim/issues/5035)
- the wish for tmux-like tethering between sessions
