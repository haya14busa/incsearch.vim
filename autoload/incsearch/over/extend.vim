"=============================================================================
" FILE: autoload/incsearch/over/extend.vim
" AUTHOR: haya14busa
" License: MIT license
"=============================================================================
scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:U = incsearch#util#import()

function! incsearch#over#extend#enrich(cli) abort
  return extend(a:cli, s:cli)
endfunction

let s:cli = {}

function! s:cli._generate_command(input) abort
  let is_cancel = self.exit_code()
  if is_cancel
    return s:U.is_visual(self._mode) ? '\<ESC>gv' : "\<ESC>"
  else
    call self._call_execute_event()
    let [pattern, offset] = incsearch#parse_pattern(a:input, self._base_key)
    " TODO: implement convert input method
    let p = incsearch#combine_pattern(self, incsearch#convert(pattern), offset)
    return self._build_search_cmd(p)
  endif
endfunction

" @return search cmd
function! s:cli._build_search_cmd(pattern) abort
  let op = (self._mode == 'no')      ? v:operator
  \      : s:U.is_visual(self._mode) ? 'gv'
  \      : ''
  let zv = (&foldopen =~# '\vsearch|all' && self._mode !=# 'no' ? 'zv' : '')
  " NOTE:
  "   Should I consider o_v, o_V, and o_CTRL-V cases and do not
  "   <Esc>? <Esc> exists for flexible v:count with using s:cli._vcount1,
  "   but, if you do not move the cursor while incremental searching,
  "   there are no need to use <Esc>.
  return printf("\<Esc>\"%s%s%s%s%s\<CR>%s",
  \   v:register, op, self._vcount1, self._base_key, a:pattern, zv)
endfunction

function! s:cli._call_execute_event(...) abort
  let view = get(a:, 1, winsaveview())
  try
    call winrestview(self._w)
    call self.callevent('on_execute_pre')
  finally
    call winrestview(view)
  endtry
  call self.callevent('on_execute')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" __END__
" vim: expandtab softtabstop=2 shiftwidth=2 foldmethod=marker
