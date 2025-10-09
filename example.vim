" Example usage of Cursor Agent VIM Plugin
" This file demonstrates how to use the plugin

" Example 1: Basic usage
" Open this file in VIM and try these commands:

" :CursorAgent "Объясни этот код"
" :CursorAgentAsk "Что делает эта функция?"
" :CursorAgent "Найди потенциальные проблемы"

" Example 2: Code analysis
function! ExampleFunction()
    let x = 10
    let y = 20
    let result = x + y
    return result
endfunction

" Try: :CursorAgent "Проанализируй эту функцию"

" Example 3: Code improvement
let my_list = [1, 2, 3, 4, 5]
for item in my_list
    echo item
endfor

" Try: :CursorAgent "Как можно улучшить этот код?"

" Example 4: Documentation request
function! CalculateSum(a, b)
    return a + b
endfunction

" Try: :CursorAgent "Создай документацию для этой функции"