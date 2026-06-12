vim.diagnostic.config({
    virtual_text = true,
    underline = true,
    signs = true,
    update_in_insert = false,
    severity_sort = true,
})

vim.api.nvim_create_autocmd("LspAttach", {
    desc = "LSP keymaps",
    callback = function(event)
        local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, {
                buffer = event.buf,
                desc = desc,
            })
        end

        map("n", "gd", vim.lsp.buf.definition, "Go to definition")
        map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
        map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
        map("n", "go", vim.lsp.buf.type_definition, "Go to type definition")
        map("n", "gr", vim.lsp.buf.references, "Go to references")

        map("n", "K", vim.lsp.buf.hover, "Hover documentation")
        map("n", "<C-k>", vim.lsp.buf.signature_help, "Signature help")

        map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
        map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")

        map("n", "<leader>ds", vim.lsp.buf.document_symbol, "Document symbols")
        map("n", "<leader>ws", vim.lsp.buf.workspace_symbol, "Workspace symbols")

        map("n", "<leader>f", function()
            vim.lsp.buf.format({ async = true })
        end, "Format buffer")
    end,
})

vim.lsp.enable({
    "bashls",
    "julials",
    "luals",
})
