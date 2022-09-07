local lua_parser = require("run.yaml")
local Job = require("plenary.job")

-- Object for the module
local M = {}

local function get_command_table(command)
  -- Seprate executables (1) and the arguments (2...)
  -- putting them into a table
  local command_table = {}
  for command_component in string.gmatch(command, "%S+") do
    table.insert(command_table, command_component)
  end

  return command_table
end

local function run()
  local settings_file = assert(io.open("/Users/marco/.nvim-run.yaml", "r"))
  local settings = lua_parser.eval(settings_file:read("a"))
  settings_file:close()

  local file_type = vim.bo.filetype
  if settings[file_type] then

    vim.notify("Running...")

    local jobs = {}

    for _, el in pairs(settings[file_type]) do
      local command_table = get_command_table(el)
      table.insert(jobs, Job:new({
        command = table.remove(command_table, 1),
        args = command_table,
      }))
    end

    if #jobs == 0 then
      vim.notify("No commands for this filetype", "error")
      return
    end

    -- There is at least one job/command
    local first_job = jobs[1]
    local last_job = first_job
    for k,next_job in pairs(jobs) do
      -- Every job get the failure handler -> show "Error"
      next_job:after_failure(function (j, code, _)
        vim.notify("Command: "..j.command.." "..table.concat(j.args, " ").."\nFailed with exit code: "..code, "error")
      end)

      -- Chain of jobs. The next one is lunched only if 
      -- the current exited with code=0 (and_then_on_success)
      if k ~= 1 then
        last_job:and_then_on_success(next_job)
        last_job = next_job
      end
    end

    -- Last job get the success handler -> show "Completed"
    last_job:after_success(function (_, _, _)
      vim.notify("Completed")
    end)

    first_job:start()

  else
    print("Filetype ("..file_type..") not recognized!")
  end
end

M.run = run

return M
