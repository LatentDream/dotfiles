require("core.lazy")
require("core.lsp")

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
