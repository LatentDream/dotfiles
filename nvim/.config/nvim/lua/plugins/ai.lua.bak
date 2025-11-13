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
                require("supermaven-nvim").setup({
                    disable_inline_completion = true,
                    disable_keymaps = true
                })
            end,
        },
    }
else
    return {}
end
