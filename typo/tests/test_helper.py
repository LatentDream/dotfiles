import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import helper


class HelperTests(unittest.TestCase):
    def test_history_round_trip(self):
        entry = {"createdAt": "now", "input": "teh", "output": "the", "model": "test"}
        with tempfile.TemporaryDirectory() as directory:
            with mock.patch.dict(os.environ, {"XDG_STATE_HOME": directory}, clear=False):
                helper.save_history([entry])
                self.assertEqual(helper.load_history(), [entry])
                self.assertEqual(oct(helper.state_path().stat().st_mode & 0o777), "0o600")

    def test_corrected_text_parses_openai_response(self):
        response = mock.MagicMock()
        response.__enter__.return_value.read.return_value = json.dumps(
            {"choices": [{"message": {"content": "This is fixed."}}]}
        ).encode()
        environment = {
            "TYPO_PROVIDER": "openai-compatible",
            "TYPO_API_KEY": "secret",
            "TYPO_MODEL": "test-model",
        }
        with mock.patch.dict(os.environ, environment, clear=False):
            with mock.patch("helper.request.urlopen", return_value=response):
                output, model = helper.corrected_text("Ths is fixed.")
        self.assertEqual(output, "This is fixed.")
        self.assertEqual(model, "test-model")

    def test_parse_codex_stream(self):
        stream = (
            'data: {"type":"response.output_text.delta","delta":"This is "}\n\n'
            'data: {"type":"response.output_text.delta","delta":"fixed."}\n\n'
            'data: {"type":"response.completed"}\n\n'
            "data: [DONE]\n\n"
        ).encode()
        self.assertEqual(helper.parse_codex_response(stream, "text/event-stream"), "This is fixed.")

    def test_parse_codex_stream_without_content_type(self):
        stream = (
            'event: response.output_text.done\r\n'
            'data: {"type":"response.output_text.done","text":"Fixed."}\r\n\r\n'
        ).encode()
        self.assertEqual(helper.parse_codex_response(stream, "application/json"), "Fixed.")

    def test_parse_codex_completed_embedded_response(self):
        stream = (
            'data: {"type":"response.completed","response":{"output_text":"Fixed."}}\n\n'
        ).encode()
        self.assertEqual(helper.parse_codex_response(stream, "text/event-stream"), "Fixed.")

    def test_codex_auth_reads_opencode_record(self):
        record = {
            "openai": {
                "type": "oauth",
                "access": "access-token",
                "refresh": "refresh-token",
                "expires": 9999999999999,
                "accountId": "account-id",
            }
        }
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "auth.json"
            path.write_text(json.dumps(record), encoding="utf-8")
            with mock.patch.dict(os.environ, {"TYPO_CODEX_AUTH_FILE": str(path)}, clear=False):
                self.assertEqual(helper.codex_auth()["access"], "access-token")

    def test_codex_request_uses_membership_headers(self):
        response = mock.MagicMock()
        response.__enter__.return_value.read.return_value = (
            'data: {"type":"response.output_text.done","text":"Fixed."}\n\n'
        ).encode()
        response.__enter__.return_value.headers.get.return_value = "text/event-stream"
        environment = {"TYPO_PROVIDER": "codex", "TYPO_MODEL": "test-model"}
        with mock.patch.dict(os.environ, environment, clear=False):
            with mock.patch(
                "helper.codex_auth",
                return_value={"access": "access-token", "accountId": "account-id"},
            ):
                with mock.patch("helper.request.urlopen", return_value=response) as urlopen:
                    output, model = helper.corrected_text("Fix me")
        sent = urlopen.call_args.args[0]
        self.assertEqual(sent.get_header("Authorization"), "Bearer access-token")
        self.assertEqual(sent.get_header("Chatgpt-account-id"), "account-id")
        self.assertEqual(output, "Fixed.")
        self.assertEqual(model, "test-model")

    def test_codex_fast_variant_uses_base_model_and_priority_tier(self):
        response = mock.MagicMock()
        response.__enter__.return_value.read.return_value = (
            'data: {"type":"response.output_text.done","text":"Fixed."}\n\n'
        ).encode()
        response.__enter__.return_value.headers.get.return_value = "text/event-stream"
        with mock.patch.dict(os.environ, {"TYPO_MODEL": "gpt-5.4-mini-fast"}, clear=False):
            with mock.patch("helper.codex_auth", return_value={"access": "token"}):
                with mock.patch("helper.request.urlopen", return_value=response) as urlopen:
                    output, model = helper.codex_text("Fix me")
        payload = json.loads(urlopen.call_args.args[0].data)
        self.assertEqual(payload["model"], "gpt-5.4-mini")
        self.assertEqual(payload["service_tier"], "priority")
        self.assertEqual(output, "Fixed.")
        self.assertEqual(model, "gpt-5.4-mini-fast")

    def test_handle_correct_updates_clipboard_and_history(self):
        with tempfile.TemporaryDirectory() as directory:
            with mock.patch.dict(os.environ, {"XDG_STATE_HOME": directory}, clear=False):
                with mock.patch("helper.clipboard_read", return_value="teh text"):
                    with mock.patch("helper.corrected_text", return_value=("the text", "test-model")):
                        with mock.patch("helper.clipboard_write") as clipboard_write:
                            with mock.patch("helper.emit") as emit:
                                self.assertTrue(helper.handle({"type": "correct", "id": "request-1"}))

                clipboard_write.assert_called_once_with("the text")
                self.assertEqual(helper.load_history()[0]["output"], "the text")
                self.assertEqual(emit.call_args.args[0], "result")

    def test_clipboard_write_does_not_wait_for_owner_to_exit(self):
        process = mock.MagicMock()
        with mock.patch("helper.subprocess.Popen", return_value=process) as popen:
            helper.clipboard_write("corrected text")
        popen.assert_called_once()
        process.stdin.write.assert_called_once_with("corrected text")
        process.stdin.close.assert_called_once_with()
        process.wait.assert_not_called()

    def test_zero_history_limit_removes_existing_history(self):
        with tempfile.TemporaryDirectory() as directory:
            with mock.patch.dict(
                os.environ,
                {"XDG_STATE_HOME": directory, "TYPO_HISTORY_LIMIT": "1"},
                clear=False,
            ):
                helper.save_history([{"output": "old"}])
                self.assertTrue(helper.state_path().exists())

            with mock.patch.dict(
                os.environ,
                {"XDG_STATE_HOME": directory, "TYPO_HISTORY_LIMIT": "0"},
                clear=False,
            ):
                with mock.patch("helper.clipboard_read", return_value="teh"):
                    with mock.patch("helper.corrected_text", return_value=("the", "test")):
                        with mock.patch("helper.clipboard_write"):
                            with mock.patch("helper.emit"):
                                helper.handle({"type": "correct", "id": "request-2"})
                self.assertFalse(helper.state_path().exists())


if __name__ == "__main__":
    unittest.main()
