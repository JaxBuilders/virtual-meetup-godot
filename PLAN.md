# Virtual Meetup Roadmap

Virtual Meetup is a creator-friendly Godot social sandbox for small invited groups. Windows and Linux desktop are the first supported platforms; systems and content budgets should remain compatible with a later mobile milestone.

## Product rules

- Keep offline play fully functional when Photon Fusion is absent, unconfigured, or unavailable.
- Keep multiplayer services behind project-owned interfaces. Gameplay and UI must not call vendor singletons directly.
- Build activities as independent runtime scenes and resources rather than adding activity-specific branches to the application controller.
- Reuse work from sibling projects only when JaxBuilders has documented authorization and the audited snapshot has recorded provenance.
- Do not download or import asset candidates until their status in `docs/ASSET_CANDIDATES.md` is explicitly changed to Approved.
- Do not publish source or binaries until a project license and asset redistribution review are complete.

## Milestone 1 — Foundation

Gate: a fresh clone imports in Godot 4.7.1, headless checks pass, and offline startup needs no credentials.

- Repository documentation, portable Godot/MCP harness, Windows/Linux export presets, and VS Code launch configurations.
- Versioned profile and settings stores.
- Session, avatar, activity, interaction, and voice transport interfaces.
- Audited Godot MCP and Photon Fusion snapshots from MegaDart commit `e9d98061751366641c6fa46159be308a8d14abc2`.
- Asset candidate and approved-import provenance workflow.

## Milestone 2 — Offline clubhouse

Gate: the complete social playground works without Fusion.

- Home flow for offline play, online room actions, customization, and settings.
- Cozy clubhouse and patio with third-/first-person movement.
- Primitive modular avatar catalog, emotes, seating, balls, blocks, and dice.
- Ephemeral local chat, room menu, local safety controls, and development gallery.

## Milestone 3 — Private online room

Gate: two or more desktop clients can join by regional invite code and retain usable room state through late join and master migration.

- Hidden 16-person Fusion Shared Authority rooms.
- Player-attached avatar replication, transient chat/emotes, participant state, and room locking.
- Transferable authority for seats and physics toys.
- Multi-instance latency, disconnect, late-join, ownership-contention, and capacity testing.

## Milestone 4 — Social expansion

- Additional approved venues and independently registered activities.
- Larger avatar catalog, richer animation, gamepad support, accessibility, and desktop/mobile performance budgets.

## Milestone 5 — Voice and identity

- Re-evaluate Photon Voice, LiveKit, and other transports.
- Spatial voice, microphone/device UX, authenticated identity, and durable moderation.

## Milestone 6 — Creator and platform expansion

- Runtime venue/activity creation, persistence, discovery, mobile controls/exports, platform integration, and public release licensing.

## Explicitly deferred

Voice transmission, public matchmaking, authenticated accounts, kick/ban services, mobile releases, VR, commerce, combat, arbitrary user uploads, persistent rooms, and production packaging are not part of the first playable.
