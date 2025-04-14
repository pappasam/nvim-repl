""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" OriginalAuthor: Samuel Roeca
" Maintainer:     Samuel Roeca samuel.roeca@gmail.com
" Description:    nvim-repl: configure and work with a repl
" Website:        https://github.com/pappasam/nvim-repl
" License:        MIT
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if !has('nvim-0.11.0')
  echohl WarningMsg
  echom 'nvim-repl: fatal error, cannot load'
  echom '           requires nvim 0.11.0 or later'
  echom '           check version: `nvim --version`'
  echohl None
  finish
endif
if exists("g:loaded_repl")
  finish
endif
let g:loaded_repl = v:true
let s:save_cpo = &cpo
set cpo&vim

function s:cmpAider(arglead, cmdline, cursorpos)
  return ['/add', '/drop']
endfunction

command -nargs=? -complete=shellcmd               Repl call repl#open(<f-args>)
command                                           ReplIpython call repl#open(v:lua.require('repl').get_special_repl('ipython'))
command                                           ReplUtop call repl#open(v:lua.require('repl').get_special_repl('utop'))
command                                           ReplAider call repl#open(v:lua.require('repl').get_special_repl('aider'))
command                                           ReplAttach call repl#attach()
command                                           ReplDetach call repl#detach()
command                                           ReplClose call repl#close()
command                                           ReplToggle call repl#toggle()
command                                           ReplNewCell call repl#newcell()
command                                           ReplRunCell call repl#sendcell()
command                                           ReplCurrent call repl#current()
command                                           ReplFocus call repl#focus()
command                                           ReplClear call repl#clear()
command -nargs=?                                  ReplSend call repl#send(<f-args>)
command -nargs=1 -complete=customlist,s:cmpAider  ReplAiderBufCur call repl#aiderbuf(<f-args>)
command -nargs=1 -complete=customlist,s:cmpAider  ReplAiderBufAll call repl#aiderbufall(<f-args>)

nnoremap <silent> <Plug>(ReplSendLine) <Cmd>execute 'set operatorfunc=repl#noop'<CR><Cmd>call repl#sendline()<CR>g@l<Cmd>execute 'set operatorfunc=repl#sendline'<CR>
nnoremap <silent> <Plug>(ReplSendCell) <Cmd>execute 'set operatorfunc=repl#noop'<CR><Cmd>call repl#sendcell()<CR>g@l<Cmd>execute 'set operatorfunc=repl#sendcell'<CR>
xnoremap <silent> <Plug>(ReplSendVisual) <Cmd>execute 'set operatorfunc=repl#noop'<CR>:<C-u>call repl#sendvisual(visualmode())<CR>g@l<Cmd>execute 'set operatorfunc=repl#sendline'<CR>

let &cpo = s:save_cpo
unlet s:save_cpo
