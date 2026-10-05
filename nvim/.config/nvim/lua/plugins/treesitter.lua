local ensure_installed = {
    "bash",
    "c",
    "html",
    "javascript",
    "json",
    "lua",
    "luadoc",
    "luap",
    "query",
    "regex",
    "vim",
    "vimdoc",
    "yaml",
    "rust",
    "go",
    "gomod",
    "gowork",
    "gosum",
    "python",
    "c_sharp",
    "scala",
}

return {
    {
        "nvim-treesitter/nvim-treesitter",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter").setup({})

            local installed = require("nvim-treesitter").get_installed()
            local missing = vim.tbl_filter(function(parser)
                return not vim.tbl_contains(installed, parser)
            end, ensure_installed)
            if #missing > 0 then
                require("nvim-treesitter").install(missing)
            end

            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("TreesitterSetup", { clear = true }),
                callback = function(args)
                    if not pcall(vim.treesitter.start, args.buf) then
                        return
                    end
                    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end,
            })
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        config = function()
            require("nvim-treesitter-textobjects").setup({
                select = {
                    lookahead = true,
                    selection_modes = {
                        ["@parameter.outer"] = "v",
                        ["@parameter.inner"] = "v",
                        ["@function.outer"] = "v",
                        ["@conditional.outer"] = "V",
                        ["@loop.outer"] = "V",
                        ["@class.outer"] = "<c-v>",
                    },
                    include_surrounding_whitespace = false,
                },
                move = {
                    set_jumps = true,
                },
            })

            local select = require("nvim-treesitter-textobjects.select")
            local move = require("nvim-treesitter-textobjects.move")
            local swap = require("nvim-treesitter-textobjects.swap")

            local select_keymaps = {
                ["af"] = "@function.outer",
                ["if"] = "@function.inner",
                ["ac"] = "@class.outer",
                ["ic"] = "@class.inner",
                ["ai"] = "@conditional.outer",
                ["ii"] = "@conditional.inner",
                ["al"] = "@loop.outer",
                ["il"] = "@loop.inner",
                ["ap"] = "@parameter.outer",
                ["ip"] = "@parameter.inner",
            }
            for keys, query in pairs(select_keymaps) do
                vim.keymap.set({ "x", "o" }, keys, function()
                    select.select_textobject(query, "textobjects")
                end)
            end

            local move_keymaps = {
                { "n", "[f", move.goto_previous_start, "@function.outer" },
                { "n", "[c", move.goto_previous_start, "@class.outer" },
                { "n", "[p", move.goto_previous_start, "@parameter.inner" },
                { "n", "]f", move.goto_next_start, "@function.outer" },
                { "n", "]c", move.goto_next_start, "@class.outer" },
                { "n", "]p", move.goto_next_start, "@parameter.inner" },
            }
            for _, map in ipairs(move_keymaps) do
                local modes, keys, fn, query = map[1], map[2], map[3], map[4]
                vim.keymap.set({ modes, "x", "o" }, keys, function()
                    fn(query, "textobjects")
                end)
            end

            vim.keymap.set("n", "<leader>a", function()
                swap.swap_next("@parameter.inner")
            end)
            vim.keymap.set("n", "<leader>A", function()
                swap.swap_previous("@parameter.inner")
            end)
        end,
    },
}
