# Neovim REPL

Create, use, and remove [interactive REPLs](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop) in Neovim 0.11.0 or later (nightly recommended).

Works with any REPL, but contains custom support for the following REPLs:

- [aider](https://aider.chat): AI pair programming in your terminal
- [ipython](https://ipython.readthedocs.io/en/stable): a powerful interactive Python shell
- [utop](https://opam.ocaml.org/blog/about-utop): a much improved interface to the OCaml toplevel

Default REPL settings are defined in [lua/repl/init.lua:defaults](https://github.com/pappasam/nvim-repl/blob/main/lua/repl/init.lua).

## Demo

![demo](images/nvim-repl-demo.gif)

## Installation

Neovim REPL is a [normal Neovim package](https://neovim.io/doc/user/usr_05.html#_adding-a-package).

<details>
  <summary>lazy.nvim</summary>
  <br>

Configuration for <https://github.com/folke/lazy.nvim>

### Basic

```lua
{
  "pappasam/nvim-repl",
  keys = {
    { "<Leader>c", "<Plug>(ReplSendCell)",   mode = "n", desc = "Send Repl Cell" },
    { "<Leader>r", "<Plug>(ReplSendLine)",   mode = "n", desc = "Send Repl Line" },
    { "<Leader>r", "<Plug>(ReplSendVisual)", mode = "x", desc = "Send Repl Visual Selection" },
  },
}
```

### Custom

```lua
{
  "pappasam/nvim-repl",
  opts = {
    filetype_commands = {
      javascript = {cmd = "deno repl", filetype = "javascript"},
    },
    default = {cmd = "bash", filetype = "bash"},
    open_window_default = "vertical split new",
  },
  keys = {
    { "<Leader>c", "<Plug>(ReplSendCell)",   mode = "n", desc = "ReplSendCell" },
    { "<Leader>r", "<Plug>(ReplSendLine)",   mode = "n", desc = "ReplSendLine" },
    { "<Leader>r", "<Plug>(ReplSendVisual)", mode = "x", desc = "ReplSendVisual" },
  },
}
```

</details>

## FAQ

### Where's the documentation?

Documentation is in a normal Neovim help file. You can [read it online here](https://github.com/pappasam/nvim-repl/blob/main/doc/repl.txt).

From within Neovim, type `:help repl`.

### Escape doesn't work in Terminal mode

If you find yourself in Terminal mode, use `<C-\><C-n>` instead of `<Esc>` to return to Normal mode.

Type `:help Terminal-mode` and `:help CTRL-\_CTRL-N` for more information.

### Recommended aider configuration

The built-in aider integration overrides aider's `--multiline`, `--notifications`, and `--notifications-command` for a smooth Neovim integration. All other settings default to the user's aider configuration file and environment. To that end, we recommend:

1. Use [$AIDER_MODEL](https://aider.chat/docs/config/options.html#main-model) to specify your preferred model before opening Neovim.
2. For other settings, please reference the Author's current [aider configuration](https://github.com/pappasam/config/blob/main/dotfiles/.aider.conf.yml) for inspiration.

### My tabline is really long

Sometimes, terminal commands (like aider) can be long. If your tabline is long, you can customize it.

[Click here for an example](https://github.com/pappasam/config/blob/main/dotfiles/.config/nvim/lua/settings.lua)
