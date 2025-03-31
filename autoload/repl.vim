""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" OriginalAuthor: Samuel Roeca
" Maintainer:     Samuel Roeca samuel.roeca@gmail.com
" Description:    nvim-repl: configure and work with a repl
" Website:        https://github.com/pappasam/nvim-repl
" License:        MIT
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! repl#info(msg)
  echohl DiagnosticInfo
  echom 'repl: ' .. a:msg
  echohl None
endfunction

function! repl#warning(msg)
  echohl WarningMsg
  echom 'repl: ' .. a:msg
  echohl None
endfunction

let s:active_repls = {} " type: {jobid: [filepath, repl_config]}

function! s:path_relative_to_git_root(path)
  let git_root = trim(system('git rev-parse --show-toplevel 2>/dev/null'))
  if git_root == '' || v:shell_error != 0
    throw 'not in a git repository'
  endif
  " +1 to skip the trailing slash
  return escape(strpart(a:path, len(git_root) + 1), ' ')
endfunction

function! s:buffers_in_gitroot()
  let git_root = trim(system('git rev-parse --show-toplevel 2>/dev/null'))
  if git_root == '' || v:shell_error != 0
    throw 'not in a git repository'
  endif
  let git_root = git_root .. '/'
  let buffers = map(
        \ filter(
        \   filter(range(0, bufnr('$')), 'buflisted(v:val)'),
        \   'fnamemodify(bufname(v:val), ":p") =~ "^" .. escape(l:git_root, "\\[].$^") .. ".*"'
        \ ),
        \ 'strpart(fnamemodify(bufname(v:val), ":p"), len(l:git_root))'
        \ )
  return uniq(sort(buffers))
endfunction

function! s:cleanup(bufnr) abort
  let repl_data = getbufvar(str2nr(a:bufnr), 'repl_data', {})
  if empty(repl_data) || !has_key(repl_data, 'job_id')
    return
  endif
  let job_id = repl_data.job_id
  call jobstop(job_id)
  let repl_windows = filter(getwininfo(), {_, v -> get(get(getbufinfo(v.bufnr)[0], 'variables', {}), 'terminal_job_id', '') == job_id})
  let current_window_id = win_getid()
  for win in repl_windows
    call win_gotoid(win.winid)
    quit
  endfor
  unlet s:active_repls[job_id]
  call repl#info('closed!')
endfunction

function! s:repl_reset_visual_position()
  let repl_windows = filter(getwininfo(), {_, v -> get(get(getbufinfo(v.bufnr)[0], 'variables', {}), 'terminal_job_id', '') == b:repl_data.job_id})
  let current_window_id = win_getid()
  for win in repl_windows
    call win_gotoid(win.winid)
    call cursor(line('$'), 0)
  endfor
  call win_gotoid(current_window_id)
endfunction

function! s:repl_id_job_exists()
  if !exists('b:repl_data')
    return 0
  endif
  try
    call jobpid(b:repl_data.job_id)
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
    call repl#warning('already open, try `:ReplDetach` or `:ReplClose`')
    return
  endif
  if a:0 == 0
    let repl_config = s:get_repl(get(g:repl_filetype_commands, &filetype, g:repl_default))
  elseif a:0 == 1
    let repl_config = s:get_repl(a:1)
  else
    throw 'nvim-repl: repl#open only takes 0 or 1 arguments'
  endif
  let current_window_id = win_getid()
  execute repl_config.open_window
  let old_shell = &shell
  if old_shell == 'powershell'
    set shell=cmd
  endif
  let job_id = jobstart(repl_config.cmd, {'term': v:true})
  " Create the repl_data structure
  let repl_data = #{
        \ job_id: job_id,
        \ config: repl_config
        \ }
  let b:repl_data = repl_data " set in terminal buffer
  setlocal nonumber nornu nobuflisted
  autocmd BufHidden <buffer> call s:cleanup(expand('<abuf>'))
  call win_gotoid(current_window_id)
  let b:repl_data = repl_data " set in repl buffer
  let &shell = old_shell
  let s:active_repls[job_id] = [expand('%:.'), repl_config]
  call repl#info('opened!')
