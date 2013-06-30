let vimdictive_dicts = {
      \ 'dictionary' : ['dict.org', ['gcide']],
      \ 'thesaurus' : ['dict.org', ['moby-thes']]
      \ }

" If you have your own dict server:
" let vimdictive_dicts = {
"       \ 'dictionary' : ['localhost', ['gcide']],
"       \ 'thesaurus' : ['localhost', ['moby-thesaurus']]
"       \ }

function! vimdictive#lookup(dictionary, term)
  let host = g:vimdictive_dicts[a:dictionary]
  let results = []
  for db in host[1]
    let r = system(g:dict_curl_command . ' -s ' . g:dict_curl_options . ' dict://' . host[0] . '/d:"' . a:term . '":' . db)
    let result = s:uncurl(r, a:term, db)
    call add(results, result)
  endfor
  return results
endfunction

function! s:trim(text)
  return substitute(substitute(a:text, '^\_s*', '', ''), '\_s*$', '', '')
endfunction

function! s:uncurl(text, term, db)
  let r = ''
  let capture = 0
  let text = substitute(a:text, '\r', '', 'g')
  for s in split(text, '\n')
    if s =~ '^\_s*$'
      continue
    endif
    if s =~ '^\.'
      let capture = 0
    endif
    if capture == 1
      let r .= s . "\n"
    endif
    if s =~? '^151\s\+"' . a:term . '"\s\+' . a:db
      let capture = 1
    endif
  endfor
  return {'term' : a:term, 'db' : a:db, 'entry' : s:trim(r)}
endfunction

function! vimdictive#entries(dictionary, term)
  let entries = vimdictive#lookup(a:dictionary, a:term)
  return map(entries, 'v:val["entry"]')
endfunction

function! vimdictive#synonyms(term)
  let syn = {}
  for entry in vimdictive#entries('thesaurus', a:term)
    let entry = substitute(entry, '^.*:\n\s*', '', '')
    call map(split(entry, ',\_s*'), 'extend(syn, {v:val : 0})')
  endfor
  return sort(keys(syn))
endfunction

function! vimdictive#meanings(term)
  let meanings = []
  for entry in vimdictive#entries('dictionary', a:term)
    call extend(meanings, split(entry, '\n'))
  endfor
  return meanings
endfunction
