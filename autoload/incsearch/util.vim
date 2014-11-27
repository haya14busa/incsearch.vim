"=============================================================================
" FILE: autoload/incsearch/util.vim
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
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" Utilities:

function! incsearch#util#import() abort
    let prefix = '<SNR>' . s:SID() . '_'
    let module = {}
    for func in s:functions
        let module[func] = function(prefix . func)
    endfor
    return copy(module)
endfunction

function! s:SID() abort
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction

let s:functions = [
\     'is_visual'
\   , 'get_max_col'
\   , 'is_pos_less_equal'
\   , 'is_pos_more_equal'
\   , 'sort_num'
\   , 'sort_pos'
\   , 'count_pattern'
\   , 'silent_feedkeys'
\ ]


function! s:is_visual(mode) abort
    return a:mode =~# "[vV\<C-v>]"
endfunction

" Return max column number of given line expression
" expr: similar to line(), col()
function! s:get_max_col(expr) abort
    return strlen(getline(a:expr)) + 1
endfunction

" return (x <= y)
function! s:is_pos_less_equal(x, y) abort
    return (a:x[0] == a:y[0]) ? a:x[1] <= a:y[1] : a:x[0] < a:y[0]
endfunction

" return (x > y)
function! s:is_pos_more_equal(x, y) abort
    return ! s:is_pos_less_equal(a:x, a:y)
endfunction

" x < y -> -1
" x = y -> 0
" x > y -> 1
function! s:compare_pos(x, y) abort
    return max([-1, min([1,(a:x[0] == a:y[0]) ? a:x[1] - a:y[1] : a:x[0] - a:y[0]])])
endfunction

function! s:sort_num(xs) abort
    " 7.4.341
    " http://ftp.vim.org/vim/patches/7.4/7.4.341
    if v:version > 704 || v:version == 704 && has('patch341')
        return sort(a:xs, 'n')
    else
        return sort(a:xs, 's:_sort_num_func')
    endif
endfunction

function! s:_sort_num_func(x, y) abort
    return a:x - a:y
endfunction

function! s:sort_pos(pos_list) abort
    " pos_list: [ [x1, y1], [x2, y2] ]
    return sort(a:pos_list, 's:compare_pos')
endfunction

" Return the number of matched patterns in the current buffer or the specified
" region with `from` and `to` positions
" parameter: pattern, from, to
function! s:count_pattern(pattern, ...) abort
    let w = winsaveview()
    let [from, to] = s:sort_pos([
    \   get(a:, 1, [1, 1]),
    \   get(a:, 2, [line('$'), s:get_max_col('$')])
    \ ])
    call cursor(from)
    let cnt = 0
    try
        " first: accept a match at the cursor position
        let pos = searchpos(a:pattern, 'cW')
        while (pos != [0, 0] && s:is_pos_less_equal(pos, to))
            let cnt += 1
            let pos = searchpos(a:pattern, 'W')
        endwhile
    finally
        call winrestview(w)
    endtry
    return cnt
endfunction

" NOTE: support vmap?
function! s:silent_feedkeys(expr, name, ...) abort
    " Ref:
    " https://github.com/osyo-manga/vim-over/blob/d51b028c29661d4a5f5b79438ad6d69266753711/autoload/over.vim#L6
    let mode = get(a:, 1, "m")
    let name = "incsearch-" . a:name
    let map = printf("<Plug>(%s)", name)
    if mode == "n"
        let command = "nnoremap"
    else
        let command = "nmap"
    endif
    execute command "<silent>" map printf("%s:nunmap %s<CR>", a:expr, map)
    if mode(1) !=# 'ce'
        " FIXME: mode(1) !=# 'ce' exists only for the test
        "        :h feedkeys() doesn't work while runnning a test script
        "        https://github.com/kana/vim-vspec/issues/27
        call feedkeys(printf("\<Plug>(%s)", name))
    endif
endfunction

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}
" __END__  {{{
" vim: expandtab softtabstop=4 shiftwidth=4
" vim: foldmethod=marker
" }}}