endfunction

function! repl#attach()
  let inputs_tail = []
  let jobs = []
  for [jobid, value] in items(s:active_repls)
    let select_id = printf('%s :: %s :: %s',
          \ jobid,
          \ value[1].repl_type != '' ? value[1].repl_type : value[1].cmd,
          \ value[0])
    call add(inputs_tail, select_id)
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
    let choice = inputlist(extendnew(['Select REPL (name :: jobid :: creator):'], inputs_tail))
    redraw!
    if choice > len(jobs) || choice < 1
      call repl#warning('no valid choice selected, not attatched')
      return
    endif
  endif
  let b:repl_data = #{
        \ job_id: jobs[choice - 1][0],
        \ config: jobs[choice - 1][1]
        \ }
  call repl#info('attached')
endfunction

function! repl#detach()
  if exists('b:repl_data')
    unlet b:repl_data
  endif
  call repl#info('detached buffer from existing REPL')
endfunction

function! repl#close()
  let current_window_id = win_getid()
  let current_tab = tabpagenr()
  if !exists('b:repl_data') || !has_key(b:repl_data, 'job_id')
    return
  endif
  let current_repl_id = b:repl_data.job_id
  set lazyredraw
  let tab_count = tabpagenr('$')
  for t in range(1, tab_count)
    if t <= tabpagenr('$')
      execute 'tabnext ' .. t
      let repl_windows = filter(getwininfo(), {_, v -> get(get(getbufinfo(v.bufnr)[0], 'variables', {}), 'terminal_job_id', '') == current_repl_id})
      for win in repl_windows
        call win_gotoid(win.winid)
        quit
      endfor
    endif
  endfor
  if current_tab <= tabpagenr('$')
    execute 'tabnext ' .. current_tab
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
    if !s:repl_id_job_exists()
      return
    endif
  endif
  call s:send_block(line('.'), line('.'), 'n')
  normal! j0
endfunction

function! repl#sendvisual(mode)
  if !s:repl_id_job_exists()
    call repl#attach()
    if !s:repl_id_job_exists()
      return
    endif
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

let s:repl_type_handlers = {} " Handler registry for different REPL types

function! s:ipython_handler(job_id, lines)
  let buflines = copy(a:lines)
  if len(buflines) > 0 && buflines[-1] =~ "^\\s\\+.*"
    let buflines += [""] " If last line has leading whitespace, add 1 line
  endif
  if len(buflines) == 1
    call chansend(a:job_id, buflines)
  else
    call chansend(a:job_id, "\<C-o>")
    call chansend(a:job_id, buflines)
    call chansend(a:job_id, s:arrow_down())
  endif
  call chansend(a:job_id, "\r")
endfunction
let s:repl_type_handlers['ipython'] = function('s:ipython_handler')

function! s:utop_handler(job_id, lines)
  let buflines = copy(a:lines)
  if len(buflines) > 0
    let buflines[-1] = buflines[-1] .. ' ;;'
  endif
  call chansend(a:job_id, buflines + [""])
endfunction
let s:repl_type_handlers['utop'] = function('s:utop_handler')

function! s:aider_handler(job_id, lines)
  let buflines = copy(a:lines)
  if len(buflines) > 0
    let buflines[-1] = buflines[-1] .. s:alt_enter()
  endif
  call chansend(a:job_id, buflines)
endfunction
let s:repl_type_handlers['aider'] = function('s:aider_handler')

function! s:default_handler(job_id, lines)
  let buflines = copy(a:lines)
  if len(buflines) > 0 && buflines[-1] =~ "^\\s\\+.*"
    let buflines += ["", ""] " If last line has leading whitespace, add 2 lines
  else
    let buflines += [""] " Otherwise, add 1
  endif
  call chansend(a:job_id, buflines)
endfunction

function! s:chansend_buflines(buflines)
  if has_key(s:repl_type_handlers, b:repl_data.config.repl_type)
    call s:repl_type_handlers[b:repl_data.config.repl_type](b:repl_data.job_id, a:buflines)
  else
    call s:default_handler(b:repl_data.job_id, a:buflines)
  endif
  call s:repl_reset_visual_position()
