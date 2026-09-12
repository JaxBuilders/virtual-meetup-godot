import { createHash } from "node:crypto";
import { spawn, spawnSync } from "node:child_process";
import {
  access,
  chmod,
  copyFile,
  mkdir,
  readFile,
  readdir,
  realpath,
  rename,
  rm,
  writeFile,
} from "node:fs/promises";
import { createReadStream, createWriteStream } from "node:fs";
import net from "node:net";
import path from "node:path";
import { Readable } from "node:stream";
import { pipeline } from "node:stream/promises";
import { fileURLToPath } from "node:url";

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const repositoryRoot = path.resolve(scriptDirectory, "..");
const toolsRoot = path.join(repositoryRoot, ".tools");
const developmentRoot = path.join(repositoryRoot, ".dev");
const logRoot = path.join(developmentRoot, "logs");
const runRoot = path.join(developmentRoot, "run");
const statePath = path.join(runRoot, "godot.json");
const stopRequestPath = path.join(runRoot, "stop.request");
const toolchain = JSON.parse(await readFile(path.join(scriptDirectory, "toolchain.json"), "utf8"));
const command = process.argv[2] ?? "help";
const commandArguments = process.argv.slice(3);
const approvedDownloadHosts = new Set([
  "downloads.godotengine.org",
  "github.com",
  "release-assets.githubusercontent.com",
  "objects.githubusercontent.com",
  "github-releases.githubusercontent.com",
  "godot-releases.nbg1.your-objectstorage.com",
]);

function print(message = "") {
  process.stdout.write(`${message}\n`);
}

function warn(message) {
  process.stderr.write(`WARNING: ${message}\n`);
}

function fail(message) {
  throw new Error(message);
}

function normalizeComparable(value) {
  const normalized = path.resolve(value);
  return process.platform === "win32" ? normalized.toLowerCase() : normalized;
}

function assertOwnedPath(target, parent) {
  const relative = path.relative(parent, target);
  if (relative === "" || relative.startsWith("..") || path.isAbsolute(relative)) {
    fail(`Refusing to modify path outside ${parent}: ${target}`);
  }
}

function platformKey() {
  if (process.arch !== "x64") {
    fail(`Unsupported architecture '${process.arch}'. Virtual Meetup tooling supports x64 only.`);
  }
  if (process.platform === "win32") {
    return "windows-x86_64";
  }
  if (process.platform === "linux") {
    return "linux-x86_64";
  }
  fail(`Unsupported platform '${process.platform}'. Virtual Meetup tooling supports Windows and Linux.`);
}

function artifactForHost() {
  const key = platformKey();
  const artifact = toolchain.godot.artifacts[key];
  if (!artifact) {
    fail(`Toolchain manifest has no Godot artifact for '${key}'.`);
  }
  return { key, artifact };
}

function nodeVersionCheck() {
  const major = Number.parseInt(process.versions.node.split(".")[0], 10);
  if (major < toolchain.node.minimumMajor) {
    fail(
      `Node ${toolchain.node.minimumMajor} or newer is required; found ${process.versions.node}. `
        + "Install a supported Node LTS release and retry.",
    );
  }
  if (!toolchain.node.supportedLtsMajors.includes(major)) {
    warn(
      `Node ${process.versions.node} is outside the recommended LTS majors `
        + `${toolchain.node.supportedLtsMajors.join(", ")}; continuing with this installed version.`,
    );
  }
  return process.versions.node;
}

function godotInstallDirectory() {
  return path.join(toolsRoot, "godot", toolchain.godot.version, platformKey());
}

function godotExecutable(kind = "console") {
  const override = String(process.env.GODOT_BIN ?? "").trim();
  if (override) {
    return path.resolve(override);
  }
  const { artifact } = artifactForHost();
  return path.join(godotInstallDirectory(), artifact.executables[kind]);
}

function mcpEntryPath() {
  return path.join(repositoryRoot, "dev", "mcp", ...toolchain.mcp.entry.split("/"));
}

async function pathExists(target) {
  try {
    await access(target);
    return true;
  } catch {
    return false;
  }
}

async function fileSha512(target) {
  const hash = createHash("sha512");
  for await (const chunk of createReadStream(target)) {
    hash.update(chunk);
  }
  return hash.digest("hex");
}

