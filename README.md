# rocket-duel (demo-rocket)

The first content package. Root package for the rocket duel demo (`prototypes/DEMO.md`).
Format: `PACKAGE_FORMAT.md` in the workspace repo (P1, OMG-12).

## Layout

- `pack.json`: author descriptor. Not packaged. Read by `omg-pack` (OMG-14).
- `content/`: package root. Packaged as-is, plus a generated `package.json`.
  - `data/`: JSON definitions (schema, entities, movers, weapons, gamemodes, maps).
  - `scripts/`: Luau sources (places).
  - `map/`: cooked collision blobs (`.omgcol`). Generated from `source/` by the cooker (OMG-27).
- `source/`: authoring inputs. Not packaged. `source/map/box_arena.txt` is the MVP box list.

## Status of values

Provisional: rocket lifetime (180 ticks), weapon refire and ammo, pickup timings, velocity
representation, filter value `world`, int bit widths. Each will be set with the Script API
(`API_0.md`) and tuning.

## Build

Not yet. `omg-pack` (OMG-14) and the cooker (OMG-27) are next.
