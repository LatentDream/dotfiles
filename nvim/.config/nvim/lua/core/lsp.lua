vim.lsp.enable({
    "csharp_ls",
    "erlang_ls",
    "gopls",
    "lua_ls",
    -- "omnisharp",
    "typescript",
    "yamlls",
    "zls"
})

vim.diagnostic.config({
    virtual_lines = false,
    virtual_text = false,
    underline = false,
    update_in_insert = false,
    severity_sort = true,
    float = {
        border = "rounded",
        source = true,
    },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "󰅚 ",
            [vim.diagnostic.severity.WARN] = "󰀪 ",
            [vim.diagnostic.severity.INFO] = "󰋽 ",
            [vim.diagnostic.severity.HINT] = "󰌶 ",
        },
        numhl = {
            [vim.diagnostic.severity.ERROR] = "ErrorMsg",
            [vim.diagnostic.severity.WARN] = "WarningMsg",
        },
    },
})

local full_diagnostics_active = false
local function toggle_full_diagnostics()
    full_diagnostics_active = not full_diagnostics_active
    vim.diagnostic.config({
        virtual_lines = full_diagnostics_active,
    })
    print("Diagnostics full " .. (full_diagnostics_active and "enabled" or "disabled"))
end

local inline_diagnostics_active = false
local function toggle_inline_diagnostics()
    inline_diagnostics_active = not inline_diagnostics_active
    vim.diagnostic.config({
        virtual_text = inline_diagnostics_active,
    })
    print("Diagnostics inline " .. (inline_diagnostics_active and "enabled" or "disabled"))
end

local underlined_diagnostics_active = true
local function toggle_underlined_diagnostics()
    underlined_diagnostics_active = not underlined_diagnostics_active
    vim.diagnostic.config({
        underline = underlined_diagnostics_active
    })
    print("Diagnostics underline " .. (underlined_diagnostics_active and "enabled" or "disabled"))
end


vim.api.nvim_create_user_command('LspRestart', function()
    local clients = vim.lsp.get_active_clients({ bufnr = 0 })
    local buf_name = vim.api.nvim_buf_get_name(0)

    if #clients == 0 then
        print("No active LSP clients for current buffer")
        return
    end

    print(string.format("Restarting LSP for: %s", vim.fn.fnamemodify(buf_name, ":t")))
    for _, client in ipairs(clients) do
        print(string.format("  • %s (id: %d)", client.name, client.id))
    end

    vim.lsp.stop_client(clients)
    vim.cmd('edit')

    vim.defer_fn(function()
        local new_clients = vim.lsp.get_active_clients({ bufnr = 0 })
        print("✓ Restart complete!")
        if #new_clients > 0 then
            for _, client in ipairs(new_clients) do
                print(string.format("  • %s", client.name))
            end
        end
    end, 500)
end, {})

vim.keymap.set('n', '<leader>tf', toggle_full_diagnostics, { desc = '[T]oggle [F]ull diagnostics' })
vim.keymap.set('n', '<leader>td', toggle_inline_diagnostics, { desc = '[T]oggle inline [D]iagnostics' })
vim.keymap.set('n', '<C-s>', toggle_full_diagnostics, { desc = 'Toggle diagnostics' })
vim.keymap.set('n', '<leader>tu', toggle_underlined_diagnostics, { desc = '[T]oggle diagnostics [U]nderlinged' })
