# Cursor Agent VIM Plugin

A VIM plugin that integrates Cursor AI agent into the editor through popup windows.

## Requirements

- VIM 9.0 or higher
- `cursor-agent` installed in the system
- Popup window support (enabled by default in VIM 9)

## Installation

### Installation via VimPlug (recommended)

Add to your `.vimrc`:

```vim
" VimPlug
call plug#begin()
Plug 'dev-4-fun/cursor-agent.vim'
call plug#end()

" Plugin settings (optional)
let g:cursor_agent_command = 'cursor-agent'
let g:cursor_agent_popup_width = 80
let g:cursor_agent_popup_height = 20
let g:cursor_agent_popup_border = 1
```

Then run:
```vim
:PlugInstall
```

### Installation via Vundle

Add to your `.vimrc`:

```vim
" Vundle
Plugin 'dev-4-fun/cursor-agent.vim'
```

Then run:
```vim
:PluginInstall
```

### Manual Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/dev-4-fun/cursor-agent.vim.git
   cd cursor-agent.vim
   ```

2. Install the plugin:
   ```bash
   make install
   ```

3. Restart VIM

### Additional Commands

```bash
make test        # Run tests
make status      # Show plugin status
make uninstall   # Remove plugin
make clean       # Clean temporary files
```

## Usage

### Commands

- `:CursorAgent [query]` - Run cursor-agent with current buffer as context
- `:CursorAgentAsk <question>` - Ask a specific question to cursor-agent
- `:CursorAgentSelection` - Run with selected text
- `:CursorAgentClose` - Close popup window
- `:CursorAgentHelp` - Show help
- `:CursorAgentStatus` - Check cursor-agent status
- `:CursorAgentInfo` - Show plugin information

### Keyboard Shortcuts

- `<leader>ca` - Run cursor-agent (normal mode)
- `<leader>cq` - Ask question (normal mode)
- `<leader>cc` - Close popup window
- `<leader>ca` - Run cursor-agent with selected text (visual mode)
- `<leader>cq` - Ask question with selected text (visual mode)
- `Ctrl-A Ctrl-A` - Run cursor-agent (insert mode)
- `Ctrl-A Ctrl-Q` - Ask question (insert mode)

### Popup Navigation

- `q` or `Esc` - Close popup window
- `j`/`k` - Scroll down/up
- `g`/`G` - Go to top/bottom

## Configuration

Add to your `.vimrc` to configure the plugin:

```vim
" Path to cursor-agent (if not in PATH)
let g:cursor_agent_command = '/path/to/cursor-agent'

" Popup window size
let g:cursor_agent_popup_width = 80
let g:cursor_agent_popup_height = 20

" Show popup window borders
let g:cursor_agent_popup_border = 1

" Show file path in popup title
let g:cursor_agent_show_file_path = 1

" Auto-close popup after N seconds (0 = disable)
let g:cursor_agent_auto_close = 0
```

## Usage Examples

1. **Code Analysis:**
   ```
   :CursorAgent "Explain this code"
   ```

2. **Error Detection:**
   ```
   :CursorAgent "Find potential errors in this code"
   ```

3. **Refactoring:**
   ```
   :CursorAgent "Suggest improvements for this function"
   ```

4. **Documentation:**
   ```
   :CursorAgent "Create documentation for this function"
   ```

## Features

- Automatically passes current buffer content as context
- Supports asynchronous command execution
- Beautiful popup window with scrollable content
- Flexible configuration through variables
- Support for all VIM modes

## Troubleshooting

### cursor-agent not found
Make sure `cursor-agent` is installed and available in PATH:
```bash
which cursor-agent
```

### Popup windows not working
Check VIM version:
```vim
:version
```
Make sure version is 9.0 or higher.

### Plugin not loading
Check that files are in the correct directory:
```vim
:echo &runtimepath
```

## License

MIT License