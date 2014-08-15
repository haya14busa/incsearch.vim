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
let g:incsearch#highlight = get(g:, 'incsearch#highlight', {})


let s:V = vital#of('incsearch')

" Highlight: {{{
let s:hi = s:V.import("Coaster.Highlight").make()

function! s:init_hl()
    hi link IncSearchMatch Search
    hi link IncSearchCursor Cursor
    hi link IncSearchOnCursor IncSearch
    hi IncSearchUnderline term=underline cterm=underline gui=underline
endfunction
call s:init_hl()
augroup plugin-incsearch-highlight
    autocmd!
    autocmd ColorScheme * call s:init_hl()
augroup END

let s:default_highlight = {
\   'visual' : {
\       'group'    : 'IncSearchVisual',
\       'priority' : '10'
\   },
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
function! s:hgm() " highlight group management
    let hgm = copy(s:default_highlight)
    for key in keys(hgm)
        call extend(hgm[key], get(g:incsearch#highlight, key, {}))
    endfor
    return hgm
endfunction

function! s:update_hl()
    call s:hi.disable_all()
    call s:hi.enable_all()
endfunction

"}}}

" CommandLine Interface: {{{
let s:cli = s:V.import('Over.Commandline').make_default("/")
let s:modules = s:V.import('Over.Commandline.Modules')

" Add modules
call s:cli.connect('BufferComplete')
call s:cli.connect('Cancel')
call s:cli.connect('CursorMove')
call s:cli.connect('Delete')
call s:cli.connect('DrawCommandline')
call s:cli.connect('ExceptionExit')
call s:cli.connect('Exit')
call s:cli.connect('InsertRegister')
call s:cli.connect('Paste')
" XXX: better handling.
if expand("%:p") !=# expand("<sfile>:p")
    call s:cli.connect(s:modules.get('Doautocmd').make('IncSearch'))
endif
call s:cli.connect(s:modules.get('ExceptionMessage').make('incsearch.vim: ', 'echom'))
call s:cli.connect(s:modules.get('History').make('/'))
call s:cli.connect(s:modules.get('NoInsert').make_special_chars())
if g:incsearch#emacs_like_keymap
    call s:cli.connect(s:modules.get('KeyMapping').make_emacs())
endif


function! s:cli.keymapping()
    return extend({
\       "\<CR>"   : {
\           "key" : "<Over>(exit)",
\           "noremap" : 1,
\           "lock" : 1,
\       },
\       "\<Tab>"   : {
\           "key" : "<Over>(incsearch-next)",
\           "noremap" : 1,
\       },
\       "\<S-Tab>"   : {
\           "key" : "<Over>(incsearch-prev)",
\           "noremap" : 1,
\       },
\       "\<C-l>"   : {
\           "key" : "<Over>(buffer-complete)",
\           "noremap" : 1,
\       },
\   }, g:incsearch_cli_key_mappings)
endfunction

let s:inc = {
\   "name" : "incsearch",
\}

function! s:inc.on_enter(cmdline)
    nohlsearch " disable previous highlight
    let s:w = winsaveview()
    let hgm = s:hgm()
    let c = hgm.cursor
    call s:hi.add(c.group, c.group, '\%#', c.priority)
    call s:update_hl()
endfunction

function! s:inc.on_leave(cmdline)
    call s:hi.disable_all()
    call s:hi.delete_all()
    " redraw: hide pseud-cursor
    echo | redraw
    if s:cli.getline() !=# ''
        echo s:cli.get_prompt() . s:cli.getline()
    endif
endfunction

function! s:inc.on_char_pre(cmdline)
    if a:cmdline.is_input("<Over>(incsearch-next)")
        let s:cli.vcount1 += 1
        call a:cmdline.setchar('')
    elseif a:cmdline.is_input("<Over>(incsearch-prev)")
        let s:cli.vcount1 = max([1, s:cli.vcount1 - 1])
        call a:cmdline.setchar('')
    endif
endfunction

function! s:inc.on_char(cmdline)
    try
        call winrestview(s:w)
        " get `pattern` and ignore flags
        let [pattern, flags] = incsearch#parse_pattern(s:cli.getline(), s:cli.get_prompt())
        " pseud-move cursor position: this is restored afterward if called by
        " <expr> mappings
        if pattern !=# ''
            let pattern = incsearch#convert(pattern)
            for _ in range(s:cli.vcount1)
                call search(pattern, a:cmdline.flag)
            endfor
        endif
        let hgm = s:hgm()
        let m = hgm.match
        let o = hgm.on_cursor
        let c = hgm.cursor
        let on_cursor_pattern = '\M\%#\(' . pattern . '\M\)'
        call s:hi.add(m.group , m.group , pattern           , m.priority)
        call s:hi.add(o.group , o.group , on_cursor_pattern , o.priority)
        call s:hi.add(c.group , c.group , '\v%#'            , c.priority)
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

call s:cli.connect(s:inc)
"}}}

" Main: {{{

function! incsearch#forward()
    return s:search('/')
endfunction

function! incsearch#backward()
    return s:search('?')
endfunction

function! incsearch#stay()
    let pattern = s:get_pattern('')
    call histadd('/', pattern)
    let @/ = pattern
    return "\<ESC>"
endfunction

function! s:get_pattern(search_key)
    " if search_key is empty, it means `stay` & do not move cursor
    let s:cli.vcount1 = v:count1
    let prompt = a:search_key ==# '' ? '/' : a:search_key
    call s:cli.set_prompt(prompt)
    let s:cli.flag = a:search_key ==# '/' ? ''
    \              : a:search_key ==# '?' ? 'b'
    \              : a:search_key ==# ''  ? 'n'
    \              : ''

    return s:cli.get()
endfunction

function! s:search(search_key)
    let m = mode(1)

    " Get pattern {{{
    if (m =~# "[vV\<C-v>]") " Handle visual mode highlight
        let visual_hl = s:highlight_capture('Visual')
        try
            call s:turn_off(visual_hl)
            call s:pseud_visual_highlight(visual_hl, m)
            let pattern = s:get_pattern(a:search_key)
        finally
            call s:turn_on(visual_hl)
        endtry
    else
        let pattern = s:get_pattern(a:search_key)
    endif
    "}}}

    " Handle operator-pending mode
    let op = (m == 'no')          ? v:operator
    \      : (m =~# "[vV\<C-v>]") ? 'gv'
    \      : ''
    if (s:cli.exit_code() == 0)
        call s:cli.callevent('on_execute_pre')
        return "\<ESC>" . op . s:cli.vcount1 . a:search_key . pattern . "\<CR>"
    else " Cancel
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

    " Find uppercase letter which isn't escaped
    let very_magic = '\v'
    let escaped_backslash = '%(^|[^\\])%(\\\\)*'
    if a:pattern =~# very_magic . escaped_backslash . '[A-Z]'
        return '\C' . a:pattern " smartcase with [A-Z]
    else
        return '\c' . a:pattern " smartcase without [A-Z]
    endif
endfunction

function!s:highlight_capture(hlname) "{{{
    " Based On: https://github.com/t9md/vim-ezbar
    "           https://github.com/osyo-manga/vital-over
    let hlname = a:hlname
    if !hlexists(hlname)
        return
    endif
    while 1
        let save_verbose = &verbose
        let &verbose = 0
        try
            redir => HL_SAVE
            execute 'silent! highlight ' . hlname
            redir END
        finally
            let &verbose = save_verbose
        endtry
        if !empty(matchstr(HL_SAVE, 'xxx cleared$'))
            return ''
        endif
        " follow highlight link
        let ml = matchlist(HL_SAVE, 'links to \zs.*')
        if !empty(ml)
            let hlname = ml[0]
            continue
        endif
        break
    endwhile
    let HL_SAVE = substitute(matchstr(HL_SAVE, 'xxx \zs.*'),
                           \ '[ \t\n]\+', ' ', 'g')
    return { 'name': hlname, 'highlight': HL_SAVE }
endfunction "}}}

function! s:turn_off(highlight)
    execute 'highlight' a:highlight.name 'NONE'
endfunction

function! s:turn_on(highlight)
    execute 'highlight' a:highlight.name a:highlight.highlight
endfunction

function! s:pseud_visual_highlight(visual_hl, mode)
    let pattern = s:get_visual_pattern_by_range(a:mode)
    let hgm = s:hgm()
    let v = hgm.visual
    execute 'hi IncSearchVisual' a:visual_hl.highlight
    call s:hi.add(v.group, v.group, pattern, v.priority)
    call s:update_hl()
endfunction

function! s:get_visual_pattern_by_range(mode)
    let v_start = [line("v"),col("v")] " visual_start_position
    let v_end   = [line("."),col(".")] " visual_end_position
    if s:is_pos_less_equal(v_end, v_start)
        " swap position
        let [v_end, v_start] = [v_start, v_end]
    endif
    if a:mode ==# 'v'
        return printf('\v%%%dl%%%dc\_.*%%%dl%%%dc',
        \              v_start[0], v_start[1], v_end[0], v_end[1])
    elseif a:mode ==# 'V'
        return printf('\v%%%dl\_.*%%%dl', v_start[0], v_end[0])
    elseif a:mode ==# "\<C-v>"
        let [min_c, max_c] = sort([v_start[1], v_end[1]])
        return '\v'.join(map(range(v_start[0], v_end[0]), '
        \               printf("%%%dl%%%dc.*%%%dc",
        \                      v:val, min_c, min([max_c, len(getline(v:val))]))
        \      '), "|")
    else " Error: unexpected mode
        " TODO: error handling
        return ''
    endif
endfunction

" return (x <= y)
function! s:is_pos_less_equal(x, y)
    return (a:x[0] == a:y[0]) ? a:x[1] <= a:y[1] : a:x[0] < a:y[0]
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
