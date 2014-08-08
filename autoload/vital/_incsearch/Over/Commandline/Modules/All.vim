scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


let s:modules =  map(split(globpath(expand("<sfile>:p:h"), "/*.vim"), "\n"), "fnamemodify(v:val, ':t:r')")


function! s:_vital_depends()
	return map(copy(s:modules), "'Over.Commandline.Modules.' . v:val")
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
