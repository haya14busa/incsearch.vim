"=============================================================================
" FILE: autoload/incsearch/cli.vim
" AUTHOR: haya14busa
" License: MIT license
"=============================================================================
scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:TRUE = !0
let s:FALSE = 0
let s:DIRECTION = { 'forward': 1, 'backward': 0 } " see :h v:searchforward

let s:V = vital#of(g:incsearch#debug ? 'vital' : 'incsearch')
let s:hi = g:incsearch#highlight#_hi
let s:U = incsearch#util#import()

function! incsearch#cli#get() abort
  try
    " It returns current cli object
    return s:Doautocmd.get_cmdline()
  catch /vital-over(_incsearch) Exception/
    " If there are no current cli object, return default one
    " return s:cli
    return s:cli
  endtry
endfunction

function! incsearch#cli#make(config) abort
  let cli = s:copy_cli(s:cli)
  let cli._base_key = a:config.command
  let cli._vcount1 = a:config.count1
  let cli._is_expr = a:config.is_expr
  let cli._mode = a:config.mode
  let cli._pattern = a:config.pattern
  for module in a:config.modules
    call cli.connect(module)
  endfor
  call cli.connect(s:InsertRegister)
  return cli
endfunction

function! incsearch#cli#Doautocmd() abort
  return s:Doautocmd
endfunction

"" partial deepcopy() for cli.connect(module) instead of copy()
function! s:copy_cli(cli) abort
  let cli = copy(a:cli)
  let cli.variables = deepcopy(a:cli.variables)
  return cli
endfunction

" CommandLine Interface: {{{
let s:cli = s:V.import('Over.Commandline').make_default("/")
let s:modules = s:V.import('Over.Commandline.Modules')

" Add modules
call s:cli.connect('BufferComplete')
call s:cli.connect('Cancel')
call s:cli.connect('CursorMove')
call s:cli.connect('Digraphs')
call s:cli.connect('Delete')
call s:cli.connect('DrawCommandline')
call s:cli.connect('ExceptionExit')
call s:cli.connect('LiteralInsert')
call s:cli.connect('AsyncUpdate')
" call s:cli.connect('Exit')
" NOTE:
" <CR> in {rhs} wil be remapped even after exiting vital-over comman line
" interface, so do not use <Over>(exit)
" See also s:cli.keymapping()
let s:incsearch_exit = {
\   "name" : "IncsearchExit",
\   "exit_code" : 0
\}
function! s:incsearch_exit.on_char_pre(cmdline) abort
  if   a:cmdline.is_input("\<CR>")
  \ || a:cmdline.is_input("\<NL>")
    call a:cmdline.setchar("")
    call a:cmdline.exit(self.exit_code)
  endif
endfunction
call s:cli.connect(s:incsearch_exit)

" Lazy connect
let s:InsertRegister = s:modules.get('InsertRegister').make()

call s:cli.connect('Paste')
let s:Doautocmd = s:modules.get('Doautocmd')
call s:cli.connect(s:Doautocmd.make('IncSearch'))
call s:cli.connect(s:modules.get('ExceptionMessage').make('incsearch.vim: ', 'echom'))
call s:cli.connect(s:modules.get('History').make('/'))
call s:cli.connect(s:modules.get('NoInsert').make_special_chars())

" Dynamic Module Loading Management
let s:KeyMapping = s:modules.get('KeyMapping')
let s:emacs_like = s:KeyMapping.make_emacs()
let s:vim_cmap = s:KeyMapping.make_vim_cmdline_mapping()
let s:smartbackword = s:modules.get('IgnoreRegexpBackwardWord').make()
function! s:emacs_like._condition() abort
  return g:incsearch#emacs_like_keymap
endfunction
function! s:vim_cmap._condition() abort
  return g:incsearch#vim_cmdline_keymap
endfunction
function! s:smartbackword._condition() abort
  return g:incsearch#smart_backward_word
