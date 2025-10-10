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

if !exists('g:cursor_agent_debug')
    let g:cursor_agent_debug = 0
endif

" Global variables
let s:popup_winid = -1
let s:terminal_winid = -1
let s:terminal_bufnr = -1
let s:is_running = 0
let s:stream_output = ''
let s:job = v:null
let s:read_timer = -1
let s:raw_buffer = ''
let s:chat_output_winid = -1
let s:chat_input_winid = -1
let s:chat_input_text = []
let s:chat_cursor_pos = 0

" Main function to run cursor-agent with current buffer context
function! cursor_agent#run(...)
    let query = a:0 > 0 ? a:1 : ''
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
    let context = #{file_path: file_path, file_name: file_name, content: buffer_content, query: query}
    
    " Run cursor-agent asynchronously (popup will be created there)
    call s:run_cursor_agent(context)
endfunction

" Interactive function to run cursor-agent
function! cursor_agent#run_interactive(...)
    let query = a:0 > 0 ? a:1 : ''
    " If no query provided, ask for one
    if query == ''
        let query = input('What would you like to ask about this file? ')
        if query == ''
            return
        endif
    endif
    
    " Call the main run function
    call cursor_agent#run(query)
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

" Function to run cursor-agent with streaming
function! s:run_cursor_agent(context)
    " Close existing popup if open
    if s:popup_winid != -1
        call popup_close(s:popup_winid)
    endif
    
    " Get or create chat session
    let chat_id_file = '/tmp/cursor_agent_chat_id_' . getpid()
    let chat_id = ''
    
    if filereadable(chat_id_file)
        " Use existing chat session
        let chat_id = readfile(chat_id_file)[0]
    else
        " Create new chat session
        let create_cmd = g:cursor_agent_command . ' create-chat'
        let chat_id = system(create_cmd)
        let chat_id = substitute(chat_id, '\n', '', 'g')
        call writefile([chat_id], chat_id_file)
    endif
    
    " Prepare streaming command with session
    " Use script to emulate TTY for cursor-agent (required for streaming)
    let cmd = 'script -q /dev/null ' . g:cursor_agent_command . ' --resume ' . chat_id . ' -p --output-format stream-json --stream-partial-output "' . a:context.query . '"'
    
    " Initialize streaming output
    let s:stream_output = ''
    
    " Create popup immediately for streaming
    let s:popup_winid = popup_create(['🤖 Thinking...'], #{
        \ pos: 'center',
        \ title: 'Cursor Agent - Streaming',
        \ wrap: 1,
        \ moved: 'any',
        \ border: [],
        \ filter: function('s:interactive_popup_filter')
        \ })
    
    " Force redraw to show popup immediately
    redraw
    
    " Debug logging (only if g:cursor_agent_debug is enabled)
    if g:cursor_agent_debug
        call writefile(['STARTING JOB: ' . cmd], 'vim_stream_debug.log', 'a')
    endif
    
    " Run command asynchronously with streaming
    " Use callbacks with raw mode
    let s:job = job_start(['/bin/sh', '-c', cmd], #{
        \ out_cb: function('s:on_stream_output'),
        \ err_cb: function('s:on_stream_error'),
        \ exit_cb: function('s:on_stream_close'),
        \ out_mode: 'raw',
        \ err_mode: 'raw'
        \ })
    
    " Debug: check if job started
    if job_status(s:job) == 'fail'
        if g:cursor_agent_debug
            call writefile(['JOB FAILED TO START'], 'vim_stream_debug.log', 'a')
        endif
        call popup_close(s:popup_winid)
        echom 'Job failed to start!'
        let s:is_running = 0
    else
        if g:cursor_agent_debug
            call writefile(['JOB STARTED WITH CALLBACKS: ' . job_status(s:job)], 'vim_stream_debug.log', 'a')
        endif
        echom 'Job started: ' . job_status(s:job)
    endif
endfunction

" Read stream output via timer (not used, kept for reference)
function! s:read_stream_output(timer)
    " This function is not currently used - callbacks work better
    " Kept for reference in case timer-based approach is needed
    call timer_stop(a:timer)
endfunction

