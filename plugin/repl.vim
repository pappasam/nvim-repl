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
      \ 'python': #{cmd: 'ipython --TerminalInteractiveShell.editing_mode=emacs --quiet --no-autoindent -i -c "%config InteractiveShell.ast_node_interactivity=\"last_expr_or_assign\""', repl_type: 'ipython'},
      \ }

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
    let g:repl_default = #{cmd: &shell, repl_type: ''}
  elseif type(g:repl_default) == v:t_dict
    let g:repl_default = extendnew(#{cmd: &shell, repl_type: ''}, g:repl_default)
  elseif type(g:repl_default) != v:t_string
    throw 'g:repl_default must be a String or a Dict'
  endif

  if !exists('g:repl_open_window_default')
    let g:repl_open_window_default = 'vertical split new'
  elseif type(g:repl_open_window_default) != v:t_string
    throw 'g:repl_open_window_default must be a String'
  endif

  " Commands

  if !s:cmd_exists(':Repl')
    command! -nargs=? -complete=shellcmd Repl call repl#open(<f-args>)
  endif
  if !s:cmd_exists(':ReplOpen')
    command! -nargs=? -complete=shellcmd ReplOpen call repl#open(<f-args>)
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
  if !s:cmd_exists('ReplSend')
    command! -nargs=1 ReplSend call repl#sendargs([<f-args>])
  endif
  if !s:cmd_exists('Aider')
    command! Aider call repl#aideropen()
  endif
  if !s:cmd_exists('AiderBufAll')
    function! s:complete_aider_bufall_add_drop(arglead, cmdline, cursorpos)
      return ['/add', '/drop']
    endfunction
    command! -nargs=1 -complete=customlist,s:complete_aider_bufall_add_drop AiderBufAll call repl#aiderbufall(<f-args>)
  endif
  if !s:cmd_exists('AiderBuf')
    function! s:complete_aider_buf_add_drop(arglead, cmdline, cursorpos)
      return ['/add', '/drop']
    endfunction
    command! -nargs=1 -complete=customlist,s:complete_aider_buf_add_drop AiderBuf call repl#aiderbuf(<f-args>)
  endif
  if !s:cmd_exists('AiderSend')
    function! s:complete_aider_send(arglead, cmdline, cursorpos)
      return [ '/add',
            \  '/architect',
            \  '/ask',
            \  '/chat-mode',
            \  '/clear',
            \  '/code',
            \  '/commit',
            \  '/context',
            \  '/copy',
            \  '/copy-context',
            \  '/diff',
            \  '/drop',
            \  '/edit',
            \  '/editor',
            \  '/editor-model',
            \  '/exit',
            \  '/git',
            \  '/help',
            \  '/lint',
            \  '/load',
            \  '/ls',
            \  '/map',
            \  '/map-refresh',
            \  '/model',
            \  '/models',
            \  '/multiline-mode',
            \  '/paste',
            \  '/quit',
            \  '/read-only',
            \  '/reasoning-effort',
            \  '/report',
            \  '/reset',
            \  '/run',
            \  '/save',
            \  '/settings',
            \  '/test',
            \  '/think-tokens',
            \  '/tokens',
            \  '/undo',
            \  '/voice',
            \  '/weak-model',
            \  '/web']
    endfunction
    command! -nargs=? -complete=customlist,s:complete_aider_send AiderSend call repl#aidersend(<f-args>)
  endif
endfunction

" Pluggable mappings

nnoremap <silent> <Plug>(ReplSendLine) <Cmd>execute 'set operatorfunc=repl#noop'<CR><Cmd>call repl#sendline()<CR>g@l<Cmd>execute 'set operatorfunc=repl#sendline'<CR>
nnoremap <silent> <Plug>(ReplSendCell) <Cmd>execute 'set operatorfunc=repl#noop'<CR><Cmd>call repl#sendcell()<CR>g@l<Cmd>execute 'set operatorfunc=repl#sendcell'<CR>
xnoremap <silent> <Plug>(ReplSendVisual) <Cmd>execute 'set operatorfunc=repl#noop'<CR>:<C-u>call repl#sendvisual(visualmode())<CR>g@l<Cmd>execute 'set operatorfunc=repl#sendline'<CR>

" Finish

try
  call s:configure_constants()
catch /.*/
  call repl#warning(v:exception)
finally
  let &cpo = s:save_cpo
  unlet s:save_cpo
endtry
