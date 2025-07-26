-- Simple Q CLI plugin - lean and mean
local M = {}

-- Get session name for current project
local function get_session_name()
  local cwd = vim.fn.getcwd()
  local project_name = vim.fn.fnamemodify(cwd, ':t')
  local hash = vim.fn.sha256(cwd):sub(1, 8)
  return 'q-cli-' .. project_name .. '-' .. hash
end

-- Check if session exists
local function session_exists(name)
  local result = vim.fn.system('tmux has-session -t ' .. name .. ' 2>/dev/null')
  return vim.v.shell_error == 0
end

-- Get tmux prefix key dynamically
local function get_tmux_prefix()
  local handle = io.popen('tmux show-options -g prefix 2>/dev/null')
  local result = handle:read('*a')
  handle:close()
  
  if result and result ~= '' then
    local prefix = result:match('prefix%s+(.-)%s*\n?$')
    if prefix then
      if prefix == 'C-b' then return 'Ctrl+B'
      elseif prefix == 'C-s' then return 'Ctrl+S'
      elseif prefix == 'C-a' then return 'Ctrl+A'
      else return prefix:gsub('C%-', 'Ctrl+') end
    end
  end
  return 'Ctrl+B'
end

-- Main toggle function
function M.toggle()
  if not vim.env.TMUX then
    vim.notify('Not running in tmux session', vim.log.levels.ERROR)
    return
  end
  
  local session_name = get_session_name()
  local cwd = vim.fn.getcwd()
  local prefix_key = get_tmux_prefix()
  
  -- Create session if it doesn't exist
  if not session_exists(session_name) then
    vim.notify('Creating Q CLI session...', vim.log.levels.INFO)
    
    -- Create session
    vim.fn.system(string.format('tmux new-session -d -s %s -c "%s"', session_name, cwd))
    
    -- Set up environment and start Q CLI
    vim.fn.system(string.format('tmux send-keys -t %s "export PAGER=cat" Enter', session_name))
    vim.fn.system(string.format('tmux send-keys -t %s "q chat --trust-all-tools" Enter', session_name))
    
    -- Wait for Q CLI to start
    vim.wait(3000)
  else
    vim.notify('Connecting to existing session...', vim.log.levels.INFO)
  end
  
  -- Open popup
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
  
  vim.fn.system(popup_cmd)
end

-- Debug function
function M.debug()
  local session_name = get_session_name()
  print("Session: " .. session_name)
  print("Exists: " .. tostring(session_exists(session_name)))
end

-- Cleanup function
function M.cleanup()
  local handle = io.popen('tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^q-cli-"')
  local sessions = handle:read('*a')
  handle:close()
  
  for session in sessions:gmatch('[^\r\n]+') do
    vim.fn.system('tmux kill-session -t ' .. session .. ' 2>/dev/null')
    print("Killed session: " .. session)
  end
end

-- Setup
function M.setup(opts)
  -- Default configuration
  local config = {
    keymap = '<leader>tq',
  }
  
  -- Merge user config
  if opts then
    config = vim.tbl_deep_extend('force', config, opts)
  end
  
  -- Set up keymap
  vim.keymap.set('n', config.keymap, M.toggle, { desc = 'Toggle Q CLI popup' })
  
  -- Create commands
  vim.api.nvim_create_user_command('QToggle', M.toggle, { desc = 'Toggle Q CLI popup' })
  vim.api.nvim_create_user_command('QDebug', M.debug, { desc = 'Debug Q CLI session' })
  vim.api.nvim_create_user_command('QCleanup', M.cleanup, { desc = 'Clean up Q CLI sessions' })
  
  local prefix_key = get_tmux_prefix()
  vim.notify('Q CLI plugin loaded:\n  ' .. config.keymap .. ' - Open Q CLI\n  ' .. prefix_key .. ' d - Close popup', vim.log.levels.INFO)
end

return M
