-- PlayerActor places (API-L3-004 on_spawn, API-L3-007 on_impulse). Entity type: PlayerActor (API-L2-010).
--
-- Replicated `player` (PlayerState handle) on the actor and its launcher lets each client find its own.
-- Host sets, server-local, before on_spawn: self.handle (this actor), self.player (its PlayerState handle),
-- self.weapon (the loadout weapon data, data/weapons/rocket_launcher.json).
--
-- Knockback (API-L3-007): the actor is told an impulse was applied and computes its own response from its
-- own mass and tuning (params from data/movers/character.json). Velocity change is in mm per tick and goes
-- into self.knock, which the character mover applies.

local Player = {}

local UNIT = 1000           -- normalize() scale: a unit direction is length 1000
local TICKS_PER_S = 60

local function zero()
    return { x = 0, y = 0, z = 0 }
end

-- Creates the weapon slot and its rocket launcher. Full ammo on spawn (no pickups in the demo).
function Player:on_spawn(args)
    self.position = args.position
    self.velocity = zero()
    self.grounded = false
    self.knock = zero()
    self.health = args.health
    self.dead = false

    local slot = spawn("WeaponSlot", { owner = self.handle, player = self.player })
    local launcher = spawn("ActorRocketLauncher", {
        owner = slot,
        player = self.player,
        ammo = self.weapon.starting_ammo,
        cooldown = 0,
    })
    set_field(slot, "item", launcher)
    return {}
end

-- impulse = { direction = {x, y, z} in mm (source to destination), magnitude = hp-scale int, kind = string }
-- params = mover params (character variant).
function Player:on_impulse(impulse, params)
    local d = impulse.direction
    local unit
    if length(d) == 0 then
        unit = { x = 0, y = 0, z = UNIT }   -- no direction: push straight up
    else
        unit = normalize(d, UNIT)
    end

    -- dv (mm/s) = unit * magnitude * knockback_k / mass. Scaled to mm per tick.
    local m = impulse.magnitude
    local denom = UNIT * params.mass * TICKS_PER_S
    local dv = {
        x = divide(unit.x * m * params.knockback_k, denom),
        y = divide(unit.y * m * params.knockback_k, denom),
        z = divide(unit.z * m * params.knockback_k, denom),
    }
    self.knock = {
        x = self.knock.x + dv.x,
        y = self.knock.y + dv.y,
        z = self.knock.z + dv.z,
    }
    return {}
end

return Player
