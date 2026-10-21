-- ActorProjectileRocket on_hit (API-L3-003). The rocket's interaction with something: it explodes.
-- It names the interaction. The engine applies it: damage() changes health and delivers the impulse
-- (API-L3-007); the rocket itself never moves a player. Removal on contact is the engine's job
-- (data/entities/rocket.json, removal: contact).
--
-- Event (engine-built): point (vec3 mm, contact), shooter (actor handle), weapon (data),
--   victim (actor handle, or nil for a world contact), victim_position (vec3, when victim is set).
--
-- Rules (decided 2026-10-19, DEMO.md):
--   Direct hit on an actor: direct_damage to that actor only. Push is from the contact point to the victim.
--   Splash: every living actor within splash_radius_mm with line of sight from the point (walls block).
--     Damage falls off linearly: splash_damage * (radius - dist) / radius. The direct victim is excluded.
--   Self splash (shooter in range): scaled by self_splash_scale_percent (50), kind "self".
--   Every damage call carries dir = source to destination (explosion point to victim), in mm.

local Rocket = {}

local function sub(a, b)
    return { x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }
end

function Rocket:on_hit(event)
    local w = event.weapon
    local at = event.point
    local shooter = event.shooter

    if event.victim ~= nil then
        damage(event.victim, shooter, w.direct_damage, "direct", sub(event.victim_position, at))
    end

    -- query_radius returns records { actor, position }, stable order (API-L5-006).
    local hits = query_radius(at, w.splash_radius_mm, "actors")
    for i = 1, #hits do
        local hit = hits[i]
        if hit.actor ~= event.victim and line_of_sight(at, hit.position, "world") then
            local d = sub(hit.position, at)
            local dist = length(d)
            local amount = divide(w.splash_damage * (w.splash_radius_mm - dist), w.splash_radius_mm)
            local kind = "splash"
            if hit.actor == shooter then
                amount = divide(amount * w.self_splash_scale_percent, 100)
                kind = "self"
            end
            if amount > 0 then
                damage(hit.actor, shooter, amount, kind, d)
            end
        end
    end
    return {}
end

return Rocket
