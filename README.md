# rocket-duel (demo-rocket)

The first content package. Root package for the rocket duel demo.

## Layout

- `pack.json`: author descriptor. Not packaged. Read by the packager (`omg-pack`).
- `content/`: package root. Packaged as-is, plus a generated `package.json`.
  - `data/`: JSON definitions (schema, entities, movers, weapons, gamemodes, maps).
  - `scripts/`: Luau sources (places).
  - `map/`: cooked collision blobs (`.omgcol`). Generated from `source/` by the cooker.
- `source/`: authoring inputs. Not packaged.
  - `source/map/box_arena.blend`: the map (Blender 5.0.1). Collision: mesh objects or materials whose
    name ends in `-col`. Tracked with Git LFS (`*.blend`).
  - `source/map/export_glb.py`: exports the `.blend` to `source/map/box_arena.glb` (derived, ignored).

## Status of values

Map: spawns sit on the flat z=2 m ring (surface + 0.5 m), ammo at the z=0 center pit. Verified by ray cast.

Provisional: rocket lifetime (180 ticks), weapon refire and ammo, pickup timings, velocity
representation, filter value `world`, int bit widths. Each will be set with the Script API
(`API_0.md`) and tuning.

## Build

1. Export the map: `blender-py source/map/export_glb.py -- source/map/box_arena.blend source/map/box_arena.glb`
2. Pack: `omg-pack pack . dist/` (output in `dist/`, not committed). `pack.json` `maps` entries are cooked
   into `map/` during packing.

Requires Blender 5.0.1's Python module (`bpy`) and runs the export script with it.
