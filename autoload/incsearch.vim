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
let g:incsearch#emacs_like_keymap      = get(g: , 'incsearch#emacs_like_keymap'      , s:FALSE)
let g:incsearch#highlight              = get(g: , 'incsearch#highlight'              , {})
let g:incsearch#separate_highlight     = get(g: , 'incsearch#separate_highlight'     , s:FALSE)
let g:incsearch#consistent_n_direction = get(g: , 'incsearch#consistent_n_direction' , s:FALSE)


let s:V = vital#of('incsearch')

" Highlight: {{{
let s:hi = s:V.import("Coaster.Highlight").make()

function! s:init_hl()
    hi link IncSearchMatch IncSearch
    hi link IncSearchMatchReverse Search
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
\   'match_reverse' : {
\       'group'    : 'IncSearchMatchReverse',
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
\       "\<C-j>"   : {
\           "key" : "<Over>(incsearch-scroll-f)",
\           "noremap" : 1,
\       },
\       "\<C-k>"   : {
\           "key" : "<Over>(incsearch-scroll-b)",
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
    redraw " need to redraw for handling non-<expr> mappings
    if s:cli.getline() ==# ''
        echo ''
    else
        echo s:cli.get_prompt() . s:cli.getline()
    endif
endfunction

function! s:inc.get_pattern()
    " get `pattern` and ignore {offset}
    let [pattern, flags] = incsearch#parse_pattern(s:cli.getline(), s:cli.get_prompt())
    return pattern
endfunction

function! s:inc.on_char_pre(cmdline)
    if a:cmdline.is_input("<Over>(incsearch-next)")
        if a:cmdline.flag ==# 'n' " exit stay mode
            let s:cli.flag = ''
        else
            let s:cli.vcount1 += 1
        endif
        call a:cmdline.setchar('')
    elseif a:cmdline.is_input("<Over>(incsearch-prev)")
        if a:cmdline.flag ==# 'n' " exit stay mode
            let s:cli.flag = ''
        endif
        let s:cli.vcount1 -= 1
        if s:cli.vcount1 < 1
            let pattern = s:inc.get_pattern()
            let s:cli.vcount1 += s:count_pattern(pattern)
        endif
        call a:cmdline.setchar('')
    elseif (a:cmdline.is_input("<Over>(incsearch-scroll-f)")
    \       && (s:cli.flag ==# '' || s:cli.flag ==# 'n'))
    \ ||   (a:cmdline.is_input("<Over>(incsearch-scroll-b)") && s:cli.flag ==# 'b')
        if a:cmdline.flag ==# 'n' | let s:cli.flag = '' | endif
        let pattern = s:inc.get_pattern()
        let pos_expr = a:cmdline.is_input("<Over>(incsearch-scroll-f)") ? 'w$' : 'w0'
        let to_col = a:cmdline.is_input("<Over>(incsearch-scroll-f)")
        \          ? s:get_max_col(pos_expr) : 1
        let [from, to] = [getpos('.')[1:2], [line(pos_expr), to_col]]
        let cnt = s:count_pattern(pattern, from, to)
        let s:cli.vcount1 += cnt
        call a:cmdline.setchar('')
    elseif (a:cmdline.is_input("<Over>(incsearch-scroll-b)")
    \       && (s:cli.flag ==# '' || s:cli.flag ==# 'n'))
    \ ||   (a:cmdline.is_input("<Over>(incsearch-scroll-f)") && s:cli.flag ==# 'b')
        if a:cmdline.flag ==# 'n'
            let s:cli.flag = ''
            let s:cli.vcount1 -= 1
        endif
        let pattern = s:inc.get_pattern()
        let pos_expr = a:cmdline.is_input("<Over>(incsearch-scroll-f)") ? 'w$' : 'w0'
        let to_col = a:cmdline.is_input("<Over>(incsearch-scroll-f)")
        \          ? s:get_max_col(pos_expr) : 1
        let [from, to] = [getpos('.')[1:2], [line(pos_expr), to_col]]
        let cnt = s:count_pattern(pattern, from, to)
        let s:cli.vcount1 -= cnt
        if s:cli.vcount1 < 1
            let s:cli.vcount1 += s:count_pattern(pattern)
        endif
        call a:cmdline.setchar('')
    endif

    " Handle nowrapscan:
    "   if you `:set nowrapscan`, you can't move to the reverse direction
    if &wrapscan == s:FALSE && (
    \    a:cmdline.is_input("<Over>(incsearch-next)")
    \ || a:cmdline.is_input("<Over>(incsearch-prev)")
    \ || a:cmdline.is_input("<Over>(incsearch-scroll-f)")
    \ || a:cmdline.is_input("<Over>(incsearch-scroll-b)")
    \ )
        let pattern = s:inc.get_pattern()
        let start = [s:w.lnum, s:w.col]
        let end = (s:cli.flag ==# '') ? [line('$'), s:get_max_col('$')] : [1, 1]
        let [from, to] = sort([start, end])
        let max_cnt = s:count_pattern(pattern, from, to)
        let s:cli.vcount1 = min([max_cnt, s:cli.vcount1])
    endif
endfunction

function! s:inc.on_char(cmdline)
    try
        call winrestview(s:w)
        let pattern = s:inc.get_pattern()

        if pattern ==# ''
            call s:hi.disable_all()
            return
        endif

        let pattern = incsearch#convert_with_case(pattern)

        " pseud-move cursor position: this is restored afterward if called by
        " <expr> mappings
        for _ in range(s:cli.vcount1)
            call search(pattern, a:cmdline.flag)
        endfor

        " Highlight
        let hgm = s:hgm()
        let m = hgm.match
        let r = hgm.match_reverse
        let o = hgm.on_cursor
        let c = hgm.cursor
        let on_cursor_pattern = '\M\%#\(' . pattern . '\M\)'
        let should_separate_highlight =
        \   g:incsearch#separate_highlight == s:TRUE && s:cli.flag !=# 'n'
        if ! should_separate_highlight
            call s:hi.add(m.group, m.group, pattern, m.priority)
        else
            let forward_pattern = s:forward_pattern(pattern, s:w.lnum, s:w.col)
            let backward_pattern = s:backward_pattern(pattern, s:w.lnum, s:w.col)
            if s:cli.flag == '' " forward
                call s:hi.add(m.group , m.group , forward_pattern  , m.priority)
                call s:hi.add(r.group , r.group , backward_pattern , r.priority)
            elseif s:cli.flag == 'b' " backward
                call s:hi.add(m.group , m.group , backward_pattern , m.priority)
                call s:hi.add(r.group , r.group , forward_pattern  , r.priority)
            endif
        endif
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

    " pseudo-normal-zz after scroll
    if ( a:cmdline.is_input("<Over>(incsearch-scroll-f)")
    \ || a:cmdline.is_input("<Over>(incsearch-scroll-b)"))
        call winrestview({'topline': max([1, line('.') - winheight(0) / 2])})
    endif
endfunction

call s:cli.connect(s:inc)
"}}}

" Main: {{{
" @expr: called by <expr> mappings

function! incsearch#forward()
    call s:search_for_non_expr('/')
endfunction

" @expr
function! incsearch#forward_expr()
    return s:search('/')
endfunction

function! incsearch#backward()
    return s:search_for_non_expr('?')
endfunction

" @expr
function! incsearch#backward_expr()
    return s:search('?')
endfunction

" similar to incsearch#forward() but do not move the cursor unless explicitly
" move the cursor while searching
function! incsearch#stay()
    let m = mode(1)
    let cmd = incsearch#stay_expr(s:TRUE) " arg: Please histadd for me!
    call winrestview(s:w)

    " Avoid using feedkeys() as much as possible because
    " feedkeys() cannot be tested and sometimes cause unexpected behavior
    " FIXME: redundant
    let [_, offset] = incsearch#parse_pattern(s:cli.getline(), s:cli.get_prompt())
    if !empty(offset)
        call feedkeys(cmd, 'n')
    else
        " XXX: `execute` cannot handle {offset} for `n` & `N`, so use
        " `feedkeys()` in that case
        call s:silent_after_search(m)
        exec 'normal!' cmd
    endif
endfunction

" @expr
function! incsearch#stay_expr(...)
    " arg: called_by_non_expr
    " return: command which is excutable with expr-mappings or `exec 'normal!'`
    let called_by_non_expr = get(a:, 1, s:FALSE) " XXX: exists only for non-expr mappings
    let m = mode(1)

    let input = s:get_pattern('', m)

    " execute histadd manually
    if s:cli.flag ==# 'n' && input !=# ''
        let [pattern, offset] = incsearch#parse_pattern(s:cli.getline(), s:cli.get_prompt())
        if (!called_by_non_expr || empty(offset)) " see incsearch#stay() and below NOTE:
            call histadd('/', input)
            let @/ = pattern
        endif
    endif

    if s:cli.flag ==# 'n' " stay TODO: better flag name
        " NOTE: do not move cursor but need to handle {offset} for n & N ...! {{{
        if !empty(offset)
            let cmd = s:generate_command(m, input, '/')
            call feedkeys(cmd, 'n')
            " XXX: string()... use <SNR> or <SID>? But it doesn't work well.
            call s:silent_feedkeys(":\<C-u>call winrestview(". string(s:w) . ")\<CR>", 'winrestview', 'n')
        endif
        " }}}
        return (m =~# "[vV\<C-v>]") ? '\<ESC>gv' : "\<ESC>" " just exit
    else " exit stay mode while searching
        return s:generate_command(m, input, '/') " assume '/'
    endif
endfunction

function! s:search(search_key)
    let m = mode(1)
    let pattern = s:get_pattern(a:search_key, m)
    return s:generate_command(m, pattern, a:search_key)
endfunction

function! s:get_pattern(search_key, mode)
    " if search_key is empty, it means `stay` & do not move cursor
    let s:cli.vcount1 = v:count1
    let prompt = a:search_key ==# '' ? '/' : a:search_key
    call s:cli.set_prompt(prompt)
    let s:cli.flag = a:search_key ==# '/' ? ''
    \              : a:search_key ==# '?' ? 'b'
    \              : a:search_key ==# ''  ? 'n'
    \              : ''

    " Handle visual mode highlight
    if (a:mode =~# "[vV\<C-v>]")
        let visual_hl = s:highlight_capture('Visual')
        try
            call s:turn_off(visual_hl)
            call s:pseud_visual_highlight(visual_hl, a:mode)
            let pattern = s:cli.get()
        finally
            call s:turn_on(visual_hl)
        endtry
    else
        let pattern = s:cli.get()
    endif
    return pattern
endfunction

function! s:generate_command(mode, pattern, search_key)
    let op = (a:mode == 'no')          ? v:operator
    \      : (a:mode =~# "[vV\<C-v>]") ? 'gv'
    \      : ''
    if (s:cli.exit_code() == 0)
        call s:cli.callevent('on_execute_pre') " XXX: side-effect!
        " NOTE:
        "   Should I consider o_v, o_V, and o_CTRL-V cases and do not
        "   <Esc>? <Esc> exists for flexible v:count with using s:cli.vcount1,
        "   but, if you do not move the cursor while incremental searching,
        "   there are no need to use <Esc>.
        return "\<ESC>" . '"' . v:register . op . s:cli.vcount1 . a:search_key . a:pattern . "\<CR>"
    else " Cancel
        return (a:mode =~# "[vV\<C-v>]") ? '\<ESC>gv' : "\<ESC>"
    endif
endfunction

" @normal: assume normal mode basically
function! s:search_for_non_expr(search_key)
    let m = mode(1)
    " side effect: move cursor
    let input = s:get_pattern(a:search_key, m)
    let is_cancel = s:cli.exit_code()
    if is_cancel
        return
    endif

    let [pattern, offset] = incsearch#parse_pattern(s:cli.getline(), s:cli.get_prompt())
    let should_execute = !empty(offset) || input ==# ''
    if should_execute
        " Execute with feedkeys() to work with
        "  1. {offset}
        "  2. empty input (use last search pattern)
        "  FIXME: Pattern not found error will not occur
        "  NOTE: Don't use feedkeys() as much as possible to avoid flickering
        "  FIXME: if the offset is `/e`, `/b+` , etc... and currrent cursor
        "  position matches the input pattern, the incremental highlight of
        "  cursor position is wrong... but it's hard to fix
        let cmd = s:generate_command(m, input, a:search_key)
        call winrestview(s:w)
        call feedkeys(cmd, 'n')
    else
        " Add history if necessary
        call histadd(a:search_key, input)
        let @/ = pattern

        " Emulate E486 and handling `n` and `N` preparation {{{
        let target_view = winsaveview()
        call winrestview(s:w) " Get back start position temporarily for 'nowrapscan'
        normal! m`
        let pos = searchpos(pattern, 'n' . s:cli.flag)

        " handle
        "   1. `n` and `N` preparation with s:silent_after_search()
        "   2. 'search hit BOTTOM, continuing at TOP'
        "   3. 'search hit TOP, continuing at BOTTOM'
        exec "normal!" a:search_key . "\<CR>"

        call winrestview(target_view)
        if pos ==# [0,0]
            call s:Error('E486: Pattern not found: ' . pattern)
        endif
        "}}}

        call s:silent_after_search(m)
    endif
endfunction

"}}}

" Helper: {{{
function! incsearch#parse_pattern(expr, search_key)
    " search_key : '/' or '?'
    " expr       : /{pattern\/pattern}/{offset}
    " expr       : /{pattern}/;/{newpattern} :h //;
    " return     : [{pattern\/pattern}, {offset}]
    let very_magic = '\v'
    let pattern  = '(%(\\.|.){-})'
    let slash = '(\' . a:search_key . '&[^\\"|[:alnum:][:blank:]])'
    let offset = '(.*)'

    let parse_pattern = very_magic . pattern . '%(' . slash . offset . ')?$'
    let result = matchlist(a:expr, parse_pattern)[1:3]
    if type(result) == type(0) || empty(result)
        return []
    endif
    unlet result[1]
    return result
endfunction

function! incsearch#convert_with_case(pattern)
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

function! s:highlight_capture(hlname) "{{{
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

" TODO: test
function! s:pseud_visual_highlight(visual_hl, mode, ...)
    " Note: the default pos value assume visual selection is not cleared.
    " It uses curswant to emulate visual-block
    " FIXME: highlight doesn't work if the range is over screen height
    let v_start_pos = get(a:, 1, [line("v"),col("v")]) " cannot get curswant
    let v_end_pos   = get(a:, 2, [line("."),getcurpos()[4]])
    let pattern = s:get_visual_pattern(a:mode, v_start_pos, v_end_pos)
    let hgm = s:hgm()
    let v = hgm.visual
    execute 'hi IncSearchVisual' a:visual_hl.highlight
    call s:hi.add(v.group, v.group, pattern, v.priority)
    call s:update_hl()
endfunction

" TODO: test
function! s:get_visual_pattern(mode, v_start_pos, v_end_pos)
    let [v_start, v_end] = sort([a:v_start_pos, a:v_end_pos])
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

function! s:forward_pattern(pattern, line, col)
    let forward_line = printf('%%>%dl', a:line)
    let current_line = printf('%%%dl%%>%dc', a:line, a:col)
    return '\v(' . forward_line . '|' . current_line . ')\M\(' . a:pattern . '\M\)'
endfunction

function! s:backward_pattern(pattern, line, col)
    let backward_line = printf('%%<%dl', a:line)
    let current_line = printf('%%%dl%%<%dc', a:line, a:col)
    return '\v(' . backward_line . '|' . current_line . ')\M\(' . a:pattern . '\M\)'
endfunction

" Return the number of matched patterns in the current buffer or the specified
" region with `from` and `to` positions
" parameter: pattern, from, to
function! s:count_pattern(pattern, ...)
    let w = winsaveview()
    let [from, to] = reverse(sort([
    \   get(a:, 1, [1, 1]),
    \   get(a:, 2, [line('$'), s:get_max_col('$')])
    \ ], 's:is_pos_less_equal'))
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

" Return max column number of given line expression
" expr: similar to line(), col()
function! s:get_max_col(expr)
    return strlen(getline(a:expr)) + 1
endfunction

function! s:silent_feedkeys(expr, name, ...)
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

function! s:silent_after_search(...) " arg: mode
    " :h function-search-undo
    " Handle :set hlsearch
    if get(a:, 1, mode()) !=# 'no' " guard for operator-mapping
        call s:silent_feedkeys(":let &hlsearch=&hlsearch\<CR>", 'hlsearch', 'n')
        let d = g:incsearch#consistent_n_direction ? 1 : v:searchforward
        call s:silent_feedkeys(
        \   ":let v:searchforward=" . d . "\<CR>",
        \   'searchforward', 'n')
    endif
endfunction

function! s:Error(msg)
    redraw | echo ''
    echohl ErrorMsg
    echo a:msg
    echohl None
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
