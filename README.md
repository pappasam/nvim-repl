# nvim-repl

Create, use, and remove an [interactive repl](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop) within Neovim.

This plugin uses a Neovim-specific api and is only intended to be used with the latest version of Neovim (0.5.0+). To see if your Neovim is compatible, run:

```bash
nvim --version
```

2 pluggable mappings are provided; they rely on the latest version of Tim Pope's [vim-repeat](https://github.com/tpope/vim-repeat).

## Installation

If using [vim-plug](https://github.com/junegunn/vim-plug), place the following line in the Plugin section of your init.vim / vimrc:

```vim
Plug 'tpope/vim-repeat'
Plug 'pappasam/nvim-repl'
```

Then run the Ex command:

```vim
:PlugInstall
```

I personally use [vim-packager](https://github.com/kristijanhusak/vim-packager), so if you'd like to go down the "package" rabbit hole, I suggest giving that a try.

## Full Documentation

From within Neovim, type:

```vim
:help repl
```

## Key mappings

Two pluggable mappings are provided. They rely on the latest version of Tim Pope's vim-repeat.

`<Plug>ReplSendLine` send the current line to the repl. Only mappable in normal mode.

`<Plug>ReplSendVisual` send the visual selection to the repl. Only mappable in visual mode.

The user should map these pluggable mappings. Example mappings:

```vim
nnoremap <leader><leader>e :ReplToggle<CR>
nmap <leader>e <Plug>ReplSendLine
vmap <leader>e <Plug>ReplSendVisual
```

## Configurations

Use `g:repl_filetype_commands` to map Neovim filetypes to repls. Eg, if you automatically want to run a "python" repl for python filetypes and a "node" repl for JavaScript filetypes, your configuration might look like this:

```vim
let g:repl_filetype_commands = {
    \ 'javascript': 'node',
    \ 'python': 'python',
    \ }
```

**notice: ipython config**

- You should `pip install ipython` firstly, then `let g:repl_filetype_commands = {'python': 'ipython'}`
- If the code in your ipython shell has error indent, please try `let g:repl_filetype_commands = {'python': 'ipython --no-autoindent'}`

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

## Commands

`:Repl` or `:ReplOpen`:

- open the repl. Takes the name of an executable repl as an optional argument. If no argument is provided, defaults to either the filetype-associated repl or the configured default repl.
- python virual env integrated(only support for [conda](https://www.anaconda.com/)): `:Repl env $env_name`

`:ReplClose`: close the repl, if open.

`:ReplToggle`: if repl is open, close it. If repl is closed, open it using either the filetype-associated repl or the configured default repl.

`:ReplClear`: clear the repl, if open.

## Notes

This plugin prioritizes simplicity and ease of use on a POSIX-compliant system. Support for Windows and other non-Unix derivatives is out of scope.

## FAQ

### Getting strange errors with Python, please help

One such error might be an `IndentError`. This has to do with quirks related to the default Python interpreter. To get around this, I suggest using [bpython](https://github.com/bpython/bpython) as your default interpreter for Python files. To do this, do the following.

```shell
pip install bpython
```

In your vimrc:

```vim
let g:repl_filetype_commands = {
      \ 'python': 'bpython -q',
      \ }
```

## Written by

[Samuel Roeca](https://samroeca.com/)
[A Cup of Air](https://acupofair.github.io/)
