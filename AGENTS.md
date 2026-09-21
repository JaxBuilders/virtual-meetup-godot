# Agent Notes

Virtual Meetup is JaxBuilders' Godot social sandbox. Read `PLAN.md` before adding features.

## Local instructions

Local-only instructions belong in `AGENTS_LOCAL.md`. Read it after this file when present; it is gitignored and must not be committed. Never store passwords, tokens, private keys, or other secrets in either agent file.

## Development rules

- Target Godot 4.7.1 with typed GDScript.
- Keep direct input in `PlayerInputSource`; simulation consumes `PlayerCommand`.
- Humanoid visuals must use sourced assets, including fallback selections, previews, and remote players. Procedural modification/generation of those humans is allowed; primitive assembled humanoids or stand-in hair/accessories are not. Invisible physics colliders are unaffected.
- Keep vendor services behind project-owned adapters and preserve complete offline behavior.
- Build activities as runtime scenes/resources; runtime code must not depend on editor APIs or write beneath `res://`.
- Treat `docs/ASSET_CANDIDATES.md` approval as a hard gate before downloading or importing content.
- Record approved sources, licenses, checksums, transformations, and derived files in `docs/ASSET_PROVENANCE.md`.
- Preserve third-party notices and do not copy application IDs from sibling projects.
- Follow `docs/VENDOR_SNAPSHOT_POLICY.md` before changing bundled development or networking snapshots.
- Finalize edited text with CRLF line endings.

## Godot and MCP

Use `node dev/dev.mjs bootstrap` and the tracked project configuration for the pinned Godot/MCP environment. MCP stays on localhost and is excluded from production behavior. Do not launch visual gameplay, capture screenshots, or terminate Godot processes unless the user requests it. Headless imports and checks are the normal validation path.

## Privacy and releases

Do not add telemetry, transcript logging, PII logging, raw personal paths, secrets, or unapproved network calls. Do not package, publish, rewrite history, expire reflogs, or run garbage collection without explicit approval.