endfunction

function! s:send_block(firstline_num, lastline_num, mode)
  if !s:repl_id_job_exists()
    call repl#attach()
    if !s:repl_id_job_exists()
      return
    endif
  endif
  let buflines_raw = a:mode ==? 'v' || a:mode == "\<c-v>"
        \ ? s:get_visual_selection(a:mode)
        \ : getbufline(bufnr('%'), a:firstline_num, a:lastline_num)
  let buflines_chansend = []
  for line in buflines_raw
    if b:repl_data.config.repl_type == 'aider' " send all text to aider
      let buflines_chansend += [line]
    elseif line != "" && line !~ "^\\s*#\\s*%%.*" " remove the empty line and #%% line
      let buflines_chansend += [line]
    endif
  endfor
  call s:chansend_buflines(buflines_chansend)
endfunction

function! s:process_input(input_data)
  let lines = nvim_buf_get_lines(a:input_data.buf, 0, -1, v:false)
  if len(lines) > 0
    let input_text = lines
    if nvim_win_is_valid(a:input_data.win)
      call nvim_win_close(a:input_data.win, v:true)
    endif
    if nvim_win_is_valid(a:input_data.original_win)
      call nvim_set_current_win(a:input_data.original_win)
      call a:input_data.callback(input_text)
    endif
  endif
endfunction

function! s:create_floating_input(callback)
  let parent_repl_data = b:repl_data
  let parent_filetype = &filetype
  let original_win = win_getid()
  let buf = nvim_create_buf(v:false, v:true)
  call nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  let width = 60
  let height = 20
  let win_height = nvim_get_option('lines')
  let win_width = nvim_get_option('columns')
  let row = (win_height - height) / 2
  let col = (win_width - width) / 2
  let opts = {
        \ 'title': [[' REPL: ' .. parent_repl_data.config.repl_type .. ' ', 'FloatTitle']],
        \ 'title_pos': 'center',
        \ 'footer': [[' &ft=' .. parent_filetype .. ' ', 'FloatFooter']],
        \ 'footer_pos': 'center',
        \ 'relative': 'editor',
        \ 'width': width,
        \ 'height': height,
        \ 'col': col,
        \ 'row': row,
        \ 'anchor': 'NW',
        \ 'style': 'minimal',
        \ 'border': 'rounded'
        \ }
  let win = nvim_open_win(buf, v:true, opts)
  autocmd BufUnload <buffer> call s:process_input(b:input_data_store)
  " necessary so that folks don't try to save and get errors
  let b:input_data_store = {
        \ 'win': win,
        \ 'buf': buf,
        \ 'callback': a:callback,
        \ 'original_win': original_win
        \ }
  let b:repl_data = parent_repl_data
  " set filetype of buffer for highlighting purposes
  if b:repl_data.config.repl_type == 'aider'
    setlocal filetype=markdown
  else
    execute 'setlocal filetype=' .. parent_filetype
  endif
  startinsert!
endfunction

function! s:sendargs_direct(cmd_args)
  let t_cmd_args = type(a:cmd_args)
  if t_cmd_args == v:t_string
    let args = [trim(a:cmd_args, '', 2)]
  else
    let args = []
    for arg in a:cmd_args
      call add(args, trim(arg, '', 2))
    endfor
  endif
  call s:chansend_buflines(args)
  call repl#info("sent '" .. trim(join(args, "\n")) .. "'")
endfunction

function! s:sendargs_float_callback(cmd_args)
  let args = []
  let count = 0
  for arg in a:cmd_args
    let trimmed = trim(arg, '', 2)
    if trimmed == ''
      if b:repl_data.config.repl_type == 'aider'
        call add(args, trimmed) " keep newlines for aider
      endif
    else
      call add(args, trimmed)
      let count += 1
    endif
  endfor
  if count > 0
    call s:chansend_buflines(args)
    call repl#info('sent text to REPL')
  else
    call repl#warning('send cancelled')
  endif
endfunction

