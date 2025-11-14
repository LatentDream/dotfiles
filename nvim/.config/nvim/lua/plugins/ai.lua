local function check_user()
    local handle = io.popen("whoami")
    local result = ""
    if handle then
        result = handle:read("*a"):gsub("%s+$", "") -- Remove trailing whitespace/newline
        handle:close()
    end
    return result
end

-- Only return plugins if not work computer
if check_user() ~= "guillaume.thibault" then
    return {
        {
            "supermaven-inc/supermaven-nvim",
            config = function()
                require("supermaven-nvim").setup({})

                -- Add toggle mapping
                vim.keymap.set('n', '<leader>ta', function()
                    local api = require("supermaven-nvim.api")
                    if api.is_running() then
                        api.stop()
                        print("Supermaven disabled")
                    else
                        api.start()
                        print("Supermaven enabled")
                    end
                end, { desc = 'Toggle AI (Supermaven)' })
            end,
        },
    }
else
    return {}
end
