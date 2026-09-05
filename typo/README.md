# Typo

An Omarchy Shell plugin that corrects spelling and grammar in the current
clipboard using a Codex membership or an OpenAI-compatible LLM API.

## Behavior

- Left-click the bar icon to correct clipboard text.
- The icon spins while the request is running.
- The corrected text replaces the clipboard when the request succeeds.
- Right-click the icon to open the correction history.
- Left-click a history result to copy it again.
- Right-click a history result to show or hide the original text.

History is stored with mode `0600` at:

```text
${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/typo/history.json
```

## Configuration

Codex membership through your existing OpenCode login is the default. Authenticate
the OpenAI provider in OpenCode first; Typo then reads the same OAuth record used
by Harness from `~/.local/share/opencode/auth.json`.

The plugin reads these variables from the `omarchy-shell` environment:

| Variable | Default | Purpose |
| --- | --- | --- |
| `TYPO_PROVIDER` | `codex` | `codex` or `openai-compatible` |
| `TYPO_CODEX_AUTH_FILE` | `~/.local/share/opencode/auth.json` | OpenCode OAuth store |
| `TYPO_CODEX_AUTH_PROVIDER` | `openai` | OAuth record name |
| `TYPO_API_KEY` | none | OpenAI-compatible provider API key |
| `TYPO_API_URL` | `https://api.openai.com/v1/chat/completions` | OpenAI-compatible chat-completions URL |
| `TYPO_MODEL` | `gpt-5.4-mini-fast` | Model identifier; `-fast` requests priority service |
| `TYPO_TIMEOUT` | `60` | Request timeout in seconds |
| `TYPO_HISTORY_LIMIT` | `100` | Saved entries; use `0` to disable history |
| `TYPO_MAX_CHARS` | `50000` | Maximum clipboard input size |
| `TYPO_SYSTEM_PROMPT` | built in | Custom correction instruction |

No API key is needed in Codex mode. The helper reloads OpenCode credentials for
each request and never writes to the shared authentication file. If OpenAI
rejects an expired token, authenticate OpenAI in OpenCode again; this avoids
racing with OpenCode or Harness over a rotating refresh token.

OpenCode exposes `gpt-5.4-mini-fast` as a convenience variant. The Codex backend
does not accept that literal model name, so Typo sends `gpt-5.4-mini` with
`service_tier: "priority"`, matching OpenCode's Fast mode.

For API-key mode, variables must be available to the graphical session that
starts `omarchy-shell`; setting them in an interactive terminal alone is not
sufficient. After changing the shell environment, restart the shell with:

```bash
omarchy restart shell
```

OpenRouter example:

```text
TYPO_PROVIDER=openai-compatible
TYPO_API_URL=https://openrouter.ai/api/v1/chat/completions
TYPO_MODEL=openai/gpt-4.1-mini
TYPO_API_KEY=...
```

Local OpenAI-compatible server example:

```text
TYPO_PROVIDER=openai-compatible
TYPO_API_URL=http://127.0.0.1:11434/v1/chat/completions
TYPO_MODEL=qwen2.5:7b
```

An API key is optional only for `localhost` and `127.0.0.1` HTTP endpoints.

## Install

Validate the checkout:

```bash
omarchy plugin validate "$PWD"
```

For development, copy this directory into the user plugin directory:

```bash
mkdir -p ~/.config/omarchy/plugins/io.github.latent.typo
cp -a ./. ~/.config/omarchy/plugins/io.github.latent.typo/
omarchy plugin enable io.github.latent.typo --section right
```

To place it immediately before the power widget:

```bash
omarchy bar put io.github.latent.typo --before omarchy.power
```

Plugin files and `shell.json` hot-reload. If needed, force discovery with:

```bash
omarchy-shell shell rescanPlugins
```

## Privacy

Clipboard text is sent to the selected provider. OAuth and API credentials are
never written to plugin configuration or history. Codex mode uses the internal
ChatGPT Codex backend, whose protocol may change independently of the public API.
History stores complete original and corrected text locally; set
`TYPO_HISTORY_LIMIT=0` if that is undesirable.
