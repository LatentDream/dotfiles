/**
 * Unity Helper Extension
 *
 * Built specifically for Guillaume's Unity turn-based strategy game project.
 *
 * Features:
 * 1. Auto-injects PROJECT_CONTEXT.md into the system prompt every session
 * 2. Guards against dangerous operations on Unity-critical files (.meta, ProjectSettings, Library)
 * 3. `unity_run_tests` tool — lets the LLM trigger Unity Test Runner from the CLI
 * 4. `/unity-status` command — shows a summary of the project structure
 * 5. Status bar showing last test run result
 */

import * as fs from "node:fs";
import * as path from "node:path";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { StringEnum } from "@mariozechner/pi-ai";

// ─── Types ───────────────────────────────────────────────────────────────────

interface TestResult {
  suite: string;
  passed: number;
  failed: number;
  skipped: number;
  timestamp: number;
  error?: string;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

function readProjectContext(cwd: string): string | null {
  const contextPath = path.join(cwd, "Assets", "PROJECT_CONTEXT.md");
  if (fs.existsSync(contextPath)) {
    return fs.readFileSync(contextPath, "utf-8");
  }
  return null;
}

function isUnityProject(cwd: string): boolean {
  return (
    fs.existsSync(path.join(cwd, "Assets")) &&
    fs.existsSync(path.join(cwd, "ProjectSettings"))
  );
}

function parseNUnitXml(xml: string): { passed: number; failed: number; skipped: number } {
  const passed = parseInt(xml.match(/passed="(\d+)"/)?.[1] ?? "0", 10);
  const failed = parseInt(xml.match(/failed="(\d+)"/)?.[1] ?? "0", 10);
  const skipped = parseInt(xml.match(/(skipped|inconclusive)="(\d+)"/)?.[2] ?? "0", 10);
  return { passed, failed, skipped };
}

// ─── Extension ───────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  let lastTestResult: TestResult | null = null;
  let projectCwd = "";

  // ── 1. Session start: detect project & set status ──────────────────────────

  pi.on("session_start", async (_event, ctx) => {
    projectCwd = ctx.cwd;

    if (!isUnityProject(projectCwd)) return;

    const theme = ctx.ui.theme;
    ctx.ui.setStatus(
      "unity",
      theme.fg("accent", "🎮") + theme.fg("dim", " Unity project detected")
    );

    ctx.ui.notify("Unity Helper loaded — PROJECT_CONTEXT.md will be injected into prompts.", "info");
  });

  // ── 2. Inject PROJECT_CONTEXT.md into every prompt ────────────────────────

  pi.on("before_agent_start", async (event, ctx) => {
    if (!isUnityProject(projectCwd)) return;

    const context = readProjectContext(projectCwd);
    if (!context) return;

    return {
      systemPrompt:
        event.systemPrompt +
        `

## Unity Project Context

The following is the project's living architecture document. Treat it as ground truth for conventions, naming, and design decisions:

\`\`\`markdown
${context}
\`\`\`

Always follow the conventions described above (namespaces, interface-first design, backend abstraction, etc.).
`,
    };
  });

  // ── 3. Guard dangerous Unity file operations ───────────────────────────────

  // Patterns that should require confirmation in a Unity project
  const protectedPatterns: { pattern: RegExp; reason: string }[] = [
    {
      pattern: /\.meta\b/,
      reason:
        ".meta files are Unity asset database references. Deleting or modifying them orphans assets.",
    },
    {
      pattern: /\bLibrary\b/,
      reason:
        "The Library/ folder is Unity's generated cache. Deleting it forces a full reimport (slow but safe). Editing files inside it manually can corrupt the project.",
    },
    {
      pattern: /\bProjectSettings\b.*\.(asset|txt|json)/,
      reason:
        "ProjectSettings files configure Unity's build, physics, input, and rendering. Wrong edits can break the build.",
    },
    {
      pattern: /\bPackages\/manifest\.json\b/,
      reason:
        "Packages/manifest.json controls which Unity packages are installed. Edits affect the entire package graph.",
    },
  ];

