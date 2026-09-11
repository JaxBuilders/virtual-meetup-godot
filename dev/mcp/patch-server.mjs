import { readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const directory = path.dirname(fileURLToPath(import.meta.url));
const packageRoot = path.join(directory, "node_modules", "godot-mcp-server", "dist");

async function replaceExact(file, before, after) {
  const target = path.join(packageRoot, file);
  const source = await readFile(target, "utf8");
  if (source.includes(after)) {
    return;
  }
  if (!source.includes(before)) {
    throw new Error(`Pinned MCP patch context was not found in ${file}.`);
  }
  await writeFile(target, source.replace(before, after), "utf8");
}

await replaceExact(
  "visualizer-server.js",
  "            openBrowser(url);",
  "            if (process.env.GODOT_MCP_OPEN_BROWSER === '1') {\n                openBrowser(url);\n            }",
);
await replaceExact(
  "index.js",
  "Interactive visualization opened in browser at ${url}",
  "Interactive visualization available at ${url}",
);
await replaceExact(
  path.join("tools", "visualizer-tools.js"),
  "Opens an interactive browser-based visualization.",
  "Serves an interactive browser-based visualization without opening it automatically.",
);

process.stdout.write("Applied Virtual Meetup's no-browser MCP 0.5.0 safety patch.\n");
