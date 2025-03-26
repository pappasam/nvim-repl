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

function! s:path_relative_to_git_root(path)
  let git_root = trim(system('git rev-parse --show-toplevel 2>/dev/null'))
  if git_root == '' || v:shell_error != 0
    throw 'not in a git repository'
  endif
  return strpart(a:path, len(git_root) + 1)  " +1 to skip the trailing slash
endfunction

function! s:buffers_in_cwd()
  let l:cwd = getcwd() .. '/'
  let l:buffers = map(
        \ filter(
        \   filter(range(0, bufnr('$')), 'buflisted(v:val)'),
        \   'fnamemodify(bufname(v:val), ":p") =~ "^" . escape(l:cwd, "\\[].$^") . ".*"'
        \ ),
        \ 'fnamemodify(bufname(v:val), ":.")'
        \ )
  return uniq(sort(l:buffers))
endfunction

function! s:buffers_in_gitroot()
  let l:git_root = trim(system('git rev-parse --show-toplevel 2>/dev/null'))
  if l:git_root == '' || v:shell_error != 0
    throw 'not in a git repository'
  endif
  let l:git_root = l:git_root .. '/'
  let l:buffers = map(
        \ filter(
        \   filter(range(0, bufnr('$')), 'buflisted(v:val)'),
        \   'fnamemodify(bufname(v:val), ":p") =~ "^" . escape(l:git_root, "\\[].$^") . ".*"'
        \ ),
        \ 'strpart(fnamemodify(bufname(v:val), ":p"), len(l:git_root))'
        \ )
  return uniq(sort(l:buffers))
endfunction

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

function! s:get_repl(config)
  let t_config = type(a:config)
  if t_config == v:t_string && len(a:config) > 0
    if a:config[0] == '#' || a:config[0] == '{'
      let parsed = eval(a:config)
      return #{cmd: parsed.cmd,
            \ repl_type: get(parsed, 'repl_type', ''),
            \ open_window: get(parsed, 'open_window', g:repl_open_window_default)}
    else
      return #{cmd: a:config,
            \ repl_type: '',
            \ open_window: g:repl_open_window_default}
    endif
  elseif t_config == v:t_dict
    return #{cmd: a:config.cmd,
          \ repl_type: get(a:config, 'repl_type', ''),
          \ open_window: get(a:config, 'open_window', g:repl_open_window_default)}
  else
    throw 'nvim-repl config for ' .. &filetype .. 'is neither a String nor a Dict'
  endif
endfunction

function! repl#open(...) " takes 0 or 1 arguments (dict)
  if s:repl_id_job_exists()
    call repl#warning('already open. To close existing repl, run ":ReplClose"')
    return
  endif
  if a:0 == 0
    let repl = s:get_repl(get(g:repl_filetype_commands, &filetype, g:repl_default))
  elseif a:0 == 1
    let repl = s:get_repl(a:1)
  else
    throw 'nvim-repl: repl#open only takes 0 or 1 arguments'
  endif
  let current_window_id = win_getid()
  execute repl.open_window
  let old_shell = &shell
  if old_shell == 'powershell'
    set shell=cmd
  endif
  if repl.repl_type == 'aider'
    let id_job = jobstart(
          \ repl.cmd .. ' ' .. join(s:buffers_in_cwd(), ' '),
          \ {'term': v:true})
  else
    let id_job = jobstart(repl.cmd, {'term': v:true})
  endif
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
  let jobs = []
  for [jobid, value] in items(s:active_repls)
    call add(inputs_tail, '(jobid ' .. jobid .. ') opened by ' .. value[0])
    call add(jobs, [str2nr(jobid), value[1]])
  endfor
  if len(jobs) == 0
    call repl#warning('no open repls, cannot attach')
    return
  elseif len(jobs) == 1
    let choice = 1
  else
    call sort(inputs_tail)
    call sort(jobs)
    call map(inputs_tail, '  (v:key + 1) .. ". " .. v:val')
    let choice = inputlist(extendnew(['Select repl:'], inputs_tail))
    redraw!
    if choice > len(jobs) || choice < 1
      call repl#warning('no valid choice selected, not attatched')
      return
    endif
  endif
  let b:repl_id_job = jobs[choice - 1][0]
  let b:repl = jobs[choice - 1][1]
  echom 'repl: attached'
endfunction

