-- Installation:
-- npm install -g bash-language-server
return {
    cmd = { "bash-language-server", "start" },
    filetypes = {
        "sh",
        "bash",
    },
    root_markers = {
        ".git",
    },
    settings = {
        bashIde = {
            globPattern = "*@(.sh|.inc|.bash|.command)",
        },
    },
    single_file_support = true,
}
