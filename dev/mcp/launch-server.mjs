import { createWriteStream, existsSync, mkdirSync, readFileSync, readdirSync, rmSync } from "node:fs";
import { spawn } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const repositoryRoot = path.resolve(scriptDirectory, "..", "..");
const toolchain = JSON.parse(readFileSync(path.join(repositoryRoot, "dev", "toolchain.json"), "utf8"));
const serverEntry = path.join(scriptDirectory, ...toolchain.mcp.entry.split("/"));
const installedManifest = path.join(scriptDirectory, "node_modules", toolchain.mcp.package, "package.json");

if (!existsSync(serverEntry) || !existsSync(installedManifest)) {
  process.stderr.write(
    "Virtual Meetup Godot MCP is not installed. Run `node dev/dev.mjs bootstrap`, then restart Codex.\n",
  );
  process.exit(1);
}

const installedPackage = JSON.parse(readFileSync(installedManifest, "utf8"));
if (installedPackage.version !== toolchain.mcp.version) {
  process.stderr.write(
    `Virtual Meetup requires ${toolchain.mcp.package}@${toolchain.mcp.version}, but ${installedPackage.version} is installed. `
      + "Run `node dev/dev.mjs bootstrap --force`, then restart Codex.\n",
  );
  process.exit(1);
}

const logDirectory = path.join(repositoryRoot, ".dev", "logs");
mkdirSync(logDirectory, { recursive: true });
const stamp = new Date().toISOString().replaceAll(":", "-").replaceAll(".", "-");
const logPath = path.join(logDirectory, `mcp-${stamp}.log`);
const logStream = createWriteStream(logPath, { flags: "a" });

const priorLogs = readdirSync(logDirectory)
  .filter((name) => name.startsWith("mcp-") && name.endsWith(".log"))
  .sort()
  .reverse();
for (const staleLog of priorLogs.slice(5)) {
  rmSync(path.join(logDirectory, staleLog), { force: true });
}

const child = spawn(process.execPath, [serverEntry], {
  cwd: repositoryRoot,
  env: { ...process.env, GODOT_MCP_OPEN_BROWSER: "0" },
  stdio: ["inherit", "inherit", "pipe"],
  windowsHide: true,
});

child.stderr.on("data", (chunk) => {
  process.stderr.write(chunk);
  logStream.write(chunk);
});

let stopping = false;
function forwardSignal(signal) {
  if (stopping || child.exitCode !== null) {
    return;
  }
  stopping = true;
  child.kill(process.platform === "win32" ? "SIGTERM" : signal);
}

process.once("SIGINT", () => forwardSignal("SIGINT"));
process.once("SIGTERM", () => forwardSignal("SIGTERM"));
if (process.platform !== "win32") {
  process.once("SIGHUP", () => forwardSignal("SIGHUP"));
}

child.once("error", (error) => {
  logStream.end();
  process.stderr.write(`Could not start Virtual Meetup Godot MCP: ${error.message}\n`);
  process.exitCode = 1;
});

child.once("close", (code, signal) => {
  logStream.end();
  if (signal) {
    process.stderr.write(`Virtual Meetup Godot MCP stopped by ${signal}.\n`);
  }
  process.exitCode = code ?? (signal ? 1 : 0);
});