endfunction
call s:cli.connect(incsearch#over#modules#module_management#make([s:emacs_like, s:vim_cmap, s:smartbackword]))
unlet s:KeyMapping s:emacs_like s:vim_cmap s:smartbackword s:incsearch_exit

let s:pattern_saver =  {
\   'name' : 'PatternSaver',
\   'pattern' : '',
\   'hlsearch' : &hlsearch
\}
function! s:pattern_saver.on_enter(cmdline) abort
  if ! g:incsearch#no_inc_hlsearch
    let self.pattern = @/
    let self.hlsearch = &hlsearch
    if exists('v:hlsearch')
      let self.vhlsearch = v:hlsearch
    endif
    set hlsearch | nohlsearch
  endif
endfunction
function! s:pattern_saver.on_leave(cmdline) abort
  if ! g:incsearch#no_inc_hlsearch
    let is_cancel = a:cmdline.exit_code()
    if is_cancel
      let @/ = self.pattern
    endif
    let &hlsearch = self.hlsearch
    if exists('v:hlsearch')
      let v:hlsearch = self.vhlsearch
    endif
  endif
endfunction
call s:cli.connect(s:pattern_saver)

let s:default_keymappings = {
\   "\<Tab>"   : {
\       "key" : "<Over>(incsearch-next)",
\       "noremap" : 1,
\   },
\   "\<S-Tab>"   : {
\       "key" : "<Over>(incsearch-prev)",
\       "noremap" : 1,
\   },
\   "\<C-j>"   : {
\       "key" : "<Over>(incsearch-scroll-f)",
\       "noremap" : 1,
\   },
\   "\<C-k>"   : {
\       "key" : "<Over>(incsearch-scroll-b)",
\       "noremap" : 1,
\   },
\   "\<C-l>"   : {
\       "key" : "<Over>(buffer-complete)",
\       "noremap" : 1,
\   },
\   "\<CR>"   : {
\       "key": "\<CR>",
\       "noremap": 1
\   },
\ }

" https://github.com/haya14busa/incsearch.vim/issues/35
if has('mac')
  call extend(s:default_keymappings, {
  \   '"+gP'   : {
  \       'key': "\<C-r>+",
  \       'noremap': 1
  \   },
  \ })
endif

" FIXME: arguments?
function! s:cli.keymapping(...) abort
  return extend(copy(s:default_keymappings), g:incsearch_cli_key_mappings)
endfunction

let s:inc = {
\   "name" : "incsearch",
\}

" NOTE: for InsertRegister handling
function! s:inc.priority(event) abort
  return a:event is# 'on_char' ? 10 : 0
endfunction

function! s:inc.on_enter(cmdline) abort
  nohlsearch " disable previous highlight
  " let s:w = winsaveview()
  let a:cmdline._w = winsaveview()
  let hgm = incsearch#highlight#hgm()
  let c = hgm.cursor
  call s:hi.add(c.group, c.group, '\%#', c.priority)
  call incsearch#highlight#update()

  " XXX: Manipulate search history for magic option
  " In the first place, I want to omit magic flag when histadd(), but
  " when returning cmd as expr mapping and feedkeys() cannot handle it, so
  " remove no user intended magic flag at on_enter.
  " Maybe I can also handle it with autocmd, should I use autocmd instead?
  let hist = histget('/', -1)
  if len(hist) > 2 && hist[:1] ==# incsearch#magic()
    call histdel('/', -1)
    call histadd('/', hist[2:])
  endif
endfunction

function! s:inc.on_leave(cmdline) abort
  call s:hi.disable_all()
  call s:hi.delete_all()
  " redraw: hide pseud-cursor
  redraw " need to redraw for handling non-<expr> mappings
  if a:cmdline.getline() ==# ''
    echo ''
  else
    echo a:cmdline.get_prompt() . a:cmdline.getline()
  endif
  " NOTE:
  "   push rest of keymappings with feedkeys()
  "   FIXME: assume 'noremap' but it should take care wheter or not the
  "   mappings should be remapped or not
  if a:cmdline.input_key_stack_string() != ''
    call feedkeys(a:cmdline.input_key_stack_string(), 'n')
  endif
endfunction

" Avoid search-related error while incremental searching
function! s:on_searching(func, ...) abort
  try
    return call(a:func, a:000)
  catch /E16:/  " E16: Invalid range  (with /\_[a- )
  catch /E33:/  " E33: No previous substitute regular expression
  catch /E53:/  " E53: Unmatched %(
  catch /E54:/
  catch /E55:/
  catch /E62:/  " E62: Nested \= (with /a\=\=)
  catch /E63:/  " E63: invalid use of \_
  catch /E64:/  " E64: \@ follows nothing
  catch /E65:/  " E65: Illegal back reference
  catch /E66:/  " E66: \z( not allowed here
  catch /E67:/  " E67: \z1 et al. not allowed here
  catch /E68:/  " E68: Invalid character after \z (with /\za & re=1)
  catch /E69:/  " E69: Missing ] after \%[
  catch /E70:/  " E70: Empty \%[]
  catch /E71:/  " E71: Invalid character after \%
  catch /E554:/
  catch /E678:/ " E678: Invalid character after \%[dxouU]
  catch /E864:/ " E864: \%#= can only be followed by 0, 1, or 2. The
                "       automatic engine will be used
  catch /E865:/ " E865: (NFA) Regexp end encountered prematurely
  catch /E866:/ " E866: (NFA regexp) Misplaced @
  catch /E867:/ " E867: (NFA) Unknown operator
  catch /E869:/ " E869: (NFA) Unknown operator '\@m
  catch /E870:/ " E870: (NFA regexp) Error reading repetition limits
  catch /E871:/ " E871: (NFA regexp) Can't have a multi follow a multi !
  catch /E874:/ " E874: (NFA) Could not pop the stack ! (with \&)
  catch /E877:/ " E877: (NFA regexp) Invalid character class: 109
  catch /E888:/ " E888: (NFA regexp) cannot repeat (with /\ze*)
    call s:hi.disable_all()
  catch
    echohl ErrorMsg | echom v:throwpoint . " " . v:exception | echohl None
  endtry
endfunction

function! s:on_char_pre(cmdline) abort
  " NOTE:
  " `:call a:cmdline.setchar('')` as soon as possible!
  let [pattern, offset] = incsearch#cli_parse_pattern(a:cmdline)

  " Interactive :h last-pattern if pattern is empty
  if ( a:cmdline.is_input("<Over>(incsearch-next)")
  \ || a:cmdline.is_input("<Over>(incsearch-prev)")
  \ ) && empty(pattern)
    call a:cmdline.setchar('')
    " Use history instead of @/ to work with magic option and converter
    call a:cmdline.setline(histget('/', -1) . (empty(offset) ? '' : a:cmdline._base_key) . offset)
    " Just insert last-pattern and do not count up, but the incsearch-prev
    " should move the cursor to reversed directly, so do not return if the
    " command is prev
    if a:cmdline.is_input("<Over>(incsearch-next)") | return | endif
  endif

  if a:cmdline.is_input("<Over>(incsearch-next)")
    call a:cmdline.setchar('')
    if a:cmdline.flag ==# 'n' " exit stay mode
      let a:cmdline.flag = ''
    else
      let a:cmdline._vcount1 += 1
    endif
  elseif a:cmdline.is_input("<Over>(incsearch-prev)")
    call a:cmdline.setchar('')
    if a:cmdline.flag ==# 'n' " exit stay mode
      let a:cmdline.flag = ''
    endif
    let a:cmdline._vcount1 -= 1
    if a:cmdline._vcount1 < 1
      let a:cmdline._vcount1 += s:U.count_pattern(pattern)
    endif
  elseif (a:cmdline.is_input("<Over>(incsearch-scroll-f)")
  \ &&   (a:cmdline.flag ==# '' || a:cmdline.flag ==# 'n'))
  \ ||   (a:cmdline.is_input("<Over>(incsearch-scroll-b)") && a:cmdline.flag ==# 'b')
    call a:cmdline.setchar('')
    if a:cmdline.flag ==# 'n' | let a:cmdline.flag = '' | endif
    let pos_expr = a:cmdline.is_input("<Over>(incsearch-scroll-f)") ? 'w$' : 'w0'
    let to_col = a:cmdline.is_input("<Over>(incsearch-scroll-f)")
    \          ? s:U.get_max_col(pos_expr) : 1
    let [from, to] = [getpos('.')[1:2], [line(pos_expr), to_col]]
    let cnt = s:U.count_pattern(pattern, from, to)
    let a:cmdline._vcount1 += cnt
  elseif (a:cmdline.is_input("<Over>(incsearch-scroll-b)")
  \ &&   (a:cmdline.flag ==# '' || a:cmdline.flag ==# 'n'))
  \ ||   (a:cmdline.is_input("<Over>(incsearch-scroll-f)") && a:cmdline.flag ==# 'b')
    call a:cmdline.setchar('')
    if a:cmdline.flag ==# 'n'
      let a:cmdline.flag = ''
      let a:cmdline._vcount1 -= 1
    endif
    let pos_expr = a:cmdline.is_input("<Over>(incsearch-scroll-f)") ? 'w$' : 'w0'
    let to_col = a:cmdline.is_input("<Over>(incsearch-scroll-f)")
    \          ? s:U.get_max_col(pos_expr) : 1
    let [from, to] = [getpos('.')[1:2], [line(pos_expr), to_col]]
    let cnt = s:U.count_pattern(pattern, from, to)
    let a:cmdline._vcount1 -= cnt
    if a:cmdline._vcount1 < 1
      let a:cmdline._vcount1 += s:U.count_pattern(pattern)
    endif
  endif

  " Handle nowrapscan:
  "   if you `:set nowrapscan`, you can't move to the reversed direction
  if &wrapscan == s:FALSE && (
  \    a:cmdline.is_input("<Over>(incsearch-next)")
  \ || a:cmdline.is_input("<Over>(incsearch-prev)")
  \ || a:cmdline.is_input("<Over>(incsearch-scroll-f)")
  \ || a:cmdline.is_input("<Over>(incsearch-scroll-b)")
  \ )
    call a:cmdline.setchar('')
    let [from, to] = [[a:cmdline._w.lnum, a:cmdline._w.col],
    \       a:cmdline.flag !=# 'b'
    \       ? [line('$'), s:U.get_max_col('$')]
    \       : [1, 1]
    \   ]
    let max_cnt = s:U.count_pattern(pattern, from, to)
    let a:cmdline._vcount1 = min([max_cnt, a:cmdline._vcount1])
  endif
endfunction

function! s:on_char(cmdline) abort
  let [raw_pattern, offset] = incsearch#cli_parse_pattern(a:cmdline)

  if raw_pattern ==# ''
    call s:hi.disable_all()
    nohlsearch
    return
  endif

  " For InsertRegister
  if a:cmdline.get_tap_key() ==# "\<C-r>"
    let p = a:cmdline.getpos()
    " Remove `"`
    let raw_pattern = raw_pattern[:p-1] . raw_pattern[p+1:]
    let w = winsaveview()
    call cursor(line('.'), col('.') + len(a:cmdline.backward_word()))
    call s:InsertRegister.reset()
    call winrestview(w)
  endif

  let pattern = incsearch#convert(raw_pattern)

  " Improved Incremental cursor move!
  call s:move_cursor(a:cmdline, pattern, offset)

  " Improved Incremental highlighing!
  " case: because matchadd() doesn't handle 'ignorecase' nor 'smartcase'
  let case = incsearch#detect_case(raw_pattern)
  let should_separate = g:incsearch#separate_highlight && a:cmdline.flag !=# 'n'
  let d = (a:cmdline.flag !=# 'b' ? s:DIRECTION.forward : s:DIRECTION.backward)
  call incsearch#highlight#incremental_highlight(
  \   pattern . case, should_separate, d, [a:cmdline._w.lnum, a:cmdline._w.col])

  " functional `normal! zz` after scroll for <expr> mappings
  if ( a:cmdline.is_input("<Over>(incsearch-scroll-f)")
  \ || a:cmdline.is_input("<Over>(incsearch-scroll-b)"))
    call winrestview({'topline': max([1, line('.') - winheight(0) / 2])})
  endif
endfunction

" Caveat: It handle :h last-pattern, so be careful if you want to pass empty
" string as a pattern
function! s:move_cursor(cli, pattern, ...) abort
  let offset = get(a:, 1, '')
  if a:cli.flag ==# 'n' " skip if stay mode
    return
  endif
  call winrestview(a:cli._w)
  " pseud-move cursor position: this is restored afterward if called by
  " <expr> mappings
  if a:cli._is_expr
    for _ in range(a:cli._vcount1)
      " NOTE: This cannot handle {offset} for cursor position
      call search(a:pattern, a:cli.flag)
    endfor
  else
    " More precise cursor position while searching
    " Caveat:
    "   This block contains `normal`, please make sure <expr> mappings
    "   doesn't reach this block
    let is_visual_mode = s:U.is_visual(mode(1))
    let cmd = incsearch#with_ignore_foldopen(
    \   function('incsearch#build_search_cmd'),
    \   a:cli, 'n', incsearch#combine_pattern(a:cli, a:pattern, offset), a:cli._base_key)
    " NOTE:
    " :silent!
    "   Shut up errors! because this is just for the cursor emulation
    "   while searching
    silent! call incsearch#execute_search(cmd)
    if is_visual_mode
      let w = winsaveview()
      normal! gv
      call winrestview(w)
      call incsearch#highlight#emulate_visual_highlight()
    endif
  endif
endfunction

function! s:inc.on_char_pre(cmdline) abort
  call s:on_searching(function('s:on_char_pre'), a:cmdline)
endfunction

function! s:inc.on_char(cmdline) abort
  call s:on_searching(function('s:on_char'), a:cmdline)
endfunction

call s:cli.connect(s:inc)

let &cpo = s:save_cpo
unlet s:save_cpo
" __END__
" vim: expandtab softtabstop=2 shiftwidth=2 foldmethod=marker
