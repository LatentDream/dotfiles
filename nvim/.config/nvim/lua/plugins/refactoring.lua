return {
    "ThePrimeagen/refactoring.nvim",
    -- Required on Neovim 0.12; Neovim 0.13 provides the async API itself.
    dependencies = { "lewis6991/async.nvim" },
    lazy = false,
    keys = {
        {
            "<leader>re",
            function()
                return require("refactoring").extract_func()
            end,
            mode = { "n", "x" },
            expr = true,
            desc = "Extract Function",
        },
        {
            "<leader>rv",
            function()
                return require("refactoring").extract_var()
            end,
            mode = { "n", "x" },
            expr = true,
            desc = "Extract Variable",
        },
        {
            "<leader>rs",
            function()
                require("refactoring").select_refactor()
            end,
            mode = { "n", "x" },
            desc = "Select Refactoring",
        },
    },
}
