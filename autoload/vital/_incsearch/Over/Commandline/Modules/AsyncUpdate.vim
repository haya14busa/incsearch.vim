scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V)
	let s:V = a:V
endfunction


let s:module = {
\	"name" : "AsyncUpdate"
\}

function! s:module.on_enter(cmdline)
	function! a:cmdline._update()
		call self.callevent("on_update")
		if !getchar(1)
			return
		endif

		call self._input(s:V.import("Over.Commandline.Base").getchar(0))
		call self.draw()
	endfunction
endfunction


function! s:make()
	return deepcopy(s:module)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
