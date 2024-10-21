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

function! s:get_visual_selection(mode) " https://stackoverflow.com/a/61486601
  if a:mode !=? 'v' && a:mode !=? "\<c-v>"
    throw 'Mode "' .. a:mode .. '" is not a valid Visual mode.'
  endif
  let [line_start, column_start] = getpos("'<")[1:2]
  let [line_end, column_end] = getpos("'>")[1:2]
  let lines = getline(line_start, line_end)
  if a:mode ==# 'v'
    let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][column_start - 1:]
  elseif a:mode ==? "\<c-v>"
    for i in range(len(lines))
      let lines[i] = lines[i][column_start - 1: column_end - (&selection == 'inclusive' ? 1 : 2)]
    endfor
  endif
  return lines
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
      " TODO: support more editors than conda
      let command = 'conda activate ' .. func_args[1] .. ' & ' .. command
    endif
  endif
  if g:repl_split == 'vertical'
    execute 'vertical ' . g:repl_width .. 'split new'
  elseif g:repl_split == 'left'
    execute 'leftabove vertical ' .. g:repl_width .. 'split new'
  elseif g:repl_split == 'right'
    execute 'rightbelow vertical ' .. g:repl_width .. 'split new'
  elseif g:repl_split == 'horizontal'
    execute g:repl_height .. 'split new'
  elseif g:repl_split == 'bottom'
    execute 'rightbelow ' .. g:repl_height .. 'split new'
  elseif g:repl_split == 'top'
    execute 'leftabove ' .. g:repl_height .. 'split new'
  else
    throw 'Something went wrong, file issue with https://github.com/pappasam/nvim-repl...'
  endif
  let s:old_shell = &shell
  if s:old_shell == 'powershell'
    set shell=cmd
  endif
  let s:id_job = termopen(command)
  let s:id_window = win_getid()
  call s:setup()
  call win_gotoid(current_window_id)
  let &shell=s:old_shell
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

function! repl#noop(...)
  return
endfunction

function! repl#sendline(...)
  if s:id_window == v:false
    call repl#warning('no repl currently open. Run ":ReplOpen" first')
    return
  endif
  call repl#sendblock(line('.'), line('.'), 'n')
  normal! j0
endfunction

function! repl#sendvisual(mode)
  if s:id_window == v:false
    call repl#warning('no repl currently open. Run ":ReplOpen" first')
    return
  endif
  call repl#sendblock('not applicable', 'not applicable', a:mode)
endfunction

function! repl#sendblock(firstline_num, lastline_num, mode)
  if s:id_window == v:false
    call repl#open() " If there is no repl window opened, create one
  endif
  let buflines_raw = a:mode ==? 'v' || a:mode == "\<c-v>"
        \ ? s:get_visual_selection(a:mode)
        \ : getbufline(bufnr('%'), a:firstline_num, a:lastline_num)
  let buflines_chansend = []
  for line in buflines_raw
    if line != "" && line !~ "^\\s*#\\s*%%.*"
      let buflines_chansend += [line] " remove the empty line and #%% line
    endif
  endfor
  if len(buflines_chansend) > 0 && buflines_chansend[-1] =~ "^\\s\\+.*"
    let buflines_chansend += ["", ""] " If last line has leading whitespace, add 2 lines
  else
    let buflines_chansend += [""] " Otherwise, add 1
  endif
  call chansend(s:id_job, buflines_chansend)
  let current_window_id = win_getid()
  call win_gotoid(s:id_window)
  call cursor(line('$'), 0)
  call win_gotoid(current_window_id)
endfunction

function! repl#sendargs(cmd_args)
  if s:id_window == v:false
    call repl#open() " If there is no repl window opened, create one
  endif
  call chansend(s:id_job, [a:cmd_args, ""])
endfunction

function! repl#sendcell(...)
  " This supports single-line comments with only a prefix (lije '## %s') and
  " comments that fully surround (like '<!-- %s -->')
  let cell_pattern = "^\\s*" .. substitute(&commentstring, '%s', "\\s*%%.*", '')
  let cur_line_num = line('.')
  let find_begin_line = 0
  while cur_line_num > 0 && !find_begin_line
    let cur_line = getline(cur_line_num)
    if cur_line =~ cell_pattern
      let cell_begin_line_num = cur_line_num
      let find_begin_line = 1
    endif
    let cur_line_num -= 1
  endwhile
  if !find_begin_line
    let cell_begin_line_num = 1
  endif
  let cur_line_num = line('.') + 1
  let find_end_line = 0
  while cur_line_num <= line('$') && !find_end_line
    let cur_line = getline(cur_line_num)
    if cur_line =~ cell_pattern
      let cell_end_line_num = cur_line_num - 1
      let find_end_line = 1
    endif
    let cur_line_num += 1
  endwhile
  if !find_end_line
    let cell_end_line_num = line('$')
    call cursor(cell_end_line_num, 0)
  else
    call cursor(cell_end_line_num + 1, 0)
  endif
  " add 1 to avoid sending the commented line itself to the repl
  call repl#sendblock(cell_begin_line_num + 1, cell_end_line_num, mode())
  call chansend(s:id_job, ["\<CR>"]) "emulate <enter> key in ipython
endfunction

function! repl#clear()
  if s:id_window == v:false
    call repl#warning('no repl currently open. Run ":ReplOpen" first')
    return
  endif
  call chansend(s:id_job, "\<c-l>")
endfunction
