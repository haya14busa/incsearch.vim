"=============================================================================
" FILE: autoload/incsearch/config.vim
" AUTHOR: haya14busa
" License: MIT license
"=============================================================================
scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:TRUE = !0
let s:FALSE = 0
lockvar s:TRUE s:FALSE

"" incsearch config
" TODO: more detail documentation
" @command is equivalent with base_key TODO: fix this inconsistence
" @count1 default: v:count1 secret
" @mode default: mode(1) secret
let s:config = {
\   'command': '/',
\   'is_stay': s:FALSE,
\   'is_expr': s:FALSE,
\   'pattern': '',
\   'mode': 'n',
\   'count1': 1,
\   'prompt': '',
\   'modules': []
\ }

" @return config for lazy value
function! s:lazy_config() abort
  let m = mode(1)
  return {'count1': v:count1, 'mode': m, 'is_expr': (m is# 'no')}
endfunction

" @return config with default value
function! incsearch#config#make(additional) abort
  let default = extend(copy(s:config), s:lazy_config())
  let c = extend(default, a:additional)
  if c.prompt is# ''
    let c.prompt = c.command
  endif
  return c
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" __END__
" vim: expandtab softtabstop=2 shiftwidth=2 foldmethod=marker
