-- Q CLI Neovim Plugin
-- A lean and mean integration with Amazon Q CLI through tmux popups

local M = {}

-- Default configuration
local DEFAULT_CONFIG = {
  keymap = '<leader>tq',
  trust_all_tools = true,
  startup_timeout = 3000,
}

-- Plugin state
local state = {
  config = {},
  initialized = false,
}

-- Utility functions
local utils = {}

--- Check if plugin is initialized
--- @return boolean success, string? error_message
local function check_initialized()
  if not state.initialized then
    vim.notify('Plugin not initialized. Call setup() first.', vim.log.levels.ERROR)
    return false, 'Plugin not initialized'
  end
  return true, nil
end

--- Check if a command exists in PATH
--- @param cmd string The command to check
--- @return boolean True if command exists
function utils.command_exists(cmd)
  local handle = io.popen('which ' .. cmd .. ' 2>/dev/null')
  if not handle then return false end
  
  local result = handle:read('*a')
  handle:close()
  
  return result ~= ''
end

--- Execute a system command with error handling
--- @param cmd string The command to execute
--- @return boolean success, string? error_message
function utils.execute_command(cmd)
  local result = vim.fn.system(cmd)
  local success = vim.v.shell_error == 0
  
  if not success then
    return false, result
  end
  
  return true, nil
end

--- Validate configuration options
--- @param config table User configuration
--- @return boolean valid, string? error_message
function utils.validate_config(config)
  local validations = {
    {
      field = 'keymap',
      check = function(val) return val == nil or type(val) == 'string' end,
      message = 'keymap must be a string'
    },
    {
      field = 'trust_all_tools',
      check = function(val) return val == nil or type(val) == 'boolean' end,
      message = 'trust_all_tools must be a boolean'
    },
    {
      field = 'startup_timeout',
      check = function(val) return val == nil or (type(val) == 'number' and val > 0) end,
      message = 'startup_timeout must be a positive number'
    },
  }
  
  for _, validation in ipairs(validations) do
    local value = config[validation.field]
    if not validation.check(value) then
      return false, validation.message
    end
  end
  
  return true, nil
end

-- Session management
local session = {}

--- Generate unique session name for current project
--- @return string Session name
function session.get_name()
  local cwd = vim.fn.getcwd()
  local project_name = vim.fn.fnamemodify(cwd, ':t')
  local hash = vim.fn.sha256(cwd):sub(1, 8)
  return 'q-cli-' .. project_name .. '-' .. hash
end

--- Check if tmux session exists
--- @param name string Session name
--- @return boolean True if session exists
function session.exists(name)
  local success, _ = utils.execute_command('tmux has-session -t ' .. name .. ' 2>/dev/null')
  return success
end

--- Create new Q CLI session
--- @param name string Session name
--- @param cwd string Working directory
--- @return boolean success, string? error_message
function session.create(name, cwd)
  -- Create tmux session
  local success, error_msg = utils.execute_command(
    string.format('tmux new-session -d -s %s -c "%s"', name, cwd)
  )
  
  if not success then
    return false, 'Failed to create tmux session: ' .. (error_msg or 'unknown error')
  end
  
  -- Set up environment
  utils.execute_command(string.format('tmux send-keys -t %s "export PAGER=cat" Enter', name))
  
  -- Build Q CLI command
  local q_cmd = 'q chat'
  if state.config.trust_all_tools then
    q_cmd = q_cmd .. ' --trust-all-tools'
  end
  
  -- Start Q CLI
  utils.execute_command(string.format('tmux send-keys -t %s "%s" Enter', name, q_cmd))
  
  -- Wait for startup
  vim.wait(state.config.startup_timeout)
  
  return true, nil
end

--- Kill session by name
--- @param name string Session name
--- @return boolean success
function session.kill(name)
  local success, _ = utils.execute_command('tmux kill-session -t ' .. name .. ' 2>/dev/null')
  return success
end

--- List all Q CLI sessions
--- @return string[] List of session names
function session.list_all()
  local handle = io.popen('tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^q-cli-"')
  if not handle then return {} end
  
  local sessions_output = handle:read('*a')
  handle:close()
  
  if sessions_output == '' then return {} end
  
  local sessions = {}
  for session_name in sessions_output:gmatch('[^\r\n]+') do
    table.insert(sessions, session_name)
  end
  
  return sessions
end

-- Tmux integration
local tmux = {}

--- Get tmux prefix key in human-readable format
--- @return string Formatted prefix key
function tmux.get_prefix()
  local handle = io.popen('tmux show-options -g prefix 2>/dev/null')
  if not handle then return 'Ctrl+B' end
  
  local result = handle:read('*a')
  handle:close()
  
  if not result or result == '' then return 'Ctrl+B' end
  
  local prefix = result:match('prefix%s+(.-)%s*\n?$')
  if not prefix then return 'Ctrl+B' end
  
  -- Convert tmux format to human readable
  local prefix_map = {
    ['C-b'] = 'Ctrl+B',
    ['C-s'] = 'Ctrl+S',
    ['C-a'] = 'Ctrl+A',
  }
  
  return prefix_map[prefix] or prefix:gsub('C%-', 'Ctrl+')
