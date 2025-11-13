-- [[ Custom keymap ]]

-- Move between windows
vim.api.nvim_set_keymap('n', '<C-h>', ':TmuxNavigateLeft<CR>',
  { noremap = true, silent = true, desc = 'Move to the left window' })
vim.api.nvim_set_keymap('n', '<C-j>', ':TmuxNavigateDown<CR>',
  { noremap = true, silent = true, desc = 'Move to the down window' })
vim.api.nvim_set_keymap('n', '<C-k>', ':TmuxNavigateUp<CR>',
  { noremap = true, silent = true, desc = 'Move to the up window' })
vim.api.nvim_set_keymap('n', '<C-l>', ':TmuxNavigateRight<CR>',
  { noremap = true, silent = true, desc = 'Move to the right window' })
vim.api.nvim_set_keymap('n', '<C-\\>', ':TmuxNavigatePrevious<CR>',
  { noremap = true, silent = true, desc = 'Move to the previous window' })

-- Resize window using <Ctrl> arrow keys
vim.api.nvim_set_keymap('n', '<C-Up>', ':resize +2<CR>',
    { noremap = true, silent = true, desc = 'Increase window height' })
vim.api.nvim_set_keymap('n', '<C-Down>', ':resize -2<CR>',
    { noremap = true, silent = true, desc = 'Decrease window height' })
vim.api.nvim_set_keymap('n', '<C-Left>', ':vertical resize -2<CR>',
    { noremap = true, silent = true, desc = 'Decrease window width' })
vim.api.nvim_set_keymap('n', '<C-Right>', ':vertical resize +2<CR>',
    { noremap = true, silent = true, desc = 'Increase window width' })
vim.api.nvim_set_keymap('n', '<leader>th', ':set invhlsearch hlsearch?<CR>',
    { noremap = true, silent = true, desc = 'Toggle Highlight Search' })

-- Quick List
vim.api.nvim_set_keymap('n', '<leader>q', ':copen<CR>',
    { noremap = true, silent = true, desc = 'Open [Q]uickfix' })

-- C utility
vim.api.nvim_set_keymap('n', 'gh', ':ClangdSwitchSourceHeader<CR>',
    { noremap = true, silent = true, desc = '[G]o to [H]eader or source' })

-- Normal esc in terminal mode
vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]])

-- Open terminal and enter insert mode
vim.keymap.set('n', '<leader>tt', ':bel term<CR>i', {
    noremap = true,
    silent = true,
    desc = '[T]oggle build-in [T]erminal'
})

--- --- --- --- --- ---
--- Insert Snippet
function insertArrow()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("i →", true, true, true), 'n', true)
end
vim.api.nvim_set_keymap('n', '<leader>ia', ':lua insertArrow()<CR>',
    { noremap = true, silent = true, desc = '[I]nsert [A]rrow char' })

-- go error handling
vim.keymap.set('n', '<leader>ie', function()
    local pos = vim.api.nvim_win_get_cursor(0)
    local line = pos[1] - 1
    vim.api.nvim_buf_set_lines(0, line, line, false, {
        "if err != nil {",
        "\t",
        "}"
    })
    -- Move cursor to the indented line
    vim.api.nvim_win_set_cursor(0, { line + 2, 1 })
end, 
    { noremap = true, silent = true, desc = '[I]nsert Go [E]error handling' })

