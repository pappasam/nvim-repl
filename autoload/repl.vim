""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" OriginalAuthor: Samuel Roeca
" Maintainer:     Samuel Roeca samuel.roeca@gmail.com
" Description:    nvim-repl: configure and work with a repl
" License:        MIT License
" Website:        https://github.com/pappasam/nvim-repl
" License:        MIT
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! repl#warning(msg)
  echohl WarningMsg
  echom 'repl: ' . a:msg
  echohl None
endfunction

let s:active_repls = {} " type: {jobid: [filepath, repl]}

function! s:cleanup(bufnr) abort
  let job_id = getbufvar(str2nr(a:bufnr), 'repl_id_job', 0)
  if !job_id
    return
  endif
  call jobstop(job_id)
  let repl_windows = filter(getwininfo(), {_, v -> get(get(getbufinfo(v.bufnr)[0], 'variables', {}), 'terminal_job_id', '') == job_id})
  let current_window_id = win_getid()
  for win in repl_windows
    call win_gotoid(win.winid)
    quit
  endfor
  unlet s:active_repls[job_id]
  echom 'repl: closed!'
endfunction

function! s:repl_reset_visual_position()
  let repl_windows = filter(getwininfo(), {_, v -> get(get(getbufinfo(v.bufnr)[0], 'variables', {}), 'terminal_job_id', '') == b:repl_id_job})
  let current_window_id = win_getid()
  for win in repl_windows
    call win_gotoid(win.winid)
    call cursor(line('$'), 0)
  endfor
  call win_gotoid(current_window_id)
endfunction

function! s:repl_id_job_exists()
  if !exists('b:repl_id_job')
    return 0
  endif
  try
    call jobpid(b:repl_id_job)
    return 1
  catch /.*/
    return 0
  endtry
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
  silent! execute line_end + 1
  return lines
endfunction

function! s:get_repl_from_config()
  let config = get(g:repl_filetype_commands, &filetype, g:repl_default)
  let t_config = type(config)
  if t_config == v:t_string
    return #{cmd: config, prefix: '', suffix: ''}
  elseif t_config == v:t_dict
    return #{cmd: config.cmd, prefix: get(config, 'prefix', ''), suffix: get(config, 'suffix', '')}
  else
    throw 'nvim-repl config for ' .. &filetype .. 'is neither a String nor a Dict'
  endif
endfunction

function! s:dequote(str)
  return substitute(a:str, '^["'']\(.*\)["'']$', '\1', '')
endfunction

function! repl#open(...)
  if s:repl_id_job_exists()
    call repl#warning('already open. To close existing repl, run ":ReplClose"')
    return
  endif
  let current_window_id = win_getid()
  if a:0 > 0
    let repl = #{cmd: a:1, prefix: s:dequote(get(a:, 2, '')), suffix: s:dequote(get(a:, 3, ''))}
  else
    let repl = s:get_repl_from_config()
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
  let old_shell = &shell
  if old_shell == 'powershell'
    set shell=cmd
  endif
  let id_job = termopen(repl.cmd)
  let b:repl_id_job = id_job " set in terminal buffer
  setlocal nonumber nornu nobuflisted
  autocmd BufHidden <buffer> call s:cleanup(expand('<abuf>'))
  call win_gotoid(current_window_id)
  let b:repl_id_job = id_job " set in repl buffer
  let b:repl = repl
  let &shell = old_shell
  let s:active_repls[id_job] = [expand('%:.'), repl]
  echom 'repl: opened!'
endfunction

function! repl#attach()
  let inputs_tail = []
  let inputs = ['Select repl:']
  let jobs = []
  for [jobid, value] in items(s:active_repls)
    call add(inputs_tail, '(jobid ' .. jobid .. ') opened by ' .. value[0])
    call add(jobs, [str2nr(jobid), value[1]])
  endfor
  call sort(inputs_tail)
  call sort(jobs)
  call map(inputs_tail, '  (v:key + 1) .. ". " .. v:val')
  call extend(inputs, inputs_tail)
  if len(inputs) == 0
    echom 'repl: no open repls, cannot attach'
    return
  endif
  let choice = inputlist(inputs)
  redraw!
  if choice > len(jobs) || choice < 1
    echom 'repl: no valid choice selected, not attatched'
    return
  endif
  let b:repl_id_job = jobs[choice - 1][0]
  let b:repl = jobs[choice - 1][1]
  echom 'repl: attached'
