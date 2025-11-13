-- [[ Setting options ]]

-- Set highlight on search
vim.o.hlsearch = false

-- Make line numbers default
vim.wo.number = true

-- Enable mouse mode
vim.o.mouse = 'a'

-- Sync clipboard between OS and Neovim.
vim.o.clipboard = 'unnamedplus'

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

-- Set terminal color
vim.o.termguicolors = true

-- Relative line number
vim.opt.nu = true
vim.opt.relativenumber = true

-- Tab confit
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

-- Expect Nerd Font
vim.g.have_nerd_font = true

-- Border
vim.opt.winborder = "solid" -- https://neovim.io/doc/user/options.html#'winborder'

-- Split config
vim.opt.splitright = true
vim.opt.splitbelow = true

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- Remap the :make -> justfile
vim.o.makeprg = 'just'
vim.api.nvim_create_user_command('Just', function(opts)
  vim.cmd('make ' .. opts.args)
end, { nargs = '*' })

vim.keymap.set('n', '<leader>mj', ':!just<CR>', { noremap = true, silent = true, desc = '[M]ake [J]ust' })
vim.keymap.set('n', '<leader>ml', ':make lint<CR>', { noremap = true, silent = true, desc = '[M]ake [L]int' })
vim.keymap.set('n', '<leader>mt', ':make test<CR>', { noremap = true, silent = true, desc = '[M]ake [T]est' })
vim.keymap.set('n', '<leader>mm', ':make build<CR>', { noremap = true, silent = true, desc = '[M]ake build' })
vim.keymap.set('n', '<leader>mo', function()
  -- Try to find existing buffer first
  local buf_exists = vim.fn.bufexists('justfile') == 1

  if buf_exists then
    vim.cmd('sbuffer justfile')
  else
    -- Open the file (will create buffer if file exists)
    vim.cmd('e justfile')
  end
end, { noremap = true, silent = true, desc = '[Makefile] Open' })
