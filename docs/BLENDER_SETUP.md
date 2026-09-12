# Blender authoring workspace

Choose **Virtual Meetup: Blender + MCP + MPFB** to start a new Blender process with the project authoring tools. Save work in existing windows before closing them yourself. The plain Blender entry remains available. Restart the MCP client to load the new `virtual_meetup_blender` configuration; the client owns the stdio server, so no additional terminal server is needed.

## Installed tools

- Blender MCP 1.9.1: https://github.com/ahujasid/blender-mcp (MIT). Project-local Python environment: `.tools/blender-mcp-1.9.1`. Installed with `uv venv .tools/blender-mcp-1.9.1` then `uv pip install --python .tools/blender-mcp-1.9.1/bin/python blender-mcp==1.9.1`. Windows uses `Scripts/python.exe` instead of `bin/python`.
- MPFB 2.0.15: https://github.com/makehumancommunity/mpfb2/tree/f4f4f1ffa8203585730a7ce433b66738777ba168 (GPL-3.0-or-later). Source archive: https://codeload.github.com/makehumancommunity/mpfb2/zip/f4f4f1ffa8203585730a7ce433b66738777ba168 . Extract under `.tools/`, keeping the archive's root directory. SHA-256: `4f4203eac1292cf58adc1c8ca49856c984e959caef6905d94bb95d94a314ccc7`.
- Blender MCP wheel SHA-256 published by PyPI: `ede3aed34926f77142b8f00ee4f8544f68067d2dc747da8295d1c456171355b2`.

Tool installation is local and ignored by Git. A fresh clone needs the setup above; automatic authoring-tool bootstrap is not implemented. Python dependencies are resolved by uv; only the top-level MCP version is pinned at present.

The startup script registers MPFB through a session extension repository and loads the matching bundled MCP add-on. It does not save global Blender preferences. MPFB creates its normal user-data directories. `DISABLE_TELEMETRY=true` is set in both processes, and the add-on's telemetry consent default is patched in memory before registration. External asset integrations are disabled. The bridge listens on localhost:9876. Only run one authoring bridge at a time.

## Validation and next step

Blender 5.2.1 LTS successfully registered MPFB 2.0.15 in a factory-startup headless check on 2026-09-12. This validates registration, not character generation, rigs, or export compatibility. The documented Blender 4.5 baseline remains unchanged pending the first avatar export test.

Use the MPFB viewport sidebar to create the first human. Keep downloaded clothes, skins, and hair behind the asset approval workflow. Save editable sources under `assets/source/` and export reviewed GLB outputs for the Godot gallery. No external art has been imported by this setup.