async function fetchApproved(url) {
  let current = new URL(url);
  for (let redirectCount = 0; redirectCount <= 5; redirectCount += 1) {
    if (current.protocol !== "https:" || !approvedDownloadHosts.has(current.hostname)) {
      fail(`Refusing unapproved Godot download URL: ${current.href}`);
    }
    const response = await fetch(current, { redirect: "manual" });
    if (response.status >= 300 && response.status < 400) {
      const location = response.headers.get("location");
      if (!location) {
        fail(`Godot download redirect from ${current.hostname} had no Location header.`);
      }
      current = new URL(location, current);
      continue;
    }
    if (!response.ok || response.body === null) {
      fail(`Godot download failed with HTTP ${response.status} from ${current.hostname}.`);
    }
    return response;
  }
  fail("Godot download exceeded the five-redirect safety limit.");
}

async function downloadGodotArchive(artifact, force) {
  const downloadDirectory = path.join(toolsRoot, "downloads", toolchain.godot.version);
  const archivePath = path.join(downloadDirectory, artifact.archiveName);
  assertOwnedPath(archivePath, toolsRoot);
  await mkdir(downloadDirectory, { recursive: true });

  if (await pathExists(archivePath)) {
    const cachedHash = await fileSha512(archivePath);
    if (!force && cachedHash === artifact.sha512) {
      print(`Using verified cached archive ${path.relative(repositoryRoot, archivePath)}.`);
      return archivePath;
    }
    await rm(archivePath, { force: true });
  }

  const partialPath = `${archivePath}.part`;
  await rm(partialPath, { force: true });
  print(`Downloading Godot ${toolchain.godot.version} for ${platformKey()}...`);
  const response = await fetchApproved(artifact.url);
  await pipeline(Readable.fromWeb(response.body), createWriteStream(partialPath, { flags: "wx" }));
  const downloadedHash = await fileSha512(partialPath);
  if (downloadedHash !== artifact.sha512) {
    await rm(partialPath, { force: true });
    fail(
      `Godot archive checksum mismatch. Expected ${artifact.sha512}, received ${downloadedHash}.`,
    );
  }
  await rename(partialPath, archivePath);
  return archivePath;
}

function commandAvailable(executable, args = ["--version"]) {
  const result = spawnSync(executable, args, { encoding: "utf8", windowsHide: true });
  return !result.error;
}

async function createLogPath(kind) {
  await mkdir(logRoot, { recursive: true });
  const stamp = new Date().toISOString().replaceAll(":", "-").replaceAll(".", "-");
  const logPath = path.join(logRoot, `${kind}-${stamp}.log`);
  const logs = (await readdir(logRoot))
    .filter((name) => name.startsWith(`${kind}-`) && name.endsWith(".log"))
    .sort()
    .reverse();
  for (const staleLog of logs.slice(4)) {
    await rm(path.join(logRoot, staleLog), { force: true });
  }
  return logPath;
}

async function runProcess(executable, args, options = {}) {
  const logPath = await createLogPath(options.logKind ?? "command");
  const logStream = createWriteStream(logPath, { flags: "a" });
  const child = spawn(executable, args, {
    cwd: options.cwd ?? repositoryRoot,
    env: options.env ?? process.env,
    stdio: ["ignore", "pipe", "pipe"],
    windowsHide: options.windowsHide ?? true,
  });
  child.stdout.on("data", (chunk) => {
    process.stdout.write(chunk);
    logStream.write(chunk);
  });
  child.stderr.on("data", (chunk) => {
    process.stderr.write(chunk);
    logStream.write(chunk);
  });
  const result = await new Promise((resolve, reject) => {
    child.once("error", reject);
    child.once("close", (code, signal) => resolve({ code: code ?? 1, signal }));
  });
  await new Promise((resolve) => logStream.end(resolve));
  if (result.code !== 0 && !options.allowFailure) {
    fail(
      `${path.basename(executable)} exited with code ${result.code}`
        + `${result.signal ? ` after ${result.signal}` : ""}. See ${path.relative(repositoryRoot, logPath)}.`,
    );
  }
  return { ...result, logPath };
}

