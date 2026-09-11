# Local Development

Virtual Meetup pins Godot 4.7.1 and Godot MCP 0.5.0 through the repository-local development harness adapted from MegaDart.

Install Node.js 22 or 24 LTS, then run:

```text
node dev/dev.mjs bootstrap
node dev/dev.mjs doctor
node dev/dev.mjs check
node dev/dev.mjs editor
```

`bootstrap` downloads a verified Godot build into ignored `.tools/`, installs the locked MCP server under `dev/mcp/`, imports the project, and runs nonvisual diagnostics. `GODOT_BIN` may override editor discovery.

For online room development, create a Fusion 3 application specifically for Virtual Meetup and expose its identifier only in your local environment:

```text
VIRTUAL_MEETUP_FUSION_APP_ID=
```

An empty value is valid and leaves online actions unavailable. The identifier is never copied from MegaDart or BB-Godot.

Avatar authoring uses Blender 4.5 LTS and MPFB2 2.0.15 outside the game repository. Set `BLENDER_BIN` or put Blender on `PATH`. MPFB2 is not installed by the development harness.
