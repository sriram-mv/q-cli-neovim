<div align="center">

# q-cli-neovim
##### Get the power of Q CLI in your Neovim!

[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![Neovim](https://img.shields.io/badge/Neovim%200.9+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)
[![tmux](https://img.shields.io/badge/tmux%203.0+-red.svg?style=for-the-badge&logo=tmux)](https://github.com/tmux/tmux)
[![Amazon Q](https://img.shields.io/badge/Amazon%20Q%20CLI-orange.svg?style=for-the-badge&logo=amazon)](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line-getting-started-installing.html)

</div>

## 🎬 Demo

![Q CLI Neovim Demo](gifs/neovim-q-cli.gif)

## ✨ Features

- **Tmux Popup Integration**: Smooth popup experience that feels native to Neovim
- **Project-Specific Sessions**: Each project gets its own persistent Q CLI session
- **Dynamic Prefix Detection**: Automatically detects your tmux prefix key
- **Session Persistence**: Sessions survive popup closes - reconnect with full history
- **Simple & Reliable**: Minimal dependencies, maximum reliability
- **Flexible Keymaps**: No forced keymaps - set your own preferences

## 📋 Requirements

- Neovim 0.9+
- tmux 3.0+
- Amazon Q CLI installed and configured
- Running Neovim inside a tmux session

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'sriram-mv/q-cli-neovim',
  config = function()
    require('q-cli-neovim').setup()
    
    -- Set your preferred keymaps
    vim.keymap.set('n', '<leader>tq', '<cmd>QToggle<cr>', { desc = 'Toggle Q CLI' })
    vim.keymap.set('n', '<leader>qd', '<cmd>QDebug<cr>', { desc = 'Debug Q CLI session' })
    vim.keymap.set('n', '<leader>qc', '<cmd>QCleanup<cr>', { desc = 'Clean up Q CLI sessions' })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'sriram-mv/q-cli-neovim',
  config = function()
    require('q-cli-neovim').setup()
    
    -- Set your preferred keymaps
    vim.keymap.set('n', '<leader>tq', '<cmd>QToggle<cr>', { desc = 'Toggle Q CLI' })
    vim.keymap.set('n', '<leader>qd', '<cmd>QDebug<cr>', { desc = 'Debug Q CLI session' })
    vim.keymap.set('n', '<leader>qc', '<cmd>QCleanup<cr>', { desc = 'Clean up Q CLI sessions' })
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'sriram-mv/q-cli-neovim'

" Add to your init.vim/init.lua
lua << EOF
require('q-cli-neovim').setup()

-- Set your preferred keymaps
vim.keymap.set('n', '<leader>tq', '<cmd>QToggle<cr>', { desc = 'Toggle Q CLI' })
vim.keymap.set('n', '<leader>qd', '<cmd>QDebug<cr>', { desc = 'Debug Q CLI session' })
vim.keymap.set('n', '<leader>qc', '<cmd>QCleanup<cr>', { desc = 'Clean up Q CLI sessions' })
EOF
```

## 🚀 Usage

### Basic Commands

- `:QToggle` - Toggle Q CLI popup (creates new session or connects to existing)
- `:QDebug` - Show session information
- `:QCleanup` - Clean up orphaned sessions

### Workflow

1. Open any file in Neovim (inside tmux)
2. Run `:QToggle` (or your custom keymap) to open Q CLI popup
3. Ask questions, get help with your code
4. Press `[Your Prefix] + d` to close popup (session stays alive)
5. Run `:QToggle` again to reconnect with full history

## ⚙️ Configuration

### Default Configuration

```lua
require('q-cli-neovim').setup({
  trust_all_tools = false,     -- Disable --trust-all-tools flag by default (more secure)
  startup_timeout = 3000,      -- Time to wait for Q CLI to start (milliseconds)
})
```

### Custom Configuration Examples

```lua
-- Enable --trust-all-tools for faster workflow (less secure)
require('q-cli-neovim').setup({
  trust_all_tools = true,
})

-- Faster startup for quick machines
require('q-cli-neovim').setup({
  startup_timeout = 1500,  -- 1.5 seconds
})

-- Full custom configuration
require('q-cli-neovim').setup({
  trust_all_tools = true,   -- Enable for convenience
  startup_timeout = 4000,   -- 4 seconds
})
```

### Setting Up Keymaps

The plugin doesn't set any keymaps by default. Set your own keymaps after setup:

```lua
-- Basic setup
require('q-cli-neovim').setup()

-- Set your preferred keymaps
vim.keymap.set('n', '<leader>tq', '<cmd>QToggle<cr>', { desc = 'Toggle Q CLI' })
vim.keymap.set('n', '<leader>qd', '<cmd>QDebug<cr>', { desc = 'Debug Q CLI session' })
vim.keymap.set('n', '<leader>qc', '<cmd>QCleanup<cr>', { desc = 'Clean up Q CLI sessions' })
```

### Configuration Notes

#### Security
The `trust_all_tools` option controls whether Q CLI runs with the `--trust-all-tools` flag:

- **`false` (default)**: Q CLI will prompt before executing any tools (more secure)
- **`true`**: Q CLI will execute tools without asking for confirmation (less secure)

For security-sensitive environments, keep the default `trust_all_tools = false`. For development environments where you want faster workflows, you can set `trust_all_tools = true`.

#### Startup Timeout
The `startup_timeout` option controls how long to wait for Q CLI to initialize:

- **Default**: `3000` milliseconds (3 seconds)
- **Fast machines**: Try `1500-2000` milliseconds
- **Slow machines**: Try `4000-6000` milliseconds
- **Network issues**: May need `5000+` milliseconds

If Q CLI seems unresponsive when opening, try increasing this value.

## 🔧 How It Works

### Session Management

Each Neovim instance creates a unique Q CLI session based on:
- Current working directory
- Project name
- Directory hash (for uniqueness)

Session naming: `q-cli-{project-name}-{hash}`

### Tmux Integration

The plugin uses tmux popups for a seamless experience:
- Popups are centered and responsive
- Sessions persist when popup is closed
- Smooth transitions with proper styling
- Handles multiple projects gracefully
- Automatically detects your tmux prefix key

## 🐛 Troubleshooting

### Q CLI Not Found

```
Amazon Q CLI not found. Please install it first.
```

**Solution**: Install Amazon Q CLI following the [official documentation](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line-getting-started-installing.html).

### Not Running in Tmux

```
Not running in tmux session
```

**Solution**: Start tmux first, then run Neovim inside the tmux session.

### Session Issues

If sessions become unresponsive:

```vim
:QCleanup
```

This will clean up orphaned sessions.

### Popup Not Closing

The popup closes with your tmux prefix key + `d`. For example:
- Default tmux: `Ctrl+B` then `d`
- Custom prefix: `Ctrl+S` then `d` (or whatever your prefix is)

The plugin automatically detects and displays your prefix key.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

### Development Setup

1. Clone the repository
2. Create a symlink to your Neovim config
3. Test with different scenarios

## 📄 License

MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

- Inspired by telescope.nvim's smooth user experience
- Built for the Amazon Q CLI ecosystem
- Thanks to the Neovim and tmux communities