end

--- Check if running inside tmux
--- @return boolean True if in tmux session
function tmux.is_available()
  return vim.env.TMUX ~= nil
end

--- Open tmux popup for session
--- @param session_name string Session name to attach to
--- @return boolean success, string? error_message
function tmux.open_popup(session_name)
  local prefix_key = tmux.get_prefix()
  
  local popup_cmd = string.format([[
    tmux display-popup \
      -w 85%% \
      -h 75%% \
      -x C \
      -y C \
      -T " Amazon Q CLI (%s d to close)" \
      -b "rounded" \
      -E "tmux attach-session -t %s"
  ]], prefix_key, session_name)
  
  local success, error_msg = utils.execute_command(popup_cmd)
  if not success then
    return false, 'Failed to open popup: ' .. (error_msg or 'unknown error')
  end
  
  return true, nil
end

-- Environment validation
local env = {}

--- Validate runtime environment
--- @return boolean valid, string? error_message
function env.validate()
  if not tmux.is_available() then
    return false, 'Not running in tmux session'
  end
  
  if not utils.command_exists('q') then
    return false, 'Amazon Q CLI not found. Please install it first.'
  end
  
  return true, nil
end

-- Main plugin functions
--- Toggle Q CLI popup
function M.toggle()
  local initialized, init_error = check_initialized()
  if not initialized then return end
  
  -- Validate environment
  local env_valid, env_error = env.validate()
  if not env_valid then
    vim.notify(env_error, vim.log.levels.ERROR)
    return
  end
  
  -- Get or create session
  local session_name = session.get_name()
  local cwd = vim.fn.getcwd()
  
  if not session.exists(session_name) then
    vim.notify('Creating Q CLI session...', vim.log.levels.INFO)
    
    local success, error_msg = session.create(session_name, cwd)
    if not success then
      vim.notify(error_msg, vim.log.levels.ERROR)
      return
    end
  else
    vim.notify('Connecting to existing session...', vim.log.levels.INFO)
  end
  
  -- Open popup
  local success, error_msg = tmux.open_popup(session_name)
  if not success then
    vim.notify(error_msg, vim.log.levels.ERROR)
  end
end

--- Debug current session
function M.debug()
  local initialized, init_error = check_initialized()
  if not initialized then return end
  
  local session_name = session.get_name()
  
  print('=== Q CLI Debug Info ===')
  print('Session: ' .. session_name)
  print('Exists: ' .. tostring(session.exists(session_name)))
  print('Tmux available: ' .. tostring(tmux.is_available()))
  print('Q CLI available: ' .. tostring(utils.command_exists('q')))
  print('Config: ' .. vim.inspect(state.config))
end

--- Clean up all Q CLI sessions
function M.cleanup()
  local initialized, init_error = check_initialized()
  if not initialized then return end
  
  local sessions = session.list_all()
  
  if #sessions == 0 then
    vim.notify('No Q CLI sessions found to clean up', vim.log.levels.INFO)
    return
  end
  
  local cleaned_count = 0
  for _, session_name in ipairs(sessions) do
    if session.kill(session_name) then
      cleaned_count = cleaned_count + 1
      print('Killed session: ' .. session_name)
    else
      print('Failed to kill session: ' .. session_name)
    end
  end
  
  vim.notify('Cleaned up ' .. cleaned_count .. ' Q CLI sessions', vim.log.levels.INFO)
end

--- Setup plugin with user configuration
--- @param opts table? User configuration options
function M.setup(opts)
  -- Validate and merge configuration
  local config = vim.tbl_deep_extend('force', DEFAULT_CONFIG, opts or {})
  
  local valid, error_msg = utils.validate_config(config)
  if not valid then
    vim.notify('Invalid configuration: ' .. error_msg, vim.log.levels.ERROR)
    return
  end
  
  -- Store configuration
  state.config = config
  state.initialized = true
  
  -- Set up keymap
  vim.keymap.set('n', config.keymap, M.toggle, { 
    desc = 'Toggle Q CLI popup',
    silent = true,
  })
  
  -- Create user commands
  local commands = {
    { name = 'QToggle', func = M.toggle, desc = 'Toggle Q CLI popup' },
    { name = 'QDebug', func = M.debug, desc = 'Debug Q CLI session' },
    { name = 'QCleanup', func = M.cleanup, desc = 'Clean up Q CLI sessions' },
  }
  
  for _, cmd in ipairs(commands) do
    vim.api.nvim_create_user_command(cmd.name, cmd.func, { desc = cmd.desc })
  end
  
  -- Show setup confirmation
  local prefix_key = tmux.get_prefix()
  local trust_status = config.trust_all_tools and 'with --trust-all-tools' or 'without --trust-all-tools'
  local timeout_sec = config.startup_timeout / 1000
  
  vim.notify(
    string.format(
      'Q CLI plugin loaded %s (startup timeout: %.1fs):\n  %s - Open Q CLI\n  %s d - Close popup',
      trust_status,
      timeout_sec,
      config.keymap,
      prefix_key
    ),
    vim.log.levels.INFO
  )
end

return M
