-- =========================================================
-- Basic Settings
-- =========================================================

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.incsearch = true
vim.opt.hlsearch = true

vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"

vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.wrap = false
vim.opt.updatetime = 250

vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"
vim.opt.undofile = true


-- =========================================================
-- Diagnostics
-- =========================================================

vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    update_in_insert = true,
    severity_sort = true,
})


-- =========================================================
-- lazy.nvim
-- =========================================================

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "--branch=stable",
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    })
end

vim.opt.rtp:prepend(lazypath)


-- =========================================================
-- Plugins
-- =========================================================

require("lazy").setup({
    -- =======================================================
    -- AI AGENT
    -- =======================================================

    {
    "yetone/avante.nvim",
    event = "VeryLazy",
    version = false,
    build = "make",

    opts = {
        provider = "cursor",
        mode = "agentic",

        acp_providers = {
            cursor = {
                command = vim.fn.expand("~/.local/bin/agent"),
                args = { "acp" },

                auth_method = "cursor_login",

                env = {
                    HOME = vim.fn.expand("~"),
                    PATH = vim.env.PATH,
                },
            },
        },
    },

    dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        "nvim-tree/nvim-web-devicons",

        {
            "MeanderingProgrammer/render-markdown.nvim",
            opts = {
                file_types = {
                    "markdown",
                    "Avante",
                },
            },
            ft = {
                "markdown",
                "Avante",
            },
        },
    },
},
    -- =======================================================
    -- UI
    -- =======================================================
{
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,

    opts = {
        flavour = "mocha",

        integrations = {
            treesitter = true,
            lsp_trouble = true,
            native_lsp = {
                enabled = true,
            },
            telescope = true,
            nvimtree = true,
            gitsigns = true,
            blink_cmp = true,
        },
    },

    config = function(_, opts)
        require("catppuccin").setup(opts)
        vim.cmd.colorscheme("catppuccin")
    end,
},
    {
        "nvim-lualine/lualine.nvim",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        opts = {},
    },

    {
        "folke/which-key.nvim",
        event = "VeryLazy",

        opts = {
            preset = "helix",

            delay = 300,

            icons = {
                breadcrumb = "»",
                separator = "➜",
                group = "+",
            },
        },
    },

    {
        "nvim-tree/nvim-tree.lua",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        cmd = {
            "NvimTreeToggle",
            "NvimTreeFocus",
        },
        opts = {},
    },


    -- =======================================================
    -- Completion
    -- =======================================================

    {
        "saghen/blink.cmp",
        version = "1.*",

        dependencies = {
            "rafamadriz/friendly-snippets",
        },

        opts = {
            keymap = {
                preset = "super-tab",
            },

            appearance = {
                nerd_font_variant = "mono",
            },

            completion = {
                documentation = {
                    auto_show = true,
                    auto_show_delay_ms = 200,
                },

                menu = {
                    border = "rounded",
                },
            },

            sources = {
                default = {
                    "lsp",
                    "path",
                    "snippets",
                    "buffer",
                },
            },

            signature = {
                enabled = true,
            },

            cmdline = {
                keymap = {
                    preset = "inherit",
                },

                completion = {
                    menu = {
                        auto_show = true,
                    },
                },
            },
        },
    },


    -- =======================================================
    -- Fuzzy Finder
    -- =======================================================

    {
        "nvim-telescope/telescope.nvim",
        version = "*",

        dependencies = {
            "nvim-lua/plenary.nvim",

            {
                "nvim-telescope/telescope-fzf-native.nvim",
                build = "make",
            },

            "nvim-tree/nvim-web-devicons",
        },

        opts = {},
    },


    -- =======================================================
    -- LSP
    -- =======================================================

    {
        "neovim/nvim-lspconfig",
    },

    {
        "williamboman/mason.nvim",
        build = ":MasonUpdate",
        opts = {},
    },


    -- =======================================================
    -- Rust
    -- =======================================================

    {
        "mrcjkb/rustaceanvim",
        version = "^9",
        lazy = false,

        config = function()
            vim.g.rustaceanvim = {
                server = {
                    default_settings = {
                        ["rust-analyzer"] = {

                            check = {
                                command = "clippy",
                            },

                            cargo = {
                                allFeatures = true,
                            },

                            procMacro = {
                                enable = true,
                            },

                            inlayHints = {

                                bindingModeHints = {
                                    enable = true,
                                },

                                closureReturnTypeHints = {
                                    enable = "always",
                                },

                                discriminantHints = {
                                    enable = "always",
                                },

                                expressionAdjustmentHints = {
                                    enable = "always",
                                },

                                lifetimeElisionHints = {
                                    enable = "always",
                                    useParameterNames = true,
                                },

                                typeHints = {
                                    enable = true,
                                },
                            },
                        },
                    },
                },
            }

            -- Compatibility command
            vim.api.nvim_create_user_command("RustExpandMacro", function()
                vim.cmd("RustLsp expandMacro")
            end, {
                desc = "Expand Rust macro",
            })
        end,
    },


    -- =======================================================
    -- Treesitter
    -- =======================================================

    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        build = ":TSUpdate",

        config = function()
            require("nvim-treesitter").setup({
                install_dir = vim.fn.stdpath("data") .. "/site",
            })

            require("nvim-treesitter").install({
                "rust",

                "lua",
                "vim",
                "vimdoc",
                "query",

                "python",

                "javascript",
                "typescript",
                "tsx",
                "json",

                "html",
                "css",

                "bash",
                "yaml",

                "markdown",
                "markdown_inline",

                "dockerfile",
            })

            vim.api.nvim_create_autocmd("FileType", {
                callback = function()
                    if vim.treesitter.language.add(vim.bo.filetype) then
                        vim.treesitter.start()
                    end
                end,
            })
        end,
    },


    -- =======================================================
    -- Formatting
    -- =======================================================

    {
        "stevearc/conform.nvim",

        opts = {
            formatters_by_ft = {
                lua = { "stylua" },

                python = { "black" },

                javascript = { "prettier" },
                typescript = { "prettier" },
                typescriptreact = { "prettier" },

                json = { "prettier" },
                html = { "prettier" },
                css = { "prettier" },

                rust = { "rustfmt" },
            },

            format_on_save = {
                timeout_ms = 500,
                lsp_fallback = true,
            },
        },
    },


    -- =======================================================
    -- Linting
    -- =======================================================

    {
        "mfussenegger/nvim-lint",

        config = function()
            local lint = require("lint")

            lint.linters_by_ft = {
                python = { "ruff" },

                javascript = { "eslint_d" },
                typescript = { "eslint_d" },

                dockerfile = { "hadolint" },
            }

            vim.api.nvim_create_autocmd({
                "BufWritePost",
                "BufReadPost",
                "InsertLeave",
            }, {
                callback = function()
                    lint.try_lint()
                end,
            })
        end,
    },


    -- =======================================================
    -- Git
    -- =======================================================

    {
        "lewis6991/gitsigns.nvim",
        opts = {},
    },

    {
        "tpope/vim-fugitive",

        cmd = {
            "Git",
            "Gdiffsplit",
            "Gvdiffsplit",
            "Gread",
            "Gwrite",
        },
    },


    -- =======================================================
    -- Navigation
    -- =======================================================

    {
        "folke/flash.nvim",
        event = "VeryLazy",
        opts = {},
    },


    -- =======================================================
    -- Code Editing
    -- =======================================================

    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        opts = {},
    },

    {
        "numToStr/Comment.nvim",
        event = "VeryLazy",
        opts = {},
    },

    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        opts = {},
    },


    -- =======================================================
    -- Diagnostics / TODO
    -- =======================================================

    {
        "folke/trouble.nvim",
        cmd = "Trouble",
        opts = {},
    },

    {
        "folke/todo-comments.nvim",
        event = "VeryLazy",

        dependencies = {
            "nvim-lua/plenary.nvim",
        },

        opts = {},
    },

})


