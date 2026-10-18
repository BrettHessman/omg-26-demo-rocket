-- Straight-line mover for ActorProjectileRocket (API-L3-002, variant "straight").
-- Integer-only. Position advances by the integer velocity (mm per tick) set at spawn.
-- Contact is found with the sweep_point host function (API-L5-002) and reported
-- to the engine as the result; the engine resolves on_hit (API-L3-003).

local Rocket = {}

function Rocket:mover_step(input, params, tick)
    local from = self.position
    local to = {
        x = from.x + self.velocity.x,
        y = from.y + self.velocity.y,
        z = from.z + self.velocity.z,
    }

    local contact = sweep_point(from, to, params.filter)

    self.position = to
    self.lifetime = self.lifetime - 1

    if contact ~= nil then
        return { contact = contact, position = contact.position }
    end
    if self.lifetime <= 0 then
        return { expired = true, position = to }
    end
    return { position = to }
end

return Rocket
