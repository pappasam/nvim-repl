# Neovim REPL

Create, use, and remove [interactive REPLs](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop) within Neovim.

Works with any REPL, but contains custom support for the following REPLs:

- [ipython](https://ipython.readthedocs.io/en/stable): a powerful interactive Python shell
- [aider](https://aider.chat): AI pair programming in your terminal
- [utop](https://opam.ocaml.org/blog/about-utop): a much improved interface to the OCaml toplevel

## Installation

See below for installation instructions for some common Neovim Package managers. For all other package managers, consult your package manager's documentation. Neovim REPL is a [normal Neovim package](https://neovim.io/doc/user/usr_05.html#_adding-a-package).

<details>
  <summary>lazy.nvim</summary>
  <br>

Configuration for <https://github.com/folke/lazy.nvim>

```lua
{
  "pappasam/nvim-repl",
  init = function()
    vim.g["repl_filetype_commands"] = {
      bash = "bash",
      javascript = "node",
      haskell = "ghci",
      ocaml = {cmd = "utop", repl_type = "utop"},
      r = "R",
      sh = "sh",
      vim = "nvim --clean -ERM",
      zsh = "zsh",
    }
  end,
  keys = {
    { "<Leader>cc", "<Cmd>ReplNewCell<CR>",   mode = "n", desc = "Create New Cell" },
    { "<Leader>cr", "<Plug>(ReplSendCell)",   mode = "n", desc = "Send Repl Cell" },
    { "<Leader>r",  "<Plug>(ReplSendLine)",   mode = "n", desc = "Send Repl Line" },
    { "<Leader>r",  "<Plug>(ReplSendVisual)", mode = "x", desc = "Send Repl Visual Selection" },
  },
}
```

</details>

## Usage

![demo](images/nvim-repl-demo.gif)

For detailed documentation, see: <https://github.com/pappasam/nvim-repl/blob/main/doc/repl.txt>

From within Neovim, type:

```vim
:help repl
```

## Cells

Cells are denoted by full-line comments that begin with the characters `%%`.

Comments are identified by your buffer's filetype's `'commentstring'`.

See some examples below:

### Python

```python
# %%
print("I am the first cell")
print("I am still the first cell")

# %% anything can follow
print("I am the second cell")
print("I am still the second cell")
print("I am still, still the second cell")
# %%

print("I am the third cell")
```

### Haskell

```haskell
-- %%
putStrLn "I am the first cell"
putStrLn "I am still the first cell"

-- %% anything can follow
putStrLn "I am the second cell"
putStrLn "I am still the second cell"
putStrLn "I am still, still the second cell"
-- %%

putStrLn "I am the third cell"
```

## FAQ

### Escape doesn't work in Terminal mode

If you find yourself in Terminal mode, use `<C-\><C-n>` instead of `<Esc>` to return to Normal mode.

Type `:help Terminal-mode` and `:help CTRL-\_CTRL-N` for more information.

## Written by

- [Samuel Roeca](https://samroeca.com/)
- [A Cup of Air](https://acupofair.github.io/)