function! repl#send(...)
  if a:0 == 0
    if !s:repl_id_job_exists()
      call repl#attach()
      if !s:repl_id_job_exists()
        return
      endif
    endif
    call s:create_floating_input(function('s:sendargs_float_callback'))
  elseif a:0 == 1
    let cmd_args = a:1
    call s:sendargs_direct(cmd_args)
  else
    call repl#warning('repl#send only takes 0 or 1 arguments')
  endif
endfunction

function! repl#aiderbufall(preamble)
  if a:preamble != '/add' && a:preamble != '/drop'
    call repl#warning('unsupported command argument')
    return
  elseif !s:repl_id_job_exists()
    call repl#attach()
    if !s:repl_id_job_exists()
      return
    elseif b:repl_data.config.repl_type != 'aider'
      call repl#warning('can ony run if attached to aider repl')
      return
    endif
  endif
  try
    let file_args = join(s:buffers_in_gitroot(), ' ')
  catch /.*/
    call repl#warning(v:exception)
    return
  endtry
  call s:sendargs_direct([a:preamble .. ' ' .. file_args])
endfunction

function! repl#aiderbuf(preamble)
  if a:preamble != '/add' && a:preamble != '/drop'
    call repl#warning('unsupported command argument')
    return
  elseif !s:repl_id_job_exists()
    call repl#attach()
    if !s:repl_id_job_exists()
      return
    elseif b:repl_data.config.repl_type != 'aider'
      call repl#warning('can ony run if attached to aider repl')
      return
    endif
  endif
  try
    let path = s:path_relative_to_git_root(expand('%:p'))
  catch /.*/
    call repl#warning(v:exception)
    return
  endtry
  call s:sendargs_direct([a:preamble .. ' ' .. path])
endfunction

function! repl#aider_notifications_command()
  call repl#info('aider finished, buffers updated!')
  call s:repl_reset_visual_position()
  let current_bufnr = bufnr('%')
  let current_tabnr = tabpagenr()
  for bufnr in range(1, bufnr('$'))
    if bufexists(bufnr) && getbufvar(bufnr, '&buftype') == ''
      call bufload(bufnr)
      execute 'checktime ' .. bufnr
    endif
  endfor
  execute 'tabnext ' .. current_tabnr
  if bufexists(current_bufnr) && bufloaded(current_bufnr)
    execute 'buffer ' .. current_bufnr
  endif
endfunction

function! repl#aideropen()
  let cmd = "aider --multiline --notifications --notifications-command=\"nvim --server $NVIM --remote-send '<C-\\><C-n>:call repl#aider_notifications_command()<CR>'\""
  call repl#open(#{cmd: cmd, open_window: 'tabnew', repl_type: 'aider'})
endfunction

function! repl#sendcell(...)
  if !s:repl_id_job_exists()
    call repl#attach()
    if !s:repl_id_job_exists()
      return
    endif
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

function! repl#current()
  if !s:repl_id_job_exists()
    call repl#warning('no open repl attached to buffer. Run ":ReplOpen" or ":ReplAttach"')
    return
  endif
  echohl DiagnosticInfo
  echom 'repl:'
  echom '  cmd  : ' .. b:repl_data.config.cmd
  echom '  type : ' .. (b:repl_data.config.repl_type == '' ? 'default' : b:repl_data.config.repl_type)
  echom '  jobid: ' .. b:repl_data.job_id
  echohl None
endfunction

function! repl#focus()
  if !s:repl_id_job_exists()
    call repl#warning('no open repl attached to buffer. Run ":ReplOpen" or ":ReplAttach"')
    return
  endif
  let repl_windows = filter(getwininfo(), {_, v -> get(get(getbufinfo(v.bufnr)[0], 'variables', {}), 'terminal_job_id', '') == b:repl_data.job_id})
  for win in repl_windows
    call win_gotoid(win.winid)
    call cursor(line('$'), 0)
  endfor
endfunction

function! repl#clear()
  if !s:repl_id_job_exists()
    call repl#warning('no open repl attached to buffer. Run ":ReplOpen" or ":ReplAttach"')
    return
  endif
  call chansend(b:repl_data.job_id, "\<c-l>")
endfunction
