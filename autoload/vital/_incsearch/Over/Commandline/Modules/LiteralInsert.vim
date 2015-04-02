scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


let s:module = {
\	"name" : "LiteralInsert",
\}

function! s:module.on_char_pre(cmdline)
	if a:cmdline.is_input("\<C-v>")
\	|| a:cmdline.is_input("\<C-q>")
		call a:cmdline.setchar('^')
		let self.prefix_key = a:cmdline.input_key()
		let self.old_line = a:cmdline.getline()
		let self.old_pos  = a:cmdline.getpos()
		return
	elseif exists("self.prefix_key")
\		&& a:cmdline.get_tap_key() == self.prefix_key
		call a:cmdline.setline(self.old_line)
		call a:cmdline.setpos(self.old_pos)
		call a:cmdline.setchar(a:cmdline.input_key())
	endif
endfunction

function! s:module.on_char(cmdline)
	if a:cmdline.is_input("\<C-v>")
\	|| a:cmdline.is_input("\<C-q>")
		call a:cmdline.tap_keyinput(self.prefix_key)
		call a:cmdline.disable_keymapping()
		call a:cmdline.setpos(a:cmdline.getpos()-1)
	else
		if exists("self.prefix_key")
			call a:cmdline.untap_keyinput(self.prefix_key)
			call a:cmdline.enable_keymapping()
			unlet! self.prefix_key
		endif
	endif
endfunction


function! s:make()
	return deepcopy(s:module)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
