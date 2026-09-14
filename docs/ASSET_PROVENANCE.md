# Asset Provenance

Every approved imported asset must record its stable ID, in-project paths, original and preview URLs, creator, license evidence, approval date, SHA-256, transformations, derived outputs, and attribution or compatibility requirements.

## Authored foundation content

The current clubhouse, primitive avatars, UI, materials, and activity props are project-authored Godot resources and scripts. No external art assets are included.

### `brand.virtual-meetup-mark`

- Project path: `icon.png`
- Source: project-owner-supplied logo concept provided directly during development; no public source URL.
- Approval: approved by the project owner for use as the Virtual Meetup project and export icon on 2026-09-11.
- Rights status: approved for private JaxBuilders development; creator and redistribution evidence must be retained or completed before public release.
- SHA-256: `a8581198730ee64a1792fe980e231f487a3fe641ce7bf73a2da037f8fdb1dc5e`
- Transformation: the supplied mark was background-extracted with image generation, placed on a transparent square canvas with even padding, and preserved as a 1254×1254 RGBA PNG.
- Derived outputs: Godot imports `icon.png` for the project and Linux-facing icon. `icon.ico` is a 256/128/64/48/32/16-pixel Windows icon derived from the approved PNG (SHA-256 `4234092ba6d9371777fa7064e7e02b709ed329e8474c27725283e1ef321673ac`).

## Audited code/vendor snapshots

- Godot MCP 0.5.0: copied from MegaDart commit `e9d98061751366641c6fa46159be308a8d14abc2`; MIT notice preserved.
- Photon Fusion for Godot/Core 3.0.0.625: copied from the same commit; Photon SDK terms preserved in `THIRD_PARTY_NOTICES.md`.
- Development harness: adapted from the same MegaDart commit; project names, scene defaults, and extension checks were changed for Virtual Meetup.

Upgrade policy: follow `docs/VENDOR_SNAPSHOT_POLICY.md` before changing bundled development or networking snapshots.
