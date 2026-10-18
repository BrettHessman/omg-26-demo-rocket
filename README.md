# rocket-duel (demo-rocket)

The first content package. Root package for the rocket duel demo (`prototypes/DEMO.md`).
Format: `PACKAGE_FORMAT.md` in the workspace repo (P1, OMG-12).

## Layout

- `pack.json`: author descriptor. Not packaged. Read by `omg-pack` (OMG-14).
- `content/`: package root. Packaged as-is, plus a generated `package.json`.
  - `data/`: JSON definitions (schema, entities, movers, weapons, gamemodes, maps).
  - `scripts/`: Luau sources (places).
  - `map/`: cooked collision blobs (`.omgcol`). Generated from `source/` by the cooker (OMG-27).
- `source/`: authoring inputs. Not packaged.
  - `source/map/box_arena.blend`: the map (Blender 5.0.1). Collision: mesh objects or materials whose
    name ends in `-col` (D-32). Tracked with Git LFS (`*.blend`).
  - `source/map/export_glb.py`: exports the `.blend` to `source/map/box_arena.glb` (derived, ignored).

## Status of values

Map: spawns sit on the flat z=2 m ring (surface + 0.5 m), ammo at the z=0 center pit. Verified by ray cast.

Provisional: rocket lifetime (180 ticks), weapon refire and ammo, pickup timings, velocity
representation, filter value `world`, int bit widths. Each will be set with the Script API
(`API_0.md`) and tuning.

## Build

1. Export the map: `blender-py source/map/export_glb.py -- source/map/box_arena.blend source/map/box_arena.glb`
2. Pack: `omg-pack pack . dist/` (output in `dist/`, not committed). `pack.json` `maps` entries are cooked
   into `map/` during packing (D-32).

`blender-py` is the bpy 5.0.1 runner in `~/.local/share/omg-tools/`.
