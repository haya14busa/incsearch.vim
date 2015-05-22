"=============================================================================
" FILE: autoload/incsearch/autocmd.vim
" AUTHOR: haya14busa
" License: MIT license
"=============================================================================
scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:U = incsearch#util#import()

" Make sure move cursor by search related action __after__ calling this
" function because the first move event just set nested autocmd which
" does :nohlsearch
" @expr
function! incsearch#autocmd#auto_nohlsearch(nest) abort
  " NOTE: see this value inside this function in order to toggle auto
  " :nohlsearch feature easily with g:incsearch#autocmd#auto_nohlsearch option
  if !g:incsearch#auto_nohlsearch | return '' | endif
  let cmd = s:U.is_visual(mode(1))
  \   ? 'call feedkeys(":\<C-u>nohlsearch\<CR>" . (mode(1) =~# "[vV\<C-v>]" ? "gv" : ""), "n")
  \     '
  \   : 'call s:U.silent_feedkeys(":\<C-u>nohlsearch\<CR>" . (mode(1) =~# "[vV\<C-v>]" ? "gv" : ""), "nohlsearch", "n")
  \     '
  " NOTE: :h autocmd-searchpat
  "   You cannot implement this feature without feedkeys() bacause of
  "   :h autocmd-searchpat
  augroup incsearch-auto-nohlsearch
    autocmd!
    " NOTE: this break . unit with c{text-object}
    " side-effect: InsertLeave & InsertEnter are called with i_CTRL-\_CTRL-O
    " autocmd InsertEnter * call feedkeys("\<C-\>\<C-o>:nohlsearch\<CR>", "n")
    " \   | autocmd! incsearch-auto-nohlsearch
    execute join([
    \   'autocmd CursorMoved *'
    \ , repeat('autocmd incsearch-auto-nohlsearch CursorMoved * ', a:nest)
    \ , cmd
    \ , '| autocmd! incsearch-auto-nohlsearch'
    \ ], ' ')
  augroup END
  return ''
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" __END__
" vim: expandtab softtabstop=2 shiftwidth=2 foldmethod=marker