-- =========================================================
-- General Keybindings
-- =========================================================

local map = vim.keymap.set
local telescope = require("telescope.builtin")


-- =========================================================
-- Helix Space Mode
-- =========================================================

-- ---------------------------------------------------------
-- File finding / browsing
-- ---------------------------------------------------------

-- Space f
-- Find files by name
map("n", "<leader>f", telescope.find_files, {
    desc = "Find Files",
})

-- Space /
-- Search inside files
map("n", "<leader>/", telescope.live_grep, {
    desc = "Search in Files",
})

-- Space e
-- Explorer at workspace root
map("n", "<leader>e", function()
    require("nvim-tree.api").tree.open({
        path = vim.fn.getcwd(),
    })
end, {
    desc = "File Explorer",
})

-- Space E
-- Explorer at current file directory
map("n", "<leader>E", function()
    local path = vim.fn.expand("%:p:h")

    if path == "" then
        path = vim.fn.getcwd()
    end

    require("nvim-tree.api").tree.open({
        path = path,
    })
end, {
    desc = "Explorer Here",
})


-- ---------------------------------------------------------
-- Pickers
-- ---------------------------------------------------------

-- Space b
-- Open buffers
map("n", "<leader>b", telescope.buffers, {
    desc = "Buffers",
})

-- Space j
-- Jumplist
map("n", "<leader>j", telescope.jumplist, {
    desc = "Jumplist",
})