async function extractGodot(archivePath, installDirectory, artifact) {
  assertOwnedPath(installDirectory, toolsRoot);
  await rm(installDirectory, { recursive: true, force: true });
  await mkdir(installDirectory, { recursive: true });

  if (process.platform === "win32") {
    if (!commandAvailable("tar.exe")) {
      fail("Windows tar.exe is required to extract the portable Godot archive.");
    }
    await runProcess("tar.exe", ["-xf", archivePath, "-C", installDirectory], {
      logKind: "bootstrap",
    });
  } else {
    if (!commandAvailable("unzip", ["-v"])) {
      fail("Linux unzip is required to extract the portable Godot archive.");
    }
    await runProcess("unzip", ["-q", "-o", archivePath, "-d", installDirectory], {
      logKind: "bootstrap",
    });
  }

  const normalized = new Set();
  for (const kind of ["editor", "console"]) {
    const member = path.join(installDirectory, artifact.members[kind]);
    const destination = path.join(installDirectory, artifact.executables[kind]);
    if (!(await pathExists(member))) {
      fail(`Godot archive did not contain expected member '${artifact.members[kind]}'.`);
    }
    if (!normalized.has(destination)) {
      if (normalizeComparable(member) !== normalizeComparable(destination)) {
        await copyFile(member, destination);
      }
      if (process.platform !== "win32") {
        await chmod(destination, 0o755);
      }
      normalized.add(destination);
    }
  }

  await writeFile(
    path.join(installDirectory, "installation.json"),
    `${JSON.stringify({
      schemaVersion: 1,
      godotVersion: toolchain.godot.version,
      platform: platformKey(),
      archiveName: artifact.archiveName,
      sha512: artifact.sha512,
      installedAt: new Date().toISOString(),
    }, null, 2)}\n`,
    "utf8",
  );
}

async function installedGodotVersion() {
  const executable = godotExecutable("console");
  if (!(await pathExists(executable))) {
    return null;
  }
  const result = spawnSync(executable, ["--version"], {
    cwd: repositoryRoot,
    encoding: "utf8",
    windowsHide: true,
  });
  if (result.error || result.status !== 0) {
    return null;
  }
  return result.stdout.trim();
}

async function requireGodot() {
  const version = await installedGodotVersion();
  if (version !== toolchain.godot.versionOutput) {
    print(`Preparing pinned Godot ${toolchain.godot.version} for launch...`);
    await installGodot(false);
  }
  return godotExecutable("console");
}

async function installMcp(force) {
  if (!force) {
    try {
      const installedVersion = await verifyMcpInstall();
      print(`Using pinned MCP server ${installedVersion} from dev/mcp/node_modules.`);
      return;
    } catch {
      // A missing, mismatched, or unpatched install is replaced from the lockfile below.
    }
  }
  const npmExecutable = process.platform === "win32"
    ? (process.env.ComSpec ?? "cmd.exe")
    : "npm";
  const npmPrefix = process.platform === "win32" ? ["/d", "/s", "/c", "npm.cmd"] : [];
  if (!commandAvailable(npmExecutable, [...npmPrefix, "--version"])) {
    fail("npm is required to install the pinned local MCP server.");
  }
  await runProcess(
    npmExecutable,
    [...npmPrefix, "ci", "--ignore-scripts", "--no-audit", "--no-fund"],
    { cwd: path.join(repositoryRoot, "dev", "mcp"), logKind: "bootstrap" },
  );
  await runProcess(
    process.execPath,
    [path.join(repositoryRoot, "dev", "mcp", "patch-server.mjs")],
    { logKind: "bootstrap" },
  );
  await verifyMcpInstall();
}

async function verifyMcpInstall() {
  if (!(await pathExists(mcpEntryPath()))) {
    fail("Pinned MCP server is missing. Run `node dev/dev.mjs bootstrap`.");
  }
  const packagePath = path.join(
    repositoryRoot,
    "dev",
    "mcp",
    "node_modules",
    toolchain.mcp.package,
    "package.json",
  );
  const installed = JSON.parse(await readFile(packagePath, "utf8"));
  if (installed.version !== toolchain.mcp.version) {
    fail(`Expected MCP ${toolchain.mcp.version}; found ${installed.version}.`);
  }
  const visualizerSource = await readFile(
    path.join(repositoryRoot, "dev", "mcp", "node_modules", toolchain.mcp.package, "dist", "visualizer-server.js"),
    "utf8",
  );
  if (!visualizerSource.includes("GODOT_MCP_OPEN_BROWSER === '1'")) {
    fail("Pinned MCP no-browser safety patch is missing. Run `node dev/dev.mjs bootstrap`.");
  }
  return installed.version;
}

