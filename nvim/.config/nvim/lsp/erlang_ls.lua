-- Installation:
-- # Install erlang_ls (Erlang Language Server)
-- brew install erlang-ls
--
-- Or build from source:
-- git clone https://github.com/erlang-ls/erlang_ls.git
-- cd erlang_ls
-- make
-- export PATH="$PATH:/path/to/erlang_ls/_build/default/bin"
--
return {
    cmd = { "erlang_ls" },                                  -- Command to start the language server
    filetypes = { "erlang" },                               -- File types that this server will handle
    root_markers = { "rebar.config", "erlang.mk", ".git" }, -- Markers to identify the root of the project
    settings = {
        erlang_ls = {
            -- Enable/disable features
            diagnosticsEnabled = true,
            completionEnabled = true,
            hoverEnabled = true,
            referencesEnabled = true,
            definitionEnabled = true,
            -- Code lens settings
            codeLensEnabled = true,
        },
    },
    single_file_support = true,
}
