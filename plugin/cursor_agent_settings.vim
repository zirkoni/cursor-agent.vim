" Cursor Agent Default Settings
" These can be overridden in your .vimrc

" Default cursor-agent command (can be overridden)
if !exists('g:cursor_agent_command')
    let g:cursor_agent_command = 'cursor-agent'
endif

" Popup window settings
if !exists('g:cursor_agent_popup_width')
    let g:cursor_agent_popup_width = 80
endif

if !exists('g:cursor_agent_popup_height')
    let g:cursor_agent_popup_height = 20
endif

if !exists('g:cursor_agent_popup_border')
    let g:cursor_agent_popup_border = 1
endif

" Leader key for mappings (defaults to backslash)
if !exists('g:cursor_agent_leader')
    let g:cursor_agent_leader = '\'
endif

" Enable/disable plugin
if !exists('g:cursor_agent_enabled')
    let g:cursor_agent_enabled = 1
endif

" Auto-close popup after inactivity (in seconds, 0 to disable)
if !exists('g:cursor_agent_auto_close')
    let g:cursor_agent_auto_close = 0
endif

" Show file path in popup title
if !exists('g:cursor_agent_show_file_path')
    let g:cursor_agent_show_file_path = 1
endif