" Cursor Agent VIM Plugin - Autoload functions
" This file is loaded on demand when functions are called

" Load settings first
if !exists('g:cursor_agent_command')
    let g:cursor_agent_command = 'cursor-agent'
endif

if !exists('g:cursor_agent_popup_width')
    let g:cursor_agent_popup_width = 80
endif

if !exists('g:cursor_agent_popup_height')
    let g:cursor_agent_popup_height = 20
endif

if !exists('g:cursor_agent_popup_border')
    let g:cursor_agent_popup_border = 1
endif

" Global variables
let s:popup_winid = -1
let s:is_running = 0

" Main function to run cursor-agent with current buffer context
function! cursor_agent#run(query = '')
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
    let context = #{file_path: file_path, file_name: file_name, content: buffer_content, query: a:query}
    
    " Show popup with loading message
    call cursor_agent#show_popup("Loading...")
    
    " Run cursor-agent asynchronously
    call s:run_cursor_agent(context)
endfunction

" Function to show popup window
function! cursor_agent#show_popup(content)
    " Close existing popup if open
    if s:popup_winid != -1
        call popup_close(s:popup_winid)
    endif
    
    " Convert content to list if it's a string
    let content_list = type(a:content) == v:t_string ? split(a:content, '\n') : a:content
    
    " Check if popup is supported
    if has('popupwin')
        try
            " Create popup window with simplified options
            let s:popup_winid = popup_create(content_list, #{pos: 'center', line: 'cursor+1', col: 'cursor', minwidth: g:cursor_agent_popup_width, minheight: g:cursor_agent_popup_height, maxwidth: g:cursor_agent_popup_width, maxheight: g:cursor_agent_popup_height, border: g:cursor_agent_popup_border, title: 'Cursor Agent', wrap: 1, moved: 'any', filter: function('s:popup_filter')})
        catch
            " Fallback to echo if popup fails
            echo join(content_list, "\n")
            let s:popup_winid = -1
        endtry
    else
        " Fallback to echo if popup is not supported
        echo join(content_list, "\n")
        let s:popup_winid = -1
    endif
endfunction

" Popup filter function for key handling
function! s:popup_filter(winid, key)
    if a:key ==# 'q' || a:key ==# "\<Esc>"
        call popup_close(a:winid)
        return 1
    endif
    return 0
endfunction

" Function to run cursor-agent
function! s:run_cursor_agent(context)
    " Create temporary file with context
    let temp_file = tempname() . '_cursor_context.txt'
    let context_text = "File: " . a:context.file_path . "\n"
    let context_text .= "Query: " . a:context.query . "\n"
    let context_text .= "Content:\n" . a:context.content
    
    call writefile(split(context_text, "\n"), temp_file)
    
    " Prepare command with @-syntax for file context
    let cmd = g:cursor_agent_command . ' --print "' . a:context.query . ' @' . a:context.file_path . '"'
    
    " Run command synchronously
    echo "Running cursor-agent..."
    let output = system(cmd)
    if v:shell_error == 0
        call cursor_agent#show_popup(output)
    else
        call cursor_agent#show_popup("Error running cursor-agent: " . output)
    endif
    let s:is_running = 0
    
    " Clean up temp file
    call delete(temp_file)
endfunction

" Callback for command output
function! s:on_output(channel, data)
    if s:popup_winid != -1
        try
            let current_content = popup_gettext(s:popup_winid)
            let new_content = current_content . a:data
            call popup_settext(s:popup_winid, new_content)
        catch
            " Fallback to echo if popup operations fail
            echo a:data
        endtry
    else
        " Echo output if no popup
        echo a:data
    endif
endfunction

" Callback for command errors
function! s:on_error(channel, data)
    if s:popup_winid != -1
        try
            let current_content = popup_gettext(s:popup_winid)
            let new_content = current_content . "\nError: " . a:data
            call popup_settext(s:popup_winid, new_content)
        catch
            " Fallback to echo if popup operations fail
            echo "Error: " . a:data
        endtry
    else
        " Echo error if no popup
        echo "Error: " . a:data
    endif
endfunction

" Callback for command completion
function! s:on_close(channel)
    let s:is_running = 0
    if s:popup_winid != -1
        let current_content = popup_gettext(s:popup_winid)
        let new_content = current_content . "\n\n[Press 'q' or Esc to close]"
        call popup_settext(s:popup_winid, new_content)
    endif
endfunction

" Function to ask a specific question
function! cursor_agent#ask(question)
    call cursor_agent#run(a:question)
endfunction

" Function to run cursor-agent with selected text
function! cursor_agent#run_with_selection(query = '')
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
    let context = #{file_path: expand('%:p'), file_name: expand('%:t'), content: selected_text, query: a:query, selection: 1}
    
    " Show popup with loading message
    call cursor_agent#show_popup("Analyzing selected text...")
    
    " Run cursor-agent asynchronously
    call s:run_cursor_agent(context)
endfunction

" Function to close popup
function! cursor_agent#close()
    if s:popup_winid != -1
        call popup_close(s:popup_winid)
        let s:popup_winid = -1
    endif
endfunction

" Function to show help
function! cursor_agent#help()
    let help_text = [
        \ "Cursor Agent VIM Plugin Help",
        \ "=============================",
        \ "",
        \ "Commands:",
        \ "  :CursorAgent [query]     - Run cursor-agent with current buffer",
        \ "  :CursorAgentAsk <query>  - Ask a specific question",
        \ "  :CursorAgentSelection    - Run with selected text",
        \ "  :CursorAgentClose        - Close popup window",
        \ "  :CursorAgentHelp         - Show this help",
        \ "",
        \ "Key Mappings:",
        \ "  <leader>ca               - Run cursor-agent (normal mode)",
        \ "  <leader>cq               - Ask question (normal mode)",
        \ "  <leader>cc               - Close popup",
        \ "  <leader>ca               - Run with selection (visual mode)",
        \ "  <leader>cq               - Ask with selection (visual mode)",
        \ "  Ctrl-A Ctrl-A            - Run cursor-agent (insert mode)",
        \ "  Ctrl-A Ctrl-Q            - Ask question (insert mode)",
        \ "",
        \ "Popup Navigation:",
        \ "  q, Esc                   - Close popup",
        \ "  j, k                     - Scroll up/down",
        \ "  g, G                     - Go to top/bottom",
        \ "",
        \ "Configuration:",
        \ "  g:cursor_agent_command   - Path to cursor-agent",
        \ "  g:cursor_agent_popup_width  - Popup width",
        \ "  g:cursor_agent_popup_height - Popup height",
        \ "  g:cursor_agent_popup_border - Show popup border",
        \ ""
        \ ]
    
    call cursor_agent#show_popup(join(help_text, "\n"))
endfunction

" Function to check cursor-agent status
function! cursor_agent#status()
    if executable(g:cursor_agent_command)
        let version = system(g:cursor_agent_command . ' --version 2>&1')
        if v:shell_error == 0
            echo "Cursor Agent: " . substitute(version, '\n', '', 'g')
        else
            echo "Cursor Agent: Installed but version check failed"
        endif
    else
        echo "Cursor Agent: Not found. Please install it first."
    endif
endfunction

" Function to show plugin info
function! cursor_agent#info()
    let info_text = [
        \ "Cursor Agent VIM Plugin Info",
        \ "=============================",
        \ "",
        \ "Version: 1.0.0",
        \ "Author: dzmitry",
        \ "Status: " . (s:is_running ? "Running" : "Idle"),
        \ "Popup: " . (s:popup_winid != -1 ? "Open" : "Closed"),
        \ "",
        \ "Configuration:",
        \ "  Command: " . g:cursor_agent_command,
        \ "  Popup Size: " . g:cursor_agent_popup_width . "x" . g:cursor_agent_popup_height,
        \ "  Border: " . (g:cursor_agent_popup_border ? "Enabled" : "Disabled"),
        \ ""
        \ ]
    
    call cursor_agent#show_popup(join(info_text, "\n"))
endfunction