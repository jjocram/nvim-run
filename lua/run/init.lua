local lua_parser = require("run.yaml")
local Job = require("plenary.job")
local Path = require("plenary.path")

-- Object for the module
local M = {}
local plugin_name = "Run"
local is_windows = jit.os == "Windows"
local use_shellslash = is_windows and vim.o.shellslash

local function get_command_table(command)
  -- Seprate executables (1) and the arguments (2...)
  -- putting them into a table
  local command_table = {}
  for command_component in string.gmatch(command, "%S+") do
    table.insert(command_table, command_component)
  end

  return command_table
end

-- Build the list of jobs to execute
local function get_jobs(commands)
  local jobs = {}

  for _, el in ipairs(commands) do
      local command_table = get_command_table(el)
      table.insert(jobs, Job:new({
        command = table.remove(command_table, 1),
        args = command_table,
      }))
    end

    return jobs
end

-- Build the chain of jobs
-- Returns the first job of the chain
local function build_jobs_chain(jobs)
    -- There is at least one job/command
    local first_job = jobs[1]
    local last_job = first_job
    for index,next_job in pairs(jobs) do
      -- Every job get the failure handler -> show "Error"
      next_job:after_failure(function (j, code, _)
        vim.notify("Command: "..j.command.." "..table.concat(j.args, " ").."\nFailed with exit code: "..code, "error", {title = plugin_name})
      end)

      -- Chain of jobs. The next one is lunched only if 
      -- the current exited with code=0 (and_then_on_success)
      if index ~= 1 then
        last_job:and_then_on_success(next_job)
        last_job = next_job
      end
    end

    -- Last job get the success handler -> show "Completed"
    last_job:after_success(function (_, _, _)
      vim.notify("Completed", "info", {title = plugin_name})
    end)

    return first_job
end

local function get_separator() 
  if is_windows and (not use_shellslash) then
    -- is windows with the back_slash
    return '\\'
  end

  -- otherwise is the classic slash
  return '/'
end

-- Locate settings file, open it, and parse it
-- TODO: improve
local function get_settings(file_name)
  local settings_full_path = ""

  settings_full_path = vim.loop.os_homedir()..get_separator()..file_name

  local settings_file = assert(io.open(settings_full_path, "r"))
  local settings = lua_parser.eval(settings_file:read("a"))
  settings_file:close()

  return settings
end

-- Main function of the plugin
local function run()
  -- Load settings file
  -- TODO: move in an init function to run once 
  -- TODO: provide a way to reload settings through a command
  local settings = get_settings(".nvim-run.yaml")
  local jobs = nil

  local file_type = vim.bo.filetype

  -- Retrieve the list of commands to execute
  -- separated as follow: {"executable", "arg_1", ..., "arg_n"}
  if settings[file_type] then
    -- File type is present on settings file
    jobs = get_jobs(settings[file_type])
  else
    jobs = get_jobs(settings)
  end

  -- Jobs must not be 0
  if #jobs == 0 then
    vim.notify("No commands for this filetype", "error", {title = plugin_name})
    return
  end

  -- Build the chain of jobs 
  local first_job = build_jobs_chain(jobs)

  -- Notify the start of the process
  vim.notify("Jobs started", "info", { title = plugin_name })

  -- Execute first command
  first_job:start()

end

M.run = run

return M
