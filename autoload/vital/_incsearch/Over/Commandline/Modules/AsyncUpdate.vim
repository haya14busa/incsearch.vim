scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V)
	let s:V = a:V
	let s:Base = s:V.import("Over.Commandline.Base")
endfunction


let s:module = {
\	"name" : "AsyncUpdate"
\}

function! s:module.on_enter(cmdline)
	function! a:cmdline._update()
		call self.callevent("on_update")
		try
			if !getchar(1)
				return
			endif
			let key = s:Base.getchar(0)
		catch /^Vim:Interrupt$/
			let key = "\<C-c>"
		endtry

		call self._input(key)
		call self.draw()
	endfunction
endfunction


function! s:make()
	return deepcopy(s:module)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
