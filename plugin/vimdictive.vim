function! s:FilterText()
  return exists('g:vimdictive_filter') ? g:vimdictive_filter : ''
endfunction

function! s:RhymeTerm()
  return exists('g:vimdictive_rhyme_term') ? g:vimdictive_rhyme_term : ''
endfunction

function! s:PreviewWindow(purpose, term)
  let filter = s:FilterText()
  let filter = filter == '' ? '' : '/' . filter . '/'
  let rhyme_term = s:RhymeTerm()
  let rhyme_term = rhyme_term == '' ? '' : '{' . rhyme_term . '}'
  let details = ''
  if a:purpose =~? 'Synonyms'
    let details = ':' . filter . rhyme_term
  endif
  silent! exe "noautocmd botright pedit vimdictive:[" . a:purpose[0] . details . ":'" . a:term . "']"
  noautocmd wincmd P
  setlocal modifiable
  setlocal buftype=nofile ff=unix
  setlocal nobuflisted
endfunction

function! s:FilterByRegex(synonyms)
  let filter = s:FilterText()
  return filter(a:synonyms, 'v:val =~ filter')
endfunction

function! s:FilterByRhyme(synonyms)
  let rhymes = vimdictive#rhyme(s:RhymeTerm())
  if rhymes == []
    return a:synonyms
  else
    return filter(a:synonyms, 'index(rhymes, v:val) != -1')
  endif
endfunction

function! s:FilterSynonyms(synonyms)
  return s:FilterByRegex(s:FilterByRhyme(a:synonyms))
endfunction

function! s:PreviewRefresh()
  if exists('b:purpose')
    call PreviewTerm(b:purpose, b:term)
  endif
endfunction

function! s:PreviewWindowMaps()
  nnoremap <buffer><silent> q :bw!<cr>
  nnoremap <buffer><silent><enter> :call PreviewTerm('Meanings', expand('<cword>'))<cr>
  nnoremap <buffer><silent><bs> :call PreviewTerm('Synonyms', expand('<cword>'))<cr>
  nnoremap <buffer><silent><f5> :call <SID>PreviewRefresh()<cr>
endfunction

function! PreviewTerm(purpose, term)
  call s:PreviewWindow(a:purpose, a:term)
  let b:purpose = a:purpose
  let b:term = a:term

  if a:purpose == 'Meanings'
    let data = vimdictive#meanings(a:term)
  else
    let data = s:FilterSynonyms(vimdictive#synonyms(a:term))
  endif
  if data == []
    let data = vimdictive#matches(a:term)
  endif
  if data == []
    call setline(1, ['No ' . a:purpose . ' for term: ' . a:term])
  else
    call setline(1, data)
  endif

  call s:PreviewWindowMaps()
endfunction

function! PreviewFilter(filter)
  if a:filter != ''
    let filter = a:filter
  else
    let filter = input('Filter: ', s:FilterText())
  endif
  let g:vimdictive_filter = filter
  call s:PreviewRefresh()
endfunction

function! PreviewRhyme(rhyme)
  if a:rhyme != ''
    let rhyme = a:rhyme
  else
    let rhyme = input('Rhyme: ', s:RhymeTerm())
  endif
  let g:vimdictive_rhyme_term = rhyme
  call s:PreviewRefresh()
endfunction

nnoremap <leader>dm :silent call PreviewTerm('Meanings', expand('<cword>'))<cr>
nnoremap <leader>ds :silent call PreviewTerm('Synonyms', expand('<cword>'))<cr>
nnoremap <leader>df :call PreviewFilter('')<cr>
nnoremap <leader>dr :call PreviewRhyme('')<cr>
