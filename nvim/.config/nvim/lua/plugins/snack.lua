return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    -- Remove un-wanted plugin
    notifier = { enabled = false },
    statuscolumn = { enabled = false },
    words = { enabled = false },

    -- Keep the desired one
    bigfile = { enabled = true },
    quickfile = { enabled = true },

    vim.api.nvim_set_hl(0, "DashboardDesc", { fg = "#89b4fa" }),
    vim.api.nvim_set_hl(0, "DashboardIcon", { fg = "#89b4fa" }),
    dashboard = {
      width = 40,
      row = nil,
      col = nil,
      pane_gap = 4,
      preset = {
        -- Defaults to a picker that supports `fzf-lua`, `telescope.nvim` and `mini.pick`
        ---@type fun(cmd:string, opts:table)|nil
        pick = nil,
        keys = {
          { icon = { "󰙅", hl = "DashboardIcon" }, key = "e", desc = " Explorer", action = ":wincmd o | Neotree show reveal=true focus position=current" },
          { icon = { "󰈞", hl = "DashboardIcon" }, key = "f", desc = " Find File", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = { "󰊄", hl = "DashboardIcon" }, key = "g", desc = " Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = { "󱋢", hl = "DashboardIcon" }, key = "r", desc = " Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          { icon = { "󰛢", hl = "DashboardIcon" }, key = "h", desc = " Harpoon", action = ":lua require('harpoon.ui').toggle_quick_menu()" },
          { icon = { "󰊢", hl = "DashboardIcon" }, key = "b", desc = " Repo", padding = 1, action = function() Snacks.gitbrowse() end, },
        },
        header = {
          "           Welcome back Latent",
        },
      },
      -- item field formatters
      formats = {
        desc = function(item)
          return { item.desc, hl = "DashboardDesc" }
        end,
      },
      sections = {
        { section = "header", gap = 2, padding = 1 },
        { section = "keys", gap = 1, padding = 1 },
      },
    }
  }
}
