vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- [[ Install `lazy.nvim` plugin manager ]]
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins")


-- Load all config files from the configs directory
local configs_path = vim.fn.stdpath('config') .. '/lua/configs/'
local function load_config_files(directory)
    for _, filename in ipairs(vim.fn.glob(directory .. '*.lua', false, true)) do
        local ok, err = pcall(require, 'configs.' .. vim.fn.fnamemodify(filename, ':t:r'))
        if not ok then
            print('Error loading config file ' .. filename)
            print(err)
        end
    end
end
load_config_files(configs_path)