-- Space '
-- Recent files / previous picker-like behavior
map("n", "<leader>'", telescope.oldfiles, {
    desc = "Recent Files",
})


-- ---------------------------------------------------------
-- Code / LSP
-- ---------------------------------------------------------

-- Space s
-- Symbols in current file
map("n", "<leader>s", telescope.lsp_document_symbols, {
    desc = "Document Symbols",
})

-- Space S
-- Symbols across workspace
map("n", "<leader>S", telescope.lsp_workspace_symbols, {
    desc = "Workspace Symbols",
})

-- Space d
-- Diagnostic under cursor
map("n", "<leader>d", vim.diagnostic.open_float, {
    desc = "Diagnostics",
})

-- Space D
-- All workspace diagnostics
map("n", "<leader>D", function()
    vim.diagnostic.setqflist()
end, {
    desc = "Workspace Diagnostics",
})

-- Space a
-- Code action
map("n", "<leader>a", vim.lsp.buf.code_action, {
    desc = "Code Action",
})

-- Space k
-- Hover documentation
map("n", "<leader>k", vim.lsp.buf.hover, {
    desc = "Hover",
})

-- Space r
-- Rename
map("n", "<leader>r", vim.lsp.buf.rename, {
    desc = "Rename",
})

-- Space h
-- References
map("n", "<leader>h", telescope.lsp_references, {
    desc = "References",
})


-- ---------------------------------------------------------
-- Clipboard
-- ---------------------------------------------------------

-- Space Y
map({ "n", "x" }, "<leader>Y", '"+y', {
    desc = "Copy to Clipboard",
})

-- Space R
map({ "n", "x" }, "<leader>R", '"+p', {
    desc = "Paste from Clipboard",
})


-- ---------------------------------------------------------
-- Comments
-- ---------------------------------------------------------

-- Space c
map("n", "<leader>c", function()
    require("Comment.api").toggle.linewise.current()
end, {
    desc = "Toggle Comment",
})

map("x", "<leader>c", function()
    require("Comment.api").toggle.linewise(vim.fn.visualmode())
end, {
    desc = "Toggle Comment",
})


-- ---------------------------------------------------------
-- Window mode
-- ---------------------------------------------------------

-- Space w
-- Enter normal Vim window commands
map("n", "<leader>w", "<C-w>", {
    desc = "Window",
})


-- ---------------------------------------------------------
-- Command palette
-- ---------------------------------------------------------

-- Space ?
map("n", "<leader>?", telescope.commands, {
    desc = "Command Palette",
})


-- =========================================================
-- Save / Quit
-- =========================================================

-- Space w s
map("n", "<leader>ws", "<cmd>w<cr>", {
    desc = "Save",
})

-- Space q
map("n", "<leader>q", "<cmd>q<cr>", {
    desc = "Quit",
})


-- =========================================================
-- Clear Search Highlight
-- =========================================================

map("n", "<Esc>", "<cmd>nohlsearch<cr>", {
    desc = "Clear search highlight",
})


-- =========================================================
-- Window Navigation
-- =========================================================

map("n", "<C-h>", "<C-w>h", {
    desc = "Move left",
})

map("n", "<C-j>", "<C-w>j", {
    desc = "Move down",
})

map("n", "<C-k>", "<C-w>k", {
    desc = "Move up",
})

map("n", "<C-l>", "<C-w>l", {
    desc = "Move right",
})


-- =========================================================
-- Buffer Navigation
-- =========================================================

map("n", "<S-l>", "<cmd>bnext<cr>", {
    desc = "Next buffer",
})

map("n", "<S-h>", "<cmd>bprevious<cr>", {
    desc = "Previous buffer",
})

