return {
    {'nvim-telescope/telescope.nvim', tag = '0.1.6', dependencies = {'nvim-lua/plenary.nvim'}},
    {'rebelot/kanagawa.nvim'},
    {'nvim-treesitter/nvim-treesitter', build = ':TSUpdate'},
    {'nvim-treesitter/playground'},
    {'theprimeagen/harpoon'},
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
        version = '^3',
        ft = { 'rust' },
    }
}

