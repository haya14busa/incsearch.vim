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

" Option:
let g:incsearch#emacs_like_keymap = get(g:, 'incsearch#emacs_like_keymap', s:FALSE)


let s:V = vital#of('incsearch')

" Highlight: {{{
let s:hi = s:V.import("Coaster.Highlight").make()

function! s:init_hl()
    hi link IncSearchMatch Search
    hi link IncSearchCursor Cursor
    hi link IncSearchOnCursor IncSearch
endfunction
call s:init_hl()
augroup plugin-incsearch-highlight
    autocmd!
    autocmd ColorScheme * call s:init_hl()
augroup END

let s:default_highlight = {
\   'match' : {
\       'group'    : 'IncSearchMatch',
\       'priority' : '49'
\   },
\   'on_cursor' : {
\       'group'    : 'IncSearchOnCursor',
\       'priority' : '50'
\   },
\   'cursor' : {
\       'group'    : 'IncSearchCursor',
\       'priority' : '51'
\   },
\ }
let g:incsearch#highlight = {}
let g:incsearch#highlight = extend(s:default_highlight, get(g:, 'incsearch#highlight', {}))
function! s:hig() " highlight group management
    return extend(s:default_highlight, g:incsearch#highlight)
endfunction

function! s:update_hl()
    call s:hi.disable_all()
    call s:hi.enable_all()
endfunction

"}}}

" CommandLine Interface: {{{
let s:cmdline = s:V.import('Over.Commandline')
let s:modules = s:V.import('Over.Commandline.Modules')

let s:search = s:cmdline.make_default("/")

" Add modules
call s:search.connect('BufferComplete')
call s:search.connect('Cancel')
call s:search.connect('CursorMove')
call s:search.connect('Delete')
call s:search.connect('DrawCommandline')
call s:search.connect('ExceptionExit')
call s:search.connect('Exit')
call s:search.connect('InsertRegister')
call s:search.connect('Paste')
call s:search.connect(s:modules.get('ExceptionMessage').make('incsearch.vim: ', 'echom'))
call s:search.connect(s:modules.get('History').make('/'))
call s:search.connect(s:modules.get('NoInsert').make_special_chars())
if g:incsearch#emacs_like_keymap
    call s:search.connect(s:modules.get('KeyMapping').make_emacs())
endif

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
    " disable previous highlight
    nohlsearch
    let s:w = winsaveview()
    let hig = s:hig()
    let c = hig.cursor
    call s:hi.add(c.group, c.group, '\%#', c.priority)
    call s:update_hl()
endfunction

function! s:inc.on_leave(cmdline)
    call s:hi.disable_all()
    call s:hi.delete_all()
    " redraw: hide pseud-cursor
    echo s:search.get_prompt() . s:search.getline()
endfunction

function! s:inc.on_char_pre(cmdline)
    " Filter unexpected char {{{
    " XXX: I don't know why, but if you use vital-over in <expr> mapping, some
    "      unexpected char will be automatically inserted.
    let charnr = char2nr(s:search.char())
    if charnr == 128 || charnr == 253 ||
    \   (exists('s:old_charnr') && s:old_charnr == 253 && charnr == 96)
        call a:cmdline.setchar('')
    endif
    let s:old_charnr = charnr
    " }}}
endfunction

function! s:inc.on_char(cmdline)
    try
        " get `pattern` and ignore flags
        let [pattern, flags] = incsearch#parse_pattern(s:search.getline(), s:search.get_prompt())
        " pseud-move cursor position: this is restored afterward
        if pattern !=# ''
            let pattern = incsearch#convert(pattern)
            call winrestview(s:w)
            for _ in range(v:count1)
                call search(pattern, a:cmdline.flag)
            endfor
        endif
        let hig = s:hig()
        call s:hi.add(hig.match.group, hig.match.group, pattern, hig.match.priority)
        call s:hi.add(hig.on_cursor.group, hig.on_cursor.group, '\%#' . pattern, hig.on_cursor.priority)
        call s:hi.add(hig.cursor.group, hig.cursor.group, '\%#', hig.cursor.priority)
        call s:update_hl()
    catch /E53:/ " E53: Unmatched %(
    catch /E54:/
    catch /E55:/
    catch /E867:/ " E867: (NFA) Unknown operator
        call s:hi.disable_all()
    catch
        echohl ErrorMsg | echom v:throwpoint . " " . v:exception | echohl None
    endtry
endfunction

" KeyMapping Interface: {{{
function! incsearch#cmap(args)
    let lhs = s:as_keymapping(a:args[0])
    let rhs = s:as_keymapping(a:args[1])
    call s:search.cmap(lhs, rhs)
endfunction
function! incsearch#cnoremap(args)
    let lhs = s:as_keymapping(a:args[0])
    let rhs = s:as_keymapping(a:args[1])
    call s:search.cnoremap(lhs, rhs)
endfunction
function! incsearch#cunmap(lhs)
    let lhs = s:as_keymapping(a:lhs)
    call s:search.cunmap(lhs)
endfunction
function! s:as_keymapping(key)
    execute 'let result = "' . substitute(a:key, '\(<.\{-}>\)', '\\\1', 'g') . '"'
    return result
endfunction
"}}}

call s:search.connect(s:inc)
"}}}

" Main: {{{

function! incsearch#forward()
    return incsearch#search('/')
endfunction

function! incsearch#backward()
    return incsearch#search('?')
endfunction

function! incsearch#stay()
    let pattern = incsearch#get('')
    call histadd('/', pattern)
    let @/ = pattern
    return "\<ESC>"
endfunction

function! incsearch#get(search_key)
    " if search_key is empty, it means `stay` & do not move cursor
    let prompt = a:search_key ==# '' ? '/' : a:search_key
    call s:search.set_prompt(prompt)
    let s:search.flag = a:search_key ==# '/' ? ''
    \                 : a:search_key ==# '?' ? 'b'
    \                 : a:search_key ==# ''  ? 'n'
    \                 : ''
    return s:search.get()
endfunction

function! incsearch#search(search_key)
    let pattern = incsearch#get(a:search_key)
    if (s:search.exit_code() == 0)
        return a:search_key . pattern . "\<CR>"
    else
        " Cancel
        return "\<ESC>"
    endif
endfunction

"}}}

" Helper: {{{
function! incsearch#parse_pattern(expr, search_key)
    " search_key : '/'
    " expr       : /{pattern\/pattern}/{flags}
    " return     : [{pattern\/pattern}, {flags}]
    let very_magic = '\v'
    let pattern  = '(%(\\.|.){-})'
    let slash = '(\' . a:search_key . '&[^\\"|[:alnum:][:blank:]])'
    let flags = '(.*)'

    let parse_pattern = very_magic . pattern . '%(' . slash . flags . ')?$'
    let result = matchlist(a:expr, parse_pattern)[1:3]
    if type(result) == type(0) || empty(result)
        return []
    endif
    unlet result[1]
    return result
endfunction

function! incsearch#convert(pattern)
    if &ignorecase == s:FALSE
        return '\C' . a:pattern " noignorecase
    endif

    if &smartcase == s:FALSE
        return '\c' . a:pattern " ignorecase & nosmartcase
    endif

    " Find uppercase letter which isn't' escaped
    let very_magic = '\v'
    let escaped_backslash = '%(^|[^\\])%(\\\\)*'
    if a:pattern =~# very_magic . escaped_backslash . '[A-Z]'
        return '\C' . a:pattern " smartcase with [A-Z]
    else
        return '\c' . a:pattern " smartcase without [A-Z]
    endif
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