function! repl#close()
  let current_window_id = win_getid()
  let current_tab = tabpagenr()
  let current_repl_id = get(b:, 'repl_id_job', '')
  if empty(current_repl_id)
    return
  endif
  set lazyredraw
  let tab_count = tabpagenr('$')
  for t in range(1, tab_count)
    if t <= tabpagenr('$')
      execute 'tabnext ' . t
      let repl_windows = filter(getwininfo(), {_, v -> get(get(getbufinfo(v.bufnr)[0], 'variables', {}), 'terminal_job_id', '') == current_repl_id})
      for win in repl_windows
        call win_gotoid(win.winid)
        quit
      endfor
    endif
  endfor
  if current_tab <= tabpagenr('$')
    execute 'tabnext ' . current_tab
  endif
  if win_id2tabwin(current_window_id)[0] > 0
    call win_gotoid(current_window_id)
  endif
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
    call repl#attach()
  endif
  call s:send_block(line('.'), line('.'), 'n')
  normal! j0
endfunction

function! repl#sendvisual(mode)
  if !s:repl_id_job_exists()
    call repl#attach()
  endif
  call s:send_block('not applicable', 'not applicable', a:mode)
endfunction

function! s:arrow_down()
  " ANSI/VT100-compatible symbol for the Down arrow key
  return "\x1b[B"
endfunction

function! s:alt_enter()
  " Standard escape sequence for Alt+Enter
  return "\x1b\r"
endfunction

function! s:chansend_buflines(buflines)
  let buflines_chansend = a:buflines
  if b:repl.repl_type == 'ipython'
    if len(buflines_chansend) > 0 && buflines_chansend[-1] =~ "^\\s\\+.*"
      let buflines_chansend += [""] " If last line has leading whitespace, add 1 line
    endif
    if len(buflines_chansend) == 1
      call chansend(b:repl_id_job, buflines_chansend)
    else
      call chansend(b:repl_id_job, "\<C-o>")
      call chansend(b:repl_id_job, buflines_chansend)
      call chansend(b:repl_id_job, s:arrow_down())
    endif
    call chansend(b:repl_id_job, "\r")
  elseif b:repl.repl_type == 'utop'
    if len(buflines_chansend) > 0
      let buflines_chansend[-1] = buflines_chansend[-1] .. ' ;;'
    endif
    call chansend(b:repl_id_job, buflines_chansend + [""])
  elseif b:repl.repl_type == 'aider'
    if len(buflines_chansend) > 0
      let buflines_chansend[-1] = buflines_chansend[-1] .. s:alt_enter()
    endif
    call chansend(b:repl_id_job, buflines_chansend)
  else
    if len(buflines_chansend) > 0 && buflines_chansend[-1] =~ "^\\s\\+.*"
      let buflines_chansend += ["", ""] " If last line has leading whitespace, add 2 lines
    else
      let buflines_chansend += [""] " Otherwise, add 1
    endif
    call chansend(b:repl_id_job, buflines_chansend)
  endif
  call s:repl_reset_visual_position()
endfunction

function! s:send_block(firstline_num, lastline_num, mode)
  if !s:repl_id_job_exists()
    call repl#attach()
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
  call s:chansend_buflines(buflines_chansend)
endfunction

function! repl#sendargs(cmd_args)
  if !s:repl_id_job_exists()
    call repl#attach()
  endif
  call s:chansend_buflines([a:cmd_args])
endfunction

function! repl#aider_buffers(preamble) " public version
  if a:preamble != '/add' && a:preamble != '/drop'
    throw 'Unsupported command argument'
  endif
  let file_args = join(s:buffers_in_gitroot(), ' ')
  echom file_args
  call repl#sendargs(a:preamble .. ' ' .. file_args)
endfunction

function! repl#yolo()
  if !s:repl_id_job_exists()
    call repl#open()
  endif
  let yolo_message = "print(\"YOLO: You Only Live Once!\")"
  call s:chansend_buflines([yolo_message])
  echom 'YOLO mode activated!'
endfunction


function! repl#sendcell(...)
  if !s:repl_id_job_exists()
    call repl#attach()
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
  call s:send_block(cell_begin_line_num + 1, cell_end_line_num, mode())
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
    call repl#warning('no open repl attached to buffer. Run ":ReplOpen" or ":ReplAttach"')
    return
  endif
  call chansend(b:repl_id_job, "\<c-l>")
endfunction
