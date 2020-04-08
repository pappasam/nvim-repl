""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" OriginalAuthor: Samuel Roeca
" Maintainer:     Samuel Roeca samuel.roeca@gmail.com
" Description:    nvim-repl: configure and work with a repl
" License:        MIT License
" Website:        https://github.com/pappasam/nvim-repl
" License:        MIT
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let g:repl_filetype_commands = {
      \ 'python': 'python',
      \ }
let g:repl_defaults = '/bin/bash'

let s:id_window = v:false
let s:id_job = v:false

function! s:repl_cleanup()
  call jobstop(s:id_job)
  let s:id_window = v:false
  let s:id_job = v:false
  echom 'Repl: Closed'
endfunction

function! s:repl_setup_buffer()
  setlocal nonumber nornu nobuflisted
  nnoremap <buffer> i <NOP>
  nnoremap <buffer> a <NOP>
  nnoremap <buffer> o <NOP>
  nnoremap <buffer> I <NOP>
  nnoremap <buffer> A <NOP>
  nnoremap <buffer> O <NOP>
  nnoremap <buffer> q :q<CR>
  autocmd WinClosed <buffer> call s:repl_cleanup()
endfunction

function! s:repl_open()
  if s:id_window != v:false
    echom 'Terminal already open, aborting'
    return
  endif
  let current_window_id = win_getid()
  let command = get(g:repl_filetype_commands, &filetype, g:repl_defaults)
  if &columns >= 160
    vert new
  else
    split new
  endif
  let s:id_job = termopen(command)
  let s:id_window = win_getid()
  call s:repl_setup_buffer()
  call win_gotoid(current_window_id)
  echom 'Repl: Opened'
endfunction

function! s:repl_close()
  let current_window_id = win_getid()
  call win_gotoid(s:id_window)
  quit
  call win_gotoid(current_window_id)
endfunction

function! s:repl_toggle()
  if s:id_window == v:false
    call s:repl_open()
  else
    call s:repl_close()
  endif
endfunction

function! s:repl_reset_visual_position()
  set lazyredraw
  let current_window_id = win_getid()
  call win_gotoid(s:id_window)
  normal! G
  call win_gotoid(current_window_id)
  set nolazyredraw
  redraw
endfunction

function! s:repl_send() range
  let buflines = getbufline(bufnr('%'), a:firstline, a:lastline) + ['']
  call chansend(s:id_job, buflines)
  call s:repl_reset_visual_position()
endfunction

command! ReplOpen call s:repl_open()
command! ReplClose call s:repl_close()
command! ReplToggle call s:repl_toggle()
command! -range ReplSend <line1>,<line2>call s:repl_send()
nnoremap <script> <silent> <Plug>ReplSendLine
      \ :ReplSend<CR>
      \ :silent! call repeat#set("\<Plug>ReplSendLine", v:count)<CR>hj
