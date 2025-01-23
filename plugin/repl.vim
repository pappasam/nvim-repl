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
  let g:repl_filetype_commands = extendnew(
        \ s:default_commands,
        \ g:repl_filetype_commands,
        \ )

  if !exists('g:repl_default')
    let g:repl_default = #{cmd: &shell, prefix: '', suffix: ''}
  elseif type(g:repl_default) == v:t_dict
    let g:repl_default = extendnew(#{cmd: &shell, prefix: '', suffix: ''}, g:repl_default)
  elseif type(g:repl_default) != v:t_string
    throw 'g:repl_default must be a String or a Dict'
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
if !s:cmd_exists(':ReplAttach')
  command! ReplAttach call repl#attach()
endif
if !s:cmd_exists('ReplClose')
  command! ReplClose call repl#close()
endif
if !s:cmd_exists(':ReplToggle')
  command! ReplToggle call repl#toggle()
endif
if !s:cmd_exists(':ReplNewCell')
  command! ReplNewCell call repl#newcell()
endif
if !s:cmd_exists(':ReplRunCell')
  command! ReplRunCell call repl#sendcell()
endif
if !s:cmd_exists('ReplClear')
  command! ReplClear call repl#clear()
endif
if !s:cmd_exists('ReplSendArgs')
  command! -nargs=1 ReplSendArgs call repl#sendargs(<f-args>)
endif

" Pluggable mappings

nnoremap <silent> <Plug>(ReplSendLine) <Cmd>execute 'set operatorfunc=repl#noop'<CR><Cmd>call repl#sendline()<CR>g@l<Cmd>execute 'set operatorfunc=repl#sendline'<CR>
nnoremap <silent> <Plug>(ReplSendCell) <Cmd>execute 'set operatorfunc=repl#noop'<CR><Cmd>call repl#sendcell()<CR>g@l<Cmd>execute 'set operatorfunc=repl#sendcell'<CR>
xnoremap <silent> <Plug>(ReplSendVisual) <Cmd>execute 'set operatorfunc=repl#noop'<CR>:<C-u>call repl#sendvisual(visualmode())<CR>g@l<Cmd>execute 'set operatorfunc=repl#sendline'<CR>

" Below mappings are deprecated and undocumented, moving to syntax with surrounding parentheses

nnoremap <silent> <Plug>ReplSendLine <Cmd>execute 'set operatorfunc=repl#noop'<CR><Cmd>call repl#sendline()<CR>g@l<Cmd>execute 'set operatorfunc=repl#sendline'<CR>
nnoremap <silent> <Plug>ReplSendCell <Cmd>execute 'set operatorfunc=repl#noop'<CR><Cmd>call repl#sendcell()<CR>g@l<Cmd>execute 'set operatorfunc=repl#sendcell'<CR>
xnoremap <silent> <Plug>ReplSendVisual <Cmd>execute 'set operatorfunc=repl#noop'<CR>:<C-u>call repl#sendvisual(visualmode())<CR>g@l<Cmd>execute 'set operatorfunc=repl#sendline'<CR>

" Finish

try
  call s:configure_constants()
catch /.*/
  call repl#warning(v:exception)
finally
  let &cpo = s:save_cpo
  unlet s:save_cpo
endtry
