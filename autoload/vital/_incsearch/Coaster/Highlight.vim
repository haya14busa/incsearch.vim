scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:base = {
\	"variables" : {
\		"hl_list" : {},
\		"id_list" : {}
\	}
\}


function! s:base.add(name, group, pattern, ...)
	call self.delete(a:name)
	let priority = get(a:, 1, 10)
	let self.variables.hl_list[a:name] = {
\		"group" : a:group,
\		"pattern" : a:pattern,
\		"priority" : priority,
\	}
endfunction


function! s:base.is_added(name)
	return has_key(self.variables.hl_list, a:name)
endfunction


function! s:base.hl_list()
	return keys(self.variables.hl_list)
endfunction


function! s:base.enable_list(...)
	let bufnr = get(a:, 1, bufnr("%"))
	return keys(get(self.variables.id_list, bufnr, {}))
endfunction


function! s:base.delete(name)
	if !self.is_added(a:name)
		return -1
	endif
	unlet! self.variables.hl_list[a:name]
endfunction


function! s:base.delete_by(expr)
	for [name, _] in items(self.variables.hl_list)
		let group = _.group
		let pattern = _.pattern
		let priority = _.priority
		if eval(a:expr)
			call self.delete(name)
		endif
	endfor
endfunction


function! s:base.delete_all()
	for name in self.hl_list()
		call self.delete(name)
	endfor
endfunction


function! s:base.get_hl_id(name, ...)
	let bufnr = get(a:, 1, bufnr("%"))
	return get(get(self.variables.id_list, bufnr, {}), a:name, "")
endfunction


function! s:base.is_enabled(name, ...)
	let bufnr = get(a:, 1, bufnr("%"))
	return self.get_hl_id(a:name, bufnr) != ""
endfunction


function! s:base.enable(name)
	let hl = get(self.variables.hl_list, a:name, {})
	if empty(hl)
		return -1
	endif
	if self.is_enabled(a:name)
		call self.disable(a:name)
	endif
	if !has_key(self.variables.id_list, bufnr("%"))
		let self.variables.id_list[bufnr("%")] = {}
	endif
	let self.variables.id_list[bufnr("%")][a:name] = matchadd(hl.group, hl.pattern, hl.priority)
endfunction


function! s:base.enable_all()
	for name in self.hl_list()
		call self.enable(name)
	endfor
endfunction


function! s:base.disable(name)
	if !self.is_enabled(a:name)
		return -1
	endif
	let id = -1
	silent! let id = matchdelete(self.get_hl_id(a:name))
	if id == -1
		return -1
	endif
	let bufnr = bufnr("%")
	unlet! self.variables.id_list[bufnr][a:name]
endfunction


function! s:base.disable_all()
	for name in self.enable_list()
		call self.disable(name)
	endfor
endfunction


function! s:base.highlight(name, group, pattern, ...)
	let priority = get(a:, 1, 10)
	call self.add(a:name, a:group, a:pattern, priority)
	call self.enable(a:name)
endfunction


function! s:base.clear(name)
	call self.disable(a:name)
	call self.delete(a:name)
endfunction


function! s:base.clear_all()
	call self.disable_all()
	call self.delete_all()
endfunction


function! s:make()
	let result = deepcopy(s:base)
	return result
endfunction


let s:global = s:make()
let s:funcs =  keys(filter(copy(s:global), "type(v:val) == type(function('tr'))"))

for s:name in s:funcs
	execute
\		"function! s:" . s:name . "(...) \n"
\			"return call(s:global." . s:name . ", a:000, s:global) \n"
\		"endfunction"
endfor
unlet s:name


let &cpo = s:save_cpo
unlet s:save_cpo
