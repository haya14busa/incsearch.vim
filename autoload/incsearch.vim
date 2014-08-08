"=============================================================================
" FILE: autoload/incsearch.vim
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

let s:V = vital#of('incsearch')

" CommandLine Interface: {{{
" let s:cmdline = s:V.import('Over.Commandline.Base')
let s:cmdline = s:V.import('Over.Commandline')
let s:modules = s:V.import('Over.Commandline.Modules')

" let s:search = s:cmdline.make()
let s:search = s:cmdline.make_default("/")

" let s:search = s:cmdline.make_standard("$ ")

" Add modules
call s:search.connect('Exit')
call s:search.connect('Cancel')
call s:search.connect('DrawCommandline')
call s:search.connect('Delete')
call s:search.connect('CursorMove')
call s:search.connect('Paste')
call s:search.connect('InsertRegister')
call s:search.connect('ExceptionExit')
call s:search.connect(s:modules.get('ExceptionMessage').make('incsearch.vim: ', 'echom'))
call s:search.connect(s:modules.get('History').make('/'))
call s:search.connect(s:modules.get('NoInsert').make_special_chars())

let s:inc = {
\   "name" : "incsearch",
\}

function! s:search.keymapping()
    return {
\       "\<CR>"   : {
\           "key" : "<Over>(exit)",
\           "noremap" : 1,
\           "lock" : 1,
\       },
\   }
endfunction

function! s:inc.on_enter(cmdline)
endfunction

function! s:inc.on_leave(cmdline)
endfunction

function! s:inc.on_char(cmdline)
endfunction

call s:search.connect(s:inc)
"}}}

" Main: {{{

function! incsearch#forward()
    return incsearch#main('/')
endfunction

function! incsearch#backward()
    return incsearch#main('?')
endfunction

function! incsearch#stay()
    " TODO:
    call incsearch#main('/')
    return ''
endfunction

function! incsearch#main(search_key)
    call s:search.set_prompt(a:search_key)
    let pattern = s:search.get()
    return a:search_key . pattern . "\<CR>"
endfunction

"}}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}
" __END__  {{{
" vim: expandtab softtabstop=4 shiftwidth=4
" vim: foldmethod=marker
" }}}
