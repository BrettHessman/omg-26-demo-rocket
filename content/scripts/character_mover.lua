-- Character mover for PlayerActor (API-L2-001, D-26, variant "character").
-- Integer-only. Division goes through divide() (API-L4-007); "/" and "//" are banned by the sanitizer.
-- Tuning values come from data/movers/character.json.
--
-- Knockback (API-L3-007): on_impulse (player_actor.lua) writes self.knock, in mm per tick. This mover adds it
-- to the step and decays it by 7/8 per tick. The mover never reads an impulse directly.
--
-- Known gaps, deferred: wall collision and slope normals (any contact in the down sweep counts as ground).

local Character = {}

local TICKS_PER_S = 60
local MOVE_RANGE = 127      -- move_x and move_y are in [-127, 127] (D-36)
local GROUND_PROBE_MM = 10  -- how far below the new position the down sweep reaches

local function decay(k)
    return divide(k * 7, 8)
end

function Character:mover_step(input, params, tick)
    local from = self.position
    local kn = self.knock

    local vx = divide(input.move_x * params.run_speed_mm_per_s, MOVE_RANGE * TICKS_PER_S) + kn.x
    local vy = divide(input.move_y * params.run_speed_mm_per_s, MOVE_RANGE * TICKS_PER_S) + kn.y
    local vz
    if self.grounded then
        if input.jump then
            vz = divide(params.jump_speed_mm_per_s, TICKS_PER_S)
        else
            vz = 0
        end
    else
        vz = self.velocity.z - divide(params.gravity_mm_per_s2, TICKS_PER_S * TICKS_PER_S)
    end
    vz = vz + kn.z

    local to = { x = from.x + vx, y = from.y + vy, z = from.z + vz }

    -- Down sweep over the whole step, so a fast fall cannot pass through the floor.
    local down = { x = to.x, y = to.y, z = to.z - GROUND_PROBE_MM }
    local contact = sweep_point(from, down, "world")
    local grounded = false
    if contact ~= nil and vz <= 0 then
        grounded = true
        to.z = contact.position.z
        vz = 0
    end

    self.position = to
    self.velocity = { x = vx, y = vy, z = vz }
    self.grounded = grounded
    self.knock = { x = decay(kn.x), y = decay(kn.y), z = decay(kn.z) }
    return {}
end

return Character
