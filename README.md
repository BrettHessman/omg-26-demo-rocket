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
    name ends in `-col` (D-32). Not committed yet: D-24 says source files use Git LFS, which this repo
    does not have set up.
  - `source/map/export_glb.py`: exports the `.blend` to `source/map/box_arena.glb` (derived, ignored).
  - `source/map/box_arena.txt`: the old box list, superseded by the `.blend`. To be removed.

## Status of values

Provisional: rocket lifetime (180 ticks), weapon refire and ammo, pickup timings, velocity
representation, filter value `world`, int bit widths. Each will be set with the Script API
(`API_0.md`) and tuning.

## Build

Not yet. Export, then cook and pack:

```
blender-py source/map/export_glb.py -- source/map/box_arena.blend source/map/box_arena.glb
```

`blender-py` is the bpy 5.0.1 runner in `~/.local/share/omg-tools/`. The cooker (OMG-27) and `omg-pack`
(OMG-14) are next.
