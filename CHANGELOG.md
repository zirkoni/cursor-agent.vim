# Changelog

All notable changes to the Cursor Agent VIM Plugin will be documented in this file.

## [1.0.0] - 2024-12-19

### Added
- Initial release of Cursor Agent VIM Plugin
- Integration with Cursor AI agent
- Popup window support for displaying results
- Support for current buffer context
- Support for selected text analysis
- VIM commands: `:CursorAgent`, `:CursorAgentAsk`, `:CursorAgentSelection`
- Keyboard shortcuts for all modes (normal, visual, insert)
- Asynchronous execution of cursor-agent
- Error handling and validation
- Configurable popup settings
- Help and status commands
- Test suite
- Makefile for easy installation and management
- Comprehensive documentation

### Features
- **Popup Integration**: Beautiful popup windows with scrollable content
- **Context Awareness**: Automatically uses current buffer as context
- **Selection Support**: Analyze selected text specifically
- **Multi-mode Support**: Works in normal, visual, and insert modes
- **Async Execution**: Non-blocking cursor-agent execution
- **Error Handling**: Graceful error handling and user feedback
- **Configurable**: Customizable popup size, borders, and behavior
- **Help System**: Built-in help and status commands

### Commands
- `:CursorAgent [query]` - Run cursor-agent with current buffer
- `:CursorAgentAsk <query>` - Ask a specific question
- `:CursorAgentSelection` - Run with selected text
- `:CursorAgentClose` - Close popup window
- `:CursorAgentHelp` - Show help
- `:CursorAgentStatus` - Check cursor-agent status
- `:CursorAgentInfo` - Show plugin information

### Key Mappings
- `<leader>ca` - Run cursor-agent (normal mode)
- `<leader>cq` - Ask question (normal mode)
- `<leader>cc` - Close popup
- `<leader>ca` - Run with selection (visual mode)
- `<leader>cq` - Ask with selection (visual mode)
- `Ctrl-A Ctrl-A` - Run cursor-agent (insert mode)
- `Ctrl-A Ctrl-Q` - Ask question (insert mode)

### Configuration
- `g:cursor_agent_command` - Path to cursor-agent executable
- `g:cursor_agent_popup_width` - Popup window width
- `g:cursor_agent_popup_height` - Popup window height
- `g:cursor_agent_popup_border` - Enable/disable popup border
- `g:cursor_agent_show_file_path` - Show file path in popup title
- `g:cursor_agent_auto_close` - Auto-close popup after inactivity

### Requirements
- VIM 9.0 or higher
- cursor-agent installed and available in PATH
- Popup window support (enabled by default in VIM 9)