endfunction

function! repl#close()
  set lazyredraw
  let repl_windows = filter(getwininfo(), {_, v -> get(get(getbufinfo(v.bufnr)[0], 'variables', {}), 'terminal_job_id', '') == b:repl_id_job})
  let current_window_id = win_getid()
  for win in repl_windows
    call win_gotoid(win.winid)
    quit
  endfor
  call win_gotoid(current_window_id)
  set nolazyredraw
  redraw
endfunction

function! repl#toggle()
  if !s:repl_id_job_exists()
    call repl#open()
  else
    call repl#close()
  endif
endfunction

function! repl#noop(...)
  return
endfunction

function! repl#sendline(...)
  if !s:repl_id_job_exists()
    call repl#warning('no repl currently open. Run ":ReplOpen" first')
    return
  endif
  call repl#sendblock(line('.'), line('.'), 'n')
  normal! j0
endfunction

function! repl#sendvisual(mode)
  if !s:repl_id_job_exists()
    call repl#warning('no repl currently open. Run ":ReplOpen" first')
    return
  endif
  call repl#sendblock('not applicable', 'not applicable', a:mode)
endfunction

function! repl#sendblock(firstline_num, lastline_num, mode)
  if !s:repl_id_job_exists()
    call repl#warning('no repl currently open. Run ":ReplOpen" first')
    return
  endif
  let buflines_raw = a:mode ==? 'v' || a:mode == "\<c-v>"
        \ ? s:get_visual_selection(a:mode)
        \ : getbufline(bufnr('%'), a:firstline_num, a:lastline_num)
  let buflines_chansend = []
  if b:repl.prefix != ''
    call add(buflines_chansend, b:repl.prefix)
  endif
  for line in buflines_raw
    if line != "" && line !~ "^\\s*#\\s*%%.*"
      let buflines_chansend += [line] " remove the empty line and #%% line
    endif
  endfor
  if b:repl.suffix != ''
    call add(buflines_chansend, b:repl.suffix)
  endif
  if len(buflines_chansend) > 0 && buflines_chansend[-1] =~ "^\\s\\+.*"
    let buflines_chansend += ["", ""] " If last line has leading whitespace, add 2 lines
  else
    let buflines_chansend += [""] " Otherwise, add 1
  endif
  call chansend(b:repl_id_job, buflines_chansend)
  call s:repl_reset_visual_position()
endfunction

function! repl#sendargs(cmd_args)
  if !s:repl_id_job_exists()
    call repl#open() " If there is no repl window opened, create one
  endif
  call chansend(b:repl_id_job, [a:cmd_args, ""])
endfunction

function! repl#sendcell(...)
  if !s:repl_id_job_exists()
    call repl#warning('no repl currently open. Run ":ReplOpen" first')
    return
  endif
  " This supports single-line comments with only a prefix (lije '## %s') and
  " comments that fully surround (like '<!-- %s -->'). commentstring is
  " escaped for compatibility with regex matching
  let cell_pattern = "^\\s*" .. substitute(escape(&commentstring, '^$.*[]~\/&'), '%s', "\\s*%%.*", '')
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
endfunction

function! repl#newcell()
  if getline('.') =~ '^\s*$' && (line('.') == 1 || getline(line('.') - 1) =~ '^\s*$')
    silent call setline('.', substitute(&commentstring, '%s', '%%', ''))
    silent put =['','']
  else
    silent execute "put =['','" .. substitute(&commentstring, '%s', '%%', '') .. "','','']"
  endif
endfunction

function! repl#clear()
  if !s:repl_id_job_exists()
    call repl#warning('no repl currently open. Run ":ReplOpen" first')
    return
  endif
  call chansend(b:repl_id_job, "\<c-l>")
endfunction
