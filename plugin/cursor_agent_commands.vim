" Cursor Agent Commands and Key Mappings
" This file is loaded after the main plugin

" Commands
command! -nargs=* CursorAgent call cursor_agent#Run(<q-args>)
command! -nargs=1 CursorAgentAsk call cursor_agent#Ask(<q-args>)
command! -nargs=* CursorAgentSelection call cursor_agent#RunWithSelection(<q-args>)
command! CursorAgentClose call cursor_agent#Close()

" Key mappings
if !hasmapto('<Plug>CursorAgentRun')
    nmap <silent> <leader>ca <Plug>CursorAgentRun
endif
if !hasmapto('<Plug>CursorAgentAsk')
    nmap <silent> <leader>cq <Plug>CursorAgentAsk
endif
if !hasmapto('<Plug>CursorAgentClose')
    nmap <silent> <leader>cc <Plug>CursorAgentClose
endif

" Define the actual mappings
nnoremap <silent> <Plug>CursorAgentRun :CursorAgent<CR>
nnoremap <silent> <Plug>CursorAgentAsk :CursorAgentAsk 
nnoremap <silent> <Plug>CursorAgentClose :CursorAgentClose<CR>

" Visual mode mappings
vnoremap <silent> <leader>ca :<C-U>CursorAgentSelection<CR>
vnoremap <silent> <leader>cq :<C-U>CursorAgentSelection<CR>

" Insert mode mappings
inoremap <silent> <C-A><C-A> <Esc>:CursorAgent<CR>
inoremap <silent> <C-A><C-Q> <Esc>:CursorAgentAsk 