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
            -- Pull additional schemas from the SchemaStore catalog and let the
            -- server auto-detect them by content where possible.
            schemaStore = {
                enable = true,
                url = "https://www.schemastore.org/api/json/catalog.json",
            },
            schemas = {
                ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
                ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "/*docker-compose*.{yml,yaml}",
                -- Kubernetes manifests: restrict to files that actually look
                -- like k8s manifests instead of every *.yaml in the project.
                kubernetes = {
                    "/deployments/**/*.{yml,yaml}",
                    "/k8s/**/*.{yml,yaml}",
                    "/kubernetes/**/*.{yml,yaml}",
                    "/manifests/**/*.{yml,yaml}",
                    "/deploy/**/*.{yml,yaml}",
                    "*-deployment.{yml,yaml}",
                    "*-service.{yml,yaml}",
                },
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
