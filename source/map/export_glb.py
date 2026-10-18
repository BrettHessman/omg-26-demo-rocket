"""Export a map .blend to glTF (.glb) for the collision cooker (OMG-27).

Run with Blender's Python (bpy), from the repo root:
    blender-py source/map/export_glb.py -- source/map/box_arena.blend source/map/box_arena.glb

What is exported: every mesh object. The cooker decides what is solid by name (see README).
Units: Blender scene units are meters (checked by the cooker). Axes: glTF is Y-up. Blender is Z-up.
The exporter applies the Z-up to Y-up change. The cooker reverses it (see D-32).
"""
import sys
import bpy

argv = sys.argv[sys.argv.index("--") + 1:]
src, dst = argv[0], argv[1]

bpy.ops.wm.open_mainfile(filepath=src)

scene = bpy.context.scene
if scene.unit_settings.system != "METRIC" or scene.unit_settings.scale_length != 1.0:
    raise SystemExit("export refused: scene units must be METRIC with scale_length 1.0")

bpy.ops.object.select_all(action="DESELECT")
for obj in scene.objects:
    if obj.type == "MESH":
        obj.select_set(True)

bpy.ops.export_scene.gltf(
    filepath=dst,
    export_format="GLB",
    use_selection=True,
    export_apply=True,
    export_yup=True,
    export_materials="EXPORT",
    export_extras=True,
)
print("EXPORTED", dst)
