" Cursor Agent VIM Plugin
" Version: 1.0.0
" Author: dzmitry
" Description: Integration with Cursor AI agent in VIM

if exists('g:loaded_cursor_agent')
    finish
endif
let g:loaded_cursor_agent = 1

" Plugin configuration
let g:cursor_agent_command = get(g:, 'cursor_agent_command', 'cursor-agent')
let g:cursor_agent_popup_width = get(g:, 'cursor_agent_popup_width', 80)
let g:cursor_agent_popup_height = get(g:, 'cursor_agent_popup_height', 20)
let g:cursor_agent_popup_border = get(g:, 'cursor_agent_popup_border', 1)

" Commands
command! -nargs=* CursorAgent call cursor_agent#run(<q-args>)
command! -nargs=1 CursorAgentAsk call cursor_agent#ask(<q-args>)
command! -nargs=* CursorAgentSelection call cursor_agent#run_with_selection(<q-args>)
command! CursorAgentInteractive call cursor_agent#show_interactive_popup('Interactive mode - press q to ask a question, Esc to close')
command! CursorAgentClose call cursor_agent#close()
command! CursorAgentHelp call cursor_agent#help()
command! CursorAgentStatus call cursor_agent#status()
command! CursorAgentInfo call cursor_agent#info()

" Key mappings
if !hasmapto('<Plug>CursorAgentRun')
    nmap <silent> <leader>ca <Plug>CursorAgentRun
endif
if !hasmapto('<Plug>CursorAgentAsk')
    nmap <silent> <leader>cq <Plug>CursorAgentAsk
endif
if !hasmapto('<Plug>CursorAgentInteractive')
    nmap <silent> <leader>ci <Plug>CursorAgentInteractive
endif
if !hasmapto('<Plug>CursorAgentClose')
    nmap <silent> <leader>cc <Plug>CursorAgentClose
endif

" Define the actual mappings
nnoremap <silent> <Plug>CursorAgentRun :CursorAgent<CR>
nnoremap <silent> <Plug>CursorAgentAsk :CursorAgentAsk 
nnoremap <silent> <Plug>CursorAgentInteractive :CursorAgentInteractive<CR>
nnoremap <silent> <Plug>CursorAgentClose :CursorAgentClose<CR>

" Visual mode mappings
vnoremap <silent> <leader>ca :<C-U>CursorAgentSelection<CR>
vnoremap <silent> <leader>cq :<C-U>CursorAgentSelection<CR>

" Insert mode mappings
inoremap <silent> <C-A><C-A> <Esc>:CursorAgent<CR>
inoremap <silent> <C-A><C-Q> <Esc>:CursorAgentAsk 