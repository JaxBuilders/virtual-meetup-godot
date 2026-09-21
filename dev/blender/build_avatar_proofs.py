"""Build the bare and clothed MPFB avatar proofs from approved inputs."""
from pathlib import Path

import bpy

from bl_ext.virtual_meetup.mpfb.services import HumanService, ObjectService


ROOT = Path(__file__).resolve().parents[2]
ASSET_ROOT = ROOT / "assets" / "source" / "vendor" / "makehuman_system_assets"
OUTPUT_ROOT = ROOT / ".tools" / "avatar-lab" / "output"


def asset(relative_path: str) -> str:
    path = ASSET_ROOT / relative_path
    if not path.is_file():
        raise FileNotFoundError(f"Missing approved system asset: {relative_path}")
    return str(path)


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def add_asset(body, relative_path: str, asset_type: str):
    created = HumanService.add_mhclo_asset(
        asset(relative_path),
        body,
        asset_type=asset_type,
        subdiv_levels=0,
        material_type="GAMEENGINE",
        set_up_rigging=True,
        interpolate_weights=True,
        import_subrig=True,
        import_weights=True,
    )
    if created is None:
        raise RuntimeError(f"MPFB did not create {relative_path}")
    return created


def create_rigged_human(asset_id: str):
    clear_scene()
    body = HumanService.create_human()
    body.name = "Body"
    ObjectService.activate_blender_object(body)
    rig = HumanService.add_builtin_rig(body, "game_engine", import_weights=True)
    if rig is None:
        rig = body.parent
    if rig is None:
        raise RuntimeError("MPFB did not create the game_engine rig")
    rig.name = "Armature"

    height = rig.dimensions.z
    if height <= 0.0:
        raise RuntimeError(f"{asset_id} has invalid skeleton bounds")
    rig.scale *= 1.70 / height
    rig["vm_asset_id"] = asset_id
    rig["vm_license"] = "CC0 MakeHuman source assets"
    return body, rig


def save_and_export(rig, stem: str) -> None:
    blend_path = OUTPUT_ROOT / f"{stem}.blend"
    glb_path = OUTPUT_ROOT / f"{stem}.glb"
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    validate_arm_weight_sides(meshes)
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
    bpy.ops.object.select_all(action="SELECT")
    bpy.context.view_layer.objects.active = rig
    bpy.ops.export_scene.gltf(
        filepath=str(glb_path),
        export_format="GLB",
        use_selection=True,
        export_animations=False,
        export_skins=True,
        export_apply=True,
    )
    bpy.context.view_layer.update()
    depsgraph = bpy.context.evaluated_depsgraph_get()
    triangles = 0
    min_z = float("inf")
    max_z = float("-inf")
    for mesh_object in meshes:
        evaluated = mesh_object.evaluated_get(depsgraph)
        evaluated_mesh = evaluated.to_mesh()
        triangles += sum(len(poly.vertices) - 2 for poly in evaluated_mesh.polygons)
        for corner in evaluated.bound_box:
            world_corner = evaluated.matrix_world @ __import__("mathutils").Vector(corner)
            min_z = min(min_z, world_corner.z)
            max_z = max(max_z, world_corner.z)
        evaluated.to_mesh_clear()
    print(
        "VIRTUAL_MEETUP_AVATAR_PROOF "
        f"asset={stem} meshes={len(meshes)} triangles={triangles} "
        f"height={max_z - min_z:.4f} blend={blend_path.name} glb={glb_path.name}"
    )


def validate_arm_weight_sides(meshes) -> None:
    """Reject a rig or garment whose named arm weights landed on the wrong side."""
    checked = 0
    for mesh_object in meshes:
        for group_name, expected_sign in (("upperarm_l", 1.0), ("upperarm_r", -1.0)):
            group = mesh_object.vertex_groups.get(group_name)
            if group is None:
                continue
            weighted_x = 0.0
            total_weight = 0.0
            for vertex in mesh_object.data.vertices:
                for membership in vertex.groups:
                    if membership.group == group.index and membership.weight > 0.0:
                        weighted_x += (mesh_object.matrix_world @ vertex.co).x * membership.weight
                        total_weight += membership.weight
            if total_weight == 0.0:
                continue
            centroid_x = weighted_x / total_weight
            if centroid_x * expected_sign <= 0.0:
                raise RuntimeError(
                    f"{mesh_object.name} has {group_name} weights on the wrong anatomical side"
                )
            checked += 1
    if checked < 2:
        raise RuntimeError("Avatar proof did not expose both anatomical upper-arm weight groups")


def main() -> None:
    if not ASSET_ROOT.is_dir():
        raise FileNotFoundError(
            "The retained MakeHuman system-asset subset is missing. Restore "
            "assets/source/vendor/makehuman_system_assets first."
        )
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)

    body, rig = create_rigged_human("avatar.makehuman_baseline")
    body.name = "BodyMesh"
    save_and_export(rig, "makehuman_baseline")

    body, rig = create_rigged_human("avatar.makehuman_wardrobe_proof")

    HumanService.set_character_skin(
        asset("skins/young_caucasian_male/young_caucasian_male.mhmat"),
        body,
        skin_type="GAMEENGINE",
    )
    add_asset(body, "eyes/low-poly/low-poly.mhclo", "Eyes")
    add_asset(body, "hair/short01/short01.mhclo", "Hair")
    add_asset(body, "clothes/male_casualsuit01/male_casualsuit01.mhclo", "Clothes")
    add_asset(body, "clothes/shoes01/shoes01.mhclo", "Clothes")
    save_and_export(rig, "makehuman_wardrobe_proof")


main()
