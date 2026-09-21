# Wardrobe batch 01

Status: acquired in the existing ignored evaluation pool; source/dependency audit
completed 2026-09-21. Not fitted, exported, visually approved, or available in-game.
No new downloads were necessary. No source pack has been added to Git.

The owner authorized further asset acquisition/evaluation on 2026-09-21.
These four packs were already approved for local evaluation in the candidate
queue. Per-item creators, source URLs, exact file hashes, archive hashes, and
source-mesh triangle counts are recorded in [the audit manifest](wardrobe_batch_01.json).
Hashes describe the local files inspected, not a claim of upstream signatures.

## First fitting queue

| Slot | Candidate | Creator | Source triangles | Fit/budget concern |
| --- | --- | --- | ---: | --- |
| Hair | Short messy hair | Cortu | 1,092 | Hairline, scalp coverage, alpha sorting |
| Hair | Blunt bob | MargaretToigo | 2,858 | Neck/shoulder contact during turns |
| Hair | Reverse French braid bun | Elvaerwyn | 7,622 | Higher budget; scalp and neck contact |
| Top | Basic tucked T-shirt | MargaretToigo | 2,700 | Waist seam against both trousers |
| Top | Fisherman sweater | MargaretToigo | 4,164 | Elbows, armpits, cuff overlap |
| Top | Male polo shirt | namuhekam | 4,106 | Body-preset compatibility not assumed |
| Bottom | Cargo pants | Cortu | 392 | Low-poly silhouette and seated knee folds |
| Bottom | Wool pants | MargaretToigo | 2,674 | Waist, hips, seated deformation |
| Footwear | Male ankle boots | MargaretToigo | 4,120 | Foot pose, trouser cuffs, ground contact |
| Footwear | Ballet flats | MargaretToigo | 8,960 | High budget for footwear; simplify or defer |

Triangle counts are triangulation estimates from source OBJ faces, before MPFB
modifiers/export. They are not measured runtime costs or quality scores.

## Source and license evidence

The official catalog lists each selected item as CC0:

- [Hair 01](https://static.makehumancommunity.org/assets/assetpacks/hair01.html)
- [Shirts 01](https://static.makehumancommunity.org/assets/assetpacks/shirts01.html)
- [Pants 01](https://static.makehumancommunity.org/assets/assetpacks/pants01.html)
- [Shoes 01](https://static.makehumancommunity.org/assets/assetpacks/shoes01.html)

All four cached archive SHA-256 values match the previously recorded values in
ASSET_CANDIDATES.md. Selected MHCLO object/material references and material texture
references resolve locally within their respective asset directories.

## Integration order

1. Fit short messy hair, tucked T-shirt, cargo pants, and ankle boots onto the
   canonical MPFB body/rig as one complete casual outfit.
2. Validate compact/tall variants and idle, walk, jog, jump, sit, and dance:
   check skin exposure, shoulder/hip/knee deformation, soles, and silhouette.
3. Fit the bob, sweater, and wool pants as a second combination. Do not promise
   arbitrary mix-and-match compatibility until each combination is checked.
4. Review braid and flats budgets before promotion.
5. Export proven combinations, record transformations and derived-output hashes,
   and then add stable runtime catalog IDs and gallery coverage.

No generated primitive accessories are needed. Only proven exports should move
from the ignored authoring pool into assets/. Dedicated wave, point, and clap
animations remain a separate acquisition/retargeting task; this batch adds none.
