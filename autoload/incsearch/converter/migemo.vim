"=============================================================================
" FILE: autoload/incsearch/converter/migemo.vim
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

let s:TRUE = !0
let s:FALSE = 0

let s:converter = incsearch#converter#make()
let s:converter.name = 'migemo'
let s:converter.async = s:TRUE " TODO: ?
let s:converter.flag = s:converter.backslash . '#m'

function! incsearch#converter#migemo#define()
    call incsearch#converter#define(s:converter)
endfunction

function! s:converter.condition(pattern, context)
    return a:pattern =~# self.flag &&
    \   s:async_migemo_convert(a:pattern).state ==# 'done'
endfunction

function! s:converter.convert(pattern, context)
    return s:async_migemo_convert(a:pattern).pattern
endfunction

let s:migemo_memo = {}
function! s:async_migemo_convert(pattern)
    if a:pattern ==# ''
        return {'state': 'done', 'pattern': ''}
    endif
    if has_key(s:migemo_memo, a:pattern)
        return {'state': 'done', 'pattern': s:migemo_memo[a:pattern]}
    endif
    if !exists('s:old_pattern') || a:pattern !=# s:old_pattern || !exists('s:cmigemo_process')
        call s:open_cmigemo_process(a:pattern)
    endif
    let s:old_pattern = a:pattern
    if s:cmigemo_process.stdout.eof
        let s:migemo_memo[a:pattern] = s:cmigemo_response
        return {'state': 'done', 'pattern': s:cmigemo_response}
    else
        let s:cmigemo_response .= s:cmigemo_process.stdout.read()
        return {'state': 'yet', 'pattern': s:cmigemo_response}
    endif
endfunction

let s:dict = incsearch#migemo#dict()
function! s:open_cmigemo_process(pattern)
    let s:cmigemo_response = '' " reset
    let s:cmigemo_process = vimproc#popen2(
    \   printf('cmigemo -v -w "%s" -d "%s"', escape(a:pattern, '"\'), s:dict))
endfunction

if expand("%:p") ==# expand("<sfile>:p")
    call incsearch#converter#migemo#define()
endif

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}
" __END__  {{{
" vim: expandtab softtabstop=4 shiftwidth=4
" vim: foldmethod=marker
" }}}