async function runGodot(args, logKind) {
  const executable = await requireGodot();
  return runProcess(executable, args, { logKind });
}

async function importProject() {
  print("Importing Virtual Meetup with the pinned headless editor...");
  return runGodot(
    ["--headless", "--editor", "--path", repositoryRoot, "--import"],
    "import",
  );
}

async function checkProject() {
  print("Loading first-party Virtual Meetup scripts, scenes, and resources...");
  return runGodot(
    ["--headless", "--path", repositoryRoot, "--script", "res://dev/godot_check.gd"],
    "check",
  );
}

async function bootstrap(force, mcpOnly = false) {
  nodeVersionCheck();
  if (mcpOnly) {
    await installMcp(force);
    return;
  }
  await installMcp(force);
  await installGodot(force);
  await importProject();
  await checkProject();
  await doctor(false);
  print("Bootstrap complete. Start the shared editor with `node dev/dev.mjs start`.");
}

async function installGodot(force) {
  const { artifact } = artifactForHost();
  await mkdir(toolsRoot, { recursive: true });
  await mkdir(developmentRoot, { recursive: true });
  const override = String(process.env.GODOT_BIN ?? "").trim();
  const installDirectory = godotInstallDirectory();
  const currentVersion = await installedGodotVersion();
  if (override && currentVersion !== toolchain.godot.versionOutput) {
    fail(`GODOT_BIN must report ${toolchain.godot.versionOutput}; found ${currentVersion ?? "nothing"}.`);
  } else if (override) {
    print(`Using Godot from GODOT_BIN (${currentVersion}).`);
  } else if (force || currentVersion !== toolchain.godot.versionOutput) {
    const archivePath = await downloadGodotArchive(artifact, force);
    await extractGodot(archivePath, installDirectory, artifact);
  } else {
    print(`Using verified Godot ${currentVersion} from ${path.relative(repositoryRoot, installDirectory)}.`);
  }

  const installedVersion = await installedGodotVersion();
  if (installedVersion !== toolchain.godot.versionOutput) {
    fail(`Installed Godot reported '${installedVersion ?? "no version"}'.`);
  }
}

async function isPortOpen(port) {
  return new Promise((resolve) => {
    const socket = net.createConnection({ host: "127.0.0.1", port });
    const finish = (value) => {
      socket.destroy();
      resolve(value);
    };
    socket.setTimeout(350);
    socket.once("connect", () => finish(true));
    socket.once("timeout", () => finish(false));
    socket.once("error", () => finish(false));
  });
}

function parseJsonOutput(output) {
  const trimmed = output.trim();
  return trimmed ? JSON.parse(trimmed) : null;
}

async function inspectProcess(pid) {
  if (!Number.isSafeInteger(pid) || pid <= 0) {
    return null;
  }
  try {
    process.kill(pid, 0);
  } catch {
    return null;
  }

  if (process.platform === "linux") {
    try {
      const executable = await realpath(`/proc/${pid}/exe`);
      const rawCommand = await readFile(`/proc/${pid}/cmdline`, "utf8");
      return { pid, executable, commandLine: rawCommand.replaceAll("\0", " ").trim() };
    } catch {
      return null;
    }
  }

  const query = [
    `$p = Get-CimInstance Win32_Process -Filter \"ProcessId = ${pid}\";`,
    "if ($null -ne $p) {",
    "@{ pid = [int]$p.ProcessId; executable = [string]$p.ExecutablePath; commandLine = [string]$p.CommandLine }",
    "| ConvertTo-Json -Compress",
    "}",
  ].join(" ");
  const result = spawnSync(
    "powershell.exe",
    ["-NoProfile", "-NonInteractive", "-Command", query],
    { encoding: "utf8", windowsHide: true },
  );
  if (result.error || result.status !== 0 || !result.stdout.trim()) {
    return null;
  }
  return parseJsonOutput(result.stdout);
}

async function readState() {
  try {
    return JSON.parse(await readFile(statePath, "utf8"));
  } catch {
    return null;
  }
}

