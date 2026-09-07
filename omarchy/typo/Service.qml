import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var manifest: null
  property var shell: null
  property string omarchyPath: ""

  property bool busy: false
  property bool helperReady: false
  property string statusText: ""
  property string lastError: ""
  property var history: []
  property var requestQueue: []
  property int requestSerial: 0
  property bool intentionalStop: false

  readonly property string sourceDir: manifest && manifest.__sourceDir
    ? String(manifest.__sourceDir) : ""
  readonly property string helperPath: sourceDir ? sourceDir + "/helper.py" : ""

  function nextRequestId() {
    requestSerial += 1
    return "correct-" + requestSerial
  }

  function correctClipboard() {
    if (busy) return
    busy = true
    lastError = ""
    statusText = "Reading clipboard..."
    send({ version: 1, id: nextRequestId(), type: "correct" })
  }

  function copyOutput(index) {
    if (index < 0 || index >= history.length) return
    send({ version: 1, id: "copy-" + Date.now(), type: "copy", text: String(history[index].output || "") })
  }

  function removeHistory(index) {
    if (index < 0 || index >= history.length) return
    send({ version: 1, id: "remove-" + Date.now(), type: "remove", index: index })
  }

  function clearHistory() {
    send({ version: 1, id: "clear-" + Date.now(), type: "clear" })
  }

  function reloadHistory() {
    send({ version: 1, id: "history-" + Date.now(), type: "history" })
  }

  function send(message) {
    ensureHelper()
    if (!helperReady || !helper.running) {
      var pending = requestQueue.slice()
      pending.push(message)
      requestQueue = pending
      return
    }
    helper.write(JSON.stringify(message) + "\n")
  }

  function ensureHelper() {
    if (helper.running || !helperPath) return
    intentionalStop = false
    helper.command = ["python3", helperPath, "--json-lines"]
    helper.running = true
  }

  function flushQueue() {
    if (!helperReady || !helper.running) return
    var pending = requestQueue
    requestQueue = []
    for (var i = 0; i < pending.length; i++)
      helper.write(JSON.stringify(pending[i]) + "\n")
  }

  function notify(title, body) {
    if (!omarchyPath) return
    Quickshell.execDetached([
      omarchyPath + "/bin/omarchy-notification-send",
      "--app-name", "Typo",
      title,
      body
    ])
  }

  function handleMessage(line) {
    var message
    try {
      message = JSON.parse(String(line || ""))
    } catch (_error) {
      lastError = "Typo helper returned malformed data"
      busy = false
      return
    }
    if (!message || message.version !== 1 || !message.type) return

    if (message.type === "ready") {
      helperReady = true
      flushQueue()
      send({ version: 1, id: "history-" + Date.now(), type: "history" })
    } else if (message.type === "status") {
      statusText = String(message.message || "")
    } else if (message.type === "history") {
      history = Array.isArray(message.entries) ? message.entries : []
    } else if (message.type === "result") {
      busy = false
      statusText = "Corrected text copied"
      lastError = ""
      if (Array.isArray(message.entries)) history = message.entries
      notify("Text corrected", "The corrected text is ready to paste")
    } else if (message.type === "copied") {
      statusText = "History result copied"
    } else if (message.type === "error") {
      busy = false
      statusText = ""
      lastError = String(message.message || "Correction failed")
      notify("Correction failed", lastError)
    }
  }

  Process {
    id: helper
    stdinEnabled: true

    stdout: SplitParser {
      onRead: function(line) { root.handleMessage(line) }
    }

    stderr: SplitParser {
      onRead: function(line) {
        var message = String(line || "").trim()
        if (message) root.lastError = message
      }
    }

    onExited: function(exitCode, _exitStatus) {
      root.helperReady = false
      if (root.intentionalStop) return
      root.busy = false
      root.statusText = ""
      root.lastError = "Typo helper stopped unexpectedly (exit " + exitCode + ")"
    }
  }

  Component.onCompleted: ensureHelper()
  Component.onDestruction: {
    if (helper.running) {
      intentionalStop = true
      if (helperReady)
        helper.write(JSON.stringify({ version: 1, id: "shutdown", type: "shutdown" }) + "\n")
      helper.running = false
    }
  }
}
