local function lsp_status()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    return ''
  end

  local names = {}
  for _, client in ipairs(clients) do
    table.insert(names, client.name)
  end
  local client_str = table.concat(names, ', ')

  local ok, fidget = pcall(require, 'fidget')
  if ok then
    local progress = fidget.get_status and fidget.get_status() or nil
    if progress and progress ~= '' then
      return client_str .. ' ' .. progress
    end
  end

  return client_str
end

return {
  { "nvim-tree/nvim-web-devicons" },
  {
    -- Set lualine as statusline
    'nvim-lualine/lualine.nvim',
    -- See `:help lualine.txt`
    opts = {
      options = {
        icons_enabled = false,
        theme = 'gruvbox_dark',
        component_separators = '|',
        section_separators = '',
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'diff',
          {
            'diagnostics',
            sources = { "nvim_diagnostic" },
            symbols = { error = ' ', warn = ' ', info = ' ', hint = ' ' }
          } },
        lualine_c = { 'filename' },
        lualine_x = {
          {
            lsp_status,
            color = { fg = '#a89984' },
          },
          'encoding', 'fileformat', 'filetype'
        },
        lualine_y = { 'progress' },
        lualine_z = { 'location' }
      },
    },
  }
}
