scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


function! s:_vital_loaded(V)
	let s:V = a:V
	let s:Buffer = a:V.import("Vim.Buffer")
endfunction


function! s:_vital_depends()
	return [
\		"Vim.Buffer",
\	]
endfunction


function! s:windo(func, args, ...)
	let dict = get(a:, 1, {})
	if len(tabpagebuflist()) <= 1 || s:Buffer.is_cmdwin()
		return call(a:func, a:args, dict)
	endif
	let pre_winnr = winnr()

	noautocmd windo call call(a:func, a:args, dict)
	
	if pre_winnr == winnr()
		return
	endif
	execute pre_winnr . "wincmd w"
endfunction


function! s:as_windo(base)
	let windo = {}
	let windo.obj = a:base
	for [key, Value] in items(a:base)
		if type(function("tr")) == type(Value)
			execute
\			"function! windo.". key. "(...)\n"
\			"	return s:windo(self.obj." . key . ", a:000, self.obj)\n"
\			"endfunction"
		endif
		unlet Value
	endfor
	return windo
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
