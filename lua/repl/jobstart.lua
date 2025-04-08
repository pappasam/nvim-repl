---Functions related to neovim's jobstart() function
---Implemented in lua for performance reasons
local M = {}

---@diagnostic disable-next-line: unused-local
function M.on_stdout_aider(job_id, data, event)
  for _, item in ipairs(data) do
    if string.find(item, "Processing your request...", 1, true) then
      vim.notify("repl: AI comment detected, aider processing...")
      return
    end
  end
end

return M
