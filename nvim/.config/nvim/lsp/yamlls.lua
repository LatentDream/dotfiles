-- Installation:
-- npm install -g yaml-language-server
return {
    cmd = { "yaml-language-server", "--stdio" },
    filetypes = {
        "yaml",
        "yaml.docker-compose",
        "yaml.gitlab",
    },
    root_markers = {
        ".git",
    },
    settings = {
        yaml = {
            schemas = {
                ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
                ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "/*docker-compose*.{yml,yaml}",
                kubernetes = "/*.yaml",
            },
            format = {
                enable = true,
            },
            validate = true,
            hover = true,
            completion = true,
        },
    },
    single_file_support = true,
}
