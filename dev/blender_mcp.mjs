import { spawn } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const executable = path.join(root, ".tools", "blender-mcp-1.9.1", process.platform === "win32" ? "Scripts/blender-mcp.exe" : "bin/blender-mcp");
const child = spawn(executable, [], {
  cwd: root,
  env: { ...process.env, DISABLE_TELEMETRY: "true", BLENDER_HOST: "127.0.0.1", BLENDER_PORT: "9876" },
  stdio: "inherit",
});
child.on("error", () => {
  process.stderr.write("Blender MCP is missing. Follow docs/BLENDER_SETUP.md.\n");
  process.exitCode = 1;
});
child.on("exit", (code) => { process.exitCode = code ?? 1; });
