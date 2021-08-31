cmd([[
augroup PackerB
autocmd!
autocmd BufWritePost plugins.lua PackerCompile
augroup end
]])

return require('packer').startup(function()
  -- Packer can manage itself
  use('wbthomason/packer.nvim')

  -- Nvim Treesitter configurations and abstraction layer
  use({
    'nvim-treesitter/nvim-treesitter',
    branch = '0.5-compat',
    run = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = 'maintained', -- one of "all", "maintained" (parsers with maintainers), or a list of languages
        highlight = {
          enable = true, -- false will disable the whole extension
          -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
          -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
          -- Using this option may slow down your editor, and you may see some duplicate highlights.
          -- Instead of true it can also be a list of languages
          additional_vim_regex_highlighting = false,
        },
      })
    end,
  })

  -- autopairs for neovim written by lua
  use({
    'windwp/nvim-autopairs',
    config = function()
      require('nvim-autopairs').setup({})
    end,
  })

  -- Find the enemy and replace them with dark power
  use({
    'windwp/nvim-spectre',
    requires = { { 'nvim-lua/popup.nvim' }, { 'nvim-lua/plenary.nvim' } },
  })

  -- Git signs written in pure lua
  use({
    'lewis6991/gitsigns.nvim',
    requires = {
      'nvim-lua/plenary.nvim',
    },
    config = function()
      require('gitsigns').setup()
      opt.signcolumn = 'yes'
    end,
  })

  -- Neovim motions on speed!
  use({
    'phaazon/hop.nvim',
    as = 'hop',
    config = function()
      -- you can configure Hop the way you like here; see :h hop-config
      require('hop').setup()
    end,
  })

  -- lsp signature hint when you type
  use({
    'ray-x/lsp_signature.nvim',
    config = function()
      require('lsp_signature').setup()
    end,
  })

  -- Quickstart configurations for the Nvim LSP client
  use({
    'neovim/nvim-lspconfig',
    config = function()
      require('./plugins/nvim-lspconfig')
    end,
  })

  -- A completion plugin for neovim coded by Lua
  use({
    'hrsh7th/nvim-cmp',
    requires = {
      { 'hrsh7th/cmp-buffer' },
      { 'hrsh7th/cmp-nvim-lua' },
      { 'hrsh7th/cmp-path' },
      { 'hrsh7th/vim-vsnip' },
      { 'hrsh7th/vim-vsnip-integ' },
      { 'rafamadriz/friendly-snippets' },
      { 'hrsh7th/cmp-nvim-lsp' },
    },
    config = function()
      require('./plugins/nvim-cmp')
    end,
  })

  -- vscode-like pictograms for neovim lsp completion items
  use({
    'onsails/lspkind-nvim',
    config = function()
      require('lspkind').init({
        with_text = true,
        preset = 'default',
      })

      local cmp = require('cmp')
      local lspkind = require('lspkind')

      cmp.setup({
        formatting = {
          format = function(entry, vim_item)
            vim_item.kind = lspkind.presets.default[vim_item.kind] .. ' ' .. vim_item.kind
            vim_item.menu = ({
              nvim_lsp = '[LSP]',
              buffer = '[Buffer]',
              nvim_lua = '[nvim-lua]',
              path = '[Path]',
              vsnip = '[Snippet]',
              --  tmux = ''[Tmux']
            })[entry.source.name]
            return vim_item
          end,
        },
      })
    end,
  })

  use({
    'terrortylor/nvim-comment',
    config = function()
      require('nvim_comment').setup()
    end,
  })

  use({
    'aserowy/tmux.nvim',
    config = function()
      -- All copy, and yank synchronization break the use of the system clipboard
      require('tmux').setup({
        -- overwrite default configuration
        -- here, e.g. to enable default bindings
        copy_sync = {
          -- enables copy sync and overwrites all register actions to
          -- sync registers *, +, unnamed, and 0 till 9 from tmux in advance
          enable = false,
        },
        -- TMUX >= 3.2: yanks (and deletes) will get redirected to system
        -- clipboard by tmux
        redirect_to_clipboard = false,
        navigation = {
          -- enables default keybindings (C-hjkl) for normal mode
          enable_default_keybindings = true,
        },
        resize = {
          -- enables default keybindings (A-hjkl) for normal mode
          enable_default_keybindings = true,
        },
      })
    end,
  })

  -- A file explorer tree for neovim written in lua
  use({
    'kyazdani42/nvim-tree.lua',
    requires = { 'kyazdani42/nvim-web-devicons' },
    config = function()
      g.nvim_tree_side = 'right'
      -- opens the tree when typing `vim $DIR` or `vim`
      g.nvim_tree_auto_open = 1
      -- closes the tree when it's the last window
      g.nvim_tree_auto_close = 1
      -- will enable file highlight for git attributes (can be used without the ico
      g.nvim_tree_git_hl = 1
      -- will show lsp diagnostics in the signcolumn. See :help nvim_tree_lsp_diagnostics
      g.nvim_tree_lsp_diagnostics = 1
    end,
  })

  use({
    'glepnir/dashboard-nvim',
    config = function()
      g.dashboard_default_executive = 'telescope'
      g.dashboard_custom_shortcut = {
        last_session = '<leader> d l',
        find_history = '<leader> d h',
        find_file = '<leader> d f',
        new_file = '<leader> d n',
        change_colorscheme = '<leader> d c',
        find_word = '<leader> d w',
        book_marks = '<leader> d b',
      }
      cmd([[
      augroup dasboard_no_indent_lines
      au!
      au FileType dashboard IndentBlanklineDisable
      augroup END
      ]])
    end,
  })

  -- The fastest Neovim colorizer
  use({
    'norcalli/nvim-colorizer.lua',
    config = function()
      -- Attaches to every FileType mode
      require('colorizer').setup()
    end,
  })

  -- Create key bindings that stick. WhichKey is a lua plugin for Neovim 0.5 that displays a popup with possible keybindings of the command you started typing.
  use({
    'folke/which-key.nvim',
    config = function()
      require('./plugins/which-key')
    end,
  })

  --  Indent guides for Neovim
  -- :h buftype
  use({
    'lukas-reineke/indent-blankline.nvim',
    config = function()
      require('indent_blankline').setup({
        char = '┊',
        buftype_exclude = { 'terminal' },
        fileTypeExclude = { 'dashboard' },
        indent_blankline_use_treesitter = true,
        indent_blankline_show_current_context = true,
      })
    end,
  })

  -- Find, Filter, Preview, Pick. All lua, all the time.
  use({
    'nvim-telescope/telescope.nvim',
    requires = { { 'nvim-lua/popup.nvim' }, { 'nvim-lua/plenary.nvim' } },
    config = function()
      local actions = require('telescope.actions')
      require('telescope').setup({
        defaults = {
          kayout_strategy = 'horizontal',
          layout_config = {
            horizontal = { preview_cutoff = 500 },
          },
          previewer = true,
          file_ignore_patterns = { 'node_modules/.*', '.git/.*', '.snakemake/.*', './conda/.*' },
          mappings = {
            i = {
              ['<esc>'] = actions.close,
            },
          },
        },
      })
    end,
  })

  -- A neovim tabline plugin
  use({
    'romgrk/barbar.nvim',
    requires = { 'kyazdani42/nvim-web-devicons' },
    config = function()
      -- Set barbar's options
      vim.g.bufferline = {
        -- Enable/disable animations
        animation = true,
        -- Enable/disable auto-hiding the tab bar when there is a single buffer
        auto_hide = false,
        -- Enable/disable current/total tabpages indicator (top right corner)
        tabpages = true,
        -- Enable/disable close button
        closable = true,
        -- Enables/disable clickable tabs
        --  - left-click: go to buffer
        --  - middle-click: delete buffer
        clickable = true,
        -- Enable/disable icons
        -- if set to 'numbers', will show buffer index in the tabline
        -- if set to 'both', will show buffer index and icons in the tabline
        icons = 'both',
        -- If set, the icon color will follow its corresponding buffer
        -- highlight group. By default, the Buffer*Icon group is linked to the
        -- Buffer* group (see Highlighting below). Otherwise, it will take its
        -- default value as defined by devicons.
        icon_custom_colors = false,

        -- Configure icons on the bufferline.
        icon_separator_active = '▎',
        icon_separator_inactive = '▎',
        icon_close_tab = '',
        icon_close_tab_modified = '●',
        icon_pinned = '車',

        -- If true, new buffers will be inserted at the end of the list.
        -- Default is to insert after current buffer.
        insert_at_end = false,

        -- Sets the maximum padding width with which to surround each tab
        maximum_padding = 1,

        -- Sets the maximum buffer name length.
        maximum_length = 30,

        -- If set, the letters for each buffer in buffer-pick mode will be
        -- assigned based on their name. Otherwise or in case all letters are
        -- already assigned, the behavior is to assign letters in order of
        -- usability (see order below)
        semantic_letters = true,

        -- New buffer letters are assigned in this order. This order is
        -- optimal for the qwerty keyboard layout but might need adjustement
        -- for other layouts.
        letters = 'asdfjkl;ghnmxcvbziowerutyqpASDFJKLGHNMXCVBZIOWERUTYQP',

        -- Sets the name of unnamed buffers. By default format is "[Buffer X]"
        -- where X is the buffer number. But only a static string is accepted here.
        no_name_title = nil,
      }
    end,
  })
  -- A neovim lua plugin to help easily manage multiple terminal windows
  use({
    'akinsho/nvim-toggleterm.lua',
    config = function()
      require('toggleterm').setup({
        open_mapping = [[<c-t>]],
        -- insert_mappings = true, -- whether or not the open mapping applies in insert mode
        start_in_insert = true,
        hide_numbers = true, -- hide the number column in toggleterm buffers
        direction = 'window',
        close_on_exit = true, -- close the terminal window when the process exits
      })
      function _G.set_terminal_keymaps()
        local opts = { noremap = true }
        vim.api.nvim_buf_set_keymap(0, 't', '<esc>', [[<C-\><C-n>]], opts)
        vim.api.nvim_buf_set_keymap(0, 't', 'jk', [[<C-\><C-n>]], opts)
        vim.api.nvim_buf_set_keymap(0, 't', '<C-h>', [[<C-\><C-n><C-W>h]], opts)
        vim.api.nvim_buf_set_keymap(0, 't', '<C-j>', [[<C-\><C-n><C-W>j]], opts)
        vim.api.nvim_buf_set_keymap(0, 't', '<C-k>', [[<C-\><C-n><C-W>k]], opts)
        vim.api.nvim_buf_set_keymap(0, 't', '<C-l>', [[<C-\><C-n><C-W>l]], opts)
      end

      -- if you only want these mappings for toggle term use term://*toggleterm#* instead
      --vim.cmd('autocmd! TermOpen * startinsert')
      --vim.cmd('autocmd! BufEnter term://* startinsert')
      vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
      vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
    end,
  })

  --  Neovim motions on speed!
  use({
    'phaazon/hop.nvim',
  })

  -- A fast and easy to configure statusline plugin for neovim.
  use({
    'hoob3rt/lualine.nvim',
    requires = { 'kyazdani42/nvim-web-devicons', opt = true },
    config = function()
      require('lualine').setup({
        options = {
          theme = 'molokai',
        },
      })
    end,
  })

  -- A NeoVim plugin for saving your work before the world collapses or you type :qa!
  use({
    'Pocco81/AutoSave.nvim',
  })

  -- More useful word motions for Vim 
  use({
    'chaoren/vim-wordmotion'
  })

  use({
    'machakann/vim-highlightedyank',
    config = function()
      g.highlightedyank_highlight_duration = 200
      cmd('highlight HighlightedyankRegion cterm=reverse gui=reverse')
    end
  })

  -- Syntax for i3 config
  use({ 'mboughaba/i3config.vim'})

  -- Syntax for snakemake
  use({
    'snakemake/snakemake',
     rtp = 'misc/vim',
     config = function()
      cmd('au BufNewFile,BufRead Snakefile,*.smk set filetype=snakemake')
     end
  })

  -- EditorConfig plugin for Vim
  use({
    'editorconfig/editorconfig-vim'
  })

  use({ 'sainnhe/sonokai' })
end)
