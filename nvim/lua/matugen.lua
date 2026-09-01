 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#111414',
    base01 = '#1d2020',
    base02 = '#272b2a',
    base03 = '#899392',
    base04 = '#bec8c7',
    base05 = '#e1e3e2',
    base06 = '#e1e3e2',
    base07 = '#e1e3e2',
    base08 = '#ffb4ab',
    base09 = '#d5bcf2',
    base0A = '#b2ccca',
    base0B = '#90d2cf',
    base0C = '#d5bcf2',
    base0D = '#90d2cf',
    base0E = '#b2ccca',
    base0F = '#cde8e6',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#e1e3e2',          bg = '#111414' })
  hi('TelescopeBorder',         { fg = '#899392',             bg = '#111414' })
  hi('TelescopePromptNormal',   { fg = '#e1e3e2',          bg = '#111414' })
  hi('TelescopePromptBorder',   { fg = '#899392',             bg = '#111414' })
  hi('TelescopePromptPrefix',   { fg = '#90d2cf',             bg = '#111414' })
  hi('TelescopePromptCounter',  { fg = '#bec8c7',  bg = '#111414' })
  hi('TelescopePromptTitle',    { fg = '#111414',             bg = '#90d2cf' })
  hi('TelescopePreviewTitle',   { fg = '#111414',             bg = '#b2ccca' })
  hi('TelescopeResultsTitle',   { fg = '#111414',             bg = '#d5bcf2' })
  hi('TelescopeSelection',      { fg = '#e1e3e2',          bg = '#272b2a' })
  hi('TelescopeSelectionCaret', { fg = '#90d2cf',             bg = '#272b2a' })
  hi('TelescopeMatching',       { fg = '#90d2cf',             bold = true })
end

-- Register a signal handler for SIGUSR1 (matugen updates).
-- The handler re-requires this module, which re-runs the code below, so the
-- previous handle is stopped first; otherwise handlers double on every signal.
if _G.__matugen_signal then
  _G.__matugen_signal:stop()
  _G.__matugen_signal:close()
end

local signal = vim.uv.new_signal()
_G.__matugen_signal = signal
signal:start(
  'sigusr1',
  vim.schedule_wrap(function()
    package.loaded['matugen'] = nil
    require('matugen').setup()
  end)
)

return M
