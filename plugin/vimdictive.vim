" dict.org dictionarty & thesaurus browser
" Maintainer:	Barry Arthur     <barry.arthur@gmail.com>
"       	Israel Chauca F. <israelchauca@gmail.com>
" Version:	0.1
" Description:	A dict.org compatible dictionarty & thesaurus browser for Vim
" Last Change:	2013-07-01
" License:	Vim License (see :help license)
" Location:	plugin/vimdictive.vim
" Website:	https://github.com/dahu/vimdictive
"
" See vimdictive.txt for help.  This can be accessed by doing:
"
" :helptags ~/.vim/doc
" :help vimdictive

" Vimscript Setup: {{{1
" Allow use of line continuation.
let s:save_cpo = &cpo
set cpo&vim

" load guard
" uncomment after plugin development.
" XXX The conditions are only as examples of how to use them. Change them as
" needed. XXX
"if exists("g:loaded_vimdictive")
"      \ || v:version < 700
"      \ || v:version == 703 && !has('patch338')
"      \ || &compatible
"  let &cpo = s:save_cpo
"  finish
"endif
"let g:loaded_vimdictive = 1

" Options: {{{1

" Private Functions: {{{1

function! s:FilterText()
  return get(g:, 'vimdictive_filter', '')
endfunction

function! s:RhymeTerm()
  return get(g:, 'vimdictive_rhyme_term', '')
endfunction

function! s:PreviewWindow(purpose, term)
  let filter = s:FilterText()
  let filter = empty(filter) ? '' : '/' . filter . '/'
  let rhyme_term = s:RhymeTerm()
  let rhyme_term = empty(rhyme_term) ? '' : '{' . rhyme_term . '}'
  let details = ''
  if a:purpose =~? 'Synonyms'
    let details = ':' . filter . rhyme_term
  endif
  silent! exe "noautocmd botright pedit vimdictive:[" . a:purpose[0] . details . ":'" . a:term . "']"
  noautocmd wincmd P
  setlocal stl=%f\ [%p%%\ line\ %l\ of\ %L]
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
  if empty(rhymes)
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
  nnoremap <buffer><silent><enter>
        \ :call PreviewTerm('Meanings', expand('<cword>'))<cr>
  nnoremap <buffer><silent><bs>
        \ :call PreviewTerm('Synonyms', expand('<cword>'))<cr>
  nnoremap <buffer><silent><f5> :call <SID>PreviewRefresh()<cr>
endfunction

" Public Interface: {{{1

function! PreviewTerm(purpose, term)
  call s:PreviewWindow(a:purpose, a:term)
  let b:purpose = a:purpose
  let b:term = a:term

  if a:purpose == 'Meanings'
    let data = vimdictive#meanings(a:term)
  else
    let data = vimdictive#synonyms(a:term)
  endif
  if empty(data)
    let data = vimdictive#matches(a:term)
  endif
  if a:purpose == 'Synonyms'
    let data = s:FilterSynonyms(data)
  endif
  if empty(data)
    call setline(1, ['No ' . a:purpose . ' for term: ' . a:term])
  else
    call setline(1, data)
  endif

  call s:PreviewWindowMaps()
endfunction

function! PreviewFilter(filter)
  if !empty(a:filter)
    let filter = a:filter
  else
    let filter = input('Filter: ', s:FilterText())
  endif
  let g:vimdictive_filter = filter
  call s:PreviewRefresh()
endfunction

function! PreviewRhyme(rhyme)
  if !empty(a:rhyme)
    let rhyme = a:rhyme
  else
    let rhyme = input('Rhyme: ', s:RhymeTerm())
  endif
  let g:vimdictive_rhyme_term = rhyme
  call s:PreviewRefresh()
endfunction

" Maps: {{{1
nnoremap <silent> <Plug>vimdictive_meanings
      \ :silent call PreviewTerm('Meanings', expand('<cword>'))<CR>

nnoremap <silent> <Plug>vimdictive_synonyms
      \ :silent call PreviewTerm('Synonyms', expand('<cword>'))<CR>

nnoremap <silent> <Plug>vimdictive_filter :call PreviewFilter('')<CR>

nnoremap <silent> <Plug>vimdictive_filter_rhyme :call PreviewRhyme('')<CR>

if !hasmapto('<Plug>vimdictive_meanings')
  silent! nmap <unique><silent> <leader>dm <Plug>vimdictive_meanings
endif

if !hasmapto('<Plug>vimdictive_synonyms')
  silent! nmap <unique><silent> <leader>ds <Plug>vimdictive_synonyms
endif

if !hasmapto('<Plug>vimdictive_filter')
  silent! nmap <unique><silent> <leader>df <Plug>vimdictive_filter
endif

if !hasmapto('<Plug>vimdictive_filter_rhyme')
  silent! nmap <unique><silent> <leader>dr <Plug>vimdictive_filter_rhyme
endif

" Commands: {{{1

" Teardown:{{{1
"reset &cpo back to users setting
let &cpo = s:save_cpo

" vim: set sw=2 sts=2 et fdm=marker:
