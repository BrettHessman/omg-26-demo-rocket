-- ActorRocketLauncher fire logic (API-L3-006 weapon_step, decision (a) 2026-10-19).
-- Entity type: ActorRocketLauncher (API-L2-014). Owned by a WeaponSlot, which is owned by PlayerActor.
--
-- Call: weapon_step(self, input, weapon, owner, tick)
--   input   MoverInput: move_x, move_y, jump, fire, aim (vec3). Only fire and aim are used here.
--   weapon  weapon data: refire_ticks, projectile_speed_mm_per_s, projectile_lifetime_ticks, muzzle_offset_mm.
--   owner   read-only snapshot of the owning PlayerActor: handle, position.
-- Host: runs this only while the owner is alive. Ticks the cooldown down every call.

local Launcher = {}

local TICKS_PER_S = 60

function Launcher:weapon_step(input, weapon, owner, tick)
    if self.cooldown > 0 then
        self.cooldown = self.cooldown - 1
    end
    if not input.fire then
        return {}
    end
    if self.cooldown > 0 or self.ammo <= 0 then
        return {}
    end
    -- Aim is a direction vector (MoverInput). A zero aim has no direction to fire along.
    if length(input.aim) == 0 then
        return {}
    end

    self.ammo = self.ammo - 1
    self.cooldown = weapon.refire_ticks

    local per_tick = divide(weapon.projectile_speed_mm_per_s, TICKS_PER_S)
    local velocity = normalize(input.aim, per_tick)
    local muzzle = weapon.muzzle_offset_mm
    local position = {
        x = owner.position.x + muzzle.x,
        y = owner.position.y + muzzle.y,
        z = owner.position.z + muzzle.z,
    }

    spawn("ActorProjectileRocket", {
        position = position,
        velocity = velocity,
        shooter = owner.handle,
        lifetime = weapon.projectile_lifetime_ticks,
    })
    return {}
end

return Launcher
