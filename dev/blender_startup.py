"""Enable project-local authoring add-ons without saving global preferences."""
import importlib.util
import os
from pathlib import Path
import sys

import bpy

os.environ["DISABLE_TELEMETRY"] = "true"
root = Path(__file__).resolve().parent.parent
environment = root / ".tools" / "blender-mcp-1.9.1"
candidates = list(environment.glob("lib/python*/site-packages/blender_mcp/bundled/addon.py"))
candidates += list(environment.glob("Lib/site-packages/blender_mcp/bundled/addon.py"))
if len(candidates) != 1:
    raise RuntimeError("Install the pinned Blender MCP environment; see docs/BLENDER_SETUP.md")
source = candidates[0].read_text()
# Change only the consent default before registration (including edit handlers).
original = 'default=True,\n        update=_on_telemetry_consent_changed,'
if source.count(original) != 1:
    raise RuntimeError("Blender MCP consent patch no longer matches; review the vendor version")
source = source.replace(original, 'default=False,\n        update=_on_telemetry_consent_changed,')
module = importlib.util.module_from_spec(importlib.util.spec_from_loader("virtual_meetup_blender_mcp", loader=None))
module.__file__ = str(candidates[0])
sys.modules[module.__name__] = module
exec(compile(source, str(candidates[0]), "exec"), module.__dict__)
mpfb_parent = root / ".tools" / "mpfb2-f4f4f1ffa8203585730a7ce433b66738777ba168" / "src"
import addon_utils
bpy.context.preferences.extensions.repos.new(
    name="Virtual Meetup Authoring", module="virtual_meetup",
    custom_directory=str(mpfb_parent),
)
mpfb = addon_utils.enable("bl_ext.virtual_meetup.mpfb", default_set=True, persistent=False)
if mpfb is None:
    raise RuntimeError("MPFB registration failed")
wardrobe_root = root / ".tools" / "avatar-lab" / "library"
if not wardrobe_root.is_dir():
    wardrobe_root = root / ".tools" / "avatar-lab" / "extracted" / "makehuman_system_assets"
if wardrobe_root.is_dir():
    preferences = bpy.context.preferences.addons["bl_ext.virtual_meetup.mpfb"].preferences
    preferences.mpfb_second_root = str(wardrobe_root)
    from bl_ext.virtual_meetup.mpfb.services import LocationService
    LocationService.update_second_root()
    print("Virtual Meetup: project-local MakeHuman wardrobe enabled")
if "--verify-authoring" in sys.argv:
    # Verify registration without opening a bridge or modifying a scene.
    print("VIRTUAL_MEETUP_AUTHORING_CHECK MPFB registered; MCP consent patch verified")
elif bpy.app.background:
    print("Virtual Meetup: MPFB enabled for background authoring; Blender MCP skipped")
else:
    module.register()
    for name in ("polyhaven", "hyper3d", "hunyuan3d", "sketchfab", "polypizza"):
        setattr(bpy.context.scene, "blendermcp_use_" + name, False)
    print("Virtual Meetup: MPFB and Blender MCP enabled for this session")
