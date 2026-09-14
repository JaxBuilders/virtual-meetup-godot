# Vendor Snapshot Upgrade Policy

Bundled development and networking dependencies are audited snapshots, not casual drop-ins. Upgrade them only when a task explicitly targets the vendor snapshot or when the project owner approves the change.

## Current pinned snapshots

- Godot MCP addon and local server: `0.5.0`, with the addon under `addons/godot_mcp/` and the server lockfile under `dev/mcp/`.
- Photon Fusion for Godot/Core: `3.0.0.625`, under `addons/fusion/`.
- Repo-local Godot editor toolchain: `4.7.1`, pinned in `dev/toolchain.json`.

Source and license records live in `docs/ASSET_PROVENANCE.md` and `THIRD_PARTY_NOTICES.md`.

## Upgrade rules

- Keep matched components together. Do not mix Godot MCP addon and server versions.
- Keep networking dependencies behind project-owned adapters, and preserve complete offline behavior when online services are absent or unconfigured.
- Record the upstream version, source URL, release or commit, copied paths, license or notice changes, and any changed checksums or lockfiles.
- Review the vendor diff before replacing a snapshot. Summarize behavior changes and migration notes in the PR.
- Do not copy sibling-project application IDs, credentials, generated local state, or unapproved assets.
- Keep vendor changes separate from unrelated gameplay, menu, UI, or scene edits unless the migration requires them.

## PR checklist

- The issue or PR names the dependency and target version.
- `docs/ASSET_PROVENANCE.md` and `THIRD_PARTY_NOTICES.md` are updated when source, license, notice, or provenance details change.
- `dev/toolchain.json`, `dev/mcp/package.json`, `dev/mcp/package-lock.json`, addon metadata, and native extension files are updated as applicable.
- Validation includes the relevant repo-local harness commands, usually `node dev/dev.mjs bootstrap`, `node dev/dev.mjs import`, `node dev/dev.mjs check`, and a bounded headless test or smoke run when runtime behavior can change.
- Edited text files are finalized with CRLF line endings.
