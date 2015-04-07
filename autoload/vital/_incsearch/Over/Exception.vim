scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


let s:vname = expand("<sfile>:h:h:t")
let s:prefix = printf("== vital-over(%s)", s:vname)


function! s:throw_cmd(exp, where)
	return 'throw ' . string(s:prefix . " : " . a:exp . " in " . a:where)
endfunction


function! s:throw(exp, where)
	execute s:throw_cmd(a:exp, a:where)
endfunction


function! s:error(text, where)
	echohl ErrorMsg
	echom s:prefix . " : " . a:text . " in " . a:where
	echohl None
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
