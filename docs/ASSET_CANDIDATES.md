# Asset Candidate Queue

Codex may add research entries here. During a project-owner-authorized exploration window, candidates may be downloaded, extracted, converted, and evaluated only under ignored local staging. A candidate must still be explicitly `Approved` before any part enters Git or a shipping build, and every tracked input or output needs complete provenance.

## Candidate template

- ID:
- Title:
- Preview URL:
- Author/source:
- Original URL:
- License and evidence URL:
- Intended use:
- Available formats and estimated size:
- Visual/technical fit:
- Integration effort:
- Redistribution or maintenance risks:
- Recommendation:
- Decision: Proposed | Approved | Rejected
- Decision date and approver:

## Initial authoring tool

- ID: `tool-mpfb2`
- Title: MPFB2
- Preview URL: https://github.com/makehumancommunity/mpfb2
- Author/source: MakeHuman Community
- Original URL: https://github.com/makehumancommunity/mpfb2
- License and evidence URL: GPLv3 for add-on code; https://github.com/makehumancommunity/mpfb2/blob/master/LICENSE.md
- Intended use: External Blender authoring and glTF export of a canonical humanoid pipeline.
- Available formats and estimated size: Blender add-on; not vendored into the game.
- Visual/technical fit: Useful base for curated human bodies and compatible wearables.
- Integration effort: Retopology/material simplification, rig normalization, animation retargeting, and per-output provenance.
- Redistribution or maintenance risks: GPL code must remain outside the game; generated output and source assets require individual review.
- Recommendation: Use only as an external authoring tool.
- Decision: Approved
- Decision date and approver: 2026-09-10, project owner

## Animation candidates

- ID: `animation-quaternius-universal`
- Title: Quaternius Universal Animation Library
- Preview URL: https://quaternius.com/packs/universalanimationlibrary.html
- Author/source: Quaternius
- Original URL: https://quaternius.com/packs/universalanimationlibrary.html
- License and evidence URL: CC0; the source page identifies the library and its Blend, FBX, and GLB exports as CC0.
- Intended use: Primary source for locomotion, jumping, sitting, interaction, and social-emote clips retargeted onto the canonical avatar skeleton.
- Available formats and estimated size: the evaluated Standard 3.0 ZIP is approximately 16 MB and contains 43 clips as FBX and GLB, each with root-motion and no-root-motion variants; a larger source package is offered separately.
- Visual/technical fit: Designed for humanoid retargeting and explicitly tested with Godot. It covers most of the first-playable animation contract from one consistent source.
- Integration effort: The source rig and 23-bone semantic mapping are inspected. Configure Godot humanoid rest fixing, retarget a small proof set, bake or import in-place clips at 30 FPS, and validate contacts and loop seams.
- Redistribution or maintenance risks: The free and paid/source downloads must not be conflated. The evaluated Standard archive, 43-clip subset, CC0 notice, and SHA-256 are recorded in `docs/ASSET_PROVENANCE.md`.
- Recommendation: Approve as the primary animation library and begin with idle, walk, jog, jump, sit, wave, clap, and dance.
- Decision: Approved
- Decision date and approver: 2026-09-13, project owner; local evaluation and retargeting

- ID: `animation-adobe-mixamo`
- Title: Adobe Mixamo animation library
- Preview URL: https://www.mixamo.com/
- Author/source: Adobe
- Original URL: https://www.mixamo.com/
- License and evidence URL: Adobe Mixamo FAQ; https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html
- Intended use: Secondary source for missing social or interaction clips after the CC0 library is evaluated.
- Available formats and estimated size: Per-animation FBX downloads selected through the authenticated Mixamo site.
- Visual/technical fit: MPFB includes a Mixamo-compatible rig definition, and the standard Mixamo bone names now have a checked mapping to the project skeleton.
- Integration effort: A human signs in, selects and downloads each approved clip, then Blender retargeting strips root motion and bakes the target action.
- Redistribution or maintenance risks: Royalty-free use in games is documented, but this is not CC0. Downloads require an Adobe ID and must never be automated or redistributed as a standalone animation library.
- Recommendation: Keep as a human-operated fallback rather than the foundation of the catalog.
- Decision: Proposed
- Decision date and approver:

