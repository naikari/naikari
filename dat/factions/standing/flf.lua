require "factions/standing/skel"


_fdelta_distress = {-0.5, 0} -- Maximum change constraints
_fdelta_kill = {-10, 0.2} -- Maximum change constraints

_fthis = faction.get("FLF")


function faction_hit(current, amount, source, secondary)
    local ret = default_hit(current, amount, source, secondary)

    local frontier_rep = faction.get("Frontier"):playerStanding()
    if frontier_rep < 0 then
        -- If you've made enemies of the Frontier, the FLF will not
        -- forgive you until the Frontier does.
        ret = math.min(ret, frontier_rep)
    end

    return ret
end
