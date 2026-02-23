-- Installation:
-- csharp-ls has been built from source (v0.14.0) and installed manually
-- Location: ~/tools/csharp-ls
-- Wrapper script: ~/.dotnet/tools/csharp-ls
--
-- Note: Using csharp-ls instead of omnisharp for a lighter-weight C# LSP
-- To switch between csharp-ls and omnisharp, enable/disable in lua/core/lsp.lua

return {
    cmd = { "csharp-ls" },                          -- Command to start the language server
    filetypes = { "cs" },                           -- C# file types
    root_markers = {                                -- Markers to identify the root of the project
        "*.sln",                                    -- Solution file
        "*.csproj",                                 -- C# project file
        "*.fsproj",                                 -- F# project file
        ".git"                                      -- Git repository
    },
    settings = {
        csharp = {
            solution = nil,                         -- Optional: path to .sln file (nil = auto-detect)
            applyFormattingOptions = false,         -- Use .editorconfig for formatting
        },
    },
    single_file_support = true,                     -- Support opening single .cs files
}