" Callback for streaming output (now used with raw mode)
function! s:on_stream_output(channel, msg)
    " Debug logging
    if g:cursor_agent_debug
        call writefile(['CALLBACK CALLED: len=' . len(a:msg)], 'vim_stream_debug.log', 'a')
    endif
    
    " Accumulate raw data
    if !exists('s:raw_buffer')
        let s:raw_buffer = ''
    endif
    let s:raw_buffer .= a:msg
    
    " Split by newlines and process complete lines
    let lines = split(s:raw_buffer, "\n", 1)
    
    " If last element is not empty, it's incomplete - save it for next callback
    if len(lines) > 0 && lines[-1] != ''
        let s:raw_buffer = lines[-1]
        let lines = lines[:-2]
    else
        let s:raw_buffer = ''
    endif
    
    " Process each complete line
    for line in lines
        if line == ''
            continue
        endif
        
        " Remove ANSI escape sequences and control characters from script command
        let line = substitute(line, '\e\[[0-9;]*[a-zA-Z]', '', 'g')
        let line = substitute(line, '[\x00-\x1F]', '', 'g')
        
        if line == ''
            continue
        endif
        
        if g:cursor_agent_debug
            call writefile(['PROCESSING LINE: ' . line[:50] . '...'], 'vim_stream_debug.log', 'a')
        endif
        
        try
            let json = json_decode(line)
            
            " Handle assistant messages (streaming chunks)
            if has_key(json, 'type') && json.type == 'assistant' && has_key(json, 'message')
                let content = json.message.content
                if type(content) == v:t_list && len(content) > 0
                    let text_obj = content[0]
                    if has_key(text_obj, 'text')
                        let s:stream_output .= text_obj.text
                        
                        " Update popup with current output
                        if s:popup_winid != -1
                            call popup_settext(s:popup_winid, split(s:stream_output, "\n"))
                            redraw
                        endif
                    endif
                endif
            endif
            
            " Handle final result
            if has_key(json, 'type') && json.type == 'result' && has_key(json, 'result')
                let s:stream_output = json.result
                
                " Update popup with final output
                if s:popup_winid != -1
                    let final_lines = split(s:stream_output, "\n")
                    call add(final_lines, '')
                    call add(final_lines, '---')
                    call add(final_lines, 'Press "q" to ask another question, "Esc" to close')
                    call popup_settext(s:popup_winid, final_lines)
                    call popup_setoptions(s:popup_winid, #{title: 'Cursor Agent - Complete'})
                    redraw
                endif
            endif
        catch
            if g:cursor_agent_debug
                call writefile(['JSON ERROR: ' . v:exception], 'vim_stream_debug.log', 'a')
            endif
        endtry
    endfor
endfunction

" Callback for streaming errors
function! s:on_stream_error(channel, msg)
    if s:popup_winid != -1
        call popup_close(s:popup_winid)
        call cursor_agent#show_interactive_popup("Error: " . a:msg)
    endif
endfunction

" Callback for stream close
function! s:on_stream_close(job, status)
    if g:cursor_agent_debug
        call writefile(['EXIT CALLBACK: status=' . a:status], 'vim_stream_debug.log', 'a')
    endif
    let s:is_running = 0
    " Popup already updated with final result, nothing more to do
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


" Function to run cursor-agent with selected text
function! cursor_agent#run_with_selection(...)
    let query = a:0 > 0 ? a:1 : ''
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
    let context = #{file_path: expand('%:p'), file_name: expand('%:t'), content: selected_text, query: query, selection: 1}
    
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
    if s:terminal_winid != -1
        call popup_close(s:terminal_winid)
        let s:terminal_winid = -1
        let s:terminal_bufnr = -1
    endif
    " Also close chat windows
    call cursor_agent#close_chat()
endfunction

" Function to show help
function! cursor_agent#help()
    let help_text = ["Cursor Agent VIM Plugin Help", "=============================", "", "Commands:", "  :CursorAgent [query]     - Run cursor-agent with streaming", "  :CursorAgentChat         - Open interactive chat (2-panel UI)", "  :CursorAgentSelection    - Run with selected text", "  :CursorAgentTerm         - Open terminal in popup window", "  :CursorAgentNewChat      - Start new chat session", "  :CursorAgentClose        - Close all popup windows", "  :CursorAgentHelp         - Show this help", "", "Key Mappings:", "  <leader>ca               - Run cursor-agent (normal mode)", "  <leader>ci               - Run interactive mode (normal mode)", "  <leader>cc               - Close popup", "  <leader>ca               - Run with selection (visual mode)", "  <leader>ci               - Run with selection (visual mode)", "  Ctrl-A Ctrl-A            - Run cursor-agent (insert mode)", "  Ctrl-A Ctrl-I            - Run interactive mode (insert mode)", "", "Chat Mode:", "  Enter                    - Send message", "  Esc                      - Close chat", "  Arrow keys               - Move cursor in input", "  Home/End, Ctrl-A/E       - Jump to start/end", "", "Popup Navigation:", "  q, Esc                   - Close popup", "  j, k                     - Scroll up/down", "  g, G                     - Go to top/bottom", "", "Configuration:", "  g:cursor_agent_command   - Path to cursor-agent", "  g:cursor_agent_debug     - Enable debug logging (0/1)", ""]
    
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

" Interactive chat with two-section popup
function! cursor_agent#chat()
    " Check if chat is already open
    if s:chat_output_winid != -1
        echom 'Chat is already open'
        return
    endif
    
    " Calculate sizes and positions
    let width = float2nr(&columns * 0.8)
    let height = float2nr(&lines * 0.8)
    let xoffset = float2nr((&columns - width) / 2)
    let yoffset = float2nr((&lines - height) / 2)
    
    " Output section (top, bigger)
    let output_height = height - 5
    
    " Input section (bottom, 3 lines)
    let input_height = 3
    let input_yoffset = yoffset + output_height + 2
    
    " Create output popup
    let s:chat_output_winid = popup_create([], #{
        \ line: yoffset,
        \ col: xoffset,
        \ minwidth: width,
        \ maxwidth: width,
        \ minheight: output_height,
        \ maxheight: output_height,
        \ border: [],
        \ title: ' Cursor Agent Chat ',
        \ wrap: 1,
        \ scrollbar: 1,
        \ mapping: 0
        \ })
    
    " Create input popup with filter
    let s:chat_input_winid = popup_create(['> '], #{
        \ line: input_yoffset,
        \ col: xoffset,
        \ minwidth: width,
        \ maxwidth: width,
        \ minheight: input_height,
        \ maxheight: input_height,
        \ border: [],
        \ title: ' Input (Enter to send, Esc to close) ',
        \ wrap: 0,
        \ filter: function('s:chat_input_filter'),
        \ mapping: 0
        \ })
    
    " Initialize input state
    let s:chat_input_text = []
    let s:chat_cursor_pos = 0
    
    " Set cursor highlight
    call matchaddpos('Cursor', [[1, 3]], 10, -1, #{window: s:chat_input_winid})
    
    redraw
endfunction

" Filter for chat input popup
function! s:chat_input_filter(winid, key)
    let ascii_val = char2nr(a:key)
    
    " Printable characters
    if (len(a:key) == 1 && ascii_val >= 32 && ascii_val <= 126)
        if s:chat_cursor_pos == len(s:chat_input_text)
            call add(s:chat_input_text, a:key)
        else
            let pre = s:chat_cursor_pos > 0 ? s:chat_input_text[: s:chat_cursor_pos - 1] : []
            let s:chat_input_text = pre + [a:key] + s:chat_input_text[s:chat_cursor_pos :]
        endif
        let s:chat_cursor_pos += 1
        call s:update_chat_input()
        return 1
    endif
    
    " Backspace
    if a:key ==# "\<BS>" || a:key ==# "\<C-h>"
        if s:chat_cursor_pos > 0
            if s:chat_cursor_pos == len(s:chat_input_text)
                let s:chat_input_text = s:chat_input_text[:-2]
            else
                let before = s:chat_cursor_pos > 1 ? s:chat_input_text[: s:chat_cursor_pos - 2] : []
                let s:chat_input_text = before + s:chat_input_text[s:chat_cursor_pos :]
            endif
            let s:chat_cursor_pos -= 1
            call s:update_chat_input()
        endif
        return 1
    endif
    
    " Cursor movement
    if a:key ==# "\<Left>"
        let s:chat_cursor_pos = max([0, s:chat_cursor_pos - 1])
        call s:update_chat_input()
        return 1
    endif
    
    if a:key ==# "\<Right>"
        let s:chat_cursor_pos = min([len(s:chat_input_text), s:chat_cursor_pos + 1])
        call s:update_chat_input()
        return 1
    endif
    
    " Home/End
    if a:key ==# "\<Home>" || a:key ==# "\<C-a>"
        let s:chat_cursor_pos = 0
        call s:update_chat_input()
        return 1
    endif
    
    if a:key ==# "\<End>" || a:key ==# "\<C-e>"
        let s:chat_cursor_pos = len(s:chat_input_text)
        call s:update_chat_input()
        return 1
    endif
    
    " Enter - send message
    if a:key ==# "\<CR>"
        let query = join(s:chat_input_text, '')
        if query != ''
            call s:send_chat_message(query)
            let s:chat_input_text = []
            let s:chat_cursor_pos = 0
            call s:update_chat_input()
        endif
        return 1
    endif
    
    " Escape - close chat
    if a:key ==# "\<Esc>" || a:key ==# "\<C-c>"
        call cursor_agent#close_chat()
        return 1
    endif
    
    return 0
endfunction

" Update chat input display with cursor
function! s:update_chat_input()
    let text = '> ' . join(s:chat_input_text, '')
    call popup_settext(s:chat_input_winid, text)
    
    " Clear and re-add cursor highlight
    call clearmatches(s:chat_input_winid)
    let cursor_col = 3 + s:chat_cursor_pos
    call matchaddpos('Cursor', [[1, cursor_col]], 10, -1, #{window: s:chat_input_winid})
    redraw
endfunction

" Send chat message
function! s:send_chat_message(query)
    " Add user message to output
    let user_msg = ['', 'You: ' . a:query, '']
    let current_text = getbufline(winbufnr(s:chat_output_winid), 1, '$')
    call popup_settext(s:chat_output_winid, current_text + user_msg + ['AI: ...'])
    
    " Prepare context for cursor-agent
    let context = #{
        \ file_path: expand('%:p'),
        \ file_name: expand('%:t'),
        \ content: '',
        \ query: a:query
        \ }
    
    " Run cursor-agent with streaming (reuse existing function)
    call s:run_cursor_agent_for_chat(context)
endfunction

" Modified run_cursor_agent for chat mode
function! s:run_cursor_agent_for_chat(context)
    if s:is_running
        return
    endif
    
    let s:is_running = 1
    
    " Get or create chat session
    let chat_id_file = '/tmp/cursor_agent_chat_id_' . getpid()
    let chat_id = ''
    
    if filereadable(chat_id_file)
        let chat_id = readfile(chat_id_file)[0]
    else
        let create_cmd = g:cursor_agent_command . ' create-chat'
        let chat_id = system(create_cmd)
        let chat_id = substitute(chat_id, '\n', '', 'g')
        call writefile([chat_id], chat_id_file)
    endif
    
    " Prepare streaming command
    let cmd = 'script -q /dev/null ' . g:cursor_agent_command . ' --resume ' . chat_id . ' -p --output-format stream-json --stream-partial-output "' . a:context.query . '"'
    
    " Initialize streaming output for chat
    let s:stream_output = ''
    
    if g:cursor_agent_debug
        call writefile(['CHAT: STARTING JOB: ' . cmd], 'vim_stream_debug.log', 'a')
    endif
    
    " Run command asynchronously
    let s:job = job_start(['/bin/sh', '-c', cmd], #{
        \ out_cb: function('s:on_chat_stream_output'),
        \ err_cb: function('s:on_stream_error'),
        \ exit_cb: function('s:on_chat_stream_close'),
        \ out_mode: 'raw',
        \ err_mode: 'raw'
        \ })
    
    if job_status(s:job) == 'fail'
        if g:cursor_agent_debug
            call writefile(['CHAT: JOB FAILED TO START'], 'vim_stream_debug.log', 'a')
        endif
        let s:is_running = 0
    endif
