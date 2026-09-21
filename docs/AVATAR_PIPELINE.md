# Avatar Pipeline

## Runtime contract

- Units are meters, Y is up, and gameplay faces negative Z. Raw MPFB exports face positive Z, so `AvatarVisual` applies a presentation-only 180-degree yaw without changing controller or network orientation.
- Game-ready imports use one armature with `Skeleton3D` at `Armature/Skeleton3D`.
- Authoring files preserve the MPFB `game_engine` names (`Root`, `pelvis`, `spine_01` through `spine_03`, `neck_01`, `head`, and paired game-rig limb names). Godot imports them through an explicit `BoneMap` and renames them to `SkeletonProfileHumanoid` names such as `Hips`, `LeftUpperArm`, and `RightUpperArm`; those normalized names are the runtime contract.
- Attachment targets are the right hand, head, chest, and pelvis bones. Runtime catalog IDs—not node paths or filenames—select bodies and wearables.
- Body, hair, outfit, and accessory meshes bind to the same canonical skeleton. The avatar catalog explicitly allowlists compatible combinations.
- Locomotion and emotes are in-place at 30 FPS. Root translation is removed during Blender export; Godot movement remains controller-driven.
- Each desktop avatar should remain below 60,000 visible triangles, four material slots, and four 2K texture sets. Content should also provide a future-mobile reduction path.

## Authoring workflow

1. Confirm the source or generator is permitted by the current asset-intake policy. During an explicitly recorded exploration window, untracked evaluation may happen under `.tools/avatar-lab/`; tracked inputs still require an Approved candidate and complete provenance.
2. Author in Blender 4.5 LTS using MPFB2 2.0.15 externally when appropriate.
3. Normalize scale, axes, bone names, bind pose, materials, and attachment targets in a source `.blend` tracked by Git LFS.
4. Retarget the approved idle, walk, jog, turn, jump, sit, wave, point, clap, dance, pickup, hold, and throw clips.
5. Export game-ready glTF/GLB with meshes, skeleton, skinning, and animations; do not embed MPFB2 add-on code.
6. Inspect scale, bounds, clipping, materials, and every animation in the in-game avatar gallery.
7. Record source checksums, license evidence, transformations, and derived outputs in `docs/ASSET_PROVENANCE.md`.

Source selection, the first retarget proof, wardrobe scope, and replacement gate are defined in `docs/AVATAR_CONTENT_AND_RETARGETING.md`.

## Current authored baseline

`avatar.makehuman_baseline` is the first approved authored avatar proof. It is generated from the CC0 MakeHuman core human included with MPFB2 2.0.15, uses the unmodified MPFB `game_engine` rig, and is exported at approximately 1.696 meters with 26,756 evaluated triangles and 53 bones. Godot normalizes the imported bones and MPFB A-pose to the project's humanoid contract. The source Blend and game-ready GLB live under `assets/source/avatars/` and `assets/avatars/` respectively.

The baseline is deliberately bare and uses MPFB's default body material. It proves source ownership, scale, skinning, skeleton hierarchy, Blender-to-Godot import, and gallery inspection without silently introducing wardrobe or community assets. Those remain separate approval and authoring steps.

`avatar.makehuman_wardrobe_proof` is the first clothed evaluation avatar. It retains only five approved CC0 system-pack inputs, stays below the desktop triangle budget, and shares the normalized Godot humanoid skeleton with the Quaternius animation source. The gallery displays both the bare baseline and clothed proof with idle, walk, and dance clips for direct comparison.

As of 2026-09-13, the clothed MPFB proof is the default local and remote gameplay visual. The procedural primitive remains a load-failure fallback. Idle, walk, jog, jump, sitting, dance, holding, and throwing use the approved Quaternius library; wave, point, and clap temporarily use its generic `Interact` gesture until dedicated clips are authored or approved. Body presets apply conservative uniform scale differences.

Home and room customization share an isolated 3D preview of the same gameplay avatar. Selection changes apply, persist, and publish through the existing profile flow immediately, without an Apply button. The current wardrobe offers five suit color tints (including charcoal and cream), six skin tints, crop/cap/bun/bald hair choices, and optional glasses or badge. The cap, bun, glasses, and badge are project-authored primitive accessories attached to the normalized head/chest bones; the cropped hair and suit remain the approved MakeHuman assets. Appearance updates preserve animation playback and use per-instance material overrides. These are variants of one fitted outfit, not separate authored garment sets; accessory fit and the preview layout still require visual review.
