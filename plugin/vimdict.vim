function! s:FilterText()
  return exists('g:vimdictive_filter') ? g:vimdictive_filter : ''
endfunction

function! s:PreviewWindow(purpose, term)
  let filter = s:FilterText()
  let filter = filter == '' ? '' : ' =~ /' . filter . '/'
  silent! exe "noautocmd botright pedit vimdictive:[" . a:purpose[0] . filter . "]'" . a:term . "'"
  noautocmd wincmd P
  setlocal modifiable
  setlocal buftype=nofile ff=unix
  setlocal nobuflisted
endfunction

function! s:FilterSynonyms(synonyms)
  let filter = s:FilterText()
  return filter(a:synonyms, 'v:val =~ filter')
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

nnoremap <leader>dm :silent call PreviewTerm('Meanings', expand('<cword>'))<cr>
nnoremap <leader>ds :silent call PreviewTerm('Synonyms', expand('<cword>'))<cr>
nnoremap <leader>df :call PreviewFilter('')<cr>