endfunction

" Callback for chat streaming output
function! s:on_chat_stream_output(channel, msg)
    if g:cursor_agent_debug
        call writefile(['CHAT: CALLBACK len=' . len(a:msg)], 'vim_stream_debug.log', 'a')
    endif
    
    " Accumulate raw data
    let s:raw_buffer .= a:msg
    
    " Split by newlines
    let lines = split(s:raw_buffer, "\n", 1)
    
    if len(lines) > 0 && lines[-1] != ''
        let s:raw_buffer = lines[-1]
        let lines = lines[:-2]
    else
        let s:raw_buffer = ''
    endif
    
    " Process each complete line
    for line in lines
        if line == ''
            continue
        endif
        
        " Remove ANSI escape sequences
        let line = substitute(line, '\e\[[0-9;]*[a-zA-Z]', '', 'g')
        let line = substitute(line, '[\x00-\x1F]', '', 'g')
        
        if line == ''
            continue
        endif
        
        try
            let json = json_decode(line)
            
            " Handle assistant messages (streaming chunks)
            if has_key(json, 'type') && json.type == 'assistant' && has_key(json, 'message')
                let content = json.message.content
                if type(content) == v:t_list && len(content) > 0
                    let text_obj = content[0]
                    if has_key(text_obj, 'text')
                        let s:stream_output .= text_obj.text
                        
                        " Update chat output window
                        if s:chat_output_winid != -1
                            let current_text = getbufline(winbufnr(s:chat_output_winid), 1, '$')
                            " Replace last line (AI: ...) with actual content
                            if len(current_text) > 0
                                let current_text = current_text[:-2]
                            endif
                            call popup_settext(s:chat_output_winid, current_text + ['AI: ' . s:stream_output])
                            " Scroll to bottom
                            call win_execute(s:chat_output_winid, 'normal! G')
                            redraw
                        endif
                    endif
                endif
            endif
            
            " Handle final result
            if has_key(json, 'type') && json.type == 'result' && has_key(json, 'result')
                let s:stream_output = json.result
                
                " Final update
                if s:chat_output_winid != -1
                    let current_text = getbufline(winbufnr(s:chat_output_winid), 1, '$')
                    if len(current_text) > 0
                        let current_text = current_text[:-2]
                    endif
                    call popup_settext(s:chat_output_winid, current_text + ['AI: ' . s:stream_output, ''])
                    call win_execute(s:chat_output_winid, 'normal! G')
                    redraw
                endif
            endif
        catch
            if g:cursor_agent_debug
                call writefile(['CHAT: JSON ERROR: ' . v:exception], 'vim_stream_debug.log', 'a')
            endif
        endtry
    endfor
