local M = {}

local setup_done = false

---@alias ReplType "utop" | "ipython" | "aider"

---@class ReplConfig
---@field cmd string shell command to run
---@field repl_type ReplType? special handling for repl
---@field open_window string? see Config.open_window_default
---@field filetype string? filetype associated with the repl

---@class ConfigDefault
---@field filetype_commands table<string, ReplConfig>
---@field default ReplConfig
---@field open_window_default string
local defaults = {
  filetype_commands = {
    bash = { cmd = "bash", filetype = "bash" },
    haskell = { cmd = "ghci", filetype = "haskell" },
    javascript = { cmd = "node", filetype = "javascript" },
    ocaml = { cmd = "utop", repl_type = "utop", filetype = "ocaml" },
    python = {
      cmd = "ipython --TerminalInteractiveShell.editing_mode=emacs --quiet --no-autoindent -i -c \"%config InteractiveShell.ast_node_interactivity='last_expr_or_assign'\"",
      repl_type = "ipython",
      filetype = "python",
    },
    r = { cmd = "R", filetype = "r" },
    sh = { cmd = "sh", filetype = "sh" },
    vim = { cmd = "nvim --clean -ERM", filetype = "vim" },
    zsh = { cmd = "zsh", filetype = "zsh" },
  },
  default = { cmd = "bash", filetype = "bash" },
  open_window_default = "vertical split new",
}

---@class Config
---@field filetype_commands table<string, ReplConfig>? map filetype to repl command
---@field default ReplConfig? set default ReplConfig
---@field open_window_default string? command to open repl window. See :help opening-window

---Configure nvim-repl's global constants. Can only be called once
---@param opts Config? nvim-repl options
function M.setup(opts)
  if setup_done then
    return
  end
  opts = opts or {}
  local config = vim.tbl_deep_extend("force", defaults, opts)

  ---@type table<string, ReplConfig>
  vim.g.repl_filetype_commands = config.filetype_commands

  ---@type ReplConfig
  vim.g.repl_default = config.default

  ---@type string
  vim.g.repl_open_window_default = config.open_window_default

  setup_done = true
end

return M