async function healthyOwnedState() {
  const state = await readState();
  if (!state) {
    return null;
  }
  const expectedExecutable = state.mode === "editor"
    ? godotExecutable("editor")
    : godotExecutable("console");
  if (
    state.schemaVersion !== 1
    || normalizeComparable(state.projectPath) !== normalizeComparable(repositoryRoot)
    || normalizeComparable(state.executable) !== normalizeComparable(expectedExecutable)
  ) {
    return null;
  }
  const processInfo = await inspectProcess(Number(state.pid));
  if (!processInfo) {
    return null;
  }
  if (normalizeComparable(processInfo.executable) !== normalizeComparable(state.executable)) {
    return null;
  }
  if (!processInfo.commandLine.includes(repositoryRoot)) {
    return null;
  }
  return { state, processInfo };
}

async function removeStaleState() {
  const state = await readState();
  if (state && !(await healthyOwnedState())) {
    await rm(statePath, { force: true });
    await rm(stopRequestPath, { force: true });
  }
}

async function inspectListeningProcess(port) {
  if (!(await isPortOpen(port))) {
    return null;
  }
  if (process.platform === "win32") {
    const query = [
      `$c = Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort ${port} -State Listen`,
      "| Select-Object -First 1;",
      "if ($null -ne $c) {",
      "$p = Get-CimInstance Win32_Process -Filter (\"ProcessId = \" + $c.OwningProcess);",
      "@{ pid = [int]$p.ProcessId; executable = [string]$p.ExecutablePath; commandLine = [string]$p.CommandLine }",
      "| ConvertTo-Json -Compress",
      "}",
    ].join(" ");
    const result = spawnSync(
      "powershell.exe",
      ["-NoProfile", "-NonInteractive", "-Command", query],
      { encoding: "utf8", windowsHide: true },
    );
    if (!result.error && result.status === 0 && result.stdout.trim()) {
      return parseJsonOutput(result.stdout);
    }
    return { pid: null, executable: "", commandLine: "" };
  }

  if (commandAvailable("lsof", ["-v"])) {
    const result = spawnSync(
      "lsof",
      ["-nP", `-iTCP:${port}`, "-sTCP:LISTEN", "-Fpfc"],
      { encoding: "utf8" },
    );
    const pid = Number.parseInt(result.stdout.match(/^p(\d+)$/m)?.[1] ?? "", 10);
    return Number.isSafeInteger(pid) ? await inspectProcess(pid) : null;
  }
  return { pid: null, executable: "", commandLine: "" };
}

function isExpectedMcpProcess(processInfo) {
  const commandLine = String(processInfo?.commandLine ?? "").toLowerCase();
  return commandLine.includes("godot-mcp-server") || commandLine.includes("dev/mcp/launch-server.mjs");
}

async function assertBridgePortSafe() {
  if (!(await isPortOpen(toolchain.mcp.bridgePort))) {
    return;
  }
  const owner = await inspectListeningProcess(toolchain.mcp.bridgePort);
  if (!owner || !isExpectedMcpProcess(owner)) {
    const identity = owner?.pid ? `PID ${owner.pid}` : "an unidentified process";
    fail(
      `Port ${toolchain.mcp.bridgePort} is occupied by ${identity}, not Virtual Meetup's MCP server. `
        + "The launcher will not terminate it.",
    );
  }
}

async function writeState(child, executable, mode, logPath) {
  await mkdir(runRoot, { recursive: true });
  await writeFile(
    statePath,
    `${JSON.stringify({
      schemaVersion: 1,
      pid: child.pid,
      projectPath: repositoryRoot,
      executable,
      mode,
      startedAt: new Date().toISOString(),
      godotVersion: toolchain.godot.version,
      mcpVersion: toolchain.mcp.version,
      bridgePort: toolchain.mcp.bridgePort,
      visualizerPort: toolchain.mcp.visualizerPort,
      logPath,
    }, null, 2)}\n`,
    "utf8",
  );
}

