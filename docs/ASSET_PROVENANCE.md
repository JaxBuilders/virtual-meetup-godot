# Asset Provenance

Every approved imported asset must record its stable ID, in-project paths, original and preview URLs, creator, license evidence, approval date, SHA-256, transformations, derived outputs, and attribution or compatibility requirements.

## Authored foundation content

The clubhouse, UI, materials, and activity props are project-authored Godot resources and scripts. Imported avatar content is recorded below. Runtime customization applies per-instance suit/skin tints, body scaling, and sourced hair visibility to the approved MakeHuman wardrobe without altering source GLBs or their checksums. Primitive humanoid fallbacks and cap/bun/glasses/badge approximations have been removed.

### `brand.virtual-meetup-mark`

- Project path: `icon.png`
- Source: project-owner-supplied logo concept provided directly during development; no public source URL.
- Approval: approved by the project owner for use as the Virtual Meetup project and export icon on 2026-09-11.
- Rights status: approved for private JaxBuilders development; creator and redistribution evidence must be retained or completed before public release.
- SHA-256: `a8581198730ee64a1792fe980e231f487a3fe641ce7bf73a2da037f8fdb1dc5e`
- Transformation: the supplied mark was background-extracted with image generation, placed on a transparent square canvas with even padding, and preserved as a 1254×1254 RGBA PNG.
- Derived outputs: Godot imports `icon.png` for the project and Linux-facing icon. `icon.ico` is a 256/128/64/48/32/16-pixel Windows icon derived from the approved PNG (SHA-256 `4234092ba6d9371777fa7064e7e02b709ed329e8474c27725283e1ef321673ac`).

### `avatar.makehuman_baseline`

- Project paths: `assets/source/avatars/makehuman_baseline.blend` and `assets/avatars/makehuman_baseline.glb`.
- Original source: the core human bundled with MPFB2 2.0.15 from https://github.com/makehumancommunity/mpfb2/tree/v2.0.15.
- Creator/source: MakeHuman Community; generated and adapted for Virtual Meetup by JaxBuilders.
- License evidence: MakeHuman core assets and generated graphical output are CC0; https://static.makehumancommunity.org/about/license.html and https://static.makehumancommunity.org/mpfb/faq/is_it_really_free.html. MPFB add-on code remains GPLv3 and is not embedded in either asset.
- Approval: approved by the project owner for the authored avatar baseline on 2026-09-12.
- Source tool snapshot: MPFB2 tag `v2.0.15`, commit `f4f4f1ffa8203585730a7ce433b66738777ba168`; downloaded source archive SHA-256 `4f4203eac1292cf58adc1c8ca49856c984e959caef6905d94bb95d94a314ccc7`.
- Editable source SHA-256: `b484f473f9ad9ca853a1d159128181f13b76cf158b3471bbe4fae2b1e507c415`.
- Derived GLB SHA-256: `7a6bd1128a20bcaef0747b4a8ab6693016b04ee76649980d16c9e508034e8c76`.
- Generation: Blender 5.2.1 LTS with MPFB2 2.0.15; neutral core human with the unmodified `game_engine` rig; meter scale; no wardrobe or community assets loaded. Blender 4.5 remains the pinned release baseline and must reproduce the proof before release.
- Transformation: rig normalized to 1.70 meters, source bone names preserved for reproducibility, and Godot's humanoid importer performs the canonical rename, axis overwrite, and A-pose-to-T-pose silhouette correction. The GLB contains one skinned mesh, 26,756 evaluated triangles, 53 bones, and approximately 1.696 meters of visible vertical extent.
- Compatibility: this is a validation mannequin, not a complete player catalog entry. It has no clothing, hair, textures, or animation library and currently appears only in the avatar gallery.

### `animation.quaternius_ual_standard`

