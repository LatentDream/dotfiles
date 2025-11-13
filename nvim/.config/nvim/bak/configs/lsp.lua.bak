-- [[ Configure LSP ]]

-- Some utilities
vim.keymap.set("n", "<leader>ls", ':LspStart<cr>', { desc = 'Lsp start' })
vim.keymap.set("n", "<leader>lp", ':LspStop<cr>', { desc = 'Lsp stop' })
vim.keymap.set("n", "<leader>lr", ':LspRestart<cr>', { desc = 'Lsp restart' })

-- Use LspAttach autocommand instead of the on_attach method
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('user-lsp-attach', { clear = true }),
  callback = function(event)
    -- Create a function that lets us more easily define mappings specific
    -- for LSP related items. It sets the mode, buffer and description for us each time.
    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    -- Maintain your existing FZF-lua mappings
    map('<leader>rn', vim.lsp.buf.rename, 'Rename')
    map('<leader>ca', vim.lsp.buf.code_action, 'Code Action')

    map('gd', require('fzf-lua').lsp_definitions, 'Goto Definition')
    map('gr', require('fzf-lua').lsp_references, 'Goto References')
    map('gI', require('fzf-lua').lsp_implementations, 'Goto Implementation')
    map('gt', require('fzf-lua').lsp_typedefs, 'Goto Type Definition')
    map('<leader>ds', require('fzf-lua').lsp_document_symbols, 'Document Symbols')
    map('<leader>ws', require('fzf-lua').lsp_workspace_symbols, 'Workspace Symbols')
    map('<leader>ca', require('fzf-lua').lsp_code_actions, 'Code Action')

    map('K', vim.lsp.buf.hover, 'Hover Documentation')
    map('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

    map('gD', vim.lsp.buf.declaration, 'Goto Declaration')
    map('<leader>wa', vim.lsp.buf.add_workspace_folder, 'Workspace Add Folder')
    map('<leader>wr', vim.lsp.buf.remove_workspace_folder, 'Workspace Remove Folder')

    map('<leader>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, 'Workspace List Folders')

    -- Create a command `:Format` local to the LSP buffer
    vim.api.nvim_buf_create_user_command(event.buf, 'Format', function(_)
      vim.lsp.buf.format()
    end, { desc = 'Format current buffer with LSP' })

    -- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
    ---@param client vim.lsp.Client
    ---@param method vim.lsp.protocol.Method
    ---@param bufnr? integer some lsp support methods only in specific files
    ---@return boolean
    local function client_supports_method(client, method, bufnr)
      if vim.fn.has 'nvim-0.11' == 1 then
        return client:supports_method(method, bufnr)
      else
        return client.supports_method(method, { bufnr = bufnr })
      end
    end

    -- Set up document highlighting on cursor hold
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
      local highlight_augroup = vim.api.nvim_create_augroup('user-lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('user-lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'user-lsp-highlight', buffer = event2.buf }
        end,
      })
    end

    -- Add toggle for inlay hints if supported
    if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
      map('<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
      end, 'Toggle Inlay Hints')
    end
  end,
})

vim.api.nvim_set_keymap('n', '<leader>ff', ':Format<CR>', { noremap = true, silent = true, desc = "Format" })

-- document existing key chains
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

-- mason-lspconfig requires that these setup functions are called in this order
-- before setting up the servers.
require('mason').setup()
require('mason-lspconfig').setup()

-- Enable the following language servers
--  Add any additional override configuration in the following tables. They will be passed to
--  the `settings` field of the server config.
--  If you want to override the default filetypes that your language server will attach to you can
--  define the property 'filetypes' to the map in question.
local servers = {
  -- TODO:
  clangd = {},
  -- gopls = {},
  -- pyright = {},
  rust_analyzer = {},
  -- tsserver = {},
  -- html = { filetypes = { 'html', 'twig', 'hbs'} },

  lua_ls = {
    Lua = {
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
      diagnostics = { disable = { 'missing-fields' } },
    },
  },
}

-- Setup neovim lua configuration
require('neodev').setup()

-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- Ensure the servers above are installed
local mason_lspconfig = require 'mason-lspconfig'

mason_lspconfig.setup {
  ensure_installed = vim.tbl_keys(servers),
}

-- Set up each server
for server_name, server_config in pairs(servers) do
  require('lspconfig')[server_name].setup {
    capabilities = capabilities,
    -- on_attach is no longer needed since we're using LspAttach
    settings = server_config,
    filetypes = (server_config or {}).filetypes,
  }
end

local lsp = require('lspconfig')
local configs = require('lspconfig.configs')
local home = os.getenv('HOME')
if not configs.just_lsp then
  configs.just_lsp = {
    default_config = {
      cmd = { home .. '/.cargo/bin/just-lsp' },
      filetypes = { 'just' },
      root_dir = function(fname)
        return lsp.util.find_git_ancestor(fname)
      end,
      settings = {},
    },
  }
end
lsp.just_lsp.setup({
  -- on_attach is no longer needed since we're using LspAttach
  capabilities = capabilities,
})
