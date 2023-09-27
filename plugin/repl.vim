""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" OriginalAuthor: Samuel Roeca
" Maintainer:     Samuel Roeca samuel.roeca@gmail.com
" Description:    nvim-repl: configure and work with a repl
" License:        MIT License
" Website:        https://github.com/pappasam/nvim-repl
" License:        MIT
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Setup:

if exists("g:loaded_repl")
  finish
endif
let g:loaded_repl = v:true
let s:save_cpo = &cpo
set cpo&vim

function! s:cmd_exists(name)
  let _exists = exists(a:name) == 2
  if _exists
    call repl#warning(printf('cannot define "%s"; already defined', a:name))
  endif
  return _exists
endfunction

" Configuration:

let s:default_commands = {
      \ 'python': 'python',
      \ }

let s:allowed_split_values = [
      \ 'vertical',
      \ 'horizontal',
      \ 'top',
      \ 'left',
      \ 'right',
      \ 'bottom',
      \ ]

" User configuration

function! s:configure_constants()
  if !exists('g:repl_filetype_commands')
    let g:repl_filetype_commands = {}
  elseif type(g:repl_filetype_commands) != v:t_dict
    throw 'g:repl_filetype_commands must be Dict'
  endif
  let g:repl_filetype_commands = extend(
        \ s:default_commands,
        \ g:repl_filetype_commands,
        \ )

  if !exists('g:repl_default')
    let g:repl_default = &shell
  elseif type(g:repl_default) != v:t_string
    throw 'g:repl_default must be a String'
  endif

  if !exists('g:repl_split')
    let g:repl_split = 'vertical'
  elseif index(s:allowed_split_values, g:repl_split) == -1
    throw 'g:repl_split is not in allowed values '
          \ .. join(s:allowed_split_values, ', ')
  endif

  if !exists('g:repl_height')
    let g:repl_height = ''
  elseif type(g:repl_height) != v:t_number
    throw 'g:repl_height is configured and is not a number'
  endif

  if !exists('g:repl_width')
    let g:repl_width = ''
  elseif type(g:repl_width) != v:t_number
    throw 'g:repl_width is configured and is not a number'
  endif
endfunction

" Commands

if !s:cmd_exists(':Repl')
  command! -nargs=* -complete=shellcmd Repl call repl#open(<f-args>)
endif
if !s:cmd_exists(':ReplOpen')
  command! -nargs=* -complete=shellcmd ReplOpen call repl#open(<f-args>)
endif
if !s:cmd_exists('ReplClose')
  command! ReplClose call repl#close()
endif
if !s:cmd_exists(':ReplToggle')
  command! ReplToggle call repl#toggle()
endif
if !s:cmd_exists(':ReplSend')
  command! -range ReplSend <line1>,<line2>call repl#send(mode())
endif
if !s:cmd_exists(':ReplSendVisual')
  command! -range ReplSendVisual <line1>,<line2>call repl#send(visualmode())
endif
if !s:cmd_exists(':ReplRunCell')
  command! ReplRunCell call repl#run_cell()
endif
if !s:cmd_exists('ReplClear')
  command! ReplClear call repl#clear()
endif

" Pluggable mappings

nnoremap <script> <silent> <Plug>ReplSendLine
      \ :ReplSend<CR>
      \ :call repeat#set("\<Plug>ReplSendLine", v:count)<CR>hj

" visual selection sets up normal mode command for repetition
vnoremap <script> <silent> <Plug>ReplSendVisual
      \ :ReplSendVisual<CR>
      \ :call repeat#set("\<Plug>ReplSendLine", v:count)<CR>gv<esc>j

" Finish

try
  call s:configure_constants()
catch /.*/
  call repl#warning(v:exception)
finally
  let &cpo = s:save_cpo
  unlet s:save_cpo
endtry
