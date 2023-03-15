""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" OriginalAuthor: Samuel Roeca
" Maintainer:     Samuel Roeca samuel.roeca@gmail.com
" Description:    nvim-repl: configure and work with a repl
" License:        MIT License
" Website:        https://github.com/pappasam/nvim-repl
" License:        MIT
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:id_window = v:false
let s:id_job = v:false

function! repl#warning(msg)
  echohl WarningMsg
  echom 'repl: ' . a:msg
  echohl None
endfunction

function! s:cleanup()
  call jobstop(s:id_job)
  let s:id_window = v:false
  let s:id_job = v:false
  echom 'repl: closed!'
endfunction

function! s:setup()
  setlocal nonumber nornu nobuflisted
  autocmd WinClosed <buffer> call s:cleanup()
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

function! repl#open(...)
  if s:id_window != v:false
    call repl#warning('already open. To close existing repl, run ":ReplClose"')
    return
  endif
  let current_window_id = win_getid()
  let func_args = a:000

  if len(func_args) == 1
    let command = func_args[0]
  else "The num of args is 0 or 2
    let command = get(g:repl_filetype_commands, &filetype, g:repl_default)
    if len(func_args) == 2 && func_args[0] == 'env'
      " [TODO) I only use conda to manage my virual env, others should be
      " another command
      let command = 'conda activate '. func_args[1].' & '. command
    endif
  endif

  if g:repl_split == 'vertical'
    execute 'vertical ' . g:repl_width . 'split new'
  elseif g:repl_split == 'left'
    execute 'leftabove vertical ' . g:repl_width . 'split new'
  elseif g:repl_split == 'right'
    execute 'rightbelow vertical ' . g:repl_width . 'split new'
  elseif g:repl_split == 'horizontal'
    execute g:repl_height . 'split new'
  elseif g:repl_split == 'bottom'
    execute 'rightbelow ' . g:repl_height . 'split new'
  elseif g:repl_split == 'top'
    execute 'leftabove ' . g:repl_height . 'split new'
  else
    throw 'Something went wrong, file issue with https://github.com/pappasam/nvim-repl...'
  endif
  let s:id_job = termopen(command)
  let s:id_window = win_getid()
  call s:setup()
  call win_gotoid(current_window_id)
  echom 'repl: opened!'
endfunction

function! repl#close()
  let current_window_id = win_getid()
  call win_gotoid(s:id_window)
  quit
  call win_gotoid(current_window_id)
endfunction

function! repl#toggle()
  if s:id_window == v:false
    call repl#open()
  else
    call repl#close()
  endif
endfunction

function! repl#send() range
  if s:id_window == v:false
    call repl#warning('no repl currently open. Run ":ReplOpen" first')
    return
  endif
  call repl#send_block(a:firstline, a:lastline)
  " call repl#SendLines(l:cell_begin_line_num, l:cell_end_line_num)
  " echom l:cell_begin_line_num l:cell_end_line_num
  " echom 'repl: run range successly!'
endfunction

function! repl#send_block(firstline_num, lastline_num)
  "If there is no repl window opened, create one
  if s:id_window == v:false
    call repl#open()
  endif

  let buflines_raw = getbufline(bufnr('%'), a:firstline_num, a:lastline_num)
  let buflines_chansend = []
  for line in buflines_raw
    " remove the empty line and #%% line
    if line != "" && line !~ "^\\s*#\\s*%%.*"
      let buflines_chansend += [line]
    endif
  endfor
  call chansend(s:id_job, buflines_chansend)

  "Func: Adjust the cursor location to the last of the output
  let current_window_id = win_getid()
  call win_gotoid(s:id_window)
  call cursor(line('$'), 0)
  call win_gotoid(current_window_id)
endfunction

function! repl#run_cell()
  let l:cur_line_num = line('.')
  let l:find_begin_line = 0
  while l:cur_line_num > 0 && !l:find_begin_line
    let l:cur_line = getline(l:cur_line_num)
    if l:cur_line =~ "^\\s*#\\s*%%.*"
      let l:cell_begin_line_num = l:cur_line_num
      let l:find_begin_line = 1
    endif
    let l:cur_line_num -= 1
  endwhile
  if !l:find_begin_line
    let l:cell_begin_line_num = 1
  endif

  let l:cur_line_num = line('.') + 1
  let l:find_end_line = 0
  while l:cur_line_num <= line('$') && !l:find_end_line
    let l:cur_line = getline(l:cur_line_num)
    if l:cur_line =~ "^\\s*#\\s*%%.*"
      let l:cell_end_line_num = l:cur_line_num - 1
      let l:find_end_line = 1
    endif
    let l:cur_line_num += 1
  endwhile
  if !l:find_end_line
    let l:cell_end_line_num = line('$')
    call cursor(l:cell_end_line_num, 0)
  else
    call cursor(l:cell_end_line_num + 1, 0)
  endif

  call repl#send_block(l:cell_begin_line_num, l:cell_end_line_num)

  "emulate the <enter> key in ipython
  call chansend(s:id_job, ["\<CR>"])

endfunction

function! repl#clear()
  if s:id_window == v:false
    call repl#warning('no repl currently open. Run ":ReplOpen" first')
    return
  endif
  call chansend(s:id_job, "\<c-l>")
endfunction
