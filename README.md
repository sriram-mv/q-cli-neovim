# q-cli.nvim

A lean and mean Neovim plugin that provides seamless integration with Amazon Q CLI through tmux popups. Get the power of Amazon Q directly in your editor with a telescope-like experience.

## ✨ Features

- **Tmux Popup Integration**: Smooth popup experience that feels native to Neovim
- **Project-Specific Sessions**: Each project gets its own persistent Q CLI session
- **Dynamic Prefix Detection**: Automatically detects your tmux prefix key
- **Session Persistence**: Sessions survive popup closes - reconnect with full history
- **Simple & Reliable**: Minimal dependencies, maximum reliability

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
  end,
  keys = {
    { '<leader>tq', '<cmd>QToggle<cr>', desc = 'Toggle Q CLI' },
  },
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'sriram-mv/q-cli-neovim',
  config = function()
    require('q-cli-neovim').setup()
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'sriram-mv/q-cli-neovim'

" Add to your init.vim/init.lua
lua require('q-cli-neovim').setup()
```

## 🚀 Usage

### Basic Commands

- `<leader>tq` - Toggle Q CLI popup (creates new session or connects to existing)
- `[Your Prefix] + d` - Close popup (keeps session alive)

### User Commands

- `:QToggle` - Toggle Q CLI popup
- `:QDebug` - Show session information
- `:QCleanup` - Clean up orphaned sessions

### Workflow

1. Open any file in Neovim (inside tmux)
2. Press `<leader>tq` to open Q CLI popup
3. Ask questions, get help with your code
4. Press `[Your Prefix] + d` to close popup (session stays alive)
5. Press `<leader>tq` again to reconnect with full history

## ⚙️ Configuration

### Default Configuration

```lua
require('q-cli-neovim').setup({
  keymap = '<leader>tq',  -- Key mapping to toggle Q CLI
})
```

### Custom Configuration Examples

```lua
-- Custom keymap
require('q-cli-neovim').setup({
  keymap = '<C-q>',
})
```

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

## 📄 License

MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

- Built for the Amazon Q CLI ecosystem
- Thanks to the Neovim and tmux communities
