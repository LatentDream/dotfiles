-- Installation:
-- uv tool install basedpyright
--
-- Types only. Honors pyrightconfig.json so editor checks match CI.
-- Prefers <project>/.venv (the interpreter created by make setup-eno).
local function project_python(root)
    if not root or root == "" then
        return nil
    end
    local python = vim.fs.joinpath(root, ".venv", "bin", "python")
    if vim.fn.executable(python) == 1 then
        return python
    end
    return nil
end

return {
    cmd = { "basedpyright-langserver", "--stdio" },
    filetypes = { "python" },
    root_markers = {
        {
            "pyrightconfig.json",
            "pyproject.toml",
            "setup.py",
            "setup.cfg",
            "requirements.txt",
            "Pipfile",
        },
        ".git",
    },
    settings = {
        basedpyright = {
            -- Ruff organizes imports and reports lint.
            disableOrganizeImports = true,
            analysis = {
                autoSearchPaths = true,
                diagnosticMode = "openFilesOnly",
                useLibraryCodeForTypes = true,
                inlayHints = {
                    variableTypes = false,
                    callArgumentNames = false,
                    functionReturnTypes = false,
                    genericTypes = false,
                },
            },
        },
    },
    before_init = function(_, config)
        local python = project_python(config.root_dir)
        if not python then
            return
        end
        config.settings = vim.tbl_deep_extend("force", config.settings or {}, {
            python = {
                pythonPath = python,
            },
        })
    end,
}
