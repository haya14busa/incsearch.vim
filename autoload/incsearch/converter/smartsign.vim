"=============================================================================
" FILE: autoload/incsearch/converter/smartsign.vim
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

let s:sticky = {}
let s:sticky.us = {
\  ',' : '<', '.' : '>', '/' : '?',
\  '1' : '!', '2' : '@', '3' : '#', '4' : '$', '5' : '%',
\  '6' : '^', '7' : '&', '8' : '*', '9' : '(', '0' : ')', '-' : '_', '=' : '+',
\  ';' : ':', '[' : '{', ']' : '}', '`' : '~', "'" : "\"", '\' : '|',
\  }

let s:sticky.ja = {
\  ',' : '<', '.' : '>', '/' : '?',
\  '1' : '!', '2' : '"', '3' : '#', '4' : '$', '5' : '%',
\  '6' : '&', '7' : "'", '8' : '(', '9' : ')', '0' : '_', '-' : '=', '^' : '~',
\  ';' : '+', ':' : '*', '[' : '{', ']' : '}', '@' : '`', '\' : '|',
\  }

let s:sticky_table = s:sticky[get(g:, 'incsearch#converter#smartsign#layout', 'us')]

let s:escape_in_rec = '\]^-/?'
let s:signs = '\m[' . escape(join(keys(s:sticky_table), ''), s:escape_in_rec) . ']'

let s:converter = incsearch#converter#make()
let s:converter.name = 'smartsign'
" let s:converter.flag = s:converter.backslash . 'f'

" assume '\V'
function! incsearch#converter#smartsign#char(sign)
    return has_key(s:sticky_table, a:sign) ?
    \     printf('\[%s%s]',
    \         escape(a:sign, s:escape_in_rec),
    \         escape(s:sticky_table[a:sign], s:escape_in_rec))
    \   : a:sign
endfunction

" " USAGE:
" let p =  s:converter.convert("`1234567890-=[];'\\,./")
" echo p | " p == \V\[`~]\[1!]\[2@]\[3#]\[4$]\[5%]\[6\^]\[7&]\[8*]\[9(]\[0)]\[\-_]\[=+]\[[{]\[\]}]\[;:]\['"]\[,<]\[.>]\[\/\?]
" echo (match("`1234567890-=[];'\\,./", p) != -1) == 1
" echo (match('~!@#$%^&*()_+{}:"|<>\', p) != -1) == 1
" echo (match("`1234%67890-=[];'\\,./", p) != -1) == 1
function! s:converter.convert(pattern)
    return '\V' . substitute(a:pattern, s:signs, '\=
    \                        incsearch#converter#smartsign#char(submatch(0))', 'g')
endfunction

function! incsearch#converter#smartsign#define()
    call incsearch#converter#define(s:converter)
endfunction


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}
" __END__  {{{
" vim: expandtab softtabstop=4 shiftwidth=4
" vim: foldmethod=marker
" }}}
