#!/usr/bin/env python3
"""Clipboard and LLM helper for the Typo Omarchy plugin."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from typing import Any
from urllib import error, request


VERSION = 1
DEFAULT_ENDPOINT = "https://api.openai.com/v1/chat/completions"
DEFAULT_CODEX_ENDPOINT = "https://chatgpt.com/backend-api/codex/responses"
DEFAULT_CODEX_AUTH_FILE = "~/.local/share/opencode/auth.json"
DEFAULT_MODEL = "gpt-5.4-mini-fast"
DEFAULT_PROMPT = (
    "Correct spelling, grammar, punctuation, and obvious typographical errors in "
    "the text below. Preserve its meaning, tone, paragraph structure, Markdown, "
    "and code. Return only the corrected text, without commentary or quotation marks."
)


def state_path() -> Path:
    state_home = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
    return state_home / "omarchy" / "typo" / "history.json"


def history_limit() -> int:
    try:
        return max(0, min(1000, int(os.environ.get("TYPO_HISTORY_LIMIT", "100"))))
    except ValueError:
        return 100


def load_history() -> list[dict[str, Any]]:
    path = state_path()
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (FileNotFoundError, OSError, json.JSONDecodeError):
        return []
    return value if isinstance(value, list) else []


def save_history(entries: list[dict[str, Any]]) -> None:
    path = state_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(entries[: history_limit()], ensure_ascii=False, indent=2) + "\n"
    with tempfile.NamedTemporaryFile(
        mode="w", encoding="utf-8", dir=path.parent, delete=False
    ) as temporary:
        temporary.write(payload)
        temporary.flush()
        os.fsync(temporary.fileno())
        temporary_path = Path(temporary.name)
    temporary_path.replace(path)
    path.chmod(0o600)


def clear_history() -> None:
    try:
        state_path().unlink()
    except FileNotFoundError:
        pass


def clipboard_read() -> str:
    try:
        result = subprocess.run(
            ["wl-paste", "--type", "text", "--no-newline"],
            check=True,
            capture_output=True,
            text=True,
            timeout=10,
        )
    except FileNotFoundError as exc:
        raise RuntimeError("wl-paste is not installed") from exc
    except subprocess.TimeoutExpired as exc:
        raise RuntimeError("Timed out reading the clipboard") from exc
    except subprocess.CalledProcessError as exc:
        raise RuntimeError("The clipboard does not contain plain text") from exc
    if not result.stdout.strip():
        raise RuntimeError("The clipboard is empty")
    return result.stdout


def clipboard_write(text: str) -> None:
    try:
        process = subprocess.Popen(
            ["wl-copy"],
            stdin=subprocess.PIPE,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            text=True,
            start_new_session=True,
        )
    except FileNotFoundError as exc:
        raise RuntimeError("wl-copy is not installed") from exc
    try:
        assert process.stdin is not None
        process.stdin.write(text)
        process.stdin.close()
    except (BrokenPipeError, OSError) as exc:
        process.wait(timeout=1)
        raise RuntimeError("Could not write the corrected text to the clipboard") from exc


def timeout_seconds() -> int:
    try:
        return max(1, min(300, int(os.environ.get("TYPO_TIMEOUT", "60"))))
    except ValueError:
        return 60


def api_error(exc: error.HTTPError) -> str:
    detail = exc.read().decode("utf-8", errors="replace")[:500]
    try:
        parsed = json.loads(detail)
        detail = parsed.get("error", {}).get("message", detail)
    except (json.JSONDecodeError, AttributeError):
        pass
    return f"LLM request failed ({exc.code}): {detail}"


def openai_compatible_text(source: str) -> tuple[str, str]:
    endpoint = os.environ.get("TYPO_API_URL", DEFAULT_ENDPOINT).strip()
    model = os.environ.get("TYPO_MODEL", DEFAULT_MODEL).strip()
    api_key = os.environ.get("TYPO_API_KEY", "").strip()
    prompt = os.environ.get("TYPO_SYSTEM_PROMPT", DEFAULT_PROMPT).strip()
    if not endpoint:
        raise RuntimeError("TYPO_API_URL is empty")
    if not model:
        raise RuntimeError("TYPO_MODEL is empty")
    if not api_key and not endpoint.startswith(("http://localhost", "http://127.0.0.1")):
        raise RuntimeError("TYPO_API_KEY is not configured")

    payload = {
        "model": model,
        "temperature": 0,
        "messages": [
            {"role": "system", "content": prompt},
            {"role": "user", "content": source},
        ],
    }
    headers = {"Content-Type": "application/json"}
    if api_key:
        headers["Authorization"] = f"Bearer {api_key}"
    api_request = request.Request(
        endpoint,
        data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
        headers=headers,
        method="POST",
    )
    try:
        with request.urlopen(api_request, timeout=timeout_seconds()) as response:
            body = json.loads(response.read().decode("utf-8"))
    except error.HTTPError as exc:
        raise RuntimeError(api_error(exc)) from exc
    except error.URLError as exc:
        raise RuntimeError(f"Could not reach the LLM endpoint: {exc.reason}") from exc
    except TimeoutError as exc:
        raise RuntimeError("The LLM request timed out") from exc
    except json.JSONDecodeError as exc:
        raise RuntimeError("The LLM endpoint returned invalid JSON") from exc

    try:
        content = body["choices"][0]["message"]["content"]
    except (KeyError, IndexError, TypeError) as exc:
        raise RuntimeError("The LLM response did not contain corrected text") from exc
    if isinstance(content, list):
        content = "".join(
            str(part.get("text", "")) for part in content if isinstance(part, dict)
        )
    output = str(content).strip()
    if not output:
        raise RuntimeError("The LLM returned an empty correction")
    return output, model


def codex_auth_path() -> Path:
    return Path(os.path.expanduser(os.environ.get("TYPO_CODEX_AUTH_FILE", DEFAULT_CODEX_AUTH_FILE)))


def read_auth_records(path: Path) -> dict[str, Any]:
    try:
        records = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise RuntimeError("OpenCode login not found; authenticate OpenAI in OpenCode first") from exc
    except (OSError, json.JSONDecodeError) as exc:
        raise RuntimeError(f"Could not read OpenCode authentication: {exc}") from exc
    if not isinstance(records, dict):
        raise RuntimeError("OpenCode authentication has an invalid format")
    return records


def codex_auth() -> dict[str, Any]:
    path = codex_auth_path()
    provider = os.environ.get("TYPO_CODEX_AUTH_PROVIDER", "openai").strip() or "openai"
    records = read_auth_records(path)
    auth = records.get(provider)
    if not isinstance(auth, dict) or auth.get("type") != "oauth":
        raise RuntimeError(f"OpenCode OAuth provider '{provider}' is unavailable")
    if not auth.get("access"):
        raise RuntimeError("OpenCode OAuth login has no access token")
    return auth


def parse_codex_response(raw: bytes, content_type: str) -> str:
    decoded = raw.decode("utf-8", errors="replace")
    stripped = decoded.lstrip()
    is_stream = (
        "text/event-stream" in content_type.lower()
        or stripped.startswith(("event:", "data:"))
        or "\ndata:" in decoded
    )
    if not is_stream:
        try:
            response = json.loads(decoded)
        except json.JSONDecodeError as exc:
            preview = " ".join(stripped[:160].splitlines())
            raise RuntimeError(f"Codex returned an unsupported response: {preview}") from exc
        if not isinstance(response, dict):
            raise RuntimeError("Codex returned an unsupported JSON response")
        output = str(response.get("output_text") or "")
        if output:
            return output.strip()
        items = response.get("output", [])
        return "".join(
            str(part.get("text") or "")
            for item in items if isinstance(item, dict) and item.get("role") == "assistant"
            for part in item.get("content", []) if isinstance(part, dict)
        ).strip()

    chunks: list[str] = []
    final_text = ""
    for event in decoded.replace("\r\n", "\n").split("\n\n"):
        data = "\n".join(line[5:].lstrip() for line in event.splitlines() if line.startswith("data:"))
        if not data or data == "[DONE]":
            continue
        try:
            value = json.loads(data)
        except json.JSONDecodeError:
            continue
        event_type = value.get("type", "")
        if event_type == "response.output_text.delta":
            chunks.append(str(value.get("delta") or ""))
        elif event_type == "response.output_text.done":
            final_text = str(value.get("text") or "")
        elif isinstance(value.get("response"), dict):
            embedded = json.dumps(value["response"]).encode()
            embedded_text = parse_codex_response(embedded, "application/json")
            if embedded_text:
                final_text = embedded_text
        elif event_type in ("error", "response.failed"):
            problem = value.get("error", value)
            if isinstance(problem, dict):
                problem = problem.get("message", "Codex request failed")
            raise RuntimeError(str(problem))
    return (final_text or "".join(chunks)).strip()


def codex_text(source: str) -> tuple[str, str]:
    auth = codex_auth()
    endpoint = os.environ.get("TYPO_CODEX_API_URL", DEFAULT_CODEX_ENDPOINT).strip()
    if endpoint != DEFAULT_CODEX_ENDPOINT and os.environ.get("TYPO_ALLOW_CUSTOM_CODEX_URL") != "1":
        raise RuntimeError("Refusing to send OAuth credentials to a custom Codex endpoint")
    configured_model = os.environ.get("TYPO_MODEL", DEFAULT_MODEL).strip()
    fast_mode = configured_model.endswith("-fast")
    model = configured_model[:-5] if fast_mode else configured_model
    prompt = os.environ.get("TYPO_SYSTEM_PROMPT", DEFAULT_PROMPT).strip()
    payload = {
        "model": model,
        "input": [{"type": "message", "role": "user", "content": [{"type": "input_text", "text": source}]}],
        "instructions": prompt,
        "store": False,
        "stream": True,
    }
    if fast_mode:
        payload["service_tier"] = "priority"
    headers = {
        "Authorization": f"Bearer {auth['access']}",
        "Content-Type": "application/json",
        "originator": "typo",
        "User-Agent": "typo",
    }
    account_id = str(auth.get("accountId") or "")
    if account_id:
        headers["ChatGPT-Account-Id"] = account_id
    codex_request = request.Request(
        endpoint, data=json.dumps(payload, ensure_ascii=False).encode(), headers=headers, method="POST"
    )
    try:
        with request.urlopen(codex_request, timeout=timeout_seconds()) as response:
            output = parse_codex_response(response.read(), response.headers.get("Content-Type", ""))
    except error.HTTPError as exc:
        raise RuntimeError(api_error(exc)) from exc
    except error.URLError as exc:
        raise RuntimeError(f"Could not reach Codex: {exc.reason}") from exc
    except TimeoutError as exc:
        raise RuntimeError("The Codex request timed out") from exc
    if not output:
        raise RuntimeError("Codex returned an empty correction")
    return output, configured_model


def corrected_text(source: str) -> tuple[str, str]:
    provider = os.environ.get("TYPO_PROVIDER", "codex").strip().lower()
    if provider == "codex":
        return codex_text(source)
    if provider in ("openai", "openai-compatible"):
        return openai_compatible_text(source)
    raise RuntimeError("TYPO_PROVIDER must be 'codex' or 'openai-compatible'")


def emit(message_type: str, **values: Any) -> None:
    print(json.dumps({"version": VERSION, "type": message_type, **values}, ensure_ascii=False), flush=True)


def handle(message: dict[str, Any]) -> bool:
    message_type = message.get("type")
    request_id = str(message.get("id", ""))
    if message_type == "shutdown":
        return False
    if message_type == "history":
        emit("history", requestId=request_id, entries=load_history())
        return True
    if message_type == "copy":
        text = str(message.get("text", ""))
        if not text:
            raise RuntimeError("That history entry has no corrected text")
        clipboard_write(text)
        emit("copied", requestId=request_id)
        return True
    if message_type == "remove":
        entries = load_history()
        index = int(message.get("index", -1))
        if 0 <= index < len(entries):
            del entries[index]
            save_history(entries)
        emit("history", requestId=request_id, entries=entries)
        return True
    if message_type == "clear":
        clear_history()
        emit("history", requestId=request_id, entries=[])
        return True
    if message_type != "correct":
        raise RuntimeError("Unknown helper request")

    emit("status", requestId=request_id, message="Reading clipboard...")
    source = clipboard_read()
    try:
        max_chars = max(1, int(os.environ.get("TYPO_MAX_CHARS", "50000")))
    except ValueError:
        max_chars = 50000
    if len(source) > max_chars:
        raise RuntimeError(f"Clipboard text exceeds the {max_chars:,} character limit")
    emit("status", requestId=request_id, message="Correcting text...")
    output, model = corrected_text(source)
    emit("status", requestId=request_id, message="Updating clipboard...")
    clipboard_write(output)

    entries = load_history()
    if history_limit() > 0:
        from datetime import datetime

        entries.insert(
            0,
            {
                "createdAt": datetime.now().astimezone().isoformat(timespec="seconds"),
                "input": source,
                "output": output,
                "model": model,
            },
        )
        entries = entries[: history_limit()]
        save_history(entries)
    else:
        entries = []
        clear_history()
    emit("result", requestId=request_id, output=output, model=model, entries=entries)
    return True


def serve() -> int:
    emit("ready")
    for line in sys.stdin:
        try:
            message = json.loads(line)
            if not isinstance(message, dict):
                raise RuntimeError("Helper request must be an object")
            if not handle(message):
                return 0
        except (RuntimeError, ValueError, json.JSONDecodeError) as exc:
            request_id = ""
            try:
                request_id = str(message.get("id", ""))
            except (NameError, AttributeError):
                pass
            emit("error", requestId=request_id, message=str(exc))
        except Exception as exc:  # Keep the service alive after unexpected request failures.
            emit("error", message=f"Unexpected helper error: {exc}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json-lines", action="store_true", help="run the QML JSON-lines service")
    args = parser.parse_args()
    if not args.json_lines:
        parser.error("--json-lines is required")
    return serve()


if __name__ == "__main__":
    raise SystemExit(main())