  pi.on("tool_call", async (event, ctx) => {
    if (!isUnityProject(projectCwd)) return;

    const toolName = event.toolName;
    if (!["bash", "write", "edit"].includes(toolName)) return;

    // Gather the paths / command involved
    let targets: string[] = [];
    if (toolName === "bash") {
      targets = [event.input.command as string];
    } else if (toolName === "write" || toolName === "edit") {
      targets = [event.input.path as string];
    }

    for (const target of targets) {
      for (const { pattern, reason } of protectedPatterns) {
        if (pattern.test(target)) {
          if (!ctx.hasUI) {
            return {
              block: true,
              reason: `[Unity Guard] Protected path matched (${pattern}): ${reason}`,
            };
          }

          const choice = await ctx.ui.select(
            `⚠️  Unity Guard — Protected file detected\n\n` +
              `  Tool:   ${toolName}\n` +
              `  Target: ${target}\n\n` +
              `  Reason: ${reason}\n\n` +
              `  Proceed?`,
            ["Yes, allow it", "No, block it"]
          );

          if (choice !== "Yes, allow it") {
            return { block: true, reason: `[Unity Guard] Blocked by user. ${reason}` };
          }

          break; // One confirmation per tool call is enough
        }
      }
    }
  });

  // ── 4. unity_run_tests tool ────────────────────────────────────────────────

