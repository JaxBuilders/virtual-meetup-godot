# Blender authoring workspace

Choose **Virtual Meetup: Blender + MCP + MPFB** to start a new Blender process with the project authoring tools. Save work in existing windows before closing them yourself. The plain Blender entry remains available. Restart the MCP client to load the new `virtual_meetup_blender` configuration; the client owns the stdio server, so no additional terminal server is needed.

## Installed tools

- Blender MCP 1.9.1: https://github.com/ahujasid/blender-mcp (MIT). Project-local Python environment: `.tools/blender-mcp-1.9.1`. Installed with `uv venv .tools/blender-mcp-1.9.1` then `uv pip install --python .tools/blender-mcp-1.9.1/bin/python blender-mcp==1.9.1`. Windows uses `Scripts/python.exe` instead of `bin/python`.
- MPFB 2.0.15: https://github.com/makehumancommunity/mpfb2/tree/f4f4f1ffa8203585730a7ce433b66738777ba168 (GPL-3.0-or-later). Source archive: https://codeload.github.com/makehumancommunity/mpfb2/zip/f4f4f1ffa8203585730a7ce433b66738777ba168 . Extract under `.tools/`, keeping the archive's root directory. SHA-256: `4f4203eac1292cf58adc1c8ca49856c984e959caef6905d94bb95d94a314ccc7`.
- Blender MCP wheel SHA-256 published by PyPI: `ede3aed34926f77142b8f00ee4f8544f68067d2dc747da8295d1c456171355b2`.

Tool installation is local and ignored by Git. A fresh clone needs the setup above; automatic authoring-tool bootstrap is not implemented. Python dependencies are resolved by uv; only the top-level MCP version is pinned at present.

The startup script registers MPFB through a session extension repository and loads the matching bundled MCP add-on. It does not save global Blender preferences. When present, ignored `.tools/avatar-lab/library/` is exposed as MPFB's secondary asset root for that session; it currently combines approved CC0 system and modular packs using local hard links. MPFB creates its normal user-data directories. `DISABLE_TELEMETRY=true` is set in both processes, and the add-on's telemetry consent default is patched in memory before registration. External asset integrations are disabled. The bridge listens on localhost:9876. Only run one authoring bridge at a time.

## Validation and next step

Blender 5.2.1 LTS successfully registered MPFB 2.0.15 and reproducibly generated the bare and clothed rigged GLBs on 2026-09-13. The clothed output contains five skinned meshes at 39,342 evaluated triangles, and repeated builds produced the same GLB SHA-256 values for both proofs. The builder rejects left/right upper-arm weight groups whose weighted geometry centroid falls on the wrong anatomical side. The documented Blender 4.5 baseline remains the release target; 5.2.1 is now a validated local compatibility version, and the proofs should still be regenerated under 4.5 before release.

Use the MPFB viewport sidebar to inspect the local wardrobe pool. Run **Virtual Meetup: Build Avatar Proofs** from VS Code, or `node dev/dev.mjs blender --build-avatar-proofs`, to execute the reproducible bare-and-clothed builder in a factory-startup background Blender session. It reads only the narrow retained source subset and writes ignored review output under `.tools/avatar-lab/output/`. Approved editable sources live under `assets/source/`, and reviewed GLBs live under `assets/avatars/`.
