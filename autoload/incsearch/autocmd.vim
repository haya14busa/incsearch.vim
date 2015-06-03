"=============================================================================
" FILE: autoload/incsearch/autocmd.vim
" AUTHOR: haya14busa
" License: MIT license
"=============================================================================
scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

noremap  <silent> <Plug>(_incsearch-nohlsearch) <Nop>
noremap! <silent> <Plug>(_incsearch-nohlsearch) <Nop>
nnoremap <silent> <Plug>(_incsearch-nohlsearch) :<C-u>nohlsearch<CR>
xnoremap <silent> <Plug>(_incsearch-nohlsearch) :<C-u>nohlsearch<CR>gv

" :set hlsearch just before :nohlsearch not to blink highlight
noremap  <silent> <Plug>(_incsearch-sethlsearch) <Nop>
noremap! <silent> <Plug>(_incsearch-sethlsearch) <Nop>
nnoremap <silent> <Plug>(_incsearch-sethlsearch) :<C-u>set hlsearch <Bar> nohlsearch<CR>
xnoremap <silent> <Plug>(_incsearch-sethlsearch) :<C-u>set hlsearch <Bar> nohlsearch<CR>

" Make sure move cursor by search related action __after__ calling this
" function because the first move event just set nested autocmd which
" does :nohlsearch
" @expr
function! incsearch#autocmd#auto_nohlsearch(nest) abort
  " NOTE: see this value inside this function in order to toggle auto
  " :nohlsearch feature easily with g:incsearch#autocmd#auto_nohlsearch option
  if !g:incsearch#auto_nohlsearch | return '' | endif
  return s:auto_nohlsearch(a:nest)
endfunction

function! s:auto_nohlsearch(nest) abort
  " NOTE: :h autocmd-searchpat
  "   You cannot implement this feature without feedkeys() because of
  "   :h autocmd-searchpat
  augroup incsearch-auto-nohlsearch
    autocmd!
    autocmd InsertEnter * :call <SID>on_insert_enter() | autocmd! incsearch-auto-nohlsearch
    execute join([
    \   'autocmd CursorMoved *'
    \ , repeat('autocmd incsearch-auto-nohlsearch CursorMoved * ', a:nest)
    \ , 'call feedkeys("\<Plug>(_incsearch-nohlsearch)", "m")'
    \ , '| autocmd! incsearch-auto-nohlsearch'
    \ ], ' ')
  augroup END
  return ''
endfunction

" Auto nohlsearch on insert
let s:noi = {}

function! s:noi.on_insert_enter() abort
  " NOTE:
  " Ideally, it should be :nohlsearch but it use `set nohlsearch` instead
  " to avoid :h autocmd-searchpat
  let self.hlsearch = &hlsearch
  set nohlsearch
endfunction

function! s:noi.on_insert_leave() abort
  if self.hlsearch
    call feedkeys("\<Plug>(_incsearch-sethlsearch)", 'm')
  endif
endfunction

function! s:on_insert_enter() abort
  call s:noi.on_insert_enter()
  augroup incsearch-auto-nohlsearch-on-insert-leave
    autocmd!
    autocmd InsertLeave * :call <SID>on_insert_leave() | autocmd! incsearch-auto-nohlsearch-on-insert-leave
  augroup END
endfunction

function! s:on_insert_leave() abort
  call s:noi.on_insert_leave()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" __END__
" vim: expandtab softtabstop=2 shiftwidth=2 foldmethod=marker