async function runPersistentEditor(mode) {
  nodeVersionCheck();
  await requireGodot();
  // The editor uses the bundled plugin; the separate server launcher owns npm setup.
  await removeStaleState();
  const current = await healthyOwnedState();
  if (current) {
    print(`Virtual Meetup ${current.state.mode} editor is already running as PID ${current.state.pid}.`);
    return;
  }
  if (mode === "mcp-headless") {
    await assertBridgePortSafe();
  }

  const executable = mode === "editor" ? godotExecutable("editor") : godotExecutable("console");
  const args = mode === "editor"
    ? ["--editor", "--path", repositoryRoot]
    : ["--headless", "--editor", "--path", repositoryRoot];
  const logPath = await createLogPath(mode === "editor" ? "editor" : "mcp-headless");
  const logStream = createWriteStream(logPath, { flags: "a" });
  const child = spawn(executable, args, {
    cwd: repositoryRoot,
    env: process.env,
    stdio: ["ignore", "pipe", "pipe"],
    windowsHide: mode !== "editor",
  });
  child.stdout.on("data", (chunk) => {
    process.stdout.write(chunk);
    logStream.write(chunk);
  });
  child.stderr.on("data", (chunk) => {
    process.stderr.write(chunk);
    logStream.write(chunk);
  });
  await new Promise((resolve, reject) => {
    child.once("spawn", resolve);
    child.once("error", reject);
  });
  await writeState(child, executable, mode, path.relative(repositoryRoot, logPath));
  await rm(stopRequestPath, { force: true });
  print(`Started Virtual Meetup ${mode} editor as PID ${child.pid}. Press Ctrl+C to stop it.`);

  let stopping = false;
  const requestStop = () => {
    if (stopping || child.exitCode !== null) {
      return;
    }
    stopping = true;
    child.kill("SIGTERM");
  };
  process.once("SIGINT", requestStop);
  process.once("SIGTERM", requestStop);
  const stopWatcher = setInterval(async () => {
    if (await pathExists(stopRequestPath)) {
      requestStop();
    }
  }, 500);

  const result = await new Promise((resolve, reject) => {
    child.once("error", reject);
    child.once("close", (code, signal) => resolve({ code: code ?? 1, signal }));
  });
  clearInterval(stopWatcher);
  logStream.end();
  const finalState = await readState();
  if (Number(finalState?.pid) === child.pid) {
    await rm(statePath, { force: true });
    await rm(stopRequestPath, { force: true });
  }
  if (result.code !== 0 && !stopping) {
    fail(`Godot editor exited with code ${result.code}. See ${path.relative(repositoryRoot, logPath)}.`);
  }
}

async function runHeadlessGame(args) {
  let scene = "res://scenes/app/app.tscn";
  let frames = 120;
  for (let index = 0; index < args.length; index += 1) {
    if (args[index] === "--frames") {
      frames = Number.parseInt(args[index + 1] ?? "", 10);
      index += 1;
    } else if (!args[index].startsWith("--")) {
      scene = args[index];
    }
  }
  if (!scene.startsWith("res://") || scene.includes("..")) {
    fail("game-headless scene must be a safe res:// path.");
  }
  if (!Number.isSafeInteger(frames) || frames < 1 || frames > 3600) {
    fail("--frames must be an integer from 1 through 3600.");
  }
  const localScene = path.join(repositoryRoot, ...scene.slice("res://".length).split("/"));
  if (!(await pathExists(localScene))) {
    fail(`Scene does not exist: ${scene}`);
  }
  await runGodot(
    ["--headless", "--path", repositoryRoot, "--quit-after", String(frames), scene],
    "runtime",
  );
}

async function reportStatus() {
  await removeStaleState();
  const owned = await healthyOwnedState();
  print(`Repository: ${repositoryRoot}`);
  print(`Node: ${process.versions.node}`);
  print(`Godot: ${(await installedGodotVersion()) ?? "not installed"}`);
  try {
    print(`MCP server: ${await verifyMcpInstall()}`);
  } catch {
    print("MCP server: not installed");
  }
  print(
    `Owned editor: ${owned ? `${owned.state.mode} PID ${owned.state.pid}` : "not running"}`,
  );
  print(
    `Bridge ${toolchain.mcp.bridgePort}: ${(await isPortOpen(toolchain.mcp.bridgePort)) ? "listening" : "closed"}`,
  );
  print(
    `Visualizer ${toolchain.mcp.visualizerPort}: ${(await isPortOpen(toolchain.mcp.visualizerPort)) ? "listening" : "closed"}`,
  );
  print(`Logs: ${path.relative(repositoryRoot, logRoot)}`);
}

