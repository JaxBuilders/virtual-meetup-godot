# Avatar Pipeline

## Runtime contract

- Units are meters, Y is up, and the avatar faces negative Z.
- Game-ready imports use one armature with `Skeleton3D` at `Armature/Skeleton3D`.
- Canonical bones are `root`, `pelvis`, `spine_01`, `spine_02`, `chest`, `neck`, `head`, paired `clavicle`, `upper_arm`, `lower_arm`, `hand`, `upper_leg`, `lower_leg`, `foot`, and `toe` bones using `_l` and `_r` suffixes.
- Attachment targets are the right hand, head, chest, and pelvis bones. Runtime catalog IDs—not node paths or filenames—select bodies and wearables.
- Body, hair, outfit, and accessory meshes bind to the same canonical skeleton. The avatar catalog explicitly allowlists compatible combinations.
- Locomotion and emotes are in-place at 30 FPS. Root translation is removed during Blender export; Godot movement remains controller-driven.
- Each desktop avatar should remain below 60,000 visible triangles, four material slots, and four 2K texture sets. Content should also provide a future-mobile reduction path.

## Authoring workflow

1. Confirm the source or generator entry is Approved in `docs/ASSET_CANDIDATES.md`.
2. Author in Blender 4.5 LTS using MPFB2 2.0.15 externally when appropriate.
3. Normalize scale, axes, bone names, bind pose, materials, and attachment targets in a source `.blend` tracked by Git LFS.
4. Retarget the approved idle, walk, jog, turn, jump, sit, wave, point, clap, dance, pickup, hold, and throw clips.
5. Export game-ready glTF/GLB with meshes, skeleton, skinning, and animations; do not embed MPFB2 add-on code.
6. Inspect scale, bounds, clipping, materials, and every animation in the in-game avatar gallery.
7. Record source checksums, license evidence, transformations, and derived outputs in `docs/ASSET_PROVENANCE.md`.

The procedural primitive avatars are the current approved fallback and networking proxy. Replacing them with MPFB-derived content does not change `AvatarDescriptor` or network wire data.
