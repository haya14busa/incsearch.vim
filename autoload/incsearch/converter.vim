"=============================================================================
" FILE: autoload/incsearch/converter.vim
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
let s:escaped_backslash = '\m\%(^\|[^\\]\)\%(\\\\\)*'

" Converter:

" type: ['replace', 'append']
" break: Boolean, break convert loop if true
" backslash: utility for flag
" flag: can be used as a condition of convertion
let s:converter = {
\     'type': 'append'
\   , 'break': s:FALSE
\   , 'backslash' : s:escaped_backslash . '\zs\\'
\   , 'flag' : ''
\ }

" pattern which flags has already beeen replaced
function! s:converter.convert(pattern)
    return a:pattern
endfunction

" pattern as a raw input
function! s:converter.condition(pattern)
    return empty(self.flag) ? s:TRUE : a:pattern =~# self.flag
endfunction

function! incsearch#converter#make()
    return deepcopy(s:converter)
endfunction

let s:converters = []

function! incsearch#converter#convert(pattern)
    " Remove flag first
    let p = substitute(a:pattern, join(filter(map(copy(s:converters), 'v:val.flag'), '!empty(v:val)'), '\|'), '', 'g')
    if empty(p) | return '' | endif
    for converter in s:converters
        if !converter.condition(a:pattern) | continue | endif
        if converter.type == 'replace'
            let p = converter.convert(p)
        elseif converter.type == 'append'
            let p = printf('\m\(%s\m\|%s\m\)', p, converter.convert(p))
        endif
        if converter.break | break | endif
    endfor
    return empty(p) ? '' : incsearch#magic() . p
endfunction


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}
" __END__  {{{
" vim: expandtab softtabstop=4 shiftwidth=4
" vim: foldmethod=marker
" }}}
