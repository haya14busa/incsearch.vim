scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:modules = [
\	"Scroll",
\	"CursorMove",
\	"Delete",
\	"HistAdd",
\	"History",
\	"Cancel",
\	"Execute",
\	"NoInsert",
\	"InsertRegister",
\	"Redraw",
\	"DrawCommandline",
\	"ExceptionExit",
\	"ExceptionMessage",
\]


function! s:_vital_loaded(V)
	let s:V = a:V
	let s:Cmdline = s:V.import("Over.Commandline.Base")
	let s:Modules = s:V.import("Over.Commandline.Modules")
	let s:base.variables.modules = s:Signals.make()
	function! s:base.variables.modules.get_slot(val)
		return a:val.slot.module
	endfunction
endfunction


function! s:_vital_depends()
	return [
\		"Over.Commandline.Base",
\		"Over.Commandline.Modules",
\	] + map(copy(s:modules), "'Over.Commandline.Modules.' . v:val")
endfunction


function! s:default(...)
	return call(s:Cmdline.make, a:000, s:Cmdline)
endfunction


function! s:plain()
	return s:Cmdline.plain()
endfunction


function! s:standard(...)
	let result = call(s:Cmdline.make, a:000, s:Cmdline)
	call result.connect("Execute")
	call result.connect("Cancel")
	call result.connect("Delete")
	call result.connect("CursorMove")
	call result.connect("HistAdd")
	call result.connect("History")
	call result.connect("InsertRegister")
	call result.connect(s:Modules.get("NoInsert").make_special_chars())
	call result.connect("Redraw")
	call result.connect("DrawCommandline")
	call result.connect("ExceptionExit")
	call result.connect("ExceptionMessage")
	call result.connect(s:Modules.get("KeyMapping").make_vim_cmdline_mapping())
	call result.connect("Digraphs")
	call result.connect("LiteralInsert")

	return result
endfunction


function! s:standard_search(...)
	let result = s:standard(get(a:, 1, "/"))
	call result.connect(s:Modules.get("Execute").make_search("/"))
	call result.connect(s:Modules.make("HistAdd", "/"))
	call result.connect(s:Modules.make("History", "/"))
	return result
endfunction


function! s:standard_search_back(...)
	let result = s:standard(get(a:, 1, "?"))
	call result.connect(s:Modules.get("Execute").make_search("?"))
	call result.connect(s:Modules.make("HistAdd", "/"))
	call result.connect(s:Modules.make("History", "/"))
	return result
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