async function doctor(requireLiveMcp) {
  const failures = [];
  const check = async (label, operation) => {
    try {
      const detail = await operation();
      print(`[ok] ${label}${detail ? `: ${detail}` : ""}`);
    } catch (error) {
      failures.push(`${label}: ${error.message}`);
      print(`[fail] ${label}: ${error.message}`);
    }
  };

  await check("Node LTS", async () => nodeVersionCheck());
  await check("Host platform", async () => platformKey());
  await check("Pinned Godot", async () => {
    const version = await installedGodotVersion();
    if (version !== toolchain.godot.versionOutput) {
      fail(`expected ${toolchain.godot.versionOutput}, found ${version ?? "nothing"}`);
    }
    return version;
  });
  await check("Pinned MCP server", async () => verifyMcpInstall());
  await check("Project import", async () => {
    const cachePath = path.join(repositoryRoot, ".godot", "editor", "filesystem_cache10");
    if (!(await pathExists(cachePath))) {
      fail("import cache is missing; run `node dev/dev.mjs import`");
    }
    return "Godot 4 import cache present";
  });
  await check("MCP plugin pair", async () => {
    const plugin = await readFile(path.join(repositoryRoot, "addons", "godot_mcp", "plugin.cfg"), "utf8");
    if (!plugin.includes(`version=\"${toolchain.mcp.version}\"`)) {
      fail(`plugin does not declare version ${toolchain.mcp.version}`);
    }
    return toolchain.mcp.version;
  });
  await check("MCP plugin enabled", async () => {
    const project = await readFile(path.join(repositoryRoot, "project.godot"), "utf8");
    if (!project.includes("res://addons/godot_mcp/plugin.cfg")) {
      fail("plugin is not enabled in project.godot");
    }
    return "yes";
  });
  await check("Native extensions", async () => {
    const platformFiles = process.platform === "win32"
      ? [
          "addons/fusion/bin/libfusion.windows.editor.x86_64.release.dll",
        ]
      : [
          "addons/fusion/bin/libfusion.linux.editor.x86_64.release.so",
        ];
    for (const relative of platformFiles) {
      if (!(await pathExists(path.join(repositoryRoot, ...relative.split("/"))))) {
        fail(`missing ${relative}`);
      }
    }
    const extensionRegistry = await readFile(
      path.join(repositoryRoot, ".godot", "extension_list.cfg"),
      "utf8",
    );
    for (const extension of ["fusion/fusion.gdextension"]) {
      if (!extensionRegistry.includes(extension)) {
        fail(`Godot did not register ${extension}`);
      }
    }
    return `${platformFiles.length} host binaries registered`;
  });
  await check("Owned editor state", async () => {
    await removeStaleState();
    const owned = await healthyOwnedState();
    return owned ? `${owned.state.mode} PID ${owned.state.pid}` : "not running (optional)";
  });
  await check(`Bridge port ${toolchain.mcp.bridgePort}`, async () => {
    const open = await isPortOpen(toolchain.mcp.bridgePort);
    if (requireLiveMcp && !open) {
      fail("not listening; open Codex with the project MCP config first");
    }
    if (!open) {
      return "closed (normal before Codex starts the server)";
    }
    const owner = await inspectListeningProcess(toolchain.mcp.bridgePort);
    if (!owner || !isExpectedMcpProcess(owner)) {
      fail(`occupied by ${owner?.pid ? `PID ${owner.pid}` : "an unidentified process"}`);
    }
    return owner.pid ? `Virtual Meetup MCP PID ${owner.pid}` : "listening";
  });
  await check(`Visualizer port ${toolchain.mcp.visualizerPort}`, async () => {
    if (!(await isPortOpen(toolchain.mcp.visualizerPort))) {
      return "closed until map_project is requested";
    }
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 1000);
    try {
      const response = await fetch(`http://127.0.0.1:${toolchain.mcp.visualizerPort}/`, {
        signal: controller.signal,
      });
      if (!response.ok) {
        fail(`HTTP ${response.status}`);
      }
      return `HTTP ${response.status}`;
    } finally {
      clearTimeout(timeout);
    }
  });

  if (failures.length > 0) {
    fail(`Doctor found ${failures.length} problem(s).`);
  }
  return true;
}

async function stopOwnedEditor() {
  await removeStaleState();
  const owned = await healthyOwnedState();
  if (!owned) {
    print("No owned Virtual Meetup editor process is running.");
    return;
  }
  await mkdir(runRoot, { recursive: true });
  await writeFile(stopRequestPath, `${new Date().toISOString()}\n`, "utf8");
  print(`Requested shutdown of owned Virtual Meetup editor PID ${owned.state.pid}.`);
  const deadline = Date.now() + 5000;
  while (Date.now() < deadline) {
    if (!(await inspectProcess(owned.state.pid))) {
      await rm(statePath, { force: true });
      await rm(stopRequestPath, { force: true });
      print("Virtual Meetup editor stopped.");
      return;
    }
    await new Promise((resolve) => setTimeout(resolve, 200));
  }
  warn("The owned editor did not stop within five seconds; it was not force-terminated.");
}

