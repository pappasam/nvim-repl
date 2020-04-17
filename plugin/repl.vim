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

function! s:warning(msg)
  echohl WarningMsg
  echom 'repl: ' . a:msg
  echohl None
endfunction

function! s:exists(name)
  let _exists = exists(a:name)
  if _exists
    call s:warning(printf('cannot define "%s"; already defined', a:name))
  endif
  return _exists
endfunction

" Configuration:

let s:default_commands = {
      \ 'python': 'python',
      \ }

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
endfunction

" Commands

if !s:exists(':Repl')
  command! -nargs=? -complete=shellcmd Repl call repl#open(<f-args>)
endif
if !s:exists(':ReplOpen')
  command! -nargs=? -complete=shellcmd ReplOpen call repl#open(<f-args>)
endif
if !s:exists('ReplClose')
  command! ReplClose call repl#close()
endif
if !s:exists(':ReplToggle')
  command! ReplToggle call repl#toggle()
endif
if !s:exists(':ReplSend')
  command! -range ReplSend <line1>,<line2>call repl#send()
endif
if !s:exists('ReplClear')
  command! ReplClear call repl#clear()
endif

" Pluggable mappings

nnoremap <script> <silent> <Plug>ReplSendLine
      \ :ReplSend<CR>
      \ :call repeat#set("\<Plug>ReplSendLine", v:count)<CR>hj

" visual selection sets up normal mode command for repetition
vnoremap <script> <silent> <Plug>ReplSendVisual
      \ :ReplSend<CR>
      \ :call repeat#set("\<Plug>ReplSendLine", v:count)<CR>gv<esc>j

" Finish

try
  call s:configure_constants()
catch /.*/
  call s:warning(v:exception)
finally
  let &cpo = s:save_cpo
  unlet s:save_cpo
endtry
