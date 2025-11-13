-- Harpoon
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
    -- Navigate to previous file in list
    ui.nav_prev()
end, { desc = 'Harpoon Previous' })

vim.keymap.set("n", "L", function()
    -- Navigate to next file in list
    ui.nav_next()
end, { desc = 'Harpoon Next' })
