return {
    {'nvim-telescope/telescope.nvim', version = '^0.2', dependencies = {'nvim-lua/plenary.nvim'}},
    {'sainnhe/everforest'},
    {'nvim-treesitter/nvim-treesitter', branch = 'main', lazy = false, build = ':TSUpdate'},
    {'mbbill/undotree'},
    {'tpope/vim-fugitive'},
    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v3.x',
        dependencies = {
            'williamboman/mason.nvim',
            'williamboman/mason-lspconfig.nvim',
            'neovim/nvim-lspconfig',
            'hrsh7th/nvim-cmp',
            'hrsh7th/cmp-nvim-lsp',
            'L3MON4D3/LuaSnip'
        }
    },
    {'terrortylor/nvim-comment'},
    {'rust-lang/rust.vim'},
    {
      'mrcjkb/rustaceanvim',
      version = '^5', -- Recommended
      lazy = false, -- This plugin is already lazy
    }
}

