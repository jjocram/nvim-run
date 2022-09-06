local lua_parser = require("yaml")

-- Object for the module
local M = {}

function run()
  local settings_file = assert(io.open("~/.nvim-run.yaml", "r"))
  local settings = lua_parser.eval(settings_file:read("a"))
  settings_file:close()

  local file_type = vim.bo.filetype
  print(file_type)
  print(settings)
end

M.run = run

return M
