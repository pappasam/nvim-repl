# nvim-repl

Create, use, and remove an [interactive repl](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop) within Neovim.

This plugin uses a Neovim-specific api and is only intended to be used with the latest version of Neovim (0.5.0+).

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

Two pluggable mappings are provided. They rely on the latest version of Tim Pope's vim-repeat: https://github.com/tpope/vim-repeat.

`<Plug>ReplSendLine` send the current line to the repl. Only mappable in normal mode.

`<Plug>ReplSendVisual` send the visual selection to the repl. Only mappable in visual mode.

The user should map these pluggable mappings. Example mappings:

```vim
nnoremap <leader><leader>e :ReplToggle<CR>
nmap <leader>e <Plug>ReplSendLine
vmap <leader>e <Plug>ReplSendVisual
```

## Configurations

Use `g:repl_filetype_commands` to map Neovim filetypes to repls. Eg, if you automatically want to run a "python" repl for python filetypes and a "node" repl for javascript filetypes, your configuration might look like this:

```vim
let g:repl_filetype_commands = {
    \ 'javascript': 'node',
    \ 'python': 'python',
    \ }
```

Use `g:repl_default` to set the default repl if no configured repl is found in `g:repl_filetype_commands`. Defaults to `&shell`.

## Commands

`:Repl` or `:ReplOpen`: open the repl. Takes the name of an executable repl as an optional argument. If no argument is provided, defaults to either the filetype-associated repl or the configured default repl.

`:ReplClose`: close the repl, if open.

`:ReplToggle`: if repl is open, close it. If repl is closed, open it using either the filetype-associated repl or the configured default repl.

## Notes

This plugin prioritizes simplicity and ease of use on a POSIX-compliant system. Support for Windows and other non-Unix derivatives is out of scope.

## Written by

Samuel Roeca _samuel.roeca@gmail.com_
