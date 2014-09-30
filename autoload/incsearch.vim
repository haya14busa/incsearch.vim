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
let s:DIRECTION = { 'forward': 1, 'backward': 0 } " see :h v:searchforward

" Option:
let g:incsearch#emacs_like_keymap      = get(g: , 'incsearch#emacs_like_keymap'      , s:FALSE)
let g:incsearch#highlight              = get(g: , 'incsearch#highlight'              , {})
let g:incsearch#separate_highlight     = get(g: , 'incsearch#separate_highlight'     , s:FALSE)
let g:incsearch#consistent_n_direction = get(g: , 'incsearch#consistent_n_direction' , s:FALSE)
" This changes emulation way slightly
let g:incsearch#do_not_save_error_message_history =
\   get(g:, 'incsearch#do_not_save_error_message_history', s:FALSE)


let s:V = vital#of('incsearch')

" Utility:
let s:U = incsearch#util#import()

" Highlight:
let s:hi = g:incsearch#highlight#hi

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
    let hgm = incsearch#highlight#hgm()
    let c = hgm.cursor
    call s:hi.add(c.group, c.group, '\%#', c.priority)
    call incsearch#highlight#update()
endfunction

function! s:inc.on_leave(cmdline)
    call s:reset()
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

function! s:reset()
    " Current commandline is called by <expr> mapping
    let s:cli.is_expr = s:FALSE
endfunction
call s:reset()

function! s:inc.get_pattern()
    " get `pattern` and ignore {offset}
    let [pattern, flags] = incsearch#parse_pattern(s:cli.getline(), s:cli.get_prompt())
    return pattern
endfunction

" Avoid search-related error while incremental searching
function! s:on_searching(func, ...)
    try
        return call(a:func, a:000)
    catch /E33:/  " E33: No previous substitute regular expression
    catch /E53:/  " E53: Unmatched %(
    catch /E54:/
    catch /E55:/
    catch /E66:/  " E66: \z( not allowed here
    catch /E67:/  " E67: \z1 et al. not allowed here
    catch /E69:/  " E69: Missing ] after \%[
    catch /E554:/
    catch /E678:/ " E678: Invalid character after \%[dxouU]
    catch /E865:/ " E865: (NFA) Regexp end encountered prematurely
    catch /E866:/ " E866: (NFA regexp) Misplaced @
    catch /E867:/ " E867: (NFA) Unknown operator
    catch /E870:/ " E870: (NFA regexp) Error reading repetition limits
    catch /E871:/ " E871: (NFA regexp) Can't have a multi follow a multi !
        call s:hi.disable_all()
    catch
        echohl ErrorMsg | echom v:throwpoint . " " . v:exception | echohl None
    endtry
endfunction

