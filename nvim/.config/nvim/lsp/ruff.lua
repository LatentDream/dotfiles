-- Installation:
-- uv tool install ruff
--
-- Lint and format. Type checking stays with basedpyright.
-- Project rules come from pyproject.toml / ruff.toml (same as make lint / make format).
return {
    cmd = { "ruff", "server" },
    filetypes = { "python" },
    root_markers = {
        {
            "pyproject.toml",
            "ruff.toml",
            ".ruff.toml",
            "pyrightconfig.json",
            "setup.py",
            "setup.cfg",
            "requirements.txt",
            "Pipfile",
        },
        ".git",
    },
    on_attach = function(client)
        -- Hover, signature, and go-to-definition come from basedpyright.
        client.server_capabilities.hoverProvider = false
    end,
}