endfunction

" Callback for chat stream close
function! s:on_chat_stream_close(job, status)
    if g:cursor_agent_debug
        call writefile(['CHAT: EXIT status=' . a:status], 'vim_stream_debug.log', 'a')
    endif
    let s:is_running = 0
    let s:stream_output = ''
endfunction

" Close chat windows
function! cursor_agent#close_chat()
    if s:chat_output_winid != -1
        call popup_close(s:chat_output_winid)
        let s:chat_output_winid = -1
    endif
    if s:chat_input_winid != -1
        call popup_close(s:chat_input_winid)
        let s:chat_input_winid = -1
    endif
    let s:chat_input_text = []
    let s:chat_cursor_pos = 0
endfunction

" Function to open terminal in popup
function! cursor_agent#terminal()
    " Close existing terminal popup if open
    if s:terminal_winid != -1
        call popup_close(s:terminal_winid)
        let s:terminal_winid = -1
    endif
    
    " Check if terminal and popup features are available
    if !has('terminal') || !has('popupwin')
        echo "Error: Terminal or popup feature not available"
        return
    endif
    
    " Check if cursor-agent is available
    if !executable(g:cursor_agent_command)
        echo "Error: cursor-agent not found. Please install it first."
        return
    endif
    
    " Set Terminal highlight before creating terminal
    hi link Terminal Search
    
    " Path to temporary file for chat ID (fixed location)
    let chat_id_file = '/tmp/cursor_agent_chat_id_' . getpid()
    
    " Check if chat session already exists
    let cmd = g:cursor_agent_command
    if filereadable(chat_id_file)
        " Restore existing chat session
        let chat_id = readfile(chat_id_file)[0]
        let cmd = g:cursor_agent_command . ' --resume ' . chat_id
    else
        " Create new chat and save ID
        let create_cmd = g:cursor_agent_command . ' create-chat'
        let chat_id = system(create_cmd)
        let chat_id = substitute(chat_id, '\n', '', 'g')
        call writefile([chat_id], chat_id_file)
        let cmd = g:cursor_agent_command . ' --resume ' . chat_id
    endif
    
    " Start cursor-agent with chat session
    let opts = #{
        \ hidden: 1,
        \ term_finish: 'close',
        \ curwin: 0
        \ }
    
    let s:terminal_bufnr = term_start(cmd, opts)
    
    " Create popup window with terminal buffer
    let popup_opts = #{
        \ minwidth: 80,
        \ minheight: 20,
        \ maxwidth: 120,
        \ maxheight: 30,
        \ border: [],
        \ title: ' Terminal (Cursor Agent) ',
        \ close: 'button',
        \ drag: 1,
        \ resize: 1,
        \ filter: function('s:terminal_filter')
        \ }
    
    let s:terminal_winid = popup_create(s:terminal_bufnr, popup_opts)
    
    if s:terminal_winid == -1
        echo "Error: Failed to create terminal popup"
        " Clean up the terminal buffer
        if bufexists(s:terminal_bufnr)
            execute 'bdelete! ' . s:terminal_bufnr
        endif
        let s:terminal_bufnr = -1
    endif
endfunction

" Filter function for terminal popup
function! s:terminal_filter(winid, key)
    " Don't handle any keys here - let them pass to the terminal
    " The terminal will handle all input
    return 0
endfunction

" Function to create new chat session
function! cursor_agent#new_chat()
    " Close existing terminal if open
    if s:terminal_winid != -1
        call popup_close(s:terminal_winid)
        let s:terminal_winid = -1
        let s:terminal_bufnr = -1
    endif
    
    " Delete chat ID file to force new session
    let chat_id_file = '/tmp/cursor_agent_chat_id_' . getpid()
    if filereadable(chat_id_file)
        call delete(chat_id_file)
    endif
    
    " Open new terminal with new chat
    call cursor_agent#terminal()
endfunction
