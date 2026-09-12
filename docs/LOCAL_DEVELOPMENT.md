# Local Development

Virtual Meetup pins Godot 4.7.1 and Godot MCP 0.5.0 through the repository-local development harness adapted from MegaDart.

Use Node.js 22 or 24 LTS (recommended), then run:

```text
node dev/dev.mjs bootstrap
node dev/dev.mjs doctor
node dev/dev.mjs check
node dev/dev.mjs editor
```

`bootstrap` downloads a verified Godot build into ignored `.tools/`, installs the locked MCP server under `dev/mcp/`, imports the project, and runs nonvisual diagnostics. `GODOT_BIN` may override editor discovery.

The VS Code MCP Server entry and `node dev/mcp/launch-server.mjs` automatically install or repair missing, mismatched, or unpatched MCP dependencies before starting. This uses `bootstrap --mcp-only`, the pinned lockfile, and disabled npm lifecycle scripts; an existing valid installation needs no download. Installation failures stop launch with a diagnostic. Node 22 or newer and npm must already be available. Versions outside the recommended 22/24 LTS releases emit a compatibility warning and continue. Editor, headless-editor, import, and check commands automatically download and verify the pinned Godot runtime when missing. An invalid explicit GODOT_BIN override is reported rather than replaced. Full bootstrap remains available for upfront setup and diagnostics.

VS Code launch entries use shell commands that clear NODE_OPTIONS and VSCODE_INSPECTOR_OPTIONS before starting Node, preventing injected JavaScript debugger attachment. This also clears any custom Node options for these development launches. Setup diagnostics use stderr so the same MCP launcher also works with stdio clients.

For online room development, create a Fusion 3 application specifically for Virtual Meetup and expose its identifier only in your local environment:

```text
VIRTUAL_MEETUP_FUSION_APP_ID=
```

An empty value is valid and leaves online actions unavailable. The identifier is never copied from MegaDart or BB-Godot.

Avatar authoring uses Blender 4.5 LTS and MPFB2 2.0.15 outside the game repository. Set `BLENDER_BIN` or put Blender on `PATH`. MPFB2 is not installed by the development harness.
