return {
    cmd = { "omnisharp", "--languageserver", "--hostPID", tostring(vim.fn.getpid()), "-Xmx8G" },
    filetypes = { "cs", "vb" },
    root_markers = { 
        "*.sln", 
        "*.csproj", 
        "*.fsproj", 
        "*.xproj", 
        "project.json",
        ".git" 
    },
    settings = {
        FormattingOptions = {
            EnableEditorConfigSupport = true,
            OrganizeImports = true,
        },
        RoslynExtensionsOptions = {
            EnableAnalyzersSupport = true,
            EnableImportCompletion = true,
        },
    },
    single_file_support = true,
}