  pi.registerTool({
    name: "unity_run_tests",
    label: "Run Unity Tests",
    description:
      "Run the Unity Test Runner in batch mode for EditMode or PlayMode tests and return the results. " +
      "Use this after making changes to verify nothing is broken. " +
      "Requires the UNITY_PATH environment variable to point to the Unity executable, " +
      "e.g. /Applications/Unity/Hub/Editor/<version>/Unity.app/Contents/MacOS/Unity",
    promptSnippet: "Run Unity EditMode or PlayMode tests and get pass/fail counts",
    promptGuidelines: [
      "Run unity_run_tests after any change to C# game logic, backend, or test files.",
      "Prefer 'editmode' for unit tests (fast). Use 'playmode' for integration/UI tests.",
      "If tests fail, read the output carefully — Unity test names follow the pattern Assembly.Class.Method.",
    ],
    parameters: Type.Object({
      suite: StringEnum(["editmode", "playmode", "all"] as const, {
        description: "Which test suite to run: 'editmode', 'playmode', or 'all' (both).",
      }),
      filter: Type.Optional(
        Type.String({
          description:
            "Optional test name filter (substring match). E.g. 'FakeBackend' runs only tests whose full name contains that string.",
        })
      ),
    }),

    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const unityPath = process.env["UNITY_PATH"];
      if (!unityPath) {
        throw new Error(
          "UNITY_PATH environment variable is not set. " +
            "Set it to the Unity executable path, e.g.:\n" +
            "  export UNITY_PATH=/Applications/Unity/Hub/Editor/6000.1.0f1/Unity.app/Contents/MacOS/Unity"
        );
      }

      if (!fs.existsSync(unityPath)) {
        throw new Error(`Unity executable not found at: ${unityPath}`);
      }

      const suites = params.suite === "all" ? ["editmode", "playmode"] : [params.suite];
      const results: TestResult[] = [];

      for (const suite of suites) {
        onUpdate?.({
          content: [{ type: "text", text: `Running ${suite} tests…` }],
          details: { suite, status: "running" },
        });

        const resultFile = path.join(projectCwd, `Temp/test-results-${suite}.xml`);

        const args = [
          "-batchmode",
          "-nographics",
          "-projectPath",
          projectCwd,
          "-runTests",
          `-testPlatform`,
          suite,
          "-testResults",
          resultFile,
          "-logFile",
          path.join(projectCwd, `Temp/unity-test-${suite}.log`),
        ];

        if (params.filter) {
          args.push("-testFilter", params.filter);
        }

        const { code, stdout, stderr } = await pi.exec(unityPath, args, {
          signal,
          timeout: 300_000, // 5 minutes
        });

        let parsed = { passed: 0, failed: 0, skipped: 0 };
        let error: string | undefined;

        if (fs.existsSync(resultFile)) {
          const xml = fs.readFileSync(resultFile, "utf-8");
          parsed = parseNUnitXml(xml);
        } else {
          error = `Unity exited with code ${code}. No result XML found. stderr: ${stderr.slice(0, 500)}`;
        }

        const result: TestResult = {
          suite,
          ...parsed,
          timestamp: Date.now(),
          error,
        };

        results.push(result);
        lastTestResult = result;

        // Update status bar
        if (ctx.hasUI) {
          const theme = ctx.ui.theme;
          const icon = parsed.failed > 0 ? theme.fg("error", "✗") : theme.fg("success", "✓");
          ctx.ui.setStatus(
            "unity",
            icon + theme.fg("dim", ` ${suite}: ${parsed.passed}✓ ${parsed.failed}✗`)
          );
        }
      }

      // Build summary
      const totalPassed = results.reduce((s, r) => s + r.passed, 0);
      const totalFailed = results.reduce((s, r) => s + r.failed, 0);
      const totalSkipped = results.reduce((s, r) => s + r.skipped, 0);

      const lines: string[] = [];
      lines.push(`## Unity Test Results`);
      lines.push("");

      for (const r of results) {
        lines.push(`### ${r.suite.charAt(0).toUpperCase() + r.suite.slice(1)}`);
        lines.push(`- Passed:  ${r.passed}`);
        lines.push(`- Failed:  ${r.failed}`);
        lines.push(`- Skipped: ${r.skipped}`);
        if (r.error) {
          lines.push(`- Error: ${r.error}`);
        }
        lines.push("");
      }

      if (results.length > 1) {
        lines.push(`### Total`);
        lines.push(`- Passed:  ${totalPassed}`);
        lines.push(`- Failed:  ${totalFailed}`);
        lines.push(`- Skipped: ${totalSkipped}`);
      }

      const overallOk = totalFailed === 0 && results.every((r) => !r.error);
      lines.push(overallOk ? "✅ All tests passed." : "❌ Some tests failed.");

      return {
        content: [{ type: "text", text: lines.join("\n") }],
        details: { results, totalPassed, totalFailed, totalSkipped },
      };
    },
  });

  // ── 5. /unity-status command ───────────────────────────────────────────────

  pi.registerCommand("unity-status", {
    description: "Show a summary of the Unity project structure and last test run",
    handler: async (_args, ctx) => {
      if (!isUnityProject(projectCwd)) {
        ctx.ui.notify("Not a Unity project directory.", "warning");
        return;
      }

      const theme = ctx.ui.theme;

      const assetsDir = path.join(projectCwd, "Assets");
      const csFiles = fs
        .readdirSync(assetsDir, { withFileTypes: true, recursive: true } as any)
        .filter((e: fs.Dirent) => e.isFile() && (e.name as string).endsWith(".cs"))
        .length;

      const lines: string[] = [
        theme.bold("🎮 Unity Project Status"),
        "",
        theme.fg("dim", `Path: ${projectCwd}`),
        theme.fg("dim", `C# files in Assets/: ${csFiles}`),
        "",
      ];

      if (lastTestResult) {
        const age = Math.round((Date.now() - lastTestResult.timestamp) / 1000);
        const icon =
          lastTestResult.failed > 0
            ? theme.fg("error", "✗")
            : theme.fg("success", "✓");

        lines.push(theme.bold("Last Test Run:"));
        lines.push(
          `  ${icon} ${lastTestResult.suite} — ` +
            `${theme.fg("success", String(lastTestResult.passed))} passed, ` +
            `${theme.fg("error", String(lastTestResult.failed))} failed ` +
            theme.fg("dim", `(${age}s ago)`)
        );
      } else {
        lines.push(theme.fg("dim", "No tests run yet this session. Use the unity_run_tests tool."));
      }

      const context = readProjectContext(projectCwd);
      if (context) {
        lines.push("");
        lines.push(theme.fg("dim", "✔ PROJECT_CONTEXT.md found and will be injected into prompts."));
      }

      ctx.ui.notify(lines.join("\n"), "info");
    },
  });
}
