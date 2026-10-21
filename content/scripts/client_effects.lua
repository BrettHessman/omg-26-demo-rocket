-- client_effects (API-L3-005). Client only. Presentation only: it reads the replicated mirror and draws
-- placeholder boxes. It never writes state (D-35 rule 5). Explosions and the gun kick are decided here, in the
-- package, not in the engine (D-51, D-52). Effects are not sent over the network (DEMO.md defaults).
--
-- Call: client_effects(self, event), once per client frame. event = { now_ms = integer }.
-- Host (client, capabilities "mirror" and "present"):
--   mirror_entities(type)        -> array of handles of that type (ascending)
--   mirror_field(handle, field)  -> array of integers, or nil when absent
--   local_player()               -> this client's PlayerState handle (0 until welcomed)
--   present_box{space, center, half, color}
--       space "world": center and half in mm, world space.
--       space "view": center and half in mm, relative to the local eye (x right, y up, z forward).
--       color {r, g, b}, each 0..255.
--   present_text{x, y, text, color}  debug text, pixels from the top-left, color {r, g, b}.
-- The module is the object: its state lives in these locals and persists between frames.

local Effects = {}

local EXPLOSION_MS = 300     -- how long a blast stays on screen
local BLAST_START_MM = 150   -- blast box half size when it appears
local BLAST_GROWTH_MM = 500  -- added to the half size over the blast's life
local KICK_MS = 130          -- gun kick duration after a shot

local seen_rockets = {}      -- handle -> last known position {x, y, z}
local blasts = {}            -- { pos = {x, y, z}, start = ms }
local last_ammo = nil        -- ammo of the local launcher last frame
local kick_start = nil       -- ms when the local gun last fired

local function first(t)
    return t and t[1]
end

local function vec3(t)
    return { x = t[1], y = t[2], z = t[3] }
end

-- A rocket that left the mirror has hit something (it is removed on contact or when its lifetime ends).
local function update_rockets(now)
    local current = {}
    local handles = mirror_entities("ActorProjectileRocket")
    for i = 1, #handles do
        local h = handles[i]
        local p = mirror_field(h, "position")
        if p then
            current[h] = vec3(p)
        end
    end
    for h, pos in pairs(seen_rockets) do
        if current[h] == nil then
            blasts[#blasts + 1] = { pos = pos, start = now }
        end
    end
    seen_rockets = current
end

local function draw_blasts(now)
    local alive = {}
    for i = 1, #blasts do
        local b = blasts[i]
        local age = now - b.start
        if age < EXPLOSION_MS then
            alive[#alive + 1] = b
            local half = BLAST_START_MM + BLAST_GROWTH_MM * age / EXPLOSION_MS
            local left = (EXPLOSION_MS - age) / EXPLOSION_MS
            present_box({
                space = "world",
                center = b.pos,
                half = { x = half, y = half, z = half },
                color = { 255, 150 * left, 25 },
            })
        end
    end
    blasts = alive
end

-- Finds the local launcher (the one whose player is this client) and starts the kick when its ammo drops.
local function update_gun(now, me)
    local launchers = mirror_entities("ActorRocketLauncher")
    for i = 1, #launchers do
        local h = launchers[i]
        if first(mirror_field(h, "player")) == me then
            local ammo = first(mirror_field(h, "ammo"))
            if last_ammo ~= nil and ammo ~= nil and ammo < last_ammo then
                kick_start = now
            end
            last_ammo = ammo
            return
        end
    end
end

local function local_actor_alive(me)
    local actors = mirror_entities("PlayerActor")
    for i = 1, #actors do
        local h = actors[i]
        if first(mirror_field(h, "player")) == me and first(mirror_field(h, "dead")) == 0 then
            return true
        end
    end
    return false
end

-- Placeholder gun: a box held low on the right, kicked back and up while the kick runs.
local function draw_gun(now, me)
    if not local_actor_alive(me) then
        return
    end
    local remaining = 0
    if kick_start ~= nil and now - kick_start < KICK_MS then
        remaining = KICK_MS - (now - kick_start)
    end
    local k = remaining / KICK_MS
    present_box({
        space = "view",
        center = { x = 220, y = -200 + 30 * k, z = 550 - 80 * k },
        half = { x = 50, y = 50, z = 180 },
        color = { 77, 77, 82 },
    })
end

-- Debug text only (D-53). Plain lines in the top-left corner. Not a designed HUD.
local function text_line(row, text, color)
    present_text({ x = 16, y = 16 + 18 * row, text = text, color = color })
end

local function draw_debug(me)
    local row = 0
    local match = mirror_entities("MatchState")
    if match[1] ~= nil then
        local m = match[1]
        text_line(row, "phase " .. tostring(first(mirror_field(m, "phase")))
            .. "  elapsed " .. tostring(first(mirror_field(m, "elapsed")))
            .. "  winner " .. tostring(first(mirror_field(m, "winner"))), { 255, 255, 255 })
        row = row + 1
    end

    local launchers = mirror_entities("ActorRocketLauncher")
    local rockets = "-"
    for i = 1, #launchers do
        if first(mirror_field(launchers[i], "player")) == me then
            rockets = tostring(first(mirror_field(launchers[i], "ammo")))
        end
    end
    local actors = mirror_entities("PlayerActor")
    local health = "-"
    for i = 1, #actors do
        if first(mirror_field(actors[i], "player")) == me then
            health = tostring(first(mirror_field(actors[i], "health")))
        end
    end
    text_line(row, "you " .. tostring(me) .. "  health " .. health .. "  rockets " .. rockets, { 200, 220, 255 })
    row = row + 1

    local states = mirror_entities("PlayerState")
    for i = 1, #states do
        local p = states[i]
        local color = { 255, 255, 255 }
        if p == me then
            color = { 255, 230, 120 }
        end
        text_line(row, "player " .. tostring(p)
            .. "  kills " .. tostring(first(mirror_field(p, "kills")))
            .. "  deaths " .. tostring(first(mirror_field(p, "deaths"))), color)
        row = row + 1
    end
end

function Effects.client_effects(self, event)
    local now = event.now_ms
    local me = local_player()
    update_rockets(now)
    if me ~= 0 then
        update_gun(now, me)
        draw_gun(now, me)
    end
    draw_blasts(now)
    draw_debug(me)
    return {}
end

return Effects
