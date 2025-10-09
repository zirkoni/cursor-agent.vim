" Enhanced features for Cursor Agent VIM Plugin
" This file provides additional functionality

" Function to show help
function! cursor_agent_enhanced#ShowHelp()
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
    
    call cursor_agent#ShowPopup(join(help_text, "\n"))
endfunction

" Function to check cursor-agent status
function! cursor_agent_enhanced#CheckStatus()
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
function! cursor_agent_enhanced#ShowInfo()
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
    
    call cursor_agent#ShowPopup(join(info_text, "\n"))
endfunction

" Add help command
command! CursorAgentHelp call cursor_agent_enhanced#ShowHelp()
command! CursorAgentStatus call cursor_agent_enhanced#CheckStatus()
command! CursorAgentInfo call cursor_agent_enhanced#ShowInfo()