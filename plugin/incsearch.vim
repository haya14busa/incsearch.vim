"=============================================================================
" FILE: plugin/incsearch.vim
" AUTHOR: haya14busa
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================
scriptencoding utf-8
" Load Once {{{
if expand("%:p") ==# expand("<sfile>:p")
    unlet! g:loaded_incsearch
endif
if exists('g:loaded_incsearch')
    finish
endif
let g:loaded_incsearch = 1
" }}}

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" <expr> is just for passing mode(1) value, so basically called with
" non-<expr> state
noremap <silent><expr> <Plug>(incsearch-forward)  <SID>mode_wrap('forward')
noremap <silent><expr> <Plug>(incsearch-backward) <SID>mode_wrap('backward')
noremap <silent><expr> <Plug>(incsearch-stay)     <SID>mode_wrap('stay')

" <expr> for dot repeat (`.`) in operator pending mode
onoremap <silent><expr> <Plug>(incsearch-forward)  incsearch#forward_expr()
onoremap <silent><expr> <Plug>(incsearch-backward) incsearch#backward_expr()
onoremap <silent><expr> <Plug>(incsearch-stay)     incsearch#stay_expr()

" Apply automatic :h :nohlsearch with :h :autocmd
" NOTE:
"   - This mappings doesn't move the cursor, please use this with other
"     mappings at the same time.
"   - Make sure calling this mapping __before__ moving commands
"     e.g. `<Plug>(incsearch-nohl)n` works but `n<Plug>(incsearch-nohl)` doesn't
"     work
noremap <expr> <Plug>(incsearch-nohl) incsearch#auto_nohlsearch(1)
" NOTE: Should I consider to make below mappings public?
" noremap <expr> <Plug>(incsearch-nohl0) incsearch#auto_nohlsearch(0)
" noremap <expr> <Plug>(incsearch-nohl2) incsearch#auto_nohlsearch(2)

map <Plug>(incsearch-nohl-n)  <Plug>(incsearch-nohl)<Plug>(_incsearch-n)
map <Plug>(incsearch-nohl-N)  <Plug>(incsearch-nohl)<Plug>(_incsearch-N)
map <Plug>(incsearch-nohl-*)  <Plug>(incsearch-nohl)<Plug>(_incsearch-*)
map <Plug>(incsearch-nohl-#)  <Plug>(incsearch-nohl)<Plug>(_incsearch-#)
map <Plug>(incsearch-nohl-g*) <Plug>(incsearch-nohl)<Plug>(_incsearch-g*)
map <Plug>(incsearch-nohl-g#) <Plug>(incsearch-nohl)<Plug>(_incsearch-g#)

" These mappings are just alias to default mappings except they won't be
" remapped any more
noremap <Plug>(_incsearch-n)  n
noremap <Plug>(_incsearch-N)  N
noremap <Plug>(_incsearch-*)  *
noremap <Plug>(_incsearch-#)  #
noremap <Plug>(_incsearch-g*) g*
noremap <Plug>(_incsearch-g#) g#

" for normal and visual mode
function! s:mode_wrap(cmd)
    let m = mode(1)
    let esc = m ==# 'no' ? '' : "\<ESC>"
    return printf(esc . ":\<C-u>call incsearch#%s('%s', %d)\<CR>",
    \             a:cmd, strtrans(m), v:count1)
endfunction

" CommandLine Mapping {{{
let g:incsearch_cli_key_mappings = get(g:, 'g:incsearch_cli_key_mappings', {})

function! s:key_mapping(lhs, rhs, noremap)
    let g:incsearch_cli_key_mappings[a:lhs] = {
\       "key" : a:rhs,
\       "noremap" : a:noremap,
\   }
endfunction

function! s:as_keymapping(key)
    execute 'let result = "' . substitute(a:key, '\(<.\{-}>\)', '\\\1', 'g') . '"'
    return result
endfunction

command! -nargs=* IncSearchNoreMap
\   call call("s:key_mapping", map([<f-args>], "s:as_keymapping(v:val)") + [1])

command! -nargs=* IncSearchMap
\   call call("s:key_mapping", map([<f-args>], "s:as_keymapping(v:val)") + [0])

"}}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}
" __END__  {{{
" vim: expandtab softtabstop=4 shiftwidth=4
" vim: foldmethod=marker
" }}}
