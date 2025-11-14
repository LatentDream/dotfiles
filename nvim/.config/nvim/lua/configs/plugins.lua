-- --- [[ Whichkey ]] --- --
local wk = require("which-key")
wk.add({
  { "<leader>b", group = "Buffer" },
  { "<leader>b_", hidden = true },
  { "<leader>c", group = "Code" },
  { "<leader>c_", hidden = true },
  { "<leader>d", group = "Document" },
  { "<leader>d_", hidden = true },
  { "<leader>f_", hidden = true },
  { "<leader>g", group = "Git" },
  { "<leader>g_", hidden = true },
  { "<leader>i", group = "Insert" },
  { "<leader>i_", hidden = true },
  { "<leader>r", group = "Rename" },
  { "<leader>r_", hidden = true },
  { "<leader>s", group = "Search" },
  { "<leader>s_", hidden = true },
  { "<leader>t", group = "Toggle" },
  { "<leader>t_", hidden = true },
  { "<leader>w", group = "Workspace" },
  { "<leader>w_", hidden = true },
  { "<leader>x", group = "Error" },
  { "<leader>x_", hidden = true },
  { "<leader>", group = "VISUAL <leader>", mode = "v" },
  { "<leader>k", group = "Harpoon Explorer", icon = "󰛢" },
  { "<leader>", group = "Leader", icon = "󰘳" },
  { "<leader>g", group = "Git", icon = "󰊢" },
})


-- --- [[ TODO Comments ]] --- --
vim.keymap.set('n', '<leader>tq', ':TodoQuickFix keywords=TODO,FIX,FIXME <cr>', { desc = '[T]oggle [Q]uick fix TODO' })
vim.keymap.set('n', '<leader>t/', ':TodoTelescope<cr>', { desc = '[T]oggle search TODO' })

-- --- [[ Gitsigns ]] --- --
require('gitsigns').setup()


-- --- [[ Telescope && fzf-lua ]] --- --
-- Enable telescope fzf native, if installed
pcall(require('telescope').load_extension, 'fzf')
local function find_git_root()
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir
  local cwd = vim.fn.getcwd()
  if current_file == '' then
    current_dir = cwd
  else
    current_dir = vim.fn.fnamemodify(current_file, ':h')
  end

  local git_root = vim.fn.systemlist('git -C ' .. vim.fn.escape(current_dir, ' ') .. ' rev-parse --show-toplevel')[1]
  if vim.v.shell_error ~= 0 then
    print 'Not a git repository. Searching on current working directory'
    return cwd
  end
  return git_root
end

-- Custom live_grep function to search in git root
local function live_grep_git_root()
  local git_root = find_git_root()
  if git_root then
    require('telescope.builtin').live_grep {
      search_dirs = { git_root },
    }
  end
end

local function telescope_live_grep_open_files()
  require('fzf-lua').live_grep {
    grep_open_files = true,
    prompt_title = 'Live Grep in Open Files',
  }
end


vim.api.nvim_create_user_command('LiveGrepGitRoot', live_grep_git_root, {})
vim.keymap.set('n', '<leader>sg', ':LiveGrepGitRoot<cr>', { desc = 'Search by Grep on Git Root' })
vim.keymap.set('n', '<leader>?', require('fzf-lua').oldfiles, { desc = '[?] Find recently opened files' })
vim.keymap.set('n', '<leader><leader>', require('fzf-lua').buffers, { desc = '[<leader>] Find existing buffers' })
vim.keymap.set('n', '<C-f>', require('fzf-lua').files, { desc = 'Search Files' })
vim.keymap.set('n', '<C-g>', require('fzf-lua').grep, { desc = 'Search by Grep' })
vim.keymap.set('n', '<leader>/', telescope_live_grep_open_files, { desc = 'Search by Grep' })
vim.keymap.set('n', '<leader>sd', require('fzf-lua').diagnostics_document, { desc = 'Search Diagnostics' })
vim.keymap.set('n', '<leader>ss', require('fzf-lua').builtin, { desc = 'Search Selector' })
vim.keymap.set('n', '<leader>sw', require('fzf-lua').grep_cword, { desc = 'Search current Word' })
vim.keymap.set('n', '<leader>w', require('fzf-lua').grep_cword, { desc = 'Search current Word' })
vim.keymap.set('n', '<leader>sr', require('fzf-lua').resume, { desc = 'Search Resume' })
vim.keymap.set('n', '<leader>sf', require('fzf-lua').files, { desc = 'Search Files' })
vim.keymap.set('n', '<leader>sq', require('fzf-lua').quickfix, { desc = 'Search Quickfix' })
vim.keymap.set('n', '<leader>st', require('fzf-lua').tabs, { desc = 'Search Tabs' })
vim.keymap.set('n', '<leader>sF', require('fzf-lua').git_files, { desc = 'Search by Grep on Git Root' })
vim.keymap.set('n', '<leader>sh', require('fzf-lua').helptags, { desc = 'Search Help' })

-- [[ Navigation ]]
-- Highlight the current reference and all other refs
require('illuminate').configure({
    delay = 100,
    large_file_cutoff = 2000,
    large_file_overrides = {
      providers = { 'lsp', 'treesitter', 'regex' },
    },
})


local function map(key, dir, buffer)
    vim.keymap.set("n", key, function()
        require("illuminate")["goto_" .. dir .. "_reference"](false)
    end, { desc = dir:sub(1, 1):upper() .. dir:sub(2) .. " Reference", buffer = buffer })
end

map("]]", "next")
map("[[", "prev")

-- Needs to be set after loading plugins, since a lot overwrite [[ and ]]
vim.api.nvim_create_autocmd("FileType", {
    callback = function()
      local buffer = vim.api.nvim_get_current_buf()
      map("]]", "next", buffer)
      map("[[", "prev", buffer)
    end,
})

-- In File navigation
require("aerial").setup({
  on_attach = function(bufnr)
    -- Jump forwards/backwards with '<' and '>'
    vim.keymap.set("n", "<", "<cmd>AerialPrev<CR>", { buffer = bufnr })
    vim.keymap.set("n", ">", "<cmd>AerialNext<CR>", { buffer = bufnr })
  end,
})
vim.keymap.set("n", "<leader>n", "<cmd>AerialToggle!<CR>", { desc = 'Open in-file [N]avigation' })



-- --- [[ Harpoon ]] --- --
local mark = require("harpoon.mark")
local ui = require("harpoon.ui")

-- Your existing keybindings
vim.keymap.set("n", "<leader>j", mark.add_file, { desc = 'Harpoon Aadd file'})
vim.keymap.set("n", "<leader>k", ui.toggle_quick_menu, { desc = 'Harpoon Explorer'})
vim.keymap.set("n", "<leader>1", function() ui.nav_file(1) end, { desc = '[H]arpoon 1'})
vim.keymap.set("n", "<leader>2", function() ui.nav_file(2) end, { desc = '[H]arpoon 2'})
vim.keymap.set("n", "<leader>3", function() ui.nav_file(3) end, { desc = '[H]arpoon 3'})
vim.keymap.set("n", "<leader>4", function() ui.nav_file(4) end, { desc = '[H]arpoon 4'})

-- Add navigation with Shift+H and Shift+L
vim.keymap.set("n", "H", function()
    ui.nav_prev()
end, { desc = 'Harpoon Previous' })
vim.keymap.set("n", "L", function()
    ui.nav_next()
end, { desc = 'Harpoon Next' })
