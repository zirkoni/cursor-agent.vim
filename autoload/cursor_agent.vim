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
    
    " Check if popup is supported and all required functions exist
    if has('popupwin') && exists('*popup_create') && exists('*popup_close') && exists('*popup_settext')
        try
        " Create popup window with working options
        let s:popup_winid = popup_create(content_list, #{pos: 'center', title: 'Cursor Agent', wrap: 1, moved: 'any', border: [], filter: function('s:popup_filter')})
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

" Function to show interactive popup with follow-up capability
function! cursor_agent#show_interactive_popup(content)
    " Close existing popup if open
    if s:popup_winid != -1
        call popup_close(s:popup_winid)
    endif
    
    " Convert content to list if it's a string
    let content_list = type(a:content) == v:t_string ? split(a:content, '\n') : a:content
    
    " Add interactive instructions
    call add(content_list, '')
    call add(content_list, '---')
    call add(content_list, 'Press "q" to ask another question, "Esc" to close')
    
    " Check if popup is supported and all required functions exist
    if has('popupwin') && exists('*popup_create') && exists('*popup_close') && exists('*popup_settext')
        try
        " Create popup window with interactive options
        let s:popup_winid = popup_create(content_list, #{pos: 'center', title: 'Cursor Agent - Interactive', wrap: 1, moved: 'any', border: [], filter: function('s:interactive_popup_filter')})
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
        let s:popup_winid = -1
        return 1
    endif
    return 0
endfunction

" Interactive popup filter function
function! s:interactive_popup_filter(winid, key)
    if a:key ==# "\<Esc>"
        " Close popup
        call popup_close(a:winid)
        let s:popup_winid = -1
        return 1
    elseif a:key ==# 'q'
        " Ask another question
        call popup_close(a:winid)
        let s:popup_winid = -1
        
        " Get new query from user
        let query = input('Enter your follow-up question: ')
        if query != ''
            call cursor_agent#run(query)
        endif
        return 1
    endif
    return 0
endfunction

" Terminal popup filter function
function! s:terminal_popup_filter(winid, key)
    if a:key ==# "\<Esc>"
        " Close terminal popup
        call popup_close(a:winid)
        let s:popup_winid = -1
        return 1
    elseif a:key ==# 'q'
        " Close terminal and ask for next question
        call popup_close(a:winid)
        let s:popup_winid = -1
        
        " Get new query from user
        let query = input('Enter your follow-up question: ')
        if query != ''
            call cursor_agent#run(query)
        endif
        return 1
    endif
    return 0
endfunction

" Function to run cursor-agent
function! s:run_cursor_agent(context)
    " Close existing popup if open
    if s:popup_winid != -1
        call popup_close(s:popup_winid)
    endif
    
    " Prepare command with @-syntax for file context
    let cmd = g:cursor_agent_command . ' --print "' . a:context.query . ' @' . a:context.file_path . '"'
    
    " Show loading popup with progress
    call s:show_loading_popup()
    
    " Run command asynchronously with progress updates
    let s:is_running = 1
    let s:output_lines = []
    let s:job = job_start(cmd, #{out_cb: function('s:on_output_progress'), err_cb: function('s:on_error_progress'), close_cb: function('s:on_close_progress')})
endfunction

" Show loading popup with progress
function! s:show_loading_popup()
    let loading_content = ['🤖 Cursor Agent is thinking...', '', '⏳ Processing your request...', '📝 Analyzing file context...', '🧠 Generating response...', '', 'Press Esc to cancel']
    
    if has('popupwin') && exists('*popup_create')
        try
            let s:popup_winid = popup_create(loading_content, #{pos: 'center', title: 'Cursor Agent - Processing', wrap: 1, moved: 'any', border: [], filter: function('s:loading_popup_filter')})
        catch
            echo join(loading_content, "\n")
            let s:popup_winid = -1
        endtry
    else
        echo join(loading_content, "\n")
        let s:popup_winid = -1
    endif
endfunction

" Loading popup filter
function! s:loading_popup_filter(winid, key)
    if a:key ==# "\<Esc>"
        " Cancel the job if running
        if s:is_running && exists('s:job')
            call job_stop(s:job)
        endif
        call popup_close(a:winid)
        let s:popup_winid = -1
        let s:is_running = 0
        return 1
    endif
    return 0
endfunction

" Progress output callback
function! s:on_output_progress(channel, data)
    call add(s:output_lines, a:data)
    
    " Update popup with current output
    if s:popup_winid != -1
        try
            let current_content = popup_gettext(s:popup_winid)
            let new_content = current_content . "\n" . a:data
            call popup_settext(s:popup_winid, new_content)
        catch
            " Fallback to echo
            echo a:data
        endtry
    else
        echo a:data
    endif
endfunction

" Progress error callback
function! s:on_error_progress(channel, data)
    call add(s:output_lines, "Error: " . a:data)
    
    if s:popup_winid != -1
        try
            let current_content = popup_gettext(s:popup_winid)
            let new_content = current_content . "\nError: " . a:data
            call popup_settext(s:popup_winid, new_content)
        catch
            echo "Error: " . a:data
        endtry
    else
        echo "Error: " . a:data
    endif
endfunction

" Progress close callback
function! s:on_close_progress(channel)
    let s:is_running = 0
    
    " Show final result in interactive popup
    if s:popup_winid != -1
        call popup_close(s:popup_winid)
    endif
    
    let final_output = join(s:output_lines, "\n")
    if final_output != ''
        call cursor_agent#show_interactive_popup(final_output)
    else
        call cursor_agent#show_interactive_popup("No output received from cursor-agent")
    endif
    
    let s:popup_winid = -1
endfunction

" Fallback function for systems without popup_terminal
function! s:run_cursor_agent_fallback(context)
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
        call cursor_agent#show_interactive_popup(output)
    else
        call cursor_agent#show_interactive_popup("Error running cursor-agent: " . output)
    endif
    
    " Clean up temp file
    call delete(temp_file)
endfunction

" Function to run cursor-agent in interactive mode
function! s:run_cursor_agent_interactive(context)
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
        call cursor_agent#show_interactive_popup(output)
    else
        call cursor_agent#show_interactive_popup("Error running cursor-agent: " . output)
    endif
    let s:is_running = 0
    
    " Clean up temp file
    call delete(temp_file)
endfunction

" Callback for command output
function! s:on_output(channel, data)
    if s:popup_winid != -1
        try
            " Check if popup_gettext exists before using it
            if exists('*popup_gettext')
                let current_content = popup_gettext(s:popup_winid)
                let new_content = current_content . a:data
                call popup_settext(s:popup_winid, new_content)
            else
                " Just append to popup without getting current content
                call popup_settext(s:popup_winid, a:data)
            endif
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
            " Check if popup_gettext exists before using it
            if exists('*popup_gettext')
                let current_content = popup_gettext(s:popup_winid)
                let new_content = current_content . "\nError: " . a:data
                call popup_settext(s:popup_winid, new_content)
            else
                " Just show error in popup
                call popup_settext(s:popup_winid, "Error: " . a:data)
            endif
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

" Function to run cursor-agent in interactive mode
function! cursor_agent#run_interactive(query = '')
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
    
    " Show interactive popup with loading message
    call cursor_agent#show_interactive_popup("Loading...")
    
    " Run cursor-agent asynchronously
    call s:run_cursor_agent_interactive(context)
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
    let help_text = ["Cursor Agent VIM Plugin Help", "=============================", "", "Commands:", "  :CursorAgent [query]     - Run cursor-agent with current buffer", "  :CursorAgentInteractive [query] - Run in interactive mode", "  :CursorAgentSelection    - Run with selected text", "  :CursorAgentClose        - Close popup window", "  :CursorAgentHelp         - Show this help", "", "Key Mappings:", "  <leader>ca               - Run cursor-agent (normal mode)", "  <leader>ci               - Run interactive mode (normal mode)", "  <leader>cc               - Close popup", "  <leader>ca               - Run with selection (visual mode)", "  <leader>ci               - Run with selection (visual mode)", "  Ctrl-A Ctrl-A            - Run cursor-agent (insert mode)", "  Ctrl-A Ctrl-I            - Run interactive mode (insert mode)", "", "Popup Navigation:", "  q, Esc                   - Close popup", "  j, k                     - Scroll up/down", "  g, G                     - Go to top/bottom", "", "Interactive Mode:", "  q                        - Ask follow-up question", "  Esc                      - Close popup", "", "Configuration:", "  g:cursor_agent_command   - Path to cursor-agent", "  g:cursor_agent_popup_width  - Popup width", "  g:cursor_agent_popup_height - Popup height", "  g:cursor_agent_popup_border - Show popup border", ""]
    
    call cursor_agent#show_popup(join(help_text, "\n"))
endfunction

" Function to check cursor-agent status
function! cursor_agent#status()
    if executable(g:cursor_agent_command)
        let agent_version = system(g:cursor_agent_command . ' --version 2>&1')
        if v:shell_error == 0
            echo "Cursor Agent: " . substitute(agent_version, '\n', '', 'g')
        else
            echo "Cursor Agent: Installed but version check failed"
        endif
    else
        echo "Cursor Agent: Not found. Please install it first."
    endif
endfunction

" Function to show plugin info
function! cursor_agent#info()
    let info_text = ["Cursor Agent VIM Plugin Info", "=============================", "", "Version: 1.0.0", "Author: dzmitry", "Status: " . (s:is_running ? "Running" : "Idle"), "Popup: " . (s:popup_winid != -1 ? "Open" : "Closed"), "", "Configuration:", "  Command: " . g:cursor_agent_command, "  Popup Size: " . g:cursor_agent_popup_width . "x" . g:cursor_agent_popup_height, "  Border: " . (g:cursor_agent_popup_border ? "Enabled" : "Disabled"), ""]
    
    call cursor_agent#show_popup(join(info_text, "\n"))
endfunction