function! s:on_char_pre(cmdline)
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
            let s:cli.vcount1 += s:U.count_pattern(pattern)
        endif
        call a:cmdline.setchar('')
    elseif (a:cmdline.is_input("<Over>(incsearch-scroll-f)")
    \       && (s:cli.flag ==# '' || s:cli.flag ==# 'n'))
    \ ||   (a:cmdline.is_input("<Over>(incsearch-scroll-b)") && s:cli.flag ==# 'b')
        if a:cmdline.flag ==# 'n' | let s:cli.flag = '' | endif
        let pattern = s:inc.get_pattern()
        let pos_expr = a:cmdline.is_input("<Over>(incsearch-scroll-f)") ? 'w$' : 'w0'
        let to_col = a:cmdline.is_input("<Over>(incsearch-scroll-f)")
        \          ? s:U.get_max_col(pos_expr) : 1
        let [from, to] = [getpos('.')[1:2], [line(pos_expr), to_col]]
        let cnt = s:U.count_pattern(pattern, from, to)
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
        \          ? s:U.get_max_col(pos_expr) : 1
        let [from, to] = [getpos('.')[1:2], [line(pos_expr), to_col]]
        let cnt = s:U.count_pattern(pattern, from, to)
        let s:cli.vcount1 -= cnt
        if s:cli.vcount1 < 1
            let s:cli.vcount1 += s:U.count_pattern(pattern)
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
        let max_cnt = s:U.count_pattern(pattern, start, end)
        let s:cli.vcount1 = min([max_cnt, s:cli.vcount1])
    endif
endfunction

function! s:on_char(cmdline)
    call winrestview(s:w)
    let pattern = s:inc.get_pattern()

    if pattern ==# ''
        call s:hi.disable_all()
        return
    endif

    let pattern = incsearch#convert_with_case(pattern)

    " pseud-move cursor position: this is restored afterward if called by
    " <expr> mappings
    if a:cmdline.flag !=# 'n' " skip if stay mode
        if s:cli.is_expr
            for _ in range(s:cli.vcount1)
                " NOTE: This cannot handle {offset} for cursor position
                call search(pattern, a:cmdline.flag)
            endfor
        else
            " More precise cursor position while searching
            " Caveat:
            "   This block contains `normal`, please make sure <expr> mappings
            "   doesn't reach this block
            let is_visual_mode = s:U.is_visual(mode(1))
            let cmd = s:with_ignore_foldopen(
            \   function('s:build_search_cmd'),
            \   'n', s:cli.getline(), s:cli.get_prompt())
            " silent!:
            "   Shut up errors! because this is just for the cursor emulation
            "   while searching
            silent! exec 'keepjumps' 'normal!' cmd
            if is_visual_mode
                let w = winsaveview()
                normal! gv
                call winrestview(w)
                call incsearch#highlight#emulate_visual_highlight()
            endif
        endif
    endif

    " Highlight
    let hgm = incsearch#highlight#hgm()
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
    call incsearch#highlight#update()

    " pseudo-normal-zz after scroll
    if ( a:cmdline.is_input("<Over>(incsearch-scroll-f)")
    \ || a:cmdline.is_input("<Over>(incsearch-scroll-b)"))
        call winrestview({'topline': max([1, line('.') - winheight(0) / 2])})
    endif
endfunction

function! s:inc.on_char_pre(cmdline)
    call s:on_searching(function('s:on_char_pre'), a:cmdline)
endfunction

function! s:inc.on_char(cmdline)
    call s:on_searching(function('s:on_char'), a:cmdline)
endfunction

call s:cli.connect(s:inc)
"}}}

" Main: {{{
" @expr: called by <expr> mappings

function! incsearch#forward(mode, ...)
    if s:U.is_visual(a:mode)
        normal! gv
    endif
    call s:search_for_non_expr('/', get(a:, 1, v:count1))
endfunction

" @expr
function! incsearch#forward_expr()
    return s:search('/')
endfunction

function! incsearch#backward(mode, ...)
    if s:U.is_visual(a:mode)
        normal! gv
    endif
    call s:search_for_non_expr('?', get(a:, 1, v:count1))
endfunction

" @expr
function! incsearch#backward_expr()
    return s:search('?')
endfunction

" similar to incsearch#forward() but do not move the cursor unless explicitly
" move the cursor while searching
function! incsearch#stay(mode, ...)
    if s:U.is_visual(a:mode)
        normal! gv
    endif
    let m = mode(1)
    let cmd = incsearch#stay_expr(get(a:, 1, v:count1)) " arg: Please histadd for me!
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
        " NOTE: Should I emulate warning? But 'search hit BOTTOM, continuing
        " at TOP' is not appropriage warning message if the cursor doesn't
        " move?
        call s:emulate_search_error(s:DIRECTION.forward)
        call s:silent_after_search(m)
        call winrestview(s:w)
        if s:cli.flag !=# 'n' " if exit stay mode, set jumplist
            normal! m`
        endif
        silent! exec 'keepjumps' 'normal!' cmd
    endif
endfunction

" @expr but sometimes called by non-<expr>
function! incsearch#stay_expr(...)
    " return: command which is excutable with expr-mappings or `exec 'normal!'`
    let s:cli.vcount1 = get(a:, 1, v:count1)
    let m = mode(1)

    let input = s:get_input('', m)

    let [pattern, offset] = incsearch#parse_pattern(s:cli.getline(), s:cli.get_prompt())

    " execute histadd manually
    if s:cli.flag ==# 'n' && input !=# ''
         " NOTE: this is for non-expr mapping see incsearch#stay() and below NOTE:
        if (s:cli.is_expr || empty(offset))
            call histadd('/', input)
            let @/ = pattern
        endif
    endif

    if s:cli.flag ==# 'n' " stay TODO: better flag name
        " NOTE: do not move cursor but need to handle {offset} for n & N ...! {{{
        " FIXME: cannot set {offset} if in operator-pending mode because this
        " have to use feedkeys()
        if !empty(offset) && mode(1) !=# 'no'
            let cmd = s:with_ignore_foldopen(
            \   function('s:generate_command'), m, input, '/')
            call feedkeys(cmd, 'n')
            " XXX: string()... use <SNR> or <SID>? But it doesn't work well.
            call s:U.silent_feedkeys(":\<C-u>call winrestview(". string(s:w) . ")\<CR>", 'winrestview', 'n')
        endif
        " }}}
        return s:U.is_visual(m) ? "\<ESC>gv" : "\<ESC>" " just exit
    else " exit stay mode while searching
        return s:generate_command(m, input, '/') " assume '/'
    endif
endfunction

function! s:search(search_key, ...)
    let m = mode(1)
    let s:cli.is_expr = s:TRUE
    let s:cli.vcount1 = get(a:, 1, v:count1)
    let input = s:get_input(a:search_key, m)
    return s:generate_command(m, input, a:search_key)
endfunction

function! s:get_input(search_key, mode)
    " if search_key is empty, it means `stay` & do not move cursor
    let prompt = a:search_key ==# '' ? '/' : a:search_key
    call s:cli.set_prompt(prompt)
    let s:cli.flag = a:search_key ==# '/' ? ''
    \              : a:search_key ==# '?' ? 'b'
    \              : a:search_key ==# ''  ? 'n'
    \              : ''

    " Handle visual mode highlight
    if s:U.is_visual(a:mode)
        let visual_hl = incsearch#highlight#get_visual_hlobj()
        try
            call incsearch#highlight#turn_off(visual_hl)
            call incsearch#highlight#emulate_visual_highlight(a:mode, visual_hl)
            let input = s:cli.get()
        finally
            call incsearch#highlight#turn_on(visual_hl)
        endtry
    else
        let input = s:cli.get()
    endif
    return input
endfunction

function! s:generate_command(mode, pattern, search_key)
    if (s:cli.exit_code() == 0)
        call s:cli.callevent('on_execute_pre') " XXX: side-effect!
        return s:build_search_cmd(a:mode, a:pattern, a:search_key)
    else " Cancel
        return s:U.is_visual(a:mode) ? '\<ESC>gv' : "\<ESC>"
    endif
endfunction

function! s:build_search_cmd(mode, pattern, search_key)
    let op = (a:mode == 'no')      ? v:operator
    \      : s:U.is_visual(a:mode) ? 'gv'
    \      : ''
    let zv = (&foldopen =~# '\vsearch|all' && a:mode !=# 'no' ? 'zv' : '')
    " NOTE:
    "   Should I consider o_v, o_V, and o_CTRL-V cases and do not
    "   <Esc>? <Esc> exists for flexible v:count with using s:cli.vcount1,
    "   but, if you do not move the cursor while incremental searching,
    "   there are no need to use <Esc>.
    return printf("\<Esc>\"%s%s%s%s%s\<CR>%s",
    \   v:register, op, s:cli.vcount1, a:search_key, a:pattern, zv)
endfunction

" @normal, @visual: assume not operator-pending mode
function! s:search_for_non_expr(search_key, ...)
    let m = mode(1)
    let s:cli.vcount1 = get(a:, 1, v:count1)
    " side effect: move cursor
    let input = s:get_input(a:search_key, m)
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
        if g:incsearch#consistent_n_direction
            call s:_silent_searchforward(s:DIRECTION.forward)
        endif
    else
        " Add history if necessary
        call histadd(a:search_key, input)
        let @/ = pattern

        " Emulate errors, and handling `n` and `N` preparation {{{
        let target_view = winsaveview()
        call winrestview(s:w) " Get back start position temporarily for emulation
        " Set jump list
        normal! m`
        let d = (a:search_key == '/' ? s:DIRECTION.forward : s:DIRECTION.backward)
        call s:emulate_search_error(d)
        call winrestview(target_view)
        "}}}

        " Emulate warning {{{
        " NOTE:
        " - It should use :h echomsg considering emulation of default
        "   warning messages remain in the :h message-history, but it'll mess
        "   up the message-history unnecessary, so it use :h echo
        " - Echo warning message after winrestview() to avoid flickering
        " - See :h shortmess
        if &shortmess !~# 's' && g:incsearch#do_not_save_error_message_history
            let from = [s:w.lnum, s:w.col]
            let to = [target_view.lnum, target_view.col]
            let old_warningmsg = v:warningmsg
            let v:warningmsg =
            \   ( d == s:DIRECTION.forward && !s:U.is_pos_less_equal(from, to)
            \   ? 'search hit BOTTOM, continuing at TOP'
            \   : d == s:DIRECTION.backward && s:U.is_pos_less_equal(from, to)
            \   ? 'search hit TOP, continuing at BOTTOM'
            \   : '' )
            if v:warningmsg !=# ''
                call s:Warning(v:warningmsg)
            else
                let v:warningmsg = old_warningmsg
            endif
        endif
        "}}}

        call s:silent_after_search(m)

        " Open fold
        if &foldopen =~# '\vsearch|all'
            normal! zv
        endif
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

function! s:silent_after_search(...) " arg: mode(1)
    " :h function-search-undo
    " Handle :set hlsearch
    if get(a:, 1, mode(1)) !=# 'no' " guard for operator-mapping
        call s:_silent_hlsearch()
        call s:_silent_searchforward()
    endif
endfunction

function! s:_silent_hlsearch()
    call s:U.silent_feedkeys(":let &hlsearch=&hlsearch\<CR>", 'hlsearch', 'n')
endfunction

function! s:_silent_searchforward(...)
    " NOTE: You have to 'exec normal! `/` or `?`' before calling this
    " function to update v:searchforward
    let direction = get(a:, 1,
    \   (g:incsearch#consistent_n_direction == s:TRUE)
    \   ? s:DIRECTION.forward : v:searchforward)
    call s:U.silent_feedkeys(
    \   ":let v:searchforward=" . direction . "\<CR>",
    \   'searchforward', 'n')
endfunction

function! s:emulate_search_error(direction)
    let keyseq = (a:direction == s:DIRECTION.forward ? '/' : '?')
    let old_errmsg = v:errmsg
    let v:errmsg = ''
    " NOTE:
    "   - XXX: Handle `n` and `N` preparation with s:silent_after_search()
    "   - silent!: Do not show error and warning message, because it also
    "     echo v:throwpoint for error and save messages in message-history
    "   - Unlike v:errmsg, v:warningmsg doesn't set if it use :silent!
    let w = winsaveview()
    " Get first error
    silent! exec 'keepjumps' 'normal!' keyseq . "\<CR>"
    call winrestview(w)
    if g:incsearch#do_not_save_error_message_history
        if v:errmsg != ''
            call s:Error(v:errmsg)
        else
            let v:errmsg = old_errmsg
        endif
    else
        " NOTE: show more than two errors e.g. `/\za`
        let last_error = v:errmsg
        try
            " Show warning
            exec 'keepjumps' 'normal!' keyseq . "\<CR>"
        catch /^Vim\%((\a\+)\)\=:E/
            let first_error = matchlist(v:exception, '\v^Vim%(\(\a+\))=:(E.*)$')[1]
            call s:Error(first_error, 'echom')
            if last_error != '' && last_error !=# first_error
                call s:Error(last_error, 'echom')
            endif
        endtry
        if v:errmsg == ''
            let v:errmsg = old_errmsg
        endif
    endif
endfunction

" Should I use :h echoerr ? But it save the messages in message-history
function! s:Error(msg, ...)
    return call(function('s:_echohl'), [a:msg, 'ErrorMsg'] + a:000)
endfunction

function! s:Warning(msg, ...)
    return call(function('s:_echohl'), [a:msg, 'WarningMsg'] + a:000)
endfunction

function! s:_echohl(msg, hlgroup, ...)
    let echocmd = get(a:, 1, 'echo')
    redraw | echo ''
    exec 'echohl' a:hlgroup
    exec echocmd string(a:msg)
    echohl None
endfunction

" Not to generate command with zv
function! s:with_ignore_foldopen(F, ...)
    let foldopen_save = &foldopen
    let &foldopen=''
    try
        return call(a:F, a:000)
    finally
        let &foldopen = foldopen_save
    endtry
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