## MakeHuman wardrobe candidates

- ID: `makehuman-system-assets`
- Title: MakeHuman system assets
- Preview URL: https://static.makehumancommunity.org/assets/assetpacks/makehuman_system_assets.html
- Author/source: MakeHuman Community
- Original URL: https://static.makehumancommunity.org/assets/assetpacks/makehuman_system_assets.html
- License and evidence URL: CC0; every included entry is listed with its license on the source page.
- Intended use: Required MPFB foundation assets plus the first audited hair, eyes, skin, casual outfit, and shoe options.
- Available formats and estimated size: MPFB/MakeHuman asset-pack ZIP, approximately 267 MB.
- Visual/technical fit: Native MHCLO assets fit MakeHuman phenotypes and can be rigged through MPFB. The pack includes several casual suits, sports/work outfits, six or more hairstyles, shoes, eyes, and skin materials.
- Integration effort: Install locally outside `res://`, inventory exact selected assets, generate a small number of baked game-ready avatar combinations, simplify materials, and validate clipping.
- Redistribution or maintenance risks: Do not copy the entire authoring pack into the game. The first proof retains only five selected inputs and its source manifest; further additions require the same narrow provenance treatment.
- Recommendation: Approve as the first wardrobe source.
- Decision: Approved
- Decision date and approver: 2026-09-13, project owner; local evaluation and selective derived outputs

- ID: `makehuman-cc0-casual-packs`
- Title: MakeHuman Hair 01, Shirts 01, Pants 01, and Shoes 01 packs
- Preview URL: https://static.makehumancommunity.org/assets/assetpacks.html
- Author/source: MakeHuman Community asset-pack maintainers and the creators listed per item
- Original URL: https://static.makehumancommunity.org/assets/assetpacks/hair01.html, https://static.makehumancommunity.org/assets/assetpacks/shirts01.html, https://static.makehumancommunity.org/assets/assetpacks/pants01.html, and https://static.makehumancommunity.org/assets/assetpacks/shoes01.html
- License and evidence URL: Each selected pack is listed in the MakeHuman asset-pack index under mesh assets shared as CC0.
- Intended use: Expand the first catalog with low-poly/stylized hair and mix-and-match casual tops, bottoms, and footwear.
- Available formats and evaluated archives: MakeHuman/MPFB asset-pack ZIPs. Hair 01 is 227,775,853 bytes (`49445d69848a313ec41a9970f6a0fe4bcf925c9f1c6ef40a76f119c2e07940c9`), Shirts 01 is 24,479,483 bytes (`a5a723b0e84a109bb190fcfeac7f1de4138d875da3e30fe5b3340eac9f38bcd3`), Pants 01 is 21,908,723 bytes (`e4e0ec60db34f279be291a83cfd7b342a7c5cf09bb7676682a5f39f4f6ac4ad9`), and Shoes 01 is 82,953,569 bytes (`ded3f70428505eabbf1f6d7b5f61196a7366ef20757103d276ad0ed336c35ada`).
- Visual/technical fit: Better matches a modular social avatar catalog than the system pack's mostly one-piece gendered suits.
- Integration effort: The ignored evaluation pool contains 25 hair, 10 shirt, 4 pants, and 23 shoe meshes. Audit individual items, test phenotype compatibility, simplify materials, define stable catalog IDs, and export only proven combinations.
- Redistribution or maintenance risks: Pack-level CC0 does not replace per-item technical review. Avoid the similarly named CC-BY Hair 02/03, Shirts 02/03, Pants 02/03, and Shoes 02/03 packs unless attribution is deliberately added.
- Recommendation: Approve after the system pack proves the end-to-end clothing workflow.
- Decision: Approved
- Decision date and approver: 2026-09-13, project owner; local evaluation after system-pack validation
