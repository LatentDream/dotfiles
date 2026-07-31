local dashboard_width = 44
local separator = "────────────────────────────────────────────"

local function crop(text, max_width)
  text = tostring(text or "")
  max_width = max_width or dashboard_width

  if vim.fn.strdisplaywidth(text) <= max_width then
    return text
  end

  local ellipsis = "…"
  local width = max_width - vim.fn.strdisplaywidth(ellipsis)
  if width <= 0 then
    return ""
  end
  local out = ""

  for i = 1, vim.fn.strchars(text) do
    local next = vim.fn.strcharpart(text, 0, i)
    if vim.fn.strdisplaywidth(next) > width then
      break
    end
    out = next
  end

  return out .. ellipsis
end

local function systemlist(cmd)
  local result = vim.fn.systemlist(cmd)
  return vim.v.shell_error == 0 and result or nil
end

local function repo_info()
  local cwd = vim.fn.shellescape(vim.fn.getcwd())
  local root = systemlist("git -C " .. cwd .. " rev-parse --show-toplevel")
  local branch = systemlist("git -C " .. cwd .. " branch --show-current")
  local changes = systemlist("git -C " .. cwd .. " status --short")
  local items = {}

  local function add(icon, label, value)
    local icon_text = icon .. " "
    local label_width = 9
    local value_width = dashboard_width - vim.fn.strdisplaywidth(icon_text) - label_width

    table.insert(items, {
      text = {
        { icon_text, hl = "DashboardIcon" },
        { label, width = label_width, hl = "DashboardMuted" },
        { crop(value, value_width), width = value_width, align = "right", hl = "DashboardDesc" },
      },
    })
  end

  add("󰏗", " Repo:", root and vim.fn.fnamemodify(root[1], ":t") or "none")
  add("", " Branch:", branch and branch[1] ~= "" and branch[1] or "none")
  add("", " Changes:", changes and (#changes == 0 and "clean" or #changes .. " changed") or "none")

  if vim.fn.executable("kubectl") == 1 then
    local ctx = systemlist("kubectl config current-context")
    if ctx and ctx[1] ~= "" then
      add("󱃾", " k8s ctx:", ctx[1])
    end
  end

  return items
end

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
    vim.api.nvim_set_hl(0, "DashboardLogo", { fg = "#57a143" }),
    vim.api.nvim_set_hl(0, "DashboardMuted", { fg = "#6c7086" }),
    vim.api.nvim_set_hl(0, "DashboardSpecial", { fg = "#f9e2af" }),
    dashboard = {
      width = dashboard_width,
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
          { icon = { "󰋖", hl = "DashboardIcon" }, key = "?", desc = " Help", action = ":help" },
          { icon = { "󰓙", hl = "DashboardIcon" }, key = "h", desc = " Checkhealth", action = ":checkhealth" },
          { icon = { "󰊢", hl = "DashboardIcon" }, key = "b", desc = " Diff", action = function()
            vim.fn.system("git rev-parse --verify main")
            local branch = vim.v.shell_error == 0 and "main" or "master"
            vim.cmd("DiffviewOpen " .. branch)
          end },
        },
        header = table.concat({
          " │ ╲ ││",
          " ││╲╲││",
          " ││ ╲ │",
          "",
          " NVIM v" .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
        }, "\n"),
      },
      -- item field formatters
      formats = {
        desc = function(item)
          return { item.desc, hl = "DashboardDesc" }
        end,
      },
      sections = {
        { section = "header", align = "center", hl = "DashboardLogo", padding = 1 },
        { text = separator, align = "center", hl = "DashboardMuted" },
        { section = "keys" },
        { text = separator, align = "center", hl = "DashboardMuted" },
        repo_info,
        { text = separator, align = "center", hl = "DashboardMuted" },
      },
    }
  }
}