map("n", "<leader>x", "<cmd>bdelete<cr>", {
    desc = "Close buffer",
})

-- =========================================================
-- CURSOR
-- =========================================================
map("n", "<leader>i", "<cmd>AvanteAsk<CR>", {
    desc = "Cursor AI",
})
-- =========================================================
-- Visual Mode
-- =========================================================

map("v", "<", "<gv")
map("v", ">", ">gv")

map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")


-- =========================================================
-- Terminal
-- =========================================================

map("n", "<leader>t", "<cmd>split | terminal<cr>", {
    desc = "Open terminal",
})

map("t", "<Esc>", "<C-\\><C-n>", {
    desc = "Exit terminal mode",
})


-- =========================================================
-- Git
-- =========================================================

map("n", "<leader>gg", "<cmd>Git<CR>", {
    desc = "Git Status",
})

map("n", "<leader>gd", "<cmd>Gdiffsplit<CR>", {
    desc = "Git Diff",
})


-- =========================================================
-- Diagnostics
-- =========================================================

map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", {
    desc = "Diagnostics",
})

map("n", "<leader>xq", vim.diagnostic.setloclist, {
    desc = "Diagnostic List",
})

map("n", "[d", vim.diagnostic.goto_prev, {
    desc = "Previous Diagnostic",
})

map("n", "]d", vim.diagnostic.goto_next, {
    desc = "Next Diagnostic",
})


-- =========================================================
-- TODO
-- =========================================================

map("n", "<leader>ft", "<cmd>TodoTelescope<CR>", {
    desc = "Find TODOs",
})


-- =========================================================
-- Navigation / Flash
-- =========================================================

map({ "n", "x", "o" }, "s", function()
    require("flash").jump()
end, {
    desc = "Flash Jump",
})


-- =========================================================
-- LSP
-- =========================================================

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(event)

        local bufnr = event.buf

        local opts = {
            buffer = bufnr,
            silent = true,
        }


        -- -------------------------------------------------
        -- Inlay Hints
        -- -------------------------------------------------

        if vim.lsp.inlay_hint then
            vim.lsp.inlay_hint.enable(true, {
                bufnr = bufnr,
            })
        end


        -- -------------------------------------------------
        -- Navigation
        -- -------------------------------------------------

        map("n", "gd", vim.lsp.buf.definition, opts)

        map("n", "gD", vim.lsp.buf.declaration, opts)

        map("n", "gr", vim.lsp.buf.references, opts)

        map("n", "gi", vim.lsp.buf.implementation, opts)


        -- -------------------------------------------------
        -- Information
        -- -------------------------------------------------

        map("n", "K", vim.lsp.buf.hover, opts)


        -- -------------------------------------------------
        -- Signature Help
        -- -------------------------------------------------

        map("n", "<leader>k", vim.lsp.buf.signature_help, opts)


        -- -------------------------------------------------
        -- Rename
        -- -------------------------------------------------

        map("n", "<leader>rn", vim.lsp.buf.rename, opts)


        -- -------------------------------------------------
        -- Code Actions
        -- -------------------------------------------------

        map("n", "<leader>ca", vim.lsp.buf.code_action, opts)


        -- -------------------------------------------------
        -- Formatting
        -- -------------------------------------------------

        -- Space c f
        map("n", "<leader>cf", function()
            vim.lsp.buf.format({
                async = true,
            })
        end, {
            buffer = bufnr,
            silent = true,
            desc = "Format",
        })


        -- -------------------------------------------------
        -- Toggle Inlay Hints
        -- -------------------------------------------------

        -- Space h
        -- Note: LSP reference mapping above uses Space h.
        -- Use Space h h for inlay hints.
        map("n", "<leader>hh", function()

            local enabled = vim.lsp.inlay_hint.is_enabled({
                bufnr = bufnr,
            })

            vim.lsp.inlay_hint.enable(not enabled, {
                bufnr = bufnr,
            })

        end, {
            buffer = bufnr,
            silent = true,
            desc = "Toggle Inlay Hints",
        })

    end,
})


-- =========================================================
-- Rust-specific
-- =========================================================

vim.api.nvim_create_autocmd("FileType", {
    pattern = "rust",

    callback = function()

        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
        vim.opt_local.softtabstop = 4

    end,
})


-- =========================================================
-- Startup
-- =========================================================

vim.notify("Neovim ready", vim.log.levels.INFO)
