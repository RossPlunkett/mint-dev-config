-- Loaded by init.lua only when bspwmrc exports RICE_NVIM, so other sessions keep the normal colorscheme.
local rice = vim.fn.expand("~/.config/rice")

local function palette_scheme(p)
  vim.cmd("highlight clear")
  vim.g.colors_name = "rice"
  local hl = function(group, spec) vim.api.nvim_set_hl(0, group, spec) end
  local groups = {
    Normal = { fg = p.fg, bg = p.bg },
    NormalFloat = { fg = p.fg, bg = p.bg_light },
    FloatBorder = { fg = p.accent },
    Comment = { fg = p.fg_muted, italic = true },
    Constant = { fg = p.magenta },
    String = { fg = p.green },
    Character = { fg = p.green },
    Number = { fg = p.yellow },
    Boolean = { fg = p.yellow },
    Identifier = { fg = p.fg },
    Function = { fg = p.cyan },
    Statement = { fg = p.accent, bold = true },
    Keyword = { fg = p.accent, bold = true },
    PreProc = { fg = p.magenta },
    Type = { fg = p.blue },
    Special = { fg = p.yellow },
    Delimiter = { fg = p.fg_muted },
    Title = { fg = p.accent, bold = true },
    Visual = { bg = p.selection },
    Search = { fg = p.bg, bg = p.yellow },
    IncSearch = { fg = p.bg, bg = p.accent },
    CurSearch = { fg = p.bg, bg = p.accent },
    MatchParen = { fg = p.accent, bold = true, underline = true },
    LineNr = { fg = p.muted },
    CursorLineNr = { fg = p.accent, bold = true },
    CursorLine = { bg = p.bg_light },
    ColorColumn = { bg = p.bg_light },
    Pmenu = { fg = p.fg, bg = p.bg_light },
    PmenuSel = { fg = p.bg, bg = p.accent },
    StatusLine = { fg = p.fg, bg = p.selection },
    StatusLineNC = { fg = p.fg_muted, bg = p.bg_light },
    WinSeparator = { fg = p.selection },
    NonText = { fg = p.muted },
    Directory = { fg = p.accent },
    ErrorMsg = { fg = p.red, bold = true },
    WarningMsg = { fg = p.yellow },
    DiagnosticError = { fg = p.red },
    DiagnosticWarn = { fg = p.yellow },
    DiagnosticInfo = { fg = p.blue },
    DiagnosticHint = { fg = p.cyan },
    DiffAdd = { fg = p.green },
    DiffChange = { fg = p.yellow },
    DiffDelete = { fg = p.red },
  }
  for group, spec in pairs(groups) do hl(group, spec) end
end

-- Terminal transparency only shows through when these groups have no background.
local function clear_backgrounds()
  for _, group in ipairs({ "Normal", "NormalNC", "SignColumn", "EndOfBuffer", "LineNr", "CursorLineNr", "FoldColumn", "NormalFloat", "FloatBorder" }) do
    local spec = vim.api.nvim_get_hl(0, { name = group, link = false })
    spec.bg = nil
    vim.api.nvim_set_hl(0, group, spec)
  end
end

function RiceApply()
  local theme = dofile(rice .. "/current/nvim-theme.lua")
  if theme.scheme == "palette" then
    palette_scheme(theme.palette)
  else
    vim.cmd.colorscheme(theme.scheme)
  end
  clear_backgrounds()
  return "ok"
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = clear_backgrounds })
RiceApply()

-- rice-theme finds running editors through these sockets and restyles them live.
local dir = (vim.env.XDG_RUNTIME_DIR or "/tmp") .. "/rice-nvim"
vim.fn.mkdir(dir, "p")
pcall(vim.fn.serverstart, dir .. "/" .. vim.fn.getpid() .. ".sock")
