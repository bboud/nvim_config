return require('packer').startup(function(use)
	use 'wbthomason/packer.nvim'

	use "EdenEast/nightfox.nvim"

	use 'nvim-lua/plenary.nvim'
	use {
	  'nvim-telescope/telescope.nvim', tag = '0.1.1',
	  requires = { {'nvim-lua/plenary.nvim'} }
	}

	use 'nvim-tree/nvim-web-devicons'
	use {'romgrk/barbar.nvim', wants = 'nvim-web-devicons'}

	use {
	  'nvim-tree/nvim-tree.lua',
	  requires = {
	    'nvim-tree/nvim-web-devicons', -- optional, for file icons
	  },
	  tag = 'nightly' -- optional, updated every week. (see issue #1193)
	}

	use { "williamboman/mason.nvim" }

	use "feline-nvim/feline.nvim"

	use 'lervag/vimtex'

	use {
	    "williamboman/mason-lspconfig.nvim",
	    "neovim/nvim-lspconfig",
	}
	  use { -- Autocompletion
	    'hrsh7th/nvim-cmp',
	    requires = { 'hrsh7th/cmp-nvim-lsp', 'L3MON4D3/LuaSnip', 'saadparwaiz1/cmp_luasnip' },
	  }
end)
