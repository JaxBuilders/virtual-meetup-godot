import { spawn } from "node:child_process";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const repositoryRoot = path.resolve(scriptDirectory, "..");
const toolchain = JSON.parse(await readFile(path.join(scriptDirectory, "toolchain.json"), "utf8"));
const args = process.argv.slice(2);
const root = args.find((argument) => !argument.startsWith("--")) ?? "res://";
const waitForWorkspace = args.includes("--wait-for-workspace");
const stayAlive = args.includes("--stay-alive");

function fail(message) {
  throw new Error(message);
}

function comparable(value) {
  const normalized = path.resolve(value);
  return process.platform === "win32" ? normalized.toLowerCase() : normalized;
}

function delay(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

function parseToolText(result, toolName) {
  const textContent = result?.content?.find((entry) => entry.type === "text")?.text;
  if (typeof textContent !== "string") {
    fail(`MCP tool ${toolName} returned no text result.`);
  }
  let parsed;
  try {
    parsed = JSON.parse(textContent);
  } catch {
    fail(`MCP tool ${toolName} returned invalid JSON.`);
  }
  if (result.isError || parsed.error) {
    fail(`MCP tool ${toolName} failed: ${parsed.error ?? "unknown error"}`);
  }
  return parsed;
}

async function requestJson(url, options = {}, timeoutMs = 65000) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(url, { ...options, signal: controller.signal });
    if (!response.ok) {
      fail(`${url} returned HTTP ${response.status}.`);
    }
    return response;
  } catch (error) {
    if (error.name === "AbortError") {
      fail(`${url} timed out after ${timeoutMs}ms.`);
    }
    throw error;
  } finally {
    clearTimeout(timeout);
  }
}

async function callTool(name, toolArgs) {
  const response = await requestJson(
    `http://127.0.0.1:${toolchain.mcp.proxyPort}/tool`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name, args: toolArgs }),
    },
  );
  return parseToolText(await response.json(), name);
}

async function waitForMcpServer() {
  const deadline = Date.now() + 30000;
  let lastError;
  do {
    try {
      const response = await requestJson(
        `http://127.0.0.1:${toolchain.mcp.proxyPort}/health`,
        {},
        1000,
      );
      const health = await response.json();
      if (health.server !== toolchain.mcp.package || health.version !== toolchain.mcp.version) {
        fail(`Port ${toolchain.mcp.proxyPort} is not the pinned Virtual Meetup MCP server.`);
      }
      return;
    } catch (error) {
      lastError = error;
      if (!waitForWorkspace) {
        throw error;
      }
      await delay(250);
    }
  } while (Date.now() < deadline);
  fail(`MCP server did not become ready within 30 seconds: ${lastError?.message}`);
}

async function waitForGodotEditor() {
  const deadline = Date.now() + 30000;
  let lastError;
  do {
    try {
      const status = await callTool("get_godot_status", {});
      if (status.connected && comparable(status.project_path) !== comparable(repositoryRoot)) {
        fail(`MCP is connected to a different project: ${status.project_path}`);
      }
      if (status.connected) {
        return;
      }
      lastError = new Error("Godot has not connected yet.");
    } catch (error) {
      lastError = error;
    }
    if (!waitForWorkspace) {
      throw lastError;
    }
    await delay(250);
  } while (Date.now() < deadline);
  fail(`Godot did not connect to MCP within 30 seconds: ${lastError?.message}`);
}

async function remainActive() {
  if (!stayAlive) {
    return;
  }
  process.stdout.write("Project map is active. Stop this launch to shut down its workspace.\n");
  await new Promise((resolve) => {
    // Signal listeners do not keep Node's event loop alive on their own.
    const keepAlive = setInterval(() => {}, 1000);
    const stop = () => {
      clearInterval(keepAlive);
      process.removeListener("SIGINT", stop);
      process.removeListener("SIGTERM", stop);
      resolve();
    };
    process.once("SIGINT", stop);
    process.once("SIGTERM", stop);
  });
}

function openBrowser(url) {
  const child = process.platform === "win32"
    ? spawn("rundll32.exe", ["url.dll,FileProtocolHandler", url], {
        detached: true,
        stdio: "ignore",
        windowsHide: true,
      })
    : spawn("xdg-open", [url], { detached: true, stdio: "ignore" });
  child.unref();
}

try {
  const major = Number.parseInt(process.versions.node.split(".")[0], 10);
  if (major < toolchain.node.minimumMajor) {
    fail(`Node ${toolchain.node.minimumMajor} or newer is required; found ${process.versions.node}.`);
  }
  if (!toolchain.node.supportedLtsMajors.includes(major)) {
    process.stderr.write(`WARNING: Node ${process.versions.node} is outside the recommended LTS majors ${toolchain.node.supportedLtsMajors.join(", ")}; continuing with this installed version.\n`);
  }
  if (!root.startsWith("res://") || root.includes("..")) {
    fail("The project-map root must be a safe res:// path.");
  }

  await waitForMcpServer();
  await waitForGodotEditor();

  const mapped = await callTool("map_project", {
    root,
    include_addons: args.includes("--include-addons"),
  });
  const visualizationUrl = new URL(mapped.visualization_url);
  if (
    visualizationUrl.protocol !== "http:"
    || !["localhost", "127.0.0.1"].includes(visualizationUrl.hostname)
    || Number(visualizationUrl.port) !== toolchain.mcp.visualizerPort
  ) {
    fail(`MCP returned an unexpected visualizer URL: ${visualizationUrl.href}`);
  }
  await requestJson(visualizationUrl, {}, 3000);
  process.stdout.write(`Virtual Meetup project map: ${visualizationUrl.href}\n`);
  if (args.includes("--open")) {
    openBrowser(visualizationUrl.href);
  }
  await remainActive();
} catch (error) {
  process.stderr.write(
    `ERROR: ${error.message}\nFor a complete workspace, launch "Virtual Meetup: Godot Editor Headless + Project Map" or "Virtual Meetup: All".\n`,
  );
  process.exitCode = 1;
}
