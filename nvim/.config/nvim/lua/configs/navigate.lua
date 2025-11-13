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

-- also set it after loading plugins, since a lot overwrite [[ and ]]
vim.api.nvim_create_autocmd("FileType", {
    callback = function()
      local buffer = vim.api.nvim_get_current_buf()
      map("]]", "next", buffer)
      map("[[", "prev", buffer)
    end,
})

-- In File navigation
require("aerial").setup({
  -- optionally use on_attach to set keymaps when aerial has attached to a buffer
  on_attach = function(bufnr)
    -- Jump forwards/backwards with '<' and '>'
    vim.keymap.set("n", "<", "<cmd>AerialPrev<CR>", { buffer = bufnr })
    vim.keymap.set("n", ">", "<cmd>AerialNext<CR>", { buffer = bufnr })
  end,
})
-- You probably also want to set a keymap to toggle aerial
vim.keymap.set("n", "<leader>n", "<cmd>AerialToggle!<CR>", { desc = 'Open in-file [N]avigation' })
