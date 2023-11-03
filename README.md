# Neovim REPL

Create, use, and remove an [interactive REPL](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop) within Neovim 0.5.0+.

## :tea: Installation

If you use [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "pappasam/nvim-repl",
  init = function()
    vim.g["repl_filetype_commands"] = {
      javascript = "node",
      python = "ipython --no-autoindent"
    }
  end,
  keys = {
    { "<leader>rt", "<cmd>ReplToggle<cr>", desc = "Toggle nvim-repl" },
    { "<leader>rc", "<cmd>ReplRunCell<cr>", desc = "nvim-repl run cell" },
  },
}
```

For other package management tools, please consult their documentation.

## :toolbox: Usage

![demo](images/nvim-repl-demo.gif)

- `:Repl` or `:ReplOpen`
- _without argument_: open the default shell which is configured by filetype
- `:Repl env $env_name`:open a python shell with the environment of `$env_name`, only support for [Conda](https://www.anaconda.com/)
- `:Repl arg`: open the default shell and exec the `arg` command
- `:ReplClose`: close the REPL, if open.
- `:ReplToggle`: if REPL is open, close it. If REPL is closed, open it using either the filetype associated REPL or the configured default REPL.
- `:ReplClear`: clear the REPL, if open.
- `:ReplRunCell`: will run the cell under the cursor and the cursor will jump to next cell

Several pluggable, dot-repeatable mappings are provided.

- `<Plug>ReplSendLine` send the current line to the REPL.
- `<Plug>ReplSendCell` send the current cell to the REPL.
- `<Plug>ReplSendVisual` send the visual selection to the REPL.

The user should map these pluggable mappings. Example mappings in config using vim filetype:

```vim
nnoremap <Leader>rt <Cmd>ReplToggle<CR>
nmap     <Leader>rc <Plug>ReplSendCell
nmap     <Leader>rr <Plug>ReplSendLine
xmap     <Leader>r  <Plug>ReplSendVisual
```

## :gear: Configurations

Use `g:repl_filetype_commands` to map Neovim file types to REPL. E.g., if you automatically want to run a `ipython` REPL for python file types and a "node" REPL for JavaScript file types, your configuration might look like this:

```vim
let g:repl_filetype_commands = {
  \ 'javascript': 'node',
  \ 'python': 'ipython --no-autoindent',
  \ }
```

**:warning:notice: `ipython` config**

- You should `pip install ipython` firstly, then `let g:repl_filetype_commands = {'python': 'ipython'}`

Use `g:repl_default` to set the default REPL if no configured REPL is found in `g:repl_filetype_commands`. Defaults to `&shell`.

Use `g:repl_split` to set the REPL window position. `vertical` and `horizontal` respect the user-configured global `splitright` and `splitbottom` settings.

- `'bottom'`
- `'top'`
- `'left'`
- `'right'`
- `'horizontal'`
- `'vertical'` (default)

If split bottom is preferred, then add below line to configuration.

```vim
let g:repl_split = 'bottom'
```

- `g:repl_height` to set REPL window's height (number of lines) if `g:repl_split` set `'bottom'`/`'top'`. Default `split` equally.
- `g:repl_width` to set REPL window's width (number of columns) if `g:repl_split` set `'left'`/`'right'`. Default `vsplit` equally.

## :book: Full Documentation

From within Neovim, type:

```vim
:help repl
```

## :question: FAQ

### Getting strange errors with Python, please help

One such error might be a `IndentError`. This has to do with quirks related to the default Python interpreter. To get around this, use [`ipython`](https://github.com/ipython/ipython) as your default interpreter for Python files.

Terminal:

```bash
pip install ipython
```

`init.vim`:

```vim
" init.vim
let g:repl_filetype_commands = {'python': 'ipython --no-autoindent'}
```

### Escape doesn't work in Terminal mode

If you find yourself in Terminal mode, use `<C-\><C-n>` instead of `<Esc>` to return to Normal mode.

Type `:help Terminal-mode` and `:help CTRL-\_CTRL-N` for more information.

## :small_airplane: Written by

- [Samuel Roeca](https://samroeca.com/)
- [A Cup of Air](https://acupofair.github.io/)
