" Test file for Cursor Agent VIM Plugin
" Run with: vim -S test/test_cursor_agent.vim

" Test configuration
let g:cursor_agent_command = 'echo'  " Use echo for testing
let g:cursor_agent_popup_width = 60
let g:cursor_agent_popup_height = 15

" Load the plugin
source plugin/cursor_agent.vim
source plugin/cursor_agent_commands.vim
source plugin/cursor_agent_enhanced.vim

" Test functions
function! TestBasicFunctionality()
    echo "Testing basic functionality..."
    
    " Test 1: Check if functions exist
    if !exists('*cursor_agent#Run')
        echo "ERROR: cursor_agent#Run function not found"
        return 0
    endif
    
    if !exists('*cursor_agent#Ask')
        echo "ERROR: cursor_agent#Ask function not found"
        return 0
    endif
    
    if !exists('*cursor_agent#Close')
        echo "ERROR: cursor_agent#Close function not found"
        return 0
    endif
    
    echo "✓ All functions exist"
    return 1
endfunction

function! TestCommands()
    echo "Testing commands..."
    
    " Test if commands are defined
    if !exists(':CursorAgent')
        echo "ERROR: :CursorAgent command not found"
        return 0
    endif
    
    if !exists(':CursorAgentAsk')
        echo "ERROR: :CursorAgentAsk command not found"
        return 0
    endif
    
    if !exists(':CursorAgentClose')
        echo "ERROR: :CursorAgentClose command not found"
        return 0
    endif
    
    echo "✓ All commands exist"
    return 1
endfunction

function! TestSettings()
    echo "Testing settings..."
    
    " Test default settings
    if g:cursor_agent_command != 'echo'
        echo "ERROR: cursor_agent_command not set correctly"
        return 0
    endif
    
    if g:cursor_agent_popup_width != 60
        echo "ERROR: popup_width not set correctly"
        return 0
    endif
    
    echo "✓ Settings work correctly"
    return 1
endfunction

" Run tests
echo "Starting Cursor Agent VIM Plugin Tests"
echo "======================================"

let test_results = []
call add(test_results, TestBasicFunctionality())
call add(test_results, TestCommands())
call add(test_results, TestSettings())

" Summary
let passed = 0
for result in test_results
    if result
        let passed += 1
    endif
endfor

echo ""
echo "Test Results: " . passed . "/" . len(test_results) . " tests passed"

if passed == len(test_results)
    echo "✓ All tests passed!"
else
    echo "✗ Some tests failed"
endif

" Clean up
quit