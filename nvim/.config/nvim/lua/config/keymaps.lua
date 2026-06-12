-- A basic keymap to save the file
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

local keymap = vim.keymap.set

-- Better defaults
keymap("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Save / quit
keymap("n", "<leader>w", "<cmd>write<CR>", { desc = "Save file" })
keymap("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit" })
keymap("n", "<leader>Q", "<cmd>quitall<CR>", { desc = "Quit all" })

-- Window navigation
keymap("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Window management
keymap("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "Split window vertically" })
keymap("n", "<leader>sh", "<cmd>split<CR>", { desc = "Split window horizontally" })
keymap("n", "<leader>se", "<C-w>=", { desc = "Equalize window sizes" })
keymap("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close window" })

-- Resize windows
keymap("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
keymap("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
keymap("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
keymap("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

-- Buffers
keymap("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
keymap("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })

-- Keep visual selection when indenting
keymap("v", "<", "<gv", { desc = "Indent left" })
keymap("v", ">", ">gv", { desc = "Indent right" })

-- no yanks
keymap("v", "r", '"_dP', { desc = "Replace without yanking deleted text" })
keymap({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete without yanking" })

-- system clipboard
keymap({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
keymap("n", "<leader>p", '"+p', { desc = "Paste from system clipboard" })

-- Select all
keymap("n", "<leader>a", "ggVG", { desc = "Select all" })

-- Quickfix list
keymap("n", "[q", "<cmd>cprevious<CR>", { desc = "Previous quickfix item" })
keymap("n", "]q", "<cmd>cnext<CR>", { desc = "Next quickfix item" })
keymap("n", "<leader>qo", "<cmd>copen<CR>", { desc = "Open quickfix list" })
keymap("n", "<leader>qc", "<cmd>cclose<CR>", { desc = "Close quickfix list" })

-- Terminal mode
keymap("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
