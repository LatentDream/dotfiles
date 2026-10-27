-- Installation:
-- npm install -g typescript-language-server typescript
-- TypeScript 7 uses its native LSP; older versions use typescript-language-server.
--
-- North uses the native TypeScript 7 language server. Its workspace package is
-- named `typescript-7`; the `typescript` package intentionally has no
-- tsserver.js, so typescript-language-server cannot run against it.
local function is_typescript_7(package_dir)
    local package_json = package_dir .. "/package.json"
    if vim.fn.filereadable(package_json) ~= 1 then
        return false
    end

    local ok, package = pcall(vim.json.decode, table.concat(vim.fn.readfile(package_json), "\n"))
    return ok and package.version and vim.startswith(package.version, "7.")
end

local function find_native_typescript(root_dir)
    local dir = root_dir
    while dir do
        for _, package_name in ipairs({ "typescript-7", "typescript" }) do
            local package_dir = dir .. "/node_modules/" .. package_name
            local executable = package_dir .. "/bin/tsc"
            if vim.fn.executable(executable) == 1 and is_typescript_7(package_dir) then
                return executable
            end
        end

        local parent = vim.fs.dirname(dir)
        if parent == dir then
            break
        end
        dir = parent
    end

    -- Worktrees without node_modules can use a global native TypeScript install.
    -- Resolve the npm bin symlink to locate its package.json.
    local executable = vim.uv.fs_realpath(vim.fn.exepath("tsc"))
    if executable then
        local package_dir = vim.fs.dirname(vim.fs.dirname(executable))
        if is_typescript_7(package_dir) then
            return executable
        end
    end
end

return {
    cmd = function(dispatchers, config)
        local native_typescript = find_native_typescript(config.root_dir)
        local command = native_typescript
                and { native_typescript, "--lsp", "--stdio" }
            or { "typescript-language-server", "--stdio" }

        return vim.lsp.rpc.start(command, dispatchers, {
            cwd = config.cmd_cwd,
            env = config.cmd_env,
            detached = config.detached,
        })
    end,
    filetypes = {
        "javascript",
        "javascriptreact",
        "javascript.jsx",
        "typescript",
        "typescriptreact",
        "typescript.tsx",
    },
    root_markers = {
        "package.json",
        "tsconfig.json",
        "jsconfig.json",
        ".git",
    },
    single_file_support = true,
}
