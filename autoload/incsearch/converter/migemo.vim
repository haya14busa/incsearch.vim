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

let s:has_migemo = has('migemo')
let s:has_cmigemo = executable('cmigemo')
function! s:_has_vimproc()
    try
        call vimproc#version()
        let ret = 1
    catch
        let ret = 0
    endtry
    return ret
endfunction
let s:has_vimproc = s:_has_vimproc()
let s:is_meet_requirement = s:has_migemo || (s:has_vimproc && s:has_cmigemo)

let s:converter = incsearch#converter#make()
let s:converter.name = 'migemo'
let s:converter.async = s:has_migemo ? s:FALSE : s:TRUE
let s:converter.flag = s:converter.backslash . '#m'

function! incsearch#converter#migemo#define()
    if s:is_meet_requirement
        call incsearch#converter#define(s:converter)
    endif
endfunction

function! s:converter.condition(pattern)
    return a:pattern =~# self.flag &&
    \   s:async_migemo_convert(a:pattern).state ==# 'done'
endfunction

function! s:converter.convert(pattern)
    return s:has_migemo ? migemo('pattern')
    \    : s:has_cmigemo ? s:async_migemo_convert(a:pattern).pattern
    \    : a:pattern
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

function! s:open_cmigemo_process(pattern)
    let s:cmigemo_response = '' " reset
    let s:migemodict = incsearch#converter#migemo#dict()
    let s:cmigemo_process = vimproc#popen2(
    \   printf('cmigemo -v -w "%s" -d "%s"', escape(a:pattern, '"\'), s:migemodict))
endfunction

function! incsearch#converter#migemo#dict()
    if exists('s:migemodict')
        return s:migemodict
    endif
    let s:migemodict = s:SearchDict()
    return s:migemodict
endfunction

function! s:SearchDict2(name)
  let path = $VIM . ',' . &runtimepath
  let dict = globpath(path, "dict/".a:name)
  if dict == ''
    let dict = globpath(path, a:name)
  endif
  if dict == ''
    for path in [
          \ '/usr/local/share/migemo/',
          \ '/usr/local/share/cmigemo/',
          \ '/usr/local/share/',
          \ '/usr/share/cmigemo/',
          \ '/usr/share/',
          \ ]
      let path = path . a:name
      if filereadable(path)
        let dict = path
        break
      endif
    endfor
  endif
  let dict = matchstr(dict, "^[^\<NL>]*")
  return dict
endfunction

function! s:SearchDict()
  for path in [
        \ 'migemo/'.&encoding.'/migemo-dict',
        \ &encoding.'/migemo-dict',
        \ 'migemo-dict',
        \ ]
    let dict = s:SearchDict2(path)
    if dict != ''
      return dict
    endif
  endfor
  echoerr 'a dictionary for migemo is not found'
  echoerr 'your encoding is '.&encoding
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
