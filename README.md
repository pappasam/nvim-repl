# nvim-repl

Create, use, and remove an [interactive repl](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop) within Neovim.

This plugin uses a Neovim-specific api and is only intended to be used with the latest version of Neovim (0.5.0+). To see if your Neovim is compatible, run:

```bash
nvim --version
```

2 dot-repeatable pluggable mappings are provided.

## :tea: Installation

If using [vim-plug](https://github.com/junegunn/vim-plug), place the following line in the Plugin section of your init.vim / vimrc:

```vim
Plug 'pappasam/nvim-repl'
```

Then run the Ex command:

```vim
:PlugInstall
```

I personally use [vim-packager](https://github.com/kristijanhusak/vim-packager), so if you'd like to go down the "package" rabbit hole, I suggest giving that a try.

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

## :toolbox: Usage

![demo](images/nvim-repl-demo.gif)

- `:Repl` or `:ReplOpen`
- _without arg_: open the default shell which is configured by filetype
- `:Repl env $env_name`:open a python shell with the enviorment of $env_name, only support for [conda](https://www.anaconda.com/)
- `:Repl arg`: open the default shell and exec the `arg` command
- `:ReplClose`: close the repl, if open.
- `:ReplToggle`: if repl is open, close it. If repl is closed, open it using either the filetype-associated repl or the configured default repl.
- `:ReplClear`: clear the repl, if open.
- `:ReplRunCell`: will run the cell under the cursor and the cursor will jump to next cell

## :book: Full Documentation

From within Neovim, type:

```vim
:help repl
```

## :keyboard: Key mappings

Two pluggable mappings are provided.

- `<Plug>ReplSendLine` send the current line to the repl.
- `<Plug>ReplSendVisual` send the visual selection to the repl.

The user should map these pluggable mappings. Example mappings in config using vim filetype:

```vim
nnoremap <leader>rt :ReplToggle<CR>
nnoremap <leader>rc :ReplRunCell<CR>
nmap <leader>rr <Plug>ReplSendLine
xmap <leader>rr <Plug>ReplSendVisual
```

## :gear: Configurations

Use `g:repl_filetype_commands` to map Neovim filetypes to repls. Eg, if you automatically want to run a "ipython" repl for python filetypes and a "node" repl for JavaScript filetypes, your configuration might look like this:

```vim
let g:repl_filetype_commands = {
  \ 'javascript': 'node',
  \ 'python': 'ipython --no-autoindent',
  \ }
```

**:warning:notice: ipython config**

- You should `pip install ipython` firstly, then `let g:repl_filetype_commands = {'python': 'ipython'}`

Use `g:repl_default` to set the default repl if no configured repl is found in `g:repl_filetype_commands`. Defaults to `&shell`.

Use `g:repl_split` to set the repl window position. `vertical` and `horizontal` respect the user-configured global splitright and splitbottom settings.

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

Use `g:repl_height` to set repl window's height (number of lines) if `g:repl_split` set `'bottom'`/`'top'`. Default will split equally.

Use `g:repl_width` to set repl window's width (number of columns) if `g:repl_split` set `'left'`/`'right'`. Default will vsplit equally.

## :question: FAQ

### Getting strange errors with Python, please help

One such error might be an `IndentError`. This has to do with quirks related to the default Python interpreter. To get around this, I suggest using [bpython](https://github.com/bpython/bpython) as your default interpreter for Python files. To do this, do the following.

```bash
pip install bpython
```

In your vimrc:

```vim
let g:repl_filetype_commands = {
  \ 'python': 'bpython -q',
  \ }
```

### Escape doesn't work in Terminal mode

If you find yourself in Terminal mode, use `<C-\><C-n>` instead of `<Esc>` to return to Normal mode.

Type `:help Terminal-mode` and `:help CTRL-\_CTRL-N` for more information.

## :small_airplane: Written by

- [Samuel Roeca](https://samroeca.com/)
- [A Cup of Air](https://acupofair.github.io/)
