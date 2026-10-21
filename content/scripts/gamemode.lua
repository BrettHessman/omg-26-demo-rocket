-- Gamemode for rocket_duel (API-L2-020, API-L3-001). Free-for-all, one instance per match.
--
-- The gamemode object is the MatchState entity (data/schema/match_state.json): phase, elapsed, winner are
-- replicated, so they are written with plain assignment. Scores live on PlayerState entities and are written
-- with set_field (capability set_field).
--
-- Host sets, server-local, at construction:
--   self.config   gamemode data: kill_limit, time_limit_ticks, respawn_delay_ticks, starting_health
--   self.weapon   rocket_launcher weapon data (not used here; passed on for loadouts)
--   self.spawns   SpawnPoint list from the map, file order: { position = vec3, yaw = int }
-- Host delivers: events, an ordered list since the last tick. Kinds used here:
--   { kind = "join", player }              player = PlayerState handle
--   { kind = "leave", player }
--   { kind = "kill", attacker, victim, cause }   player handles; attacker == victim for a self-kill
--
-- Rules (decided 2026-10-19):
--   Score equals kills (free-for-all). Self-kill gives a death and no kill credit.
--   Spawn point: the one unused for the longest time, ties to the lower index.
--   Match ends at kill_limit kills (the first to reach it) or at time_limit_ticks.
--   Tie-break at the time limit: most kills, then fewer deaths, then earlier join.
--   Respawn after respawn_delay_ticks (0 for the demo). A disconnect removes the player; the match continues.
--   Phases: WARMUP (warmup_ticks; players spawn, kills do not count) -> LIVE -> ENDED (ended_ticks, result
--   shown, actors stay) -> reset -> WARMUP. The match clock (elapsed, time limit) starts at LIVE.

local Gamemode = {}

local PHASE_LIVE = 0
local PHASE_ENDED = 1
local PHASE_WARMUP = 2

local function roster_index(self, player)
    for i = 1, #self.roster do
        if self.roster[i].player == player then
            return i
        end
    end
    return nil
end

local function last_used(self, i)
    local t = self.spawn_used[i]
    if t == nil then
        return -1
    end
    return t
end

local function pick_spawn(self, tick)
    local best = 1
    for i = 2, #self.spawns do
        if last_used(self, i) < last_used(self, best) then
            best = i
        end
    end
    self.spawn_used[best] = tick
    return self.spawns[best]
end

local function spawn_player(self, rec, tick)
    local sp = pick_spawn(self, tick)
    rec.actor = spawn("PlayerActor", {
        player = rec.player,
        position = sp.position,
        yaw = sp.yaw,
        health = self.config.starting_health,
    })
    rec.died = nil
end

local function destroy_actor(rec)
    if rec.actor ~= nil then
        destroy(rec.actor)
        rec.actor = nil
    end
    rec.died = nil
end

-- Score, kills, deaths back to zero. Used when a new warmup starts.
local function clear_stats(self)
    for i = 1, #self.roster do
        local rec = self.roster[i]
        rec.kills = 0
        rec.deaths = 0
        set_field(rec.player, "score", 0)
        set_field(rec.player, "kills", 0)
        set_field(rec.player, "deaths", 0)
    end
end

local function respawn_all(self, tick)
    for i = 1, #self.roster do
        destroy_actor(self.roster[i])
    end
    for i = 1, #self.roster do
        spawn_player(self, self.roster[i], tick)
    end
end

local function spawn_missing(self, tick)
    for i = 1, #self.roster do
        local rec = self.roster[i]
        if rec.actor == nil then
            spawn_player(self, rec, tick)
        end
    end
end

local function apply_events(self, tick, events, scoring)
    for i = 1, #events do
        local ev = events[i]
        if ev.kind == "join" then
            self.roster[#self.roster + 1] = { player = ev.player, actor = nil, died = nil, kills = 0, deaths = 0 }
        elseif ev.kind == "leave" then
            local idx = roster_index(self, ev.player)
            if idx ~= nil then
                local rec = self.roster[idx]
                if rec.actor ~= nil then
                    destroy(rec.actor)
                end
                local kept = {}
                for j = 1, #self.roster do
                    if j ~= idx then
                        kept[#kept + 1] = self.roster[j]
                    end
                end
                self.roster = kept
            end
        elseif ev.kind == "kill" and scoring then
            local v = roster_index(self, ev.victim)
            if v ~= nil then
                local vr = self.roster[v]
                vr.deaths = vr.deaths + 1
                vr.died = tick
                set_field(ev.victim, "deaths", vr.deaths)
            end
            if ev.attacker ~= ev.victim then
                local a = roster_index(self, ev.attacker)
                if a ~= nil then
                    local ar = self.roster[a]
                    ar.kills = ar.kills + 1
                    set_field(ev.attacker, "kills", ar.kills)
                    set_field(ev.attacker, "score", ar.kills)
                end
            end
        end
    end
end

local function ranked_winner(self)
    local best = nil
    for i = 1, #self.roster do
        local r = self.roster[i]
        if best == nil or r.kills > best.kills or (r.kills == best.kills and r.deaths < best.deaths) then
            best = r
        end
    end
    if best == nil then
        return 0
    end
    return best.player
end

local function check_end(self)
    for i = 1, #self.roster do
        if self.roster[i].kills >= self.config.kill_limit then
            self.phase = PHASE_ENDED
            self.phase_start = self.elapsed_tick
            self.winner = self.roster[i].player
            return
        end
    end
    if self.elapsed >= self.config.time_limit_ticks then
        self.phase_start = self.elapsed_tick
        self.phase = PHASE_ENDED
        self.winner = ranked_winner(self)
    end
end

function Gamemode:match_update(tick, events)
    if self.spawn_used == nil then
        self.spawn_used = {}
        self.roster = {}
        self.phase = PHASE_WARMUP
        self.phase_start = tick
        self.match_start = tick
        self.winner = 0
    end
    self.elapsed_tick = tick

    if self.phase == PHASE_WARMUP then
        apply_events(self, tick, events, false)
        spawn_missing(self, tick)
        if tick - self.phase_start >= self.config.warmup_ticks then
            clear_stats(self)
            self.phase = PHASE_LIVE
            self.match_start = tick
            self.winner = 0
            respawn_all(self, tick)
        end
        self.elapsed = 0
        return {}
    end

    if self.phase == PHASE_ENDED then
        apply_events(self, tick, events, false)
        if tick - self.phase_start >= self.config.ended_ticks then
            clear_stats(self)
            self.phase = PHASE_WARMUP
            self.phase_start = tick
            self.winner = 0
            respawn_all(self, tick)
        end
        self.elapsed = tick - self.match_start
        return {}
    end

    -- LIVE
    self.elapsed = tick - self.match_start
    apply_events(self, tick, events, true)
    check_end(self)
    if self.phase == PHASE_ENDED then
        return {}
    end

    -- Spawn anyone with no living actor. A dead actor is destroyed (its owned slot and launcher go with it)
    -- and replaced once the respawn delay has passed.
    for i = 1, #self.roster do
        local rec = self.roster[i]
        if rec.actor == nil then
            spawn_player(self, rec, tick)
        elseif rec.died ~= nil and tick - rec.died >= self.config.respawn_delay_ticks then
            destroy(rec.actor)
            rec.actor = nil
            spawn_player(self, rec, tick)
        end
    end
    return {}
end

return Gamemode
