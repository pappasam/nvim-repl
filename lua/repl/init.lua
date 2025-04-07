local M = {}

---@alias ReplType "utop" | "ipython" | "aider"

---@class ReplCmd
---@field cmd string shell command to run
---@field repl_type ReplType? special handling for repl
---@field open_window string? see ReplGlobalConfig.open_window_default
---@field filetype string? filetype associated with the repl

---@class ReplGlobalConfig
---@field filetype_commands table<string, ReplCmd>
---@field default ReplCmd
---@field open_window_default string

---@type ReplGlobalConfig
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
  open_window_default = "vnew",
}

---@class SetupOptions
---@field filetype_commands table<string, ReplCmd>? map filetype to repl command
---@field default ReplCmd? set default ReplCmd
---@field open_window_default string? command to open repl window. See :help opening-window

---Configure nvim-repl's global constants
---@param opts SetupOptions?
function M.setup(opts)
  opts = opts or {}

  ---@type ReplGlobalConfig
  vim.g.repl = vim.tbl_deep_extend("force", defaults, vim.g.repl or {}, opts)
end

return M
