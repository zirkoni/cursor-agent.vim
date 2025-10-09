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

" Global variables
let s:popup_winid = -1
let s:is_running = 0

" Main function to run cursor-agent with current buffer context
function! cursor_agent#Run(query = '')
    if s:is_running
        echo "Cursor Agent is already running..."
        return
    endif

    let s:is_running = 1
    
    " Get current buffer content
    let buffer_content = join(getline(1, '$'), "\n")
    let file_path = expand('%:p')
    let file_name = expand('%:t')
    
    " Check if cursor-agent is available
    if !executable(g:cursor_agent_command)
        echo "Error: cursor-agent not found. Please install it first."
        let s:is_running = 0
        return
    endif
    
    " Prepare context for cursor-agent
    let context = {
        \ 'file_path': file_path,
        \ 'file_name': file_name,
        \ 'content': buffer_content,
        \ 'query': a:query
        \ }
    
    " Show popup with loading message
    call cursor_agent#ShowPopup("Loading...")
    
    " Run cursor-agent asynchronously
    call s:RunCursorAgent(context)
endfunction

" Function to show popup window
function! cursor_agent#ShowPopup(content)
    " Close existing popup if open
    if s:popup_winid != -1
        call popup_close(s:popup_winid)
    endif
    
    " Create popup window
    let s:popup_winid = popup_create(a:content, {
        \ 'pos': 'center',
        \ 'line': 'cursor+1',
        \ 'col': 'cursor',
        \ 'minwidth': g:cursor_agent_popup_width,
        \ 'minheight': g:cursor_agent_popup_height,
        \ 'maxwidth': g:cursor_agent_popup_width,
        \ 'maxheight': g:cursor_agent_popup_height,
        \ 'border': g:cursor_agent_popup_border,
        \ 'borderchars': ['─', '│', '─', '│', '┌', '┐', '┘', '└'],
        \ 'title': 'Cursor Agent',
        \ 'wrap': 1,
        \ 'scrollbar': 1,
        \ 'moved': 'any',
        \ 'filter': function('s:PopupFilter')
        \ })
endfunction

" Popup filter function for key handling
function! s:PopupFilter(winid, key)
    if a:key ==# 'q' || a:key ==# "\<Esc>"
        call popup_close(a:winid)
        return 1
    endif
    return 0
endfunction

" Function to run cursor-agent
function! s:RunCursorAgent(context)
    " Create temporary file with context
    let temp_file = tempname() . '_cursor_context.txt'
    let context_text = "File: " . a:context.file_path . "\n"
    let context_text .= "Query: " . a:context.query . "\n"
    let context_text .= "Content:\n" . a:context.content
    
    call writefile(split(context_text, "\n"), temp_file)
    
    " Prepare command
    let cmd = g:cursor_agent_command . ' "' . a:context.query . '" < ' . temp_file
    
    " Run command asynchronously
    if has('job')
        let job = job_start(cmd, {
            \ 'out_cb': function('s:OnOutput'),
            \ 'err_cb': function('s:OnError'),
            \ 'close_cb': function('s:OnClose'),
            \ 'out_mode': 'raw'
            \ })
    else
        " Fallback for older VIM versions
        let output = system(cmd)
        call s:OnOutput('', output)
        call s:OnClose('')
    endif
    
    " Clean up temp file
    call delete(temp_file)
endfunction

" Callback for command output
function! s:OnOutput(channel, data)
    if s:popup_winid != -1
        let current_content = popup_gettext(s:popup_winid)
        let new_content = current_content . a:data
        call popup_settext(s:popup_winid, new_content)
    endif
endfunction

" Callback for command errors
function! s:OnError(channel, data)
    if s:popup_winid != -1
        let current_content = popup_gettext(s:popup_winid)
        let new_content = current_content . "\nError: " . a:data
        call popup_settext(s:popup_winid, new_content)
    endif
endfunction

" Callback for command completion
function! s:OnClose(channel)
    let s:is_running = 0
    if s:popup_winid != -1
        let current_content = popup_gettext(s:popup_winid)
        let new_content = current_content . "\n\n[Press 'q' or Esc to close]"
        call popup_settext(s:popup_winid, new_content)
    endif
endfunction

" Function to ask a specific question
function! cursor_agent#Ask(question)
    call cursor_agent#Run(a:question)
endfunction

" Function to run cursor-agent with selected text
function! cursor_agent#RunWithSelection(query = '')
    if s:is_running
        echo "Cursor Agent is already running..."
        return
    endif

    " Get selected text
    let [line_start, col_start] = getpos("'<")[1:2]
    let [line_end, col_end] = getpos("'>")[1:2]
    let selected_text = join(getline(line_start, line_end), "\n")
    
    " Remove selection
    normal! gv
    
    if empty(selected_text)
        echo "No text selected"
        return
    endif
    
    let s:is_running = 1
    
    " Check if cursor-agent is available
    if !executable(g:cursor_agent_command)
        echo "Error: cursor-agent not found. Please install it first."
        let s:is_running = 0
        return
    endif
    
    " Prepare context for cursor-agent
    let context = {
        \ 'file_path': expand('%:p'),
        \ 'file_name': expand('%:t'),
        \ 'content': selected_text,
        \ 'query': a:query,
        \ 'selection': 1
        \ }
    
    " Show popup with loading message
    call cursor_agent#ShowPopup("Analyzing selected text...")
    
    " Run cursor-agent asynchronously
    call s:RunCursorAgent(context)
endfunction

" Function to close popup
function! cursor_agent#Close()
    if s:popup_winid != -1
        call popup_close(s:popup_winid)
        let s:popup_winid = -1
    endif
endfunction