# Avatar Content and Retargeting

## Selected direction

The project keeps one canonical game skeleton: the normalized MPFB `game_engine` rig already imported at `Armature/Skeleton3D`. Source animation skeletons are temporary Blender authoring inputs. Runtime GLBs contain only the canonical skeleton and baked actions.

The preferred animation source is the CC0 Quaternius Universal Animation Library. Adobe Mixamo is a secondary, human-operated gap filler because it requires an account and uses Adobe's royalty-free terms rather than CC0. MPFB's bundled walk-cycle data is not a production source: MPFB labels the relevant animation service mostly experimental and its only bundled walk-cycle preset as experimental.

The preferred wardrobe source is the official CC0 MakeHuman system-assets pack. After that workflow is validated, the separate CC0 Hair 01, Shirts 01, Pants 01, and Shoes 01 packs are the best candidates for modular casual combinations. CC-BY packs stay out of the first pass to keep redistribution and attribution simple.

During the temporary exploration window recorded in ignored `AGENTS_LOCAL.md`, candidate archives may be downloaded, extracted, converted, and tested under ignored `.tools/avatar-lab/` without individual confirmation. Nothing becomes a tracked or shipping asset until its license, source URL, hashes, transformations, and provenance are complete.

## Source inspection results

Quaternius Universal Animation Library Standard 3.0 contains 43 CC0 actions and provides both root-motion and no-root-motion GLBs. The no-root-motion GLB is the selected gameplay source. It directly covers idle, walk, jog, jump, seated idle/transitions, and dance. It does not contain dedicated wave, point, or clap clips; `Interact` is a possible temporary gesture stand-in, but it is not assigned a stable social-emote ID until visual review.

The Quaternius skeleton uses the same broad game-engine hierarchy as MPFB, but its bone rests differ substantially at the shoulders, pelvis, and limbs. Matching tracks by bone name is therefore invalid. Import retargeting uses Godot's `SkeletonProfileHumanoid`/`BoneMap` and rest-fixing pipeline. Quaternius is already in a T-pose; MPFB targets require both axis overwrite and A-pose silhouette correction. Automated checks verify that left/right arms remain on their anatomical sides and that the corrected chains are horizontal. The mapping discovered during Blender inspection is recorded in `dev/blender/retarget_profiles/humanoid_profiles.json` for validation and future Blender tooling.

## First retarget proof

Retarget and validate this small set before importing the entire library:

1. `idle` — looping, relaxed stance, no root drift.
2. `walk` — looping and in-place, with stable foot contacts.
3. `jog` — looping and in-place, suitable for sprint playback scaling.
4. `jump` — one-shot takeoff, airborne, and landing phases that can be split or blended.
5. `sit` — transition into the project's seat pose and a looping seated idle.
6. `dance` — one looping full-body emote.
7. `wave` — upper-body-friendly one-shot from a separately approved source or a project-authored clip.
8. `clap` — looping or repeatable social emote from a separately approved source or a project-authored clip.

Point, pickup, hold, throw, turns, and the remaining directional locomotion follow only after this proof passes in Godot.

## Blender retarget contract

- Target armature object: `Armature`.
- Target profile: `virtual_meetup_game_engine_v1` in `dev/blender/retarget_profiles/humanoid_profiles.json`.
- Source action names are never runtime IDs. Exported actions use the stable IDs above.
- Bake visual transforms onto the target rig at 30 FPS; do not ship source rigs or live retarget constraints.
- Preserve target rest-pose scale and bone rolls. MPFB's direct BVH helper is avoided because it overwrites target bone rolls.
- Remove horizontal root translation and accumulated yaw for gameplay locomotion. Preserve only vertical motion genuinely required by jump/landing.
- Keep all clips controller-driven and in-place. Seat alignment and prop attachment remain gameplay state, not animation root motion.
- Clamp the final skinning export to four joint influences per vertex and inspect shoulders, wrists, hips, knees, and ankles.
- Put each exported clip through loop-seam, foot-slide, floor-height, hand-pose, silhouette, and first-/third-person clipping checks.

## Wardrobe proof

The first clothed character should use only assets from the approved CC0 MakeHuman system pack and should remain deliberately small:

- one compatible casual outfit or shirt/pants pair;
- one pair of shoes;
- three hairstyles with honest body/phenotype compatibility;
- eyes and one simple skin material;
- no physics cloth, strand hair, or runtime body morphing.

MPFB fits MHCLO assets to the chosen phenotype and transfers rig weights. The export then bakes modifiers, removes hidden body faces and helper geometry, simplifies materials, and produces a game-only GLB. The repository keeps the editable Blend plus only the source files needed to reproduce approved outputs; the complete 267 MB authoring pack remains under ignored local staging. Blender sessions launched through the repository expose that staging directory as MPFB's secondary asset root when it is present.

## Production catalog gate

The current authored proof may serve as the private-development gameplay default, with the primitive retained as a technical fallback. It is not a production-ready avatar catalog until:

- the eight proof animations import and play through one Godot `AnimationTree`;
- outfit, hair, body, and skin variants map to stable `AvatarDescriptor` IDs;
- no selectable combination exposes hidden body geometry or severe clipping;
- first-person hides or masks obstructive head geometry;
- third-person locomotion and all social emotes remain readable at clubhouse camera distance;
- a representative avatar stays within the documented triangle, material, texture, and joint-influence budgets.
