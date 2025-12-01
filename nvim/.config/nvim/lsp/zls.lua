-- Installation:
-- # Install zls (Zig language server)
-- Download from https://github.com/zigtools/zls/releases
-- Or build from source:
-- git clone https://github.com/zigtools/zls && cd zls
-- zig build -Doptimize=ReleaseSafe
--
-- Make sure zls is in the PATH
-- export PATH="$PATH:/path/to/zls/bin"

return {
    cmd = { "zls" },                                    -- Command to start the language server
    filetypes = { "zig", "zir" },                       -- File types that this server will handle
    root_markers = { "zls.json", "build.zig", ".git" }, -- Markers to identify the root of the project
    settings = {
        zls = {
            enable_snippets = true,
            enable_ast_check_diagnostics = true,
            enable_autofix = true,
            enable_import_embedfile_argument_completions = true,
            warn_style = true,
            highlight_global_var_declarations = true,
            dangerous_comptime_experiments_do_not_enable = false,
            skip_std_references = false,
            prefer_ast_check_as_child_process = true,
            enable_build_on_save = false,
            build_on_save_step = "install",
            enable_autofix_on_save = false,
            semantic_tokens = "full",
            inlay_hints_show_variable_type_hints = true,
            inlay_hints_show_struct_literal_field_type = true,
            inlay_hints_show_parameter_name = true,
            inlay_hints_show_builtin = true,
            inlay_hints_exclude_single_argument = true,
            inlay_hints_hide_redundant_param_names = false,
            inlay_hints_hide_redundant_param_names_last_token = false,
        },
    },
}
