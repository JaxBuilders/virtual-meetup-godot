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

## Online room setup

Online rooms use the bundled Photon Fusion snapshot when it is available and when a local Virtual Meetup Fusion App ID is provided. Offline play is still the default fallback and must keep working without credentials.

Create a Photon Fusion 3 application specifically for Virtual Meetup, then expose only its App ID in your local shell environment. Do not copy application IDs from sibling projects and do not commit real IDs, credentials, or local config files.

PowerShell:

```powershell
$env:VIRTUAL_MEETUP_FUSION_APP_ID = "your-fusion-app-id"
node dev/dev.mjs editor
```

Git Bash or Linux shell:

```bash
export VIRTUAL_MEETUP_FUSION_APP_ID="your-fusion-app-id"
node dev/dev.mjs editor
```

An empty value is valid and leaves online actions unavailable:

```text
VIRTUAL_MEETUP_FUSION_APP_ID=
```

The repository ignores `.env`, `.env.*`, and `.envrc` for local notes or shell tooling, but the Godot harness reads the process environment. Set or source the variable in the shell that launches Godot.

To verify online availability:

1. Start the editor or game from a shell where `VIRTUAL_MEETUP_FUSION_APP_ID` is set.
2. Create a local profile if one does not exist.
3. Use the home screen's online create action for a supported region such as `us`.
4. Confirm the status reaches `Connected to <REGION-CODE>` and the room HUD shows the invite code.
5. For a two-client check, launch a second client with the same environment variable and join with that code.

To verify offline fallback:

1. Start from a shell where `VIRTUAL_MEETUP_FUSION_APP_ID` is unset or empty.
2. Confirm **Play Offline** enters the clubhouse.
3. Confirm online create or join reports that online rooms need `VIRTUAL_MEETUP_FUSION_APP_ID` instead of blocking offline play.

Avatar authoring uses Blender 4.5 LTS and MPFB2 2.0.15 outside the game repository. Set `BLENDER_BIN` or put Blender on `PATH`. MPFB2 is not installed by the development harness.

Launch **Virtual Meetup: Blender** in VS Code to open the installed Blender. The harness uses `BLENDER_BIN` first, then `blender` on `PATH`, and reports the actual version without replacing your installation. `node dev/dev.mjs blender --check` verifies discovery without opening a window; `node dev/dev.mjs blender path/to/avatar.blend` opens a source file. Paths containing spaces must be quoted. This launcher is separate from the Godot **All** compound. It sets `DISABLE_TELEMETRY=true` for Blender MCP if installed; it does not install or enable Blender MCP or MPFB. Those integrations still need version selection and setup. The documented Blender 4.5/MPFB baseline is not a claim that newer installed Blender versions have been validated.
