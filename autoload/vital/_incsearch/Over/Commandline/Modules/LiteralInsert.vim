scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


let s:module = {
\	"name" : "LiteralInsert",
\}

function! s:module.on_char_pre(cmdline)
	if a:cmdline.is_input("\<C-v>")
\	|| a:cmdline.is_input("\<C-q>")
		let old_line = a:cmdline.getline()
		let old_pos  = a:cmdline.getpos()
		call a:cmdline.insert('^')
		call a:cmdline.setpos(old_pos)
		call a:cmdline.draw()
		let char = a:cmdline.getchar()
		call a:cmdline.setline(old_line)
		call a:cmdline.setpos(old_pos)
		call a:cmdline.setchar(char)
	endif
endfunction

function! s:make()
	return deepcopy(s:module)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
