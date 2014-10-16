"=============================================================================
" FILE: autoload/incsearch/converter/spell.vim
" AUTHOR: haya14busa
" Last Change: 16-10-2014.
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
let s:converter.name = 'spell'
let s:converter.async = s:TRUE
" let s:converter.flag = s:converter.backslash . '#s'

function! s:converter.condition(pattern)
    return s:TRUE " TODO: disable flag
endfunction

function! s:spellsuggest(word)
    return [a:word] + spellsuggest(a:word, 2)
endfunction

function! s:suggest_words(word)
    let xs = s:spellsuggest(a:word)
    " TODO: uniq?
    return incsearch#detect_case(a:word) ==# '\c'
    \   ? map(xs , 'tolower(v:val)')
    \   : filter(xs, 'v:val =~# "\\u"')
endfunction

function! s:converter.convert(pattern)
    let spell_save = &spell
    let &spell = s:TRUE
    try
        let p = '\m' . incsearch#detect_case(a:pattern) .
        \   join(map(map(split(a:pattern, '\s'), 's:suggest_words(v:val)'), "
        \       printf('\\%%(%s\\)', join(v:val, '\\|'))
        \   "), '\s')
    finally
        let &spell = spell_save
    endtry
    return p
endfunction

function! incsearch#converter#spell#define()
    call incsearch#converter#define(s:converter)
endfunction

if expand("%:p") ==# expand("<sfile>:p")
    call incsearch#converter#spell#define()
endif

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}
" __END__  {{{
" vim: expandtab softtabstop=4 shiftwidth=4
" vim: foldmethod=marker
" }}}