async function mapProject(args) {
  nodeVersionCheck();
  await verifyMcpInstall();
  await runProcess(
    process.execPath,
    [path.join(scriptDirectory, "map-project.mjs"), ...args],
    { logKind: "mcp" },
  );
}

async function launchBlender(args) {
  const authoring = args.includes("--authoring");
  args = args.filter((arg) => arg !== "--authoring");
  const override = String(process.env.BLENDER_BIN ?? "").trim();
  const executable = override || "blender";
  const probe = spawnSync(executable, ["--version"], { encoding: "utf8", windowsHide: true });
  if (probe.error || probe.status !== 0 || !probe.stdout.startsWith("Blender ")) {
    fail("Blender could not be started. Install Blender and put it on PATH, or set BLENDER_BIN to its executable (without arguments).");
  }
  print(probe.stdout.split(/\r?\n/)[0]);
  if (args.includes("--check")) return;
  if (args.length > 1 || (args.length && !args[0].toLowerCase().endsWith(".blend"))) {
    fail("Usage: node dev/dev.mjs blender [file.blend | --check]");
  }
  const files = args.length ? [path.resolve(repositoryRoot, args[0])] : [];
  if (files.length && !(await pathExists(files[0]))) fail("The selected .blend file does not exist.");
  await new Promise((resolve, reject) => {
    const launchArgs = authoring ? [...files, "--python", path.join(repositoryRoot, "dev", "blender_startup.py")] : files;
    const child = spawn(executable, launchArgs, {
      cwd: repositoryRoot,
      env: { ...process.env, DISABLE_TELEMETRY: "true" },
      stdio: "inherit",
      windowsHide: false,
    });
    child.once("error", reject);
    child.once("close", (code, signal) => {
      if (code === 0) resolve();
      else reject(new Error(`Blender exited with ${signal ?? code}.`));
    });
  });
}

function usage() {
  print("Virtual Meetup repo-local Godot development harness");
  print("");
  print("Usage: node dev/dev.mjs <command> [options]");
  print("");
  print("Commands:");
  print("  bootstrap [--force]       Install pinned tools, import, check, and diagnose");
  print("    --mcp-only              Install/repair only the pinned MCP dependencies");
  print("  doctor [--mcp]            Diagnose local tools and optional live MCP state");
  print("  map-project [root]        Serve the MCP project map; add --open for a browser");
  print("  start                     Run the shared headless MCP editor");
  print("  editor                    Run the visible pinned editor");
  print("  blender [file.blend]       Open Blender; --check verifies discovery only");
  print("  import                    Import project assets headlessly and exit");
  print("  check                     Load first-party scripts/scenes/resources and exit");
  print("  game-headless [scene]     Run a bounded headless scene smoke test");
  print("  status                    Report local versions, process state, ports, and logs");
  print("  stop                      Request shutdown of this worktree's owned editor");
}

try {
  switch (command) {
    case "bootstrap":
      await bootstrap(commandArguments.includes("--force"), commandArguments.includes("--mcp-only"));
      break;
    case "doctor":
      await doctor(commandArguments.includes("--mcp"));
      break;
    case "map-project":
      await mapProject(commandArguments);
      break;
    case "start":
      await runPersistentEditor("mcp-headless");
      break;
    case "editor":
      await runPersistentEditor("editor");
      break;
    case "blender":
      await launchBlender(commandArguments);
      break;
    case "import":
      nodeVersionCheck();
      await importProject();
      break;
    case "check":
      nodeVersionCheck();
      await checkProject();
      break;
    case "game-headless":
      nodeVersionCheck();
      await runHeadlessGame(commandArguments);
      break;
    case "status":
      await reportStatus();
      break;
    case "stop":
      await stopOwnedEditor();
      break;
    case "help":
    case "--help":
    case "-h":
      usage();
      break;
    default:
      usage();
      fail(`Unknown command '${command}'.`);
  }
} catch (error) {
  process.stderr.write(`ERROR: ${error.message}\n`);
  process.exitCode = 1;
}
