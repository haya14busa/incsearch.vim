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

" <expr> for dot repeat (`.`), easy and better handling for visual mode
noremap <silent><expr> <Plug>(incsearch-forward)  incsearch#forward_expr()
noremap <silent><expr> <Plug>(incsearch-backward) incsearch#backward_expr()
noremap <silent><expr> <Plug>(incsearch-stay)     incsearch#stay_expr()
" overwrite normal mode mappings to avoid flash
nnoremap <silent> <Plug>(incsearch-forward)  :<C-u>call incsearch#forward()<CR>
nnoremap <silent> <Plug>(incsearch-backward) :<C-u>call incsearch#backward()<CR>
nnoremap <silent> <Plug>(incsearch-stay)     :<C-u>call incsearch#stay()<CR>

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