- Project paths: `assets/source/animations/quaternius_ual_standard/UAL1_Standard.glb` and `docs/licenses/QUATERNIUS_UAL_CC0.txt`.
- Original and preview URLs: https://quaternius.itch.io/universal-animation-library and https://quaternius.com/packs/universalanimationlibrary.html.
- Creator/source: Quaternius, Universal Animation Library Standard 3.0.
- License evidence: CC0 1.0 Universal, declared by the original download page and retained verbatim in `docs/licenses/QUATERNIUS_UAL_CC0.txt`.
- Approval: approved by the project owner for local evaluation, retargeting, and selective derived outputs on 2026-09-13.
- Acquisition: downloaded through the original itch.io public zero-cost download flow without an account. The Standard ZIP SHA-256 is `cc73fc4e495b82958207316596317a3f40b9fa38065bde1027937452da537724`.
- Retained source SHA-256: `69591853d817488edaa8fd9bf8fc1d821eaeaf789f8627b3cd23b41c4ed67997`. Retained license SHA-256: `6d01f55c6e4c49a2c9963e147e561945ae2c83958c8ca667d90a6bffdbfac061`.
- Selection: retained the no-root-motion Unreal/Godot GLB. The archive's root-motion GLB was inspected locally but is not tracked.
- Contents: one source armature, one reference mannequin, and 43 actions covering locomotion, jumps, sitting, swimming, combat, interactions, and social animation.
- Transformation: none to the retained source. Runtime or derived avatar animations must use Godot humanoid rest fixing or an equivalent baked retarget onto the canonical avatar skeleton; source action names are not runtime animation IDs.
- Compatibility: source skeleton semantics map closely to the MPFB game rig, but bone rests differ and direct track copying is prohibited. The inspected mapping is stored in `dev/blender/retarget_profiles/humanoid_profiles.json`.

### `avatar.makehuman_wardrobe_proof`

- Project paths: `assets/source/avatars/makehuman_wardrobe_proof.blend`, `assets/avatars/makehuman_wardrobe_proof.glb`, and the selected source dependencies under `assets/source/vendor/makehuman_system_assets/`.
- Original source: MakeHuman System Assets from https://static.makehumancommunity.org/assets/assetpacks/makehuman_system_assets.html.
- Creator/source: MakeHuman Community `makehuman_system` catalog author; assembled and adapted for Virtual Meetup by JaxBuilders.
- License evidence: every retained catalog entry declares CC0. Evidence and source links are retained in `docs/licenses/MAKEHUMAN_SYSTEM_ASSETS_CC0.md`; all selected-file hashes are in `docs/licenses/MAKEHUMAN_SYSTEM_ASSETS_SELECTED.sha256`.
- Approval: system pack approved by the project owner for local evaluation and selective derived outputs on 2026-09-13.
- Acquisition: official pack archive SHA-256 `b542127a8e25547c7c29c19f2d1d2adb9a664c80396ecd694095dbc8028a0107`.
- Selected inputs: young Caucasian male skin, low-poly eyes and their brown material, short01 hair, male casual suit 01, and shoes 01. The rest of the 267 MB authoring pack is not tracked.
- Editable source SHA-256: `94dbdb562b07e2630ec5662631eb221d43fe870273b664c98484db61c25c6ac0`.
- Derived GLB SHA-256: `a63ae599475699c560320d701d1f423cdb94000a1ce7753ba4ac6247927ca4e3`.
- Generation: Blender 5.2.1 LTS with MPFB2 2.0.15; core human with its `game_engine` rig; selected assets fitted and weighted through MPFB; Blender source saved before glTF export. Blender 4.5 remains the pinned release baseline and must reproduce the proof before release.
- Transformation: rig normalized to 1.70 meters; modifiers evaluated for export; embedded textures imported as Basis Universal; skinning limited by glTF export to four highest normalized joint influences.
- Output metrics: five skinned meshes, 39,342 evaluated triangles, 53 bones, and approximately 1.714 meters of visible vertical extent.
- Compatibility: this remains one authored proof rather than a complete selectable catalog. Godot's humanoid importer normalizes it to `GeneralSkeleton`, overwrites axes, and corrects the MPFB A-pose silhouette to Godot's humanoid T-pose. It became the private-development gameplay default on 2026-09-13; there is no longer a primitive load-failure fallback.

## Audited code/vendor snapshots

- Godot MCP 0.5.0: copied from MegaDart commit `e9d98061751366641c6fa46159be308a8d14abc2`; MIT notice preserved.
- Photon Fusion for Godot/Core 3.0.0.625: copied from the same commit; Photon SDK terms preserved in `THIRD_PARTY_NOTICES.md`.
- Development harness: adapted from the same MegaDart commit; project names, scene defaults, and extension checks were changed for Virtual Meetup.

Upgrade policy: follow `docs/VENDOR_SNAPSHOT_POLICY.md` before changing bundled development or networking snapshots.
