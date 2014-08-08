scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


function! s:_vital_loaded(V)
	let s:V = a:V
	let s:Maker = s:V.import("Over.Commandline.Maker")
	let s:Modules = s:V.import("Over.Commandline.Modules")
endfunction


function! s:_vital_depends()
	return [
\		"Over.Commandline.Maker",
\		"Over.Commandline.Modules",
\		"Over.Commandline.Modules.All",
\	]
endfunction


function! s:make_module(...)
	return call(s:Modules.make, a:000, s:Modules)
endfunction


function! s:get_module(...)
	return call(s:Modules.get, a:000, s:Modules)
endfunction


function! s:make_default(...)
	return call(s:Maker.default, a:000, s:Maker)
endfunction


function! s:make_standard(...)
	return call(s:Maker.standard, a:000, s:Maker)
endfunction


function! s:make_standard_search(...)
	return call(s:Maker.standard_search, a:000, s:Maker)
endfunction


function! s:make_standard_search_back(...)
	return call(s:Maker.standard_search_back, a:000, s:Maker)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
